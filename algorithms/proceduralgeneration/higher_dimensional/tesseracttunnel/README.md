# Tesseract Tunnel

A tunnel structure composed of hundreds of 4D tesseracts (hypercubes) arranged in cylindrical rings, projected from 4D to 3D in real time. This artifact teaches how 4D space can be tessellated with hypercubes and how different projection methods (perspective, orthographic, stereographic) dramatically change the perceived geometry. The animated W-axis offset creates the illusion of moving through the 4th dimension.

## How It Works

1. **Cylindrical arrangement**: Tesseracts are placed in concentric rings along a cylindrical tunnel. Each ring has `6 + ring_index * 4` tesseracts, with the ring radius scaling from 30% to 100% of `tunnel_radius`. Tesseracts repeat along the Z axis for the full `tunnel_length`.
2. **4D vertex generation**: Each tesseract has 16 vertices generated from 4-bit binary combinations, giving coordinates of +/- half-size along X, Y, Z, and W.
3. **4D rotation**: Vertices are rotated in the XW plane (mixing the spatial X axis with the 4th dimension W), controlled by `rotation_4d`. This rotation is animated over time.
4. **W-axis animation**: The `w_offset` oscillates sinusoidally, shifting all tesseracts along the 4th dimension. Each concentric ring is offset slightly differently in W, so rings appear to phase in and out.
5. **Projection to 3D**: Four projection types are available:
   - **Cell-first** -- orthographic, drops the W coordinate
   - **Vertex-first** -- orthographic with W-based scaling
   - **Perspective** -- perspective projection from a 4D viewpoint at distance 4
   - **Stereographic** -- conformal mapping that preserves angles
6. **Edge rendering**: The 32 edges (vertex pairs differing by one bit) are drawn as colored lines. Color interpolates between `outer_color` and `inner_color` based on each tesseract's W-position relative to `w_offset`.

All geometry is rendered into a single `ImmediateMesh` for performance.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `projection_type` | ProjectionType | PERSPECTIVE | 4D-to-3D projection method |
| `tunnel_radius` | float | 5.0 | Radius of the cylindrical tunnel |
| `tunnel_length` | float | 20.0 | Length of the tunnel along Z |
| `tesseract_grid_density` | int | 3 | Number of concentric rings |
| `tesseract_size` | float | 1.5 | Size of each tesseract |
| `w_offset` | float | 0.0 | Position along the 4th dimension |
| `animate_w` | bool | true | Animate W-offset oscillation |
| `w_speed` | float | 0.5 | Speed of W-axis animation |
| `rotation_4d` | float | 0.0 | Rotation angle in the XW plane |
| `edge_color` | Color | light blue | Material emission/albedo color |
| `emission_strength` | float | 2.0 | Glow intensity |
| `inner_color` | Color | pink | Color for tesseracts near W=0 |
| `outer_color` | Color | blue | Color for tesseracts far from W=0 |

## Features

- **Hundreds of animated tesseracts** -- real-time 4D rotation and projection of a dense tunnel structure
- **Four projection methods** -- compare how perspective, orthographic, and stereographic projections distort 4D geometry differently
- **W-axis animation** -- sinusoidal offset simulates movement through the 4th dimension
- **Depth-coded coloring** -- W-position mapped to a two-color gradient reveals 4D structure
- **Single ImmediateMesh** -- all edges combined into one mesh for VR-friendly performance
- **Custom Vector4D class** -- inner class for 4D coordinate math
- **Demo controller** -- full UI with projection selector, tunnel parameters, W-speed/offset, color pickers, randomize button

## Files

- `tesseract_tunnel.gd` -- Core generator: cylindrical layout, 4D vertex generation, XW rotation, four projection methods, ImmediateMesh rendering, Vector4D class
- `tunnel_demo_controller.gd` -- Interactive demo with full UI panel, camera orbit, randomization
- `tesseract_tunnel.tscn` -- Standalone artifact scene
- `tesseract_tunnel_demo.tscn` -- Interactive demo scene
- `tesseract_showcase.tscn` -- Showcase scene
