# Installation Guide

## Quick Install

```bash
# Clone the repo
git clone https://github.com/YOUR_USERNAME/ralph-claude-code.git ~/ralph-claude-code

# Add to PATH
echo 'export PATH="$PATH:$HOME/ralph-claude-code"' >> ~/.zshrc
source ~/.zshrc

# Install skills
cp -r ~/ralph-claude-code/skills/* ~/.claude/skills/
```

## Verify Installation

```bash
# Check ralph.sh is available
which ralph.sh

# Check skills are installed
ls ~/.claude/skills/prd/
ls ~/.claude/skills/ralph/
```

## Usage

In any git project:

```bash
# 1. Generate a PRD
claude
> /prd Add user authentication with email/password

# 2. Convert to prd.json
> /ralph

# 3. Run the autonomous loop (choose one)
ralph.sh                    # auto-detect feature
ralph.sh auth-system        # specific feature
ralph.sh auth-system 20     # with max iterations
```

## Updating

```bash
cd ~/ralph-claude-code
git pull

# Re-copy skills if updated
cp -r skills/* ~/.claude/skills/
```

## Uninstall

```bash
# Remove from PATH (edit ~/.zshrc and remove the export line)

# Remove skills
rm -rf ~/.claude/skills/prd/
rm -rf ~/.claude/skills/ralph/

# Remove repo
rm -rf ~/ralph-claude-code
```
