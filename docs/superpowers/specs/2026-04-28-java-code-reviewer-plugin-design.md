# Java Code Reviewer — Claude Code Plugin 迁移设计

## 背景

当前 java-code-reviewer 是一个 OpenClaw Skill，采用双代理架构（主代理编排 + 子代理执行审查），支持 15 维度、4 种模式的 Java 代码审查。现计划迁移为 Claude Code Plugin，利用 Plugin 系统的 skill + agent + command 三位一体能力，实现可打包分发的完整审查工具。

## 设计目标

1. 将 OpenClaw Skill 转换为 Claude Code Plugin 格式
2. 用 AskUserQuestion 替代纯文字交互
3. 用 Plugin Agent 替代 sessions_spawn 子代理
4. 核心审查逻辑（15 维度、扫描策略、报告生成、飞书集成）全部复用
5. 支持 Marketplace 分发（含企业内部 GitLab）

## 目标目录结构

```
java-code-reviewer/
├── .claude-plugin/
│   └── plugin.json                    # Plugin 元数据
├── skills/
│   └── java-code-reviewer/
│       └── SKILL.md                   # 主入口：AskUserQuestion 收集配置 + 编排流程
├── agents/
│   └── java-code-reviewer.md          # 审查执行子代理（sonnet + high effort）
├── commands/
│   └── java-code-reviewer.md          # /java-code-reviewer:java-code-reviewer 入口
├── scripts/                           # 保留不变
│   ├── phase1-detect-project.sh
│   ├── phase2-detect-branches.sh
│   ├── phase2-switch-branch.sh
│   ├── phase3-project-scan.sh
│   ├── phase4-detect-lark-plugin.sh
│   └── phase5-prepare-incremental.sh
└── references/                        # 保留（examples.md 更新交互描述）
    ├── review-framework.md
    ├── report-format.md
    └── examples.md
```

调用方式：`/java-code-reviewer:java-code-reviewer [path] [--mode ...]`

---

## 1. Plugin Manifest

**文件**：`.claude-plugin/plugin.json`

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

- `repository` 后续填实际 GitLab 地址
- `version` 显式管理，发布时手动 bump
- skills/agents/commands 使用默认路径，不指定自定义路径

---

## 2. Skill — skills/java-code-reviewer/SKILL.md

### Frontmatter

```yaml
---
description: Java 代码审查 — 支持增量/存量审查、15维度评估、飞书报告上传
---
```

### 整体流程

```
解析 $ARGUMENTS
  ├── 有 --mode 参数 → Quick Start 模式（参数直传）
  └── 无参数 → Interactive 模式

预扫描阶段（自动执行 4 个脚本）
  1. phase1-detect-project.sh → 检测项目类型 + Git clone
  2. phase2-detect-branches.sh → 列出分支
  3. phase3-project-scan.sh → 扫描项目结构
  4. phase4-detect-lark-plugin.sh → 检测 lark-cli

Interactive 模式（AskUserQuestion 6 步）
  Step 1: 选分支（条件：多分支时才问）
  Step 2: 选审查类型（incremental / stock）
  Step 3: 选审查范围（根据类型动态生成选项）
  Step 4: 选审查模式（fast / standard / deep / security）
  Step 5: 选飞书上传（条件：有 lark-cli 时才问）
  Step 6: 确认执行计划

启动子代理
  → Agent tool，指向 plugin 内置的 java-code-reviewer agent
  → 注入参数表 + 扫描结果 + 增量数据

展示结果
```

### AskUserQuestion 交互映射

| 步骤 | 触发条件 | AskUserQuestion 配置 |
|------|---------|---------------------|
| 选分支 | 分支数 > 1 | options: 分支列表（最多显示 4 个热门分支 + Other） |
| 选类型 | 始终 | options: incremental / stock |
| 选范围 | 始终 | incremental→数字选项（5/10/20/50）；stock→模块列表/full |
| 选模式 | 始终 | options: fast / standard / deep / security |
| 选飞书 | lark-cli 已安装 | options: no / doc / bitable / both |
| 确认 | 始终 | options: 确认执行 / 修改参数 |

每步 1 个 AskUserQuestion 调用，multiSelect: false，确保单选。

### 关键改动（相比当前 SKILL.md）

| 改动点 | 当前 | 改后 |
|--------|------|------|
| 交互方式 | 纯文字列出选项 + 等待输入 | AskUserQuestion tool |
| 脚本路径 | `{baseDir}/scripts/xxx.sh` | `${CLAUDE_PLUGIN_ROOT}/scripts/xxx.sh` |
| 子代理启动 | `sessions_spawn` | `Agent tool`（指向 plugin 内置 agent） |
| 交互约束规则 | 10 条强制性规则含纯文字限制 | 精简为逻辑性规则，删除纯文字交互相关约束 |
| 参考文档引用 | `{baseDir}/references/xxx.md` | `${CLAUDE_PLUGIN_ROOT}/references/xxx.md` |

### 不变的部分

