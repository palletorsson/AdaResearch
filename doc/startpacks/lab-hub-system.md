# Development Start: Grid System

**Intent:** `The Lab Hub System`
**Matched topic:** `grid`
**Pack slug:** `lab-hub-system`
**Category:** `systems`
**Tags:** `grid, maps, layout, rendering, utilities`
**Generated:** `2026-04-04T11:51:04+00:00`

The grid is the stage system for AdaResearch. It turns JSON map data into structure, utilities, and interactables, and it is the right starting point for changes to layout, colors, utilities, spawning, or map-level affordances.

## Trust Order
- repo files
- doc/ and docs/ contracts
- session handoffs and session summaries
- grounded wiki chat points and turns
- encyclopedia routes and source files
- DeepWiki overview

## Read First
- `commons/grid/GridSystem.gd` — Master orchestrator for map rendering.
- `commons/grid/GridInteractablesComponent.gd` — Artifact placement and token resolution from the interactables layer.
- `commons/grid/UtilityRegistry.gd` — Single source of truth for utility token meanings.
- `doc/LAB_GRID_GUID.md` — Concrete lab-specific grid styling, progression, and the current cube colors.
- `docs/GRID_MODIFIER_AND_SPATIAL_FIT_PLAN.md` — Current extension plan for grid modifiers and artifact placement logic.
- `doc/MAP_EDITING_PIPELINE.md` — Operational map editing flow if the change touches authored map data.

## Key Constraints
- Maps use a 3-layer contract: structure, utilities, interactables.
- The lab grid currently uses off-white cubes: Color(0.95, 0.95, 0.98, 1.0).
- Lab ambient light is documented as Color(0.9, 0.9, 1.0, 0.4).
- The current plan keeps the 2.5D map format and adds complexity through modifiers, not format replacement.

## Suggested First Moves
- Decide whether the change is structural, utility-level, or interactable-level before touching code.
- Check whether the request belongs in generic GridSystem or only in lab-specific styling.
- If the change affects authored maps, inspect one representative map_data.json first.

## Relevant History
- `doc/SESSION_HANDOFF_2026-03-28.md` — Over six days, this session built the Naples-to-VR pipeline end-to-end: 42 procedural floor patterns from MANN museum photos, 27 facade presets from Italian buildings, 23 museum maps with floor plans, a floor plan editor
- `doc/sessions/2026-03-19-garden-session-summary.md` — Single session spanning ~14 hours. Started with renaming map folders, ended with 363 algorithms having identity, desire, and truth.
- `doc/sessions/2026-03-23-continued-session.md` — Single session spanning ~14 hours. Started with renaming map folders, ended with 363 algorithms having identity, desire, and truth.

## Related Docs
- `doc/CLAUDE_PROJECT_NAVIGATOR.md` — This navigator follows a **self-similar structure**: each level contains the same pattern of organization, just at different scales. Start at the level you need, zoom in or out as required.
- `doc/CLAUDE_GUIDE_TO_PLAYING_ADA_RESEARCH.md` — # Guide: How to "Play" Ada Research by Reading the Files
- `doc/CONTRIBUTING.md` — A practical first-day guide for new contributors. Read this, then start building.
- `doc/LOD_TREE.json` — "summary": "Ada Research: a Godot 4 VR/desktop game teaching algorithms through interactive 3D spaces. QFEP (Queer Feminist Enactivist Pedagogy) framework. Content chain: Sequence -> Map -> Artifact.",
- `doc/MAP_QUALITY_SYSTEM.md` — # Map Quality System
- `doc/ONBOARDING_GUIDE.md` — This guide orients anyone arriving at the Ada Research project for the first time — a new Claude session picking up mid-project, a human collaborator joining the team, or an AI assistant asked a one-off question. It is t

## Related Repo Paths
- `commons/maps/AdvancedLaboratory_Systems_Theory/map_data.json`
- `commons/maps/AdvancedLaboratory_Systems_Lab/map_data.json`
- `commons/maps/Color_Grid_Pallet/map_data.json`
- `commons/maps/GraphTheory_Push_Relabel_Algorithm/map_data.json`
- `commons/maps/LSystems_Grammar_Lab/map_data.json`
- `commons/maps/Lab/map_data_post_artmathematics.json`
- `commons/maps/Lab/map_data_post_color.json`
- `commons/maps/Lab/map_data_post_graphtheory.json`

