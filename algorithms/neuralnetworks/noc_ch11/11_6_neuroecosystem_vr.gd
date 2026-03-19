# ===========================================================================
# NOC Example 11.6: Neuroecosystem — Evolving Creatures with Visible Brains
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing -> GDScript, 2025
#
# Elevated: real LayeredBrain per creature, mini network graph on alpha,
# sensor activation color on bodies, fitness-per-generation graph,
# creature genealogy tree showing lineage, VR sliders for all params.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 11.6: Neuroecosystem — Visible Neural Networks on Creatures
## Evolving creatures with brains you can see, sensor heatmaps, fitness graph, genealogy
## Chapter 11: Neural Networks

# -- Constants ---------------------------------------------------------------
const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_CREATURE := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_FOOD := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_secondary.tres")

const MIN_Y := 0.05
const MAX_Y := 0.95
const MIN_X := -0.45
const MAX_X := 0.45
const MIN_Z := -0.45
const MAX_Z := 0.45

# NN architecture: 5 inputs -> 4 hidden -> 2 outputs
const NN_INPUTS: int = 5
const NN_HIDDEN: int = 4
const NN_OUTPUTS: int = 2

# Colors
const COL_NEURON_OFF := Color(0.15, 0.18, 0.25)
const COL_NEURON_ON := Color(0.3, 0.95, 0.85)
const COL_WEIGHT_POS := Color(0.3, 0.85, 0.5, 0.6)
const COL_WEIGHT_NEG := Color(0.95, 0.3, 0.4, 0.6)
const COL_OUTPUT_HIGH := Color(1.0, 0.85, 0.2)
const COL_OUTPUT_LOW := Color(0.25, 0.3, 0.4)
const COL_GRAPH_LINE := Color(0.35, 0.85, 0.95, 0.8)
const COL_GRAPH_BEST := Color(1.0, 0.6, 0.2, 0.8)
const COL_GRAPH_BG := Color(0.1, 0.12, 0.16, 0.6)
const COL_LABEL := Color(0.92, 0.92, 0.96)
const COL_DIM := Color(0.5, 0.5, 0.55)
const COL_ALIVE := Color(0.3, 0.9, 0.5)
const COL_DEAD := Color(0.4, 0.15, 0.15, 0.3)
const COL_GENE_LINE := Color(0.7, 0.4, 0.95, 0.7)
const COL_GENE_NODE := Color(0.85, 0.55, 1.0)
const COL_GENE_ALPHA := Color(1.0, 0.95, 0.3)

# -- Tunable parameters -----------------------------------------------------
@export var population_size: int = 20
@export var mutation_rate: float = 0.08
@export var food_spawn_interval: float = 2.0
@export var food_radius: float = 0.05
@export var max_speed: float = 0.6
@export var sensor_range: float = 0.4

# -- State -------------------------------------------------------------------
var _sim_root: Node3D
var _creatures: Array = []
var _foods: Array[FoodItem] = []
var _spawn_timer: float = 0.0
var _generation: int = 1
var _best_fitness: float = 0.0
var _best_ever_fitness: float = 0.0
var _alpha_idx: int = 0

# Fitness history
var _fitness_history: Array[float] = []
const MAX_HISTORY: int = 50

# Genealogy: per-generation best creature lineage
var _genealogy: Array[Dictionary] = []  # [{gen, fitness, parent_idx}]
const MAX_GENEALOGY: int = 12

# -- Visual nodes ------------------------------------------------------------
var _creature_mm: MultiMesh
var _creature_mmi: MultiMeshInstance3D

# Network graph (drawn for alpha creature)
var _nn_im: ImmediateMesh
var _nn_mi: MeshInstance3D

# Fitness graph
var _graph_im: ImmediateMesh
var _graph_mi: MeshInstance3D

# Genealogy tree
var _gene_im: ImmediateMesh
var _gene_mi: MeshInstance3D

# Sensor lines (from alpha to sensed objects)
var _sensor_im: ImmediateMesh
var _sensor_mi: MeshInstance3D

# Shared unshaded material
var _mat: StandardMaterial3D

# Labels
var _title_label: Label3D
var _gen_label: Label3D
var _alive_label: Label3D
var _fitness_label: Label3D
var _nn_title_label: Label3D
var _graph_title_label: Label3D
var _gene_title_label: Label3D

# Controllers
var _mutation_ctrl: Node
var _food_ctrl: Node
var _speed_ctrl: Node
var _sensor_ctrl: Node

# ── Ready ──────────────────────────────────────────────────────────────
func _ready() -> void:
	randomize()
	_create_material()
	_setup_environment()
	_create_creature_multimesh()
	_create_meshes()
	_create_labels()
	_create_controllers()
	_spawn_population()
	_spawn_timer = food_spawn_interval

func _create_material() -> void:
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.vertex_color_use_as_albedo = true
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	_sim_root.name = "SimulationRoot"
	add_child(_sim_root)

