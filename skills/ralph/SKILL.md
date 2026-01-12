---
name: ralph
description: Convert PRD to prd.json format for autonomous agent execution. Use /ralph after creating a PRD with /prd to prepare for autonomous implementation loop.
---

# Ralph PRD Converter

Convert PRD markdown documents into `prd.json` format for the Ralph autonomous execution loop.

## When to Use

After running `/prd` to generate a PRD, or `/ultraplan` to create a SPEC.md, run `/ralph` to prepare for autonomous execution.

## Workflow

### 1. Find Source Document

Check for source documents in order of preference:
1. User-specified file
2. Recent `tasks/*/prd-*.md` or `tasks/prd-*.md`
3. `SPEC.md` in current directory (from Ultraplan)

If multiple options, ask user which to convert.

### 2. Determine Feature Name and Directory

If source is in `tasks/{name}-{suffix}/`, use that directory.

If creating new (from SPEC.md):
- Extract feature name from content
- Generate 5-character random suffix: `LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 5`
- Create directory: `tasks/{feature-name}-{suffix}/`

### 3. Convert to prd.json

**If source is PRD markdown** (from /prd):
- Parse user stories directly
- Validate story sizing

**If source is SPEC.md** (from /ultraplan):
- Extract requirements sections
- Break into atomic user stories (each completable in one context)
- Order by dependencies (DB → Backend → Frontend)
- Use AskUserQuestion to validate story breakdown with user

### 4. Validate Stories

Before writing, verify:
- Each story is atomic (2-3 sentence description max)
- Dependencies ordered correctly
- All criteria are verifiable (not vague)
- Every story has "Typecheck passes" criterion
- UI stories have "Verify in browser" criterion

**Story Too Large?** Signs:
- More than 4-5 acceptance criteria
- Touches more than 3 files
- Description requires multiple paragraphs
- Contains "and" connecting separate features

Break down large stories and re-validate.

### 5. Generate JSON

```json
{
  "project": "ProjectName",
  "branchName": "ralph/feature-name",
  "description": "One-line feature description",
  "userStories": [
    {
      "id": "US-001",
      "title": "Short title",
      "description": "As a [user], I want [goal] so that [benefit].",
      "acceptanceCriteria": [
        "Specific criterion 1",
        "Typecheck passes"
      ],
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

### 6. Initialize Progress

Create `tasks/{feature}-{suffix}/progress.txt`:
```
# Ralph Progress Log - {feature-name}
Started: [date]
---
```

### 7. Offer Execution Choice

After conversion is complete, use AskUserQuestion to ask:

**Question:** "PRD converted with {N} user stories. How would you like to proceed?"

**Options:**
1. **"Watch it work"** (Recommended) - Run in a separate terminal so you can watch the agent in real-time
2. **"Run in background"** - Claude runs `ralph.sh` in background, monitors progress, reports when complete
3. **"I'll handle it"** - Just give me the command

**If user chooses "Watch it work":**
Tell user to open a new terminal and run:
```bash
ralph.sh {feature-name}
```
Explain: "You'll see each iteration's full output - file reads, code changes, test runs, commits. Can't interact mid-story, but full visibility."

**If user chooses "Run in background":**
1. Use Bash tool with `run_in_background: true` to execute:
   ```bash
   ralph.sh {feature-name} 2>&1
   ```
2. Tell user: "Ralph is running in the background. I'll monitor progress and let you know when it completes or needs attention."
3. Periodically check the background task output
4. Report completion or any issues that need user intervention

**If user chooses "I'll handle it":**
Provide the command:
```
ralph.sh {feature-name}
```

## Multiple Features

Each feature gets its own subdirectory with unique suffix:
```
tasks/
├── auth-system-x7k2m/
│   ├── prd.json
│   └── progress.txt
├── auth-system-p3n9q/    # Second run of same feature
│   ├── prd.json
│   └── progress.txt
└── billing-a2b4c/
    ├── prd.json
    └── progress.txt
```

Run specific feature: `ralph.sh auth-system` (matches first found)
Run exact directory: `ralph.sh auth-system-x7k2m`

## Reference

See [references/iteration-workflow.md](references/iteration-workflow.md) for what happens during each Ralph iteration.

## History

Created 2025-01-12 to support Ralph autonomous agent loop. Uses random suffix for unique feature directories.
