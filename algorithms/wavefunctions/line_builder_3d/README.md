# Line Builder 3D

A collection of procedural 3D line and cable rendering tools that teach **parametric curve construction**, **spline interpolation**, and **proportional systems** in architecture. The centerpiece is an interactive recreation of Le Corbusier's Modulor Man -- a human figure drawn as a single continuous tube mesh whose proportions follow the golden ratio.

## How It Works

Each script uses Godot's `SurfaceTool` to build tube geometry from a sequence of 3D points. For every pair of adjacent points, a circular cross-section (configurable number of sides) is extruded along the segment direction, producing a smooth cylindrical mesh in real time. The tube is rebuilt every frame so that VR-grabbable control points can be repositioned interactively.

**LineBuilder3D** creates a flat triangle-strip ribbon connecting child points. **InteractiveLine** upgrades this to a full tube with randomised initial jitter and a duplicated shader material per instance. **CableBuilder** adds Bezier-handle sag via `Curve3D`, simulating catenary droop between control points. **ModulorMan** hardcodes vertex positions using Le Corbusier's Red and Blue series measurements (1.83 m standing height, 2.26 m with arm raised, golden-section subdivisions). **ModulorManInteractive** spawns grabbable spheres at every joint so learners can drag limbs and observe how the proportions deform. **PylonCables** constructs a row of electric pylons with animated wind-swayed cables and a transformer box, demonstrating catenary curves at architectural scale.

## Parameters

### LineBuilder3D
| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `point_scene` | PackedScene | -- | Scene to instantiate at each vertex |
| `line_material` | ShaderMaterial | -- | Material applied to the ribbon |
| `point_count` | int | 10 | Number of points along the line |
| `point_spacing` | float | 1.0 | Distance between successive points |

### InteractiveLine
| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `point_scene` | PackedScene | grab_sphere_point | Grabbable point scene |
| `line_material` | ShaderMaterial | line_shader | Shader for the tube |
| `point_count` | int | 8 | Number of control points |
| `point_spacing` | float | 0.5 | Initial spacing between points |
| `line_thickness` | float | 0.02 | Tube radius |
| `tube_sides` | int | 8 | Cross-section polygon count |

### CableBuilder
| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `control_point_count` | int | 4 | Number of grabbable control points |
| `cable_length` | float | 4.0 | Total horizontal span |
| `cable_thickness` | float | 0.02 | Tube radius |
| `tube_sides` | int | 8 | Cross-section resolution |
| `spline_resolution` | int | 20 | Samples per curve segment |
| `gravity_sag` | float | 0.5 | Downward droop factor |

### ModulorMan / ModulorManInteractive
| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `line_material` | ShaderMaterial | line_shader | Tube shader |
| `line_thickness` | float | 0.015 | Tube radius |
| `tube_sides` | int | 8 | Cross-section sides |
| `point_scene` | PackedScene | grab_sphere_point | (interactive only) Grabbable joint |

### PylonCables
| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `num_pylons` | int | 4 | Number of pylons in the row |
| `pylon_spacing` | float | 8.0 | Distance between pylons |
| `pylon_height` | float | 6.0 | Height of each pylon |
| `cables_per_span` | int | 3 | Cable lines between adjacent pylons |
| `cable_sag` | float | 0.8 | Catenary droop factor |
| `wind_enabled` | bool | true | Animate cable sway |
| `wind_strength` | float | 0.3 | Amplitude of wind sway |
| `wind_speed` | float | 1.5 | Frequency of wind oscillation |

## Features

- Real-time procedural tube mesh generation using `SurfaceTool`
- VR-grabbable control points for interactive curve editing
- Catenary / Bezier cable simulation with adjustable sag
- Le Corbusier Modulor proportional system with Red and Blue series measurements
- Animated wind sway on pylon cables with per-cable phase offsets
- Configurable cross-section resolution and thickness
- Shader material duplication for per-instance glow and flow parameters

## Files

| File | Description |
|------|-------------|
| `LineBuilder3D.gd` | Basic triangle-strip ribbon connecting child points |
| `interactive_line.gd` | Full tube mesh with grabbable points and random jitter |
| `cable_builder.gd` | Bezier-spline cable with gravity sag simulation |
| `modulor_man.gd` | Static Modulor Man figure with golden-ratio proportions |
| `modulor_man_interactive.gd` | Interactive Modulor Man with draggable joints |
| `pylon_cables.gd` | Electric pylon row with animated catenary cables |