func _create_creature_multimesh() -> void:
	_creature_mm = MultiMesh.new()
	_creature_mm.transform_format = MultiMesh.TRANSFORM_3D
	_creature_mm.use_colors = true
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.035
	capsule.height = 0.09
	capsule.radial_segments = 8
	capsule.rings = 2
	_creature_mm.mesh = capsule
	_creature_mm.instance_count = population_size

	_creature_mmi = MultiMeshInstance3D.new()
	_creature_mmi.multimesh = _creature_mm
	_creature_mmi.material_override = MAT_CREATURE
	_sim_root.add_child(_creature_mmi)

func _create_meshes() -> void:
	# Neural network graph (right side)
	_nn_im = ImmediateMesh.new()
	_nn_mi = MeshInstance3D.new()
	_nn_mi.mesh = _nn_im
	_nn_mi.material_override = _mat
	_nn_mi.position = Vector3(0.58, 0.15, 0.0)
	add_child(_nn_mi)

	# Fitness graph (bottom left)
	_graph_im = ImmediateMesh.new()
	_graph_mi = MeshInstance3D.new()
	_graph_mi.mesh = _graph_im
	_graph_mi.material_override = _mat
	_graph_mi.position = Vector3(-0.35, -0.15, 0.0)
	add_child(_graph_mi)

	# Genealogy tree (bottom right)
	_gene_im = ImmediateMesh.new()
	_gene_mi = MeshInstance3D.new()
	_gene_mi.mesh = _gene_im
	_gene_mi.material_override = _mat
	_gene_mi.position = Vector3(0.15, -0.15, 0.0)
	add_child(_gene_mi)

	# Sensor lines (in sim space)
	_sensor_im = ImmediateMesh.new()
	_sensor_mi = MeshInstance3D.new()
	_sensor_mi.mesh = _sensor_im
	_sensor_mi.material_override = _mat
	_sim_root.add_child(_sensor_mi)

func _create_labels() -> void:
	_title_label = _make_label(Vector3(-0.05, 0.82, 0.0), 22)
	_title_label.text = "Neuroecosystem — Visible Neural Brains"
	_title_label.modulate = COL_LABEL

	_gen_label = _make_label(Vector3(-0.35, 0.76, 0.0), 18)
	_gen_label.modulate = COL_GRAPH_BEST

	_alive_label = _make_label(Vector3(-0.05, 0.76, 0.0), 18)
	_alive_label.modulate = COL_ALIVE

	_fitness_label = _make_label(Vector3(0.25, 0.76, 0.0), 18)
	_fitness_label.modulate = COL_GRAPH_LINE

	_nn_title_label = _make_label(Vector3(0.58, 0.62, 0.0), 14)
	_nn_title_label.text = "Alpha Brain"
	_nn_title_label.modulate = COL_DIM

	_graph_title_label = _make_label(Vector3(-0.35, -0.07, 0.0), 12)
	_graph_title_label.text = "Fitness / Generation"
	_graph_title_label.modulate = COL_DIM

	_gene_title_label = _make_label(Vector3(0.15, -0.07, 0.0), 12)
	_gene_title_label.text = "Genealogy"
	_gene_title_label.modulate = COL_DIM

func _make_label(pos: Vector3, size: int) -> Label3D:
	var lbl := Label3D.new()
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.font_size = size
	lbl.outline_size = 4
	lbl.position = pos
	add_child(lbl)
	return lbl

func _create_controllers() -> void:
	var controller_root := Node3D.new()
	controller_root.name = "Controllers"
	controller_root.position = Vector3(0.85, 0.45, 0.0)
	add_child(controller_root)

	_mutation_ctrl = CONTROLLER_SCENE.instantiate()
	_mutation_ctrl.parameter_name = "Mutation"
	_mutation_ctrl.min_value = 0.01
	_mutation_ctrl.max_value = 0.3
	_mutation_ctrl.default_value = mutation_rate
	_mutation_ctrl.step_size = 0.01
	_mutation_ctrl.position = Vector3(0, 0.15, 0)
	_mutation_ctrl.rotation_degrees = Vector3(0, 90, 0)
	controller_root.add_child(_mutation_ctrl)
	_mutation_ctrl.value_changed.connect(func(v: float) -> void: mutation_rate = v)
	_mutation_ctrl.set_value(mutation_rate)

	_food_ctrl = CONTROLLER_SCENE.instantiate()
	_food_ctrl.parameter_name = "Food Rate"
	_food_ctrl.min_value = 0.5
	_food_ctrl.max_value = 5.0
	_food_ctrl.default_value = food_spawn_interval
	_food_ctrl.step_size = 0.1
	_food_ctrl.position = Vector3(0, -0.05, 0)
	_food_ctrl.rotation_degrees = Vector3(0, 90, 0)
	controller_root.add_child(_food_ctrl)
	_food_ctrl.value_changed.connect(func(v: float) -> void: food_spawn_interval = v)
	_food_ctrl.set_value(food_spawn_interval)

	_speed_ctrl = CONTROLLER_SCENE.instantiate()
	_speed_ctrl.parameter_name = "Max Speed"
	_speed_ctrl.min_value = 0.2
	_speed_ctrl.max_value = 1.5
	_speed_ctrl.default_value = max_speed
	_speed_ctrl.step_size = 0.05
	_speed_ctrl.position = Vector3(0, -0.25, 0)
	_speed_ctrl.rotation_degrees = Vector3(0, 90, 0)
	controller_root.add_child(_speed_ctrl)
	_speed_ctrl.value_changed.connect(func(v: float) -> void: max_speed = v)
	_speed_ctrl.set_value(max_speed)

	_sensor_ctrl = CONTROLLER_SCENE.instantiate()
	_sensor_ctrl.parameter_name = "Sensor Range"
	_sensor_ctrl.min_value = 0.1
	_sensor_ctrl.max_value = 0.8
	_sensor_ctrl.default_value = sensor_range
	_sensor_ctrl.step_size = 0.05
	_sensor_ctrl.position = Vector3(0, -0.45, 0)
	_sensor_ctrl.rotation_degrees = Vector3(0, 90, 0)
	controller_root.add_child(_sensor_ctrl)
	_sensor_ctrl.value_changed.connect(func(v: float) -> void: sensor_range = v)
	_sensor_ctrl.set_value(sensor_range)

