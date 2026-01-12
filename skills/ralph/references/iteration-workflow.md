# Ralph Iteration Workflow

This is what happens during each autonomous Ralph iteration.

## Iteration Steps

### 1. Read Context

- Read `tasks/{feature}/prd.json` - find highest-priority incomplete story
- Read `tasks/{feature}/progress.txt` - check for patterns/learnings from previous iterations
- Check git branch - verify on correct feature branch

### 2. Select Story

Pick the highest-priority story where `passes: false`. Only work on ONE story per iteration.

### 3. Implement

- Make the code changes required by acceptance criteria
- Follow existing codebase patterns (check AGENTS.md files)
- Keep changes minimal and focused

### 4. Quality Checks

Run all quality checks before committing:
```bash
npm run typecheck  # or equivalent
npm run lint       # if available
npm test           # if tests exist
```

If checks fail, fix the issues before proceeding.

### 5. Browser Verification (UI stories only)

For stories with "Verify in browser" criterion:
- Use webapp-testing skill to verify UI changes
- Take screenshot as evidence if needed

### 6. Commit Changes

Commit with descriptive message:
```
[Ralph] US-XXX: Title of story

- What was changed
- How it satisfies acceptance criteria
```

### 7. Update PRD

In `tasks/{feature}/prd.json`, update the completed story:
```json
{
  "passes": true,
  "notes": "Brief note about implementation"
}
```

### 8. Update Progress Log

APPEND to `tasks/{feature}/progress.txt` (never replace):
```
## [Date] - US-XXX: Story Title

**Implementation:**
- What was done
- Key decisions made

**Learnings:**
- Patterns discovered
- Gotchas for future iterations
- Useful context
```

### 9. Update AGENTS.md (if applicable)

If you discovered patterns useful for future AI agents:
- Find or create AGENTS.md in relevant directories
- Add reusable patterns, NOT story-specific details

### 10. Signal Completion

If ALL stories now have `passes: true`:
- Output: `<promise>COMPLETE</promise>`
- The bash loop will see this and exit

Otherwise, output normally - the loop continues to next iteration.

## Critical Rules

- **One story per iteration** - Never combine stories
- **Fresh context** - Don't assume knowledge from previous iterations
- **Quality gates** - Never commit broken code
- **Append-only progress** - Progress.txt is your memory
