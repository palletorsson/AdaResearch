# Grid Modifier + Spatial Fit Plan

## Purpose
Define one written plan for two related systems:

1. `GridModifierAgent` for sequence-aware voxel structure modification.
2. `ArtifactSpatialFitPlanner` for placing artifacts in pedagogically readable VR spaces.

This plan keeps the current 2.5D map approach (2D layout encoding 3D stack height) and extends it with a Blender-inspired operation pipeline.

## Current Baseline

### Existing Grid Agent Capabilities
- Spawn syntax: `gridagent:tier[:rotation[:y_offset[:scale]]]`.
- Existing tiers and operations:
  - `copy`, `translate`, `rotate`, `scale`, `color`, `array`, `sine`, `random`, `ca`.
- Current implementation touchpoints:
  - `commons/hazards/gridagent/grid_agent_base.gd`
  - `commons/hazards/gridagent/grid_operations.gd`
  - `commons/grid/GridInteractablesComponent.gd`

### Existing Spatial/Map Capabilities
- Map stack: `structure`, `utilities`, `interactables`.
- 2.5D height interpretation from `structure` cells (`0..max_height`).
- Sequence context is available in grid runtime metadata.

## System A: GridModifierAgent

### Goal
Provide a deterministic, replayable modifier pipeline that can:
- build more complex structures from grammar modules,
- apply sequence-specific style rules,
- deploy into existing maps with safety checks.

### Modifier Families (Blender-Inspired)
Note: in Blender, `extrude/inset/knife` are mesh edit tools (not stack modifiers). Here we adopt them as pipeline stages for voxel operations.

#### Core Constructive
- `extrude`: grow boundary/face selections by direction and length.
- `inset`: shrink selected footprint inward; optional keep-rim.
- `bevel`: chamfer corners/edges using voxel stair-stepping.
- `cut`: split structure by plane/path; supports straight, loop, and bisect variants.

#### Existing + Extended Generate
- `array`, `mirror`, `boolean`, `solidify`, `subdivide`, `remesh`, `weld`.

#### Deform-like (2.5D-safe)
- `translate`, `rotate`, `scale`, `shear`, `smooth`, `wave/sine`, `noise/displace`.

#### Stylization/Utility
- `colorize`, `tag`, `annotate`, `portal_hook`, `trigger_hook`.

### Proposed Pipeline
- `select` -> `extrude` -> `inset` -> `bevel` -> `cut` -> `array/mirror` -> `deform` -> `validate` -> `commit`

Each stage is optional and parameterized. Order is explicit and deterministic.

### Pipeline Data Model (Draft)
```json
{
  "pipeline_id": "grammar_courtyard_v1",
  "sequence_id": "grammar_systems",
  "target_map": "Structure_Examples_VoxelGrammar_Principles",
  "selection": {"mode": "tag", "value": "court_zone"},
  "steps": [
    {"op": "extrude", "params": {"axis": "y", "amount": 2, "boundary_only": true}},
    {"op": "inset", "params": {"rings": 1, "keep_rim": true}},
    {"op": "bevel", "params": {"radius": 1, "profile": "linear"}},
    {"op": "cut", "params": {"type": "bisect", "axis": "x", "offset": 0}}
  ]
}
```

### Sequence Profiles
Each sequence can declare allowed operations and style constraints.

Example constraints:
- `primitives`: allow `copy/translate/rotate/scale`; disallow `cut/boolean`.
- `transformation`: allow full constructive/deform set.
- `grammar_systems`: allow compositional pipeline + repeat/phase operators.

## System B: ArtifactSpatialFitPlanner

### Goal
Automatically choose artifact staging types that fit:
- interaction needs (observe/grab/walk-through),
- cognitive load and pedagogy,
- corridor and sequence flow readability.

### Directional Contract Layer (implemented scaffold)
Sidecar contract file now exists:
- `commons/artifacts/artifact_spatial_contracts.json`

Planner implementation now exists:
- `commons/artifacts/ArtifactSpatialFitPlanner.gd`