# ── Spawning ───────────────────────────────────────────────────────────
func _spawn_population() -> void:
	for c in _creatures:
		if c is EcoCreature:
			c.queue_free()
	_creatures.clear()

	for i in population_size:
		var creature := EcoCreature.new()
		creature.idx = i
		creature.init(_sim_root)
		creature.pos = Vector3(
			randf_range(MIN_X + 0.1, MAX_X - 0.1),
			randf_range(MIN_Y + 0.1, MAX_Y - 0.1),
			randf_range(MIN_Z + 0.1, MAX_Z - 0.1)
		)
		creature.tint = Color.from_hsv(fmod(float(i) / float(population_size) * 0.7 + 0.75, 1.0), 0.65, 0.9)
		_creatures.append(creature)

	if _creature_mm.instance_count != population_size:
		_creature_mm.instance_count = population_size

	_alpha_idx = 0
	_best_fitness = 0.0
	_spawn_timer = food_spawn_interval

func _spawn_food() -> void:
	var food := FoodItem.new()
	food.init(_sim_root, food_radius)
	food.pos = Vector3(
		randf_range(MIN_X + 0.05, MAX_X - 0.05),
		randf_range(MIN_Y + 0.05, MAX_Y - 0.05),
		randf_range(MIN_Z + 0.05, MAX_Z - 0.05)
	)
	_foods.append(food)

# ── Physics process ────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	# Spawn food
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_food()
		_spawn_timer = food_spawn_interval

	# Update creatures
	var alive_count := 0
	var best_local := 0.0
	var best_idx := 0

	for creature in _creatures:
		if creature.energy <= 0.0:
			continue
		alive_count += 1

		# Compute sensor inputs
		creature.sense(_foods, _creatures, sensor_range)
		creature.update(delta, max_speed)

		# Clamp position
		creature.pos = Vector3(
			clampf(creature.pos.x, MIN_X, MAX_X),
			clampf(creature.pos.y, MIN_Y, MAX_Y),
			clampf(creature.pos.z, MIN_Z, MAX_Z)
		)

		# Eat food
		for food in _foods:
			if food.consumed:
				continue
			if creature.pos.distance_to(food.pos) < food.radius + 0.04:
				creature.energy += food.energy_value
				creature.food_eaten += 1
				food.mark_consumed()

		creature.energy -= delta * 0.4
		if creature.energy <= 0.0:
			creature.energy = 0.0

		if creature.fitness() > best_local:
			best_local = creature.fitness()
			best_idx = creature.idx

	# Remove consumed food
	for food in _foods.duplicate():
		if food.consumed:
			food.queue_free()
			_foods.erase(food)

	# Pulse remaining food
	for food in _foods:
		food.pulse(delta)

	_best_fitness = maxf(_best_fitness, best_local)
	_best_ever_fitness = maxf(_best_ever_fitness, _best_fitness)
	_alpha_idx = best_idx

	# All dead -> next generation
	if alive_count == 0:
		_next_generation()

	# Update visuals
	_update_creature_multimesh()
	_rebuild_nn_graph()
	_rebuild_fitness_graph()
	_rebuild_genealogy()
	_draw_sensor_lines()
	_update_labels(alive_count)

