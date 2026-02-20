---
name: ada-knowledge-updater
description: Scans the Ada Research codebase and updates system knowledge references with current state — algorithms, maps, sequences, registries, managers
argument-hint: "[area]"
allowed-tools: Read, Grep, Glob, Bash(ls *), Bash(wc *)
---

# Ada Research System Knowledge Updater

You are updating the system knowledge for the Ada Research project — a VR educational platform built in Godot 4.6 that teaches computational algorithms through immersive 3D experiences.

## Your Task

Scan the codebase and produce an updated knowledge snapshot. If `$ARGUMENTS` specifies an area (e.g., "randomness", "maps", "sequences", "registries", "managers", "all"), focus on that area. Otherwise scan everything.

## What to Scan

### 1. Algorithm Inventory
- Scan `algorithms/` for all subdirectories (22 major domains, 100+ implementations)
- Note any new/untracked algorithms (check git status for `??` entries under algorithms/)
- Count implementations per domain
- Flag any algorithms missing from artifact registries

### 2. Map Inventory
- Scan `commons/maps/*/map_data.json` for all maps
- Count total maps, note any new ones
- Check for maps referencing artifacts that don't exist in registries

### 3. Sequence Inventory
- Scan `commons/maps/sequences/*.json` for all sequences
- List sequence names, map counts, unlock requirements
- Check for sequences referencing maps that don't exist

### 4. Registry Inventory
- Scan `commons/artifacts/registry/*.json` for all artifact registries
- Count artifacts per registry
- Flag artifacts where `scene` path doesn't point to an existing file

### 5. Manager/Singleton Status
- Check `project.godot` for autoloaded singletons
- Scan `commons/managers/*.gd` for manager scripts
- Note any managers not registered as autoloads

### 6. Addon Inventory
- Scan `addons/` for all plugins
- Note their purpose from plugin.cfg files

## Output Format

Write the results to `.claude/skills/ada-knowledge-updater/SYSTEM_KNOWLEDGE.md` as a structured reference document. Include:
- Date of scan
- Summary counts (algorithms, maps, sequences, artifacts, managers)
- Per-domain breakdowns
- Any warnings (broken references, missing files, orphaned artifacts)
- A "What's New" section highlighting changes since last scan (if previous SYSTEM_KNOWLEDGE.md exists)

## Key Project Paths

```
algorithms/                          # All algorithm implementations
commons/maps/*/map_data.json        # Individual map definitions
commons/maps/sequences/*.json       # Sequence definitions
commons/maps/Lab/map_data*.json     # Lab state maps (post-sequence)
commons/artifacts/registry/*.json   # Artifact registries (per-domain)
commons/artifacts/grid_artifacts.json # Legacy master artifact registry
commons/managers/*.gd               # Manager singletons
commons/grid/*.gd                   # Grid system components
commons/scenes/*.tscn               # Core scenes
addons/                             # Editor plugins
Helpers/*.gd                        # Global utility scripts
doc/                                # Documentation
```

## Important

- Do NOT modify any source code or game files
- Only write to `.claude/skills/ada-knowledge-updater/SYSTEM_KNOWLEDGE.md`
- Be precise with counts — actually count, don't estimate
- Report broken references clearly so they can be fixed
