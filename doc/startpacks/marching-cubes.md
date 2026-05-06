# Development Start: Generic development start for: Space Topology and Marching Cubes

**Intent:** `Space Topology and Marching Cubes`
**Matched topic:** `generic`
**Pack slug:** `marching-cubes`
**Category:** `exploration`
**Tags:** `space, topology, and, marching, cubes`
**Generated:** `2026-04-04T12:23:39+00:00`

No curated starter pack matched exactly. This pack is assembled from document hits and repo path matches, so it is useful for discovery but less trustworthy than a curated topic profile.

## Trust Order
- repo files
- doc/ and docs/ contracts
- session handoffs and session summaries
- grounded wiki chat points and turns
- encyclopedia routes and source files
- DeepWiki overview

## Suggested First Moves
- Refine the intent into a system noun if possible, then rerun this tool.
- Use tools/lod_query.py when you know the sequence, map, or artifact name.

## Relevant History
- `doc/SESSION_HANDOFF_2026-03-28.md` — # Session Handoff: March 23-28, 2026
- `doc/sessions/2026-03-19-garden-session-summary.md` — Single session spanning ~14 hours. Started with renaming map folders, ended with 363 algorithms having identity, desire, and truth.
- `doc/sessions/2026-03-23-continued-session.md` — Single session spanning ~14 hours. Started with renaming map folders, ended with 363 algorithms having identity, desire, and truth.

## Related Docs
- `doc/AlgorithmsList.md` — - Tron Grid Navigation - Spatial reference and coordinate systems
- `doc/CompliteAlgorithms.md` — Tron grid navigation and spatial references
- `doc/LOD_TREE.json` — "summary": "Ada Research: a Godot 4 VR/desktop game teaching algorithms through interactive 3D spaces. QFEP (Queer Feminist Enactivist Pedagogy) framework. Content chain: Sequence -> Map -> Artifact.",
- `doc/NATURE_SYSTEM_PLAN.md` — > **potential under restraint** — and the restraint can change. A poison
- `doc/TAXONOMY.md` — > How do we encode form? What primitives and operations are needed?
- `doc/reports/ARTIFACT_REGISTRY_AUDIT.json` — "scene_path": "res://commons/primitives/cubes/animated_cube.tscn",

## Related Repo Paths
- `algorithms/spacetopology/marchingcubes/FastCPULandscapeCaveGenerator.gd`
- `algorithms/spacetopology/marchingcubes/FastCPULandscapeCaveGenerator.gd.uid`
- `algorithms/spacetopology/marchingcubes/FastLandscapeCaveGenerator.gd`
- `algorithms/spacetopology/marchingcubes/FastLandscapeCaveGenerator.gd.uid`
- `algorithms/spacetopology/marchingcubes/LandscapeCaveGenerator.gd`
- `algorithms/spacetopology/marchingcubes/LandscapeCaveGenerator.gd.uid`
- `algorithms/spacetopology/marchingcubes/fast_landscape_demo.tscn`
- `algorithms/spacetopology/marchingcubes/gpu_landscape_demo.tscn`

## Grounded Wiki Chat Knowledge
- source project slug: `adaresearch-case-study`
- point [pattern] support=1: 1. Primary Request and Intent: - **Shader on grid cubes**: User wanted the actual grid wall cubes (rendered via GridMultiMesh) to display GPU shader patterns - "target the grid cubes" - not just flat colors - **Patchwork tile tu...
- point [decision] support=1: Key finding: GridSystem uses **MultiMesh** for all structure cubes - can't apply different shaders per cube. But we can use `wall_cove` with `wall_extend` to cover both the slope AND wall surface.
- point [fact] support=3: Bridge: Map authors work in JSON and web tooling, while the Grid System turns the same data into walls, utilities, artifacts, spawn logic, and scene flow in VR.
- point [fact] support=3: Bridge: Maps and sequences refer to stable `lookup_name` identifiers, while registry metadata carries the bridge back to scenes, categories, tags, and sequence ownership.
- claim [decision] support=1: Key finding: GridSystem uses **MultiMesh** for all structure cubes - can't apply different shaders per cube. But we can use `wall_cove` with `wall_extend` to cover both the slope AND wall surface.
- claim [pattern] support=1: 1. Primary Request and Intent: - **Shader on grid cubes**: User wanted the actual grid wall cubes (rendered via GridMultiMesh) to display GPU shader patterns - "target the grid cubes" - not just flat colors - **Patchwork tile tu...
- claim [principle] support=1: Repo and chat-grounded overview for AdaResearch 46.
- claim [principle] support=1: Grounded page for AdaResearch's sequence, map, validation, and VR iteration pipeline.
- turn `531f69cf-2ddc-41b2-9bdb-3d1a36046289#121` (assistant): Continuing with artifact screenshot work. Let me review the remaining 5 batch 8 screenshots and start preparing the next batches. **Batch 8 remaining review:** - **coordinate_system_switcher**: ✅ PASS - 3D axes with Cartesian/Spherical coordinate labels, white point marker - **coupled_pendulums**: ✅ PASS - Red & blue p...
- turn `12c4a6be-d651-49ff-9ec9-a4ca4d021cb1#23` (user): can you make the interface a bit more light and out line the cubes so I see them better
- turn `12c4a6be-d651-49ff-9ec9-a4ca4d021cb1#206` (user): * Waveform should be a continuous helix double * branching branch forward and branch more * Swarms should swarm separate look for targets * Cellular automata should be cubes with rules slower * Color should color every cube in the grid it hits
- turn `12c4a6be-d651-49ff-9ec9-a4ca4d021cb1#214` (user): I love the color gun! For Transform cubes in scene scale down move a bit and rotate a bit scale a bit, for fractals if I shoot a cube spawn two new cubes.

## DeepWiki
- Base: https://deepwiki.com/palletorsson/AdaResearch
- Suggested topic: Overview