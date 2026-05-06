extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]The Line[/b][/font_size][/center]
[center][i]Connecting Points and Imposing Measure[/i][/center]

Lines create direction, distance, and paths through space.

[b]The Line: Connecting Points[/b]
- A line is the relation between two distinct points - the shortest path through space.

[color=yellow][b]Code: Defining the Endpoints[/b][/color]
[code]
var point_a = Vector3(0, 0, 0)
var point_b = Vector3(1, 1, 0)
[/code]


[hr]

[b]The Ontological Imperative: Line and Length[/b]
The Euclidean Line is ontologically defined by its capacity for length. Its existence is its measure. If a line had no length, it would collapse back into a point. The Line asserts that the distance is the only relevant relational property between Point A and Point B. The Line is the normative truth - instantly calculable, prioritizing the single, efficient metric.

[hr]

[b]Cylinders as Lines: Materializing the Metric[/b]
- A cylinder can represent a line segment by connecting two points with a visible 3D form aligned along their direction. Its height must equal its measured distance, visually enforcing the ontological link.

[color=yellow][b]Code: Building the Measured Form[/b][/color]
[code]
var cylinder = MeshInstance3D.new()
var cylinder_mesh = CylinderMesh.new()
cylinder_mesh.height = distance
cylinder_mesh.top_radius = 0.02
cylinder_mesh.bottom_radius = 0.02
cylinder.mesh = cylinder_mesh

# Position at midpoint and enforce straightness
cylinder.position = (point_a + point_b) / 2.0
cylinder.look_at_from_position(
    cylinder.position, point_b, Vector3.UP
)

add_child(cylinder)
[/code]

[hr]

[b]What the Line Erases[/b]

The Line is a radical compression. It knows only two points and one distance. Everything between those endpoints - the journey itself - becomes invisible.

[color=orange][b]What the Line Cannot Measure:[/b][/color]

- Duration - How long did it take to traverse this distance?
- Curvature - Did the path curve, spiral, hesitate?
- Texture - Was the journey smooth or turbulent?
- Returns - Did you walk back and forth, circling?
- Intention - Was this the path you wanted, or were forced to take?

The Line is the Trace, compressed to its endpoints.

All the lived history of movement - the body's accumulation of moments - reduced to two coordinates and a single floating-point number. The algorithm sees only start and finish. The rest is noise to be discarded.

[hr]

[b]The Line as Algorithmic Violence[/b]

When the system draws a line between A and B, it is making a claim: this is the only path that matters. The straight line. The efficient route. The measured distance.

But bodies do not move in straight lines. We detour. We wander. We return to places we've already been, not because it's efficient, but because the route holds meaning the algorithm cannot parse.

The Line is the geometry of optimization - beautiful in its simplicity, violent in what it refuses to see.

[hr]

[color=cyan][b]Next:[/b] The Trace[/color]
If the Line erases duration, the Trace insists on it. The Trace is the body's refusal to be reduced to endpoints. It accumulates what the Line discards.

'''
