extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SubstrateSwitcher

## SubstrateSwitcher — Many substrates (the bridge), APPLIED tier.
##
## A device that cycles the SAME L-system string between render modes —
## lines -> tubes -> graph — every ~2s, with a mode readout. The string
## never changes; only the substrate the device chooses to grow it in.
##
## @identity
##   truth: "the grammar is the DNA, the material is a choice"
##   truth: "flip the switch — same string, new material"

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

@export var axiom: String = "F"
@export var rules: Dictionary = {"F": "FF-[-F+F+F]+[+F-F-F]"}
@export var iters: int = 3
@export var angle: float = 22.5
@export var c1: Color = Color(0.3, 0.2, 0.12)
@export var c2: Color = Color(0.5, 0.95, 0.75)
@export var cycle_seconds: float = 2.0

const MODES: Array[String] = ["LINES", "TUBES", "GRAPH"]

var _mode: int = 0
var _holder: Node3D = null
var _readout: Label3D = null
var _walk_cache: Dictionary = {}


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())
	if not Engine.is_editor_hint():
		var timer := Timer.new()
		timer.wait_time = cycle_seconds
		timer.autostart = true
		timer.one_shot = false
		timer.timeout.connect(_on_cycle)
		add_child(timer)


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("axiom"):
		axiom = String(config["axiom"])
	if config.has("iters"):
		iters = int(config["iters"])
	if config.has("angle"):
		angle = float(config["angle"])
	if config.has("c1"):
		c1 = _parse_color(config["c1"], c1)
	if config.has("c2"):
		c2 = _parse_color(config["c2"], c2)
	for child in get_children():
		child.queue_free()
	_build()


func _expand(p_axiom: String, p_rules: Dictionary, p_iters: int) -> String:
	var s := p_axiom
	for _i in range(p_iters):
		var out := ""
		for ch: String in s:
			out += String(p_rules.get(ch, ch))
		s = out
	return s


func _build() -> void:
	_walk_cache = LST.walk(_expand(axiom, rules, iters), {
		"angle_deg": angle, "step_len": 0.08, "step_shrink": 0.85,
		"base_width": 0.02, "width_shrink": 0.8, "seed": 1,
	})

	# --- device body ----------------------------------------------------------
	var body_mat := _matte_mat(Color(0.15, 0.16, 0.2), 0.6, 0.2)
	add_child(_box(Vector3(0.0, 0.1, 0.0), Vector3(0.6, 0.2, 0.6), body_mat))
	# bezel ring under the projection
	add_child(_cylinder(Vector3(0.0, 0.21, 0.0), 0.22, 0.02, _steel_mat(Color(0.35, 0.37, 0.4))))
	# status lamp
	add_child(_sphere(Vector3(0.22, 0.18, 0.22), 0.025, _glow_mat(c2, 2.0)))

	# --- projection holder (rebuilt on cycle) ---------------------------------
	_holder = Node3D.new()
	_holder.position = Vector3(0.0, 0.55, 0.0)
	_holder.scale = Vector3.ONE * 1.4
	add_child(_holder)

	# --- readout --------------------------------------------------------------
	_readout = _billboard_label("MODE: " + MODES[_mode], Vector3(0.0, 0.95, 0.0), 24, c2)
	add_child(_readout)
	add_child(_billboard_label("SUBSTRATE SWITCHER", Vector3(0.0, 1.2, 0.0), 30, c2))

	_render_mode()


func _render_mode() -> void:
	if _holder == null:
		return
	for child in _holder.get_children():
		child.queue_free()
	match _mode:
		0:
			var lines: MeshInstance3D = LST.to_lines(_walk_cache, c1, c2)
			_holder.add_child(lines)
		1:
			var tubes: MultiMeshInstance3D = LST.to_tubes(_walk_cache, c1, c2, 6)
			_holder.add_child(tubes)
		2:
			var g: Dictionary = LST.to_graph(_walk_cache)
			var node_mat := _glow_mat(c2, 1.4)
			var edge_mat := _matte_mat(c1)
			for p: Vector3 in g["positions"]:
				_holder.add_child(_sphere(p, 0.02, node_mat))
			for e: Array in g["edges"]:
				_holder.add_child(_cylinder_between(g["positions"][e[0]], g["positions"][e[1]], 0.006, edge_mat))
	if _readout != null:
		_readout.text = "MODE: " + MODES[_mode]


func _on_cycle() -> void:
	_mode = (_mode + 1) % MODES.size()
	_render_mode()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _holder != null:
		var t: float = Time.get_ticks_msec() / 1000.0
		_holder.rotation.y = t * 0.5
