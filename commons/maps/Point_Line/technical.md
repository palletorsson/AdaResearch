# The Line

In *Point_One*, you placed a single point. Vector3(x, y, z). Position without extension — existence as pure coordinate. Nothing connects it to anything else. It sits in the void, complete and useless.

A line doesn't add a new kind of thing. It adds a *relation*. Two points already exist in space. The line is the decision to formalize the distance between them — to say: these two positions are bound, and the measure of that binding is a number.

This map makes that binding tangible. There's a segment you can grab. Stretch it. Rotate it. The label updates in real-time. What you feel as elasticity is `start_pos.distance_to(end_pos)`.

---

## Two Points Make a Line

The `line` artifact in this map runs `line.gd`. At its core, the line is not a thing — it's a node that watches two other nodes:

```gdscript
@onready var point_one = $GrabSphere
@onready var point_two = $GrabSphere2

func update_connections():
    clear_connections()
    if point_one and point_two:
        current_line = create_connection_line(point_one.position, point_two.position)
        update_length_label(point_one.position, point_two.position)
```

Remove either grab sphere and the line ceases to exist. It has no intrinsic form — only a relation. The cylinder you see is not *the line*; it's a visual rendering of the relationship between two positions.

This is the first ontological commitment of geometry: a line segment is defined entirely by its endpoints. Every property that follows — length, direction, slope, midpoint — is derived. None of it belongs to the line itself.

`_process` runs every frame, updating both the geometry and the label:

```gdscript
func _process(_delta):
    if point_one and point_two:
        update_line_transform(point_one.position, point_two.position)
        update_length_label(point_one.position, point_two.position)
        if enable_resistance:
            _process_resistance(point_one.position.distance_to(point_two.position))
```

Three jobs, every frame: keep the shape accurate, keep the measurement current, check for resistance. The line is not static. It responds. The computational cost of that response — calling `distance_to` and rebuilding transforms each frame — is visible in how VR applications are actually structured. A line in a physics simulation is expensive not because the concept is complex but because it has to be re-evaluated against two moving objects sixty times per second.

---

## Constructing Distance

The label reads a number. Where does it come from?

```gdscript
func update_length_label(start_pos: Vector3, end_pos: Vector3):
    var distance = start_pos.distance_to(end_pos)
    length_label.text = "Length: %.2fm" % distance
    var center_pos = (start_pos + end_pos) / 2.0
    center_pos.y += 0.05
    length_label.position = center_pos
```

`distance_to` is the Euclidean distance formula applied in 3D:

```gdscript
# What distance_to computes:
var dx = end_pos.x - start_pos.x
var dy = end_pos.y - start_pos.y
var dz = end_pos.z - start_pos.z
var distance = sqrt(dx*dx + dy*dy + dz*dz)
```

The Pythagorean theorem, extended to one more dimension. Two points in 3D space define a right triangle with legs along x, y, and z. The hypotenuse is the distance.

The label position — `(start_pos + end_pos) / 2.0` — is the midpoint formula. The average of two vectors is the point halfway between them. This appears constantly: physics engines use it for center-of-mass approximations, rendering uses it for bounding sphere centers, pathfinding uses it for edge cost estimates. The midpoint is as fundamental as the distance.

Notice the label is a `Label3D` with `billboard = BaseMaterial3D.BILLBOARD_ENABLED`. The label always faces the camera. This is a practical VR constraint — text rotated away from you is unreadable — but it also marks a limit: the measurement exists in 3D space, but the representation of that measurement is flattened back into a 2D interface to be legible. All annotation is projection.

---

## Rendering the Invisible

Mathematics doesn't have thickness. A line segment is one-dimensional — no width, no volume. Godot has no native one-dimensional mesh. To render a line, `line.gd` constructs a cylinder:

```gdscript
func create_connection_line(start_pos: Vector3, end_pos: Vector3) -> MeshInstance3D:
    var line = MeshInstance3D.new()
    var cylinder = CylinderMesh.new()
    var distance = start_pos.distance_to(end_pos)
    cylinder.height = distance
    cylinder.top_radius = line_thickness
    cylinder.bottom_radius = line_thickness
    cylinder.radial_segments = 4
    line.mesh = cylinder
```

The cylinder's height is set to the distance between points. `radial_segments = 4` makes a square cross-section — a diamond-shaped tube, efficient for the GPU. The mathematical line has become a physical object with a real cross-section, real triangles, real draw calls.

