# Beam

A primitives artifact that constructs an abstract architectural structure from pink beams -- a vertical pillar, a horizontal crossbar, and an optional L-shaped element. Each beam is a `StaticBody3D` with collision, suitable for VR interaction and spatial composition.

## Concept Taught

**Constructive solid geometry and spatial composition** -- how simple box primitives (beams) can be combined at specific positions and orientations to create architectural forms. The artifact demonstrates procedural scene construction where each beam is a physics-enabled static body, showing the relationship between visual mesh, collision shape, and material properties.

## How It Works

1. A flat floor (`StaticBody3D` with `BoxMesh` and `BoxShape3D`) is created as the ground plane.
2. The `create_beam()` function builds each beam as a `StaticBody3D` containing a `MeshInstance3D` (box mesh) and `CollisionShape3D` (box shape) of matching dimensions. A `StandardMaterial3D` applies the configurable pink color with metallic sheen and optional emission glow.
3. The main vertical beam is placed at floor level. A horizontal beam extends from near its top. If `create_l_shape` is enabled, a smaller vertical-horizontal pair forms an L-bracket offset to the side.
4. Lighting includes a directional light with shadows, a dark blue-gray background environment, and a pink-tinted omni accent light near the main beam.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `beam_color` | Color | (0.85, 0.25, 0.65) | Hot pink color for all beams |
| `beam_metallic` | float | 0.4 | Metallic value of beam material |
| `beam_roughness` | float | 0.15 | Roughness of beam material |
| `beam_glow` | float | 0.1 | Emission intensity (0 disables glow) |
| `main_beam_size` | Vector3 | (0.8, 6.0, 0.8) | Dimensions of the main vertical beam |
| `horizontal_beam_size` | Vector3 | (4.0, 0.6, 0.8) | Dimensions of the horizontal crossbar |
| `create_l_shape` | bool | true | Whether to add the L-shaped element |

## Features

- Procedural beam construction with matched mesh and collision shapes
- Configurable material (color, metallic, roughness, emission)
- L-shaped architectural element toggle
- Shadow-casting directional light with dark environment
- Pink accent omni light for dramatic lighting
- Optional colored test cubes for scanner testing via `add_test_cubes()`

## Files

| File | Description |
|------|-------------|
| `beam.gd` | Beam structure builder with floor, lighting, L-shape, and test cube support |
