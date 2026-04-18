# Java Code Reviewer Skill

企业级 Java 代码审查专用技能，支持 15 个维度全面审查，4 种审查模式，增量/存量两种审查类型，支持交互式和快速启动两种使用方式。

## 安装

### 前置条件

- OpenClaw 已安装并运行
- Bash 3.0+ 环境
- 系统已安装 `git` 命令
- `jq`（可选，用于飞书插件检测的 JSON 解析）

### 安装步骤

将本技能目录放入 OpenClaw 的 skills 目录下即可：

```bash
# 方式一：直接复制到 skills 目录
cp -r java-code-reviewer/ ~/.openclaw/workspace-coding/skills/

# 方式二：如果是 Git 仓库，克隆到 skills 目录
git clone <repo-url> ~/.openclaw/workspace-coding/skills/java-code-reviewer
```

确保目录结构如下（`SKILL.md` 必须位于技能根目录）：

```
~/.openclaw/workspace-coding/skills/java-code-reviewer/
├── SKILL.md                      # 主技能定义（OpenClaw 自动加载此文件）
├── README.md                     # 本文件
├── prompts/
│   └── java-code-reviewer.md     # 子 Agent 审查提示词
├── scripts/                      # 各阶段执行脚本
│   ├── phase1-detect-project.sh
│   ├── phase2-detect-branches.sh
│   ├── phase2-switch-branch.sh
│   ├── phase3-project-scan.sh
│   ├── phase4-detect-lark-plugin.sh
│   └── phase6-prepare-incremental.sh
└── references/
    └── review-framework.md       # 15维度审查框架手册
```

### 验证安装

重启 OpenClaw 或等待技能自动热加载后，在对话中发送：

```
帮我审查这个项目 /path/to/your/java/project
```

如果技能正确加载，OpenClaw 会自动识别并进入审查流程。

### 可选：飞书插件安装

如需使用飞书上传功能（云文档/多维表格），需安装以下任一飞书插件：

| 插件名 | 说明 |
|--------|------|
| `openclaw-lark` | 飞书官方插件 |
| `feishu` | openclaw 飞书社区插件 |
| `openclaw-wkzj` | 企业内部插件 |

三者安装任一即可，未安装时不影响审查功能，仅无法上传飞书。

---

## 使用方式

技能支持两种使用模式：**交互式模式**（默认）和**快速启动模式**（适合自动化）。

### 模式一：交互式（默认）

直接告诉 OpenClaw 要审查的项目，技能会逐步引导你选择配置：

```
帮我审查这个项目 /path/to/project
```

交互流程：
1. 自动识别项目类型、Git 分支、项目结构
2. 逐步确认：审查类型 → 审查范围 → 审查模式 → 飞书上传 → 执行计划确认
3. 确认后启动子 Agent 执行审查

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
| 6 | 性能 | 并发安全、线程池、算法复杂度、限流降级 |
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

# 飞书插件检测
bash scripts/phase4-detect-lark-plugin.sh
```

## 工作流程

```
用户触发 → 阶段一（项目识别）→ 阶段二（分支探测）→ 阶段三（预扫描）→ 阶段四（飞书插件检测）
                                                                              ↓
                                                           ┌─────────────────┴──────────────────┐
                                                           │ 包含 --mode？                      │
                                                           ├─ 是 → 快速启动：参数校验 → 阶段六 │
                                                           └─ 否 → 阶段五（交互确认）→ 阶段六  │
                                                           └────────────────────────────────────┘
                                                                              ↓
                                                              阶段六：子 Agent 执行审查 → 返回结果
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
1. 审查框架：编辑 `references/review-framework.md`
2. Agent 提示词：编辑 `prompts/java-code-reviewer.md`
3. 确保模式×维度矩阵在两个文件中保持一致

## License

MIT