- Quick Start 模式的参数解析逻辑
- 预扫描脚本的执行顺序和参数传递
- 参数验证逻辑
- 错误处理策略

---

## 3. Agent — agents/java-code-reviewer.md

### Frontmatter

```yaml
---
name: java-code-reviewer
description: 执行 Java 代码审查的专属子代理，按维度逐文件评估，生成结构化报告
model: sonnet
effort: high
maxTurns: 50
---
```

### 配置说明

| 字段 | 值 | 理由 |
|------|-----|------|
| model | sonnet | 平衡质量和成本，审查任务适合 |
| effort | high | 审查需要深度分析，不能省 |
| maxTurns | 50 | 大型项目逐文件评估 + 报告生成，需充足轮次 |
| disallowedTools | 不设 | 需要 Read/Glob/Grep/Bash 全量工具 |
| isolation | 不设 | 需要读取项目源码，不能隔离 |

### 内容迁移

从当前 `prompts/java-code-reviewer.md` 直接迁移，保持：

- Agent 人设（15 年经验 Java 架构师）
- 审查原则
- 6 步执行流程（收集文件→分类标注→生成报告→飞书上传→多维表格→输出摘要）
- v5.5 扫描策略（逐文件单次读取多维度评估）
- 15 维度定义（引用 references/review-framework.md）
- 报告格式（引用 references/report-format.md）
- 多维表格 18 字段定义
- MUST/DO/DON'T 规则
- 检查点机制（`/tmp/review-checkpoint-{PROJECT_NAME}.md`）
- 聚合规则和优先级排序

唯一改动：
- 路径引用从 `{baseDir}/references/` 改为 `${CLAUDE_PLUGIN_ROOT}/references/`
- 删除对 OpenClaw `sessions_spawn` 参数格式的引用

---

## 4. Command — commands/java-code-reviewer.md

```markdown
---
description: Java 代码审查 — 启动交互式代码审查流程
---

Invoke the `java-code-reviewer` skill to start a Java code review session.

If the user provides arguments (e.g., project path, --mode, --type), pass them through as `$ARGUMENTS`. If no arguments are provided, the skill will guide the user through interactive configuration using AskUserQuestion.
```

轻量入口，只负责转发到 Skill。参数透传给 Skill 的 `$ARGUMENTS` 处理。

---

## 5. Scripts + References — 不变部分

### scripts/（6 个脚本）

内容完全不变。脚本通过 stdin/stdout 交互，不依赖宿主框架。使用 `/tmp` 缓存，路径硬编码合理。

路径变量替换发生在 SKILL.md 的调用指令中：
- `{baseDir}/scripts/phase1-detect-project.sh` → `${CLAUDE_PLUGIN_ROOT}/scripts/phase1-detect-project.sh`

### references/（3 个参考文档）

| 文件 | 改动 |
|------|------|
| review-framework.md | 不变 |
| report-format.md | 不变 |
| examples.md | 更新对话示例中的交互描述，匹配 AskUserQuestion 选择式风格 |

---

## 改动范围总结

| 组件 | 改动程度 | 说明 |
|------|---------|------|
| `.claude-plugin/plugin.json` | **新增** | Plugin 元数据 |
| `skills/java-code-reviewer/SKILL.md` | **重写交互部分** | 6 步 AskUserQuestion + 路径变量 + 子代理启动方式 |
| `agents/java-code-reviewer.md` | **迁移 + frontmatter** | 内容主体不变，加 model/effort/maxTurns |
| `commands/java-code-reviewer.md` | **新增** | 轻量入口，转发到 skill |
| `scripts/` | **不变** | 路径变量在 SKILL.md 调用时替换 |
| `references/` | **小改** | examples.md 更新交互示例 |

**不需要大重构**。核心审查逻辑全部复用，改动集中在交互层和编排层。

---

## 迁移步骤（概要）

1. 创建 `.claude-plugin/plugin.json`
2. 将当前 `SKILL.md` 迁移到 `skills/java-code-reviewer/SKILL.md`，重写交互为 AskUserQuestion
3. 将 `prompts/java-code-reviewer.md` 迁移到 `agents/java-code-reviewer.md`，加 frontmatter
4. 创建 `commands/java-code-reviewer.md`
5. 更新 `references/examples.md` 交互示例
6. 用 `claude --plugin-dir .` 本地测试
7. 发布到 Marketplace（GitLab 仓库）

---

## 风险与缓解

| 风险 | 缓解 |
|------|------|
| AskUserQuestion 最多 4 个 options | 分支列表可能超 4 个，用 "Other" 选项兜底 + 自由输入 |
| Plugin agent 的 maxTurns 不够 | 设为 50，足够覆盖大型项目；如不够用户可中断后调整 |
| `${CLAUDE_PLUGIN_ROOT}` 路径在开发阶段不同 | 开发时用 `--plugin-dir` 测试，路径自动解析 |
| Marketplace 分发需要 GitLab 支持 | Claude Code marketplace 支持 git 源，不限 GitHub |
