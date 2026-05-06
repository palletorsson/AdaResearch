extends Node

# Tutorial content for in-world BBCode cards
var text = '''
[center][b]Interactive Point[/b][/center]
[center][i]Pick it up and read the coordinates[/i][/center]

[hr]
[b]What It Does[/b]
- GrabSphere node makes the point pickable in VR/Desktop.
- A floating Label3D reports global x/y/z to one decimal place.
- Optional PointColor child lets you tint the sphere instantly.

[hr]
[b]Inspector Hooks[/b]
[color=yellow]Public Methods[/color]
[code]
set_point_position(Vector3)
set_point_color(Color)
set_label_visible(bool)
set_label_offset(Vector3)
get_pickable_sphere()
[/code]

[hr]
[b]Implementation Notes[/b]
- Label billboards toward the viewer and updates every _process tick.
- Coordinates read from the GrabSphere so world-space drags stay accurate.
- Falls back to a simple emissive StandardMaterial3D if PointColor is absent.

[hr]
[b]Try This[/b]
1. Drop several points to mark a path or constraint anchors.
2. Pair with line/segment primitives to measure distances.
3. Animate `set_point_position()` over time for orbiting markers.

[hr]
[i]Tip[/i]
Hide the label (set_label_visible(false)) when using the point purely as an anchor.
'''
