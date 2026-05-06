# Artifacts

> Registry system mapping artifact names to scene paths

## Overview

The artifact system connects names used in map JSON files to actual Godot scenes. When a map's `interactables` layer contains `"grab_sphere_point"`, the registry resolves it to `res://commons/primitives/point/grab_sphere_point.tscn`.

## Structure

```
artifacts/
├── grid_artifacts.json.deprecated  # Legacy registry (archived, no longer loaded)
├── registry/                       # Authoritative modular registries by category
│   ├── arrays.json
│   ├── cellular_automata.json
│   ├── foundations.json
│   ├── furniture.json
│   ├── lsystems.json
│   ├── qfep.json
│   ├── randomness.json
│   ├── soft_bodies.json
│   └── ...                         # 50 category files, 1600+ artifacts
└── catalog/                        # Visual browsing tools
```

## Registry Entry Schema

```json
{
  "artifact_name": {
    "name": "Display Name",
    "lookup_name": "artifact_name",
    "description": "What it does",
    "scene": "res://path/to/scene.tscn",
    "category": "category_tag",
    "interaction": "grab|observe|touch",
    "complexity": "beginner|intermediate|advanced",
    "tags": ["tag1", "tag2"]
  }
}
```

## Usage in Maps

In `map_data.json` interactables layer:

```json
"interactables": [
  [" ", "grab_sphere_point", " "],
  [" ", "code_display#tutorial:fractals", " "]
]
```

### Configuration Syntax

```
artifact_name:rotation:y_offset:scale
artifact_name#key:value#key2:value2
```

**Examples:**
- `grab_sphere_point` — Default placement
- `grab_sphere_point:180` — Rotated 180°
- `grab_sphere_point:0:2` — Elevated 2 units
- `code_display#tutorial:fractals_axioms` — With config

## Resolution Order

All artifacts are loaded from `registry/*.json` files. The legacy `grid_artifacts.json` has been deprecated and renamed to `grid_artifacts.json.deprecated` (kept as backup, not loaded).

## Adding New Artifacts

1. Create scene in appropriate location
2. Add entry to relevant `registry/{category}.json`
3. Use in maps via `interactables` layer

## Key Files

| File | Purpose |
|------|---------|
| `GridArtifactRegistry.gd` | `commons/managers/` — Resolution logic |
| `GridInteractablesComponent.gd` | `commons/grid/` — Spawning logic |

## Quality Guidelines

Use `foundations.json` as the exemplary model:
- Rich descriptions with context
- `gamwell_reference` for art/math history
- `qfep_connection` for theoretical tie-in
- `signals`, `interactions`, `parameters` documentation

## Spatial Contracts

Directional identity and placement constraints are tracked in a sidecar file so map generation can reason about artifact fit.

- Contract file: `res://commons/artifacts/artifact_spatial_contracts.json`
- Planner class: `ArtifactSpatialFitPlanner` (`res://commons/artifacts/ArtifactSpatialFitPlanner.gd`)

Core contract fields:

- `directional_profile`: `full_circle | half_circle | cone | corridor | ambient`
- `interaction_mode`: `observe | grab | manipulate | walkthrough`
- `staging_preference`
- `enclosure_need`
- `clearance_radius_cells`, `height_clearance_cells`
- `preferred_view_distance_m`