# ── Next generation ────────────────────────────────────────────────────
func _next_generation() -> void:
	# Record fitness history
	_fitness_history.append(_best_fitness)
	if _fitness_history.size() > MAX_HISTORY:
		_fitness_history.remove_at(0)

	# Record genealogy for alpha
	var alpha: EcoCreature = null
	for c in _creatures:
		if c.idx == _alpha_idx:
			alpha = c
			break
	if alpha:
		_genealogy.append({
			"gen": _generation,
			"fitness": alpha.fitness(),
			"parent_idx": alpha.parent_idx,
			"food_eaten": alpha.food_eaten
		})
		if _genealogy.size() > MAX_GENEALOGY:
			_genealogy.remove_at(0)

	# Build mating pool (fitness-proportionate)
	var mating_pool: Array = []
	for creature in _creatures:
		var tickets := int(creature.fitness() * 10.0) + 1
		for j in tickets:
			mating_pool.append(creature)

	if mating_pool.is_empty():
		mating_pool = _creatures.duplicate()

	# Clear food
	for food in _foods:
		food.queue_free()
	_foods.clear()

	# Create offspring
	var new_creatures: Array = []
	for i in population_size:
		var parent: EcoCreature = mating_pool[randi() % mating_pool.size()]
		var offspring := EcoCreature.new()
		offspring.idx = i
		offspring.parent_idx = parent.idx
		offspring.init(_sim_root)
		offspring.pos = Vector3(
			randf_range(MIN_X + 0.1, MAX_X - 0.1),
			randf_range(MIN_Y + 0.1, MAX_Y - 0.1),
			randf_range(MIN_Z + 0.1, MAX_Z - 0.1)
		)
		offspring.tint = Color.from_hsv(fmod(float(i) / float(population_size) * 0.7 + 0.75, 1.0), 0.65, 0.9)
		offspring.brain.copy_from(parent.brain)
		offspring.brain.mutate(mutation_rate)
		new_creatures.append(offspring)

	# Free old creatures
	for c in _creatures:
		c.queue_free()
	_creatures = new_creatures

	if _creature_mm.instance_count != population_size:
		_creature_mm.instance_count = population_size

	_generation += 1
	_best_fitness = 0.0
	_alpha_idx = 0
	_spawn_timer = food_spawn_interval

# ── MultiMesh update ──────────────────────────────────────────────────
func _update_creature_multimesh() -> void:
	for i in range(mini(_creatures.size(), _creature_mm.instance_count)):
		var creature: EcoCreature = _creatures[i]
		var t := Transform3D.IDENTITY
		if creature.energy > 0.0:
			t.origin = creature.pos
			# Orient capsule sideways along velocity
			if creature.velocity.length() > 0.01:
				var dir := creature.velocity.normalized()
				t = t.looking_at(creature.pos + dir, Vector3.UP)
			# Color based on sensor activation intensity
			var activation := creature.activation_intensity()
			var col := creature.tint.lerp(COL_NEURON_ON, clampf(activation, 0.0, 0.6))
			if i == _alpha_idx:
				col = COL_GENE_ALPHA
			_creature_mm.set_instance_color(i, col)
		else:
			t.origin = Vector3(0.0, -10.0, 0.0)
			_creature_mm.set_instance_color(i, COL_DEAD)
		_creature_mm.set_instance_transform(i, t)

