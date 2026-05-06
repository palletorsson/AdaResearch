# Static Cables

Procedural 3D cable generators that teach **parametric curve geometry**, **tube mesh construction**, and **sine wave displacement** by rendering smooth tubular meshes along mathematically defined paths. These serve as both standalone visual artifacts and a base class for other cable systems in the project.

## How It Works

**StaticCables** creates a row of parallel cables with sine-based sag. For each cable, it generates a path of evenly spaced points along the X axis with a sinusoidal Y displacement (`-sin(pi * t) * sag_amount`), producing a smooth hanging curve. Each path is then extruded into a tube mesh using the **Frenet frame** method: at every sample point, the tangent direction is computed, perpendicular `right` and `up` vectors are derived via cross products, and a ring of vertices is placed at the cable radius. Adjacent rings are connected with triangle pairs to form a smooth cylindrical surface.

The mesh construction uses indexed `ArrayMesh` with proper normals and UV coordinates for correct lighting and texturing. Materials interpolate between start and end colours across cables, with metallic sheen and emissive glow.

**SplineCables** extends this with two generation modes. In **path mode**, it reads `Path3D` children and samples their `Curve3D` at uniform intervals. In **position marker mode**, it finds child nodes named `p_1`, `p_2`, etc., and creates a sine-wave-modulated path through them. The sine displacement direction is automatically selected based on height: nodes near the floor oscillate horizontally (Z axis), while elevated nodes oscillate vertically (Y axis), creating natural-looking undulating cables.

## Parameters

### StaticCables
| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `cable_count` | int | 8 | Number of parallel cables |
| `points_per_cable` | int | 80 | Sample resolution per cable |
| `cable_length` | float | 12.0 | Horizontal span |
| `cable_spacing` | float | 2.5 | Distance between cables |
| `sag_amount` | float | 2.2 | Maximum vertical droop |
| `cable_radius` | float | 0.12 | Tube radius |
| `ring_segments` | int | 12 | Cross-section polygon count |
| `color_start` | Color | pink | Colour of the first cable |
| `color_end` | Color | blue | Colour of the last cable |

### SplineCables
| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `use_position_markers` | bool | true | Use p_1/p_2 nodes instead of Path3D |
| `sine_amplitude` | float | 0.5 | Sine wave displacement amount |
| `sine_frequency` | float | 2.0 | Number of sine cycles along the path |
| `sine_vertical` | bool | true | Apply sine displacement vertically |
| `auto_switch_oscillation` | bool | true | Auto-select direction based on height |
| `floor_height_threshold` | float | 0.5 | Height below which oscillation is horizontal |
| `auto_generate_on_ready` | bool | true | Generate cables on scene start |

## Features

- Frenet-frame tube mesh generation with proper normals and UVs
- Indexed `ArrayMesh` for efficient rendering
- Sine-based catenary approximation for natural cable sag
- Position marker workflow (p_1, p_2, ...) for quick cable routing
- Path3D / Curve3D sampling for designer-driven spline cables
- Automatic oscillation direction switching based on cable height
- Colour gradient interpolation across cable sets
- Metallic materials with emissive glow
- Dark environment with ambient glow

## Files

| File | Description |
|------|-------------|
| `StaticCables.gd` | Parallel cable generator with sine sag and indexed tube meshes |
| `SplineCables.gd` | Extended cable system with Path3D sampling and position marker support |
