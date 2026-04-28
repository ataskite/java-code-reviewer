# Java Code Reviewer Plugin 迁移实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 java-code-reviewer 从 OpenClaw Skill 迁移为 Claude Code Plugin（skill + agent + command 三位一体），支持 Marketplace 分发。

**Architecture:** Plugin 由三个核心组件构成——SKILL.md 作为主入口用 AskUserQuestion 收集配置，agents/reviewer.md 作为专属子代理执行审查，commands/review.md 作为 `/review` 斜杠命令入口。6 个 Bash 脚本和 3 个参考文档原封不动复用，仅路径变量从 `{baseDir}` 替换为 `${CLAUDE_PLUGIN_ROOT}`。

**Tech Stack:** Claude Code Plugin 系统（manifest.json + SKILL.md + Agent frontmatter）、Bash 脚本、Markdown

---

## File Structure

| 操作 | 文件路径 | 职责 |
|------|---------|------|
| Create | `.claude-plugin/plugin.json` | Plugin 元数据和分发配置 |
| Create | `skills/java-code-reviewer/SKILL.md` | 主入口：AskUserQuestion 交互 + 预扫描编排 + 子代理启动 |
| Create | `agents/java-code-reviewer.md` | 审查子代理：15 维度逐文件评估 + 报告生成 + 飞书上传 |
| Create | `commands/java-code-reviewer.md` | `/review` 斜杠命令入口，转发到 skill |
| Modify | `references/examples.md` | 更新交互示例，匹配 AskUserQuestion 风格 |
| Keep | `scripts/*.sh`（6 个） | 预扫描脚本，内容不变 |
| Keep | `references/review-framework.md` | 15 维度定义 + 模式矩阵，不变 |
| Keep | `references/report-format.md` | 报告格式规范，不变 |
| Delete | `SKILL.md`（根目录旧文件） | 迁移完成后删除 |
| Delete | `prompts/java-code-reviewer.md` | 迁移完成后删除 |

---

### Task 1: 创建 Plugin Manifest

**Files:**
- Create: `.claude-plugin/plugin.json`

- [ ] **Step 1: 创建 .claude-plugin 目录**

```bash
mkdir -p .claude-plugin
```

- [ ] **Step 2: 创建 plugin.json**

```json
{
  "name": "java-code-reviewer",
  "description": "Java 代码审查插件 — 15维度智能审查，支持增量/存量双模式",
  "version": "1.0.0",
  "author": {
    "name": "ataskite"
  },
  "repository": "https://gitlab.your-company.com/team/java-code-reviewer-plugin",
  "license": "MIT",
  "keywords": ["java", "code-review", "security", "sonar"]
}
```

- [ ] **Step 3: 验证 JSON 合法性**

```bash
cat .claude-plugin/plugin.json | python3 -m json.tool > /dev/null && echo "JSON valid" || echo "JSON invalid"
```

Expected: `JSON valid`

- [ ] **Step 4: Commit**

```bash
git add .claude-plugin/plugin.json
git commit -m "feat: add Claude Code plugin manifest"
```

---

### Task 2: 创建 Agent 文件

**Files:**
- Create: `agents/java-code-reviewer.md`

这是从 `prompts/java-code-reviewer.md` 的完整迁移。内容主体不变，加 frontmatter，路径变量替换。

- [ ] **Step 1: 创建 agents 目录**

```bash
mkdir -p agents
```

- [ ] **Step 2: 创建 agents/java-code-reviewer.md**

将 `prompts/java-code-reviewer.md` 的完整内容迁移，做以下改动：

1. **在文件开头添加 frontmatter**：
```yaml
---
name: java-code-reviewer
description: 执行 Java 代码审查的专属子代理，按维度逐文件评估，生成结构化报告
model: sonnet
effort: high
maxTurns: 50
---
```

2. **路径替换**：将文件中所有 `{baseDir}/references/` 替换为 `${CLAUDE_PLUGIN_ROOT}/references/`

具体需要替换的行（在当前 prompts/java-code-reviewer.md 中）：
- 第 73 行：`定义在 \`{baseDir}/references/review-framework.md\``
- 第 165 行：`见 \`{baseDir}/references/review-framework.md\` 覆盖矩阵`
- 第 595 行：`定义在 \`{baseDir}/references/review-framework.md\``
- 第 601 行：`定义在 \`{baseDir}/references/report-format.md\``

