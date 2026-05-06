# ===========================================================================
# NOC Example 11.1: Flappy Bird — Neuroevolution with Visible Neural Network
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# Elevated: real-time neural network graph (nodes + weighted connections),
# activation-colored neurons, population diversity via per-bird tint,
# fitness history graph, generation counter, ImmediateMesh rendering,
# VR sliders for mutation rate, population size, pipe speed.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 11.1: Flappy Bird NN — Watch the Network Learn
## Neuroevolution with visible neural network, activation heatmap, fitness graph
## Chapter 11: Neural Networks

# ── Constants ──────────────────────────────────────────────────────────
const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_PRIMARY := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_SECONDARY := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_secondary.tres")
const MAT_ACCENT := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")

const BIRD_X: float = -0.35
const MIN_Y: float = 0.05
const MAX_Y: float = 0.75
const PIPE_WIDTH: float = 0.10
const PIPE_DEPTH: float = 0.20
const PIPE_SPAWN_X: float = 0.45
const PIPE_DESPAWN_X: float = -0.55

# NN architecture: 4 inputs → 6 hidden → 1 output
const NN_INPUTS: int = 4
const NN_HIDDEN: int = 6
const NN_OUTPUTS: int = 1
const NN_INPUT_LABELS: Array[String] = ["Bird Y", "Vel Y", "Gap Y", "Pipe X"]

# Colors
const COL_NEURON_OFF := Color(0.15, 0.18, 0.25)
const COL_NEURON_ON := Color(0.3, 0.95, 0.85)      # cyan-green when active
const COL_WEIGHT_POS := Color(0.3, 0.85, 0.5, 0.6)  # green = positive weight
const COL_WEIGHT_NEG := Color(0.95, 0.3, 0.4, 0.6)  # red = negative weight
const COL_OUTPUT_FLAP := Color(1.0, 0.85, 0.2)       # yellow = flap decision
const COL_OUTPUT_WAIT := Color(0.25, 0.3, 0.4)       # dim = no flap
const COL_GRAPH_LINE := Color(0.35, 0.85, 0.95, 0.8) # cyan fitness line
const COL_GRAPH_BEST := Color(1.0, 0.6, 0.2, 0.8)    # orange best-ever line
const COL_GRAPH_BG := Color(0.1, 0.12, 0.16, 0.6)
const COL_LABEL := Color(0.92, 0.92, 0.96)
const COL_DIM := Color(0.5, 0.5, 0.55)
const COL_ALIVE := Color(0.3, 0.9, 0.5)
const COL_DEAD := Color(0.4, 0.15, 0.15, 0.3)

# ── Tunable parameters ────────────────────────────────────────────────
@export var population_size: int = 20
@export var mutation_rate: float = 0.10
@export var pipe_gap: float = 0.30
@export var pipe_spawn_interval: float = 2.0
@export var pipe_speed: float = 0.25
@export var gravity: float = 0.55
@export var flap_strength: float = 1.6

# ── State ──────────────────────────────────────────────────────────────
var _sim_root: Node3D
var _birds: Array = []   # Array of BirdNN
var _pipes: Array = []   # Array of Pipe
var _spawn_timer: float = 0.0
var _generation: int = 1
var _best_fitness: float = 0.0
var _best_ever_fitness: float = 0.0
var _alive_count: int = 0
var _champion_idx: int = 0

# Fitness history for graph (per-generation best)
var _fitness_history: Array[float] = []
const MAX_HISTORY: int = 50

# ── Visual nodes ───────────────────────────────────────────────────────
# Neural network graph
var _nn_im: ImmediateMesh
var _nn_mi: MeshInstance3D

# Fitness graph
var _graph_im: ImmediateMesh
var _graph_mi: MeshInstance3D

# Bird rendering (MultiMesh for performance)
var _bird_mm: MultiMesh
var _bird_mmi: MultiMeshInstance3D

# Unshaded vertex-color material
var _mat: StandardMaterial3D

# Labels
var _title_label: Label3D
var _gen_label: Label3D
var _alive_label: Label3D
var _fitness_label: Label3D
var _nn_title_label: Label3D
var _graph_title_label: Label3D

