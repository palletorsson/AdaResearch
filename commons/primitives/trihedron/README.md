# Trihedron Primitives

## Scenes
- `trihedron.tscn`: static trihedron mesh node.
- `grab_trihedron.tscn`: XR pickable trihedron with highlight and optional shelf snap.

## Registry Keys
- `trihedron`
- `grab_trihedron`

## Map Token Examples
- `trihedron`
- `trihedron:90`
- `grab_trihedron:90:0:0.4`

## VR Notes
- `grab_trihedron.gd` extends `XRToolsPickable`.
- Use `snap_to_shelf = true` when staging table/shelf interactions.
- Tune `snap_max_distance` and `snap_falloff_distance` per map density.
