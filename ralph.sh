#!/bin/bash
# Ralph for Claude Code - Autonomous AI agent loop
# Ported from https://github.com/snarktank/ralph
#
# Usage: ralph.sh [feature_name] [max_iterations]
#   feature_name:   Feature subdirectory in tasks/ (auto-detected if only one exists)
#   max_iterations: Maximum iterations before stopping (default: 10)
#
# Examples:
#   ralph.sh                    # Auto-detect feature, 10 iterations
#   ralph.sh auth-system        # Run tasks/auth-system-*/prd.json
#   ralph.sh auth-system 20     # Run with 20 iterations max
#   ralph.sh 15                 # Auto-detect feature, 15 iterations
#
# Environment variables:
#   RALPH_TASKS_DIR    Override tasks directory (default: ./tasks)
#   RALPH_CLAUDE_OPTS  Additional options to pass to claude CLI

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR=$(pwd)
TASKS_DIR="${RALPH_TASKS_DIR:-$PROJECT_DIR/tasks}"
CLAUDE_OPTS="${RALPH_CLAUDE_OPTS:-}"

# Parse arguments - could be feature name, iteration count, or both
FEATURE_PATTERN=""
MAX_ITERATIONS=10

for arg in "$@"; do
    if [[ "$arg" =~ ^[0-9]+$ ]]; then
        MAX_ITERATIONS=$arg
    else
        FEATURE_PATTERN=$arg
    fi
done

# Check for jq
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    echo "Install with: brew install jq"
    exit 1
fi

# Check for claude
if ! command -v claude &> /dev/null; then
    echo "Error: claude CLI is required but not installed."
    echo "Install from: https://claude.ai/claude-code"
    exit 1
fi

# Generate a random 5-character suffix
generate_suffix() {
    LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 5
}

