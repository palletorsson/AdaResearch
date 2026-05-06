# Godot Meshes

Pre-configured Godot primitive meshes at various polygon counts with grid materials.

## Files

- `sphere_low.gd` / `sphere_mid.gd` / `sphere_high.gd`: sphere LOD variants
- `cylinder_low.gd` / `cylinder_mid.gd`: cylinder LOD variants
- `torus_low.gd`: low-poly torus
- Matching `.tscn` files for each

## Behavior

- Each extends MeshInstance3D with GridMaterialFactory material applied.
- Useful for demonstrating tessellation and LOD concepts.
