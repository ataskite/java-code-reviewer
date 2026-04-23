#!/bin/bash
# 一键配置 Java 代码审查子 Agent
#
# 用法: bash scripts/setup-subagent.sh [workspace-path]
#
# 默认 workspace: ~/.openclaw/workspace-java-code-reviewer
#
# 此脚本会：
# 1. 创建子 Agent workspace 目录
# 2. 从模板生成 AGENTS.md（替换 {baseDir} 为实际路径）
# 3. 复制 references/ 参考文档
# 4. 注册子 Agent (openclaw agents add)
# 5. 设置子 Agent 身份
# 6. 配置 subagent 委派权限 (allowAgents)

set -e

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE_DIR="${1:-$HOME/.openclaw/workspace-java-code-reviewer}"
AGENT_ID="java-code-reviewer"
CONFIG_FILE="$HOME/.openclaw/openclaw.json"

echo ""
echo "🛡️ Java 代码审查子 Agent — 一键配置"
echo "===================================="
echo "Skill 目录:  $SKILL_DIR"
echo "Workspace:   $WORKSPACE_DIR"
echo ""

# ---------- 前置检查 ----------
if [ ! -f "$SKILL_DIR/prompts/java-code-reviewer.md" ]; then
    echo "❌ 错误: 找不到 prompts/java-code-reviewer.md"
    echo "   请确认脚本在正确的 skill 目录下运行"
    exit 1
fi

if [ ! -d "$SKILL_DIR/references" ]; then
    echo "❌ 错误: 找不到 references/ 目录"
    echo "   请确认脚本在正确的 skill 目录下运行"
    exit 1
fi

# ---------- Step 1: 创建 workspace 目录 ----------
echo "📁 [1/6] 创建 workspace 目录..."
mkdir -p "$WORKSPACE_DIR/references"
echo "   ✓ $WORKSPACE_DIR"

# ---------- Step 2: 从模板生成 AGENTS.md ----------
echo "📝 [2/6] 生成 AGENTS.md（替换 {baseDir} → $WORKSPACE_DIR）..."
sed "s|{baseDir}|$WORKSPACE_DIR|g" "$SKILL_DIR/prompts/java-code-reviewer.md" > "$WORKSPACE_DIR/AGENTS.md"
echo "   ✓ AGENTS.md 已生成"

# ---------- Step 3: 复制参考文档 ----------
echo "📚 [3/6] 复制参考文档..."
cp "$SKILL_DIR/references/"* "$WORKSPACE_DIR/references/"
FILE_COUNT=$(ls "$WORKSPACE_DIR/references/" | wc -l | tr -d ' ')
echo "   ✓ references/ ($FILE_COUNT 个文件)"

# ---------- Step 4: 注册子 Agent ----------
echo "🤖 [4/6] 注册子 Agent..."
if command -v openclaw &>/dev/null; then
    openclaw agents add "$AGENT_ID" \
        --workspace "$WORKSPACE_DIR" \
        --non-interactive 2>/dev/null && \
        echo "   ✓ Agent 已注册" || \
        echo "   ⚠️ Agent 可能已存在（忽略）"
else
    echo "   ⚠️ openclaw 命令未找到，请手动注册 agent"
fi

# ---------- Step 5: 设置身份 ----------
echo "🎨 [5/6] 设置身份..."
if command -v openclaw &>/dev/null; then
    openclaw agents set-identity \
        --agent "$AGENT_ID" \
        --name "Java代码审查" \
        --emoji "🛡️" 2>/dev/null && \
        echo "   ✓ 身份已设置" || \
        echo "   ⚠️ 身份设置跳过"
fi

# ---------- Step 6: 配置 subagent 委派权限 ----------
echo "⚙️ [6/6] 配置 subagent 委派权限..."

NEED_ALLOW_AGENTS=true
if [ -f "$CONFIG_FILE" ]; then
    # 检查是否已配置（兼容 JSON 和 JSON5 注释风格）
    if grep -q '"allowAgents"' "$CONFIG_FILE" 2>/dev/null; then
        if grep -q "java-code-reviewer" "$CONFIG_FILE" 2>/dev/null; then
            echo "   ✓ allowAgents 已包含 java-code-reviewer（跳过）"
            NEED_ALLOW_AGENTS=false
        fi
    fi
fi

if [ "$NEED_ALLOW_AGENTS" = true ]; then
    if [ -f "$CONFIG_FILE" ]; then
        # 使用 node 处理 JSON（比 sed 更安全）
        if command -v node &>/dev/null; then
            node -e "
const fs = require('fs');
const f = '$CONFIG_FILE';
let raw = fs.readFileSync(f, 'utf8');
// 去掉 JSON5 注释和尾逗号以便解析
let json = raw.replace(/\/\/.*$/gm, '').replace(/\/\*[\s\S]*?\*\//g, '').replace(/,\s*([}\]])/g, '\$1');
let cfg = JSON.parse(json);
if (!cfg.agents) cfg.agents = {};
if (!cfg.agents.defaults) cfg.agents.defaults = {};
if (!cfg.agents.defaults.subagents) cfg.agents.defaults.subagents = {};
if (!cfg.agents.defaults.subagents.allowAgents) {
    cfg.agents.defaults.subagents.allowAgents = [];
}
if (!cfg.agents.defaults.subagents.allowAgents.includes('java-code-reviewer')) {
    cfg.agents.defaults.subagents.allowAgents.push('java-code-reviewer');
}
// 写回时保留 JSON5 格式比较复杂，这里直接写标准 JSON
fs.writeFileSync(f, JSON.stringify(cfg, null, 2));
console.log('   ✓ allowAgents 已添加 java-code-reviewer');
" 2>/dev/null || {
                echo "   ⚠️ 自动配置失败，请手动在 openclaw.json 中添加："
                echo ""
                echo '   agents.defaults.subagents.allowAgents: ["java-code-reviewer"]'
            }
        else
            echo "   ⚠️ 未找到 node，请手动在 openclaw.json 中添加："
            echo ""
            echo '   agents.defaults.subagents.allowAgents: ["java-code-reviewer"]'
        fi
    else
        echo "   ⚠️ 未找到 $CONFIG_FILE，请确认 OpenClaw 已安装"
    fi
fi

# ---------- 完成 ----------
echo ""
echo "✅ 配置完成！"
echo ""
echo "📋 最终目录结构："
echo "   $WORKSPACE_DIR/"
echo "   ├── AGENTS.md"
echo "   └── references/ ($FILE_COUNT 个文件)"
echo ""
echo "🚀 重启 OpenClaw 后即可使用，在 coding agent 对话中发送："
echo "   帮我审查这个项目 /path/to/your/java/project"
echo ""