# ── Ready ──────────────────────────────────────────────────────────────
func _ready() -> void:
	randomize()
	_create_material()
	_setup_environment()
	_create_bird_multimesh()
	_create_meshes()
	_create_labels()
	_create_controllers()
	_spawn_population()
	_spawn_pipe()
	_spawn_timer = pipe_spawn_interval

func _create_material() -> void:
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.vertex_color_use_as_albedo = true
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	_sim_root.name = "SimulationRoot"
	add_child(_sim_root)

func _create_bird_multimesh() -> void:
	_bird_mm = MultiMesh.new()
	_bird_mm.transform_format = MultiMesh.TRANSFORM_3D
	_bird_mm.use_colors = true
	var sphere := SphereMesh.new()
	sphere.radius = 0.025
	sphere.height = 0.05
	sphere.radial_segments = 8
	sphere.rings = 4
	_bird_mm.mesh = sphere
	_bird_mm.instance_count = population_size

	_bird_mmi = MultiMeshInstance3D.new()
	_bird_mmi.multimesh = _bird_mm
	_bird_mmi.material_override = MAT_PRIMARY
	_sim_root.add_child(_bird_mmi)

func _create_meshes() -> void:
	# Neural network visualization (right side)
	_nn_im = ImmediateMesh.new()
	_nn_mi = MeshInstance3D.new()
	_nn_mi.mesh = _nn_im
	_nn_mi.material_override = _mat
	_nn_mi.position = Vector3(0.55, 0.15, 0.0)
	add_child(_nn_mi)

	# Fitness graph (bottom)
	_graph_im = ImmediateMesh.new()
	_graph_mi = MeshInstance3D.new()
	_graph_mi.mesh = _graph_im
	_graph_mi.material_override = _mat
	_graph_mi.position = Vector3(-0.15, -0.15, 0.0)
	add_child(_graph_mi)

func _create_labels() -> void:
	_title_label = _make_label(Vector3(-0.05, 0.82, 0.0), 24)
	_title_label.text = "Flappy Bird — Neuroevolution"
	_title_label.modulate = COL_LABEL

	_gen_label = _make_label(Vector3(-0.35, 0.76, 0.0), 18)
	_gen_label.modulate = COL_GRAPH_BEST

	_alive_label = _make_label(Vector3(-0.05, 0.76, 0.0), 18)
	_alive_label.modulate = COL_ALIVE

	_fitness_label = _make_label(Vector3(0.25, 0.76, 0.0), 18)
	_fitness_label.modulate = COL_GRAPH_LINE

	_nn_title_label = _make_label(Vector3(0.55, 0.62, 0.0), 16)
	_nn_title_label.text = "Best Bird's Brain"
	_nn_title_label.modulate = COL_DIM

	_graph_title_label = _make_label(Vector3(-0.15, -0.07, 0.0), 14)
	_graph_title_label.text = "Fitness / Generation"
	_graph_title_label.modulate = COL_DIM

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

	var mutation_ctrl := CONTROLLER_SCENE.instantiate()
	mutation_ctrl.parameter_name = "Mutation"
	mutation_ctrl.min_value = 0.01
	mutation_ctrl.max_value = 0.3
	mutation_ctrl.default_value = mutation_rate
	mutation_ctrl.position = Vector3(0.0, 0.15, 0.0)
	mutation_ctrl.rotation_degrees = Vector3(0, 90, 0)
	controller_root.add_child(mutation_ctrl)
	mutation_ctrl.value_changed.connect(func(v: float) -> void: mutation_rate = v)
	mutation_ctrl.set_value(mutation_rate)

	var speed_ctrl := CONTROLLER_SCENE.instantiate()
	speed_ctrl.parameter_name = "Pipe Speed"
	speed_ctrl.min_value = 0.12
	speed_ctrl.max_value = 0.5
	speed_ctrl.default_value = pipe_speed
	speed_ctrl.position = Vector3(0.0, -0.1, 0.0)
	speed_ctrl.rotation_degrees = Vector3(0, 90, 0)
	controller_root.add_child(speed_ctrl)
	speed_ctrl.value_changed.connect(func(v: float) -> void: pipe_speed = v)
	speed_ctrl.set_value(pipe_speed)

	var gravity_ctrl := CONTROLLER_SCENE.instantiate()
	gravity_ctrl.parameter_name = "Gravity"
	gravity_ctrl.min_value = 0.2
	gravity_ctrl.max_value = 1.2
	gravity_ctrl.default_value = gravity
	gravity_ctrl.position = Vector3(0.0, -0.35, 0.0)
	gravity_ctrl.rotation_degrees = Vector3(0, 90, 0)
	controller_root.add_child(gravity_ctrl)
	gravity_ctrl.value_changed.connect(func(v: float) -> void: gravity = v)
	gravity_ctrl.set_value(gravity)

