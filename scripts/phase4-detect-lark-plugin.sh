#!/bin/bash
# 阶段四：飞书插件检测
# 用途：检测OpenClaw是否安装飞书相关插件（三者启用其一即算通过）
# 插件列表：
#   - openclaw-lark: 飞书官方插件
#   - feishu: openclaw飞书社区插件
#   - openclaw-wkzj: 企业内部插件

set -e

CONFIG_FILE="$HOME/.openclaw/openclaw.json"
PLUGINS=("openclaw-lark" "feishu" "openclaw-wkzj")

if [ -f "$CONFIG_FILE" ]; then
  for plugin in "${PLUGINS[@]}"; do
    if command -v jq &> /dev/null; then
      ENABLED=$(jq -r ".plugins.entries[\"$plugin\"].enabled // false" "$CONFIG_FILE" 2>/dev/null)
    else
      ENABLED=$(grep -A 2 "\"$plugin\"" "$CONFIG_FILE" 2>/dev/null | grep '"enabled"' | grep -o 'true' || echo "false")
    fi

    if [ "$ENABLED" == "true" ]; then
      echo "LARK_PLUGIN_INSTALLED=true"
      echo "LARK_PLUGIN_NAME=$plugin"
      exit 0
    fi
  done
  echo "LARK_PLUGIN_INSTALLED=false"
else
  echo "LARK_PLUGIN_INSTALLED=false"
fi
