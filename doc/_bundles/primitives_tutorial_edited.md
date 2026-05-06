<<<ADA_BUNDLE>>>
sequence: primitives
file: tutorial.md
maps: 12
skipped_passing: 0
created: 2026-04-24T02:00:00
only_failing: true
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: Point_One>>>
# Point One

Place a single point in space. Before it, the coordinate system must already exist.

Declare the three axes.

```gdscript
const AXIS_X := Vector3(1, 0, 0)
const AXIS_Y := Vector3(0, 1, 0)
const AXIS_Z := Vector3(0, 0, 1)
```

The axes are unit vectors. They name directions, not points.

Mark the origin.

```gdscript
var origin := Vector3.ZERO  # (0, 0, 0)
```

The origin is a convention, not a point. It is the reference against which other points are measured.

Instantiate your first point.

```gdscript
func place_point(position: Vector3) -> MeshInstance3D:
    var point := MeshInstance3D.new()
    point.mesh = SphereMesh.new()
    point.position = position
    add_child(point)
    return point
```

The sphere mesh is rendering help. The point itself is the Vector3 that was passed in.

Place it at a specific location.

```gdscript
var p := place_point(Vector3(1.0, 0.5, 0.0))
```

Three floats. One position. No extent.

Show the coordinate system as visible axes.

```gdscript
func draw_axes(length: float = 3.0) -> void:
    spawn_axis_line(Vector3.ZERO, AXIS_X * length, Color.RED)
    spawn_axis_line(Vector3.ZERO, AXIS_Y * length, Color.GREEN)
    spawn_axis_line(Vector3.ZERO, AXIS_Z * length, Color.BLUE)
```

Red for X, green for Y, blue for Z. The convention is shared across Godot, OpenGL, and most 3D software.

Spawn a gyroscope to track orientation.

```gdscript
var gyro := preload("res://commons/primitives/gyroscope.tscn").instantiate()
gyro.position = Vector3(2, 1, 0)
add_child(gyro)
```

The gyroscope's axes align with yours. Move relative to it and the relationship stays constant.

Make the point grabbable.

```gdscript
func make_interactive(point: MeshInstance3D) -> void:
    var area := Area3D.new()
    var shape := CollisionShape3D.new()
    shape.shape = SphereShape3D.new()
    point.add_child(area)
    area.add_child(shape)
    area.add_to_group("grabbable")
```

The Area3D detects the controller's collision shape. Godot's XR plugin handles the grab-and-release contract.

Read the point's current coordinates.

```gdscript
func report_position(point: Node3D) -> String:
    var p := point.global_position
    return "(%.2f, %.2f, %.2f)" % [p.x, p.y, p.z]
```

The coordinates change as the point moves. The point's identity does not.

You can now place a Vector3 in space, show the axes that give it meaning, and move it while its identity persists. The next map, Point_Line, connects two of these instances into a line.

<<<MAP: Point_Line>>>
# Point Line

Two points define a line. The line is the relation, not the endpoints.

Place two points.

```gdscript
var a := Vector3(0, 0, 0)
var b := Vector3(2, 1, 0)
```

Each is a Vector3. Neither implies the other.

Compute the direction from a to b.

```gdscript
var direction: Vector3 = (b - a).normalized()
```

Subtraction produces the vector from a to b. Normalisation sets its length to 1, keeping only the direction.

Compute the length between them.

```gdscript
var length: float = a.distance_to(b)
# or equivalently: (b - a).length()
```

The distance is a scalar. It is how far the line extends, not which way.

Draw the line as a cylinder.

```gdscript
func draw_line(start: Vector3, end: Vector3, thickness: float = 0.02) -> MeshInstance3D:
    var mesh := MeshInstance3D.new()
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = thickness
    cylinder.bottom_radius = thickness
    cylinder.height = start.distance_to(end)
    mesh.mesh = cylinder
    mesh.position = (start + end) / 2.0
    mesh.look_at(end, Vector3.UP)
    mesh.rotate_object_local(Vector3.RIGHT, PI / 2)
    add_child(mesh)
    return mesh
```

The cylinder is centred between the endpoints and rotated to point along them. Godot's CylinderMesh defaults to Y-up, so a 90-degree rotation aligns it with the line direction.

Parameterise points along the segment.

```gdscript
func point_at(start: Vector3, end: Vector3, t: float) -> Vector3:
    return start + (end - start) * t
```

`t` runs from 0 to 1. At 0 you are at the start; at 1 you are at the end; at 0.5 you are halfway.

Label the distance.

