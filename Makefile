# Claude sub-agents Makefile
# Variables
CLAUDE_DIR := ~/.claude
CURRENT_DIR := $(shell pwd)

.PHONY: sync setup

# Update repository and submodules
sync:
	git pull origin main
	git submodule sync --recursive
	git submodule update --init --recursive --remote

# Setup Claude Code symbolic links
setup:
	@echo "🚀 开始设置 Claude sub-agents..."
	@echo "📂 当前目录: $(CURRENT_DIR)"
	@if [ ! -d $(CLAUDE_DIR) ]; then \
		echo "📁 创建 $(CLAUDE_DIR) 目录..."; \
		mkdir -p $(CLAUDE_DIR); \
	fi
	@if [ -L $(CLAUDE_DIR)/agents ]; then \
		echo "🔗 移除旧的 agents 符号链接..."; \
		rm $(CLAUDE_DIR)/agents; \
	fi
	@if [ -L $(CLAUDE_DIR)/commands ]; then \
		echo "🔗 移除旧的 commands 符号链接..."; \
		rm $(CLAUDE_DIR)/commands; \
	fi
	@if [ -L $(CLAUDE_DIR)/skills ]; then \
		echo "🔗 移除旧的 skills 符号链接..."; \
		rm $(CLAUDE_DIR)/skills; \
	fi
	@echo "🔗 创建 agents 符号链接..."
	@ln -sfn "$(CURRENT_DIR)/agents" $(CLAUDE_DIR)/agents
	@echo "🔗 创建 commands 符号链接..."
	@ln -sfn "$(CURRENT_DIR)/commands" $(CLAUDE_DIR)/commands
	@echo "🔗 创建 skills 符号链接..."
	@ln -sfn "$(CURRENT_DIR)/skills" $(CLAUDE_DIR)/skills
	@echo ""
	@echo "✅ 符号链接创建完成！"
	@echo ""
	@echo "📋 验证结果:"
	@ls -la $(CLAUDE_DIR)/agents $(CLAUDE_DIR)/commands $(CLAUDE_DIR)/skills
	@echo ""
	@echo "🎉 设置完成！现在你可以在 Claude Code 中使用这些 agents, commands 和 skills 了。"