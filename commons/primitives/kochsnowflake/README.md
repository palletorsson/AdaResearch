# Koch Snowflake

Koch snowflake fractal with configurable recursion depth.

## Files

- `kochsnowflake.gd`: recursive Koch curve generator
- `kochsnowflake.tscn`: scene wrapper

## Behavior

- Configurable recursion depth and line thickness.
- Extends MeshInstance3D with `koch_iteration()` recursive function.
- Exports: depth, size, line_width.
