# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure

This is a curated collection of Claude Code sub-agents organized as Git submodules:

- **agents/hesreallyhim-agents/**: Core development agents (backend, frontend, code review)
- **agents/n0rmanc-agents/**: Taiwan-specialized agents (pricing, project management, linus-code-critic)
- **agents/wshobson-agents/**: 60+ domain-specific agents (DevOps, AI/ML, business)

## Essential Commands

```bash
# Setup (run once from repository root)
./setup.sh                          # Create symbolic links for Claude Code

# Daily workflow
make sync                           # Update everything (main repo + all submodules)

# Find agents (from agents/ directory)
find . -name "*.md" -type f | grep -E "(agent|pro|engineer)"

# Invoke agents
@agent-name                         # Explicit invocation
# Or let Claude Code auto-select based on context
```

## Working Notes

- **Default directory**: `/agents/` - use `cd ..` for repository root
- **Agent paths**: Direct subfolders (e.g., `n0rmanc-agents/file.md`)
- **Never commit unless asked**: Always verify before pushing changes
- **Available commands**: `/hi-claude`, `/commit-as-prompt`

## Agent File Format

```yaml
---
name: lowercase-hyphen-name
description: When to use this agent. Use PROACTIVELY for auto-invocation
tools: Tool1, Tool2  # Optional, defaults to all
---

Agent system prompt here...
```

## Submodule Updates

```bash
# Update specific submodule (from agents/)
cd hesreallyhim-agents && git pull origin main && cd ..

# Commit submodule updates
git add . && git commit -m "Update submodules"
```

That's it. Keep it simple.