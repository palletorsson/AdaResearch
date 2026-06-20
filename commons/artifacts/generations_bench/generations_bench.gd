extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name GenerationsBench

## @identity
## lineage: L-system generations bench — the same grammar at iters 1,2,3,4 in a row
## essence: a bench that lays the growth out in space instead of time; four small
##   trees, each one rewrite-step further than its neighbour.
## truth: every symbol rewrites at once. Parallel rewriting is the engine of growth —
##   the plant doesn't grow tip-by-tip, the whole string is replaced each generation.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var max_iters: int = 4
@export var angle_deg: float = 22.5
@export var trunk_color: Color = Color(0.45, 0.32, 0.20)
@export var tip_color: Color = Color(0.45, 0.85, 0.35)


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
	# --- long bench base ---
	var base_mat := _matte_mat(Color(0.16, 0.17, 0.20), 0.85)
	add_child(_box(Vector3(0, 0.42, 0), Vector3(2.0, 0.2, 0.6), base_mat))
	var leg_mat := _steel_mat(Color(0.30, 0.31, 0.34))
	for sx in [-0.9, 0.9]:
		for sz in [-0.22, 0.22]:
			add_child(_cylinder(Vector3(sx, 0.21, sz), 0.03, 0.42, leg_mat))

	# --- four generations, side by side ---
	var axiom := "X"
	var rules := {"X": "F+[[X]-X]-F[-FX]+X", "F": "FF"}
	var xs := [-0.72, -0.24, 0.24, 0.72]
	var scales := [0.55, 0.6, 0.62, 0.62]
	for gi in range(max_iters):
		var iters := gi + 1
		var walk: Dictionary = LST.walk(_expand(axiom, rules, iters), {
			"angle_deg": angle_deg, "step_len": 0.085, "step_shrink": 0.80,
			"base_width": 0.016, "width_shrink": 0.74, "seed": 1,
		})
		var plant: MultiMeshInstance3D = LST.to_tubes(walk, trunk_color, tip_color, 6)
		# small platform under each
		var plat_mat := _glow_mat(Color(0.10, 0.13, 0.18), 0.5)
		add_child(_cylinder(Vector3(xs[gi], 0.53, 0.0), 0.12, 0.04, plat_mat))
		plant.position = Vector3(xs[gi], 0.55, 0.0)
		plant.scale = Vector3.ONE * float(scales[gi])
		plant.name = "Plant_%d" % iters
		add_child(plant)
		add_child(_billboard_label("gen %d" % iters, Vector3(xs[gi], 0.46, 0.0), 20, Color(0.70, 0.90, 1.0)))

	# --- title ---
	add_child(_billboard_label("EVERY SYMBOL REWRITES AT ONCE", Vector3(0, 1.6, 0.0), 28, Color(0.85, 0.92, 1.0)))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# gentle whole-bench sway of the row
	for gi in range(max_iters):
		var plant := get_node_or_null("Plant_%d" % (gi + 1))
		if plant:
			plant.rotation.y += delta * 0.2
