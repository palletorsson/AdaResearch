# AdaResearch S&box Port Plan

## Goal

Port AdaResearch to S&box as a data-driven runtime, not as a literal Godot project conversion.

The durable AdaResearch layer is the curriculum/content chain:

```text
Sequences -> Maps -> Artifact registries -> Artifact scenes
JSON       JSON   JSON                 Godot .tscn/.gd today
```

The S&box version should preserve the sequence, map, registry, algorithm, and QFEP content while rebuilding the engine-facing runtime in C# components, prefabs, resources, and Razor UI.

## Non-Goals

- Do not attempt to automatically convert every `.tscn` into a working S&box prefab.
- Do not port every artifact before a complete vertical slice works.
- Do not make VR the first milestone. Desktop first keeps the runtime debuggable.
- Do not couple the content data to S&box-specific paths until the loader layer is stable.

## Current Godot Anchors

These files define the runtime shape that should be mirrored in S&box:

- `project.godot`
  - Main scene: `res://commons/scenes/vr_staging.tscn`
  - Autoloads include `GameManager`, `MapProgressionManager`, `EcosystemManager`, audio, text, and XR helpers.
- `commons/grid/GridSystem.gd`
  - Orchestrates grid generation through child components.
- `commons/grid/GridDataComponent.gd`
  - Loads `commons/maps/{MapName}/map_data.json`.
  - Supports `Lab/` special cases and optional `map_data.corridor.json`.
- `commons/grid/GridStructureComponent.gd`
  - Builds grid structure from map layers.
- `commons/grid/GridUtilitiesComponent.gd`
  - Spawns utilities such as `s`, `t`, labels, text, lifts, and other map objects.
- `commons/grid/GridInteractablesComponent.gd`
  - Loads every JSON registry in `commons/artifacts/registry/`.
  - Resolves `lookup_name` entries to artifact scenes.
- `commons/grid/FloorPlanLoader.gd`
  - Optionally overlays room/floor-plan geometry from `floor_plan.json`.
- `commons/maps/sequences/*.json`
  - Sequence layer. Current repo has 62 sequence JSON files.
- `commons/artifacts/registry/*.json`
  - Artifact registry layer. Current repo has many category registries.

## S&box Runtime Shape

Create a separate S&box project, preferably beside the Godot runtime rather than inside engine-specific Godot folders:

```text
sbox/
  Code/
    Managers/
      AdaGameManager.cs
      AdaSceneManager.cs
      MapProgressionManager.cs
      EcosystemManager.cs
    Content/
      MapData.cs
      SequenceData.cs
      ArtifactDefinition.cs
      AdaContentPaths.cs
      AdaJsonLoader.cs
    Grid/
      GridSystem.cs
      GridStructureBuilder.cs
      GridUtilitySpawner.cs
      GridArtifactSpawner.cs
      FloorPlanBuilder.cs
    Artifacts/
      ArtifactComponent.cs
      PlaceholderArtifact.cs
      RotatingCubeArtifact.cs
      OscillationCubeArtifact.cs
      RotationOscillationCubeArtifact.cs
    Player/
      AdaPlayerController.cs
      InteractionRay.cs
    UI/
      MapHud.razor
      InfoPanel.razor
  Assets/
    data/
      maps/
      sequences/
      artifacts/
    prefabs/
      artifacts/
      utilities/
      player/
```

The first version can copy data into `sbox/Assets/data/`. Later, replace copying with a sync script or shared content package.

## Engine Mapping

| Godot | S&box |
| --- | --- |
| `Node3D` | `GameObject` with components |
| `.gd` script | C# class inheriting `Component` |
| `.tscn` scene | `.prefab` or `.scene` |
| autoload singleton | persistent scene manager component or service-style component |
| `PackedScene.instantiate()` | prefab load and instantiate |
| `res://` path | S&box asset path or content path resolver |
| Godot signal | C# event/delegate or component method call |
| `Control` UI | Razor/HTML/CSS UI |
| OpenXR/Godot XR Tools | S&box input/VR layer |

## Data Model To Port First

Start with the fields used by `Tutorial_Start`:

```csharp
public sealed class AdaMapData
{
    public AdaMapInfo MapInfo { get; set; }
    public Dictionary<string, AdaUtilityDefinition> UtilityDefinitions { get; set; }
    public AdaMapSettings Settings { get; set; }
    public AdaLighting Lighting { get; set; }
    public AdaLayers Layers { get; set; }
}

public sealed class AdaLayers
{
    public List<List<string>> Structure { get; set; }
    public List<List<string>> Utilities { get; set; }
    public List<List<string>> Interactables { get; set; }
}
```

