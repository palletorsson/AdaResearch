extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TheArgumentOfSolids

## @identity
## lineage: the boolean surfaces SUPER OBJECT — a debating chamber where two solids
##   argue and the verdicts stand around them. At the centre, the contested ground: a
##   cube and a sphere overlapping, their shared region lit like evidence. The three
##   verdicts are LIVE CSG — a real CSGCombiner3D each, union, intersection and
##   subtraction — so the engine itself is doing the arguing. Beside them the
##   asymmetry bench: A−B and B−A side by side, unmistakably different, the only
##   verb that cares about order. Behind, a nesting tree whose branches are arguments
##   inside arguments, and a seam plate where a coincident face shows the edges the
##   cut INVENTED. At the far end, the debt: the same tree baked, still and cheap,
##   with a plaque saying what was given up. And the last vitrine is a small building
##   — a block minus its rooms, minus its doors.
## essence: form by argument. The engine ships the whole vocabulary as an enum on one
##   property — union, intersection, subtraction — and everything else is nesting.
##   Nothing here is a modelled shape; every verdict is a live boolean.
## truth: composition is not addition. Every architectural cavity is a difference.
##
## The 2026-08-27 super-object pass (Palle: "make one super object for each").

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 13
@export var box_size: float = 0.34
@export var ball_r: float = 0.22

func _ready() -> void:
	_rng.seed = seed
	_build_chamber()
	_build_contested_ground()
	_build_verdicts()
	_build_asymmetry()
	_build_tree()
	_build_seam()
	_build_debt()
	_build_architecture()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "box_size", "ball_r"]:
		if config_data.has(key):
			set(key, config_data[key])

func _tag(at: Vector3, title: String, sub: String) -> void:
	var tag := TextScreenScript.new()
	tag.mode = 2
	tag.width_m = 0.17
	tag.position = at
	add_child(tag)
	if tag.has_method("set_text"):
		tag.set_text(title, sub)

func _slab(at: Vector3, size: Vector3, tint: Color, glow: float = 0.0) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	m.position = at
	m.material_override = _glow_mat(tint, glow) if glow > 0.0 else _matte_mat(tint, 0.75)
	add_child(m)

## ONE ARGUMENT, made of real CSG. `op` is the CSGShape3D operation the sphere applies
## to the box - the engine performs it, nothing here is modelled.
func _argue(at: Vector3, op: int, tint: Color, offset: Vector3 = Vector3(0.16, 0.06, 0.0)) -> Node3D:
	var mat := _matte_mat(tint, 0.55)
	var combiner := CSGCombiner3D.new()
	combiner.position = at
	add_child(combiner)
	var box := CSGBox3D.new()
	box.size = Vector3.ONE * box_size
	box.material = mat
	combiner.add_child(box)
	var ball := CSGSphere3D.new()
	ball.radius = ball_r
	ball.radial_segments = 20
	ball.rings = 12
	ball.position = offset
	ball.operation = op
	ball.material = mat
	combiner.add_child(ball)
	return combiner

func _build_chamber() -> void:
	_slab(Vector3(0.0, 0.9, 0.0), Vector3(4.8, 0.1, 2.5), Color(0.13, 0.12, 0.15))
	for sx in [-1.0, 1.0]:
		_slab(Vector3(sx * 2.2, 0.45, 0.0), Vector3(0.13, 0.9, 1.7), Color(0.1, 0.1, 0.12))

func _build_contested_ground() -> void:
	# the two operands, apart and translucent, with the shared region lit between them
	var glass_a := StandardMaterial3D.new()
	glass_a.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_a.albedo_color = Color(0.45, 0.7, 0.95, 0.22)
	var glass_b := glass_a.duplicate()
	glass_b.albedo_color = Color(0.95, 0.6, 0.35, 0.22)
	var at := Vector3(-1.75, 1.22, -0.62)
	var a := MeshInstance3D.new()
	var am := BoxMesh.new()
	am.size = Vector3.ONE * box_size
	a.mesh = am
	a.position = at
	a.material_override = glass_a
	add_child(a)
	var b := MeshInstance3D.new()
	var bm := SphereMesh.new()
	bm.radius = ball_r
	bm.height = ball_r * 2.0
	b.mesh = bm
	b.position = at + Vector3(0.16, 0.06, 0.0)
	b.material_override = glass_b
	add_child(b)
	# the contested region, lit: an intersection, done live
	var shared := _argue(at, CSGShape3D.OPERATION_INTERSECTION, Color(0.95, 0.9, 0.4))
	shared.position = at
	shared.scale = Vector3.ONE * 0.99
	_tag(at + Vector3(0.0, -0.3, 0.30), "two solids, overlapping", "no shared ground, no argument")

func _build_verdicts() -> void:
	var specs := [
		["union", CSGShape3D.OPERATION_UNION, Color(0.5, 0.8, 0.6), "every point that belongs to either"],
		["intersection", CSGShape3D.OPERATION_INTERSECTION, Color(0.95, 0.85, 0.4), "only what both claim"],
		["difference", CSGShape3D.OPERATION_SUBTRACTION, Color(0.9, 0.45, 0.45), "the cavity, the doorway, the bite"],
	]
	for i in range(3):
		var row: Array = specs[i]
		var at := Vector3(-0.85 + 0.55 * float(i), 1.22, -0.62)
		_argue(at, row[1], row[2])
		_tag(at + Vector3(0.0, -0.3, 0.28), str(row[0]), str(row[3]))
	_tag(Vector3(-0.3, 0.94, -0.05), "the three verbs", "an enum on one property - the set is closed")

