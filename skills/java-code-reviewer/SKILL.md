---
description: Java 代码审查 — 支持增量/存量审查、15维度评估、飞书报告上传
---

## 用途

当用户要求**审查Java代码**、**代码检查**、**发现Bug**、**安全漏洞**、**性能问题**、**潜在风险**、**技术债挖掘**、**安全检查**、**性能优化**、**架构评估**时使用此技能。

**常见触发场景**：
- "帮我审查这个项目"
- "检查一下代码有没有问题"
- "发现潜在Bug和安全漏洞"
- "评估代码质量和架构"
- "挖掘技术债和改进点"
- "代码安全检查"
- "性能优化建议"

## 快速启动模式

适用于**定时任务、自动化脚本、CI/CD 集成**等无需人工交互的场景。用户在调用时通过 `--` 参数直接传入全部审查配置，跳过交互式确认，直接执行审查。

### 模式判定

**检测规则**：如果用户输入中包含 `--mode` 参数，则进入**快速启动模式**；否则进入**交互式模式**（默认）。

### 参数规范

| 参数 | 是否必填 | 取值范围 | 说明 |
|------|----------|----------|------|
| `--mode` | **必填** | `fast` / `standard` / `deep` / `security` | 审查模式 |
| `--type` | **必填** | `incremental` / `stock` | 审查类型（增量/存量） |
| `--scope` | **条件必填** | 见下方规则 | 审查范围 |
| `--branch` | 可选 | 任意分支名 | 审查分支，默认当前分支 |
| `--upload` | 可选 | `no` / `doc` / `bitable` / `both` | 飞书上传选项，默认 `no`（不上传） |

**`--scope` 条件必填规则**：

| `--type` 值 | `--scope` 是否必填 | 合法值 | 默认值 |
|-------------|-------------------|--------|--------|
| `incremental` | **必填** | 正整数（提交次数），如 `5` | 无，缺则报错 |
| `stock` + 多模块项目 | **必填** | `full` 或逗号分隔的 Maven 模块名称，如 `user-service,order-service` | 无，缺则报错 |
| `stock` + 单模块项目 | 可选 | `full`（唯一合法值） | 自动设为 `full` |

### 参数映射

快速启动参数与交互式变量的映射关系：

| 快速启动参数 | 映射变量 | 值转换 |
|-------------|----------|--------|
| `--mode fast` | `REVIEW_MODE=fast` | 直接使用 |
| `--type incremental` | `REVIEW_TYPE=增量审查` | 转换为中文 |
| `--type stock` | `REVIEW_TYPE=存量审查` | 转换为中文 |
| `--scope 5`（incremental） | `REVIEW_SCOPE=最近5次提交` | 转换为中文 |
| `--scope full`（stock） | `REVIEW_SCOPE=全量代码` | 转换为中文 |
| `--scope user-service,order-service` | `REVIEW_SCOPE=user-service,order-service` | 直接使用 |
| `--branch develop` | `TARGET_BRANCH=develop` | 直接使用 |
| `--upload no` | `FEISHU_UPLOAD_OPTION=仅显示报告` | 转换为中文 |
| `--upload doc` | `FEISHU_UPLOAD_OPTION=上传到云文档` | 转换为中文 |
| `--upload bitable` | `FEISHU_UPLOAD_OPTION=上传到多维表格` | 转换为中文 |
| `--upload both` | `FEISHU_UPLOAD_OPTION=同时上传两者` | 转换为中文 |
| 未提供 `--upload` | `FEISHU_UPLOAD_OPTION=仅显示报告` | 使用默认值 |

### 校验规则

1. **必填参数校验**：`--mode` 和 `--type` 必须存在，缺失任何一个立即报错终止
2. **参数值校验**：每个参数的值必须在合法取值范围内，不合法立即报错
3. **条件必填校验**：根据 `--type` 的值校验 `--scope` 是否缺失
4. **分支存在性校验**：`--branch` 指定的分支如果不存在，报错并列出可用分支
5. **模块存在性校验**：当 `--type stock --scope` 为具体模块名（非 `full`）时，校验每个模块是否存在于预扫描结果的 `MODULE:` 行中；不存在的模块报错并列出可用模块
6. **lark-cli 校验**：如果 `--upload` 不是 `no` 但未检测到 lark-cli，警告并降级为 `仅显示报告`

**校验失败时的输出格式**：

