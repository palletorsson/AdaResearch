# Unit Circle — two coordinates from one angle

## Learning elements

- Radians and angular speed.
- Sine and cosine as signed coordinate ratios.
- A circle-position function: centre, radius and angle.
- A path and a graph with different horizontal axes.

In the museum, follow the bright point around the circle. Its vertical rod grows, disappears and grows below the centre. Stop the point with the nearby angle slider. At the top, the vertical offset is one metre and the horizontal offset is zero. Move through another quarter turn: those roles change.

Sine Space used sine to set heights. Here we open that function's geometric relationship: at radius one, cosine gives the horizontal offset and sine the vertical offset. We continue with our PointBody sphere and the thin cylinder from Lines. This sphere is a marker whose position we prescribe; pickup and collision are disabled in this study. The previous physical sphere remains available in its own lesson.

## Place the study in the existing hall

Use the museum and installed XR Tools from Day Zero. Save the three files below together. Attach `04_circle_coordinates.gd` to an empty Node3D in the Unit Circle hall's clear forecourt. The verified placement is hall-local `(11, 0, 10)`, Y rotation `180°`, scale `1`. No child nodes or scene paths are required. The museum supplies the player, camera, light and floor.

The local XY plane holds the circle. Positive X goes right and positive Y goes up when viewed from its positive Z side. The centre starts 1.5 metres above the floor. Angles increase counterclockwise from the rightmost point. `PI` radians is half a turn; `TAU` is a full turn. Angular speed is radians per second, so `PI / 2` makes one turn in four seconds.

The graph beside it shows one complete turn. Its horizontal axis allocates four metres to `TAU` radians. It does **not** show the sphere's horizontal position. Its vertical offset is the same `radius * sin(angle)` used by the sphere. At each full turn, the graph marker returns from the right end to the left.

## The complete study

<!-- student-code:04_circle_coordinates.gd -->

```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
@export var centre := Vector3(0, 1.5, 0)
@export var radius := 1.0
@export var angle := 0.0
@export var angular_speed := PI / 2.0
@export var running := true
var point: RigidBody3D
var marker: MeshInstance3D
var label: Label3D
var rods: Array[MeshInstance3D] = []

func circle_position(theta: float) -> Vector3:
    return centre + radius * Vector3(cos(theta), sin(theta), 0)

func graph_position(theta: float) -> Vector3:
    return centre + Vector3(1.6 + 4.0 * theta / TAU, radius * sin(theta), 0)

func line_between(a: Vector3, b: Vector3, colour: Color) -> MeshInstance3D:
    var line := LineSkin.new()
    line.material_override.albedo_color = colour
    add_child(line)
    line.show_segment(a, b - a, a.distance_to(b))
    return line

func _ready() -> void:
    point = PointBody.new()
    point.enabled = false
    point.collision_layer = 0
    point.collision_mask = 0
    add_child(point)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.035, 0.035, 0.04)
    ink.roughness = 0.22
    point.get_child(0).material_override = ink
    marker = MeshInstance3D.new()
    var cube := BoxMesh.new()
    cube.size = Vector3.ONE * 0.09
    marker.mesh = cube
    add_child(marker)
    var grey := Color(0.45, 0.45, 0.45)
    for i in range(48):
        var a := TAU * i / 48.0
        var b := TAU * (i + 1) / 48.0
        line_between(circle_position(a), circle_position(b), grey)
        line_between(graph_position(a), graph_position(b), grey)
    line_between(centre - Vector3.RIGHT * 1.2, centre + Vector3.RIGHT * 1.2, grey)
    line_between(centre - Vector3.UP * 1.2, centre + Vector3.UP * 1.2, grey)
    for colour in [grey, Color(0.2, 0.75, 0.35), Color(0.2, 0.5, 0.95), grey]:
        rods.append(line_between(centre, centre, colour))
    label = Label3D.new()
    label.position = centre + Vector3(2.4, 1.4, 0)
    label.font_size = 30
    label.pixel_size = 0.006
    label.outline_size = 8
    add_child(label)
    draw_state()

func _process(delta: float) -> void:
    if running:
        angle = fposmod(angle + angular_speed * delta, TAU)
    draw_state()

func draw_state() -> void:
    var p := circle_position(angle)
    point.position = p
    marker.position = graph_position(angle)
    var starts := [centre, Vector3(p.x, centre.y, centre.z), Vector3(centre.x, p.y, centre.z), p]
    var ends := [p, p, p, marker.position]
    for i in range(rods.size()):
        var displacement: Vector3 = ends[i] - starts[i]
        rods[i].show_segment(starts[i], displacement, displacement.length())
    label.text = "angle %.2f rad | x %+.2f m | y %+.2f m\nGRAPH: horizontal = angle; vertical = y offset" % [angle, p.x - centre.x, p.y - centre.y]
```


