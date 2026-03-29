# Session Handoff: March 23-28, 2026

## Session Summary

Over six days, this session built the Naples-to-VR pipeline end-to-end: 42 procedural floor patterns from MANN museum photos, 27 facade presets from Italian buildings, 23 museum maps with floor plans, a floor plan editor, a meander editor (14 iterations, unsolved), 16 web primitive editors, the LOD context system, the heat map autonomous work loop, and 30+ blog posts documenting the research. The current state is stable: floor height and flight mode bugs are resolved, the `/continue` skill drives autonomous work via heat map, and 7 empty sequences remain the biggest gap.

## What Works

- **LOD context system** — `python tools/lod_query.py <topic>` returns fractal-depth context. Tree at `doc/LOD_TREE.json`.
- **Heat map** — `python tools/heat_map_generator.py` scores every system by temperature. Output: `doc/HEAT_MAP.json`.
- **`/continue` skill** — reads heat map, picks hottest item, acts on it, regenerates.
- **`/ada-researcher` skill** — autonomous deep thinking agent.
- **Web editors** (encyclopedia at `localhost:3003`):
  - `/map-builder` — 3-layer map editor with AI generation
  - `/mosaic-editor` — carpet composer with ring stack UI, 7 MANN presets
  - `/facade-builder` — 52 SVG glyphs, 27 presets, v2 plan JSON
  - `/pattern-maker` — wallpaper group editor, 59 patterns in catalog
  - `/voxel-editor`, `/grid-editor`, `/floor-plan-editor`
  - `/primitives/*` — 16 interactive primitive editors (point through procedural generation)
  - `/work` — mission center dashboard
- **Godot artifacts**: 42 floor patterns in `commons/artifacts/pompeii_mosaic_floor/`, Science Screen, Filter Screen (6 modes), Dark Sphere atmosphere, FloorPlanSpace
- **MosaicFloorBuilder** — `commons/grid/MosaicFloorBuilder.gd`, 9 motifs
- **Facade system** — `commons/facade_parts/` with FacadePartLibrary, FacadeComposer, 42 parts in 9 category files
- **Museum maps** — 23 maps with floor plans, facades, mosaic floors, all in sequences
- **Capture pipeline** — `capture_multi_angle.gd` for 4-angle screenshots of maps and artifacts

## What's Broken

- **Museum VR walkability** — floor height was fixed (commit `64ce68bf`, y_offset 90->0) but many maps haven't been VR-tested. Quality over quantity needed.
- **Wall colliders** — disabled globally to stop blocking doorways. Need selective re-enable.
- **Guilloche border motif** — pixel-grid approximation, could be smoother.
- **Web mosaic editor borders** — don't match `border_motifs.gd` system yet.
- **Captures stale** — many artifacts changed since last capture batch.
- **22 museum maps untested in VR** — built fast, verification is slow.

## What's Next (from HEAT_MAP.json + FOCUS_VECTOR.json)

**Hot (temperature 75-80):** Floor patterns and facades — active, continue iterating.

**Warm (65):** Mosaic, pattern, LOD, meander, capture — all active, all need continued work.

**Cold (50) — 7 empty sequences need maps:**
- Advanced Laboratory, Critical Algorithms, Morphogenesis, Resource Management, Search & Pathfinding, Speculative Computation, Vectors

**Focus vector primary:** Wire real data into the mission center, fix remaining VR walkability.

**Directions to explore:** Continuous meander (per-stone freedom), complete remaining 4 primitive editors, aedicula facade frame, Science Screen placement in museum maps.

## Key Files

| System | Path |
|--------|------|
| Floor patterns | `commons/artifacts/pompeii_mosaic_floor/` |
| Shared palette | `commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd` |
| Border motifs | `commons/artifacts/pompeii_mosaic_floor/border_motifs.gd` |
| MosaicFloorBuilder | `commons/grid/MosaicFloorBuilder.gd` |
| Facade parts | `commons/facade_parts/` |
| Facade presets | `commons/facade_parts/presets/` |
| Floor plan space | `commons/artifacts/floor_plan_space/floor_plan_space.gd` |
| FloorPlanLoader | `commons/grid/FloorPlanLoader.gd` |
| Museum maps | `commons/maps/*/floor_plan.json` |
| Science Screen | `commons/artifacts/science_screen/` |
| Filter Screen | `commons/artifacts/filter_screen/` |
| LOD query | `tools/lod_query.py` + `doc/LOD_TREE.json` |
| LOD tree gen | `tools/lod_tree_generator.py` |
| Heat map | `tools/heat_map_generator.py` + `doc/HEAT_MAP.json` |
| Focus vector | `doc/FOCUS_VECTOR.json` |
| Artifact registries | `commons/artifacts/registry/*.json` |
| Curriculum spine | `commons/maps/curriculum_spine.json` |
| Encyclopedia | `C:\Users\palle\Documents\GitHub\ada_encyclopedia\` |
| Primitives (web) | `ada_encyclopedia/src/app/primitives/` |
| Primitive ontology | `doc/PRIMITIVE_ONTOLOGY.md` |

## How to Start

```bash
# 1. See what needs work (hottest items first)
python tools/heat_map_generator.py

