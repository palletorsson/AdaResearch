extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name HilbertRoom

## @identity
## lineage: 3D Hilbert curve — Hilbert's space-filling thread lifted out of the plane into the cube
## essence: the same one-line trick, now folding through volume; pitch and roll join yaw so the path fills a box
## truth: "ONE LINE, EVERY POINT" — a single continuous curve passes arbitrarily close to every point of 3-space
##
## LARGE tier. A room-scale 3D Hilbert curve you can walk around (~3m), rendered as
## tubes (one MultiMesh, one draw call). The 3D Hilbert grammar uses &^/\ alongside +/-.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

@export var iters: int = 2
@export var cube_size: float = 3.0
@export var trunk_color: Color = Color(0.20, 0.75, 0.95)
@export var tip_color: Color = Color(0.95, 0.85, 0.30)
@export var floor_color: Color = Color(0.10, 0.11, 0.13)


func _expand(axiom: String, rules: Dictionary, iter_count: int) -> String:
	var s := axiom
	for _i in range(iter_count):
		var out := ""
		for ch: String in s:
			out += String(rules.get(ch, ch))
		s = out
	return s


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("iters"):
		iters = int(config["iters"])
	if config.has("cube_size"):
		cube_size = float(config["cube_size"])
	if config.has("trunk_color"):
		trunk_color = _parse_color(config["trunk_color"], trunk_color)
	if config.has("tip_color"):
		tip_color = _parse_color(config["tip_color"], tip_color)
	for c in get_children():
		c.queue_free()
	_build()


func _build() -> void:
	# Room floor.
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(7.0, 0.1, 7.0), _matte_mat(floor_color, 0.7)))

	# 3D Hilbert curve grammar (Hilbert curve in 3 dimensions). Only F draws.
	# X is the recursive non-terminal; ^& pitch, +- yaw, /\ roll — all 3 axes engaged
	# so the single thread folds through volume, not just a plane.
	var axiom := "X"
	var rules := {
		"X": "^\\XF^\\XFX-F^//XFX&F+//XFX-F/X-/",
	}
	var grammar := _expand(axiom, rules, iters)
	var walk: Dictionary = LST.walk(grammar, {
		"angle_deg": 90.0,
		"step_len": 0.5,
		"step_shrink": 1.0,
		"base_width": 0.06,
		"width_shrink": 1.0,
		"seed": 1,
	})

	var curve: MultiMeshInstance3D = LST.to_tubes(walk, trunk_color, tip_color, 6)
	# Normalise the curve's natural span to cube_size and centre it in the room.
	var raw: float = 0.5 * float(pow(2, iters))
	var s: float = cube_size / maxf(raw, 0.001)
	curve.scale = Vector3.ONE * s
	# Lift so the curve sits centred ~1.4m above the floor (walk-around height).
	var half := cube_size * 0.5
	curve.position = Vector3(-half, 0.4, -half)
	add_child(curve)

	# Bounding cube wireframe (edges) so the "box being filled" reads clearly.
	_add_wire_cube(Vector3(0.0, 0.4 + half, 0.0), cube_size, _glow_mat(Color(0.4, 0.45, 0.5), 0.6))

	add_child(_billboard_label("ONE LINE, EVERY POINT", Vector3(0.0, 3.6, 0.0), 48, trunk_color))


func _add_wire_cube(center: Vector3, size: float, mat: Material) -> void:
	var h := size * 0.5
	var r := 0.01
	var corners: Array = []
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				corners.append(center + Vector3(float(sx) * h, float(sy) * h, float(sz) * h))
	var edges := [
		[0, 1], [0, 2], [0, 4], [1, 3], [1, 5], [2, 3],
		[2, 6], [3, 7], [4, 5], [4, 6], [5, 7], [6, 7],
	]
	for e: Array in edges:
		add_child(_cylinder_between(corners[e[0]], corners[e[1]], r, mat))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	pass
