# Sine Work

A display artifact that teaches **shader-driven sine wave visualisation** by rendering animated waveforms on a monitor screen. The monitor is connected to the scene by decorative cables that inherit from the `SplineCables` system, creating a cohesive installation piece.

## How It Works

**SineArtMonitor** represents a physical monitor in 3D space. It takes node paths to a pivot (for orientation control) and a screen mesh, then applies a duplicated `ShaderMaterial` to the screen surface. The shader renders animated sine waves directly on the monitor face -- the waveform parameters are baked into the shader rather than computed in GDScript.

**ArtMonitorCables** extends `SplineCables` (from the `static_cables` directory) to draw decorative cable connections to and from the monitor. It overrides the environment creation to be optional, allowing the cables to integrate into an existing scene without adding a second `WorldEnvironment`.

Together, these create a self-contained "art installation" where a sine wave plays on a screen connected by sculptural cables.

## Parameters

### SineArtMonitor
| Export | Type | Description |
|--------|------|-------------|
| `monitor_pivot_path` | NodePath | Path to the pivot node for monitor orientation |
| `screen_mesh_path` | NodePath | Path to the MeshInstance3D used as the screen |
| `screen_material` | ShaderMaterial | Shader material to display on the screen |

### ArtMonitorCables
| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `environment_enabled` | bool | false | Whether to create a WorldEnvironment (inherited from SplineCables) |

All other cable parameters (radius, segments, colors, sine wave settings) are inherited from `SplineCables`.

## Features

- Shader-based sine wave rendering on a 3D monitor surface
- Material duplication to avoid shared resource conflicts
- Cable connections using spline-based tube meshes
- Optional environment creation for scene integration flexibility

## Files

| File | Description |
|------|-------------|
| `SineArtMonitor.gd` | Monitor display controller -- applies shader material to a screen mesh |
| `ArtMonitorCables.gd` | Cable decoration extending SplineCables with optional environment |
