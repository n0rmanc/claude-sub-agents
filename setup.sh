#!/bin/bash

# Claude sub-agents 设置脚本
# 创建 agents 和 commands 目录的符号链接到 ~/.claude

set -e

echo "🚀 开始设置 Claude sub-agents..."

# 获取当前脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "📂 当前目录: $SCRIPT_DIR"

# 创建 ~/.claude 目录（如果不存在）
if [ ! -d ~/.claude ]; then
    echo "📁 创建 ~/.claude 目录..."
    mkdir -p ~/.claude
fi

# 移除旧的符号链接（如果存在）
if [ -L ~/.claude/agents ]; then
    echo "🔗 移除旧的 agents 符号链接..."
    rm ~/.claude/agents
fi

if [ -L ~/.claude/commands ]; then
    echo "🔗 移除旧的 commands 符号链接..."
    rm ~/.claude/commands
fi

# 创建 agents 符号链接
echo "🔗 创建 agents 符号链接..."
ln -sfn "$SCRIPT_DIR/agents" ~/.claude/agents

# 创建 commands 符号链接
echo "🔗 创建 commands 符号链接..."
ln -sfn "$SCRIPT_DIR/commands" ~/.claude/commands

# 验证链接创建成功
echo ""
echo "✅ 符号链接创建完成！"
echo ""
echo "📋 验证结果:"
ls -la ~/.claude/agents ~/.claude/commands

echo ""
echo "🎉 设置完成！现在你可以在 Claude Code 中使用这些 agents 和 commands 了。"