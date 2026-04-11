# Walled Cube

Open-top/bottom cube (four walls only, no floor or ceiling).

## Files

- `walledcube.gd`: wall-only cube via PrimitiveMeshBuilder
- `walledcube.tscn`: scene wrapper

## Behavior

- Purple color.
- Uses GridMaterialFactory for consistent appearance.
- `create_cube_vertices()` and `create_wall_faces()` build only side panels.
