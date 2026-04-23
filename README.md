# Java Code Reviewer Skill

企业级 Java 代码审查专用技能，支持 15 个维度全面审查，4 种审查模式，增量/存量两种审查类型，支持交互式和快速启动两种使用方式。

## 特性

- **15 维度全面审查**：正确性、代码质量、安全、性能、架构等
- **4 种审查模式**：fast（快速扫雷）、standard（日常推荐）、deep（大版本上线）、security（安全专项）
- **2 种审查类型**：增量审查（最近 N 次提交）、存量审查（全量/指定模块）
- **2 种使用模式**：交互式（逐步引导）、快速启动（自动化/CI/CD）
- **飞书集成**：审查报告上传云文档、问题清单录入多维表格（可选，依赖 lark-cli）
- **纯 Bash 实现**：无 Python 依赖，兼容 macOS/Linux 标准环境

## 快速安装

### 前置条件

- OpenClaw 已安装并运行
- Bash 3.0+ 环境（macOS / Linux）
- 系统已安装 `git` 命令

### 第一步：安装 Skill

将本技能目录放入 coding agent 的 skills 目录下：

```bash
# 方式一：Git 克隆（推荐）
git clone <repo-url> ~/.openclaw/workspace-coding/skills/java-code-reviewer

# 方式二：直接复制
cp -r java-code-reviewer/ ~/.openclaw/workspace-coding/skills/
```

### 第二步：一键配置子 Agent

运行内置的 setup 脚本，自动完成所有配置：

```bash
bash ~/.openclaw/workspace-coding/skills/java-code-reviewer/scripts/setup-subagent.sh
```

该脚本会自动完成以下操作：

| 步骤 | 操作 | 说明 |
|------|------|------|
| 1 | 创建 workspace 目录 | `~/.openclaw/workspace-java-code-reviewer/` |
| 2 | 生成 AGENTS.md | 从模板 `prompts/java-code-reviewer.md` 复制并替换 `{baseDir}` 为实际路径 |
| 3 | 复制 references/ | 审查框架、报告格式、多维表格字段定义等 |
| 4 | 注册子 Agent | `openclaw agents add java-code-reviewer` |
| 5 | 设置身份 | 名称"Java代码审查"，emoji 🛡️ |
| 6 | 配置委派权限 | 在 `openclaw.json` 中添加 `allowAgents: ["java-code-reviewer"]` |

自定义 workspace 路径：

```bash
bash scripts/setup-subagent.sh /custom/path/to/workspace
```

### 第三步：验证

重启 OpenClaw 后，在 coding agent 对话中发送：

```
帮我审查这个项目 /path/to/your/java/project
```

如果技能正确加载，会进入审查流程。

### 可选：lark-cli 安装

如需使用飞书上传功能（云文档/多维表格），需安装 `lark-cli`：

```bash
npm install -g @larksuite/cli
npx skills add larksuite/cli -y -g
lark-cli config init
lark-cli auth login --recommend
```

