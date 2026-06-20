extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ContextToy

## @identity
## title: Context-sensitive L-systems
## truth: "let a symbol read its neighbours and the plant answers its world"
##
## A held context-sensitive plant, ~0.4m. A bright pulse of signal travels up the
## stem — each segment lights when the signal "reaches" it, exactly the way a
## context-sensitive rule fires only when its neighbour is in the right state.
## The plant is static; only the travelling signal moves.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

@export var angle: float = 25.0
@export var iterations: int = 4
@export var base_col: Color = Color(0.30, 0.40, 0.22)
@export var tip_col: Color = Color(0.45, 0.70, 0.35)
@export var signal_col: Color = Color(1.0, 0.85, 0.30)
@export var signal_speed: float = 0.5

var _signal: MeshInstance3D = null
var _path: PackedVector3Array = PackedVector3Array()
var _phase: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("angle"):
		angle = float(config["angle"])
	if config.has("iterations"):
		iterations = int(config["iterations"])
	if config.has("base_col"):
		base_col = _parse_color(config["base_col"], base_col)
	if config.has("tip_col"):
		tip_col = _parse_color(config["tip_col"], tip_col)
	if config.has("signal_col"):
		signal_col = _parse_color(config["signal_col"], signal_col)
	for c in get_children():
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
	# held, near origin — small stem, no table
	var rules := {
		"X": "F[+X][-X]FX",
		"F": "FF",
	}
	var s := _expand("X", rules, iterations)
	var walk: Dictionary = LST.walk(s, {
		"angle_deg": angle,
		"step_len": 0.05,
		"step_shrink": 0.80,
		"base_width": 0.012,
		"width_shrink": 0.72,
		"seed": 2,
	})
	var plant: MultiMeshInstance3D = LST.to_tubes(walk, base_col, tip_col, 5)
	add_child(plant)

	# build a spine path (the main stem) for the signal to climb — the "neighbours"
	_path = _trunk_path(walk)

	# the travelling signal: a bright bead = a symbol reading the segment below it
	_signal = _sphere(Vector3.ZERO, 0.02, _glow_mat(signal_col, 3.0))
	if _path.size() > 0:
		_signal.position = _path[0]
	add_child(_signal)

	add_child(_billboard_label("READ YOUR NEIGHBOUR", Vector3(0, 0.42, 0), 18, signal_col))


func _trunk_path(walk: Dictionary) -> PackedVector3Array:
	# follow segments at the lowest depth — the main stem the signal travels.
	var segs: Array = walk.get("segments", [])
	var pts := PackedVector3Array()
	for seg: Array in segs:
		if int(seg[2]) == 0:
			if pts.is_empty():
				pts.append(seg[0])
			pts.append(seg[1])
	if pts.is_empty() and segs.size() > 0:
		pts.append(segs[0][0])
		pts.append(segs[0][1])
	return pts


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _signal == null or _path.size() < 2:
		return
	_phase += delta * signal_speed
	if _phase >= 1.0:
		_phase = 0.0
	# walk the signal along the trunk path; brighten as it nears the tip
	var span: int = _path.size() - 1
	var f: float = _phase * float(span)
	var idx: int = int(f)
	var frac: float = f - float(idx)
	idx = clampi(idx, 0, span - 1)
	_signal.position = _path[idx].lerp(_path[idx + 1], frac)
	var pulse: float = 2.0 + 2.5 * (0.5 + 0.5 * sin(_phase * TAU))
	var mat := _signal.material_override as StandardMaterial3D
	if mat != null:
		mat.emission_energy_multiplier = pulse if emissive else pulse * 0.4