# ── Neural network graph (alpha creature's brain) ─────────────────────
func _rebuild_nn_graph() -> void:
	_nn_im.clear_surfaces()
	_nn_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	# Layout: 3 columns — inputs | hidden | outputs
	var layer_x := [0.0, 0.12, 0.24]
	var node_r := 0.011
	var nn_h := 0.42

	# Get alpha's brain
	var alpha: EcoCreature = null
	for c in _creatures:
		if c.idx == _alpha_idx and c.energy > 0.0:
			alpha = c
			break

	var brain: EcoBrain = alpha.brain if alpha else null
	var input_acts: Array[float] = alpha.last_inputs if alpha else []
	var hidden_acts: Array[float] = brain.hidden_activations if brain else []
	var output_acts: Array[float] = brain.output_activations if brain else []

	# Compute node positions
	var input_positions: Array[Vector3] = []
	var hidden_positions: Array[Vector3] = []
	var output_positions: Array[Vector3] = []

	for i in NN_INPUTS:
		var y := nn_h * 0.5 - float(i) / maxf(NN_INPUTS - 1, 1) * nn_h
		input_positions.append(Vector3(layer_x[0], y, 0.0))

	for i in NN_HIDDEN:
		var y := nn_h * 0.5 - float(i) / maxf(NN_HIDDEN - 1, 1) * nn_h
		hidden_positions.append(Vector3(layer_x[1], y, 0.0))

	for i in NN_OUTPUTS:
		var y := nn_h * 0.25 - float(i) / maxf(NN_OUTPUTS - 1, 1) * nn_h * 0.5
		output_positions.append(Vector3(layer_x[2], y, 0.0))

	# Background panel
	_add_quad(_nn_im, Vector3(-0.03, -nn_h * 0.5 - 0.04, -0.001),
		Vector3(0.30, 0, 0), Vector3(0, nn_h + 0.08, 0), COL_GRAPH_BG)

	# Draw connections: input -> hidden
	if brain:
		for i in NN_INPUTS:
			for j in NN_HIDDEN:
				var w := brain.weights_ih[i * NN_HIDDEN + j]
				var col := COL_WEIGHT_POS if w >= 0 else COL_WEIGHT_NEG
				var thickness := clampf(absf(w) * 0.004, 0.001, 0.005)
				col.a = clampf(absf(w) * 0.5, 0.08, 0.7)
				_add_line_quad(_nn_im, input_positions[i], hidden_positions[j], thickness, col)

		# Draw connections: hidden -> output
		for j in NN_HIDDEN:
			for k in NN_OUTPUTS:
				var w := brain.weights_ho[j * NN_OUTPUTS + k]
				var col := COL_WEIGHT_POS if w >= 0 else COL_WEIGHT_NEG
				var thickness := clampf(absf(w) * 0.004, 0.001, 0.005)
				col.a = clampf(absf(w) * 0.5, 0.08, 0.7)
				_add_line_quad(_nn_im, hidden_positions[j], output_positions[k], thickness, col)

	# Draw input neurons with activation bars
	var input_labels := ["FoodDist", "FoodAng", "NearCrt", "Energy", "Speed"]
	for i in NN_INPUTS:
		var act := input_acts[i] if i < input_acts.size() else 0.0
		var col := COL_NEURON_OFF.lerp(COL_NEURON_ON, clampf(absf(act), 0.0, 1.0))
		_add_circle(_nn_im, input_positions[i], node_r, col)
		# Activation bar
		var bar_w := clampf(absf(act), 0.0, 1.0) * 0.04
		var bar_col := COL_NEURON_ON
		bar_col.a = 0.5
		_add_quad(_nn_im, input_positions[i] + Vector3(-0.06, -0.004, 0),
			Vector3(bar_w, 0, 0), Vector3(0, 0.008, 0), bar_col)

	# Draw hidden neurons
	for i in NN_HIDDEN:
		var act := hidden_acts[i] if i < hidden_acts.size() else 0.0
		var col := COL_NEURON_OFF.lerp(COL_NEURON_ON, clampf(act, 0.0, 1.0))
		_add_circle(_nn_im, hidden_positions[i], node_r, col)

	# Draw output neurons
	var output_labels := ["Turn", "Thrust"]
	for i in NN_OUTPUTS:
		var act := output_acts[i] if i < output_acts.size() else 0.0
		var col := COL_OUTPUT_LOW.lerp(COL_OUTPUT_HIGH, clampf(absf(act), 0.0, 1.0))
		_add_circle(_nn_im, output_positions[i], node_r * 1.3, col)
		# Decision indicator bar
		var dec_col := COL_OUTPUT_HIGH if absf(act) > 0.3 else COL_OUTPUT_LOW
		dec_col.a = 0.6
		_add_quad(_nn_im, output_positions[i] + Vector3(0.02, -0.006, 0),
			Vector3(0.03 * clampf(absf(act), 0.1, 1.0), 0, 0), Vector3(0, 0.012, 0), dec_col)

	_nn_im.surface_end()

# ── Fitness history graph ─────────────────────────────────────────────
func _rebuild_fitness_graph() -> void:
	_graph_im.clear_surfaces()
	_graph_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var graph_w := 0.40
	var graph_h := 0.12
	var origin := Vector3.ZERO

	# Background
	_add_quad(_graph_im, origin + Vector3(-0.01, -0.01, -0.001),
		Vector3(graph_w + 0.02, 0, 0), Vector3(0, graph_h + 0.02, 0), COL_GRAPH_BG)

	# Axes
	_add_line_quad(_graph_im, origin, origin + Vector3(graph_w, 0, 0), 0.002, COL_DIM)
	_add_line_quad(_graph_im, origin, origin + Vector3(0, graph_h, 0), 0.002, COL_DIM)

	if _fitness_history.size() < 2:
		_graph_im.surface_end()
		return

	var max_fit := 1.0
	for f in _fitness_history:
		max_fit = maxf(max_fit, f)

	var count := _fitness_history.size()
	for i in range(count - 1):
		var x0 := float(i) / float(MAX_HISTORY - 1) * graph_w
		var x1 := float(i + 1) / float(MAX_HISTORY - 1) * graph_w
		var y0 := _fitness_history[i] / max_fit * graph_h
		var y1 := _fitness_history[i + 1] / max_fit * graph_h
		_add_line_quad(_graph_im, origin + Vector3(x0, y0, 0),
			origin + Vector3(x1, y1, 0), 0.003, COL_GRAPH_LINE)

	# Current point dot
	var cur_x := float(count - 1) / float(MAX_HISTORY - 1) * graph_w
	var cur_y := _fitness_history[count - 1] / max_fit * graph_h
	_add_circle(_graph_im, origin + Vector3(cur_x, cur_y, 0.001), 0.006, COL_GRAPH_BEST)

	# Best-ever line
	var best_y := _best_ever_fitness / max_fit * graph_h
	var dash_col := COL_GRAPH_BEST
	dash_col.a = 0.3
	_add_line_quad(_graph_im, origin + Vector3(0, best_y, 0),
		origin + Vector3(graph_w, best_y, 0), 0.001, dash_col)

	_graph_im.surface_end()