Avoid over-modeling all historical map fields in milestone 1. Unknown JSON fields should be tolerated.

## First Vertical Slice

Use `commons/maps/Tutorial_Start/map_data.json` as the proof map because it is small and already includes:

- 3x3 structure layer
- spawn utility `s`
- teleporter utility `t`
- three simple interactables:
  - `rotating_cube`
  - `oscillation_cube`
  - `rotation_oscillation_cube`

Done means:

1. S&box starts in a desktop scene.
2. `AdaJsonLoader` loads `Tutorial_Start/map_data.json`.
3. `GridSystem` generates the structure layer.
4. `GridUtilitySpawner` places a player spawn and a teleporter placeholder.
5. `GridArtifactSpawner` resolves the three interactable lookup names.
6. Missing artifacts spawn as visible placeholders with their lookup names.
7. The three tutorial cubes have native S&box C# behavior.
8. Teleporter can switch to one hardcoded next map or reload the current map.

## Port Order

1. **Create S&box project shell**
   - Empty scene.
   - Camera/player.
   - Basic input.
   - One root `AdaRuntime` GameObject.

2. **Port map loading**
   - Implement `AdaContentPaths`.
   - Implement `AdaJsonLoader`.
   - Load `Tutorial_Start` from copied JSON.
   - Log map name, dimensions, layer sizes, and validation warnings.

3. **Port grid structure**
   - Implement `GridSystem`.
   - Implement `GridStructureBuilder`.
   - Convert `structure` cells into cube/floor/wall GameObjects.
   - Preserve coordinate convention:

   ```text
   row -> world Z
   col -> world X
   height -> world Y
   ```

4. **Port utility spawning**
   - Implement spawn `s`.
   - Implement teleporter `t`.
   - Add placeholder handling for unknown utility codes.

5. **Port artifact registry**
   - Load all `Assets/data/artifacts/*.json`.
   - Index by `lookup_name`.
   - Accept current Godot `scene` paths but do not use them directly.
   - Add optional S&box fields:

   ```json
   {
     "lookup_name": "rotating_cube",
     "scene": "res://...",
     "sbox_prefab": "prefabs/artifacts/rotating_cube.prefab",
     "sbox_component": "RotatingCubeArtifact"
   }
   ```

6. **Port simple artifacts**
   - `rotating_cube`
   - `oscillation_cube`
   - `rotation_oscillation_cube`
   - generic placeholder artifact

7. **Port progression**
   - Read one sequence JSON.
   - Resolve next map.
   - Connect teleporter to sequence progression.

8. **Add UI**
   - Minimal map HUD.
   - Artifact info panel.
   - Registry lookup/debug overlay.

9. **Add VR**
   - Keep artifact interaction API stable.
   - Add VR controller/ray interaction as an input layer over the same runtime.

## Conversion Tools

Write scripts after the first slice works:

- `tools/sbox/sync_content.ps1`
  - Copies `commons/maps`, `commons/maps/sequences`, and `commons/artifacts/registry` into `sbox/Assets/data`.
- `tools/sbox/audit_sbox_registry.ps1`
  - Lists registry entries missing `sbox_prefab` or `sbox_component`.
- `tools/sbox/generate_placeholder_prefabs.ps1`
  - Creates or reports placeholder prefabs for missing artifacts.
- `tools/sbox/convert_res_paths.ps1`
  - Builds a report mapping Godot `res://` paths to proposed S&box asset paths.

## Risk Register

| Risk | Mitigation |
| --- | --- |
| Hundreds of Godot artifacts cannot be converted automatically | Keep content registry, spawn placeholders, port artifacts by category |
| Godot-specific GDScript behavior is embedded in `.tscn` scenes | Treat `.tscn` as reference, reimplement artifact behavior in C# |
| VR migration slows the port | Desktop-first runtime, VR as input layer |
| Registry paths are Godot-specific | Add optional S&box fields without deleting Godot fields |
| Too many map schema variants | Start with minimal fields and tolerate unknown JSON |
| Procedural audio and ecosystem systems are large | Defer until map/artifact/progression loop works |

## Immediate Next Task

Create the S&box project shell and implement milestone 1 against `Tutorial_Start`.

The smallest useful commit should include:

- `sbox/Code/Content/MapData.cs`
- `sbox/Code/Content/AdaJsonLoader.cs`
- `sbox/Code/Grid/GridSystem.cs`
- `sbox/Code/Grid/GridStructureBuilder.cs`
- copied `Tutorial_Start/map_data.json`
- one S&box scene that loads and renders the 3x3 map

After that, the port becomes incremental instead of overwhelming.
