class_name InvariantTape
extends Node3D
## WHAT STAYS THE SAME WHEN EVERYTHING CHANGES, MEASURED (Palle, 2026-11-03: make the invariants measurable).
##
## A strip of the printed tape (commons/artifacts/tape_roll/strip.gd) laid edge to edge across the top of a
## Trans_Pre cube, and pinned in the cube's OWN frame: the strip keeps its endpoints in the body it touches,
## scale included, and reprints what it reads each time it is redrawn. So the tape is the cube's ruler:
##   moved (the bob)   0.50 M · x1.00 · HEADING N   - the same, wherever it goes
##   turned (the spin) 0.50 M · x1.00 · HEADING NE  - the same length, a new heading
##   scaled (the pulse) 0.62 M · x1.24             - the one operation the length does not survive
## It is authored, not laid by a hand: a hall stands it beside the cube it measures.
##   config: target (the cube's artifact id on this floor; else the nearest pick_up_cube within 1.5 m)
const Strip := preload("res://commons/artifacts/tape_roll/strip.gd")
const CUBE_SCRIPT := "res://commons/scenes/mapobjects/pick_up_cube.gd"
const PAPER := Color("efe7d2")
const INK := Color("1d1d1f")

@export var target := ""

var strip: MeshInstance3D
var label: Label3D
var cube: Node3D
var rest_length := 0.0
var reading := ""

func apply_grid_config(config: Dictionary) -> void:
	if config.has("target"): target = str(config.target)

func _ready() -> void:
	if has_meta("config_target"): target = str(get_meta("config_target"))
	# The floor builds its artifacts one by one: the cube may stand up after the tape.
	for i in 30:
		await get_tree().process_frame
		if not is_inside_tree(): return
		cube = _find_cube()
		if cube != null: break
	if cube == null:
		push_warning("INVARIANT_TAPE: no cube to measure near " + str(global_position));return
	_lay()

func _find_cube() -> Node3D:
	var floor_root := get_parent().get_parent() if get_parent() != null else null
	if floor_root == null: return null
	if target != "":
		var named := floor_root.get_node_or_null(NodePath(target + "/Artifact")) as Node3D
		if named != null: return named
	var best: Node3D = null;var near := 1.5
	for mount in floor_root.get_children():
		var a := mount.get_node_or_null("Artifact") as Node3D
		if a == null or a.get_script() == null or a.get_script().resource_path != CUBE_SCRIPT: continue
		var d := Vector2(a.global_position.x - global_position.x, a.global_position.z - global_position.z).length()
		if d < near: best = a;near = d
	return best

## The visible body: the pulse scales this mesh, the spin and the bob move its parent, so a point held in its frame
## goes through all three.
func _body() -> MeshInstance3D:
	return cube.find_child("CubeBaseMesh", true, false) as MeshInstance3D

func _lay() -> void:
	var body := _body()
	if body == null or not (body.mesh is BoxMesh):
		push_warning("INVARIANT_TAPE: the cube has no box to measure");return
	var half: Vector3 = (body.mesh as BoxMesh).size * .5
	strip = Strip.new();strip.name = "Tape";add_child(strip)
	strip.top_level = true
	strip.tape_width = .09
	var skin := StandardMaterial3D.new();skin.albedo_color = PAPER;skin.roughness = .85;skin.cull_mode = BaseMaterial3D.CULL_DISABLED;strip.material_override = skin   # the ribbon winds face-down
	var up := Vector3.UP
	var anchors: Array[Dictionary] = [
		{"body": weakref(body), "point": Vector3(-half.x, half.y, 0), "normal": up},
		{"body": weakref(body), "point": Vector3(half.x, half.y, 0), "normal": up}]
	strip.anchors = anchors
	rest_length = (body.global_basis * Vector3(half.x * 2, 0, 0)).length()
	# The words lie on the strip as a Label3D, not as the roll's printed skin: that skin is a SubViewport
	# picture, and on the black wire cube it photographed as nothing at all.
	label = Label3D.new();label.name = "Reading";label.top_level = true;add_child(label)
	label.font_size = 40;label.pixel_size = .0011;label.outline_size = 0;label.modulate = INK
	label.double_sided = true;label.shaded = false
	var a := Strip.resolve(anchors[0]);var b := Strip.resolve(anchors[1])
	strip.draw_between(a.position, a.normal, b.position, b.normal)
	_print(a, b)

## In _process, not the physics tick: the cube pulses in its _process and this node stands later in the tree, so
## the tape is redrawn in the same frame the cube changed size - a tick behind, a growing cube swallows its tape.
func _process(_delta: float) -> void:
	if strip == null or not is_instance_valid(strip) or strip.anchors.size() < 2: return
	var a := Strip.resolve(strip.anchors[0]);var b := Strip.resolve(strip.anchors[1])
	if a.is_empty() or b.is_empty(): label.visible = false;return
	strip.draw_between(a.position, a.normal, b.position, b.normal)
	label.visible = strip.visible
	_print(a, b)

## The reading, laid flat on the tape along its length, turned so it reads from the cube's near side.
func _print(a: Dictionary, b: Dictionary) -> void:
	var p: Vector3 = a.position;var q: Vector3 = b.position
	label.text = _phrase(p, q, p.distance_to(q)).trim_suffix(" · ")
	label.pixel_size = .00086 * p.distance_to(q) / maxf(rest_length, .001)   # the print is on the tape: it scales with it
	var n: Vector3 = (Vector3(a.normal) + Vector3(b.normal)).normalized()
	var x := (q - p).normalized();var y := n.cross(x).normalized()
	if y.dot(Vector3.BACK) > 0: x = -x;y = -y   # letter tops point away from a reader on the +z side
	label.global_transform = Transform3D(Basis(x, y, n), (p + q) * .5 + n * .006)

func _phrase(a: Vector3, b: Vector3, length: float) -> String:
	var d := b - a
	var heading := fposmod(rad_to_deg(atan2(d.x, -d.z)), 360.0)
	var parts: Array[String] = ["%.2f M" % length, "x%.2f" % (length / maxf(rest_length, .001))]
	parts.append("HEADING " + ["N", "NE", "E", "SE", "S", "SW", "W", "NW"][int(round(heading / 45.0)) % 8])
	reading = " · ".join(PackedStringArray(parts))
	return reading + " · "

## For a probe: what the tape reads now, and the length it was laid at.
func measure() -> Dictionary:
	if strip == null: return {}
	var a := Strip.resolve(strip.anchors[0]);var b := Strip.resolve(strip.anchors[1])
	if a.is_empty() or b.is_empty(): return {}
	return {"length": a.position.distance_to(b.position), "rest": rest_length, "reading": reading, "printed": label.text if label else ""}