```
❌ 快速启动参数校验失败

缺少必填参数：
  - --mode: 审查模式（fast/standard/deep/security）
  - --scope: 审查范围（增量审查时为提交次数，存量审查多模块时为 Maven 模块名称）

正确格式示例：
  帮我审查 /path/to/project --mode fast --type incremental --scope 5
  帮我审查 /path/to/project --mode standard --type stock --scope full --upload doc

请补充缺失参数后重新调用。
```

### 快速启动模式下的执行流程

```
预扫描阶段                  → 正常执行（项目识别 + 分支探测 + 项目扫描 + lark-cli 检测）
参数校验                    → 校验所有必填参数，失败则终止
交互式确认                  → ⏭️ 完全跳过
代码审查阶段：代码审查            → 直接执行（不展示执行计划确认）
```

**启动提示（快速启动模式专用）**：

校验通过后，输出以下提示后立即调用子agent：

```
🚀 快速启动模式 — 正在启动独立代码审查子代理...

📋 任务配置：{REVIEW_MODE} 模式 · {REVIEW_TYPE} · {REVIEW_SCOPE}
🌿 审查分支：{TARGET_BRANCH 或 CURRENT_BRANCH}
📤 飞书上传：{FEISHU_UPLOAD_OPTION}
⏱️ 预估耗时：{预估时间}
📌 子代理将独立执行完整审查流程，完成后自动返回结果。
```

> **注意**：快速启动模式不输出「💡 温馨提示」和「执行计划确认」，因为调用方是自动化脚本/定时任务。

### 快速启动调用示例

```
# 增量审查 — 最近5次提交，快速扫雷
帮我审查 /path/to/project --mode fast --type incremental --scope 5

# 存量审查 — 全量代码，标准模式，上传飞书云文档
帮我审查 /path/to/project --mode standard --type stock --scope full --upload doc

# 存量审查 — 指定模块，深度模式，同时上传飞书两者
帮我审查 /path/to/project --mode deep --type stock --scope user-service,order-service --upload both

# Git 仓库 + 指定分支 + 增量审查
帮我审查 https://github.com/org/repo.git --mode standard --type incremental --scope 3 --branch develop --upload bitable

# 定时任务场景（最简形式，增量快速扫雷，仅显示报告）
帮我审查 /path/to/project --mode fast --type incremental --scope 1
```

---

## 工作流程

### 模式判定（首先执行）

**检测用户输入中是否包含 `--mode` 参数**：

| 检测结果 | 执行路径 |
|----------|----------|
| 包含 `--mode` | → **快速启动模式**：执行预扫描 → 参数校验 → 直接跳到代码审查阶段 |
| 不包含 `--mode` | → **交互式模式**（默认）：执行预扫描 → 交互式确认（逐步确认）→ 代码审查阶段 |

---

### 预扫描阶段（自动执行，在第一次用户交互前全部完成）

**目标**：在用户等待期间，一次性完成项目识别、分支探测、项目扫描和 lark-cli 检测，收集所有后续交互所需的环境数据。

**⚠️ 核心原则**：此阶段所有脚本按顺序自动执行，**不与用户交互**，全部完成后统一输出预扫描摘要，然后进入交互阶段。

#### 执行步骤

**按以下顺序依次执行 4 个脚本**：

**步骤 1：项目识别**

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/phase1-detect-project.sh "<用户输入的路径>"
```

脚本输出：
- `PROJECT_DIR=<项目绝对路径>`
- `PROJECT_SOURCE=local|git-cache`

**步骤 2：分支探测**

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/phase2-detect-branches.sh "$PROJECT_DIR"
```

脚本输出：
- `IS_GIT_REPO=true/false`
- `CURRENT_BRANCH=<分支名>`
- `BRANCH: 分支名 | 提交日期 | 提交信息`（本地分支列表）
- `BRANCH_REMOTE: origin/分支名 | 提交日期 | 提交信息`（远程分支列表）

**步骤 3：项目扫描**

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/phase3-project-scan.sh "$PROJECT_DIR"
```

脚本输出：
- `PROJECT_TYPE=maven-single|maven-multi|gradle-single|gradle-multi|unknown`
- `MODULE:模块名|相对路径|Java文件数|代码行数`
- 项目概况和模块树的可视化展示

**步骤 4：lark-cli 检测**

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/phase4-detect-lark-plugin.sh
```

脚本输出：
- `LARK_PLUGIN_INSTALLED=true|false`
- `LARK_PLUGIN_NAME=lark-cli`（仅当 `LARK_PLUGIN_INSTALLED=true` 时输出）

