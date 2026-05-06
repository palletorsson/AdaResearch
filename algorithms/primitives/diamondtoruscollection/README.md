# Diamond Torus Collection

A primitives artifact that arranges diamond-shaped octahedra hanging from thin cylinders around a torus. The diamonds are evenly spaced along the torus circumference and oriented to point upward toward their attachment points, creating a chandelier-like geometric installation.

## Concept Taught

**Parametric placement on a torus** -- how objects can be positioned at regular angular intervals around a circular path using trigonometric functions. The artifact demonstrates the relationship between a torus's major radius, angular subdivision, and the vertical offset created by hanging elements from its surface.

## How It Works

1. An optional wireframe `TorusMesh` is created as a visual reference, with transparency and wireframe rendering enabled.
2. For each diamond position, the angle around the torus is calculated as `(i / count) * 2 * PI`. The torus position is `(cos(angle) * radius, 0, sin(angle) * radius)`.
3. A thin `CylinderMesh` hangs vertically downward from each torus point, positioned at the midpoint between the torus and the diamond.
4. An octahedron scene is instantiated at the bottom of each cylinder. Each diamond is oriented to look at its torus attachment point using `look_at_from_position()`, with a fallback up vector when the direction is nearly vertical.
5. The `@tool` annotation allows the arrangement to update in the Godot editor.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `torus_radius` | float | 2.0 | Distance from center to torus ring |
| `cylinder_length` | float | 1.0 | Length of hanging cylinders |
| `cylinder_radius` | float | 0.01 | Thickness of hanging cylinders |
| `diamond_count` | int | 7 | Number of diamonds around the torus |
| `diamond_scale` | float | 0.5 | Scale factor for diamond octahedra |
| `show_torus_wireframe` | bool | true | Show the reference wireframe torus |

## Features

- Editor-time preview via `@tool`
- Evenly spaced diamonds around a torus circumference
- Wireframe torus reference with transparency
- Robust up-vector handling for `look_at_from_position()`
- Runtime API: `set_diamond_count()`, `set_torus_radius()`, `set_cylinder_length()`
- Custom color support via `set_diamond_colors_custom()` and `set_cylinder_color()`
- `toggle_torus_wireframe()` for visibility control
- `get_arrangement_info()` for debug introspection

## Files

| File | Description |
|------|-------------|
| `diamondtoruscollection.gd` | Torus arrangement builder with hanging cylinders, diamond instantiation, and runtime controls |