3. **其余内容完全保持不变**，包括：
   - Agent 人设（15 年经验 Java 架构师）
   - 审查原则（9 条核心原则）
   - 外部参数注入格式
   - 审查模式定义（fast/standard/deep/security）
   - 6 步执行流程
   - v5.5 扫描策略（阶段 A→B→C→D）
   - 15 维度文件类型匹配表
   - 证据格式规范
   - 多维表格 18 字段定义和 JSON schema
   - MUST/DO/DON'T 规则
   - 问题等级定义、评分标尺
   - 审查覆盖率追踪

- [ ] **Step 3: 验证 frontmatter 格式**

```bash
head -8 agents/java-code-reviewer.md
```

Expected 输出应包含 frontmatter 的 `---` 分隔符和所有字段。

- [ ] **Step 4: 验证路径替换完成**

```bash
grep -n '{baseDir}' agents/java-code-reviewer.md
```

Expected: 无输出（所有 `{baseDir}` 已替换）

- [ ] **Step 5: 验证 CLAUDE_PLUGIN_ROOT 引用正确**

```bash
grep -n 'CLAUDE_PLUGIN_ROOT' agents/java-code-reviewer.md
```

Expected: 4 行匹配（references 引用处）

- [ ] **Step 6: Commit**

```bash
git add agents/java-code-reviewer.md
git commit -m "feat: add plugin agent for code review execution"
```

---

### Task 3: 创建 Skill 文件（核心改动）

**Files:**
- Create: `skills/java-code-reviewer/SKILL.md`

这是改动最大的文件。从当前根目录 `SKILL.md` 迁移，核心变化：纯文字交互 → AskUserQuestion。

- [ ] **Step 1: 创建 skills 目录**

```bash
mkdir -p skills/java-code-reviewer
```

- [ ] **Step 2: 创建 skills/java-code-reviewer/SKILL.md**

整体结构如下，完整内容写入文件：

**Frontmatter**：
```yaml
---
description: Java 代码审查 — 支持增量/存量审查、15维度评估、飞书报告上传
---
```

**主体结构**（按顺序）：

1. **用途** — 保留当前 SKILL.md 第 8-18 行的触发场景描述，不变

2. **快速启动模式** — 保留当前 SKILL.md 第 20-131 行的完整内容：
   - 模式判定
   - 参数规范（6 个参数表格）
   - 参数映射（快速启动参数 → 交互式变量映射表）
   - 校验规则（6 条）
   - 校验失败输出格式
   - 快速启动执行流程
   - 启动提示模板
   - 调用示例（5 个）

3. **工作流程** — 保留模式判定逻辑不变

4. **预扫描阶段** — 保留当前 SKILL.md 第 148-232 行的完整内容，唯一改动：
   - 脚本调用从 `bash scripts/phase1-xxx.sh` 改为 `bash ${CLAUDE_PLUGIN_ROOT}/scripts/phase1-xxx.sh`
   - 分支切换脚本同理：`bash ${CLAUDE_PLUGIN_ROOT}/scripts/phase2-switch-branch.sh`