```gdscript
func attach_distance_label(line: MeshInstance3D, a: Vector3, b: Vector3) -> void:
    var label := Label3D.new()
    label.text = "%.2f m" % a.distance_to(b)
    label.position = (a + b) / 2.0 + Vector3.UP * 0.3
    line.add_child(label)
```

The label sits above the midpoint. Its text is the measured length.

Record the learner's path as a trace.

```gdscript
var trace_points: Array = []

func _process(_delta: float) -> void:
    var learner = get_tree().get_first_node_in_group("learner")
    trace_points.append(learner.global_position)
    if trace_points.size() > 100:
        trace_points.pop_front()
```

The trace is a ring buffer of recent positions. Rendering each consecutive pair as a short line produces a visible trail.

You can now compute a direction, measure a length, and render the segment between any two points. Point_Lines will next extend this into a full grid of related points.

<<<MAP: Point_Lines>>>
# Point Lines

Build a grid of points. Connect each to its grid neighbours.

Declare the grid dimensions.

```gdscript
const GRID_SIZE := Vector2i(8, 8)
const SPACING := 1.0
```

An 8-by-8 grid with unit spacing gives 64 points and 112 edges.

Spawn the points.

```gdscript
var points: Array = []  # 2D array of Node3D

func spawn_grid() -> void:
    for y in GRID_SIZE.y:
        var row: Array = []
        for x in GRID_SIZE.x:
            var p := spawn_point_at(Vector3(x, 0, y) * SPACING)
            row.append(p)
        points.append(row)
```

Each point is a small mesh at a grid coordinate. The 2D array `points[y][x]` holds them by row.

Connect horizontal neighbours.

```gdscript
func connect_horizontal() -> void:
    for y in GRID_SIZE.y:
        for x in range(GRID_SIZE.x - 1):
            draw_line(points[y][x].position, points[y][x + 1].position)
```

`x - 1` so the inner loop stops before the last column. Each iteration draws the edge between column x and column x+1.

Connect vertical neighbours.

```gdscript
func connect_vertical() -> void:
    for y in range(GRID_SIZE.y - 1):
        for x in GRID_SIZE.x:
            draw_line(points[y][x].position, points[y + 1][x].position)
```

Same pattern for the other axis. After both passes, every interior point has four edges; corner points have two; edge points have three.

Move a point and update its lines.

```gdscript
func move_point(coords: Vector2i, new_pos: Vector3) -> void:
    points[coords.y][coords.x].position = new_pos
    redraw_edges_touching(coords)
```

The grid is no longer rectangular once a point moves. The adjacency structure persists.

Add diagonal connections.

```gdscript
func connect_diagonal() -> void:
    for y in range(GRID_SIZE.y - 1):
        for x in range(GRID_SIZE.x - 1):
            draw_line(points[y][x].position, points[y + 1][x + 1].position)
```

Diagonals add 49 edges to the 112 horizontal and vertical ones. The grid becomes a triangulation.

Count the graph's vertices and edges.

```gdscript
func graph_stats() -> Dictionary:
    var V: int = GRID_SIZE.x * GRID_SIZE.y
    var E: int = (GRID_SIZE.x - 1) * GRID_SIZE.y + (GRID_SIZE.y - 1) * GRID_SIZE.x
    return {"vertices": V, "edges": E}
```

V = 64, E = 112 for horizontal plus vertical. Euler's formula V - E + F = 2 (for planar graphs) lets you check the face count without enumerating.

You can now build a grid of points and connect them by adjacency. Point_Trace will next turn the learner's motion into a line that persists.

<<<MAP: Point_Trace>>>
# Point Trace

Record the learner's motion as a persistent line.

Buffer recent positions.

```gdscript
var trace: Array = []  # list of Vector3
const MAX_POINTS := 200

func _process(_delta: float) -> void:
    var p: Vector3 = learner.global_position
    trace.append(p)
    if trace.size() > MAX_POINTS:
        trace.pop_front()
```

A ring buffer bounded at 200 samples. Older samples fall off as new ones arrive.

Render the trace as connected segments.

```gdscript
func render_trace() -> void:
    if trace.size() < 2: return
    clear_previous_segments()
    for i in range(trace.size() - 1):
        spawn_line_segment(trace[i], trace[i + 1])
```

Each consecutive pair becomes a short segment. The segments together form the trail.

Fade older segments.

