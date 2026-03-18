# Menger Sponge

3D fractal with configurable recursion level (0–4).

## Files

- `mengersponge.gd`: recursive Menger sponge generator
- `mengersponge.tscn`: scene wrapper

## Behavior

- `generate_menger()` recursive function builds geometry.
- SurfaceTool procedural mesh.
- Exports: level (recursion depth), base_size.