Contract fields currently used by planner:
- `directional_profile` (`full_circle | half_circle | cone | corridor | ambient`)
- `interaction_mode`
- `staging_preference`
- `enclosure_need`
- `footprint_cells`
- `clearance_radius_cells`
- `height_clearance_cells`
- `preferred_view_distance_m`
- `sequence_tags`

### Directional Identity Rule
Every artifact should expose its directional identity so auto-layout can reason about placement:
- `full_circle`: 360 read, rotation not critical.
- `half_circle`: 180 read, front hemisphere matters.
- `cone`: focused front, facing must align with approach.
- `corridor`: movement-axis artifact, facing and axis alignment both matter.
- `ambient`: context object, low facing sensitivity.

### Current Planner Pass
`ArtifactSpatialFitPlanner` currently supports:
- Contract loading and default fallback merge.
- Candidate scoring breakdown: staging, enclosure, clearance, view distance, directionality, sequence bonus.
- Candidate ranking per artifact.
- Greedy auto-layout over grid candidates with spacing constraints.
- Conversion of placement results to interactable layer tokens.

Example usage:
```gdscript
var planner := ArtifactSpatialFitPlanner.new()
planner.load_contracts()
var result := planner.suggest_auto_layout(
	["infokiosk", "code_display", "dark_sphere"],
	25,
	25,
	{"spawn_position_2d": [0, 0], "sequence_id": "tutorial"}
)
var interactables_layer := planner.placements_to_interactable_layer(result.placements, 25, 25)
```

### Placement Archetypes
- `table/plinth` for compact observe artifacts.
- `pillar` for symbolic reference objects.
- `alcove/tab` for manipulative interactables.
- `roomlet` for medium complexity interactions.
- `corridor gateway` for sequence transitions and unlock reveals.

### Multi-Artifact Map Pattern
- Hub court + branch corridors.
- One corridor per artifact cluster when many artifacts share one map.
- Threshold pieces mark transitions to new sequence logic.

## Integration Points
- Runtime context:
  - read current sequence from `GridSystem` metadata.
- Placement:
  - artifact instantiation via `GridInteractablesComponent`.
- Game flow:
  - keep compatibility with `GameManager` modes including `TESTPLUS`.

## Validation Requirements

### Structural
- bounds, overlap, collision sanity, height limits.

### Navigation
- spawn-to-exit path,
- spawn-to-artifact path for required artifacts,
- no blocked corridor thresholds.

### Pedagogical
- focal object visibility,
- interaction clearance around manipulables,
- zone separation when multiple concepts share map.

## Milestones

### Phase 1: Spec + Contracts
- Define modifier op schema and artifact spatial contracts.
  - Status: in progress (artifact sidecar contract scaffold added).
- Add sequence profile file for allowed ops.

### Phase 2: GridModifierAgent MVP
- Implement pipeline executor with `extrude/inset/bevel/cut`.
- Add dry-run and preview report mode.

### Phase 3: Spatial Fit MVP
- Implement placement solver for table/pillar/alcove/room archetypes.
  - Status: in progress (first scoring and greedy layout pass implemented).
- Emit fit warnings and suggested corrections.

### Phase 4: Validator + Tooling
- Extend content validator with spatial-fit checks.
- Add desktop/editor panel for pipeline preview + fit report.

## Near-Term Decisions
- Keep 2.5D map format as base system.
- Add complexity through modifiers and staged composition, not by replacing format.
- Treat Blender-inspired flow as operation grammar, not 1:1 mesh emulation.

## References
- Blender modifier categories and stack concepts:
  - `https://docs.blender.org/manual/en/latest/modeling/modifiers/introduction.html`
- Blender modifier index (representative category list):
  - `https://docs.blender.org/manual/en/3.6/modeling/modifiers/index.html`
- Blender mesh tools relevant to pipeline:
  - Toolbar tools (Extrude, Inset, Bevel, Loop Cut, Knife):
    - `https://docs.blender.org/manual/en/4.2/modeling/meshes/tools/toolbar.html`
  - Extrude Faces:
    - `https://docs.blender.org/manual/en/5.1/modeling/meshes/editing/face/extrude_faces.html`
  - Knife Topology Tool:
    - `https://docs.blender.org/manual/en/4.5/modeling/meshes/editing/mesh/knife_topology_tool.html`
