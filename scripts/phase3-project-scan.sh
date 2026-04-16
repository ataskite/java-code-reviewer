#!/bin/bash
# 阶段三：项目预扫描
# 用途：快速了解项目规模、模块分布和项目类型，完成单模块/多模块判断

set -e

PROJECT_DIR="${1:?请输入项目路径}"

# 检测项目类型并执行相应扫描
if [ -f "$PROJECT_DIR/pom.xml" ]; then
  # Maven项目扫描
  echo "=== 项目概况 ==="
  echo "项目类型: Maven"
  echo "Java文件总数: $(find "$PROJECT_DIR" -name '*.java' -not -path '*/target/*' -not -path '*/.git/*' | wc -l | tr -d ' ')"
  echo "代码总行数: $(find "$PROJECT_DIR" -name '*.java' -not -path '*/target/*' -not -path '*/.git/*' -exec cat {} + 2>/dev/null | wc -l | tr -d ' ')"
  echo ""

  # 检测是否为多模块项目（关键判断，后续阶段直接使用PROJECT_TYPE变量）
  # 排除 XML 注释中的 <modules> 标签，避免误判
  IS_MULTI_MODULE=$(sed '/<!--.*-->/d' "$PROJECT_DIR/pom.xml" 2>/dev/null | grep -c '<modules>' || true)
  if [ "$IS_MULTI_MODULE" -eq 0 ]; then
    echo "模块类型: 单模块项目"
    echo "PROJECT_TYPE=maven-single"
  else
    echo "模块类型: 多模块项目"
    echo "PROJECT_TYPE=maven-multi"
  fi

  echo ""
  echo "=== 模块结构 ==="
  for dir in $(find "$PROJECT_DIR" -maxdepth 3 -name 'pom.xml' -not -path '*/target/*' | sed 's|/pom.xml||' | sort); do
    rel=$(echo "$dir" | sed "s|$PROJECT_DIR||")
    # 单模块项目：跳过根目录自身（rel 为空），避免输出空 MODULE 行
    if [ -z "$rel" ]; then
      echo "├── (root)  [$(find "$dir" -name '*.java' -not -path '*/target/*' 2>/dev/null | wc -l | tr -d ' ') 类, $(find "$dir" -name '*.java' -not -path '*/target/*' -exec cat {} + 2>/dev/null | wc -l | tr -d ' ') 行]"
      continue
    fi
    java_count=$(find "$dir" -name '*.java' -not -path '*/target/*' 2>/dev/null | wc -l | tr -d ' ')
    lines=$(find "$dir" -name '*.java' -not -path '*/target/*' -exec cat {} + 2>/dev/null | wc -l | tr -d ' ')
    if [ "$java_count" -gt 0 ]; then
      depth=$(echo "$rel" | tr -cd '/' | wc -c | tr -d ' ')
      indent=$(printf '%*s' $((depth * 2)) '')
      echo "${indent}├── ${rel##*/}  [${java_count} 类, ${lines} 行]"
      echo "MODULE:${rel##*/}|${rel}|${java_count}|${lines}"
    fi
  done

elif [ -f "$PROJECT_DIR/build.gradle" ] || [ -f "$PROJECT_DIR/build.gradle.kts" ]; then
  # Gradle项目扫描
  echo "=== 项目概况 ==="
  echo "项目类型: Gradle"
  echo "Java文件总数: $(find "$PROJECT_DIR" -name '*.java' -not -path '*/build/*' -not -path '*/.git/*' | wc -l | tr -d ' ')"
  echo "代码总行数: $(find "$PROJECT_DIR" -name '*.java' -not -path '*/build/*' -not -path '*/.git/*' -exec cat {} + 2>/dev/null | wc -l | tr -d ' ')"
  echo ""

  # 检测是否为多模块项目（通过settings.gradle判断）
  # 排除注释行，避免误判
  if [ -f "$PROJECT_DIR/settings.gradle" ] || [ -f "$PROJECT_DIR/settings.gradle.kts" ]; then
    SETTINGS_FILE=$(ls "$PROJECT_DIR"/settings.gradle* 2>/dev/null | head -1)
    INCLUDE_COUNT=$(sed '/^\s*\/\//d' "$SETTINGS_FILE" 2>/dev/null | grep -c 'include' || true)
    if [ "$INCLUDE_COUNT" -gt 0 ]; then
      echo "模块类型: 多模块项目"
      echo "PROJECT_TYPE=gradle-multi"
    else
      echo "模块类型: 单模块项目"
      echo "PROJECT_TYPE=gradle-single"
    fi
  else
    echo "模块类型: 单模块项目"
    echo "PROJECT_TYPE=gradle-single"
  fi

  echo ""
  echo "=== 模块结构 ==="
  for dir in $(find "$PROJECT_DIR" -maxdepth 3 -name 'build.gradle*' -not -path '*/build/*' | sed 's|/build.gradle.*||' | sort); do
    rel=$(echo "$dir" | sed "s|$PROJECT_DIR||")
    if [ -z "$rel" ]; then
      echo "├── (root)  [$(find "$dir" -name '*.java' -not -path '*/build/*' 2>/dev/null | wc -l | tr -d ' ') 类, $(find "$dir" -name '*.java' -not -path '*/build/*' -exec cat {} + 2>/dev/null | wc -l | tr -d ' ') 行]"
      continue
    fi
    java_count=$(find "$dir" -name '*.java' -not -path '*/build/*' 2>/dev/null | wc -l | tr -d ' ')
    lines=$(find "$dir" -name '*.java' -not -path '*/build/*' -exec cat {} + 2>/dev/null | wc -l | tr -d ' ')
    if [ "$java_count" -gt 0 ]; then
      depth=$(echo "$rel" | tr -cd '/' | wc -c | tr -d ' ')
      indent=$(printf '%*s' $((depth * 2)) '')
      echo "${indent}├── ${rel##*/}  [${java_count} 类, ${lines} 行]"
      echo "MODULE:${rel##*/}|${rel}|${java_count}|${lines}"
    fi
  done
else
  echo "=== 项目概况 ==="
  echo "❌ 未检测到 Maven (pom.xml) 或 Gradle (build.gradle) 构建文件"
  echo "PROJECT_TYPE=unknown"
  echo ""
  echo "Java文件总数: $(find "$PROJECT_DIR" -name '*.java' -not -path '*/.git/*' 2>/dev/null | wc -l | tr -d ' ')"
fi
