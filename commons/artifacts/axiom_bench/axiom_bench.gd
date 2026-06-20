extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name AxiomBench

## @identity
## lineage: L-system grammar bench — axiom + production rules → a plant
## essence: a workbench where the rules are written next to the plant they grow.
## truth: grammar is generative; the plant is in the rules, not the picture.
##   F+[[X]-X]-F[-FX]+X is the whole tree, folded. Parallel rewriting unfolds it.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var iterations: int = 4
@export var angle_deg: float = 22.5
@export var trunk_color: Color = Color(0.45, 0.32, 0.20)
@export var tip_color: Color = Color(0.45, 0.85, 0.35)
@export var panel_color: Color = Color(0.10, 0.12, 0.16)


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
	# --- bench base ---
	var base_mat := _matte_mat(Color(0.16, 0.17, 0.20), 0.85)
	add_child(_box(Vector3(0, 0.42, 0), Vector3(1.1, 0.2, 0.7), base_mat))
	# four short legs
	var leg_mat := _steel_mat(Color(0.30, 0.31, 0.34))
	for sx in [-0.45, 0.45]:
		for sz in [-0.27, 0.27]:
			add_child(_cylinder(Vector3(sx, 0.21, sz), 0.03, 0.42, leg_mat))
	# pillar holding the plant up to ~0.85 top
	var pillar_mat := _steel_mat(Color(0.34, 0.35, 0.38))
	add_child(_cylinder(Vector3(0, 0.66, 0.1), 0.05, 0.32, pillar_mat))
	add_child(_cylinder(Vector3(0, 0.84, 0.1), 0.09, 0.03, pillar_mat))

	# --- text panels: the axiom and the rules ---
	var panel_mat := _glow_mat(panel_color, 0.6)
	# left panel: AXIOM
	add_child(_box(Vector3(-0.40, 1.02, -0.20), Vector3(0.46, 0.30, 0.02), panel_mat))
	add_child(_billboard_label("AXIOM", Vector3(-0.40, 1.12, -0.18), 26, Color(0.55, 0.80, 1.0)))
	add_child(_billboard_label("X", Vector3(-0.40, 0.99, -0.18), 40, Color(0.90, 0.95, 1.0)))
	# right panel: RULES
	add_child(_box(Vector3(0.40, 1.02, -0.20), Vector3(0.56, 0.30, 0.02), panel_mat))
	add_child(_billboard_label("RULES", Vector3(0.40, 1.14, -0.18), 26, Color(0.55, 1.0, 0.70)))
	add_child(_billboard_label("X -> F+[[X]-X]-F[-FX]+X", Vector3(0.40, 1.04, -0.18), 16, Color(0.90, 0.95, 0.90)))
	add_child(_billboard_label("F -> FF", Vector3(0.40, 0.94, -0.18), 18, Color(0.90, 0.95, 0.90)))

	# --- the plant the rules grow, on top ---
	var axiom := "X"
	var rules := {"X": "F+[[X]-X]-F[-FX]+X", "F": "FF"}
	var walk: Dictionary = LST.walk(_expand(axiom, rules, iterations), {
		"angle_deg": angle_deg, "step_len": 0.085, "step_shrink": 0.80,
		"base_width": 0.018, "width_shrink": 0.74, "seed": 1,
	})
	var plant: MultiMeshInstance3D = LST.to_tubes(walk, trunk_color, tip_color, 6)
	plant.position = Vector3(0, 0.86, 0.1)
	plant.scale = Vector3.ONE * 0.85
	plant.name = "Plant"
	add_child(plant)

	# --- title label ---
	add_child(_billboard_label("AXIOM + RULES -> a plant", Vector3(0, 1.6, 0.1), 28, Color(0.85, 0.92, 1.0)))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var plant := get_node_or_null("Plant")
	if plant:
		plant.rotation.y += delta * 0.25
