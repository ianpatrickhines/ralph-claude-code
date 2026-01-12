---
name: prd
description: Generate structured Product Requirements Documents for autonomous agent execution. Use when planning a feature that will be implemented by Ralph (the autonomous agent loop). Creates atomic user stories sized for single context windows.
---

# PRD Generator

Generate PRDs optimized for autonomous agent execution. Unlike traditional PRDs, these are structured for iterative implementation by AI agents with fresh context per iteration.

## Core Principle: Atomic Stories

**Each user story must be completable in one agent context window.** If you cannot describe the change in 2-3 sentences, it's too big.

Good: "Add priority column to tasks table"
Bad: "Build authentication system"

## Workflow

### 1. Receive Feature Description

Get the high-level feature request from the user.

### 2. Ask Clarifying Questions

Use AskUserQuestion with 3-5 focused questions. Cover:
- Core functionality scope
- Technical constraints (existing DB? API patterns?)
- UI requirements (if applicable)
- Success criteria

### 3. Determine Feature Name

Create a kebab-case name from the feature:
- "User authentication" → `user-auth`
- "Task priority system" → `task-priority`

### 4. Generate Random Suffix

Create a 5-character random suffix for uniqueness:
```bash
LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 5
```

Example: `user-auth` → `user-auth-x7k2m`

### 5. Generate PRD

Write to `tasks/{feature-name}-{suffix}/prd-{feature-name}.md`:

```markdown
# [Feature Name]

## Overview
[1-2 sentences: what and why]

## Goals
- [Specific, measurable objective]

## User Stories

### US-001: [Title]
**As a** [user type], **I want** [goal] **so that** [benefit].

**Acceptance Criteria:**
- [ ] [Specific, verifiable criterion]
- [ ] Typecheck passes

### US-002: [Title]
...

## Non-Goals
- [What this feature explicitly excludes]

## Technical Considerations
- [Constraints, integrations, patterns to follow]

## Open Questions
- [Anything unresolved]
```

## Story Ordering Rules

Dependencies must come first:
1. Database/schema changes
2. Backend logic/API
3. Frontend/UI components
4. Integration/polish

## Acceptance Criteria Rules

- **Verifiable, not vague**: "Add status column with default 'pending'" not "Works correctly"
- **Every story ends with**: "Typecheck passes"
- **UI stories add**: "Verify in browser using webapp-testing skill"

## Output Location

```
tasks/
└── {feature-name}-{suffix}/
    └── prd-{feature-name}.md
```

This structure supports multiple parallel features and multiple runs of the same feature.

## After PRD Creation

Tell the user:
```
PRD created at tasks/{feature-name}-{suffix}/prd-{feature-name}.md

Next step: Run /ralph to convert to prd.json for autonomous execution.
```

## History

Created 2025-01-12 to support Ralph autonomous agent loop. Uses random suffix for uniqueness.
