# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure

This is a curated collection of Claude Code sub-agents organized as Git submodules:

- **agents/hesreallyhim-agents/**: Core agents including backend-typescript-architect, python-backend-engineer, senior-code-reviewer, ui-engineer
- **agents/n0rmanc-agents/**: Specialized agents with Taiwan-focused pricing, e2e testing, GitHub project management, and Supabase expertise  
- **agents/wshobson-agents/**: Comprehensive collection of 60+ domain-specific agents covering development, infrastructure, AI/ML, business, and documentation

## Common Commands

### Synchronize Repository
```bash
make sync  # Sync main repo and all submodules (primary command)
```

### Git Operations
```bash
# Update main repository only
git pull origin main

# Update all submodules to latest
git submodule update --init --recursive --remote

# Check status of all submodules
git submodule status
git submodule foreach git status

# Check for modified files across all submodules
git status && git submodule foreach git status
```

### Agent Discovery and Usage
```bash
# List all available agents
find . -name "*.md" -path "*/agents/*" -o -name "*-agent.md" -o -name "*-pro.md" -o -name "*-engineer.md" | head -20

# Agent categories by subdirectory
ls agents/hesreallyhim-agents/agents/     # Core development agents
ls agents/n0rmanc-agents/                 # Taiwan-specialized agents
ls agents/wshobson-agents/               # Comprehensive agent collection
```

## Architecture Overview

### Agent Organization Pattern
Each submodule follows the standard Claude Code agent format:
- Markdown files with YAML frontmatter for agent configuration
- Model assignments based on task complexity (haiku/sonnet/opus)
- Specialized system prompts for domain expertise
- Automatic invocation based on context matching

### Integration Strategy
- **agents/hesreallyhim-agents**: Focus on core development workflows
- **agents/n0rmanc-agents**: Taiwan market specialization and advanced tooling
- **agents/wshobson-agents**: Comprehensive agent ecosystem with orchestration patterns

### Submodule Management
- Each submodule maintains independent versioning
- Updates synchronized via Makefile for consistent environment
- Cross-agent coordination through Claude Code's native orchestration

## Agent Documentation Standards

Follow the 4-section structure for agent documentation:
1. **Before Starting Any Task**: Preparation and search requirements
2. **Always Save New Information**: Knowledge capture and categorization
3. **During Your Work**: Execution guidelines and consistency rules  
4. **Best Practices**: Optimization and improvement patterns

## Working with Submodules

### Adding New Agents
1. Choose appropriate submodule based on domain
2. Follow existing naming conventions (lowercase-hyphen-separated)
3. Include clear descriptions and usage examples
4. Test agent invocation patterns before committing

### Updating Agent Collections
```bash
# Update a specific submodule
cd agents/hesreallyhim-agents
git pull origin main
cd ../..
git add agents/hesreallyhim-agents
git commit -m "更新 hesreallyhim-agents 到最新版本"

# Update all submodules and commit changes
make sync
git add .
git commit -m "同步所有 submodules 到最新版本"
```


### Cross-Agent Workflows
Leverage agent orchestration patterns:
- Sequential: backend-architect → frontend-developer → test-automator
- Parallel: performance-engineer + database-optimizer  
- Review: implementation-agent → code-reviewer → security-auditor