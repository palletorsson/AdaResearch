# Skill Workflow

This document defines the standard skill-driven workflow for AdaResearch tasks.

Use this as the default execution chain for PR work.

## Core Chain

1. `ada-navigator`
   - Scope the request.
   - Identify touched files, dependencies, and risks.

2. Build skill (pick one or more)
   - Examples: `ada-artificer`, `ada-cartographer`, `ada-gamemanager`, `ada-substrate-explorer`.
   - Implement the requested feature/fix in code and content.

3. `ada-auditor`
   - Run relevant validation/audit checks.
   - Confirm no broken references in the content chain.

4. `ada-chronicler`
   - Update docs/onboarding/changelogs when behavior, policy, or workflow changes.

5. `ada-code-specialist` (when code/performance is touched)
   - Review quality, consistency, and VR performance impact.

6. `adaresearch-work-summary` (before merge)
   - Summarize what changed, why, and where.

## PR Evidence Requirements

For each PR, include:

- Skills used (from the core chain).
- Validation commands and outcomes.
- Files changed and intent.
- Any N/A decisions (for skipped steps).

## Recommended Mapping

- Feature work: full chain (1 -> 6).
- Bug fix: full chain (1 -> 6), with focused validator evidence.
- Docs-only: 1, `ada-chronicler`, `adaresearch-work-summary` (mark code/perf checks as N/A).
- Data-only/content-only: 1, build skill, `ada-auditor`, `ada-chronicler`, `adaresearch-work-summary`.

## Notes

- The goal is not box-ticking; it is reducing regressions and making intent explicit.
- If you skip a step, record why in the PR.
