extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name DragonRoom

## @identity
## lineage: Dragon & classic curves room — the Heighway dragon at room scale, glowing on
##   the floor, a labyrinth folded from FX.
## essence: stand inside the dragon. The single unbroken path that never crosses itself
##   becomes a place; you read its order by walking its turns.
## truth: depth, not chance. Eleven foldings of two rules tile the plane edge-to-edge.
##   What looks like a coastline of accidents is one law applied over and over.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var iterations: int = 11
@export var angle_deg: float = 90.0
@export var trunk_color: Color = Color(1.0, 0.40, 0.20)
@export var tip_color: Color = Color(1.0, 0.85, 0.35)


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _expand(axiom: String, rules: Dictionary, iters: int) -> String:
	var s := axiom
	for _i in range(iters):
		var out := ""
		for ch: String in s:
			out += String(rules.get(ch, ch))
		s = out
	return s


func _build() -> void:
	# --- room floor ---
	var floor_mat := _matte_mat(Color(0.09, 0.10, 0.12), 0.92)
	add_child(_box(Vector3(0, -0.05, 0), Vector3(7, 0.1, 7), floor_mat))

	# --- the big glowing dragon curve, laid flat on the floor ---
	var axiom := "FX"
	var rules := {"X": "X+YF+", "Y": "-FX-Y"}
	var walk: Dictionary = LST.walk(_expand(axiom, rules, iterations), {
		"angle_deg": angle_deg, "step_len": 0.05, "step_shrink": 1.0,
		"base_width": 0.02, "width_shrink": 1.0, "seed": 1,
	})
	var curve: MeshInstance3D = LST.to_lines(walk, trunk_color, tip_color)
	curve.rotation_degrees = Vector3(-90.0, 0.0, 0.0)  # X/Y plane -> floor
	curve.name = "Dragon"
	add_child(curve)
	_fit_floor_curve(curve, walk, 5.0, 0.06)

	# --- start / end beacons so the single unbroken path reads ---
	var segments: Array = walk["segments"]
	if not segments.is_empty():
		var start_mat := _glow_mat(Color(0.45, 1.0, 0.55), 1.0)
		var end_mat := _glow_mat(Color(1.0, 0.55, 0.45), 1.0)
		add_child(_sphere(_curve_world_point(curve, segments[0][0]), 0.12, start_mat))
		add_child(_sphere(_curve_world_point(curve, segments[segments.size() - 1][1]), 0.12, end_mat))

	# --- overhead label ---
	add_child(_billboard_label("THE DRAGON FOLDS FROM ONE RULE", Vector3(0, 3.6, 0.0), 34, Color(1.0, 0.88, 0.80)))


func _fit_floor_curve(curve: MeshInstance3D, walk: Dictionary, target_span: float, lift: float) -> void:
	var b := _bounds(walk)
	var span := maxf(b.size.x, b.size.y)
	var s := target_span / maxf(span, 0.001)
	curve.scale = Vector3.ONE * s
	var cx := (b.position.x + b.size.x * 0.5) * s
	var cy := (b.position.y + b.size.y * 0.5) * s
	# after -90° X rotation, local +Y -> world -Z, so centre by adding cy to Z.
	curve.position = Vector3(-cx, lift, cy)


func _curve_world_point(curve: MeshInstance3D, local: Vector3) -> Vector3:
	var s := curve.scale.x
	# local (x, y) under -90° X rotation -> world (x, 0, -y), then offset.
	return Vector3(curve.position.x + local.x * s, 0.10, curve.position.z - local.y * s)


func _bounds(walk: Dictionary) -> AABB:
	var segments: Array = walk["segments"]
	if segments.is_empty():
		return AABB(Vector3.ZERO, Vector3.ONE)
	var mn := Vector3(INF, INF, INF)
	var mx := Vector3(-INF, -INF, -INF)
	for seg: Array in segments:
		for k: int in [0, 1]:
			var p: Vector3 = seg[k]
			mn = Vector3(minf(mn.x, p.x), minf(mn.y, p.y), minf(mn.z, p.z))
			mx = Vector3(maxf(mx.x, p.x), maxf(mx.y, p.y), maxf(mx.z, p.z))
	return AABB(mn, mx - mn)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# room curve is static.
	pass