# ── Spawning ───────────────────────────────────────────────────────────
func _spawn_population() -> void:
	_birds.clear()
	for i in population_size:
		var bird := BirdNN.new()
		bird.idx = i
		bird.pos = Vector3(BIRD_X, randf_range(0.2, 0.6), 0.0)
		bird.gravity = gravity
		bird.flap_strength = flap_strength
		# Color diversity: hue shift per bird
		bird.tint = Color.from_hsv(fmod(float(i) / float(population_size) * 0.6 + 0.45, 1.0), 0.7, 0.9)
		_birds.append(bird)
	_alive_count = population_size
	_champion_idx = 0
	_best_fitness = 0.0

	# Resize multimesh if needed
	if _bird_mm.instance_count != population_size:
		_bird_mm.instance_count = population_size

func _spawn_pipe() -> void:
	var gap_center := randf_range(MIN_Y + pipe_gap * 0.6, MAX_Y - pipe_gap * 0.6)
	var pipe := Pipe.new()
	pipe.init(_sim_root, MAT_SECONDARY, gap_center, pipe_gap)
	pipe.position_x = PIPE_SPAWN_X
	pipe.update_geometry(PIPE_WIDTH, PIPE_DEPTH)
	_pipes.append(pipe)

# ── Physics process ────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if _birds.is_empty():
		return

	# Spawn pipes
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_pipe()
		_spawn_timer = pipe_spawn_interval

	# Move pipes
	for pipe in _pipes:
		pipe.position_x -= pipe_speed * delta
		pipe.apply_positions()

	# Remove offscreen pipes
	for pipe in _pipes.duplicate():
		if pipe.position_x < PIPE_DESPAWN_X:
			pipe.queue_free()
			_pipes.erase(pipe)

	# Update birds
	_alive_count = 0
	var best_local := 0.0
	var best_idx := 0

	for bird in _birds:
		if not bird.alive:
			continue

		_alive_count += 1
		bird.gravity = gravity
		bird.think(_pipes)
		bird.update(delta)

		# Clamp
		if bird.pos.y < MIN_Y or bird.pos.y > MAX_Y:
			bird.pos.y = clampf(bird.pos.y, MIN_Y, MAX_Y)
			bird.vel_y = 0.0
			bird.alive = false
			continue

		# Pipe collisions
		for pipe in _pipes:
			if pipe.overlaps_x(bird.pos.x, PIPE_WIDTH):
				if not pipe.is_within_gap(bird.pos.y):
					bird.alive = false
					break

		if bird.alive and bird.fitness > best_local:
			best_local = bird.fitness
			best_idx = bird.idx

	_best_fitness = max(_best_fitness, best_local)
	_best_ever_fitness = max(_best_ever_fitness, _best_fitness)
	_champion_idx = best_idx

	# All dead → next generation
	if _alive_count == 0:
		_next_generation()

	# Update visuals
	_update_bird_multimesh()
	_rebuild_nn_graph()
	_rebuild_fitness_graph()
	_update_labels()