# ── Genealogy tree ────────────────────────────────────────────────────
func _rebuild_genealogy() -> void:
	_gene_im.clear_surfaces()
	_gene_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var tree_w := 0.35
	var tree_h := 0.12

	# Background
	_add_quad(_gene_im, Vector3(-0.01, -0.01, -0.001),
		Vector3(tree_w + 0.02, 0, 0), Vector3(0, tree_h + 0.02, 0), COL_GRAPH_BG)

	if _genealogy.is_empty():
		_gene_im.surface_end()
		return

	# Draw nodes and connections left-to-right (oldest to newest)
	var count := _genealogy.size()
	var max_fit := 1.0
	for entry in _genealogy:
		max_fit = maxf(max_fit, entry.fitness)

	var prev_pos := Vector3.ZERO
	for i in count:
		var entry: Dictionary = _genealogy[i]
		var x := float(i) / maxf(count - 1, 1) * tree_w
		var y: float = (entry.fitness / max_fit) * tree_h * 0.8 + tree_h * 0.1
		var pos := Vector3(x, y, 0.0)

		# Node
		var is_latest := i == count - 1
		var node_col := COL_GENE_ALPHA if is_latest else COL_GENE_NODE
		var r := 0.008 if is_latest else 0.005
		_add_circle(_gene_im, pos, r, node_col)

		# Food eaten indicator (small bar below node)
		var food_bar := clampf(float(entry.food_eaten) / 10.0, 0.05, 1.0) * 0.02
		_add_quad(_gene_im, pos + Vector3(-food_bar * 0.5, -0.015, 0),
			Vector3(food_bar, 0, 0), Vector3(0, 0.004, 0), COL_ALIVE)

		# Connection line from previous
		if i > 0:
			_add_line_quad(_gene_im, prev_pos, pos, 0.002, COL_GENE_LINE)
		prev_pos = pos

	_gene_im.surface_end()

# ── Sensor lines (from alpha to sensed targets) ──────────────────────
func _draw_sensor_lines() -> void:
	_sensor_im.clear_surfaces()
	_sensor_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var alpha: EcoCreature = null
	for c in _creatures:
		if c.idx == _alpha_idx and c.energy > 0.0:
			alpha = c
			break

	if alpha:
		# Line to nearest food
		var nearest_food := _find_nearest_food(alpha.pos)
		if nearest_food and alpha.pos.distance_to(nearest_food.pos) < sensor_range:
			var food_dist := alpha.pos.distance_to(nearest_food.pos)
			var intensity := 1.0 - food_dist / sensor_range
			var col := Color(0.2, 0.95, 0.4, intensity * 0.5)
			_add_line_quad(_sensor_im, alpha.pos, nearest_food.pos, 0.003, col)

		# Line to nearest creature
		var nearest_creature := _find_nearest_creature(alpha)
		if nearest_creature and alpha.pos.distance_to(nearest_creature.pos) < sensor_range:
			var cdist := alpha.pos.distance_to(nearest_creature.pos)
			var intensity := 1.0 - cdist / sensor_range
			var col := Color(0.95, 0.5, 0.2, intensity * 0.4)
			_add_line_quad(_sensor_im, alpha.pos, nearest_creature.pos, 0.002, col)

		# Sensor range ring (horizontal circle on XZ plane)
		var ring_col := Color(0.6, 0.6, 0.8, 0.15)
		var segs := 16
		for i in segs:
			var a0 := TAU * float(i) / float(segs)
			var a1 := TAU * float(i + 1) / float(segs)
			var p0 := alpha.pos + Vector3(cos(a0), 0, sin(a0)) * sensor_range
			var p1 := alpha.pos + Vector3(cos(a1), 0, sin(a1)) * sensor_range
			_add_line_quad(_sensor_im, p0, p1, 0.001, ring_col)

	_sensor_im.surface_end()

# ── Helper: find nearest food ─────────────────────────────────────────
func _find_nearest_food(pos: Vector3) -> FoodItem:
	var best: FoodItem = null
	var best_d := INF
	for food in _foods:
		if food.consumed:
			continue
		var d := pos.distance_to(food.pos)
		if d < best_d:
			best_d = d
			best = food
	return best

func _find_nearest_creature(self_creature: EcoCreature) -> EcoCreature:
	var best: EcoCreature = null
	var best_d := INF
	for c in _creatures:
		if c == self_creature or c.energy <= 0.0:
			continue
		var d := self_creature.pos.distance_to(c.pos)
		if d < best_d:
			best_d = d
			best = c
	return best

# ── Labels ────────────────────────────────────────────────────────────
func _update_labels(alive: int) -> void:
	_gen_label.text = "Gen %d" % _generation
	_alive_label.text = "Alive: %d/%d" % [alive, population_size]
	_fitness_label.text = "Best: %.1f  Record: %.1f" % [_best_fitness, _best_ever_fitness]

# ── Geometry helpers ──────────────────────────────────────────────────
func _add_quad(im: ImmediateMesh, origin: Vector3, right: Vector3, up: Vector3, col: Color) -> void:
	im.surface_set_color(col)
	im.surface_add_vertex(origin)
	im.surface_add_vertex(origin + right)
	im.surface_add_vertex(origin + right + up)
	im.surface_add_vertex(origin)
	im.surface_add_vertex(origin + right + up)
	im.surface_add_vertex(origin + up)

