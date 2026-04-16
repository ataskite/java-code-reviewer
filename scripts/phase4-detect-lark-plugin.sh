#!/bin/bash
# 阶段四：openclaw-lark插件检测
# 用途：检测OpenClaw是否安装openclaw-lark插件

set -e

CONFIG_FILE="$HOME/.openclaw/openclaw.json"
if [ -f "$CONFIG_FILE" ]; then
  if command -v jq &> /dev/null; then
    LARK_ENABLED=$(jq -r '.plugins.entries["openclaw-lark"].enabled // false' "$CONFIG_FILE" 2>/dev/null)
  else
    LARK_ENABLED=$(grep -A 2 '"openclaw-lark"' "$CONFIG_FILE" 2>/dev/null | grep '"enabled"' | grep -o 'true' || echo "false")
  fi

  if [ "$LARK_ENABLED" == "true" ]; then
    echo "LARK_PLUGIN_INSTALLED=true"
  else
    echo "LARK_PLUGIN_INSTALLED=false"
  fi
else
  echo "LARK_PLUGIN_INSTALLED=false"
fi
