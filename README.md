# Ralph for Claude Code

An autonomous AI agent loop for [Claude Code](https://claude.ai/claude-code). Ralph executes iteratively through discrete iterations until all requirements in a Product Requirements Document are complete.

Each iteration spawns a fresh Claude instance with clean context. Memory persists via git history, `progress.txt`, and `prd.json`.

## Attribution

This is a port of [snarktank/ralph](https://github.com/snarktank/ralph) (originally for Amp CLI) adapted for Claude Code. The core pattern and philosophy come from Geoffrey Huntley's Ralph pattern.

## Prerequisites

- [Claude Code CLI](https://claude.ai/claude-code) installed and authenticated
- `jq` command-line tool (`brew install jq` on macOS)
- A git repository for your project

## Installation

### Option 1: Clone and Add to PATH

```bash
git clone https://github.com/ianpatrickhines/ralph-claude-code.git ~/ralph-claude-code
echo 'export PATH="$PATH:$HOME/ralph-claude-code"' >> ~/.zshrc
source ~/.zshrc
```

### Option 2: Install Skills Only

Copy the skills to your Claude Code skills directory:

```bash
cp -r skills/* ~/.claude/skills/
```

## Quick Start

### 1. Create a PRD

In your project directory, use the `/prd` skill:

```
/prd Add user authentication with email/password login
```

This generates a structured PRD with atomic user stories in `tasks/{feature}/`.

### 2. Convert to Ralph Format

```
/ralph
```

This converts your PRD to `prd.json` and offers to run the autonomous loop.

### 3. Run Ralph

```bash
# Auto-detect feature (if only one)
ralph.sh

# Specify feature
ralph.sh auth-system

# With iteration limit
ralph.sh auth-system 20
```

## How It Works

```
┌─────────────────────────────────────────────────────────┐
│                    ralph.sh loop                        │
├─────────────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────────────┐  │
│  │  Iteration 1: Fresh Claude instance              │  │
│  │  → Read prd.json, progress.txt                   │  │
│  │  → Implement US-001                              │  │
│  │  → Run quality checks                            │  │
│  │  → Commit changes                                │  │
│  │  → Update prd.json (passes: true)                │  │
│  │  → Append to progress.txt                        │  │
│  └───────────────────────────────────────────────────┘  │
│                         ↓                               │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Iteration 2: Fresh Claude instance              │  │
│  │  → Read prd.json, progress.txt (has learnings)   │  │
│  │  → Implement US-002                              │  │
│  │  → ...                                           │  │
│  └───────────────────────────────────────────────────┘  │
│                         ↓                               │
│                       ...                               │
│                         ↓                               │
│              <promise>COMPLETE</promise>                │
└─────────────────────────────────────────────────────────┘
```

## Directory Structure

Each feature gets its own isolated directory with a unique suffix:

```
your-project/
└── tasks/
    ├── auth-system-x7k2m/
    │   ├── prd.json          # User stories and status
    │   └── progress.txt      # Learnings for future iterations
    └── billing-p3n9q/
        ├── prd.json
        └── progress.txt
```

The random suffix ensures uniqueness when running multiple instances of the same feature.

## Workflow Options

After `/ralph` converts your PRD, you're offered three choices:

| Option | Description |
|--------|-------------|
| **Watch it work** | Run in a separate terminal for full visibility |
| **Run in background** | Claude manages it, reports when complete |
| **I'll handle it** | Just get the command |

## Key Files

| File | Purpose |
|------|---------|
| `ralph.sh` | Main bash loop that spawns fresh Claude instances |
| `skills/prd/SKILL.md` | Skill for generating structured PRDs |
| `skills/ralph/SKILL.md` | Skill for converting PRDs and managing execution |
| `prd.json` | User stories with completion status |
| `progress.txt` | Append-only learnings for future iterations |

## prd.json Format

```json
{
  "project": "MyApp",
  "branchName": "ralph/auth-system",
  "description": "User authentication with email/password",
  "userStories": [
    {
      "id": "US-001",
      "title": "Add users table to database",
      "description": "As a developer, I need a users table to store credentials.",
      "acceptanceCriteria": [
        "Create users table with id, email, password_hash, created_at",
        "Add unique constraint on email",
        "Typecheck passes"
      ],
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

## Critical Design Principles

### Atomic Stories
Each user story must be completable in one context window. If you can't describe the change in 2-3 sentences, it's too big.

**Good:** "Add priority column to tasks table"
**Bad:** "Build authentication system"

### Dependency Ordering
Stories are ordered by dependencies:
1. Database/schema changes
2. Backend logic/API
3. Frontend/UI components
4. Integration/polish

### Quality Gates
Every iteration runs quality checks before committing:
- Typecheck
- Lint (if available)
- Tests (if available)

### Fresh Context
Each iteration starts fresh. The only "memory" comes from:
- `prd.json` - what's done, what's next
- `progress.txt` - learnings and patterns
- Git history - the actual code changes

## Debugging

```bash
# Check story status
cat tasks/*/prd.json | jq '.userStories[] | {id, title, passes}'

# View progress/learnings
cat tasks/*/progress.txt

# Recent commits
git log --oneline -10
```

## Differences from Amp Version

| Amp CLI | Claude Code |
|---------|-------------|
| `amp --dangerously-allow-all` | `claude -p --dangerously-skip-permissions` |
| `~/.config/amp/skills/` | `~/.claude/skills/` |
| `dev-browser` skill | `webapp-testing` skill |

## License

MIT License - See [LICENSE](LICENSE)

## Contributing

Issues and PRs welcome. This is an early-stage port; feedback on the Claude Code integration is especially valuable.