# 2. Load context for any topic
python tools/lod_query.py meander
python tools/lod_query.py pompeii_mosaic_floor

# 3. Or just use the autonomous loop
/continue

# 4. For deep research on a concept
/ada-researcher

# 5. Check project status
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode status
```

## Blog Posts (this session, 30+)

In `ada_encyclopedia/public/blog/`:
- `2026-03-24-fifteen-floors` — 15 floor patterns built from MANN photos
- `2026-03-24-floor-plan-editor` — floor plan editor launch
- `2026-03-24-galleria-facades` — Galleria Vittorio Emanuele facade
- `2026-03-24-grand-museum` / `three-museums` — museum map construction
- `2026-03-25-all-maps-verify` — verification pass on all maps
- `2026-03-25-grid-as-governance` — the grid as a governance system (theory)
- `2026-03-25-mega-galleries` / `seven-museums` — scaling to 7+ museums
- `2026-03-25-mosaic-encyclopedia` — pattern catalog launch
- `2026-03-25-pattern-histories` — historical context per pattern
- `2026-03-25-queer-patterns` — queer reading of Roman mosaics
- `2026-03-25-naples-presentation` — 25-slide Swedish research presentation
- `2026-03-26-before-after` — before/after comparisons
- `2026-03-26-building-as-knowing` — epistemology of procedural building
- `2026-03-26-discoveries` — session discoveries summary
- `2026-03-26-meander-iterations` — 14 iterations documented
- `2026-03-26-qfep-methodology` — QFEP framework explained
- `2026-03-26-space-filling-ontology` — discrete vs continuous, Cantor
- `2026-03-27-2d-3d-knowledge-loop` — 2D web + 3D VR methodology
- `2026-03-27-primitives-side-by-side` — all 16 primitives
- `2026-03-27-what-primitives-teach` — toward queer simulations
- `2026-03-28-all-should-know-all` — knowledge sharing philosophy
- `2026-03-28-autonomous-researcher` — `/ada-researcher` skill
- `2026-03-28-lod-deep-research` — LOD system for AI context
- `2026-03-28-mission-center` — `/work` dashboard

## The Meander Problem (Unsolved)

14 iterations across 3 approaches, all documented in `2026-03-26-meander-iterations`.

**Approaches tried:** (1) Tile-based with 3-tile set (v1-v8), (2) boundary function with continuous math (v9-v13), (3) tile-free pattern decision (v14, labeled BREAKTHROUGH but still grid-snapped).

**Key insight:** Tiles repeat, mosaics don't. Every tile-based approach produces identical repeated hooks because the decision of which tile to place is made per-cell, and cells are identical. Real mosaics have per-stone freedom on continuous coordinates. The boundary function `sin(x) * sin(y) > threshold` produces correct topology but rendering still snaps to a tile grid.

**Next step:** Render the meander on continuous coordinates with per-stone placement. The boundary function defines where dark/light regions are; individual tesserae should be placed freely within those regions, with irregular sizes and slight misalignment. This is not jitter (tried in v14, looked identical) -- the DECISION of stone placement must be free, not just the rendering position.

**Artifacts:** `tile_meander_floor.gd` (best tile version), `free_meander_floor.gd` (boundary function), `braid_meander_floor.gd` (topology-first).

## Productive Patterns

1. **Multi-agent parallel** — Launch 3-5 agents for independent tasks (10x throughput). Watch for registry file conflicts.
2. **Capture-screenshot-iterate** — Build, capture Godot screenshot, evaluate, fix, recapture. Set max iterations to avoid infinite loops.
3. **Blog-as-thinking** — Write about the problem to clarify thinking. Writing IS thinking. Breakthrough-level effectiveness.
4. **Museum-photo-to-artifact** — Photo in museum, analyze pattern, build procedural artifact, compare. The gap between photo and render IS the research data.
5. **Web-first-then-Godot** — Build 2D web editor first (fast iteration), then port to 3D. Every successful pipeline started this way.
6. **LOD-guided context** — Use `lod_query.py` instead of reading everything. Fractal depth: overview -> sequence -> map -> artifact -> function.
7. **Heat-map-driven `/continue`** — Temperature = priority. Fix blockers (90) before active work (60-80) before empty sequences (50).
8. **Solve above, project down** — When stuck, go UP one abstraction level. Define the rule/topology first, then project onto implementation.

**Anti-patterns to avoid:** Tile-first thinking (start with topology, not tiles), building too many maps without VR testing, jitter-as-freedom (adding noise to tile positions does not create mosaic freedom).