func _add_line_quad(im: ImmediateMesh, a: Vector3, b: Vector3, width: float, col: Color) -> void:
	var dir := (b - a).normalized()
	var perp := Vector3(-dir.y, dir.x, 0).normalized() * width * 0.5
	if perp.length() < 0.0001:
		perp = Vector3(width * 0.5, 0, 0)
	im.surface_set_color(col)
	im.surface_add_vertex(a - perp)
	im.surface_add_vertex(b - perp)
	im.surface_add_vertex(b + perp)
	im.surface_add_vertex(a - perp)
	im.surface_add_vertex(b + perp)
	im.surface_add_vertex(a + perp)

func _add_circle(im: ImmediateMesh, center: Vector3, radius: float, col: Color) -> void:
	var segments := 8
	im.surface_set_color(col)
	for i in segments:
		var a0 := TAU * float(i) / float(segments)
		var a1 := TAU * float(i + 1) / float(segments)
		im.surface_add_vertex(center)
		im.surface_add_vertex(center + Vector3(cos(a0), sin(a0), 0) * radius)
		im.surface_add_vertex(center + Vector3(cos(a1), sin(a1), 0) * radius)

# ── Cleanup ───────────────────────────────────────────────────────────
func _exit_tree() -> void:
	_nn_im.clear_surfaces()
	_graph_im.clear_surfaces()
	_gene_im.clear_surfaces()
	_sensor_im.clear_surfaces()
	for child in get_children():
		if not child.owner:
			child.queue_free()

# ── apply_grid_config ─────────────────────────────────────────────────
func apply_grid_config(config: Dictionary) -> void:
	if config.has("population_size"):
		population_size = clampi(int(config.population_size), 5, 40)
	if config.has("mutation_rate"):
		mutation_rate = clampf(float(config.mutation_rate), 0.01, 0.3)
		if _mutation_ctrl:
			_mutation_ctrl.set_value(mutation_rate)
	if config.has("food_spawn_interval"):
		food_spawn_interval = clampf(float(config.food_spawn_interval), 0.5, 5.0)
		if _food_ctrl:
			_food_ctrl.set_value(food_spawn_interval)
	if config.has("max_speed"):
		max_speed = clampf(float(config.max_speed), 0.2, 1.5)
		if _speed_ctrl:
			_speed_ctrl.set_value(max_speed)
	if config.has("sensor_range"):
		sensor_range = clampf(float(config.sensor_range), 0.1, 0.8)
		if _sensor_ctrl:
			_sensor_ctrl.set_value(sensor_range)

# ============================================================================
# Inner classes
# ============================================================================

class EcoCreature:
	var idx: int = 0
	var parent_idx: int = -1
	var root: Node3D
	var energy: float = 5.0
	var food_eaten: int = 0
	var velocity: Vector3 = Vector3.ZERO
	var brain := EcoBrain.new()
	var tint: Color = Color.WHITE
	var last_inputs: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
	var _alive_time: float = 0.0

	var pos: Vector3:
		get:
			if is_instance_valid(root):
				return root.global_position
			return Vector3.ZERO
		set(value):
			if is_instance_valid(root):
				root.global_position = value

	func init(parent: Node3D) -> void:
		root = Node3D.new()
		root.name = "Creature_%d" % idx
		parent.add_child(root)
		brain = EcoBrain.new()

	func sense(foods: Array[FoodItem], creatures: Array, range_val: float) -> void:
		# Input 0: distance to nearest food (normalized by sensor range)
		# Input 1: angle to nearest food (normalized -1..1)
		# Input 2: distance to nearest creature (normalized)
		# Input 3: own energy (normalized 0..1)
		# Input 4: own speed (normalized 0..1)

		var nearest_food_dist := range_val
		var nearest_food_angle := 0.0
		var nearest_creature_dist := range_val

		for food in foods:
			if food.consumed:
				continue
			var d := pos.distance_to(food.pos)
			if d < nearest_food_dist:
				nearest_food_dist = d
				var diff := food.pos - pos
				nearest_food_angle = atan2(diff.z, diff.x)

		for c in creatures:
			if c == self or c.energy <= 0.0:
				continue
			var d := pos.distance_to(c.pos)
			if d < nearest_creature_dist:
				nearest_creature_dist = d

		last_inputs[0] = 1.0 - clampf(nearest_food_dist / range_val, 0.0, 1.0)
		last_inputs[1] = nearest_food_angle / PI  # -1..1
		last_inputs[2] = 1.0 - clampf(nearest_creature_dist / range_val, 0.0, 1.0)
		last_inputs[3] = clampf(energy / 10.0, 0.0, 1.0)
		last_inputs[4] = clampf(velocity.length() / 0.6, 0.0, 1.0)

	func update(delta: float, max_spd: float) -> void:
		if energy <= 0.0:
			return
		_alive_time += delta

		var outputs := brain.feed_forward(last_inputs)
		# Output 0: turn angle (-1..1 mapped to -PI..PI)
		# Output 1: thrust (0..1)
		var turn := outputs[0] * PI
		var thrust := clampf(outputs[1], 0.0, 1.0)

		# Current heading from velocity
		var heading := atan2(velocity.z, velocity.x) if velocity.length() > 0.001 else randf() * TAU
		heading += turn * delta * 3.0

		var desired := Vector3(cos(heading), 0, sin(heading)) * thrust * max_spd
		# Add slight Y wander
		desired.y = sin(_alive_time * 1.5) * 0.05
		velocity = velocity.lerp(desired, 0.15)
		velocity = velocity.limit_length(max_spd)
		pos += velocity * delta * 60.0

	func fitness() -> float:
		return _alive_time + food_eaten * 2.0

	func activation_intensity() -> float:
		# Average absolute activation of inputs as proxy for "sensor activity"
		var total := 0.0
		for v in last_inputs:
			total += absf(v)
		return total / float(last_inputs.size())

	func queue_free() -> void:
		if is_instance_valid(root):
			root.queue_free()