# ── Next generation ────────────────────────────────────────────────────
func _next_generation() -> void:
	# Record fitness history
	_fitness_history.append(_best_fitness)
	if _fitness_history.size() > MAX_HISTORY:
		_fitness_history.remove_at(0)

	# Build mating pool (fitness-proportionate)
	var mating_pool: Array = []
	for bird in _birds:
		var tickets := int(bird.fitness * 10.0) + 1
		for j in tickets:
			mating_pool.append(bird)

	# Clear pipes
	for pipe in _pipes:
		pipe.queue_free()
	_pipes.clear()
	_spawn_pipe()
	_spawn_timer = pipe_spawn_interval

	_generation += 1
	_best_fitness = 0.0

	# Create offspring
	var new_birds: Array = []
	for i in population_size:
		var parent: BirdNN = mating_pool[randi() % mating_pool.size()]
		var child := BirdNN.new()
		child.idx = i
		child.pos = Vector3(BIRD_X, randf_range(0.2, 0.6), 0.0)
		child.gravity = gravity
		child.flap_strength = flap_strength
		child.tint = Color.from_hsv(fmod(float(i) / float(population_size) * 0.6 + 0.45, 1.0), 0.7, 0.9)
		child.brain.copy_from(parent.brain)
		child.brain.mutate(mutation_rate)
		new_birds.append(child)

	_birds = new_birds
	_alive_count = population_size
	_champion_idx = 0

	if _bird_mm.instance_count != population_size:
		_bird_mm.instance_count = population_size

# ── MultiMesh update ───────────────────────────────────────────────────
func _update_bird_multimesh() -> void:
	for i in range(mini(_birds.size(), _bird_mm.instance_count)):
		var bird: BirdNN = _birds[i]
		var t := Transform3D.IDENTITY
		if bird.alive:
			t.origin = bird.pos
			var col := bird.tint
			if i == _champion_idx:
				col = Color(1.0, 0.95, 0.3)  # gold for champion
			_bird_mm.set_instance_color(i, col)
		else:
			t.origin = Vector3(0.0, -10.0, 0.0)  # hide dead birds
			_bird_mm.set_instance_color(i, COL_DEAD)
		_bird_mm.set_instance_transform(i, t)

