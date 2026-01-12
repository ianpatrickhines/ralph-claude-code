# Ralph for Claude Code

## Overview

Ralph is an autonomous AI agent loop that runs Claude Code repeatedly until all PRD items are complete. Each iteration spawns a fresh Claude instance with clean context.

## Key Files

- `ralph.sh` - Main bash loop that spawns fresh Claude instances
- `skills/prd/` - Skill for generating structured PRDs
- `skills/ralph/` - Skill for converting PRDs to prd.json
- `examples/prd.json` - Example PRD format

## Usage

```bash
# From your project directory
ralph.sh                    # Auto-detect feature
ralph.sh feature-name       # Specific feature
ralph.sh feature-name 20    # With max iterations
```

## Patterns

- Each iteration spawns a fresh Claude instance with clean context
- Memory persists via git history, `progress.txt`, and `prd.json`
- Stories should be small enough to complete in one context window
- Feature directories use random 5-char suffix for uniqueness (e.g., `auth-system-x7k2m`)