未安装 lark-cli 不影响审查功能，仅无法上传飞书。详细安装指南见 [lark-cli README](https://github.com/larksuite/cli/blob/main/README.zh.md)。

---

## 给 OpenClaw 的配置指南

> **使用方式**：将本 README 发给 OpenClaw（或说"按 README 配置 java-code-reviewer"），OpenClaw 按以下步骤执行即可完成全部配置。

本技能由两部分组成，需要分别部署：

**Part 1 — Skill（主 Agent 加载）**：`SKILL.md` 定义审查工作流，放在 coding agent 的 skills 目录下。

**Part 2 — 子 Agent（独立 workspace）**：`AGENTS.md` + `references/` 放在独立 workspace 下，通过 `openclaw agents add` 注册，主 Agent 通过 `sessions_spawn` 的 `agentId` 参数委派任务。

### 配置步骤

**步骤 1**：确认 skill 已安装在 coding agent 的 skills 目录下：
```
~/.openclaw/workspace-coding/skills/java-code-reviewer/
```

如果尚未安装，从 Git 克隆或复制到该目录。

**步骤 2**：运行 setup 脚本一键配置子 Agent：
```bash
bash ~/.openclaw/workspace-coding/skills/java-code-reviewer/scripts/setup-subagent.sh
```

脚本会自动：创建 workspace → 从模板生成 AGENTS.md（替换路径占位符）→ 复制 references/ → 注册 agent → 设置身份 → 配置 allowAgents。

**步骤 3**：验证配置：
```bash
openclaw agents list
# 应看到 java-code-reviewer agent
```

**步骤 4**：重启 OpenClaw 后即可使用。

### 架构说明

```
主 Agent (coding)
  │ 加载 SKILL.md（skills/java-code-reviewer/SKILL.md）
  │ 预扫描 → 交互确认 → 收集审查变量
  │
  │ sessions_spawn({
  │   task: "审查参数...",
  │   agentId: "java-code-reviewer",    ← 指定子 Agent
  │   mode: "run"
  │ })
  │
  ↓
子 Agent (java-code-reviewer)
  │ 自动加载 AGENTS.md + references/
  │ 执行代码审查 → 生成报告 → 上传飞书(可选)
  │
  ↓ 完成后自动 announce 结果回主 Agent
主 Agent 展示结果给用户
```

### 关键文件

| 文件 | 位置 | 作用 |
|------|------|------|
| SKILL.md | skills/java-code-reviewer/ | 主技能定义（工作流、交互规范、子 Agent 调用方式） |
| prompts/java-code-reviewer.md | skills/java-code-reviewer/prompts/ | 子 Agent 提示词模板（`{baseDir}` 占位符） |
| AGENTS.md | workspace-java-code-reviewer/ | 子 Agent 提示词（setup 脚本从模板生成，替换为绝对路径） |
| references/ | 两个目录都有 | 审查框架、报告格式、多维表格字段定义 |
| scripts/setup-subagent.sh | skills/java-code-reviewer/scripts/ | 一键配置脚本 |

---

## 使用方式

技能支持两种使用模式：**交互式模式**（默认）和**快速启动模式**（适合自动化）。

### 模式一：交互式（默认）

直接告诉 OpenClaw 要审查的项目，技能会逐步引导你选择配置：

```
帮我审查这个项目 /path/to/project
```

交互流程：
1. **预扫描**（自动）：项目识别 → 分支探测 → 项目扫描 → lark-cli 检测
2. **逐步确认**（严格单步交互）：
   - 选择分支（条件步骤，仅多分支时询问）
   - 选择审查类型（增量/存量）
   - 选择审查范围（条件步骤，取决于审查类型和项目类型）
   - 选择审查模式（fast/standard/deep/security）
   - 选择飞书上传选项（条件步骤，仅 lark-cli 已安装时询问）
   - 确认执行计划
3. 确认后启动子 Agent 执行审查

> **交互规则**：每个步骤单独询问，不会将多个选项（如审查范围和审查模式）合并在一个回复中。所有选项以纯文本形式展示，等待用户自由输入。

### 模式二：快速启动

通过 `--` 参数直接传入全部配置，跳过交互，适合定时任务和 CI/CD：

```
帮我审查 /path/to/project --mode <模式> --type <类型> --scope <范围>
```

#### 参数说明

| 参数 | 必填 | 取值 | 说明 |
|------|------|------|------|
| `--mode` | 必填 | `fast` / `standard` / `deep` / `security` | 审查模式 |
| `--type` | 必填 | `incremental` / `stock` | 增量审查 / 存量审查 |
| `--scope` | 条件必填 | 正整数 或 `full` 或模块名 | 增量时为提交次数；存量多模块时为模块名；存量单模块可省略 |
| `--branch` | 可选 | 分支名 | 审查分支，默认当前分支 |
| `--upload` | 可选 | `no` / `doc` / `bitable` / `both` | 飞书上传，默认 `no` |

#### 快速启动示例

```bash
# 最简用法：增量快速扫雷，仅显示报告
帮我审查 /path/to/project --mode fast --type incremental --scope 5

# 存量全量审查，标准模式，上传飞书云文档
帮我审查 /path/to/project --mode standard --type stock --scope full --upload doc

# 指定模块存量审查，深度模式，同时上传云文档+多维表格
帮我审查 /path/to/project --mode deep --type stock --scope user-service,order-service --upload both

# Git 仓库 + 指定分支
帮我审查 https://github.com/org/repo.git --mode standard --type incremental --scope 3 --branch develop --upload bitable

# 定时任务场景（最简形式）
帮我审查 /path/to/project --mode fast --type incremental --scope 1
```

> **注意**：快速启动模式下，必填参数缺失会直接报错终止，不会降级为交互式模式。

---

## 审查模式

| 模式 | 覆盖维度 | 适用场景 | 预估耗时 |
|------|---------|---------|---------|
| `fast` | 正确性、事务与配置安全、资源管理、P0级安全 | PR 合并前快速卡口 | 2-8 分钟 |
| `standard` | 1-11、14(部分)、15(部分) | 日常迭代上线前推荐 | 5-25 分钟 |
| `deep` | 全量 1-15 维度 | 大版本上线前、重要模块 | 10-60 分钟 |
| `security` | 安全核心 + 强相关交叉维度 | 安全合规检查、安全加固 | 5-35 分钟 |

## 15 个审查维度

| # | 维度 | 说明 |
|---|------|------|
| 1 | 正确性 | Bug、NPE、边界条件、异常处理、并发正确性 |
| 2 | 代码质量 | 单一职责、DRY、复杂度、命名、代码异味 |
| 3 | Spring Boot 规范 | 分层职责、依赖注入、事务、配置安全 |
| 4 | 数据库/MyBatis | N+1、SQL注入、参数绑定、批量操作、数据一致性 |
| 5 | 安全 | SQL注入、越权、反序列化、认证授权、依赖安全 |
| 6 | 性能 | 并发安全、线程池、算法复杂度、限流降额 |
| 7 | 资源管理 | 连接关闭、线程泄露、OOM风险 |
| 8 | 日志/可观测性 | 日志级别、敏感信息、健康检查 |
| 9 | 测试质量 | 覆盖率、核心逻辑测试、Mock使用 |
| 10 | 技术债 | 临时代码、过时API、设计模式 |
| 11 | 架构 | 模块化、耦合度、全局错误处理 |
| 12 | 分布式系统 | 分布式事务、分布式锁、服务间通信、熔断限流 |
| 13 | 消息队列 | 消息可靠性、幂等性、顺序性、死信队列 |
| 14 | 缓存 | 穿透/击穿/雪崩、一致性、Redis专项 |
| 15 | API 设计 | RESTful规范、版本管理、错误处理、分页 |

## 飞书多维表格

审查问题可录入飞书多维表格，包含 18 个字段：

- **基础字段（15个）**：问题编号、严重级别、所属维度、技术栈、问题描述、位置、置信度、证据、影响、修复建议、修复状态、审查模式、审查日期、负责人、备注
- **预留修复字段（3个）**：修复时间、修复分支、修复人（初始留空，供后续修复流程更新）

## 脚本说明

所有脚本位于 `scripts/` 目录，可独立运行测试：

```bash
# 项目识别
bash scripts/phase1-detect-project.sh "/path/to/project"

# 分支探测
bash scripts/phase2-detect-branches.sh "/path/to/project"

# 项目预扫描
bash scripts/phase3-project-scan.sh "/path/to/project"

# lark-cli 检测
bash scripts/phase4-detect-lark-plugin.sh

# 子 Agent 一键配置
bash scripts/setup-subagent.sh
```

## 工作流程

```
用户触发
  ↓
模式判定（检测 --mode 参数）
  ├─ 交互式模式（默认）            ├─ 快速启动模式
  ↓                                ↓
预扫描（4脚本顺序执行）            预扫描（4脚本顺序执行）
  ↓                                ↓
交互式确认（6步，严格单步）         参数校验
  ↓                                ↓
执行计划确认                        直接执行
  └──────────┬─────────────────────┘
             ↓
      代码审查阶段：子 Agent 执行审查
             ↓
      飞书上传（可选）
             ↓
      展示审查结果
```

## 开发与维护

### 修改脚本逻辑
1. 编辑 `scripts/` 下对应的 `.sh` 文件
2. 独立测试验证
3. 无需修改 SKILL.md（脚本通过路径引用）

### 修改审查流程
1. 编辑 `SKILL.md` 中对应阶段的描述
2. 如需新脚本，在 `scripts/` 目录创建

### 修改审查维度或提示词

本项目采用双目录架构，修改时需同步两处：

**Skill 目录**（主 Agent 加载）：
```
~/.openclaw/workspace-coding/skills/java-code-reviewer/
├── SKILL.md                          # 主技能定义
├── scripts/                          # 预扫描脚本 + setup 脚本
├── prompts/java-code-reviewer.md     # 子 Agent 提示词模板（{baseDir} 占位符）
└── references/                       # 审查框架、报告格式等参考文档
```

**子 Agent Workspace**（由 setup 脚本自动生成）：
```
~/.openclaw/workspace-java-code-reviewer/
├── AGENTS.md                         # 子 Agent 提示词（从模板生成，绝对路径）
└── references/                       # 从 skill 目录复制
```

**同步规则**：
- 修改审查框架 → 编辑 `references/`，然后重新运行 `setup-subagent.sh` 或手动同步
- 修改提示词 → 编辑 `prompts/java-code-reviewer.md`，然后重新运行 `setup-subagent.sh`

## License

MIT
