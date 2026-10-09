# Koch / Sierpinski — the distance between

**Learning elements**

- An ordered path of positions
- Replacing one segment with four
- Current and next arrays
- A turn in a declared plane
- Endpoint distance and path length

Hold the black point on the small line beside the Koch desk. Move it along the drawing. Its partner follows the larger line on the floor. Press the trigger once: the line takes a detour. Find the two ends again. They are still four represented metres apart.

NEXT beside your hand makes the same replacement. BACK and RESET let you compare stages; the original desk also offers TURN and FORM. Each step replaces **every current segment**, including those already climbing or descending. The readout gives the distance between the ends, the complete path length, and your point's place along that path.

## What continues

Keep the museum workspace. We bring `PointBody` from Cantor and `LineSkin` from Recursion. Trace taught us to keep positions in order and connect neighbouring entries. Cantor taught us to read `current`, construct a separate `next`, then change which record is current. Here that pattern adds a detour instead of removing a middle.

Save the three files below together. Put `koch.gd` on your existing empty, unit-scale `PointStudy` node, facing its positive Z side. Keep the previous lesson's script. The museum already supplies the light, camera, player and XR pickup functions. This script creates its own drawing and point, with no scene-node references.

Hold the point and press its trigger to replace once. On desktop, press Enter (`ui_accept`); use the existing pickup/drop interaction to move the point. The complete small study stops after four steps. Run it again to return to the seed. Its purpose is the open Koch path; the production hall adds the table, floor receiver, BACK/RESET controls and closed-triangle comparison.

## Four segments from two ends

The seed is `(-2, 0, 0)` to `(2, 0, 0)`. These are positions in a **local XY construction plane**. `third = (end - a) / 3` is a displacement, with both direction and length.

Place `b` one third from `a`, and `d` two thirds from `a`. From `b`, turn that displacement sixty degrees about positive Z (`Vector3.BACK`) to find `c`. The path goes **a → b → c → d → end**. Its middle makes two sides of an equilateral triangle. Each of the four new segments has a third of the old length.

`replace_path()` appends `a`, `b`, `c` and `d` for every old segment. The next segment supplies the shared endpoint; only the very last endpoint needs a separate append. One segment therefore needs two positions, four segments need five, and 256 segments need 257. This list describes connections through order.

## koch.gd

Read `replace_path()`, `advance()` and `path_length()` first. The remaining functions connect the known point to the drawing. The closest-point reader is supplied in full below those operations.

<!-- student-code:koch.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
const VIEW_SCALE := 0.3
const ORIGIN := Vector3(0, 1.2, 0.2)
var original: Array[Vector3] = [Vector3(-2, 0, 0), Vector3(2, 0, 0)]
var current: Array[Vector3] = []
var generation := 0
var point: XRToolsPickable
var drawing: Node3D
var readout: Label3D
var cursor := Vector3.ZERO
var along := 0.0

func _ready() -> void:
    current = original.duplicate()
    drawing = Node3D.new()
    add_child(drawing)
    point = PointBody.new()
    add_child(point)
    point.action_pressed.connect(func(_body): advance())
    readout = Label3D.new()
    readout.position = Vector3(0, 1.85, -0.3)
    readout.font_size = 24
    readout.pixel_size = 0.001
    add_child(readout)
    redraw()

func replace_path(path: Array[Vector3], side: float = 1.0) -> Array[Vector3]:
    assert(path.size() >= 2 and absf(side) == 1.0)
    var next: Array[Vector3] = []
    for i in path.size() - 1:
        var a := path[i]
        var end := path[i + 1]
        var third := (end - a) / 3.0
        var b := a + third
        var c := b + third.rotated(Vector3.BACK, side * PI / 3.0)
        var d := a + third * 2.0
        next.append_array([a, b, c, d])
    next.append(path[-1])
    return next

func advance() -> void:
    if generation == 4:
        return
    current = replace_path(current)
    generation += 1
    redraw()

func path_length(path: Array[Vector3]) -> float:
    var total := 0.0
    for i in path.size() - 1:
        total += path[i].distance_to(path[i + 1])
    return total

func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("ui_accept"):
        advance()

func _physics_process(_delta: float) -> void:
    if point.held():
        var local := (to_local(point.global_position) - ORIGIN) / VIEW_SCALE
        var reading := nearest_on_path(Vector3(local.x, -local.z, 0))
        cursor = reading.point
        along = reading.along
    else:
        point.global_transform = global_transform * Transform3D(Basis.IDENTITY, display(cursor))
    readout.text = "step %d / 4 | %d segments\nends %.3f m | path %.3f m | at %.3f m along" % [generation, current.size() - 1, current[0].distance_to(current[-1]), path_length(current), along]

# Supplied reader: closest point on the finite drawing, with distance from its start.
# This does not measure the length of the player's hand movement.
func nearest_on_path(query: Vector3) -> Dictionary:
    var best := INF
    var prefix := 0.0
    var answer := {"point":current[0], "along":0.0}
    for i in current.size() - 1:
        var a := current[i]
        var delta := current[i + 1] - a
        var t := clampf((query - a).dot(delta) / delta.length_squared(), 0.0, 1.0)
        var p := a + delta * t
        if p.distance_squared_to(query) < best:
            best = p.distance_squared_to(query)
            answer = {"point":p, "along":prefix + t * delta.length()}
        prefix += delta.length()
    return answer