This gap — between the concept and its representation — is permanent. Every line you render is a cylinder approximating the infinite thinness of the Euclidean ideal. The `line_thickness` export variable is an admission: we cannot render mathematics directly. We render approximations that are convincing at some scale.

---

## The Orientation Problem

The cylinder exists at the wrong rotation by default. Godot's `CylinderMesh` is vertical — it extends along the Y axis. The line between two arbitrary points is almost never vertical. The cylinder needs to be rotated to point from `start_pos` to `end_pos`.

This is the basis problem. Given a direction vector, construct a complete 3D coordinate frame:

```gdscript
var direction = (end_pos - start_pos).normalized()
if direction.length() > 0.001:
    var up = Vector3.UP
    var right = direction.cross(up).normalized()
    if right.length() < 0.001:  # direction is parallel to UP
        right = Vector3.RIGHT
        up = right.cross(direction).normalized()
    else:
        up = right.cross(direction).normalized()
    line.transform.basis = Basis(right, direction, up)
```

A `Basis` in Godot is three vectors: the X axis, Y axis, and Z axis of a local coordinate system. Here, the cylinder's local Y axis should point along `direction`. The X and Z axes (right and up) are constructed by cross product.

`cross` finds a vector perpendicular to two input vectors. `direction.cross(Vector3.UP)` gives a horizontal right-vector. Then `right.cross(direction)` gives the remaining axis. Three perpendicular vectors: a full orientation.

The edge case — `if right.length() < 0.001` — handles the case where `direction` is parallel to `Vector3.UP`. When two vectors are parallel, their cross product is zero. The fallback swaps the reference vector to `Vector3.RIGHT` instead.

This pattern repeats throughout 3D graphics: anytime you need to orient something to face a direction, you construct a basis. It appears in billboard calculations, camera look-at functions, procedural object placement, VR controller orientation. The `line` artifact teaches it as a concrete, graspable thing: the cylinder must point from your left hand to your right hand, and the math for "pointing at" is cross product twice.

---

## Integer Resistance

Pull the line to exactly 1.0 meters. Something happens. The cylinder jitters. A crackling sound. Your controller buzzes. At 1.0, 2.0, 3.0 meters — at whole numbers — the line resists.

```gdscript
func _process_resistance(distance: float):
    var remainder = fmod(distance, 1.0)
    var dist_to_int = min(remainder, 1.0 - remainder)
    
    if dist_to_int < resistance_threshold:
        var t = 1.0 - (dist_to_int / resistance_threshold)
        var intensity = pow(t, 2.0)
        
        if current_line:
            var jitter = Vector3(
                randf_range(-1, 1),
                randf_range(-1, 1),
                randf_range(-1, 1)
            ) * max_jitter * intensity
            current_line.position += jitter
```

`fmod(distance, 1.0)` returns the fractional part of the distance. At 1.73 meters, the remainder is 0.73. `min(remainder, 1.0 - remainder)` is the distance to the nearest integer: at 0.73, that's 0.27; at 0.97, that's 0.03.

When `dist_to_int < resistance_threshold` (default 0.08 meters), the line enters the resistance zone. Intensity scales quadratically with proximity — `pow(t, 2.0)` — meaning the last few centimeters to the integer snap produce sharply increasing feedback.

Three channels of feedback fire simultaneously: visual jitter on the cylinder, audio glitch from a white noise loop, and haptic pulse on the holding controller.

Why integers? Measurement is cultural. The meter is a political artifact — originally defined as one ten-millionth of the distance from equator to pole, later redefined in terms of the speed of light, always a negotiation between precision and convention. Whole numbers feel stable, clean, *correct* in a way that 1.4142... does not. The resistance mechanic makes that cultural prejudice visceral. The line fights you at the boundaries of convention.

It also makes a geometric point: real-valued distances are continuous. The number line between 0.9 and 1.1 contains uncountably many positions, every one as mathematically valid as 1.0 exactly. The privileging of integers is an import from human measurement practice — not from geometry.

---

## Segment vs. Vector

The `line` artifact has no direction. Grab sphere one or grab sphere two — the line doesn't care which is the start and which is the end. It's a segment: pure distance between two positions.

The `vectorline` artifact is different. It has an arrowhead. It has a `vector_name`. The relationship it encodes has a *direction* — from A toward B:

