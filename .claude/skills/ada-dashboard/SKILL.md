---
name: ada-dashboard
description: Runs the project dashboard CLI to check coverage, recommend next tasks, gather map context, and track sequence completeness. Use when starting a session, deciding what to work on, or checking progress. Triggers - "what should I work on", "show status", "check coverage", "recommend", "what's missing", "near wins".
argument-hint: "[status/recommend/nearwin/sequence NAME/context MAPNAME/tasks/missing/postlab/phase]"
allowed-tools: Bash, Read, Glob, Grep
---

# Ada Dashboard

You run the project dashboard CLI to orient sessions and drive work decisions. The CLI reads `sequence_requirements.json` and cross-references the filesystem to report what's complete and what's missing.

## Full Onboarding Doc

**Read this first if this is a new session:**

```
commons/tools/PROJECT_DASHBOARD_CLI.md
```

That file contains the complete AI onboarding guide — project context, all CLI modes, writing guidelines, session workflow, exemplar files, and multi-AI environment description.

## Quick Reference

The CLI lives at `commons/tools/project_dashboard_cli.ps1`. Run from the project root:

```bash
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode <mode> [-Name <name>] [-Format <format>]
```

## Commands

Based on `$ARGUMENTS`:

### `recommend` (default)
Run the strategic recommendation engine. Shows near-wins, blurb-complete sequences, phase completion, post-lab gaps, and a concrete next-session suggestion.

```bash
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode recommend
```

Present the output to the user and discuss what to work on.

### `status`
Overview stats — sequence counts, map totals, book/wiki readiness, missing .md counts.

```bash
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode status
```

### `nearwin`
Ranked table of all incomplete sequences sorted by fewest missing files.

```bash
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode nearwin
```

### `sequence NAME`
Deep dive into one sequence — coverage, layers, exact missing file paths.

```bash
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode sequence -Name <NAME>
```

### `context MAPNAME`
Gather everything needed to write .md files for a map — sequence position, QFEP context, algorithm sources, neighboring maps.

```bash
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode context -Name <MAPNAME>
```

### `tasks`
Full task list sorted by priority (CRITICAL/PARTIAL/WARNING).

### `missing`
Flat list of all missing .md file paths.

### `postlab`
Post-lab map status for all sequences.

### `phase`
Sequences grouped by QFEP phase with book/wiki indicators.

## Session Workflow

1. Run `recommend` to orient
2. Choose a target sequence (near-win or user preference)
3. Run `sequence <name>` to get missing file paths
4. Run `context <mapname>` for each map to gather writing context
5. Read exemplar files: `commons/maps/Point_One/` (all four .md types)
6. Write the .md files following guidelines in `commons/tools/PROJECT_DASHBOARD_CLI.md`
7. Run `sequence <name>` again to verify completion

## Integration

- Pairs with `/ada-task-manager` for Oversight server task tracking
- Pairs with `/ada-queer-theory-expert` for critical.md writing
- Pairs with `/ada-code-guide` for technical.md writing
- Pairs with `/ada-map-expert` for summary.md spatial descriptions