func display(p: Vector3) -> Vector3:
    return ORIGIN + Vector3(p.x, 0, -p.y) * VIEW_SCALE

func redraw() -> void:
    for child in drawing.get_children():
        drawing.remove_child(child)
        child.queue_free()
    for i in current.size() - 1:
        var start := display(current[i])
        var displacement := display(current[i + 1]) - start
        var line = LineSkin.new()
        drawing.add_child(line)
        line.mesh.top_radius = 0.002
        line.mesh.bottom_radius = 0.002
        line.show_segment(start, displacement, displacement.length())
    cursor = current[0]
    along = 0.0
```

The loop finishes before `current` is replaced. The original seed stays intact. Like Cantor, this implementation makes one generation per action rather than calling itself to complete every generation at once.

`path_length()` adds the distance between **each neighbouring pair**. Endpoint distance uses only the first and last positions. After one replacement those readings are 16/3 metres and 4 metres. After four they are about 12.642 metres and 4 metres. The arithmetic is `4 × (4/3)^n`; it belongs to this particular sixty-degree, thirds rule.

## Reading is another operation

`display()` lays the XY construction onto a horizontal XZ drawing. `VIEW_SCALE` makes four represented metres fit into 1.2 physical metres. It does not change the stored positions or the length calculation. The supplied LineSkin gives each connection a thin visible cylinder; it supplies no collision.

The hand remains free while held. The reader finds the nearest point on any segment, then adds the lengths of the preceding segments. On release the ball parks at that reading. It does not drag you or force your hand to follow the path. If you skip from one fold to another, the reading jumps. **“At 3 metres along” is an address on this path, not proof that your hand travelled 3 metres.**

Small folds may become hard to select with this sphere or distinguish in the headset. The exact finite record and the useful size of a gesture have different limits. The larger floor drawing gives the same route another scale; it remains a drawing supported by the existing floor, not a narrow balance beam.

## Predict, then change

Before the second step, predict sixteen segments and seventeen positions. Each segment should be 4/9 metre; their total should be 64/9 metres. Neither endpoint should move. After the fourth step, another trigger should leave the record unchanged.

For your own variation, change the call to `replace_path(current, -1.0)` and run again. Predict which coordinates will change sign. The first peak moves below the starting line. Count, segment lengths and endpoint distance stay the same. This reverses the sixty-degree turn; changing the angle itself would require a new length calculation rather than borrowing the same formula.

Now try a sloping seed in the XY plane, for example `(-1, -1, 0)` to `(1, 1, 0)`. Predict its starting length and its first replacement length. The rule uses each segment's displacement, so the peaks turn with the segment. Arbitrary out-of-plane endpoints need another declared construction plane; this lesson does not supply one.

## Across the aisle

At the existing Sierpinski triangle, press NEXT and find the missing middle. Three midpoint pairs give three corner triangles. Each corner has half the side length and a quarter of the area, so three quarters of the parent's area remain. The next generation applies that same replacement to every retained triangle.

Compare the two operations: Koch keeps the connection and increases length; Sierpinski keeps three corners and reduces area. VIEW changes whether retained corners or removed middles receive meshes, without changing the replacement rule. These are distinct constructions using a familiar current/next pattern. Rebuilding every artifact in this hall is not another assignment.

The optional box-counting desk changes its measurement grid over a held sample. Leave it for a separate investigation if needed. The next main construction is Menger: carry the replacement pattern from a segment and a triangle into cells of a cube.

## The carried files

These are unchanged from the earlier lessons. `PointBody` supplies pickup, release and the trigger signal inherited from XRTools. `LineSkin` places a cylinder between two ends. They are printed here so the example has no missing code dependency; the prepared museum still supplies XRTools and the player.

### point_body.gd

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable
## Point Lines' frozen point construction, made smaller for the hand model.
var tint := Color("25212a")
var desktop_pointer: WeakRef

func _init() -> void:
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	release_mode = XRToolsPickable.ReleaseMode.FROZEN
	ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	collision_layer = 4
	collision_mask = 0
	var surface := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.085
	sphere.height = 0.17
	sphere.radial_segments = 24
	sphere.rings = 12
	surface.mesh = sphere
	add_child(surface)
	var boundary := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.085
	boundary.shape = shape
	add_child(boundary)

func _ready() -> void:
	super._ready()
	var finish := StandardMaterial3D.new()
	finish.albedo_color = tint
	finish.roughness = 0.24
	get_child(0).material_override = finish

func held() -> bool:
	return is_picked_up() or (desktop_pointer != null and desktop_pointer.get_ref() != null)

func on_desktop_grab(pointer: Node) -> void:
	desktop_pointer = weakref(pointer)

func on_desktop_drop(_pointer: Node) -> void:
	desktop_pointer = null
```

### line_skin.gd

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