```gdscript
func render_with_fade() -> void:
    for i in range(trace.size() - 1):
        var age_fraction: float = float(i) / trace.size()
        var color: Color = Color.WHITE.lerp(Color.TRANSPARENT, 1.0 - age_fraction)
        spawn_line_segment(trace[i], trace[i + 1], color)
```

Older segments have lower alpha. The trail reads as receding rather than infinite.

Simplify the trace for performance.

```gdscript
func simplify_trace(tolerance: float = 0.05) -> Array:
    var simplified: Array = [trace[0]]
    for i in range(1, trace.size() - 1):
        var prev = simplified[-1]
        if prev.distance_to(trace[i]) > tolerance:
            simplified.append(trace[i])
    simplified.append(trace[-1])
    return simplified
```

Points within the tolerance distance of their predecessor are dropped. The resulting trace uses fewer segments while preserving the shape.

Save the trace to disk.

```gdscript
func save_trace(path: String) -> void:
    var file := FileAccess.open(path, FileAccess.WRITE)
    for p in trace:
        file.store_line("%.3f %.3f %.3f" % [p.x, p.y, p.z])
```

Three floats per line, space-separated. The file is a human-readable record of the walk.

Load a previously saved trace.

```gdscript
func load_trace(path: String) -> Array:
    var loaded: Array = []
    var file := FileAccess.open(path, FileAccess.READ)
    while not file.eof_reached():
        var line: String = file.get_line()
        var parts := line.split_whitespace()
        if parts.size() == 3:
            loaded.append(Vector3(float(parts[0]), float(parts[1]), float(parts[2])))
    return loaded
```

The loaded trace can be replayed, compared with a current walk, or used as reference geometry.

You can now record a walk, render it as a decaying trail, simplify it for efficiency, and persist it to disk. Point_Line_Grid will next snap traces to a discrete grid so recorded motion becomes quantised history.

<<<MAP: Point_Line_Grid>>>
# Point Line Grid

Snap continuous motion to a grid. Memory becomes quantised.

Set the grid resolution.

```gdscript
const CELL_SIZE := 0.5

func world_to_cell(pos: Vector3) -> Vector3i:
    return Vector3i(
        int(round(pos.x / CELL_SIZE)),
        int(round(pos.y / CELL_SIZE)),
        int(round(pos.z / CELL_SIZE))
    )

func cell_to_world(cell: Vector3i) -> Vector3:
    return Vector3(cell) * CELL_SIZE
```

`round` snaps to the nearest cell. A cell size of 0.5 means the learner's position maps to a 50cm grid.

Record cells visited.

```gdscript
var visited_cells: Dictionary = {}  # Vector3i -> timestamp

func _process(_delta: float) -> void:
    var cell := world_to_cell(learner.global_position)
    if not cell in visited_cells:
        visited_cells[cell] = Time.get_ticks_msec()
        highlight_cell(cell)
```

The dictionary records the first time each cell was entered. Re-entry doesn't overwrite.

Draw the grid as visible cells.

```gdscript
func highlight_cell(cell: Vector3i) -> void:
    var marker := MARKER_SCENE.instantiate()
    marker.position = cell_to_world(cell)
    marker.modulate = Color(1, 1, 0.3, 0.4)
    add_child(marker)
```

Each visited cell gets a semi-transparent marker. The markers together form a record of where the learner has been.

Show the grid lines only where the learner has walked.

```gdscript
func draw_visited_lines() -> void:
    var visited_list: Array = visited_cells.keys()
    visited_list.sort_custom(func(a, b): return visited_cells[a] < visited_cells[b])
    for i in range(visited_list.size() - 1):
        var a: Vector3 = cell_to_world(visited_list[i])
        var b: Vector3 = cell_to_world(visited_list[i + 1])
        draw_line_segment(a, b)
```

Sort by visit time, then connect in order. The result is a polyline of the learner's quantised path.

Quantise continuous motion into discrete steps.

```gdscript
func quantised_step(from: Vector3, to: Vector3) -> Array:
    var from_cell := world_to_cell(from)
    var to_cell := world_to_cell(to)
    var steps: Array = [from_cell]
    var current := from_cell
    while current != to_cell:
        var diff := to_cell - current
        if abs(diff.x) >= abs(diff.y) and abs(diff.x) >= abs(diff.z):
            current.x += sign(diff.x)
        elif abs(diff.y) >= abs(diff.z):
            current.y += sign(diff.y)
        else:
            current.z += sign(diff.z)
        steps.append(current)
    return steps
```

Bresenham-like stepping from one cell to the next. Each step advances along the axis of greatest remaining distance.

Measure path length in cells.