5. **交互式确认** — **全部重写**，6 步改为 AskUserQuestion：

   删除当前 SKILL.md 第 236-550 行的纯文字交互内容（包括工具禁用规则、严格单步执行规则、通用交互格式、6 个步骤的纯文字选项文本）。

   替换为以下 AskUserQuestion 交互指令：

   ```markdown
   ### 交互式确认（通过 AskUserQuestion 收集配置）

   使用 Claude Code 内置的 AskUserQuestion 工具逐步收集审查配置。每个步骤调用一次 AskUserQuestion，multiSelect: false。

   **条件步骤规则**：
   - 分支选择：仅在 IS_GIT_REPO=true 且分支数 > 1 时执行
   - 审查范围（存量多模块）：仅在 REVIEW_TYPE=存量审查 且 PROJECT_TYPE 为 *-multi 时执行
   - 飞书上传：仅在 LARK_PLUGIN_INSTALLED=true 时执行

   #### 步骤1：选择审查分支（条件步骤）

   触发条件：IS_GIT_REPO=true 且分支数 > 1

   使用 AskUserQuestion，配置如下：
   - question: "检测到 Git 仓库（当前分支：{CURRENT_BRANCH}），请选择要审查的分支"
   - header: "选择分支"
   - options: 从预扫描结果动态生成分支选项（最多 4 个，超 4 个时选最热门的 + "其他分支"选项）
   - multiSelect: false

   用户选择后：
   - 设置 TARGET_BRANCH
   - 如不是当前分支，执行：bash ${CLAUDE_PLUGIN_ROOT}/scripts/phase2-switch-branch.sh "$PROJECT_DIR" "{TARGET_BRANCH}" "$CURRENT_BRANCH" "$PROJECT_SOURCE"
   - 本地项目保护规则不变（PROJECT_SOURCE=local + 未提交改动时不切换）

   #### 步骤2：选择审查类型

   使用 AskUserQuestion，配置如下：
   - question: "请选择审查类型"
   - header: "审查类型"
   - options:
     - label: "增量审查"
       description: "审查最近 N 次提交的变更文件及其关联代码"
     - label: "存量审查"
       description: "审查指定模块或全量代码"
   - multiSelect: false

   变量赋值：增量审查 → REVIEW_TYPE=增量审查，存量审查 → REVIEW_TYPE=存量审查

   #### 步骤3：选择审查范围（条件步骤）

   **增量审查时**：
   - question: "审查最近几次提交的变更？"
   - header: "提交次数"
   - options:
     - label: "最近 1 次"
       description: "仅审查最近一次提交"
     - label: "最近 3 次"
       description: "审查最近 3 次提交"
     - label: "最近 5 次（推荐）"
       description: "审查最近 5 次提交"
     - label: "最近 10 次"
       description: "审查最近 10 次提交"
   - multiSelect: false
   - 用户选 "Other" 时接受自定义数字输入

   **存量审查 + 多模块时**：
   - question: "请选择要审查的模块"
   - header: "审查范围"
   - options: 从预扫描结果动态生成（全量代码 + 前 3 个模块，如有更多模块则用户可通过 Other 自定义输入）
   - multiSelect: false
   - 注意：即使多选场景，AskUserQuestion 的 multiSelect 选项用于模块选择

   **存量审查 + 单模块时**：跳过此步骤，自动设 REVIEW_SCOPE=全量代码

   #### 步骤4：选择审查模式

   使用 AskUserQuestion，配置如下：
   - question: "请选择审查模式"
   - header: "审查模式"
   - options:
     - label: "fast"
       description: "快速扫雷，聚焦关键风险，约 5 分钟内出结果"
     - label: "standard（推荐）"
       description: "标准审查，覆盖常规核心维度 + API设计 + 缓存基础 + 核心测试缺失，日常迭代推荐"
     - label: "deep"
       description: "深度审查，全量 15 维度，适合大版本上线前"
     - label: "security"
       description: "安全专项，聚焦安全核心维度"
   - multiSelect: false

   #### 步骤5：选择飞书上传选项（条件步骤）

   触发条件：LARK_PLUGIN_INSTALLED=true

   使用 AskUserQuestion，配置如下：
   - question: "检测到 lark-cli 已安装，请选择审查结果的处理方式"
   - header: "飞书上传"
   - options:
     - label: "仅显示报告"
       description: "只在聊天中显示完整审查报告"
     - label: "上传到云文档"
       description: "审查报告上传到飞书云文档，聊天中显示精简摘要"
     - label: "上传到多维表格"
       description: "问题清单录入飞书多维表格，聊天中显示精简摘要"
     - label: "同时上传两者"
       description: "同时上传云文档和多维表格，聊天中显示精简摘要"
   - multiSelect: false

   当 LARK_PLUGIN_INSTALLED=false 时跳过，设 FEISHU_UPLOAD_OPTION=lark-cli未安装。

   #### 步骤6：确认执行计划

   使用 AskUserQuestion，配置如下：
   - question: "确认以下执行计划后开始审查"
   - header: "确认执行"
   - options:
     - label: "确认执行"
       description: "按以上配置开始审查"
     - label: "取消"
       description: "取消本次审查"
   - multiSelect: false

   确认前展示完整执行计划（项目路径、类型、分支、审查类型/范围/模式、启用维度、飞书上传）。
   ```

6. **代码审查阶段** — 保留当前 SKILL.md 第 584-725 行的内容，改动点：
   - 子代理启动从 `sessions_spawn` 改为 `Agent tool`
   - Prompt 构造中：读取子代理内容从 `{baseDir}/prompts/java-code-reviewer.md` 改为引用 plugin 内置 agent `java-code-reviewer`
   - 路径替换说明从 `{baseDir}` 替换改为 `${CLAUDE_PLUGIN_ROOT}`
   - 增量预处理脚本路径：`bash ${CLAUDE_PLUGIN_ROOT}/scripts/phase5-prepare-incremental.sh`
   - 删除所有对 `openclaw`、`sessions_spawn`、`thread 绑定` 的引用

   **子代理调用方式改为**：
   ```markdown
   使用 Agent tool 启动 plugin 内置的 java-code-reviewer 子代理：

   - description: "执行 Java 代码审查"
   - prompt: 注入审查参数表 + 项目概况 + 增量数据 + 执行指令

   参数注入格式保持不变（参数表 + 项目概况 + 增量提交记录 + 变更文件列表 + 变更统计）。

   不再需要手动读取 agent 提示词文件并追加到 prompt 中——Agent tool 会自动加载 agents/java-code-reviewer.md 的完整内容。

   仅需在 prompt 中传入审查参数和辅助数据，附加执行指令：
   "请基于以上审查参数，立即开始执行代码审查。不要进行任何用户交互或询问，直接从代码审查开始执行。"
   ```