# ── Neural network graph ──────────────────────────────────────────────
func _rebuild_nn_graph() -> void:
	_nn_im.clear_surfaces()
	_nn_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	# Layout: 3 columns — inputs | hidden | output
	var layer_x := [0.0, 0.12, 0.24]
	var node_r := 0.012

	# Get champion's brain state
	var champ: BirdNN = _birds[_champion_idx] if _champion_idx < _birds.size() else null
	var brain: LayeredBrain = champ.brain if champ else null
	var input_acts: Array[float] = champ.last_inputs if champ else []
	var hidden_acts: Array[float] = brain.hidden_activations if brain else []
	var output_act: float = brain.output_activation if brain else 0.0

	# Compute node positions
	var input_positions: Array[Vector3] = []
	var hidden_positions: Array[Vector3] = []
	var output_positions: Array[Vector3] = []

	var nn_h := 0.45
	for i in NN_INPUTS:
		var y := nn_h * 0.5 - float(i) / maxf(NN_INPUTS - 1, 1) * nn_h
		input_positions.append(Vector3(layer_x[0], y, 0.0))

	for i in NN_HIDDEN:
		var y := nn_h * 0.5 - float(i) / maxf(NN_HIDDEN - 1, 1) * nn_h
		hidden_positions.append(Vector3(layer_x[1], y, 0.0))

	for i in NN_OUTPUTS:
		output_positions.append(Vector3(layer_x[2], 0.0, 0.0))

	# Background panel
	_add_quad(_nn_im, Vector3(-0.03, -nn_h * 0.5 - 0.04, -0.001),
		Vector3(0.30, 0, 0), Vector3(0, nn_h + 0.08, 0), COL_GRAPH_BG)

	# Draw connections: input → hidden
	if brain:
		for i in NN_INPUTS:
			for j in NN_HIDDEN:
				var w := brain.weights_ih[i * NN_HIDDEN + j]
				var col := COL_WEIGHT_POS if w >= 0 else COL_WEIGHT_NEG
				var thickness := clampf(absf(w) * 0.004, 0.001, 0.005)
				col.a = clampf(absf(w) * 0.5, 0.08, 0.7)
				_add_line_quad(_nn_im, input_positions[i], hidden_positions[j], thickness, col)

		# Draw connections: hidden → output
		for j in NN_HIDDEN:
			var w := brain.weights_ho[j]
			var col := COL_WEIGHT_POS if w >= 0 else COL_WEIGHT_NEG
			var thickness := clampf(absf(w) * 0.004, 0.001, 0.005)
			col.a = clampf(absf(w) * 0.5, 0.08, 0.7)
			_add_line_quad(_nn_im, hidden_positions[j], output_positions[0], thickness, col)

	# Draw input neurons
	for i in NN_INPUTS:
		var act := input_acts[i] if i < input_acts.size() else 0.0
		var col := COL_NEURON_OFF.lerp(COL_NEURON_ON, clampf(absf(act), 0.0, 1.0))
		_add_circle(_nn_im, input_positions[i], node_r, col)

	# Draw hidden neurons
	for i in NN_HIDDEN:
		var act := hidden_acts[i] if i < hidden_acts.size() else 0.0
		var col := COL_NEURON_OFF.lerp(COL_NEURON_ON, clampf(act, 0.0, 1.0))
		_add_circle(_nn_im, hidden_positions[i], node_r, col)

	# Draw output neuron
	var out_col := COL_OUTPUT_WAIT.lerp(COL_OUTPUT_FLAP, clampf(output_act, 0.0, 1.0))
	_add_circle(_nn_im, output_positions[0], node_r * 1.3, out_col)

	# Input labels (small text rendered as colored dots for simplicity)
	# Actual labels handled by Label3D nodes would be too many — use activation bars instead
	for i in NN_INPUTS:
		var act := input_acts[i] if i < input_acts.size() else 0.0
		var bar_w := clampf(absf(act), 0.0, 1.0) * 0.04
		var bar_col := COL_NEURON_ON
		bar_col.a = 0.5
		_add_quad(_nn_im, input_positions[i] + Vector3(-0.06, -0.004, 0),
			Vector3(bar_w, 0, 0), Vector3(0, 0.008, 0), bar_col)

	# Output decision indicator
	var decision_text_col := COL_OUTPUT_FLAP if output_act > 0.5 else COL_OUTPUT_WAIT
	decision_text_col.a = 0.6
	_add_quad(_nn_im, output_positions[0] + Vector3(0.02, -0.006, 0),
		Vector3(0.03, 0, 0), Vector3(0, 0.012, 0), decision_text_col)

	_nn_im.surface_end()

# ── Fitness history graph ──────────────────────────────────────────────
func _rebuild_fitness_graph() -> void:
	_graph_im.clear_surfaces()
	_graph_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var graph_w := 0.55
	var graph_h := 0.12
	var origin := Vector3(0.0, 0.0, 0.0)

	# Background
	_add_quad(_graph_im, origin + Vector3(-0.01, -0.01, -0.001),
		Vector3(graph_w + 0.02, 0, 0), Vector3(0, graph_h + 0.02, 0), COL_GRAPH_BG)

	# Axes
	_add_line_quad(_graph_im, origin, origin + Vector3(graph_w, 0, 0), 0.002, COL_DIM)
	_add_line_quad(_graph_im, origin, origin + Vector3(0, graph_h, 0), 0.002, COL_DIM)

	if _fitness_history.size() < 2:
		_graph_im.surface_end()
		return

	# Find max for scaling
	var max_fit := 1.0
	for f in _fitness_history:
		max_fit = maxf(max_fit, f)

	# Draw fitness line
	var count := _fitness_history.size()
	for i in range(count - 1):
		var x0 := float(i) / float(MAX_HISTORY - 1) * graph_w
		var x1 := float(i + 1) / float(MAX_HISTORY - 1) * graph_w
		var y0 := _fitness_history[i] / max_fit * graph_h
		var y1 := _fitness_history[i + 1] / max_fit * graph_h
		_add_line_quad(_graph_im, origin + Vector3(x0, y0, 0),
			origin + Vector3(x1, y1, 0), 0.003, COL_GRAPH_LINE)

	# Current generation marker (vertical bar at right edge)
	var cur_x := float(count - 1) / float(MAX_HISTORY - 1) * graph_w
	var cur_y := _fitness_history[count - 1] / max_fit * graph_h
	# Dot at current point
	_add_circle(_graph_im, origin + Vector3(cur_x, cur_y, 0.001), 0.006, COL_GRAPH_BEST)

	# Best-ever line (horizontal dashed)
	var best_y := _best_ever_fitness / max_fit * graph_h
	var dash_col := COL_GRAPH_BEST
	dash_col.a = 0.3
	_add_line_quad(_graph_im, origin + Vector3(0, best_y, 0),
		origin + Vector3(graph_w, best_y, 0), 0.001, dash_col)

	_graph_im.surface_end()

