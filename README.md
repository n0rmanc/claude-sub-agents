# Claude Sub-Agents Collection

A curated meta-repository of specialized Claude Code sub-agents, aggregating the best agent collections from multiple contributors into a single, synchronized workspace.

## Overview

This repository organizes Claude Code sub-agents as Git submodules, providing access to 80+ specialized AI agents across development, infrastructure, business, and documentation domains. Each submodule maintains independent versioning while offering unified access and synchronization.

## Agent Collections

### 🔧 [hesreallyhim-agents](https://github.com/hesreallyhim/awesome-claude-code-agents)
**Core Development Agents**
- `backend-typescript-architect` - Expert backend TypeScript development with Bun runtime
- `python-backend-engineer` - Modern Python backend development with FastAPI/Django
- `senior-code-reviewer` - Comprehensive code review with security focus
- `ui-engineer` - Frontend development and component architecture

### 🇹🇼 [n0rmanc-agents](./n0rmanc-agents/)
**Specialized Taiwan-Market Agents**
- `pricing-pm` - Taiwan salary-based project pricing specialist
- `e2e-test-engineer` - Playwright end-to-end testing expert
- `github-project-manager` - GitHub automation and project management
- `supabase-architect` - Supabase ecosystem and PostgreSQL expert
- `scrum-master` - Agile process automation specialist
- `feature-planner` - Spec-driven feature development methodology

### 🌐 [wshobson-agents](https://github.com/wshobson/agents)
**Comprehensive Agent Ecosystem (60+ agents)**
- **Development**: Language specialists (Python, Go, Rust, TypeScript, etc.)
- **Infrastructure**: DevOps, cloud architecture, database optimization
- **AI/ML**: Machine learning engineering, MLOps, prompt optimization
- **Business**: Analytics, marketing, sales automation, legal compliance
- **Quality**: Security auditing, performance engineering, debugging

## Quick Start

### Installation
```bash
# Clone with submodules
git clone --recursive https://github.com/n0rmanc/claude-sub-agents.git
cd claude-sub-agents

# Or clone and initialize submodules separately
git clone https://github.com/n0rmanc/claude-sub-agents.git
cd claude-sub-agents
git submodule update --init --recursive
```

### Synchronization
```bash
# Sync everything (main repo + all submodules)
make sync

# Manual sync
git pull origin main
git submodule update --init --recursive --remote
```

### Usage in Claude Code
Agents are automatically available when this repository is in your Claude Code workspace:

```bash
# Automatic invocation based on context
"Review this API design for security issues"
# → Invokes senior-code-reviewer or security-auditor

# Explicit invocation
"Use the pricing-pm agent to estimate this Taiwan project"
"Have the supabase-architect design the database schema"
```

## Architecture

### Submodule Strategy
- **Independent Versioning**: Each collection updates independently
- **Unified Access**: Single `make sync` command updates everything
- **Namespace Isolation**: Agents from different sources don't conflict
- **Selective Updates**: Update individual collections as needed

### Agent Organization
```
claude-sub-agents/
├── hesreallyhim-agents/     # Core development workflows
├── n0rmanc-agents/          # Taiwan-specialized + advanced tooling
├── wshobson-agents/         # Comprehensive agent ecosystem
├── Makefile                 # Sync automation
└── CLAUDE.md               # Claude Code guidance
```

### Cross-Collection Workflows
Agents work together seamlessly across collections:
```bash
# Feature development pipeline
backend-typescript-architect → ui-engineer → e2e-test-engineer → pricing-pm

# Production optimization
performance-engineer → database-optimizer → devops-troubleshooter

# Business project flow
feature-planner → github-project-manager → scrum-master → pricing-pm
```

## Available Commands

```bash
# Repository management
make sync                    # Sync main repo and all submodules
git submodule status        # Check submodule status
git submodule foreach git status  # Detailed status for each submodule

# Individual submodule updates
cd hesreallyhim-agents && git pull origin main
cd n0rmanc-agents && git pull origin main  
cd wshobson-agents && git pull origin main
```

## Agent Highlights

### 🏗️ **Development & Architecture**
- Advanced TypeScript/Python backend development
- Frontend component architecture and responsive design
- Database schema design and API architecture

### 🔒 **Quality & Security** 
- Comprehensive code review with security focus
- End-to-end testing with Playwright automation
- Performance optimization and debugging

### 🌏 **Taiwan Market Specialization**
- Salary-based project pricing for Taiwan market
- Traditional Chinese documentation standards
- Local business practice integration

### ⚡ **DevOps & Infrastructure**
- Cloud architecture and deployment automation
- Database optimization and monitoring
- Incident response and troubleshooting

### 🤖 **AI & Machine Learning**
- LLM application development and RAG systems
- MLOps pipeline automation
- Prompt engineering and optimization

### 💼 **Business Operations**
- Project management and agile workflows
- Content marketing and sales automation
- Legal compliance and documentation

## Contributing

### Adding New Collections
1. Add as submodule: `git submodule add <repo-url> <directory-name>`
2. Update `.gitmodules` configuration
3. Update `Makefile` sync target if needed
4. Document in README and CLAUDE.md

### Updating Existing Collections
1. Navigate to submodule: `cd <submodule-directory>`
2. Pull latest changes: `git pull origin main`
3. Return to main repo: `cd ..`
4. Commit submodule update: `git add <submodule-directory> && git commit -m "更新 submodule"`

## Documentation Standards

All agent documentation follows the 4-section structure:
1. **Before Starting Any Task**: Preparation and requirements
2. **Always Save New Information**: Knowledge capture rules
3. **During Your Work**: Execution guidelines
4. **Best Practices**: Optimization recommendations

## License

This meta-repository is MIT licensed. Individual submodules maintain their own licenses:
- hesreallyhim-agents: See upstream repository
- n0rmanc-agents: MIT License
- wshobson-agents: MIT License

## Resources

- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Sub-Agents Guide](https://docs.anthropic.com/en/docs/claude-code/sub-agents)
- [Original Collections](#agent-collections) - Links to source repositories

---

**Note**: This is a meta-repository that aggregates agent collections. Individual agent development and maintenance happens in the respective source repositories linked above.