```gdscript
func path_length_cells(path: Array) -> int:
    return path.size() - 1  # edges between consecutive cells
```

The grid converts continuous distance into a step count. Path length becomes a discrete integer.

You can now snap world positions to a grid, record visited cells, and render the learner's quantised path. Point_Triangle will next close a path into a cycle, introducing the first polygon.

<<<MAP: Point_Triangle>>>
# Point Triangle

Three points plus three edges close into a triangle — the minimum polygon.

Place three points.

```gdscript
var a := Vector3(0, 0, 0)
var b := Vector3(2, 0, 0)
var c := Vector3(1, 0, 1.732)  # equilateral
```

The third point is at height sqrt(3), giving an equilateral triangle with side 2.

Draw the three edges.

```gdscript
func draw_triangle(a: Vector3, b: Vector3, c: Vector3) -> void:
    draw_line(a, b)
    draw_line(b, c)
    draw_line(c, a)
```

Three edges close the shape. Without the third edge, the figure is a path rather than a polygon.

Compute the triangle's area.

```gdscript
func triangle_area(a: Vector3, b: Vector3, c: Vector3) -> float:
    var ab := b - a
    var ac := c - a
    return ab.cross(ac).length() / 2.0
```

The cross product's magnitude is the parallelogram area. The triangle is half of that.

Compute the normal vector.

```gdscript
func triangle_normal(a: Vector3, b: Vector3, c: Vector3) -> Vector3:
    var ab := b - a
    var ac := c - a
    return ab.cross(ac).normalized()
```

The normal points perpendicular to the triangle's plane. Reversing the vertex order flips the normal.

Fill the triangle as a mesh.

```gdscript
func fill_triangle(a: Vector3, b: Vector3, c: Vector3) -> MeshInstance3D:
    var mesh := ArrayMesh.new()
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)
    st.commit(mesh)
    var instance := MeshInstance3D.new()
    instance.mesh = mesh
    add_child(instance)
    return instance
```

SurfaceTool appends the three vertices in counter-clockwise order. The resulting mesh is a single filled triangle.

Check whether a point lies inside the triangle.

```gdscript
func point_in_triangle(p: Vector3, a: Vector3, b: Vector3, c: Vector3) -> bool:
    var v0 := c - a
    var v1 := b - a
    var v2 := p - a
    var dot00 := v0.dot(v0)
    var dot01 := v0.dot(v1)
    var dot02 := v0.dot(v2)
    var dot11 := v1.dot(v1)
    var dot12 := v1.dot(v2)
    var inv := 1.0 / (dot00 * dot11 - dot01 * dot01)
    var u := (dot11 * dot02 - dot01 * dot12) * inv
    var v := (dot00 * dot12 - dot01 * dot02) * inv
    return u >= 0 and v >= 0 and u + v <= 1
```

Barycentric coordinates (u, v) describe where p sits relative to a, b, c. Inside the triangle iff both coordinates are non-negative and their sum is at most 1.

Subdivide the triangle into four smaller triangles.

```gdscript
func subdivide(a: Vector3, b: Vector3, c: Vector3) -> Array:
    var ab := (a + b) / 2.0
    var bc := (b + c) / 2.0
    var ca := (c + a) / 2.0
    return [
        [a, ab, ca],
        [ab, b, bc],
        [ca, bc, c],
        [ab, bc, ca],
    ]
```

Three midpoints plus the three original vertices form four smaller triangles. Applied recursively, this is the standard triangle subdivision scheme.

You can now close three points into a triangle, compute its area and normal, fill it as a mesh, test point containment, and subdivide it. Point_Triangle_Context will next place the triangle in relationship with other shapes.

<<<MAP: Point_Triangle_Context>>>
# Point Triangle Context

Place a triangle among other shapes. Relationships emerge.

Spawn a triangle and a square.

```gdscript
func spawn_triangle_and_square() -> void:
    spawn_triangle(Vector3(-2, 0, 0))
    spawn_square(Vector3(2, 0, 0))
```

Two shapes at different positions. Their relationship becomes a feature of the map.

Measure the shortest distance between them.

```gdscript
func shortest_distance(shape_a: Array, shape_b: Array) -> float:
    var min_dist: float = INF
    for va in shape_a:
        for vb in shape_b:
            min_dist = min(min_dist, va.distance_to(vb))
    return min_dist
```

Brute-force vertex-to-vertex check. For shapes with few vertices (triangles, squares), this is fast.

Detect whether two shapes overlap.

