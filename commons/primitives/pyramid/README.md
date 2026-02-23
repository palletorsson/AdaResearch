# Pyramid Primitives

## Scenes
- `pyramid.tscn`: static pyramid mesh.
- `grab_pyramid.tscn`: XR pickable pyramid.
- `pyramid_edit.tscn`: editable square pyramid with draggable point handles.
- `tetrahedron_edit.tscn`: editable tetrahedron with draggable point handles.

## Registry Keys
- `pyramid`
- `grab_pyramid`
- `pyramid_edit`
- `tetrahedron_edit`

## Map Token Examples
- `pyramid_edit:45:0:0.4`
- `tetrahedron_edit:0:0:0.4`
- `grab_pyramid:0:0:0.3`

## Interaction Notes
- Edit variants rebuild mesh when handles move.
- Keep edit artifacts on stable floor tiles to avoid controller jitter while dragging handles.