7. **重要规则** — 保留适用的逻辑性规则，修改：
   - 删除规则 1（禁止 AskUserQuestion）和规则 9（禁止合并交互步骤）—— 这两条在 Plugin 版本中不再适用
   - 保留其余规则：输入校验、执行前确认、三个核心选项、强制中文、零审查动作、快速启动参数完整性
   - 条件步骤规则全部保留

8. **错误处理** — 保留当前内容不变

9. **示例对话** — 改为引用：`详见 ${CLAUDE_PLUGIN_ROOT}/references/examples.md`

- [ ] **Step 3: 验证关键路径引用**

```bash
grep -n 'CLAUDE_PLUGIN_ROOT' skills/java-code-reviewer/SKILL.md
```

Expected: 多行匹配，包含 scripts/ 和 references/ 的引用

- [ ] **Step 4: 验证无 OpenClaw 残留引用**

```bash
grep -in 'openclaw\|sessions_spawn\|{baseDir}' skills/java-code-reviewer/SKILL.md
```

Expected: 无输出

- [ ] **Step 5: 验证 AskUserQuestion 交互指令存在**

```bash
grep -c 'AskUserQuestion' skills/java-code-reviewer/SKILL.md
```

Expected: >= 6（6 个步骤各至少提及一次）

- [ ] **Step 6: Commit**

```bash
git add skills/java-code-reviewer/SKILL.md
git commit -m "feat: add plugin skill with AskUserQuestion interaction"
```

---

### Task 4: 创建 Command 文件

**Files:**
- Create: `commands/java-code-reviewer.md`

- [ ] **Step 1: 创建 commands 目录**

```bash
mkdir -p commands
```

- [ ] **Step 2: 创建 commands/java-code-reviewer.md**

```markdown
---
description: Java 代码审查 — 启动交互式代码审查流程
---

Invoke the `java-code-reviewer` skill to start a Java code review session.

If the user provides arguments (e.g., project path, --mode, --type), pass them through as `$ARGUMENTS`. If no arguments are provided, the skill will guide the user through interactive configuration using AskUserQuestion.
```

- [ ] **Step 3: 验证文件存在**

```bash
cat commands/java-code-reviewer.md
```

Expected: 显示完整文件内容

- [ ] **Step 4: Commit**

```bash
git add commands/java-code-reviewer.md
git commit -m "feat: add /review slash command entry point"
```

---

### Task 5: 更新 examples.md 交互描述

**Files:**
- Modify: `references/examples.md`

将示例中的纯文字交互（`📌 [xxx] 请选择... A) B) C) 请输入选项编号`）改为 AskUserQuestion 选择式描述。

- [ ] **Step 1: 更新示例1（本地单模块）**

将第 15-99 行的交互部分从纯文字选项格式改为 AskUserQuestion 描述格式：

```markdown
[第1次回复：预扫描 + AskUserQuestion 步骤2（审查类型）]
我：🔍 预扫描完成
   ...（预扫描摘要不变）

   → AskUserQuestion: "请选择审查类型"
   → 用户选择: 存量审查

[第2次回复：自动跳过步骤3 + AskUserQuestion 步骤4（审查模式）]
我：✅ 已选择：存量审查
   Maven 单模块项目，跳过审查范围选择，自动使用「全量代码」。

   → AskUserQuestion: "请选择审查模式"
   → 用户选择: standard

[第3次回复：AskUserQuestion 步骤5（飞书上传）]
我：✅ 已选择：standard

   → AskUserQuestion: "检测到 lark-cli 已安装，请选择审查结果的处理方式"
   → 用户选择: 同时上传两者

[第4次回复：AskUserQuestion 步骤6（确认）]
我：📋 执行计划：...（执行计划不变）

   → AskUserQuestion: "确认以下执行计划后开始审查"
   → 用户选择: 确认执行

[第5次回复：启动子agent]
...（启动提示不变，但 "OpenClaw" 改为 "Claude Code"）
```

- [ ] **Step 2: 更新示例2（Git多模块）**

将第 113-225 行做相同风格更新，所有 `📌 [xxx]` + `A) B) C) 请输入选项编号` 替换为 `→ AskUserQuestion: "xxx" → 用户选择: xxx` 格式。