```gdscript
func shapes_overlap(a: Array, b: Array) -> bool:
    var a_bounds := compute_aabb(a)
    var b_bounds := compute_aabb(b)
    return a_bounds.intersects(b_bounds)
```

The axis-aligned bounding box test is conservative — it may return true when shapes are close but not touching. For exact overlap, use separating-axis theorem.

Render shapes with different colours by type.

```gdscript
func color_by_type(shape_type: String) -> Color:
    match shape_type:
        "triangle": return Color.RED
        "square": return Color.BLUE
        "pentagon": return Color.GREEN
    return Color.WHITE
```

A visual legend emerges from the colour assignment. Shape type is readable at a glance.

Group shapes into scenes.

```gdscript
func group_into_scene(shapes: Array) -> Node3D:
    var scene := Node3D.new()
    for s in shapes:
        scene.add_child(s)
    return scene
```

Grouping enables uniform transformations. Move the scene and every shape moves with it.

Compute the convex hull of combined vertex sets.

```gdscript
func convex_hull(points: Array) -> Array:
    # Graham scan (simplified for 2D)
    points.sort_custom(func(a, b): return a.x < b.x or (a.x == b.x and a.y < b.y))
    var lower: Array = []
    for p in points:
        while lower.size() >= 2 and cross2d(lower[-2], lower[-1], p) <= 0:
            lower.pop_back()
        lower.append(p)
    return lower
```

The convex hull wraps all the points as tightly as possible. Shapes' relationships become visible as the hull's shape.

Define proximity as a relationship.

```gdscript
func are_neighbours(shape_a: Array, shape_b: Array, threshold: float = 0.5) -> bool:
    return shortest_distance(shape_a, shape_b) < threshold
```

Shapes within the threshold distance are neighbours. The map's spatial relationships are now queryable.

You can now place shapes in space, measure their proximity, test overlap, and compute the hull containing them all. Primitives_Polythedra will next lift the 2D polygons into 3D polyhedra.

<<<MAP: Primitives_Polythedra>>>
# Primitives Polyhedra

Five regular polyhedra exist in 3D. The constraint that produces them is angular.

Define a regular polyhedron by its face count.

```gdscript
enum Solid { TETRAHEDRON, CUBE, OCTAHEDRON, DODECAHEDRON, ICOSAHEDRON }

func face_count(solid: Solid) -> int:
    match solid:
        Solid.TETRAHEDRON: return 4
        Solid.CUBE: return 6
        Solid.OCTAHEDRON: return 8
        Solid.DODECAHEDRON: return 12
        Solid.ICOSAHEDRON: return 20
    return 0
```

Five solids. Four, six, eight, twelve, twenty faces respectively. Nothing between or beyond.

Spawn a tetrahedron via four vertices.

```gdscript
func tetrahedron_vertices() -> Array:
    return [
        Vector3(1, 1, 1),
        Vector3(1, -1, -1),
        Vector3(-1, 1, -1),
        Vector3(-1, -1, 1),
    ]
```

Alternating corners of a cube form a regular tetrahedron. Every pair of vertices is the same distance apart — the tetrahedron's edge length.

Check the angular constraint.

```gdscript
func interior_angle_sum(solid: Solid) -> float:
    # Triangles: 60°, squares: 90°, pentagons: 108°
    # Meeting at a vertex: interior_angle × faces_per_vertex < 360°
    match solid:
        Solid.TETRAHEDRON: return 60 * 3  # 180
        Solid.CUBE: return 90 * 3         # 270
        Solid.OCTAHEDRON: return 60 * 4   # 240
        Solid.DODECAHEDRON: return 108 * 3 # 324
        Solid.ICOSAHEDRON: return 60 * 5  # 300
    return 0
```

Every regular solid's interior-angle sum at a vertex is less than 360°. Six equilateral triangles (360°) collapse into a plane; five or fewer rise into a point.

Compute Euler's formula.

```gdscript
func euler_check(V: int, E: int, F: int) -> bool:
    return V - E + F == 2
```

Every convex polyhedron satisfies V - E + F = 2. For a cube: 8 - 12 + 6 = 2. For an icosahedron: 12 - 30 + 20 = 2.

Spawn a polyhedron mesh.

```gdscript
func spawn_polyhedron(solid: Solid) -> MeshInstance3D:
    var mesh := MeshInstance3D.new()
    match solid:
        Solid.CUBE:
            mesh.mesh = BoxMesh.new()
        Solid.TETRAHEDRON:
            mesh.mesh = build_tetrahedron_mesh()
        # ... etc
    add_child(mesh)
    return mesh
```

