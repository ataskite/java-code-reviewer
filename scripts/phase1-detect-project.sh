#!/bin/bash
# 阶段一：项目识别与准备
# 用途：识别用户提供的路径类型，Git仓库克隆到本地缓存目录
# 缓存策略：相同仓库只克隆一次，后续自动 pull 更新，避免重复克隆

INPUT_PATH="${1:?请输入项目路径或Git URL}"

# 本地缓存目录：脚本所在目录的上级 code/ 子目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
CODE_DIR="$BASE_DIR/code"

# 识别规则：以http://、https://、git://或git@开头的URL → Git仓库
if [[ "$INPUT_PATH" =~ ^https?:// ]] || [[ "$INPUT_PATH" =~ ^git:// ]] || [[ "$INPUT_PATH" =~ ^git@ ]]; then
  # 从 URL 中提取仓库名作为缓存目录名
  # https://github.com/org/repo.git → repo
  # git@github.com:org/repo.git → repo
  REPO_NAME=$(echo "$INPUT_PATH" | sed 's/\.git$//' | sed 's:.*/::')
  CACHE_DIR="$CODE_DIR/$REPO_NAME"

  mkdir -p "$CODE_DIR"

  if [ -d "$CACHE_DIR/.git" ]; then
    # 缓存已存在，pull 更新
    echo "检测到Git仓库（缓存命中），正在拉取最新代码..."
    CURRENT_BRANCH=$(git -C "$CACHE_DIR" branch --show-current 2>/dev/null)
    if git -C "$CACHE_DIR" pull 2>&1; then
      echo "✅ 已更新到最新: $CACHE_DIR (分支: $CURRENT_BRANCH)"
      PROJECT_DIR="$CACHE_DIR"
    else
      echo "⚠️ 拉取失败，删除缓存并重新克隆..."
      rm -rf "$CACHE_DIR"
      if git clone "$INPUT_PATH" "$CACHE_DIR" 2>&1; then
        echo "✅ 重新克隆成功: $CACHE_DIR"
        PROJECT_DIR="$CACHE_DIR"
      else
        echo "❌ 克隆失败，请检查Git仓库URL是否正确"
        exit 1
      fi
    fi
  else
    # 缓存不存在，首次克隆
    # 如存在残留目录（非 .git），先清理
    if [ -d "$CACHE_DIR" ]; then
      rm -rf "$CACHE_DIR"
    fi
    echo "检测到Git仓库，正在克隆到缓存目录..."
    if git clone "$INPUT_PATH" "$CACHE_DIR" 2>&1; then
      echo "✅ 克隆成功: $CACHE_DIR"
      PROJECT_DIR="$CACHE_DIR"
    else
      echo "❌ 克隆失败，请检查Git仓库URL是否正确"
      exit 1
    fi
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
