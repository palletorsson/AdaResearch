extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name AxiomRoom

## @identity
## lineage: L-system grammar room — production rules as the architecture
## essence: a room you walk into to stand inside a grammar; the rules are the walls,
##   the plant they grow is the centrepiece.
## truth: the plant is in the rules, not the picture. A few lines of rewriting hold
##   an entire tree. Parallel rewriting (every symbol at once) is the engine.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var iterations: int = 5
@export var angle_deg: float = 23.0
@export var trunk_color: Color = Color(0.42, 0.30, 0.18)
@export var tip_color: Color = Color(0.50, 0.90, 0.40)
@export var wall_color: Color = Color(0.08, 0.10, 0.14)


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

	# --- production rules as giant glowing wall panels ---
	var panel_mat := _glow_mat(wall_color, 0.7)
	# back wall: the rules
	add_child(_box(Vector3(0, 2.2, -3.4), Vector3(6.4, 4.2, 0.15), panel_mat))
	add_child(_billboard_label("AXIOM", Vector3(-2.0, 3.7, -3.3), 40, Color(0.55, 0.80, 1.0)))
	add_child(_billboard_label("X", Vector3(-2.0, 3.1, -3.3), 70, Color(0.92, 0.96, 1.0)))
	add_child(_billboard_label("RULES", Vector3(1.2, 3.7, -3.3), 40, Color(0.55, 1.0, 0.70)))
	add_child(_billboard_label("X -> F+[[X]-X]-F[-FX]+X", Vector3(1.2, 3.1, -3.3), 30, Color(0.90, 0.96, 0.90)))
	add_child(_billboard_label("F -> FF", Vector3(1.2, 2.5, -3.3), 34, Color(0.90, 0.96, 0.90)))

	# left wall panel
	add_child(_box(Vector3(-3.4, 2.2, 0), Vector3(0.15, 4.2, 6.4), panel_mat))
	add_child(_billboard_label("+  -   yaw left / right", Vector3(-3.3, 3.0, 0.6), 26, Color(0.80, 0.85, 0.95)))
	add_child(_billboard_label("[  ]   push / pop branch", Vector3(-3.3, 2.4, 0.6), 26, Color(0.80, 0.85, 0.95)))
	# right wall panel
	add_child(_box(Vector3(3.4, 2.2, 0), Vector3(0.15, 4.2, 6.4), panel_mat))
	add_child(_billboard_label("F   draw forward", Vector3(3.3, 3.0, -0.6), 26, Color(0.80, 0.85, 0.95)))
	add_child(_billboard_label("rewrite, then walk", Vector3(3.3, 2.4, -0.6), 26, Color(0.80, 0.85, 0.95)))

	# --- tall tree grown from the rules, in the centre ---
	var axiom := "X"
	var rules := {"X": "F+[[X]-X]-F[-FX]+X", "F": "FF"}
	var walk: Dictionary = LST.walk(_expand(axiom, rules, iterations), {
		"angle_deg": angle_deg, "step_len": 0.11, "step_shrink": 0.82,
		"base_width": 0.04, "width_shrink": 0.76, "seed": 3,
	})
	var plant: MultiMeshInstance3D = LST.to_tubes(walk, trunk_color, tip_color, 8)
	plant.position = Vector3(0, 0.0, 0.3)
	plant.scale = Vector3.ONE * 2.4
	plant.name = "Plant"
	add_child(plant)

	# --- overhead label ---
	add_child(_billboard_label("THE PLANT IS IN THE RULES, NOT THE PICTURE", Vector3(0, 3.6, 0), 34, Color(0.88, 0.94, 1.0)))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var plant := get_node_or_null("Plant")
	if plant:
		plant.rotation.y += delta * 0.12
