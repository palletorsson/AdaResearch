---
name: ada-bridge-listener
description: Reads feedback from Godot via desktop_feedback.md — checks for new messages and acts on them automatically (bug reports, feature requests, artifact tasks)
argument-hint: "[check/act]"
allowed-tools: Bash, Read, Grep, Glob, Edit, Write
---

# Ada Bridge Listener

You read messages from Godot written to `ada_run/desktop_feedback.md`. The user writes comments in the Artifact Catalog or Map Catalog comment panel, and they appear as markdown entries in this file. Your job is to read new messages and **act on them automatically**.

## Commands

Based on `$ARGUMENTS`:

- **`check`** (default): Read the feedback file, find the latest unprocessed entries, report them, and **act on any actionable requests**.
- **`act`**: Same as check but emphasize executing tasks immediately.

## Feedback File

Path: `ada_run/desktop_feedback.md`

Each entry looks like:
```markdown
## 2026-02-20T10:43:50 | Artifact Catalog
- Artifact: `bifurcation_diagram`
- Scene: `res://commons/artifacts/placeholders/ArtifactPlaceholder.tscn`
- Sequence: `foundationscrisis`
- Source: `ArtifactCatalogDesktop3D`

[artifact:bifurcation_diagram] this artifact is just a place holder, can you create it?
```

## How to Process

1. Read `ada_run/desktop_feedback.md`
2. Find entries that haven't been acted on yet (look at timestamps, focus on the latest entries)
3. For each new entry, determine the action:

### Action Types — ACT AUTOMATICALLY, DO NOT ASK

**Placeholder/Missing Scene:**
If the comment mentions "placeholder" or the scene path contains `placeholders/`, the artifact needs to be built.
→ Look up the artifact in `commons/artifacts/registry/*.json` for its description, QFEP connection, and expected behavior. Then BUILD IT — create the .gd and .tscn files.

**Bug Report:**
If the comment describes a visual bug (e.g., "falling off edge", "not rotating", "too big").
→ Read the artifact's .gd script, find the issue, and FIX IT.

**Feature Request:**
If the comment asks to add something (e.g., "add button interface", "add reset").
→ Read the artifact's .gd script and ADD the requested feature.

**Map Issue:**
If the comment mentions `[map:MapName]` with instructions like "remove from sequence".
→ Read the relevant sequence JSON and map_data.json, and make the requested change.

**General Feedback:**
If the comment is just observation or praise, acknowledge it briefly.

## Important Rules

- **ACT FIRST, REPORT AFTER** — don't ask permission, just do the work
- Follow existing artifact patterns: `extends Node3D`, procedural mesh creation in `_ready()`, VR interactable preloads, keyboard fallbacks, `reset()` method
- Use `const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")` and `const SLIDER_HORIZONTAL = preload("res://commons/interactables/slider_horizontal.tscn")` for VR controls
- Player detection: `body.is_in_group("player") or body.is_in_group("player_body")`
- GDScript type inference: use explicit `float` types, `absf()` not `abs()`, cast Dictionary values

## Key Reference Paths

```
ada_run/desktop_feedback.md                # Feedback file (THE SOURCE)
commons/artifacts/registry/*.json          # Artifact registries
commons/maps/sequences/*.json              # Sequence definitions
commons/maps/<MapName>/map_data.json       # Individual maps
commons/interactables/push_button.tscn     # VR push button
commons/interactables/slider_horizontal.tscn # VR slider
```
