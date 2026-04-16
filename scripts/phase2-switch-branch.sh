#!/bin/bash
# 阶段二：Git 分支探测与选择 - 步骤C
# 用途：切换到用户选择的分支

PROJECT_DIR="${1:?请输入项目路径}"
TARGET_BRANCH="${2:?请输入目标分支}"
CURRENT_BRANCH="${3:?请输入当前分支}"

# 如果目标分支就是当前分支，无需切换
if [ "$TARGET_BRANCH" == "$CURRENT_BRANCH" ]; then
  echo "✅ 已在目标分支: $CURRENT_BRANCH"
  exit 0
fi

# 判断是本地分支还是远程分支
if [[ "$TARGET_BRANCH" =~ ^origin/ ]]; then
  # 远程分支：需要先创建本地分支
  SHORT_BRANCH=$(echo "$TARGET_BRANCH" | sed 's|^origin/||')
  echo "正在从远程创建本地分支: $SHORT_BRANCH"
  if git -C "$PROJECT_DIR" checkout -b "$SHORT_BRANCH" "$TARGET_BRANCH" 2>&1; then
    echo "✅ 已切换到分支: $TARGET_BRANCH"
  else
    echo "⚠️ 分支切换失败，将使用当前分支 $CURRENT_BRANCH 继续审查"
    exit 1
  fi
else
  # 本地分支：直接切换
  echo "正在切换到本地分支: $TARGET_BRANCH"
  if git -C "$PROJECT_DIR" checkout "$TARGET_BRANCH" 2>&1; then
    echo "✅ 已切换到分支: $TARGET_BRANCH"
  else
    echo "⚠️ 分支切换失败，将使用当前分支 $CURRENT_BRANCH 继续审查"
    exit 1
  fi
fi