- [ ] **Step 3: 更新示例3-5（快速启动模式）**

示例3（第 229-276 行）、示例4（第 280-308 行）、示例5（第 312-367 行）无需交互改动（快速启动模式无 AskUserQuestion），但将其中的 "OpenClaw" 替换为 "Claude Code"。

- [ ] **Step 4: 验证无纯文字交互残留**

```bash
grep -c '请输入选项编号' references/examples.md
```

Expected: 0

- [ ] **Step 5: Commit**

```bash
git add references/examples.md
git commit -m "docs: update examples to reflect AskUserQuestion interaction style"
```

---

### Task 6: 清理旧文件

**Files:**
- Delete: `SKILL.md`（根目录）
- Delete: `prompts/java-code-reviewer.md`
- Delete: `prompts/` 目录（如果为空）

- [ ] **Step 1: 确认所有新文件已创建且内容正确**

```bash
echo "=== Plugin Manifest ===" && cat .claude-plugin/plugin.json | python3 -m json.tool > /dev/null && echo "OK"
echo "=== Agent ===" && head -8 agents/java-code-reviewer.md
echo "=== Skill ===" && head -5 skills/java-code-reviewer/SKILL.md
echo "=== Command ===" && cat commands/java-code-reviewer.md
echo "=== Old files to remove ===" && ls -la SKILL.md prompts/java-code-reviewer.md 2>&1
```

Expected: 所有新文件存在，旧文件仍存在等待删除

- [ ] **Step 2: 删除根目录旧 SKILL.md**

```bash
rm SKILL.md
```

- [ ] **Step 3: 删除旧 prompts 目录**

```bash
rm -rf prompts/
```

- [ ] **Step 4: 验证最终目录结构**

```bash
find . -not -path './.git/*' -not -path './.claude/*' -not -path './docs/*' -not -name '.DS_Store' | sort
```

Expected 输出应包含：
```
.
.claude-plugin
.claude-plugin/plugin.json
.gitignore
agents
agents/java-code-reviewer.md
commands
commands/java-code-reviewer.md
references
references/examples.md
references/report-format.md
references/review-framework.md
scripts
scripts/phase1-detect-project.sh
scripts/phase2-detect-branches.sh
scripts/phase2-switch-branch.sh
scripts/phase3-project-scan.sh
scripts/phase4-detect-lark-plugin.sh
scripts/phase5-prepare-incremental.sh
skills
skills/java-code-reviewer
skills/java-code-reviewer/SKILL.md
```

不应包含：`SKILL.md`（根目录）、`prompts/`

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor: remove old OpenClaw skill structure, replaced by plugin format"
```

---

### Task 7: 本地测试验证

- [ ] **Step 1: 用 --plugin-dir 加载测试**

```bash
claude --plugin-dir . --debug 2>&1 | head -30
```

Expected: 输出中包含 "loading plugin java-code-reviewer"、skill/agent/command 注册信息

- [ ] **Step 2: 验证 skill 被发现**

在 Claude Code 会话中输入 `/help`，检查是否出现 `/java-code-reviewer:java-code-reviewer`

- [ ] **Step 3: 验证 agent 被发现**

在 Claude Code 会话中查看 `/agents`，检查是否出现 `java-code-reviewer:java-code-reviewer`

- [ ] **Step 4: 冒烟测试**

在 Claude Code 会话中触发：`/java-code-reviewer:java-code-reviewer /path/to/test-project`

验证：
1. 预扫描脚本正常执行
2. AskUserQuestion 交互正确弹出选项
3. 子代理能被启动
4. 审查结果正常返回

- [ ] **Step 5: 修复发现的问题并提交**

如有问题，修复后提交：
```bash
git add -A
git commit -m "fix: address issues found during local testing"
```

---

## Spec Coverage Checklist

| Spec 需求 | 对应 Task |
|-----------|----------|
| Plugin manifest (plugin.json) | Task 1 |
| Agent frontmatter (name, description, model, effort, maxTurns) | Task 2 |
| Agent 内容迁移（15 维度、6 步流程、证据规范、飞书上传） | Task 2 |
| Agent 路径替换 {baseDir} → ${CLAUDE_PLUGIN_ROOT} | Task 2 |
| Skill AskUserQuestion 交互（6 步） | Task 3 |
| Skill 预扫描脚本路径替换 | Task 3 |
| Skill 子代理启动方式（Agent tool） | Task 3 |
| Skill Quick Start 模式保留 | Task 3 |
| Command 轻量入口 | Task 4 |
| examples.md 交互描述更新 | Task 5 |
| 旧文件清理 | Task 6 |
| 本地测试 | Task 7 |
