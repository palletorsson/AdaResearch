extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name GenerationsRoom

## @identity
## lineage: L-system generations room — a walk past five pedestals, gen 1 → gen 5
## essence: a room you traverse as a timeline; sprout at one end, full tree at the
##   other, the rewriting made into a corridor.
## truth: generation by generation, every symbol rewrites at once. The same finite
##   grammar yields unbounded form — depth, not length, is where the plant lives.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var generations: int = 5
@export var angle_deg: float = 23.0
@export var trunk_color: Color = Color(0.42, 0.30, 0.18)
@export var tip_color: Color = Color(0.50, 0.90, 0.40)


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
	var floor_mat := _matte_mat(Color(0.11, 0.12, 0.14), 0.92)
	add_child(_box(Vector3(0, -0.05, 0), Vector3(7, 0.1, 7), floor_mat))

	# --- five pedestals in a line, each a later generation ---
	var axiom := "X"
	var rules := {"X": "F+[[X]-X]-F[-FX]+X", "F": "FF"}
	var ped_mat := _steel_mat(Color(0.26, 0.27, 0.30))
	var glow_mat := _glow_mat(Color(0.12, 0.16, 0.22), 0.6)
	var span := 5.4
	for gi in range(generations):
		var iters := gi + 1
		var t := 0.0 if generations <= 1 else float(gi) / float(generations - 1)
		var x := lerpf(-span * 0.5, span * 0.5, t)
		# pedestal
		add_child(_cylinder(Vector3(x, 0.4, 0.0), 0.3, 0.8, ped_mat))
		add_child(_cylinder(Vector3(x, 0.82, 0.0), 0.34, 0.05, glow_mat))
		# the tree of this generation
		var walk: Dictionary = LST.walk(_expand(axiom, rules, iters), {
			"angle_deg": angle_deg, "step_len": 0.10, "step_shrink": 0.81,
			"base_width": 0.03, "width_shrink": 0.75, "seed": 3,
		})
		var plant: MultiMeshInstance3D = LST.to_tubes(walk, trunk_color, tip_color, 7)
		var sc := lerpf(0.7, 1.5, t)
		plant.position = Vector3(x, 0.84, 0.0)
		plant.scale = Vector3.ONE * sc
		plant.name = "Plant_%d" % iters
		add_child(plant)
		add_child(_billboard_label("GEN %d" % iters, Vector3(x, 0.66, 0.0), 26, Color(0.70, 0.92, 1.0)))

	# --- overhead label ---
	add_child(_billboard_label("GENERATION BY GENERATION", Vector3(0, 3.6, 0.0), 34, Color(0.88, 0.94, 1.0)))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	for gi in range(generations):
		var plant := get_node_or_null("Plant_%d" % (gi + 1))
		if plant:
			plant.rotation.y += delta * 0.1
