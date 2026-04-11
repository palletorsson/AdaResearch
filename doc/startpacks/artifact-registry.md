# Development Start: Artifact Registry

**Intent:** `Artifact Registry`
**Matched topic:** `artifact_registry`
**Pack slug:** `artifact-registry`
**Category:** `content`
**Tags:** `registry, artifacts, lookup, metadata, spawning`
**Generated:** `2026-04-04T11:50:50+00:00`

The artifact registry is the lookup and metadata layer between maps and scenes. Use this pack when the task is about adding artifacts, changing lookup_name metadata, understanding registry structure, or improving how artifacts are categorized and discovered.

## Trust Order
- repo files
- doc/ and docs/ contracts
- session handoffs and session summaries
- grounded wiki chat points and turns
- encyclopedia routes and source files
- DeepWiki overview

## Read First
- `commons/managers/GridArtifactRegistry.gd` — Authoritative runtime loader for registry/*.json files.
- `doc/ARCHITECTURE.md` — System-level description of artifact lookup and registry structure.
- `doc/ARTIFACT_THEME_GUIDE.md` — Metadata and categorization guide for registry entries.
- `doc/ARTIFACT_ORGANIZATION_PROPOSAL.md` — Design rationale behind modular category registries.
- `commons/artifacts/registry/primitives.json` — Representative modular registry file with live artifact entries.
- `commons/artifacts/registry/lab.json` — Registry example for lab- and tool-oriented artifacts.

## Core Principles
- registry/*.json is the authoritative source; the legacy grid_artifacts.json file is deprecated.
- lookup_name is the stable bridge between map tokens, registry metadata, and scene loading.
- Theme/category metadata should improve discovery without changing runtime identity.

## Key Constraints
- GridArtifactRegistry loads all registry/*.json files and may overwrite duplicate keys by last-loaded file.
- New metadata should stay additive and backward compatible unless you are deliberately changing loader behavior.
- Maps and sequences should refer to stable lookup_name values, not folder structure.

## Suggested First Moves
- Decide whether the work is loader behavior, registry schema, or authoring metadata.
- Check for duplicate or overlapping lookup_name entries before adding a new artifact.
- If the change is discovery-oriented, update metadata first and runtime code second.

## Relevant History
- `doc/SESSION_HANDOFF_2026-03-28.md` — - **Godot artifacts**: 42 floor patterns in `commons/artifacts/pompeii_mosaic_floor/`, Science Screen, Filter Screen (6 modes), Dark Sphere atmosphere, FloorPlanSpace
- `doc/sessions/2026-03-19-garden-session-summary.md` — Processed 38 of 42 sequences. Added titles to 313 maps. Merged 13 maps. Fixed artifact-map mismatches across 6 sequences.
- `doc/sessions/2026-03-23-continued-session.md` — Processed 38 of 42 sequences. Added titles to 313 maps. Merged 13 maps. Fixed artifact-map mismatches across 6 sequences.

## Related Docs
- `doc/ARTIFACT_THEME_GUIDE.md` — # Artifact Theme Guide
- `docs/TODO.md` — ## Registry Cleanup (2026-01-30)
- `doc/ARCHITECTURE.md` — 2. **Artifact System** — Educational object registry and spawning
- `doc/ARTIFACT_ORGANIZATION_PROPOSAL.md` — # Artifact Organization Proposal
- `doc/CLAUDE_GUIDE_TO_PLAYING_ADA_RESEARCH.md` — AdaSceneManager loads all `.json` files from the sequences directory at runtime and merges them. Each sequence file defines learning sequences (like chapters in a book). Each sequence contains:
- `doc/HOW_TO_ADD_MAP_SEQUENCE.md` — For map-building sessions, use the workbench CLI to audit spine coverage, suggest artifacts, scaffold new maps, and append them to a sequence:

## Related Repo Paths
- `commons/artifacts/category_registry.json`
- `commons/artifacts/grid_artifacts.json.deprecated`
- `commons/artifacts/registry/README.md`
- `commons/artifacts/registry/algorithms_misc.json`
- `commons/artifacts/registry/alternative_geometries.json`
- `commons/artifacts/registry/arrays.json`
- `commons/artifacts/registry/bar_array.json`
- `commons/artifacts/registry/cellular_automata.json`

## Grounded Wiki Chat Knowledge
- source project slug: `adaresearch-case-study`
- point [fact] support=3: Bridge: Maps and sequences refer to stable `lookup_name` identifiers, while registry metadata carries the bridge back to scenes, categories, tags, and sequence ownership.
- point [fact] support=3: How: `GridInteractablesComponent.gd` scans 49 registry files, validates `lookup_name`, normalizes scene paths, and merges 1,699 artifact definitions into one runtime dictionary.
- point [fact] support=3: What: Central directory of JSON registry files that define all artifacts in the project. Each file contains artifact entries with lookup names, scene paths, metadata, and configuration. This is the authoritative source for artifact definitions, loaded by ArtifactCatalogDataProvider and GridInteractablesComponent.
- point [pattern] support=1: Keep new map-facing behavior encoded in `map_data.json`, `utility_definitions`, or registry metadata rather than hardcoded scene assumptions.
- claim [fact] support=1: What: Central directory of JSON registry files that define all artifacts in the project. Each file contains artifact entries with lookup names, scene paths, metadata, and configuration. This is the authoritative source for artifact definitions, loaded by ArtifactCatalogDataProvider and GridInteractablesComponent.
- claim [fact] support=1: How: `GridInteractablesComponent.gd` scans 49 registry files, validates `lookup_name`, normalizes scene paths, and merges 1,699 artifact definitions into one runtime dictionary.
- claim [fact] support=1: Bridge: Maps and sequences refer to stable `lookup_name` identifiers, while registry metadata carries the bridge back to scenes, categories, tags, and sequence ownership.
- claim [fact] support=1: What: Central directory of JSON registry files that define all artifacts in the project. Each file contains artifact entries with lookup names, scene paths, metadata, and configuration. This is the authoritative source for artifact definitions, loaded by ArtifactCatalogDataProvider and GridInteractablesComponent.
- turn `66df209d-b3a1-4657-9cf6-522c844b3022#1` (user): ...orking on the "Ada Research Zero One" project. Take your time and do excellent work. **Task:** Merge dual registry systems **Task ID:** -untEV4J34eFwsR4F_anQ **Priority:** medium **Description:** Two parallel registry systems coexist with significant overlap: - Legacy: commons/artifacts/grid_artifacts.json (~1,015 entr...
- turn `12c4a6be-d651-49ff-9ec9-a4ca4d021cb1#448` (user): ...ps captured (4 angles each), 10 artifacts captured (4 angles each). 5 artifacts could not be found in the registry: lsystem_tree, fractal_lsystem_string, dark_sphere, lsystem_dungeon, genetic_tree_sculptor.", "entries": [ { "type": "map", "target": "LSystems_Grammar_Lab", "shots": { "above": "/audit-shots/lsystems/LSys...
- turn `12c4a6be-d651-49ff-9ec9-a4ca4d021cb1#531` (assistant): ...ite the final plan and call ExitPlanMode. Let me read the current plan file and overwrite it with the new scene catalog plan. Now let me write the new plan for the scene catalog project: Now I'll exit plan mode to present this for approval: It sounds like your message got cut off - "there came" - could you complete tha...
- turn `12c4a6be-d651-49ff-9ec9-a4ca4d021cb1#614` (user): ...uage model must consume to reach a correct answer. In an exploratory dual-agent benchmark on a real 1,971-scene codebase, fold-based navigation reached the same correct answer as traditional file exploration using 5.9x fewer inference tokens, 4x fewer tool calls, and 2.4x less wall-clock time. The result suggests that ...

## Encyclopedia Surfaces
- AI tool inventory — route `/ai` — source `src/lib/ai/tool-inventory.ts` — Useful when you want to connect artifact metadata to encyclopedia tooling surfaces.
- Map Builder — route `/map-builder` — source `src/components/map-builder/MapBuilderPage.tsx` — Relevant because map authoring consumes lookup_name artifacts from the registry layer.

## DeepWiki
- Base: https://deepwiki.com/palletorsson/AdaResearch
- Suggested topic: Artifact Registry System
- Suggested topic: Artifacts & Interactables
- Suggested topic: Map & Content Definition