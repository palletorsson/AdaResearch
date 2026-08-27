extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name WallflowerAndStar

## @identity
## lineage: the graph taxonomy's rung 6 — a parquet dance floor. In the middle, the
##   star: one lamp holding twelve taut ribbons to twelve partners in a ring. In the
##   corner, the wallflower: one lamp, one ribbon, one friend. Their degrees are
##   inlaid at their feet in brass: 12, and 1.
## essence: degree is the first number a graph gives a node — how many edges meet you.
##   It is not worth: remove the star and twelve dances end; remove the wallflower and
##   one does, but the wallflower's single edge is still the whole of its world.
## truth: degree counts edges, not importance. Hubs are load-bearing; leaves are not
##   lesser, only lighter.
##
## The 2026-08-27 graph taxonomy (doc/GRAPHTHEORY_TAXONOMY.md), rung 6 of 13.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 44
@export var ring_r: float = 1.35

func _ready() -> void:
	_rng.seed = seed
	_build_floor()
	_build_star()
	_build_wallflower()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "ring_r"]:
		if config_data.has(key):
			set(key, config_data[key])

func _node_lamp(at: Vector3, tint: Color, r: float = 0.09) -> void:
	var post := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.02
	pm.bottom_radius = 0.03
	pm.height = at.y
	post.mesh = pm
	post.position = Vector3(at.x, at.y * 0.5, at.z)
	post.material_override = _matte_mat(Color(0.2, 0.19, 0.18), 0.85)
	add_child(post)
	var lamp := MeshInstance3D.new()
	var lm := SphereMesh.new()
	lm.radius = r
	lm.height = r * 2.0
	lamp.mesh = lm
	lamp.position = at
	lamp.material_override = _glow_mat(tint, 1.6)
	add_child(lamp)

func _ribbon(a: Vector3, b: Vector3, tint: Color) -> void:
	var e := MeshInstance3D.new()
	var em := CylinderMesh.new()
	em.top_radius = 0.011
	em.bottom_radius = 0.011
	em.height = a.distance_to(b)
	e.mesh = em
	e.position = (a + b) * 0.5
	var dir := (b - a).normalized()
	var axis := Vector3.UP.cross(dir)
	if axis.length() > 0.001:
		e.rotate(axis.normalized(), acos(clampf(Vector3.UP.dot(dir), -1.0, 1.0)))
	e.material_override = _glow_mat(tint, 0.6)
	add_child(e)

func _brass_number(at: Vector3, txt: String) -> void:
	var tag := TextScreenScript.new()
	tag.mode = 2
	tag.width_m = 0.16
	tag.position = at
	add_child(tag)
	if tag.has_method("set_text"):
		tag.set_text(txt, "degree")

func _build_floor() -> void:
	# parquet: alternating warm tiles
	for ix in range(8):
		for iz in range(6):
			var tile := MeshInstance3D.new()
			var tm := BoxMesh.new()
			tm.size = Vector3(0.55, 0.04, 0.55)
			tile.mesh = tm
			tile.position = Vector3(-1.95 + 0.56 * float(ix), 0.02, -1.4 + 0.56 * float(iz))
			var warm := 0.32 + 0.06 * float((ix + iz) % 2)
			tile.material_override = _matte_mat(Color(warm, warm * 0.72, warm * 0.45), 0.8)
			add_child(tile)

func _build_star() -> void:
	var c := Vector3(0.35, 1.15, 0.0)
	_node_lamp(c, Color(0.95, 0.8, 0.3), 0.12)
	for i in range(12):
		var ang := TAU * float(i) / 12.0
		var p := Vector3(0.35 + cos(ang) * ring_r, 0.95 + 0.12 * sin(float(i) * 2.1), sin(ang) * ring_r * 0.78)
		_node_lamp(p, Color.from_hsv(float(i) / 12.0, 0.45, 0.95), 0.06)
		_ribbon(c, p, Color(0.95, 0.8, 0.3))
	_brass_number(Vector3(0.35, 0.06, 0.35), "12")

func _build_wallflower() -> void:
	var w := Vector3(-1.75, 1.0, -1.15)
	var friend := Vector3(-1.15, 0.95, -0.75)
	_node_lamp(w, Color(0.55, 0.7, 0.95), 0.08)
	_node_lamp(friend, Color(0.55, 0.7, 0.95), 0.06)
	_ribbon(w, friend, Color(0.55, 0.7, 0.95))
	_brass_number(Vector3(-1.75, 0.06, -0.8), "1")

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "DegreePlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(1.7, 0.24, 1.2)
	ts.rotation.y = deg_to_rad(-38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("WALLFLOWER AND STAR",
			"Degree: how many edges meet you. The star holds twelve ribbons - remove it\nand twelve dances end. The wallflower holds one, no less connected for it:\nthat single edge is the whole of its world.")