> **说明**：飞书上传功能依赖 `lark-cli` 命令行工具及配套的 `lark-doc`（云文档）和 `lark-base`（多维表格）两个 skill。此处仅检测 `lark-cli` 是否安装，子 agent 执行上传时会自动调用对应的 skill。

#### 预扫描摘要输出

**4 个脚本全部执行完成后，必须向用户输出以下统一摘要**（这是预扫描阶段的唯一输出，之后进入交互阶段）：

```
🔍 预扫描完成

📂 项目：{项目名称}
- 来源：{PROJECT_SOURCE 对应展示，本地路径 / Git仓库缓存}
- 路径：{PROJECT_DIR}
- 类型：{PROJECT_TYPE 展示名，如 Maven 单模块 / Gradle 多模块 / 未知}

🌿 Git：{IS_GIT_REPO=true 时显示}
- 当前分支：{CURRENT_BRANCH}
- 可用分支：{分支数量} 个{分支数 > 1 时显示"（需选择）"，否则显示"（自动使用）"}

📊 规模：
- Java 文件：{N} 个
- 代码行数：{M} 行
{多模块时追加以下行}
- 模块数量：{K} 个
- 模块列表：{模块1名称}({n1}类), {模块2名称}({n2}类), ...

🔌 lark-cli：{LARK_PLUGIN_INSTALLED=true 时显示 "✅ lark-cli 已安装" / false 时显示 "⚠️ 未安装"}
```

> **注意**：
> - 预扫描摘要是所有环境数据的统一展示，让用户在交互前对项目有全面了解
> - 分支列表解析说明：`BRANCH:` 行为本地分支，`BRANCH_REMOTE:` 行为远程分支（需去掉 `origin/` 前缀展示）
> - 模块结构解析说明：`MODULE:` 行格式为 `MODULE:模块名|相对路径|Java文件数|代码行数`，主agent在交互步骤3（方案B）动态生成模块选项时，应解析这些行提取模块信息

---

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

切换失败时的处理：
1. 脚本输出警告，继续使用当前分支
2. 在执行计划确认环节（步骤6）中明确显示实际使用的分支

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

变量赋值：
- 全量代码 → REVIEW_SCOPE=全量代码
- 具体模块 → REVIEW_SCOPE=模块路径（逗号分隔）
- 自定义数字 → REVIEW_SCOPE=最近N次提交

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

确认前展示完整执行计划：
```
📋 执行计划：
- 项目路径：{PROJECT_DIR}
- 项目类型：{PROJECT_TYPE}
- 审查分支：{CURRENT_BRANCH 或 TARGET_BRANCH}（仅 Git 项目显示）
- 审查类型：{REVIEW_TYPE}
- 审查范围：{REVIEW_SCOPE}
- 审查模式：{REVIEW_MODE}
- 启用维度：{根据模式 × 维度矩阵列出具体维度名称}
- 飞书上传：{FEISHU_UPLOAD_OPTION}
```

使用 AskUserQuestion，配置如下：
- question: "确认以上执行计划后开始审查"
- header: "确认执行"
- options:
  - label: "确认执行"
    description: "按以上配置开始审查"
  - label: "取消"
    description: "取消本次审查"
- multiSelect: false

用户选择"确认执行"后进入代码审查阶段；选择"取消"则终止流程。

#### 步骤6确认后的启动提示

用户确认后、调用子代理之前，输出以下格式的提示信息：

```
🚀 正在启动独立代码审查子代理...

📋 任务配置：{REVIEW_MODE} 模式 · {REVIEW_TYPE} · {REVIEW_SCOPE}
⏱️ 预估耗时：{预估时间}
📌 子代理将独立执行完整审查流程，完成后自动返回结果。

{FEISHU_UPLOAD_OPTION 不是「仅显示报告」/「lark-cli未安装」时，追加以下行}
📤 审查完成后将自动上传到飞书（{FEISHU_UPLOAD_OPTION}），无需手动操作。

💡 温馨提示：审查期间您可以继续使用 Claude Code 进行其他操作。
```

**预估时间参考**（根据 REVIEW_MODE + 项目规模估算）：

| 模式 | 小型项目（<50 类） | 中型项目（50-200 类） | 大型项目（>200 类） |
|------|:---:|:---:|:---:|
| fast | 2-3 分钟 | 3-5 分钟 | 5-8 分钟 |
| standard | 5-8 分钟 | 8-15 分钟 | 15-25 分钟 |
| deep | 10-15 分钟 | 15-30 分钟 | 30-60 分钟 |
| security | 5-10 分钟 | 10-20 分钟 | 20-35 分钟 |

---

### 代码审查阶段：代码审查（使用子agent执行）

