extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ParametricDesigner

## @identity
## title: Parametric L-systems
## truth: "hang numbers on the symbols and the grammar can taper and grow old"
##
## APPLIED: a small device that re-grows the SAME grammar with different numbers
## every couple of seconds — sweeping the branch angle and the iteration count.
## Each rebuild is a different parametric variant of one plant: turn the dials,
## get a new tree. Nothing animates per frame; only the timer rebuilds the plant.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

@export var step_len: float = 0.06
@export var base_col: Color = Color(0.42, 0.28, 0.17)
@export var tip_col: Color = Color(0.55, 0.85, 0.40)
@export var cycle_seconds: float = 2.0

var _plant_root: Node3D = null
var _readout: Label3D = null
var _timer: Timer = null
var _variant: int = 0

# parametric sweep — (angle_deg, iterations)
const _VARIANTS: Array = [
	[18.0, 4],
	[25.0, 5],
	[33.0, 4],
	[28.0, 6],
	[20.0, 5],
	[40.0, 4],
]


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("step_len"):
		step_len = float(config["step_len"])
	if config.has("base_col"):
		base_col = _parse_color(config["base_col"], base_col)
	if config.has("tip_col"):
		tip_col = _parse_color(config["tip_col"], tip_col)
	if config.has("cycle_seconds"):
		cycle_seconds = float(config["cycle_seconds"])
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
	# ~1m device: base box + pillar + planter
	add_child(_box(Vector3(0, 0.05, 0), Vector3(0.6, 0.10, 0.6), _matte_mat(Color(0.15, 0.16, 0.19), 0.9)))
	add_child(_cylinder(Vector3(0, 0.40, 0), 0.05, 0.60, _steel_mat(Color(0.55, 0.57, 0.62))))
	add_child(_cylinder(Vector3(0, 0.72, 0), 0.12, 0.08, _matte_mat(Color(0.28, 0.21, 0.15), 0.85)))

	# a glowing console strip — this is the designer panel
	add_child(_box(Vector3(0, 0.30, 0.31), Vector3(0.40, 0.18, 0.02), _glow_mat(Color(0.20, 0.45, 0.65), 0.8)))

	# rebuildable plant
	_plant_root = Node3D.new()
	_plant_root.position = Vector3(0, 0.76, 0)
	add_child(_plant_root)

	# label + live readout
	add_child(_billboard_label("PARAMETRIC DESIGNER", Vector3(0, 1.4, 0), 36, Color(0.75, 0.90, 0.95)))
	_readout = _billboard_label("", Vector3(0, 1.18, 0), 24, Color(0.95, 0.85, 0.45))
	add_child(_readout)

	_grow_variant()

	# timer drives the sweep — rebuild only, no per-frame regen
	if not Engine.is_editor_hint():
		_timer = Timer.new()
		_timer.wait_time = maxf(cycle_seconds, 0.5)
		_timer.autostart = true
		_timer.one_shot = false
		_timer.timeout.connect(_on_cycle)
		add_child(_timer)


func _on_cycle() -> void:
	_variant = (_variant + 1) % _VARIANTS.size()
	_grow_variant()


func _grow_variant() -> void:
	if _plant_root == null:
		return
	for c in _plant_root.get_children():
		c.queue_free()
	var v: Array = _VARIANTS[_variant]
	var angle_deg: float = float(v[0])
	var iters: int = int(v[1])
	var rules := {
		"X": "F+[[X]-X]-F[-FX]+X",
		"F": "FF",
	}
	var s := _expand("X", rules, iters)
	var walk: Dictionary = LST.walk(s, {
		"angle_deg": angle_deg,
		"step_len": step_len,
		"step_shrink": 0.78,
		"base_width": 0.022,
		"width_shrink": 0.66,
		"seed": 1,
	})
	var plant: MultiMeshInstance3D = LST.to_tubes(walk, base_col, tip_col, 6)
	_plant_root.add_child(plant)
	if _readout != null:
		_readout.text = "angle %d°   iters %d" % [int(angle_deg), iters]


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# gentle idle spin of the planter so variants read from all sides
	if _plant_root != null:
		_plant_root.rotation.y += delta * 0.4