Godot provides BoxMesh directly. The other four solids need custom SurfaceTool construction.

Compute a polyhedron's volume.

```gdscript
func solid_volume(solid: Solid, edge_length: float) -> float:
    var a := edge_length
    match solid:
        Solid.TETRAHEDRON: return a * a * a / (6.0 * sqrt(2))
        Solid.CUBE: return a * a * a
        Solid.OCTAHEDRON: return a * a * a * sqrt(2) / 3.0
        Solid.DODECAHEDRON: return a * a * a * (15 + 7 * sqrt(5)) / 4.0
        Solid.ICOSAHEDRON: return a * a * a * 5 * (3 + sqrt(5)) / 12.0
    return 0.0
```

Closed-form volumes from the edge length. The constants are irrational — these are continuous 3D objects, not grid artifacts.

You can now spawn any of the five regular polyhedra, verify the angular constraint that produces them, and compute their volumes. Point_Animatedcube will next animate a cube through a deliberate transformation.

<<<MAP: Point_Animatedcube>>>
# Point Animated Cube

A cube moves through a tween. Keyframes define the targets; interpolation fills the between.

Start with a still cube.

```gdscript
var cube := MeshInstance3D.new()
cube.mesh = BoxMesh.new()
cube.position = Vector3.ZERO
add_child(cube)
```

A default BoxMesh at the origin. Side length 1, sitting on its own axis.

Define two keyframe positions.

```gdscript
const START_POS := Vector3.ZERO
const END_POS := Vector3(3, 1, 0)
const DURATION := 2.0  # seconds
```

The cube will travel from START_POS to END_POS over DURATION seconds.

Create the tween.

```gdscript
var tween := create_tween()
tween.tween_property(cube, "position", END_POS, DURATION)
```

Godot's tween interpolates linearly between the current value and the target. One line replaces a hand-rolled animation loop.

Change the easing.

```gdscript
tween.tween_property(cube, "position", END_POS, DURATION).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
```

Elastic transitions produce a bounce at the endpoint. Linear transitions move at constant speed. Each easing has a characteristic rhythm.

Chain transformations.

```gdscript
var tween := create_tween().set_parallel(false)
tween.tween_property(cube, "position", END_POS, 2.0)
tween.tween_property(cube, "rotation", Vector3(0, PI, 0), 1.0)
tween.tween_property(cube, "scale", Vector3(2, 2, 2), 1.5)
```

set_parallel(false) makes the steps sequential. Move, then rotate, then scale — six seconds total.

Run them in parallel.

```gdscript
var tween := create_tween().set_parallel(true)
tween.tween_property(cube, "position", END_POS, 2.0)
tween.tween_property(cube, "rotation", Vector3(0, PI, 0), 2.0)
```

With set_parallel(true), every tween_property starts at the same moment. The cube moves and rotates simultaneously.

Loop the animation.

```gdscript
var tween := create_tween().set_loops()
tween.tween_property(cube, "position", END_POS, 2.0)
tween.tween_property(cube, "position", START_POS, 2.0)
```

set_loops() repeats indefinitely. The cube bounces between the two positions forever.

Read the current animation progress.

```gdscript
func animation_progress(tween: Tween) -> float:
    return tween.get_total_elapsed_time() / tween.get_total_duration()
```

Progress runs from 0 to 1. Useful for triggering side effects at specific moments.

You can now animate a cube between keyframes with custom easing, chain or parallelise transforms, and loop the motion. Primitives_Ignorance will next introduce what a single cube cannot know.

<<<MAP: Primitives_Ignorance>>>
# Primitives Ignorance

Each object knows its own state. It does not know the larger scene.

Define a local-state object.

```gdscript
class_name LocalObject extends Node3D

var own_position: Vector3 = Vector3.ZERO
var own_velocity: Vector3 = Vector3.ZERO

func _process(delta: float) -> void:
    own_position += own_velocity * delta
    global_position = own_position
```

The object tracks its own position and velocity. It has no knowledge of other objects.

Simulate interaction without shared state.

```gdscript
func _physics_process(_delta: float) -> void:
    # Each object computes its own reaction.
    # No central coordinator knows where all objects are.
    var nearby := get_tree().get_nodes_in_group("objects")
    for other in nearby:
        if other == self: continue
        if global_position.distance_to(other.global_position) < 2.0:
            react_to(other)
```

The object queries its environment for neighbours. The query is a local perception, not a global read.

Add a broadcast signal.

