#!/bin/bash
# 阶段四：lark-cli 检测
# 用途：检测系统是否安装 lark-cli 命令行工具

set -e

if command -v lark-cli &> /dev/null; then
  echo "LARK_PLUGIN_INSTALLED=true"
  echo "LARK_PLUGIN_NAME=lark-cli"
else
  echo "LARK_PLUGIN_INSTALLED=false"
fi
