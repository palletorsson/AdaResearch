# Managers

> Singleton and utility managers for game systems

## Overview

Managers provide global access to core game functionality. Most are registered as AutoLoads (singletons) in `project.godot`.

## Autoloads

| Manager | Global Name | Purpose |
|---------|-------------|---------|
| `GameManager.gd` | `GameManager` | Game state, scoring, player data |
| `AdaSceneManager.gd` | `SceneManager` | Scene transitions, map loading |
| `MapProgressionManager.gd` | `MapProgressionManager` | Sequence/map progression |
| `TextManager.gd` | `TextManager` | Localization, text lookup |

## Non-Autoload Managers

| Manager | Purpose |
|---------|---------|
| `GridArtifactRegistry.gd` | Artifact name → scene resolution |
| `JsonMapLoader.gd` | Map JSON parsing |
| `LabManager.gd` | Lab hub environment logic |
| `LogManager.gd` | Logging utilities |
| `VRGridSystemManager.gd` | VR-specific grid management |
| `VRMapDiscovery.gd` | Map discovery/unlock system |
| `SceneManagerHelper.gd` | Scene transition utilities |

## Key Flows

### Scene Transition

```
User activates teleporter
        │
        ▼
SceneManager.transition_to_map(map_name)
        │
        ├── Fade out
        ├── JsonMapLoader.load_map()
        ├── GridSystem.initialize()
        └── Fade in
```

### Artifact Resolution

```
map_data.json: "grab_sphere_point"
        │
        ▼
GridArtifactRegistry.get_artifact_scene("grab_sphere_point")
        │
        ├── Search registry/*.json
        └── Fallback to grid_artifacts.json
        │
        ▼
Returns: "res://commons/primitives/point/grab_sphere_point.tscn"
```

## Usage

```gdscript
# Scene transition
SceneManager.transition_to_map("Fractals_1")

# Check progression
var unlocked = MapProgressionManager.is_map_unlocked("Fractals_2")

# Get artifact scene
var scene_path = GridArtifactRegistry.get_artifact_scene("grab_sphere_point")
```

## Adding New Managers

1. Create script in `commons/managers/`
2. If singleton: Add to `project.godot` → `[autoload]`
3. Document purpose and API