```gdscript
signal emitted_event(event_name: String, data: Dictionary)

func emit_local_event(event: String, payload: Dictionary) -> void:
    emitted_event.emit(event, payload)
```

Signals are how local objects talk to each other without knowing about each other. The listeners subscribe independently.

Subscribe to a broadcast.

```gdscript
func _ready() -> void:
    for sibling in get_tree().get_nodes_in_group("broadcasters"):
        sibling.emitted_event.connect(_on_broadcast)

func _on_broadcast(event: String, payload: Dictionary) -> void:
    if event == "alert":
        react_to_alert(payload)
```

The listener reacts only to events it cares about. The broadcaster does not need to know who is listening.

Encapsulate private state.

```gdscript
var _internal_state: Dictionary = {}  # underscore prefix marks private

func public_report() -> Dictionary:
    return {"position": global_position}  # do not expose _internal_state
```

The underscore convention marks fields not meant for external access. Other objects see only what public_report exposes.

Test whether an object knows a fact.

```gdscript
func knows(fact: String) -> bool:
    return fact in _internal_state
```

Knowledge is local. The same fact may be known by some objects and unknown by others.

Propagate knowledge via signals.

```gdscript
func teach(fact: String, value) -> void:
    _internal_state[fact] = value
    emit_local_event("learned", {"fact": fact, "value": value})
```

When an object learns something, it broadcasts. Listeners that care can update their own state.

You can now build local-state objects that communicate by signal rather than by shared memory. Primitives_Portals will next connect two such objects through a single teleporter.

<<<MAP: Primitives_Portals>>>
# Primitives Portals

A portal links two points. Enter one, exit the other, regardless of the distance between them.

Define a portal pair.

```gdscript
class_name Portal extends Area3D

@export var linked_portal: Portal

func _on_body_entered(body: Node3D) -> void:
    if linked_portal:
        body.global_position = linked_portal.global_position
```

Two portals reference each other. Entering one moves the body to the other.

Preserve the entry orientation.

```gdscript
func _on_body_entered(body: Node3D) -> void:
    if linked_portal == null: return
    var entry_offset: Vector3 = body.global_position - global_position
    var entry_rotation: Basis = body.global_transform.basis
    body.global_position = linked_portal.global_position + entry_offset
    body.global_transform.basis = entry_rotation
```

The offset relative to the entry portal is preserved. The body arrives at the exit with the same orientation it entered.

Handle velocity transfer.

```gdscript
func _on_body_entered(body: RigidBody3D) -> void:
    if linked_portal == null: return
    body.global_position = linked_portal.global_position
    # Velocity reorients if portals face different directions
    var in_to_out_rotation: Basis = linked_portal.global_transform.basis * global_transform.basis.inverse()
    body.linear_velocity = in_to_out_rotation * body.linear_velocity
```

When the two portals face different directions, the body's velocity rotates through the difference. The direction is preserved relative to each portal's local frame.

Prevent immediate re-entry.

```gdscript
var cooldown_for_bodies: Dictionary = {}  # body -> time_last_teleported
const COOLDOWN_MS := 100

func can_teleport(body: Node) -> bool:
    var now: int = Time.get_ticks_msec()
    if body in cooldown_for_bodies and now - cooldown_for_bodies[body] < COOLDOWN_MS:
        return false
    cooldown_for_bodies[body] = now
    return true
```

Without the cooldown, a body might teleport, land inside the exit portal, and teleport back immediately. The cooldown ensures one-way passage.

Visualise the portal mouth.

```gdscript
func _ready() -> void:
    var mouth := MeshInstance3D.new()
    mouth.mesh = QuadMesh.new()
    mouth.mesh.size = Vector2(1.5, 2.0)
    var mat := StandardMaterial3D.new()
    mat.emission_enabled = true
    mat.emission = Color.CYAN
    mouth.material_override = mat
    add_child(mouth)
```

A glowing quad marks the portal's location. The colour of each portal matches its pair.

Render what lies beyond the portal.

```gdscript
func setup_portal_camera() -> void:
    var cam := Camera3D.new()
    cam.position = linked_portal.global_position
    var viewport := SubViewport.new()
    viewport.add_child(cam)
    # Render to texture, apply as portal surface material
```

A SubViewport renders the scene from the linked portal's position. The rendered image maps onto the entry portal's surface, showing the destination as seen from the other side.

Test for a valid portal pair.

```gdscript
func is_valid_pair() -> bool:
    if linked_portal == null: return false
    if linked_portal.linked_portal != self: return false
    return true
```

Both portals must reference each other. One-way links would allow entry but not return.