`circle_position()` returns a position without creating a new body. The centre supplies the location; the radius scales the two ratios. Keeping the centre outside that multiplication lets us move the construction without enlarging its distance from the origin.

The two short coloured rods show signed offsets through their endpoints. A rod has positive physical length even when its coordinate is negative; the readout supplies the sign. The grey connector joins the point to the graph marker at their shared height.

The loop in `_ready()` samples the two outlines once. It reuses the line renderer; it is drawing assistance, not another motion system. `_process()` advances one shared angle with `delta`, then updates both markers. There are no competing clocks. Change the radius or centre before running again so the sampled outlines and the moving markers use the same settings.

## Predict, stop, inspect

Set `running` to `false` and try these starting angles, rerunning after each edit. These are offsets from the centre, not world positions.

| Angle | X offset at radius 1 | Y offset at radius 1 |
| --- | --- | --- |
| `0.0` | +1 m | 0 m |
| `PI / 2.0` | 0 m | +1 m |
| `PI` | −1 m | 0 m |
| `3.0 * PI / 2.0` | 0 m | −1 m |

Restart with `running = true`. Half the angular speed: the same circle takes twice as long. Its radius and the graph's height do not change.

Now work independently: set the radius to `0.5` and the centre to `(0.5, 1.5, 0)`. Predict the top point's local position before running. Explain why the graph becomes half as high while its angle axis stays four metres wide. A successful variation preserves the shared height and the circle's distance from its new centre.

## Carried files

These are the unchanged PointBody from the preceding lessons and LineSkin from Lines. Keep your existing copies if they match. They provide the sphere and cylinder drawing; the new lesson is the coordinate function above.

<!-- student-code:point_body.gd -->

```gdscript
extends XRToolsPickable

const RADIUS := 0.14

func _init() -> void:
    freeze = true
    freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    release_mode = XRToolsPickable.ReleaseMode.FROZEN
    ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    collision_layer = 4
    collision_mask = 196615

    var surface := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    add_child(boundary)
```


<!-- student-code:line_skin.gd -->

```gdscript
# Supplied renderer, adapted from commons/primitives/line/line.gd.
# This finite cylinder gives the segment a visible thickness. It is not a collider.
# Inputs share the parent station's local frame; that station has unit scale.
extends MeshInstance3D

func _init() -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.012
	cylinder.bottom_radius = 0.012
	cylinder.radial_segments = 16
	cylinder.rings = 0
	mesh = cylinder
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.98, 0.70, 0.82)
	finish.roughness = 0.3
	material_override = finish
	visible = false

func show_segment(start: Vector3, displacement: Vector3, distance: float) -> void:
	# A zero-length segment has no direction. Do not normalize it.
	visible = distance > 0.0001
	if not visible:
		return
	(mesh as CylinderMesh).height = distance
	position = start + displacement * 0.5
	# CylinderMesh runs along local Y. This borrowed basis aligns it to the ends.
	var direction := displacement / distance
	var right := direction.cross(Vector3.UP).normalized()
	if right.length() < 0.001:
		right = Vector3.RIGHT
	var depth := right.cross(direction).normalized()
	basis = Basis(right, direction, depth)
```


One angular state now produces a visible position and two coordinate readings. In the next hall, many moving bodies will affect one another. A shared trigonometric formula alone does not make that coupling.
