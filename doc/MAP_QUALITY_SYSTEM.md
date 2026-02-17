# Map Quality System

Entry point for creating, validating, and improving `map_data.json` files.

## Overview

Every map in AdaResearch is a `map_data.json` with three layers:
- **Structure** — the voxel grid (floor, walls, platforms, voids)
- **Utilities** — spawn, teleporters, ramps, lights, text
- **Interactables** — artifacts placed in the space

Each layer has its own quality language. Structure uses the **Voxel Grammar**. Interactables use **Artifact Directionality**. Utilities have **syntax rules**. The validator checks all three.

## The Three Quality Languages

### 1. Structure: Voxel Grammar

**Source:** `grammar/grammar_structue.json`  
**Module catalog:** `commons/maps/Structure_Examples/voxel_grammar_subset.json`

Height values in the structure layer:
| Value | Meaning |
|-------|---------|
| `0` | Void (absence, negative space) |
| `1` | Floor (walkable) |
| `2` | Platform/plinth (raised walkable) |
| `3` | Wall/pillar (barrier) |
| `4+` | Accent wall, buttress, tower |

Five grammar categories:
- **Primitives** — Floor, Void, Platform, Pillar, Wall, Gate, Plinth, Ramp
- **Operators** — Place, Repeat, Rotate, Mirror, Translate, Stack Height, Carve Void, Split, Merge, Slip/Shear, Phase Shift, Portal Link
- **Spatial Roles** — Center, Edge, Corner, Threshold, Corridor, Node, Buffer, Court
- **Between** — T-Junction, Cross-Junction, Doorway Cut, Window Slit, Pier Gate, Buttress, Dogleg, S-Bend, Chicane, Vestibule
- **Beyond** — Pocket Court, Perimeter Court, Split Court, Plinth Field, Colonnade, Mirror-With-Error, Japanese Garden, Templar Compound, Amphitheatre, Fortress, Pyramid Terrace

Six thinking frameworks:
1. Local to Global — small rules generate large behavior
2. Figure and Ground — solid and void are equally authored
3. Compression and Release — narrow-to-wide creates rhythm
4. Symmetry and Error — one deviation makes order memorable
5. Threshold Literacy — doors mark cognitive state changes
6. Topology Awareness — portals alter adjacency beyond Euclidean layout

### 2. Interactables: Artifact Directionality

**Reference:** `skills/ada-spatial-designer/references/artifact-directionality.md`

Every artifact has a **footprint shape** determining how it claims surrounding space:

| Footprint | Description | Space Claim |
|-----------|-------------|-------------|
| **Full Circle (360°)** | Freestanding, no front/back | ≥1 clear cell all directions |
| **Half Circle (180°)** | Has a back (wall) and front | Back can touch wall, front clear |
| **Cone (~90°)** | Projects content one direction | 2-3 clear cells in viewing direction |
| **Corridor (Linear)** | Walk-through artifact | Clear entry and exit |
| **Ambient** | Atmosphere, no specific approach | Anywhere |

**Rotation convention:**
```
rotation:0   → faces South (increasing row)
rotation:90  → faces West (decreasing col)
rotation:180 → faces North (decreasing row)
rotation:270 → faces East (increasing col)
```

**Placement format:** `artifact_name:rotation:y_offset:scale`

### 3. Utilities: Syntax Rules

| Utility | Format | Notes |
|---------|--------|-------|
| `s` | `s` or `s:x:y:z` | Spawn point |
| `t` | `t` or `t:destination` | Teleporter |
| `wp` | `wp:rotation` | Walkable ramp |
| `tc` | `tc:distance:direction` | Transport cube (vertical) |
| `m` | `m` or `m:delay` | Move player |
| `an` | `an` or `an:rotation` | Annotation board |
| `el` | `el:energy:hide` | Extra light |
| `3t` | `3t:text` | 3D text display |

**Hard rule: No `l` (lift).** Use `tc` for all vertical movement.

## Spatial Temperature

Maps diversify as players progress through the curriculum. Temperature (= λ in QFEP) guides complexity:

| Temperature | Structure | When |
|-------------|-----------|------|
| ~0.0 | Flat arena, all floor | First encounter maps |
| ~0.2 | Some platforms (h2), simple | Early sequences |
| ~0.4 | Walls, height variation | Mid sequences |
| ~0.6 | Multi-level, voids, corridors | Advanced content |
| ~0.8+ | Complex composites, reference formulas | Mastery maps |

## Hard Constraints

1. **2×2 Spawn Safety** — Cells [0,0], [0,1], [1,0], [1,1] must all be height 1. OR the map uses `s:` or `m:` to relocate spawn to a safe 2×2 area.
2. **No `l` (lift)** — Use `tc` for vertical movement.
3. **Teleporter required** — Every map needs at least one `t` utility.
4. **Artifacts must exist** — Every artifact in interactables must be in the registry.
5. **No artifacts on void** — Don't place artifacts on height-0 cells.

## The Validator

```
# Single map
python scripts/validate_map.py commons/maps/MapName/map_data.json

# All maps
python scripts/validate_map.py --all

# Just summary
python scripts/validate_map.py --all --summary

# As JSON
python scripts/validate_map.py --all --json
```

The validator checks:
- JSON structure and required fields
- Dimension consistency across layers
- Spawn safety (2×2 rule)
- Teleporter presence
- No lifts
- Artifact registry lookup
- Artifacts not on void cells
- Spatial temperature estimation
- Grammar primitive usage

Output: pass/fail checks, grammar description, directionality warnings, grade (A/B/C/F).

## Skills

| Skill | Role | Phase |
|-------|------|-------|
| `ada-cartographer` | Writes map_data.json + 4 markdown files | CREATE |
| `ada-spatial-designer` | Designs structure from grammar formulas | CREATE |
| `ada-test-player` | Experiential review (plays map by reading files) | SCORE |
| `ada-auditor` | Structural validation, orphan detection | VALIDATE |
| `ada-code-specialist` | Code quality, VR performance | IMPROVE |

## Key Files

| File | Content |
|------|---------|
| `grammar/grammar_structue.json` | Voxel grammar catalog (primitives, operators, roles, composites) |
| `commons/maps/Structure_Examples/voxel_grammar_subset.json` | Module catalog with heightmaps and flow ports |
| `commons/artifacts/registry/*.json` | Artifact registries (10 files) |
| `commons/artifacts/grid_artifacts.json` | Legacy artifact registry (~736 entries) |
| `scripts/validate_map.py` | Map validator script |
| `skills/ada-spatial-designer/references/artifact-directionality.md` | Full directionality reference |
| `skills/ada-spatial-designer/references/formulas-catalog.md` | 53 spatial formulas with JSON grids |
| `skills/ada-spatial-designer/references/design-tiers.md` | Daily drivers, tier system |
