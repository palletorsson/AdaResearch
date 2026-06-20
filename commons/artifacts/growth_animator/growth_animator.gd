extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name GrowthAnimator

## @identity
## lineage: L-system growth animator — a device that rebuilds the tree one generation
##   at a time, looping 1 -> 2 -> 3 -> 4 -> 1
## essence: an applied tool that performs the rewriting in front of you; a readout
##   shows the current generation, and every cycle the plant is re-grown.
## truth: parallel rewriting is the engine of growth — the string is replaced wholesale
##   each step, and the form that emerges was already implied by the rules.
##   Rebuild only on the timer, never per frame: the grammar is static between steps.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var min_iters: int = 1
@export var max_iters: int = 4
@export var step_seconds: float = 1.5
@export var angle_deg: float = 22.5
@export var trunk_color: Color = Color(0.45, 0.32, 0.20)
@export var tip_color: Color = Color(0.50, 0.90, 0.40)

var _current_iter: int = 1
var _timer: float = 0.0
var _readout: Label3D = null


func _ready() -> void:
	_rng.randomize()
	_current_iter = min_iters
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_current_iter = min_iters
	_timer = 0.0
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
	# --- ~1m device body ---
	var body_mat := _matte_mat(Color(0.14, 0.15, 0.19), 0.7, 0.1)
	add_child(_box(Vector3(0, 0.35, 0), Vector3(0.7, 0.7, 0.5), body_mat))
	# base plinth
	var plinth_mat := _steel_mat(Color(0.28, 0.29, 0.32))
	add_child(_box(Vector3(0, 0.04, 0), Vector3(0.8, 0.08, 0.6), plinth_mat))
	# growth chamber rim (tree grows out the top)
	var rim_mat := _glow_mat(Color(0.15, 0.35, 0.25), 0.7)
	add_child(_cylinder(Vector3(0, 0.71, 0), 0.18, 0.04, rim_mat))
	# status lamp
	add_child(_sphere(Vector3(0.28, 0.55, 0.26), 0.04, _glow_mat(Color(0.4, 1.0, 0.5), 1.4)))

	# --- readout panel ---
	var panel_mat := _glow_mat(Color(0.06, 0.10, 0.14), 0.8)
	add_child(_box(Vector3(0, 0.55, 0.26), Vector3(0.5, 0.22, 0.01), panel_mat))
	_readout = _billboard_label("GEN %d / %d" % [_current_iter, max_iters], Vector3(0, 0.55, 0.30), 24, Color(0.6, 1.0, 0.75))
	add_child(_readout)

	# --- the plant at the current generation ---
	_grow_plant()

	# --- label ---
	add_child(_billboard_label("GROWTH ANIMATOR", Vector3(0, 1.3, 0), 26, Color(0.85, 0.92, 1.0)))


func _grow_plant() -> void:
	var old := get_node_or_null("Plant")
	if old:
		remove_child(old)
		old.queue_free()
	var axiom := "X"
	var rules := {"X": "F+[[X]-X]-F[-FX]+X", "F": "FF"}
	var walk: Dictionary = LST.walk(_expand(axiom, rules, _current_iter), {
		"angle_deg": angle_deg, "step_len": 0.085, "step_shrink": 0.80,
		"base_width": 0.018, "width_shrink": 0.74, "seed": 1,
	})
	var plant: MultiMeshInstance3D = LST.to_tubes(walk, trunk_color, tip_color, 6)
	plant.position = Vector3(0, 0.73, 0)
	plant.scale = Vector3.ONE * 0.8
	plant.name = "Plant"
	add_child(plant)
	if _readout:
		_readout.text = "GEN %d / %d" % [_current_iter, max_iters]


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# rebuild ONLY on the timer, not per frame
	_timer += delta
	if _timer >= step_seconds:
		_timer = 0.0
		_current_iter += 1
		if _current_iter > max_iters:
			_current_iter = min_iters
		_grow_plant()
	# gentle sway between steps
	var plant := get_node_or_null("Plant")
	if plant:
		plant.rotation.y += delta * 0.3
