#!/bin/bash
# 阶段一：项目识别与准备
# 用途：识别用户提供的路径类型，Git仓库自动克隆到工作目录

INPUT_PATH="${1:?请输入项目路径或Git URL}"

# 识别规则：以http://、https://、git://或git@开头的URL → Git仓库
if [[ "$INPUT_PATH" =~ ^https?:// ]] || [[ "$INPUT_PATH" =~ ^git:// ]] || [[ "$INPUT_PATH" =~ ^git@ ]]; then
  WORK_DIR="/tmp/openclaw/java-code-reviewer/$(date +%s)"
  mkdir -p "$WORK_DIR"
  echo "检测到Git仓库，正在克隆..."
  if git clone "$INPUT_PATH" "$WORK_DIR" 2>&1; then
    echo "✅ 克隆成功: $WORK_DIR"
    PROJECT_DIR="$WORK_DIR"
  else
    echo "❌ 克隆失败，请检查Git仓库URL是否正确"
    exit 1
  fi
else
  if [ -d "$INPUT_PATH" ]; then
    echo "检测到本地项目: $INPUT_PATH"
    PROJECT_DIR="$INPUT_PATH"
  else
    echo "❌ 路径不存在: $INPUT_PATH"
    exit 1
  fi
fi

# 输出结果供主agent解析
echo "PROJECT_DIR=$PROJECT_DIR"
