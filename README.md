# Java Code Reviewer Skill

企业级 Java 代码审查专用技能，支持 15 个维度全面审查，4 种审查模式，增量/全量两种审查类型。

## 目录结构

```
java-code-reviewer/
├── SKILL.md                      # 主技能定义文档
├── README.md                     # 项目说明文档
├── .gitignore                    # Git 忽略规则
├── prompts/                      # 子 Agent 提示词
│   └── java-code-reviewer.md     # 审查执行 Agent 的提示词（引用审查手册）
├── scripts/                      # 各阶段执行脚本
│   ├── README.md                 # 脚本使用说明
│   ├── phase1-detect-project.sh  # 项目识别与准备
│   ├── phase2-detect-branches.sh # 分支探测
│   ├── phase2-switch-branch.sh   # 分支切换
│   ├── phase3-project-scan.sh    # 项目预扫描
│   ├── phase4-detect-lark-plugin.sh # 飞书插件检测
│   └── phase6-prepare-incremental.sh # 增量审查预处理
└── references/                   # 参考文档（独立维护）
    ├── README.md                 # 参考文档说明
    └── review-framework.md       # 15维度审查框架手册
```

## 核心特性

- **15维度全面审查**：正确性、代码质量、Spring Boot 规范、数据库/MyBatis、安全、性能、资源管理、日志、测试、技术债、架构、分布式系统、消息队列、缓存、API 设计
- **4种审查模式**：
  - `fast`：快速扫雷，聚焦关键风险（5分钟内）
  - `standard`：标准审查，日常迭代推荐
  - `deep`：深度审查，全量15维度
  - `security`：安全专项，聚焦安全核心
- **2种审查类型**：
  - `增量审查`：审查最近N次提交的变更
  - `存量审查`：审查指定模块或全量代码
- **智能项目识别**：自动识别本地路径或Git仓库URL，支持Maven/Gradle项目自动检测
- **脚本化工作流**：各阶段检测脚本独立维护（`scripts/`目录），可复用和测试
- **飞书多维表格**：支持将审查问题录入飞书多维表格（18个字段，含3个预留修复字段），支持按技术栈筛选和修复进度跟踪
- **纯Bash实现**：无Python依赖，兼容Linux标准环境

## 工作流程

### 阶段一：项目识别与准备
自动检测输入是 Git 仓库 URL 还是本地路径，Git 仓库自动克隆到工作目录。

### 阶段二：Git 分支探测与选择
如果项目是 Git 仓库，探测最近活跃的分支供用户选择。

### 阶段三：项目预扫描
快速了解项目规模、模块分布和项目类型，完成单模块/多模块判断。

### 阶段四：openclaw-lark插件检测
检测 OpenClaw 是否安装 openclaw-lark 插件，决定是否显示飞书上传选项。

### 阶段五：交互式确认
通过文本选项交互引导用户确认：
1. 审查类型（增量/存量）
2. 审查范围（模块选择）
3. 审查模式（fast/standard/deep/security）
4. 飞书上传选项（如插件已安装）
5. 执行计划确认

### 阶段六：代码审查
调用子 Agent 执行代码审查，并按用户选择上传到飞书（可选）。

## 脚本使用说明

所有脚本位于 `scripts/` 目录，可独立运行测试：

```bash
# 测试项目扫描
cd scripts
bash phase3-project-scan.sh "/path/to/your/project"

# 测试分支探测
bash phase2-detect-branches.sh "/path/to/your/project"
```

详细说明请参考 [scripts/README.md](scripts/README.md)

## 开发与维护

### 修改脚本逻辑
1. 编辑对应的 `.sh` 文件
2. 独立测试验证
3. 无需修改 SKILL.md（脚本通过路径引用）

### 修改审查流程
1. 编辑 `SKILL.md` 中对应阶段的描述
2. 如需新脚本，在 `scripts/` 目录创建并添加到 `scripts/README.md`

### 修改审查维度或提示词
1. 审查框架：编辑 `references/review-framework.md`（15个维度的详细定义）
2. Agent 提示词：编辑 `prompts/java-code-reviewer.md`（Agent 行为指令）
3. 确保模式×维度矩阵在两个文件中保持一致

## 版本信息

- **SKILL.md 版本**: 5.1（脚本化版本）
- **Agent 提示词版本**: 5.1（引用审查手册）
- **审查框架版本**: 5.1
- **最后更新**: 2026-04-16

## 主要优化

- ✅ 脚本独立维护（`scripts/`目录）
- ✅ 审查框架独立维护（`references/`目录）
- ✅ Agent 提示词简化（从 862 行减少到 665 行）
- ✅ 变量命名优化（`PROJECT_SCAN_RESULT` 等）
- ✅ 多维表格字段扩展（18个字段，含3个预留修复字段）
- ✅ 移除Python依赖（纯Bash实现，使用 `date +%s%3N` 获取时间戳）

## 环境要求

- **操作系统**: Linux（支持标准Bash环境）
- **Shell**: Bash 3.0+
- **Git**: 用于项目扫描和分支操作
- **依赖命令**: `git`, `find`, `grep`, `date`, `jq`（可选）

## 飞书多维表格字段结构

问题清单包含 **18个字段**：

**基础字段（15个）**：
- 标识类：问题编号、严重级别、所属维度
- 描述类：问题描述、位置、证据、影响、修复建议
- 管理类：置信度、修复状态、审查模式、审查日期、负责人、备注
- 协作类：技术栈

**预留修复字段（3个，v5.1新增）**：
- **修复时间**：记录实际修复完成时间
- **修复分支**：记录修复所在的分支名（如 fix/issue-123）
- **修复人**：记录实际修复人员

预留字段初始留空，供后续修复流程更新使用，形成完整的修复工作流追踪链路。

## License

MIT