func _build_asymmetry() -> void:
	# A - B beside B - A: the only verb that cares about order
	var at1 := Vector3(1.05, 1.22, -0.62)
	_argue(at1, CSGShape3D.OPERATION_SUBTRACTION, Color(0.75, 0.55, 0.9))
	_tag(at1 + Vector3(0.0, -0.3, 0.28), "A - B", "a block with a bite")
	# B - A: sphere first, box subtracted from it
	var mat := _matte_mat(Color(0.55, 0.75, 0.9), 0.55)
	var comb := CSGCombiner3D.new()
	comb.position = Vector3(1.6, 1.22, -0.62)
	add_child(comb)
	var ball := CSGSphere3D.new()
	ball.radius = ball_r
	ball.radial_segments = 20
	ball.rings = 12
	ball.position = Vector3(0.16, 0.06, 0.0)
	ball.material = mat
	comb.add_child(ball)
	var box := CSGBox3D.new()
	box.size = Vector3.ONE * box_size
	box.operation = CSGShape3D.OPERATION_SUBTRACTION
	box.material = mat
	comb.add_child(box)
	_tag(Vector3(1.6, 0.92, -0.36), "B - A", "a crescent: not the same object")

func _build_tree() -> void:
	# arguments inside arguments: a combiner whose operand is itself a combiner
	var mat := _matte_mat(Color(0.6, 0.7, 0.85), 0.5)
	var outer := CSGCombiner3D.new()
	outer.position = Vector3(-1.75, 1.62, 0.62)
	add_child(outer)
	var inner := CSGCombiner3D.new()
	outer.add_child(inner)
	var base := CSGBox3D.new()
	base.size = Vector3(0.34, 0.2, 0.24)
	base.material = mat
	inner.add_child(base)
	var lug := CSGBox3D.new()
	lug.size = Vector3(0.14, 0.3, 0.14)
	lug.material = mat
	inner.add_child(lug)
	var bore := CSGCylinder3D.new()
	bore.radius = 0.07
	bore.height = 0.5
	bore.operation = CSGShape3D.OPERATION_SUBTRACTION
	bore.rotation.x = PI * 0.5
	bore.material = mat
	outer.add_child(bore)
	_tag(Vector3(-1.75, 1.38, 0.84), "the tree", "(box + lug) - bore: clauses inside clauses")

func _build_seam() -> void:
	# two boxes sharing a face exactly: where the cut invents new edges
	var mat := _matte_mat(Color(0.8, 0.8, 0.85), 0.5)
	var comb := CSGCombiner3D.new()
	comb.position = Vector3(-0.85, 1.62, 0.62)
	add_child(comb)
	var a := CSGBox3D.new()
	a.size = Vector3(0.3, 0.22, 0.22)
	a.material = mat
	comb.add_child(a)
	var b := CSGBox3D.new()
	b.size = Vector3(0.3, 0.22, 0.22)
	b.position = Vector3(0.3, 0.0, 0.0)          # face-to-face, exactly coincident
	b.material = mat
	comb.add_child(b)
	# the born edge, marked
	_slab(Vector3(-0.7, 1.62, 0.62), Vector3(0.006, 0.24, 0.24), Color(0.95, 0.35, 0.3), 1.6)
	_tag(Vector3(-0.85, 1.38, 0.84), "the seam", "edges born that neither solid had")

func _build_debt() -> void:
	# the same argument, baked: a plain mesh, cheap and still
	var mat := _matte_mat(Color(0.7, 0.62, 0.45), 0.6)
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.3, 0.24, 0.24)
	m.mesh = bm
	m.position = Vector3(0.2, 1.62, 0.62)
	m.material_override = mat
	add_child(m)
	_slab(Vector3(0.34, 1.68, 0.5), Vector3(0.12, 0.1, 0.12), Color(0.7, 0.62, 0.45))
	_tag(Vector3(0.2, 1.38, 0.84), "the debt", "baked: still and cheap, and no longer arguing")

func _build_architecture() -> void:
	# a building is a block minus its rooms, minus its doors - live
	var mat := _matte_mat(Color(0.82, 0.78, 0.7), 0.7)
	var comb := CSGCombiner3D.new()
	comb.position = Vector3(1.45, 1.55, 0.68)
	add_child(comb)
	var block := CSGBox3D.new()
	block.size = Vector3(0.7, 0.42, 0.4)
	block.material = mat
	comb.add_child(block)
	var r := RandomNumberGenerator.new()
	r.seed = seed
	for i in range(3):
		var room := CSGBox3D.new()
		room.size = Vector3(0.17, 0.26, 0.26)
		room.position = Vector3(-0.22 + 0.22 * float(i), -0.02, 0.02)
		room.operation = CSGShape3D.OPERATION_SUBTRACTION
		room.material = mat
		comb.add_child(room)
	for i in range(2):
		var door := CSGBox3D.new()
		door.size = Vector3(0.09, 0.14, 0.5)
		door.position = Vector3(-0.11 + 0.22 * float(i), -0.08, 0.0)
		door.operation = CSGShape3D.OPERATION_SUBTRACTION
		door.material = mat
		comb.add_child(door)
	_tag(Vector3(1.45, 1.26, 0.97), "architecture", "a block, minus the rooms, minus the doors")

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "ArgumentPlate"
	ts.mode = 2
	ts.width_m = 0.44
	ts.position = Vector3(-2.4, 0.24, 1.1)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("THE ARGUMENT OF SOLIDS",
			"Form by argument: the engine ships the whole vocabulary as an enum on one\nproperty - union, intersection, subtraction - and everything else is nesting.\nNothing here is modelled: every verdict is a live CSG tree. A - B beside B - A\nbecause subtraction is the only verb that cares who speaks first, and the last\nvitrine is a building, which is a block minus the places you can stand.")