class EcoBrain:
	# 5 inputs -> 4 hidden (tanh) -> 2 outputs (tanh)
	var weights_ih: Array[float] = []   # NN_INPUTS * NN_HIDDEN
	var biases_h: Array[float] = []     # NN_HIDDEN
	var weights_ho: Array[float] = []   # NN_HIDDEN * NN_OUTPUTS
	var biases_o: Array[float] = []     # NN_OUTPUTS

	# Cached activations for visualization
	var hidden_activations: Array[float] = []
	var output_activations: Array[float] = []

	func _init() -> void:
		weights_ih.resize(NN_INPUTS * NN_HIDDEN)
		for i in weights_ih.size():
			weights_ih[i] = randf_range(-1.0, 1.0)

		biases_h.resize(NN_HIDDEN)
		for i in biases_h.size():
			biases_h[i] = randf_range(-0.5, 0.5)

		weights_ho.resize(NN_HIDDEN * NN_OUTPUTS)
		for i in weights_ho.size():
			weights_ho[i] = randf_range(-1.0, 1.0)

		biases_o.resize(NN_OUTPUTS)
		for i in biases_o.size():
			biases_o[i] = randf_range(-0.5, 0.5)

		hidden_activations.resize(NN_HIDDEN)
		for i in hidden_activations.size():
			hidden_activations[i] = 0.0

		output_activations.resize(NN_OUTPUTS)
		for i in output_activations.size():
			output_activations[i] = 0.0

	func feed_forward(inputs: Array[float]) -> Array[float]:
		# Hidden layer (tanh activation)
		for j in NN_HIDDEN:
			var s := biases_h[j]
			for i in NN_INPUTS:
				s += inputs[i] * weights_ih[i * NN_HIDDEN + j]
			hidden_activations[j] = (exp(s) - exp(-s)) / (exp(s) + exp(-s))  # tanh

		# Output layer (tanh for -1..1 range)
		for k in NN_OUTPUTS:
			var s := biases_o[k]
			for j in NN_HIDDEN:
				s += hidden_activations[j] * weights_ho[j * NN_OUTPUTS + k]
			output_activations[k] = (exp(s) - exp(-s)) / (exp(s) + exp(-s))  # tanh

		return output_activations

	func mutate(rate: float) -> void:
		for i in weights_ih.size():
			if randf() < rate:
				weights_ih[i] += randfn(0.0, 0.3)
		for i in biases_h.size():
			if randf() < rate:
				biases_h[i] += randfn(0.0, 0.2)
		for i in weights_ho.size():
			if randf() < rate:
				weights_ho[i] += randfn(0.0, 0.3)
		for i in biases_o.size():
			if randf() < rate:
				biases_o[i] += randfn(0.0, 0.2)

	func copy_from(other: EcoBrain) -> void:
		weights_ih = other.weights_ih.duplicate()
		biases_h = other.biases_h.duplicate()
		weights_ho = other.weights_ho.duplicate()
		biases_o = other.biases_o.duplicate()


class FoodItem:
	var root: Node3D
	var mesh: MeshInstance3D
	var radius: float = 0.05
	var energy_value: float = 2.0
	var consumed: bool = false
	var _pulse_t: float = 0.0

	var pos: Vector3:
		get:
			if is_instance_valid(root):
				return root.global_position
			return Vector3.ZERO
		set(value):
			if is_instance_valid(root):
				root.global_position = value

	func init(parent: Node3D, rad: float) -> void:
		radius = rad
		root = Node3D.new()
		root.name = "Food"
		parent.add_child(root)

		mesh = MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = rad
		sphere.height = rad * 2.0
		sphere.radial_segments = 8
		sphere.rings = 4
		mesh.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.4, 1.0, 0.5, 0.7)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh.material_override = mat
		root.add_child(mesh)

	func pulse(delta: float) -> void:
		if consumed:
			return
		_pulse_t += delta
		var s := 1.0 + 0.1 * sin(_pulse_t * 4.0)
		if is_instance_valid(mesh):
			mesh.scale = Vector3.ONE * s

	func mark_consumed() -> void:
		consumed = true
		if is_instance_valid(mesh):
			mesh.visible = false

	func queue_free() -> void:
		if is_instance_valid(root):
			root.queue_free()
