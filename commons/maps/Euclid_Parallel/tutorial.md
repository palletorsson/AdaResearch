# The same triangle, measured

## Learning elements

- Constructing a parallel through a point.
- Measuring a triangle's interior angles.
- Assumptions, measurements and proof.
- Recognising a degenerate construction.

**Carry:** PointBody, the finite cylinder from Point Lines, three vertices and a triangle face. **New:** calculate the three angles and construct a parallel using the base direction. **Supplied:** the existing Endless Museum, its desktop/XR player, XRTools and the named push-button scene. We are working inside that project.

## Encounter

Find the postulates plaque, the three parallel line modules and the small triangle in Euclid's hall. NEXT changes the sentence; GOLD changes its emphasis. Neither changes the room's geometry. The old flat triangle's three “60°” labels are fixed text even though its corners are unequal. Our study will read the positions instead.

Return to the object you can already build: three points joined by three segments. Move a corner. Its individual angles change. What happens to their sum? Add a guide through C parallel to AB; hide it again. Does removing a drawing remove the relationship?

## Reuse the bodies

Create a folder in your museum working copy. Save the four scripts printed below together. The small `point_body.gd` is unchanged from Graph Theory and Gradient Landscape; `line_skin.gd` is unchanged from Point Lines. They are reprinted at the end for a complete reconstruction, not taught again. We reuse the class and construction; no live sphere or Machine Learning weights are transferred across hall loads.

Create one empty Node3D named `EuclidStudy`, keep its scale at `(1, 1, 1)`, and attach `euclid_study.gd`. Put it on clear floor in your working copy of the Euclid hall; allow 2.8 metres for the table and an approach on its local +Z side. The supplied `res://doc/book/studies/euclid-lineage/museum.tscn` launcher opens the existing hall and mounts this study at a checked position. To run your reconstructed folder, change the `LESSON` preload in `res://doc/book/studies/euclid-lineage/museum.gd` to your `euclid_study.gd`, then run the launcher scene with F6. It is room infrastructure, not a second geometry implementation. No replacement camera, light or player is part of the lesson.

## Keep positions; calculate angles

The array stores A, B and C in table coordinates. A Vector2's second coordinate becomes local Z; every measured point lies on the same plane. At each corner, subtract that position from the other two to obtain two outward vectors. `atan2(abs(cross), dot)` gives their interior angle. Sum those three measured values; do not print 180 as the answer.

`cross` here is the scalar 2D cross product. Its magnitude is twice the area. If the points coincide or nearly align, we withhold the angle reading. `EPS` is a numerical policy for this study, not a new geometric postulate. The relative area check rejects very thin triangles too.

For the parallel, copy the direction B − A and centre the visible segment on C. Equal directions in this flat coordinate model construct parallel supporting lines when C is off AB. The cylinder has finite length; the mathematical line does not end at its cap.

Save `triangle_record.gd`:

<!-- student-code:triangle_record.gd -->
```gdscript
extends RefCounted
## A flat construction in metres. Positions and measurements are separate records.
const EPS := 0.00001
var points: Array[Vector2] = []

func _init() -> void:
    reset()

func reset() -> void:
    points.assign([Vector2(-0.7, 0.4), Vector2(0.7, 0.4), Vector2(0, -0.6)])

func measure() -> Dictionary:
    var ab := points[1] - points[0]
    var ac := points[2] - points[0]
    var bc := points[2] - points[1]
    var longest := maxf(ab.length(), maxf(ac.length(), bc.length()))
    var twice_area := absf(ab.cross(ac))
    # Refuse coincident or nearly collinear corners at this numerical scale.
    if longest <= EPS or twice_area <= EPS * longest * longest:
        return {"valid": false, "angles": [], "sum": 0.0, "area": twice_area * 0.5}
    var angles: Array[float] = []
    var total := 0.0
    for i in range(3):
        var u := points[(i + 1) % 3] - points[i]
        var v := points[(i + 2) % 3] - points[i]
        var angle := rad_to_deg(atan2(absf(u.cross(v)), u.dot(v)))
        angles.append(angle)
        total += angle
    return {"valid": true, "angles": angles, "sum": total, "area": twice_area * 0.5}

func parallel_ends(half_length: float = 1.25) -> Array[Vector2]:
    var direction := points[1] - points[0]
    if direction.length() <= EPS:
        return []
    direction = direction.normalized() * half_length
    return [points[2] - direction, points[2] + direction]
```