## Grounded Wiki Chat Knowledge
- source project slug: `adaresearch-case-study`
- point [principle] support=1: New grid behavior should preserve the contract: add or update a focused component or utility definition, then keep `map_data.json` as the external source of truth.
- point [fact] support=3: Bridge: Map authors work in JSON and web tooling, while the Grid System turns the same data into walls, utilities, artifacts, spawn logic, and scene flow in VR.
- point [fact] support=3: ...ayer grabs a point, draws a line, builds a triangle. The Science Screen - a large monitor standing in the map - renders a 2D coordinate grid showing exactly what the player is doing, with live coordinates, measurements, and trails.
- point [principle] support=2: The Grid System is AdaResearch's map runtime: it turns declarative map data into explorable VR spaces, and it is the main reason hundreds of maps can stay editable without hand-authoring every scene.
- claim [principle] support=1: New grid behavior should preserve the contract: add or update a focused component or utility definition, then keep `map_data.json` as the external source of truth.
- claim [fact] support=1: ...ayer grabs a point, draws a line, builds a triangle. The Science Screen - a large monitor standing in the map - renders a 2D coordinate grid showing exactly what the player is doing, with live coordinates, measurements, and trails.
- claim [fact] support=1: Modes currently deployed through map data: `bars`, `field`, `grid`, `line`, `net`, `point`, `scatter`, `trace`, `triangle`, `wave`
- claim [fact] support=1: ...ayer grabs a point, draws a line, builds a triangle. The Science Screen - a large monitor standing in the map - renders a 2D coordinate grid showing exactly what the player is doing, with live coordinates, measurements, and trails.
- turn `531f69cf-2ddc-41b2-9bdb-3d1a36046289#99` (assistant): Continuing from where we left off. I'll tackle the three selected tasks: commit the QFEP Lab spawn fixes, implement Forces map fixes, and continue the screenshot improvement loop. Let me start by checking the current state and committing what's ready. Good. The 8 QFEP Lab spawn fixes are ready. Let me commit them and v...
- turn `66df209d-b3a1-4657-9cf6-522c844b3022#1` (user): ...s fields `nFb5-2Ixksji7dU5rNj4L` ~278 artifacts (30%) have empty map_sequences arrays. Worst offenders: - color.json: 100% empty - parametric.json: 100% empty - arrays.json: 72% empty - algorithms_misc.json: 91% empty Needs a batch script to check which maps each artifact appears in and populate the field. - [ ] Enrich...
- turn `12c4a6be-d651-49ff-9ec9-a4ca4d021cb1#448` (user): ...e, fractal_lsystem_string, dark_sphere, lsystem_dungeon, genetic_tree_sculptor.", "entries": [ { "type": "map", "target": "LSystems_Grammar_Lab", "shots": { "above": "/audit-shots/lsystems/LSystems_Grammar_Lab/above.png", "front": "/audit-shots/lsystems/LSystems_Grammar_Lab/front.png", "left": "/audit-shots/lsystems/LS...
- turn `12c4a6be-d651-49ff-9ec9-a4ca4d021cb1#614` (user): ...s the FractalNode. It has the same shape whether it represents the whole project, a domain, a registry, a map, or an artifact. interface FractalNode { id: string; kind: EntityKind; name: string; fold: string; depth: number; metrics: Record<string, number>; tags: string[]; edges: FractalEdge[]; children?: FractalNode[];...

## Encyclopedia Surfaces
- Grid Editor — route `/grid-editor` — source `src/components/grid-editor/GridCanvas.tsx` — 2D editing surface for tile/grid changes.
- Map Builder — route `/map-builder` — source `src/components/map-builder/MapBuilderPage.tsx` — Higher-level map composition and analysis flow.
- Project context store — source `src/app/api/context/route.ts` — Reusable place to persist derived clauses, formulas, and patterns.

## DeepWiki
- Base: https://deepwiki.com/palletorsson/AdaResearch
- Suggested topic: Grid System
- Suggested topic: Grid System Architecture
- Suggested topic: Map Data Format
- Suggested topic: Artifact Registry System