**目标**：将用户确认的审查配置和项目信息作为参数注入子agent prompt，由子agent独立完成代码审查和飞书上传（可选），最后将结果汇总返回主agent。

#### 子代理调用方式

使用 Agent tool 启动 plugin 内置的 `java-code-reviewer` 子代理：

- description: "执行 Java 代码审查"
- prompt: 注入审查参数表 + 项目概况 + 增量数据 + 执行指令

参数注入格式：

```
## 审查任务参数（外部注入，请直接使用，无需再次确认）

| 参数 | 值 |
|------|-----|
| 项目路径 | {PROJECT_DIR} |
| 项目名称 | {PROJECT_NAME} |
| 项目类型 | {PROJECT_TYPE} |
| 审查类型 | {REVIEW_TYPE} |
| 审查范围 | {REVIEW_SCOPE} |
| 审查模式 | {REVIEW_MODE} |
| 飞书上传选项 | {FEISHU_UPLOAD_OPTION} |
| 审查文件数量 | {REVIEW_FILE_COUNT} |
| 审查代码行数 | {REVIEW_LINE_COUNT} |

### 项目概况（预扫描结果）
{PROJECT_SCAN_RESULT}

### 增量提交记录（仅增量审查时提供）
{GIT_LOG_OUTPUT}

### 变更文件列表（仅增量审查时提供）
{CHANGED_FILES_OUTPUT}

### 变更统计概览（仅增量审查时提供）
{DIFF_STATS_OUTPUT}

请基于以上审查参数，立即开始执行代码审查。不要进行任何用户交互或询问，直接从代码审查开始执行。
```

不再需要手动读取 agent 提示词文件——Agent tool 会自动加载 agents/java-code-reviewer.md 的完整内容。仅需在 prompt 中传入审查参数和辅助数据。

#### 参数来源说明

| 变量名 | 来源 | 示例值 |
|--------|------|--------|
| `PROJECT_DIR` | 预扫描项目识别输出 | `/tmp/{仓库名}` 或本地路径 |
| `PROJECT_SOURCE` | 预扫描项目识别输出 | `local` / `git-cache` |
| `PROJECT_NAME` | `basename "$PROJECT_DIR"` 自动提取 | `spring-ai-agent-utils` |
| `PROJECT_TYPE` | 预扫描项目扫描输出 | `maven-single` / `maven-multi` / `gradle-single` / `gradle-multi` / `unknown` |
| `REVIEW_TYPE` | 交互步骤2用户选择 / 快速启动 `--type` | `增量审查` / `存量审查` |
| `REVIEW_SCOPE` | 交互步骤3用户选择 / 快速启动 `--scope` | `最近5次提交` / `全量代码` / `user-service,order-service` |
| `REVIEW_MODE` | 交互步骤4用户选择 / 快速启动 `--mode` | `fast` / `standard` / `deep` / `security` |
| `FEISHU_UPLOAD_OPTION` | 交互步骤5用户选择 / 快速启动 `--upload` | `仅显示报告` / `上传到云文档` / `上传到多维表格` / `同时上传两者` / `lark-cli未安装` |
| `PROJECT_SCAN_RESULT` | 预扫描完整输出 | 项目概况、模块结构的原始输出 |
| `REVIEW_FILE_COUNT` | 从 `PROJECT_SCAN_RESULT` 解析 | 本次审查涉及的 Java 文件数量（如 `76`） |
| `REVIEW_LINE_COUNT` | 从 `PROJECT_SCAN_RESULT` 解析 | 本次审查涉及的代码总行数（如 `16637`） |
| `GIT_LOG_OUTPUT` | 条件生成（见下方） | `git log --oneline -N` 的输出 |
| `CHANGED_FILES_OUTPUT` | 条件生成（仅增量审查） | `git diff --name-only` 的输出，变更文件路径列表 |
| `DIFF_STATS_OUTPUT` | 条件生成（仅增量审查） | `git diff --stat` 的输出，各文件改动行数统计 |

#### 增量审查预处理（仅增量审查时执行）

在调用子agent之前，先执行以下命令获取提交记录、变更文件列表和变更统计。**注意**：脚本会自动处理提交数不足 N 的情况，防止 `HEAD~N` 越界。

**执行脚本**：
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/phase5-prepare-incremental.sh "$PROJECT_DIR" {N}
```

脚本输出（三个部分用 `# ===` 分隔）：
1. `# === 提交记录 ===` 之后的内容 → `GIT_LOG_OUTPUT`
2. `# === 变更文件列表 ===` 之后的内容 → `CHANGED_FILES_OUTPUT`
3. `# === 变更统计 ===` 之后的内容 → `DIFF_STATS_OUTPUT`