## Put the construction in the hand

The host creates every point, segment, label, face and control. There are no hidden scene-node references. GUIDE—or G, or a held point's trigger—only hides/shows the gold construction. RESET—or R—restores the three starting positions and keeps the guide setting. Put all points down before resetting.

The hand may move in three dimensions. We convert its world position into this study's local frame, keep X and Z and limit them to ±1 metre. While held, the sphere stays in your hand; the edges and corner label show its projected, bounded position. On release it rests at that recorded position. The tabletop is a visual guide, not a physical constraint. Moving or rotating the whole unit-scale study does not change this local construction.

Save `euclid_study.gd`:

<!-- student-code:euclid_study.gd -->
```gdscript
extends Node3D
const Triangle = preload("triangle_record.gd")
const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
const PushButton = preload("res://commons/interactables/push_button.tscn")
const HEIGHT := 1.12
var model := Triangle.new()
var points: Array = []
var edges: Array = []
var labels: Array[Label3D] = []
var guide := LineSkin.new()
var face := MeshInstance3D.new()
var readout := Label3D.new()
var guide_on := true

func place(p: Vector2) -> Vector3:
    return Vector3(p.x, HEIGHT, p.y)

func _ready() -> void:
    var top := MeshInstance3D.new()
    var slab := BoxMesh.new()
    slab.size = Vector3(2.8, 0.08, 2.8)
    top.mesh = slab
    top.position.y = HEIGHT - 0.16
    top.material_override = finish(Color("e2ded5"))
    add_child(top)
    for i in range(3):
        var point := PointBody.new()
        point.name = ["A", "B", "C"][i]
        add_child(point)
        points.append(point)
        point.action_pressed.connect(func(_hand): toggle_guide())
        var edge := LineSkin.new()
        add_child(edge)
        edges.append(edge)
        var label := Label3D.new()
        label.font_size = 26
        label.outline_size = 0
        label.pixel_size = 0.002
        label.modulate = Color("25212a")
        label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        add_child(label)
        labels.append(label)
    add_child(guide)
    guide.material_override = finish(Color("a27622"))
    face.material_override = finish(Color("b2c2ca"))
    add_child(face)
    readout.position = Vector3(0, 1.65, -1.0)
    readout.font_size = 24
    readout.outline_size = 6
    readout.outline_modulate = Color.WHITE
    readout.pixel_size = 0.002
    readout.modulate = Color("25212a")
    readout.no_depth_test = false
    add_child(readout)
    make_button("Guide", Vector3(-0.35, 1.03, 1.15), toggle_guide)
    make_button("Reset", Vector3(0.35, 1.03, 1.15), reset)
    redraw()

func finish(colour: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    material.roughness = 0.6
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    return material

func make_button(word: String, where: Vector3, callback: Callable) -> void:
    var button = PushButton.instantiate()
    button.name = word
    button.rotation = Vector3.ZERO
    button.position = where
    add_child(button)
    button.pressed.connect(callback)
    var label := Label3D.new()
    label.text = word.to_upper()
    label.position = where + Vector3(0, 0.13, 0)
    label.font_size = 22
    label.outline_size = 0
    label.pixel_size = 0.002
    label.modulate = Color("25212a")
    add_child(label)

func toggle_guide() -> void:
    guide_on = not guide_on
    redraw()

func reset() -> void:
    for point in points:
        if point.held(): return
    model.reset()
    redraw()

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_G: toggle_guide()
        if event.keycode == KEY_R: reset()

func _process(_delta: float) -> void:
    for i in range(3):
        if points[i].held():
            var local := to_local(points[i].global_position)
            model.points[i] = Vector2(clampf(local.x, -1, 1), clampf(local.z, -1, 1))
    redraw()

func _physics_process(_delta: float) -> void:
    # Frozen rigid bodies need their released display position maintained too.
    for i in range(points.size()):
        if not points[i].held(): points[i].global_position = to_global(place(model.points[i]))

func redraw() -> void:
    var result := model.measure()
    for i in range(points.size()):
        var a := place(model.points[i])
        var b := place(model.points[(i + 1) % 3])
        if not points[i].held(): points[i].global_position = to_global(a)
        edges[i].show_segment(a, b - a, a.distance_to(b))
        labels[i].position = a + Vector3(0, 0.18, 0)
        labels[i].text = "%s: %.2f°" % [["A", "B", "C"][i], result.angles[i]] if result.valid else ["A", "B", "C"][i] + ": —"
    var ends := model.parallel_ends()
    guide.hide()
    if guide_on and result.valid and ends.size() == 2:
        var start := place(ends[0])
        var displacement := place(ends[1]) - start
        guide.show_segment(start, displacement, displacement.length())
    face.mesh = null
    if result.valid:
        var builder := SurfaceTool.new()
        builder.begin(Mesh.PRIMITIVE_TRIANGLES)
        for p in model.points: builder.add_vertex(place(p) + Vector3.DOWN * 0.018)
        builder.generate_normals()
        face.mesh = builder.commit()
    readout.text = "MOVE A, B OR C / trigger or G: guide / R: reset\nHand projects onto this flat table; x and z stay within ±1 m.\n"
    readout.text += "Measured sum %.2f° / area %.3f m²\nGuide through C copies the direction B − A." % [result.sum, result.area] if result.valid else "No triangle reading: corners coincide or nearly align.\nSeparate the points to measure again."
```