You can now link two points in space, preserving orientation and velocity through the passage, with correct cooldown and visualisation. Primitives_Melencolia will next place geometric primitives in a Dürer-referenced still-life scene.

<<<MAP: Primitives_Melencolia>>>
# Primitives Melencolia

Dürer's 1514 engraving Melencolia I sits over the sequence's closing map. The primitives of the sequence appear as its still-life elements.

Spawn the polyhedron at the map's centre.

```gdscript
func spawn_melencolia_polyhedron() -> MeshInstance3D:
    var mesh := MeshInstance3D.new()
    mesh.mesh = build_truncated_rhombohedron()
    mesh.position = Vector3(0, 0.5, 0)
    return mesh
```

Dürer's solid is a truncated rhombohedron — six rhombic faces plus two triangular caps. Construction is a one-time SurfaceTool exercise.

Build the truncated rhombohedron vertices.

```gdscript
func truncated_rhombohedron_vertices() -> Array:
    # Approximation — Dürer's solid can be drawn from a cube
    # with two opposing corners sliced off.
    const H := 0.5  # half-height
    return [
        Vector3(-H, -H, -H), Vector3(H, -H, -H),
        Vector3(H, H, -H), Vector3(-H, H, -H),
        Vector3(-H, -H, H), Vector3(H, -H, H),
        Vector3(H, H, H), Vector3(-H, H, H),
    ]
```

Eight vertices of a cube, with two diagonally opposite corners cut. The cut reveals two triangular faces; the remaining cube faces become rhombi.

Place the magic square on a wall.

```gdscript
func spawn_magic_square() -> Node3D:
    const GRID := [
        [16, 3, 2, 13],
        [5, 10, 11, 8],
        [9, 6, 7, 12],
        [4, 15, 14, 1],
    ]
    var panel := Panel3D.new()
    panel.content = format_magic_square(GRID)
    panel.position = Vector3(-2, 1.5, 0)
    return panel
```

Dürer's 4x4 magic square: every row, column, diagonal, and corner sums to 34. The bottom row's middle two numbers are 15 and 14, encoding the engraving's date.

Add the hourglass.

```gdscript
func spawn_hourglass() -> MeshInstance3D:
    var mesh := MeshInstance3D.new()
    mesh.mesh = build_hourglass_mesh()
    mesh.position = Vector3(1.5, 1, 0)
    add_child(mesh)
    return mesh
```

Two cones tip-to-tip, sharing a common axis. The narrow waist is a cylinder of small radius. Sand particles fall through via particle system.

Animate sand falling.

```gdscript
class_name SandFall extends GPUParticles3D

func _ready() -> void:
    amount = 1024
    lifetime = 3.0
    var mat := ParticleProcessMaterial.new()
    mat.gravity = Vector3(0, -2, 0)
    mat.initial_velocity_min = 0.1
    mat.initial_velocity_max = 0.2
    process_material = mat
    emitting = true
```

GPU particles handle thousands of grains at interactive rates. The emitter sits at the hourglass waist; gravity pulls the grains into the lower chamber.

Place the compass.

```gdscript
func spawn_compass() -> MeshInstance3D:
    var compass := MeshInstance3D.new()
    compass.mesh = build_compass_mesh()  # two legs hinged at top
    compass.position = Vector3(-1, 1, 0)
    return compass
```

A pair of hinged legs joined at the top. Each leg is a thin cylinder; the hinge is a sphere. The compass measures distances — itself a primitive operation.

Add the comet in the sky.

```gdscript
func spawn_comet() -> Node3D:
    var comet := Node3D.new()
    var head := MeshInstance3D.new()
    head.mesh = SphereMesh.new()
    head.material_override = make_emissive_material(Color.YELLOW)
    comet.add_child(head)
    add_tail_particles(comet)
    comet.position = Vector3(5, 8, -3)
    return comet
```

An emissive sphere with a trailing particle system. The comet is far from the scene but part of the composition.

Compose the full scene.

```gdscript
func compose_melencolia() -> void:
    spawn_melencolia_polyhedron()
    spawn_magic_square()
    spawn_hourglass()
    spawn_compass()
    spawn_comet()
    spawn_scale()
    spawn_bell()
    spawn_putto()
```

Each artifact is a primitive from the sequence made ornamental. The sequence's geometric vocabulary furnishes a 16th-century still life.

You can now compose a scene from the sequence's geometric primitives, animated via particle systems and orchestrated into a Dürer-referenced tableau. The sequence closes here; the next sequence begins in the adjacent corridor.
