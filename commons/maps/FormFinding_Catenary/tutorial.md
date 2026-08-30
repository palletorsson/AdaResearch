# Form-Finding: Catenary

Two of the oldest solved minimisations, side by side. Before them, a boundary must be fixed — two anchors for the chain, two rings for the film.

Fix the anchors.

```gdscript
for i in range(control_point_count):
    var point: Node3D = point_scene.instantiate()
    var t: float = float(i) / float(control_point_count - 1)
    point.position = Vector3((t - 0.5) * cable_length, 1, 0)
    $ControlPoints.add_child(point)
    control_points.append(point)
```

Grabbable spheres. These are the only decisions you make. The curve between them is not yours.

Pull each span down by a fraction of its own length.

```gdscript
var p1: Vector3 = to_local(control_points[i].global_position)
var p2: Vector3 = to_local(control_points[i + 1].global_position)
var distance: float = p1.distance_to(p2)
var handle_length: float = distance * 0.3
curve.set_point_out(i, Vector3(handle_length, -gravity_sag * distance * 0.5, 0))
curve.set_point_in(i + 1, Vector3(-handle_length, -gravity_sag * distance * 0.5, 0))
```

The sag scales with the span. Move an anchor and the depth follows. That dependence is the whole difference between a curve derived and a curve drawn.

Sweep a tube along the baked curve.

```gdscript
var total_length: float = curve.get_baked_length()
var sample_count: int = maxi(2, int(total_length * spline_resolution))
for i in range(sample_count):
    var t: float = float(i) / float(sample_count - 1)
    positions.append(curve.sample_baked(t * total_length))
```

`sample_baked` walks the curve by arc length, not by parameter. Even sampling along a cable that sags unevenly.

Draw the alternative, so you can see what it costs.

```gdscript
var depth: float = 0.45
var out := PackedVector3Array()
for k in range(41):
    var t: float = float(k) / 40.0
    var p: Vector3 = a[0].lerp(a[a.size() - 1], t)
    p.y -= depth * 4.0 * t * (1.0 - t)
    out.append(p)
```

One fair bow of fixed depth between the end anchors only. The interior control spheres visibly do not sit on it. A drawn curve has stopped agreeing with its own data.

Revolve a cosh to get the soap film.

```gdscript
@export var c: float = 0.5      # waist radius

var r: float = c * cosh(u / c)
var x: float = r * cos(v)
var y: float = r * sin(v)
var z: float = u
```

The catenary rotated is the catenoid — the least area that can span two rings. Galileo guessed the hanging chain was a parabola. It is `cosh`, and the chain had been getting it right the whole time. Pull the rings too far apart and no catenoid exists; the film breaks into two discs.

Rule the other minimal surface.

```gdscript
@export var pitch: float = 0.3

var x: float = u * cos(v)
var y: float = u * sin(v)
var z: float = pitch * v
```

A straight line swept as it rises. The helicoid and the plane are the only ruled minimal surfaces, and the helicoid bends continuously into a catenoid without ever stretching.

Give the surfaces a body so hands can move the boundary.

```gdscript
var cylinder := CylinderShape3D.new()
cylinder.radius = c * cosh(u_max / c) * scale_factor
cylinder.height = (u_max - u_min) * scale_factor
collision.shape = cylinder
```

The surface is a function of its frame and nothing else. Move the frame and the minimum moves with it, instantly, with no solver in between.

You can now hang a cable whose sag is derived rather than drawn, revolve a catenary into a minimal surface, rule a helicoid, and hold both by their boundaries. The draftsman proposes; gravity computes. FormFinding_Relaxation replaces the closed form with a mesh that has to settle.