# Find feature directory matching pattern
find_feature_dir() {
    local pattern="$1"
    local matches=()

    if [ -d "$TASKS_DIR" ]; then
        for dir in "$TASKS_DIR"/*/; do
            if [ -f "${dir}prd.json" ]; then
                local dirname=$(basename "$dir")
                # Match if pattern matches the base name (without suffix)
                local base_name=$(echo "$dirname" | sed 's/-[a-z0-9]\{5\}$//')
                if [ -z "$pattern" ] || [[ "$base_name" == "$pattern" ]] || [[ "$dirname" == "$pattern"* ]]; then
                    matches+=("$dir")
                fi
            fi
        done
    fi

    # Also check for legacy flat structure
    if [ -f "$TASKS_DIR/prd.json" ]; then
        matches+=("$TASKS_DIR/")
    fi

    if [ ${#matches[@]} -eq 0 ]; then
        echo ""
    elif [ ${#matches[@]} -eq 1 ]; then
        echo "${matches[0]}"
    else
        # Multiple matches - return them all (caller handles)
        printf '%s\n' "${matches[@]}"
    fi
}

# Auto-detect or find feature directory
FEATURE_DIR=""
MATCHES=$(find_feature_dir "$FEATURE_PATTERN")
MATCH_COUNT=$(echo "$MATCHES" | grep -c . || echo 0)

if [ "$MATCH_COUNT" -eq 0 ] || [ -z "$MATCHES" ]; then
    echo "Error: No prd.json found in $TASKS_DIR or its subdirectories."
    echo ""
    echo "Create a PRD first:"
    echo "  1. Run /prd to generate a PRD"
    echo "  2. Run /ralph to convert it to prd.json"
    exit 1
elif [ "$MATCH_COUNT" -eq 1 ]; then
    FEATURE_DIR="$MATCHES"
    FEATURE_NAME=$(basename "$FEATURE_DIR")
    echo "Auto-detected feature: $FEATURE_NAME"
else
    echo "Multiple features found. Please specify one:"
    echo ""
    echo "$MATCHES" | while read -r dir; do
        local name=$(basename "$dir")
        local base=$(echo "$name" | sed 's/-[a-z0-9]\{5\}$//')
        echo "  ralph.sh $base"
    done
    exit 1
fi

# Set up paths
PRD_FILE="$FEATURE_DIR/prd.json"
PROGRESS_FILE="$FEATURE_DIR/progress.txt"

# Verify prd.json exists
if [ ! -f "$PRD_FILE" ]; then
    echo "Error: No prd.json found in $FEATURE_DIR"
    echo "Run /ralph to convert your PRD to prd.json format."
    exit 1
fi

# Initialize progress file if it doesn't exist
if [ ! -f "$PROGRESS_FILE" ]; then
    echo "# Ralph Progress Log - $FEATURE_NAME" > "$PROGRESS_FILE"
    echo "Started: $(date)" >> "$PROGRESS_FILE"
    echo "---" >> "$PROGRESS_FILE"
fi

# Get feature info from prd.json
PROJECT_NAME=$(jq -r '.project // "Unknown"' "$PRD_FILE")
BRANCH_NAME=$(jq -r '.branchName // "ralph/unknown"' "$PRD_FILE")
STORY_COUNT=$(jq '.userStories | length' "$PRD_FILE")
COMPLETED=$(jq '[.userStories[] | select(.passes == true)] | length' "$PRD_FILE")

echo ""
echo "Ralph for Claude Code"
echo "====================="
echo "Project:    $PROJECT_NAME"
echo "Feature:    $FEATURE_NAME"
echo "Branch:     $BRANCH_NAME"
echo "Stories:    $COMPLETED/$STORY_COUNT completed"
echo "Max iters:  $MAX_ITERATIONS"
echo ""

# Create iteration prompt
create_prompt() {
    cat << EOF
# Ralph Iteration

You are an autonomous agent in the Ralph execution loop. Your task is to implement ONE user story from the PRD, then exit.

**Feature Directory:** \`$FEATURE_DIR\`

## Your Task

1. **Read Context**
   - Read \`$PRD_FILE\` to find the PRD and user stories
   - Read \`$PROGRESS_FILE\` for learnings from previous iterations
   - Check which git branch you're on - verify it matches: \`$BRANCH_NAME\`

2. **Select Story**
   - Find the highest-priority story where \`passes: false\`
   - Only work on ONE story this iteration

3. **Implement**
   - Make the code changes required by the acceptance criteria
   - Check existing AGENTS.md files in directories you're modifying for patterns
   - Keep changes minimal and focused on THIS story only

4. **Quality Checks**
   - Run typecheck (npm run typecheck, tsc, etc.)
   - Run lint if available
   - Run tests if available
   - Fix any failures before proceeding

5. **Browser Verification** (UI stories only)
   - If acceptance criteria mentions browser verification, use webapp-testing skill
   - Verify the UI change works as expected

6. **Commit**
   - Stage and commit with message format:
     \`\`\`
     [Ralph] US-XXX: Story title

     - What was changed
     - How it satisfies criteria
     \`\`\`

7. **Update PRD**
   - In \`$PRD_FILE\`, set \`passes: true\` for this story
   - Add implementation notes

8. **Update Progress**
   - APPEND to \`$PROGRESS_FILE\` (never replace):
     \`\`\`
     ## [Date] - US-XXX: Story Title

     **Implementation:**
     - What was done

     **Learnings:**
     - Patterns discovered
     - Gotchas for future iterations
     \`\`\`

9. **Update AGENTS.md** (if valuable)
   - Add reusable patterns to AGENTS.md in relevant directories
   - Only add genuinely useful patterns, not story-specific details

10. **Exit**
    - If ALL stories have \`passes: true\`, output: \`<promise>COMPLETE</promise>\`
    - Otherwise, just finish normally

## Critical Rules

- **One story only** - Never implement multiple stories
- **Fresh context** - Don't assume knowledge from previous iterations
- **Quality first** - Never commit broken code
- **Commit often** - Each story gets its own commit
- **Append-only** - Progress file is append-only

## Branch Management

If the feature branch doesn't exist yet:
\`\`\`bash
git checkout -b $BRANCH_NAME
\`\`\`

If it exists, make sure you're on it:
\`\`\`bash
git checkout $BRANCH_NAME
\`\`\`

## Stop Condition

When ALL user stories have \`passes: true\` in prd.json, output exactly:
\`\`\`
<promise>COMPLETE</promise>
\`\`\`

The outer loop watches for this signal to know when to stop.
EOF
}

# Main loop
for i in $(seq 1 $MAX_ITERATIONS); do
    echo ""
    echo "========================================"
    echo " Iteration $i of $MAX_ITERATIONS"
    echo "========================================"

    # Run claude with the ralph prompt
    OUTPUT=$(create_prompt | claude -p --dangerously-skip-permissions $CLAUDE_OPTS 2>&1 | tee /dev/stderr) || true

    # Check for completion signal
    if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
        echo ""
        echo "========================================"
        echo " Ralph completed all tasks!"
        echo " Finished at iteration $i of $MAX_ITERATIONS"
        echo "========================================"
        exit 0
    fi

    # Show current progress
    COMPLETED=$(jq '[.userStories[] | select(.passes == true)] | length' "$PRD_FILE")
    echo ""
    echo "Progress: $COMPLETED/$STORY_COUNT stories complete"
    sleep 2
done

echo ""
echo "========================================"
echo " Ralph reached max iterations ($MAX_ITERATIONS)"
echo " Progress: $COMPLETED/$STORY_COUNT stories complete"
echo " Check $PROGRESS_FILE for status"
echo "========================================"
exit 1