```gdscript
func _update_arrow_tip(start_local: Vector3, end_local: Vector3) -> void:
    var direction = end_local - start_local
    var normalized = direction / distance
    var tip_length = min(arrow_tip_length, distance)
    var cone_mesh := arrow_tip.mesh as CylinderMesh
    cone_mesh.top_radius = 0.0
    cone_mesh.bottom_radius = arrow_tip_radius
    arrow_tip.position = end_local - normalized * (tip_length * 0.5)
```

The cone sits at the `end_local` position — the head, not the tail. `top_radius = 0.0` makes it a cone rather than a cylinder. The tip always points away from `start_local`, regardless of how you move the sphere.

The label changes too:

```gdscript
length_label.text = "%s |v| = %.2fm" % [vector_name, distance]
```

`|v|` is the standard notation for vector magnitude. The bars indicate absolute value in the sense of length — the scalar distance, stripped of direction. A vector has two properties: magnitude and direction. `distance_to` gives you only the magnitude. The arrow gives you the direction. Together, they define the vector completely.

This distinction matters. A line segment between two points is symmetric — `AB` and `BA` describe the same geometric object. A vector from A to B and a vector from B to A are different: same magnitude, opposite direction. When you extend these maps into transformations, forces, and physics, the direction will carry meaning that the segment cannot.

---

## What the Screen Sees

The `science_screen` at position (2,7) switches to line mode when it detects the `line` artifact. It shows the 3D line projected onto a 2D coordinate system:

```gdscript
func _draw_line_data() -> void:
    var sa: Vector2 = _w2s(pos_a, cx, cy, side, grid_range)
    var sb: Vector2 = _w2s(pos_b, cx, cy, side, grid_range)
    
    # Line AB (violet with glow)
    draw_line(sa, sb, Color(I_DOT, 0.15), 6.0)
    draw_line(sa, sb, I_DOT, 2.0)
    
    # Midpoint
    var mid: Vector2 = (sa + sb) * 0.5
    draw_circle(mid, 3.0, Color(I_DOT, 0.5))
    
    # Endpoint A (cyan), Endpoint B (amber)
    draw_circle(sa, 3.5, I_CYAN)
    draw_circle(sb, 3.5, I_AMBER)
```

`_w2s` converts a world position (Vector3) into screen coordinates (Vector2) by dropping the Z axis and scaling to the display area. The 3D line becomes a 2D line. The Z dimension — depth — disappears.

This is projection: a transformation that reduces dimension. It preserves the relationship between A and B in the XY plane but destroys information about Z. The screen shows you something true and incomplete simultaneously.

Projection lines from each endpoint to the X and Y axes appear as dashed guides — showing where each point sits on each axis independently. These projections will become coordinates in the next maps. They're how you read a position off a diagram.

The screen encodes a teaching commitment: embodied manipulation (hands, VR, haptics) and diagram-based reasoning (2D abstraction, coordinates, labels) are different cognitive registers. Moving a line in VR and reading its coordinates on a screen require different skills. This map runs both simultaneously.

---

## From Segment to Network

A single line lives in isolation. It connects two points, measures distance, encodes direction. This is everything a line *is* — but not yet everything lines *do*.

*Point_Lines* takes the next step: multiple lines sharing endpoints, lines that are parallel or perpendicular, grids of lines that define a metric framework. The line you manipulate here is one instance of a type. Point_Lines shows what happens when instances relate to each other — when lines form systems instead of isolated pairs.

The basis construction in `line.gd` and `vectorline.gd` will reappear in those contexts, applied to arrays of segments rather than one. The distance formula will be used to check whether lines are equal length. The direction vector will be compared between lines to detect parallelism.

Everything this map teaches is necessary infrastructure. The single line is not a destination — it is the atomic unit from which all geometric structure is composed.

---

## Possible Artifacts

**`angle_between_lines`** — Two `vectorline` instances sharing an origin, with a live label showing the angle between their direction vectors. Teaches `acos(dir_a.dot(dir_b))` as the fundamental relationship between directions. The dot product alone is present in the existing code but never surfaced as a learnable quantity.

**`midpoint_marker`** — A grabbable sphere that auto-positions at `(start + end) / 2.0` and moves when either endpoint moves. Makes the midpoint formula tactile rather than just labeled. Currently the midpoint appears only as a text label on the screen overlay.

**`projection_lines`** — A `vectorline` with visible drop lines to the X and Y axes, matching what the science_screen draws in 2D but rendered in 3D space at the line's actual position. Bridges the gap between the 3D artifact and its 2D screen representation — the learner sees the projection happening in the same space they're inhabiting.