## Predict, then try

1. Move only C. Predict which angles grow and which shrink; compare their measured sum. The initial sum should be near 180°, within floating-point error, without three equal corners.
2. Hide the guide. A, B, C and their measurements must remain unchanged. Show it again: its direction should still match B − A.
3. Put C on AB, or put A on B. The study should withhold its triangle reading and face. Separate them and recover it.
4. Make your own scalene triangle. Record its three positions before running. Predict that doubling all coordinates doubles lengths and quadruples area while keeping each angle. Try this in a separate model copy: the hand interface deliberately limits its workspace. Explain any failed comparison before changing the prediction.

An assertion should compare calculated values, not a label that contains the desired answer. Test `(0,0), (1,0), (0,1)`: the three measured angles should be 90°, 45°, 45°, and the area 0.5. Test coincident and collinear positions separately. Test the full host too: three visible point bodies, initialized readout, grab/release, and the two buttons must work.

## What the test means

We chose Cartesian coordinates, straight segments and Euclidean angle measurement before running. A thousand successful drags check this implementation in that model. They do not prove the parallel postulate from the others, or establish which geometry every space must have.

Euclid's Proposition I.32 constructs a parallel through a vertex and reasons with equal angles to derive the triangle sum. Our gold segment recalls that construction; it is not a formal proof checker. Euclid's fifth postulate concerns which extended lines meet when a transversal makes particular interior angles. The familiar “one parallel through an external point” formulation is a later equivalent formulation in the usual Euclidean setting. [Postulate 5](https://mathcs.clarku.edu/~djoyce/elements/bookI/post5.html) · [Proposition I.32](https://mathcs.clarku.edu/~djoyce/elements/bookI/propI32.html).

Carry the three points, the measured result and the assumptions into **Non-Euclidean Spaces**. There we must define the surface and its straightest paths before comparing corner angles. Bending these cylinders on the same table would not, by itself, supply that geometry.

## Carried files, complete

Copy these unchanged if they are not already beside your new scripts. Their source versions are the small PointBody used in Gradient Landscape and Point Lines' LineSkin. The button dependency is `res://commons/interactables/push_button.tscn`; XRTools supplies `XRToolsPickable`. Both belong to the prepared museum project. A blank Godot project does not include them.


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