# ── Label updates ──────────────────────────────────────────────────────
func _update_labels() -> void:
	_gen_label.text = "Gen %d" % _generation
	_alive_label.text = "Alive: %d/%d" % [_alive_count, population_size]
	_fitness_label.text = "Best: %.1f  Record: %.1f" % [_best_fitness, _best_ever_fitness]

# ── Geometry helpers ───────────────────────────────────────────────────
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
	# Approximate circle with 8-segment fan
	var segments := 8
	im.surface_set_color(col)
	for i in segments:
		var a0 := TAU * float(i) / float(segments)
		var a1 := TAU * float(i + 1) / float(segments)
		im.surface_add_vertex(center)
		im.surface_add_vertex(center + Vector3(cos(a0), sin(a0), 0) * radius)
		im.surface_add_vertex(center + Vector3(cos(a1), sin(a1), 0) * radius)

# ── Cleanup ────────────────────────────────────────────────────────────
func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

# ── apply_grid_config ──────────────────────────────────────────────────
func apply_grid_config(config: Dictionary) -> void:
	if config.has("mutation_rate"):
		mutation_rate = clampf(float(config.mutation_rate), 0.01, 0.3)
	if config.has("pipe_speed"):
		pipe_speed = clampf(float(config.pipe_speed), 0.12, 0.5)
	if config.has("gravity"):
		gravity = clampf(float(config.gravity), 0.2, 1.2)
	if config.has("population_size"):
		population_size = clampi(int(config.population_size), 5, 40)

# ============================================================================
# Inner classes
# ============================================================================

class BirdNN:
	var idx: int = 0
	var pos: Vector3 = Vector3.ZERO
	var vel_y: float = 0.0
	var gravity: float = 0.55
	var flap_strength: float = 1.6
	var alive: bool = true
	var fitness: float = 0.0
	var tint: Color = Color.WHITE
	var brain := LayeredBrain.new()
	var last_inputs: Array[float] = [0.0, 0.0, 0.0, 0.0]

	func update(delta: float) -> void:
		if not alive:
			return
		vel_y += gravity * delta
		pos.y -= vel_y * delta
		fitness += delta

	func think(pipes: Array) -> void:
		if not alive or pipes.is_empty():
			return

		# Find next pipe ahead of bird
		var next_pipe: Pipe = pipes[0]
		for pipe in pipes:
			if pipe.position_x + PIPE_WIDTH * 0.5 > pos.x:
				next_pipe = pipe
				break

		# Normalize inputs to 0-1 range
		last_inputs[0] = (pos.y - MIN_Y) / (MAX_Y - MIN_Y)
		last_inputs[1] = clampf(vel_y / 2.0, -1.0, 1.0) * 0.5 + 0.5
		last_inputs[2] = (next_pipe.gap_center - MIN_Y) / (MAX_Y - MIN_Y)
		last_inputs[3] = clampf((next_pipe.position_x - pos.x) / (PIPE_SPAWN_X - BIRD_X), 0.0, 1.0)

		var decision := brain.feed_forward(last_inputs)
		if decision > 0.5:
			flap()

	func flap() -> void:
		vel_y = -flap_strength