**主 Agent 需解析脚本输出，分别提取三个部分作为独立变量注入子 Agent**。

**异常情况处理**：
- 如果 `CHANGED_FILES_OUTPUT` 为空（没有变更文件），主agent应：
  1. 告知用户：选择的提交范围内没有变更文件
  2. 询问是否调整提交次数或切换到存量审查
  3. 不应调用子agent处理空文件列表

#### 子agent返回结果

子agent执行完成后，根据飞书上传选项返回不同格式的结果，主agent需将此结果展示给用户。

**已上传飞书时**（简化汇总 + 飞书链接）：

```
✅ 代码审查已完成！⏱️ 耗时 {X} 分 {Y} 秒

📊 审查结果：{问题总数} 个问题（P0: {n} / P1: {n} / P2: {n} / P3: {n} / 待确认: {n}）

🔥 最高风险项：
  - P0-1: {问题一句话描述} — {位置}
  （最多列 5 条）

📄 审查报告：{链接}
📋 问题清单：{链接}

💡 建议：{一句话关键建议}
👉 详细报告请点击上方飞书链接查看。
```

> **耗时计算**：`当前时间 - START_TIME`，格式为 `X 分 Y 秒`（不足1分钟时只显示秒）。

**未上传飞书时**（完整报告）：子agent会将第三步生成的完整审查报告原样输出，包含所有章节（审查配置快照、执行摘要、各级别问题详情、修复优先级、总结等）。主agent在展示结果时，需在报告末尾追加耗时汇总：

```
✅ 代码审查已完成！⏱️ 耗时 {X} 分 {Y} 秒

📊 审查结果：{从报告中提取问题总数}
💡 建议：{从报告中提取一句话关键建议}
```

**异常降级**：如果飞书上传步骤失败，子agent会降级为输出完整报告，并说明失败原因。主agent应将结果直接展示给用户。


---

## 重要规则

### 强制规则

> **快速启动模式豁免**：当检测到 `--mode` 参数进入快速启动模式时，以下标有 ⚡ 的规则**不适用**，其余规则仍然生效。

1. **输入校验**：用户自定义输入必须与当前问题相关且合理，无效输入需提示重新选择，每步最多重试 3 次
2. **执行前强制确认** ⚡：必须展示执行计划并等待用户确认，**不能跳过**
3. **三个核心选项必须全部明确**：审查类型 + 审查范围 + 审查模式，缺一不可
4. **强制交互流程** ⚡：无论用户是否提供参数，都必须依次通过 AskUserQuestion 逐步引导用户完成所有步骤
5. **强制中文输出**：所有交互和报告都必须使用中文
6. **最终确认前零审查动作**：不得在用户确认前执行任何代码扫描
7. **快速启动参数完整性**：快速启动模式下，`--mode` 和 `--type` 必须同时存在，`--scope` 根据条件必填规则校验，缺少任一必填参数立即报错终止，**不允许降级为交互式模式**

### 条件步骤规则

1. **单模块项目自动跳过步骤3**：如果 `PROJECT_TYPE` 为 `maven-single` 或 `gradle-single` 且步骤2选择了「存量审查」，步骤3（选择审查范围）必须跳过，自动设 `REVIEW_SCOPE=全量代码`
2. **lark-cli 检测**：预扫描阶段检测 lark-cli 是否安装，根据结果决定是否执行步骤5（飞书上传选项）；未安装时自动设 `FEISHU_UPLOAD_OPTION=lark-cli未安装`
3. **飞书上传执行**：子agent根据 `FEISHU_UPLOAD_OPTION` 参数执行对应上传动作。上传飞书云文档必须使用 `lark-doc` skill，上传多维表格必须使用 `lark-base` skill，均通过 `lark-cli` 命令行工具执行
4. **Git 分支选择**：步骤1仅在项目为 Git 仓库且存在多个活跃分支时执行；非 Git 项目或单分支项目自动跳过

---

## 错误处理

如果用户输入无法识别或与当前问题无关：
- 输出 `⚠️ 输入无效` 提示，重新展示当前步骤的选项文本
- 每个步骤最多重试 3 次
- 超过 3 次仍无效时，输出 `❌ 多次输入无效，已终止本次审查` 并结束流程

---

## 示例对话

完整的示例对话详见 `${CLAUDE_PLUGIN_ROOT}/references/examples.md`。