class Pipe:
	var root: Node3D
	var top_mi: MeshInstance3D
	var bottom_mi: MeshInstance3D
	var gap_center: float = 0.5
	var gap_size: float = 0.3
	var position_x: float = 0.5

	func init(parent: Node3D, pipe_material: Material, gap: float, gap_extent: float) -> void:
		root = Node3D.new()
		root.name = "Pipe"
		parent.add_child(root)
		gap_center = gap
		gap_size = gap_extent

		top_mi = MeshInstance3D.new()
		bottom_mi = MeshInstance3D.new()
		top_mi.material_override = pipe_material
		bottom_mi.material_override = pipe_material
		root.add_child(top_mi)
		root.add_child(bottom_mi)

	func update_geometry(width: float, depth_size: float) -> void:
		var top_height := (MAX_Y - gap_center) - gap_size * 0.5
		var bottom_height := (gap_center - MIN_Y) - gap_size * 0.5
		top_height = maxf(top_height, 0.05)
		bottom_height = maxf(bottom_height, 0.05)

		var tm := BoxMesh.new()
		tm.size = Vector3(width, top_height, depth_size)
		top_mi.mesh = tm

		var bm := BoxMesh.new()
		bm.size = Vector3(width, bottom_height, depth_size)
		bottom_mi.mesh = bm

		apply_positions()

	func apply_positions() -> void:
		top_mi.position = Vector3(position_x, gap_center + gap_size * 0.5 + top_mi.mesh.size.y * 0.5, 0)
		bottom_mi.position = Vector3(position_x, gap_center - gap_size * 0.5 - bottom_mi.mesh.size.y * 0.5, 0)

	func overlaps_x(bird_x: float, width: float) -> bool:
		return bird_x > position_x - width * 0.5 and bird_x < position_x + width * 0.5

	func is_within_gap(bird_y: float) -> bool:
		return bird_y > gap_center - gap_size * 0.5 and bird_y < gap_center + gap_size * 0.5

	func queue_free() -> void:
		if is_instance_valid(top_mi):
			top_mi.queue_free()
		if is_instance_valid(bottom_mi):
			bottom_mi.queue_free()
		if is_instance_valid(root):
			root.queue_free()


class LayeredBrain:
	# 4 inputs → 6 hidden (tanh) → 1 output (sigmoid)
	var weights_ih: Array[float] = []   # NN_INPUTS * NN_HIDDEN
	var biases_h: Array[float] = []     # NN_HIDDEN
	var weights_ho: Array[float] = []   # NN_HIDDEN
	var bias_o: float = 0.0

	# Cached activations for visualization
	var hidden_activations: Array[float] = []
	var output_activation: float = 0.0

	func _init() -> void:
		weights_ih.resize(NN_INPUTS * NN_HIDDEN)
		for i in weights_ih.size():
			weights_ih[i] = randf_range(-1.0, 1.0)

		biases_h.resize(NN_HIDDEN)
		for i in biases_h.size():
			biases_h[i] = randf_range(-0.5, 0.5)

		weights_ho.resize(NN_HIDDEN)
		for i in weights_ho.size():
			weights_ho[i] = randf_range(-1.0, 1.0)

		bias_o = randf_range(-0.5, 0.5)

		hidden_activations.resize(NN_HIDDEN)
		for i in hidden_activations.size():
			hidden_activations[i] = 0.0

	func feed_forward(inputs: Array[float]) -> float:
		# Hidden layer (tanh activation)
		for j in NN_HIDDEN:
			var sum := biases_h[j]
			for i in NN_INPUTS:
				sum += inputs[i] * weights_ih[i * NN_HIDDEN + j]
			hidden_activations[j] = (exp(sum) - exp(-sum)) / (exp(sum) + exp(-sum))  # tanh

		# Output layer (sigmoid)
		var out_sum := bias_o
		for j in NN_HIDDEN:
			out_sum += hidden_activations[j] * weights_ho[j]
		output_activation = 1.0 / (1.0 + exp(-out_sum))
		return output_activation

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
		if randf() < rate:
			bias_o += randfn(0.0, 0.2)

	func copy_from(other: LayeredBrain) -> void:
		weights_ih = other.weights_ih.duplicate()
		biases_h = other.biases_h.duplicate()
		weights_ho = other.weights_ho.duplicate()
		bias_o = other.bias_o
