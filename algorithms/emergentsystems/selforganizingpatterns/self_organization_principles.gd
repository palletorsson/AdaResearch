# ===========================================================================
# SelfOrganizingPatterns — Stigmergy, Phase Transitions & Attractor Basins
# Self-organization visualization with indirect coordination (stigmergy),
# order parameter tracking for phase transitions, and attractor basin mapping.
# Elevated features:
#   - ImmediateMesh stigmergy field with deposit/evaporation gradient
#   - Phase transition detection via order parameter (alignment/clustering)
#   - Attractor basin visualization with Voronoi-like coloring
#   - Configurable via apply_grid_config()
# License: CC BY-NC-SA 3.0 derivative
# ===========================================================================

class_name SelfOrganizingPatterns
extends Node3D

## Self-Organizing Patterns with stigmergy, phase transitions, and attractors.
## STIGMERGY mode shows indirect coordination through environmental markers.
## PHASE_TRANSITION mode detects order/disorder transitions via order parameters.
## ATTRACTOR_BASINS mode maps basin boundaries and convergence flow.

# --- Configuration ---
@export var agent_count: int = 60
@export var grid_resolution: int = 40
@export var field_size: float = 6.0
@export var agent_speed: float = 2.0
@export var deposit_rate: float = 3.0
@export var evaporation_rate: float = 0.015
@export var diffusion_rate: float = 0.08
@export var coupling_strength: float = 1.5
@export var noise_level: float = 0.3
@export var num_attractors: int = 4

# --- Mode ---
enum Mode { STIGMERGY, PHASE_TRANSITION, ATTRACTOR_BASINS }
var _mode: int = Mode.STIGMERGY

# --- Internal state ---
var _time: float = 0.0
var _stigmergy_grid: Array = []   # 2D float array — environmental signal
var _agents: Array = []
var _attractors: Array = []       # {pos: Vector2, color: Color, strength: float}
var _order_parameter: float = 0.0 # Global alignment measure 0..1
var _order_history: PackedFloat32Array = PackedFloat32Array()
var _susceptibility: float = 0.0  # d(order)/d(coupling) — peaks at transition
var _temperature: float = 1.0     # Effective noise/temperature for phase transition
var _phase_sweep_active: bool = true
var _phase_sweep_dir: float = -1.0  # sweeping temperature down then up

# Basin tracking
var _basin_grid: Array = []  # 2D int array — which attractor each cell converges to
var _flow_field: Array = []  # 2D Vector2 array — gradient direction

# --- Rendering ---
var _field_im: ImmediateMesh
var _field_mi: MeshInstance3D
var _agents_im: ImmediateMesh
var _agents_mi: MeshInstance3D
var _overlay_im: ImmediateMesh
var _overlay_mi: MeshInstance3D
var _flow_im: ImmediateMesh
var _flow_mi: MeshInstance3D
var _graph_im: ImmediateMesh
var _graph_mi: MeshInstance3D

# Materials
var _mat_unshaded: StandardMaterial3D
var _mat_alpha: StandardMaterial3D

# Labels
var _title_label: Label3D
var _mode_label: Label3D
var _info_label: Label3D
var _stats_label: Label3D

# VR controls
const SLIDER_SCENE = preload("res://commons/interactables/slider_horizontal.tscn")
const BUTTON_SCENE = preload("res://commons/interactables/push_button.tscn")
var _mode_button: Node3D
var _reset_button: Node3D
var _noise_slider: Node3D
var _coupling_slider: Node3D

# Colors
const COL_AGENT_ALIGNED := Color(0.2, 0.85, 0.95)
const COL_AGENT_RANDOM := Color(0.9, 0.3, 0.2)
const COL_DEPOSIT_LOW := Color(0.05, 0.08, 0.25, 0.0)
const COL_DEPOSIT_MED := Color(0.15, 0.4, 0.7, 0.4)
const COL_DEPOSIT_HIGH := Color(0.3, 0.9, 0.5, 0.75)
const COL_DEPOSIT_MAX := Color(1.0, 0.95, 0.3, 0.95)
const COL_ORDER_LINE := Color(0.3, 0.95, 0.6)
const COL_SUSCEPT_LINE := Color(1.0, 0.6, 0.15)
const COL_TRANSITION := Color(1.0, 0.2, 0.3, 0.8)

# Basin palette
const BASIN_COLORS: Array = [
	Color(0.2, 0.6, 1.0, 0.35),
	Color(1.0, 0.4, 0.2, 0.35),
	Color(0.3, 0.9, 0.4, 0.35),
	Color(0.9, 0.2, 0.8, 0.35),
	Color(1.0, 0.85, 0.15, 0.35),
	Color(0.15, 0.9, 0.85, 0.35),
]

# Heatmap color ramp for stigmergy field
const STIG_COLORS: Array = [
	Color(0.03, 0.03, 0.15, 0.0),
	Color(0.08, 0.15, 0.45, 0.25),
	Color(0.12, 0.45, 0.65, 0.45),
	Color(0.25, 0.8, 0.5, 0.65),
	Color(0.85, 0.9, 0.2, 0.8),
	Color(1.0, 0.55, 0.1, 0.9),
	Color(1.0, 0.2, 0.1, 1.0),
]

# Agent state
class AgentState:
	var pos: Vector2
	var heading: float  # angle in radians
	var spin: float     # +1 or -1 for Ising-like alignment
	var basin_id: int = -1

	func _init(start: Vector2) -> void:
		pos = start
		heading = randf() * TAU
		spin = 1.0 if randf() > 0.5 else -1.0


func _ready() -> void:
	_create_materials()
	_create_mesh_instances()
	_create_labels()
	_create_vr_controls()
	_init_grids()
	_spawn_attractors()
	_spawn_agents()


# =========================================================================
# Materials
# =========================================================================

func _create_materials() -> void:
	_mat_unshaded = StandardMaterial3D.new()
	_mat_unshaded.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_unshaded.vertex_color_use_as_albedo = true
	_mat_unshaded.cull_mode = BaseMaterial3D.CULL_DISABLED

	_mat_alpha = StandardMaterial3D.new()
	_mat_alpha.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_alpha.vertex_color_use_as_albedo = true
	_mat_alpha.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_alpha.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


# =========================================================================
# Mesh instances
# =========================================================================

func _create_mesh_instances() -> void:
	_field_im = ImmediateMesh.new()
	_field_mi = MeshInstance3D.new()
	_field_mi.mesh = _field_im
	_field_mi.material_override = _mat_alpha
	add_child(_field_mi)

	_overlay_im = ImmediateMesh.new()
	_overlay_mi = MeshInstance3D.new()
	_overlay_mi.mesh = _overlay_im
	_overlay_mi.material_override = _mat_alpha
	add_child(_overlay_mi)

	_flow_im = ImmediateMesh.new()
	_flow_mi = MeshInstance3D.new()
	_flow_mi.mesh = _flow_im
	_flow_mi.material_override = _mat_alpha
	add_child(_flow_mi)

	_agents_im = ImmediateMesh.new()
	_agents_mi = MeshInstance3D.new()
	_agents_mi.mesh = _agents_im
	_agents_mi.material_override = _mat_unshaded
	add_child(_agents_mi)

	_graph_im = ImmediateMesh.new()
	_graph_mi = MeshInstance3D.new()
	_graph_mi.mesh = _graph_im
	_graph_mi.material_override = _mat_unshaded
	add_child(_graph_mi)


# =========================================================================
# Labels
# =========================================================================

func _create_labels() -> void:
	_title_label = Label3D.new()
	_title_label.text = "Self-Organizing Patterns"
	_title_label.font_size = 48
	_title_label.position = Vector3(0, field_size * 0.5 + 0.8, 0)
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_title_label.modulate = Color(0.9, 0.85, 0.7)
	add_child(_title_label)

	_mode_label = Label3D.new()
	_mode_label.font_size = 28
	_mode_label.position = Vector3(0, field_size * 0.5 + 0.4, 0)
	_mode_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_mode_label.modulate = Color(0.7, 0.7, 0.8)
	add_child(_mode_label)

	_info_label = Label3D.new()
	_info_label.font_size = 22
	_info_label.position = Vector3(-field_size * 0.5 - 0.6, -field_size * 0.5, 0)
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.modulate = Color(0.6, 0.7, 0.8)
	add_child(_info_label)

	_stats_label = Label3D.new()
	_stats_label.font_size = 22
	_stats_label.position = Vector3(field_size * 0.5 + 0.6, -field_size * 0.5, 0)
	_stats_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_stats_label.modulate = Color(0.7, 0.8, 0.6)
	add_child(_stats_label)

	_update_labels()


# =========================================================================
# VR Controls
# =========================================================================

func _create_vr_controls() -> void:
	var ctrl_y := -field_size * 0.5 - 1.0

	# Mode cycle button
	_mode_button = BUTTON_SCENE.instantiate()
	_mode_button.position = Vector3(-2.0, ctrl_y, 0)
	add_child(_mode_button)
	var mb_area = _mode_button.get_node_or_null("InteractableAreaButton")
	if mb_area:
		mb_area.button_pressed.connect(_on_mode_pressed)
	var mb_label = _mode_button.get_node_or_null("Frame/LabelName")
	if mb_label:
		mb_label.text = "Mode"

	# Reset button
	_reset_button = BUTTON_SCENE.instantiate()
	_reset_button.position = Vector3(-0.5, ctrl_y, 0)
	add_child(_reset_button)
	var rb_area = _reset_button.get_node_or_null("InteractableAreaButton")
	if rb_area:
		rb_area.button_pressed.connect(_on_reset_pressed)
	var rb_label = _reset_button.get_node_or_null("Frame/LabelName")
	if rb_label:
		rb_label.text = "Reset"

	# Noise/temperature slider
	_noise_slider = SLIDER_SCENE.instantiate()
	_noise_slider.position = Vector3(1.2, ctrl_y, 0)
	add_child(_noise_slider)
	if _noise_slider.has_method("set_param_name"):
		_noise_slider.set_param_name("Noise")
	if _noise_slider.has_method("set_normalized_value"):
		_noise_slider.set_normalized_value(noise_level)
	if _noise_slider.has_signal("slider_moved"):
		_noise_slider.slider_moved.connect(_on_noise_changed)

	# Coupling strength slider
	_coupling_slider = SLIDER_SCENE.instantiate()
	_coupling_slider.position = Vector3(3.0, ctrl_y, 0)
	add_child(_coupling_slider)
	if _coupling_slider.has_method("set_param_name"):
		_coupling_slider.set_param_name("Coupling")
	if _coupling_slider.has_method("set_normalized_value"):
		_coupling_slider.set_normalized_value(coupling_strength / 3.0)
	if _coupling_slider.has_signal("slider_moved"):
		_coupling_slider.slider_moved.connect(_on_coupling_changed)


func _on_mode_pressed() -> void:
	_mode = (_mode + 1) % 3
	if _mode == Mode.PHASE_TRANSITION:
		_temperature = 2.0
		_phase_sweep_active = true
		_phase_sweep_dir = -1.0
		_order_history = PackedFloat32Array()
	_update_labels()


func _on_reset_pressed() -> void:
	_reset_simulation()


func _on_noise_changed(_val: float) -> void:
	if _noise_slider.has_method("get_normalized_value"):
		noise_level = _noise_slider.get_normalized_value()
		if _mode == Mode.PHASE_TRANSITION:
			_phase_sweep_active = false
			_temperature = noise_level * 2.0


func _on_coupling_changed(_val: float) -> void:
	if _coupling_slider.has_method("get_normalized_value"):
		coupling_strength = _coupling_slider.get_normalized_value() * 3.0


# =========================================================================
# Grid initialization
# =========================================================================

func _init_grids() -> void:
	_stigmergy_grid.clear()
	_basin_grid.clear()
	_flow_field.clear()
	for x in range(grid_resolution):
		var stig_row: Array = []
		stig_row.resize(grid_resolution)
		stig_row.fill(0.0)
		_stigmergy_grid.append(stig_row)

		var basin_row: Array = []
		basin_row.resize(grid_resolution)
		basin_row.fill(-1)
		_basin_grid.append(basin_row)

		var flow_row: Array = []
		flow_row.resize(grid_resolution)
		for y in range(grid_resolution):
			flow_row[y] = Vector2.ZERO
		_flow_field.append(flow_row)


func _world_to_grid(world_pos: Vector2) -> Vector2i:
	var half := field_size * 0.5
	var gx := int((world_pos.x + half) / field_size * grid_resolution)
	var gy := int((world_pos.y + half) / field_size * grid_resolution)
	return Vector2i(clampi(gx, 0, grid_resolution - 1), clampi(gy, 0, grid_resolution - 1))


func _grid_to_world(gx: int, gy: int) -> Vector2:
	var half := field_size * 0.5
	return Vector2(
		-half + (gx + 0.5) / float(grid_resolution) * field_size,
		-half + (gy + 0.5) / float(grid_resolution) * field_size
	)


func _get_stigmergy(pos: Vector2) -> float:
	var g := _world_to_grid(pos)
	return _stigmergy_grid[g.x][g.y]


func _deposit_stigmergy(pos: Vector2, amount: float) -> void:
	var g := _world_to_grid(pos)
	_stigmergy_grid[g.x][g.y] += amount
	# Diffusion to neighbors
	var spread := amount * diffusion_rate
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var nx := g.x + dx
			var ny := g.y + dy
			if nx >= 0 and nx < grid_resolution and ny >= 0 and ny < grid_resolution:
				_stigmergy_grid[nx][ny] += spread / 8.0


func _evaporate_field() -> void:
	var decay := 1.0 - evaporation_rate
	for x in range(grid_resolution):
		for y in range(grid_resolution):
			_stigmergy_grid[x][y] *= decay


# =========================================================================
# Attractors
# =========================================================================

func _spawn_attractors() -> void:
	_attractors.clear()
	var half := field_size * 0.35
	for i in range(num_attractors):
		var angle := float(i) / num_attractors * TAU + 0.4
		var dist := half * (0.6 + randf() * 0.4)
		_attractors.append({
			"pos": Vector2(cos(angle) * dist, sin(angle) * dist),
			"color": BASIN_COLORS[i % BASIN_COLORS.size()],
			"strength": 1.5 + randf() * 1.0,
		})
	_compute_basin_grid()


func _compute_basin_grid() -> void:
	# Assign each grid cell to the attractor it would converge to
	for gx in range(grid_resolution):
		for gy in range(grid_resolution):
			var world := _grid_to_world(gx, gy)
			var best_idx := 0
			var best_potential := INF
			# Compute potential: sum of -strength/distance for each attractor
			# The cell belongs to whichever attractor gives lowest potential
			for ai in range(_attractors.size()):
				var attr: Dictionary = _attractors[ai]
				var dist := world.distance_to(attr["pos"])
				var potential := -attr["strength"] / maxf(dist, 0.1)
				if potential < best_potential:
					best_potential = potential
					best_idx = ai
			_basin_grid[gx][gy] = best_idx

			# Flow field: gradient toward nearest attractor
			var nearest_attr: Dictionary = _attractors[best_idx]
			var dir := (nearest_attr["pos"] - world)
			var d := dir.length()
			if d > 0.01:
				_flow_field[gx][gy] = dir.normalized() * minf(d, 1.0)
			else:
				_flow_field[gx][gy] = Vector2.ZERO


# =========================================================================
# Agents
# =========================================================================

func _spawn_agents() -> void:
	_agents.clear()
	var half := field_size * 0.4
	for i in range(agent_count):
		var pos := Vector2(randf_range(-half, half), randf_range(-half, half))
		_agents.append(AgentState.new(pos))


func _reset_simulation() -> void:
	_init_grids()
	_spawn_attractors()
	_spawn_agents()
	_order_parameter = 0.0
	_order_history = PackedFloat32Array()
	_susceptibility = 0.0
	_temperature = 1.0 if _mode != Mode.PHASE_TRANSITION else 2.0
	_phase_sweep_active = true
	_phase_sweep_dir = -1.0
	_time = 0.0


# =========================================================================
# Process
# =========================================================================

func _process(delta: float) -> void:
	_time += delta

	match _mode:
		Mode.STIGMERGY:
			_update_stigmergy_mode(delta)
		Mode.PHASE_TRANSITION:
			_update_phase_transition_mode(delta)
		Mode.ATTRACTOR_BASINS:
			_update_attractor_basins_mode(delta)

	_update_labels()
	_draw_all()


# =========================================================================
# Stigmergy mode — indirect coordination through environmental deposits
# =========================================================================

func _update_stigmergy_mode(delta: float) -> void:
	_evaporate_field()
	var half := field_size * 0.5

	for i in range(_agents.size()):
		var agent: AgentState = _agents[i]

		# Sense stigmergy gradient (3-antenna model like ants)
		var fwd := Vector2(cos(agent.heading), sin(agent.heading))
		var left := fwd.rotated(-PI * 0.3)
		var right := fwd.rotated(PI * 0.3)
		var sense_dist := 0.5

		var s_fwd := _get_stigmergy(agent.pos + fwd * sense_dist)
		var s_left := _get_stigmergy(agent.pos + left * sense_dist)
		var s_right := _get_stigmergy(agent.pos + right * sense_dist)

		# Turn toward strongest signal
		if s_left > s_fwd and s_left > s_right:
			agent.heading -= 0.4 * delta * agent_speed
		elif s_right > s_fwd and s_right > s_left:
			agent.heading += 0.4 * delta * agent_speed

		# Random wander
		agent.heading += (randf() - 0.5) * noise_level * 2.0 * delta

		# Move
		var vel := Vector2(cos(agent.heading), sin(agent.heading)) * agent_speed
		agent.pos += vel * delta

		# Boundary wrap
		if agent.pos.x < -half: agent.pos.x += field_size
		elif agent.pos.x > half: agent.pos.x -= field_size
		if agent.pos.y < -half: agent.pos.y += field_size
		elif agent.pos.y > half: agent.pos.y -= field_size

		# Deposit pheromone/signal
		_deposit_stigmergy(agent.pos, deposit_rate * delta)

	# Compute order parameter: how clustered are agents?
	_compute_order_parameter_clustering()


# =========================================================================
# Phase transition mode — Ising-like spin alignment with temperature sweep
# =========================================================================

func _update_phase_transition_mode(delta: float) -> void:
	var half := field_size * 0.5

	# Sweep temperature slowly
	if _phase_sweep_active:
		_temperature += _phase_sweep_dir * delta * 0.08
		if _temperature < 0.05:
			_temperature = 0.05
			_phase_sweep_dir = 1.0
		elif _temperature > 2.0:
			_temperature = 2.0
			_phase_sweep_dir = -1.0

	# Ising-like dynamics: each agent's spin influenced by neighbors
	for i in range(_agents.size()):
		var agent: AgentState = _agents[i]

		# Compute local field from neighbors
		var local_field := 0.0
		var neighbor_count := 0
		for j in range(_agents.size()):
			if j == i:
				continue
			var other: AgentState = _agents[j]
			var dist := agent.pos.distance_to(other.pos)
			if dist < 1.5:
				local_field += other.spin * coupling_strength / maxf(dist, 0.3)
				neighbor_count += 1

		# Metropolis-like spin flip: probability based on energy difference
		var delta_energy := 2.0 * agent.spin * local_field
		if delta_energy < 0.0 or randf() < exp(-delta_energy / maxf(_temperature, 0.01)):
			agent.spin = -agent.spin

		# Gentle drift to visualize clusters
		if neighbor_count > 0:
			# Move slightly toward same-spin neighbors
			var drift := Vector2.ZERO
			for j in range(_agents.size()):
				if j == i:
					continue
				var other: AgentState = _agents[j]
				var dist := agent.pos.distance_to(other.pos)
				if dist < 2.0 and other.spin == agent.spin:
					drift += (other.pos - agent.pos).normalized() * 0.1
				elif dist < 0.5:
					drift += (agent.pos - other.pos).normalized() * 0.3  # repel if too close
			agent.pos += drift * delta

		# Keep in bounds
		agent.pos.x = clampf(agent.pos.x, -half, half)
		agent.pos.y = clampf(agent.pos.y, -half, half)

	# Order parameter: magnetization |<spin>|
	var total_spin := 0.0
	for agent in _agents:
		total_spin += agent.spin
	var new_order := absf(total_spin) / float(_agents.size())

	# Track susceptibility (variance of order parameter ≈ |dM/dT|)
	var prev_order := _order_parameter
	_order_parameter = new_order
	_susceptibility = absf(new_order - prev_order) / maxf(delta, 0.001)
	_susceptibility = clampf(_susceptibility, 0.0, 5.0)

	# Record history for graph (limit to 200 samples)
	_order_history.append(_order_parameter)
	if _order_history.size() > 200:
		# Trim old entries
		var trimmed := PackedFloat32Array()
		for idx in range(1, _order_history.size()):
			trimmed.append(_order_history[idx])
		_order_history = trimmed


# =========================================================================
# Attractor basins mode — flow field and convergence visualization
# =========================================================================

func _update_attractor_basins_mode(delta: float) -> void:
	var half := field_size * 0.5

	for i in range(_agents.size()):
		var agent: AgentState = _agents[i]

		# Compute force from all attractors (gradient descent on potential)
		var force := Vector2.ZERO
		var best_attr := 0
		var best_pull := 0.0
		for ai in range(_attractors.size()):
			var attr: Dictionary = _attractors[ai]
			var dir := attr["pos"] - agent.pos
			var dist := dir.length()
			var pull := attr["strength"] / maxf(dist * dist, 0.1)
			force += dir.normalized() * pull
			if pull > best_pull:
				best_pull = pull
				best_attr = ai
		agent.basin_id = best_attr

		# Add noise for exploration
		force += Vector2(randf() - 0.5, randf() - 0.5) * noise_level * 2.0

		# Move
		agent.pos += force.normalized() * agent_speed * delta

		# Boundary clamp
		agent.pos.x = clampf(agent.pos.x, -half, half)
		agent.pos.y = clampf(agent.pos.y, -half, half)

		# When agent reaches attractor, respawn at random position
		for ai in range(_attractors.size()):
			var attr: Dictionary = _attractors[ai]
			if agent.pos.distance_to(attr["pos"]) < 0.25:
				agent.pos = Vector2(randf_range(-half, half), randf_range(-half, half))
				agent.basin_id = -1
				break

	# Compute order parameter: fraction of agents near their attractor
	var near_count := 0
	for agent in _agents:
		if agent.basin_id >= 0 and agent.basin_id < _attractors.size():
			var attr: Dictionary = _attractors[agent.basin_id]
			if agent.pos.distance_to(attr["pos"]) < 1.5:
				near_count += 1
	_order_parameter = float(near_count) / float(maxf(_agents.size(), 1))


# =========================================================================
# Order parameter computation (clustering metric for stigmergy mode)
# =========================================================================

func _compute_order_parameter_clustering() -> void:
	# Measure alignment: average cosine of heading differences with neighbors
	var total_alignment := 0.0
	var pairs := 0
	for i in range(_agents.size()):
		var ai: AgentState = _agents[i]
		for j in range(i + 1, mini(_agents.size(), i + 10)):
			var aj: AgentState = _agents[j]
			var dist := ai.pos.distance_to(aj.pos)
			if dist < 1.5:
				total_alignment += cos(ai.heading - aj.heading)
				pairs += 1
	if pairs > 0:
		_order_parameter = (total_alignment / float(pairs) + 1.0) * 0.5
	else:
		_order_parameter = 0.5


# =========================================================================
# Drawing
# =========================================================================

func _draw_all() -> void:
	match _mode:
		Mode.STIGMERGY:
			_draw_stigmergy_field()
			_draw_agents_stigmergy()
			_draw_empty(_overlay_im)
			_draw_empty(_flow_im)
			_draw_order_bar()
		Mode.PHASE_TRANSITION:
			_draw_empty(_field_im)
			_draw_agents_ising()
			_draw_empty(_overlay_im)
			_draw_empty(_flow_im)
			_draw_phase_graph()
		Mode.ATTRACTOR_BASINS:
			_draw_empty(_field_im)
			_draw_basin_coloring()
			_draw_flow_arrows()
			_draw_agents_basins()
			_draw_order_bar()


func _draw_empty(im: ImmediateMesh) -> void:
	im.clear_surfaces()


# --- Stigmergy field heatmap ---

func _draw_stigmergy_field() -> void:
	_field_im.clear_surfaces()

	var max_val := 0.01
	for x in range(grid_resolution):
		for y in range(grid_resolution):
			max_val = maxf(max_val, _stigmergy_grid[x][y])

	var cell_w := field_size / float(grid_resolution)
	var half := field_size * 0.5

	_field_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in range(grid_resolution):
		for y in range(grid_resolution):
			var val: float = _stigmergy_grid[x][y]
			if val < 0.01:
				continue

			var t := clampf(val / max_val, 0.0, 1.0)
			var col := _sample_stig_color(t)

			var wx := -half + x * cell_w
			var wy := -half + y * cell_w
			var z := -0.01

			_field_im.surface_set_color(col)
			_field_im.surface_add_vertex(Vector3(wx, wy, z))
			_field_im.surface_add_vertex(Vector3(wx + cell_w, wy, z))
			_field_im.surface_add_vertex(Vector3(wx + cell_w, wy + cell_w, z))

			_field_im.surface_set_color(col)
			_field_im.surface_add_vertex(Vector3(wx, wy, z))
			_field_im.surface_add_vertex(Vector3(wx + cell_w, wy + cell_w, z))
			_field_im.surface_add_vertex(Vector3(wx, wy + cell_w, z))

	_field_im.surface_end()


func _sample_stig_color(t: float) -> Color:
	var n := STIG_COLORS.size() - 1
	var idx := t * n
	var lo := int(floorf(idx))
	var hi := mini(lo + 1, n)
	var frac := idx - lo
	return STIG_COLORS[lo].lerp(STIG_COLORS[hi], frac)


# --- Agents in stigmergy mode (directional diamonds) ---

func _draw_agents_stigmergy() -> void:
	_agents_im.clear_surfaces()
	_agents_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for agent in _agents:
		var fwd := Vector2(cos(agent.heading), sin(agent.heading))
		var side := fwd.rotated(PI * 0.5)
		var r := 0.08
		var p := agent.pos
		var z := 0.05

		var front := p + fwd * r * 1.8
		var back := p - fwd * r
		var left := p + side * r * 0.7
		var right := p - side * r * 0.7

		var col := COL_AGENT_ALIGNED.lerp(COL_AGENT_RANDOM, noise_level)
		_agents_im.surface_set_color(col)
		_agents_im.surface_add_vertex(Vector3(front.x, front.y, z))
		_agents_im.surface_add_vertex(Vector3(left.x, left.y, z))
		_agents_im.surface_add_vertex(Vector3(back.x, back.y, z))

		_agents_im.surface_set_color(col)
		_agents_im.surface_add_vertex(Vector3(front.x, front.y, z))
		_agents_im.surface_add_vertex(Vector3(back.x, back.y, z))
		_agents_im.surface_add_vertex(Vector3(right.x, right.y, z))

	_agents_im.surface_end()


# --- Agents in Ising/phase transition mode (colored by spin) ---

func _draw_agents_ising() -> void:
	_agents_im.clear_surfaces()
	_agents_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for agent in _agents:
		var r := 0.1
		var p := agent.pos
		var z := 0.05
		var col: Color
		if agent.spin > 0:
			col = COL_AGENT_ALIGNED
		else:
			col = COL_AGENT_RANDOM

		# Draw as hexagon
		var segments := 6
		for si in range(segments):
			var a0 := float(si) / segments * TAU
			var a1 := float(si + 1) / segments * TAU
			_agents_im.surface_set_color(col)
			_agents_im.surface_add_vertex(Vector3(p.x, p.y, z))
			_agents_im.surface_add_vertex(Vector3(p.x + cos(a0) * r, p.y + sin(a0) * r, z))
			_agents_im.surface_add_vertex(Vector3(p.x + cos(a1) * r, p.y + sin(a1) * r, z))

	_agents_im.surface_end()


# --- Agents in attractor basins mode (colored by basin) ---

func _draw_agents_basins() -> void:
	_agents_im.clear_surfaces()
	_agents_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for agent in _agents:
		var r := 0.08
		var p := agent.pos
		var z := 0.08
		var col: Color
		if agent.basin_id >= 0 and agent.basin_id < BASIN_COLORS.size():
			col = BASIN_COLORS[agent.basin_id]
			col.a = 1.0
		else:
			col = Color(0.6, 0.6, 0.6)

		# Diamond shape
		_agents_im.surface_set_color(col)
		_agents_im.surface_add_vertex(Vector3(p.x, p.y + r, z))
		_agents_im.surface_add_vertex(Vector3(p.x - r * 0.7, p.y, z))
		_agents_im.surface_add_vertex(Vector3(p.x, p.y - r, z))

		_agents_im.surface_set_color(col)
		_agents_im.surface_add_vertex(Vector3(p.x, p.y + r, z))
		_agents_im.surface_add_vertex(Vector3(p.x, p.y - r, z))
		_agents_im.surface_add_vertex(Vector3(p.x + r * 0.7, p.y, z))

	_agents_im.surface_end()


# --- Basin coloring (Voronoi-like regions) ---

func _draw_basin_coloring() -> void:
	_overlay_im.clear_surfaces()
	_overlay_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var cell_w := field_size / float(grid_resolution)
	var half := field_size * 0.5

	for gx in range(grid_resolution):
		for gy in range(grid_resolution):
			var basin_id: int = _basin_grid[gx][gy]
			if basin_id < 0:
				continue

			var col: Color = BASIN_COLORS[basin_id % BASIN_COLORS.size()]

			# Darken cells near boundaries between basins
			var on_boundary := false
			for dx in [-1, 1]:
				var nx := gx + dx
				if nx >= 0 and nx < grid_resolution and _basin_grid[nx][gy] != basin_id:
					on_boundary = true
					break
			if not on_boundary:
				for dy in [-1, 1]:
					var ny := gy + dy
					if ny >= 0 and ny < grid_resolution and _basin_grid[gx][ny] != basin_id:
						on_boundary = true
						break

			if on_boundary:
				col = col.lerp(Color(1.0, 1.0, 1.0, 0.6), 0.5)

			var wx := -half + gx * cell_w
			var wy := -half + gy * cell_w
			var z := -0.02

			_overlay_im.surface_set_color(col)
			_overlay_im.surface_add_vertex(Vector3(wx, wy, z))
			_overlay_im.surface_add_vertex(Vector3(wx + cell_w, wy, z))
			_overlay_im.surface_add_vertex(Vector3(wx + cell_w, wy + cell_w, z))

			_overlay_im.surface_set_color(col)
			_overlay_im.surface_add_vertex(Vector3(wx, wy, z))
			_overlay_im.surface_add_vertex(Vector3(wx + cell_w, wy + cell_w, z))
			_overlay_im.surface_add_vertex(Vector3(wx, wy + cell_w, z))

	# Draw attractor centers as bright circles
	for ai in range(_attractors.size()):
		var attr: Dictionary = _attractors[ai]
		var pos := attr["pos"]
		var col: Color = attr["color"]
		col.a = 0.9
		var r := 0.2 + sin(_time * 2.0 + ai) * 0.04
		var segments := 10
		for si in range(segments):
			var a0 := float(si) / segments * TAU
			var a1 := float(si + 1) / segments * TAU
			_overlay_im.surface_set_color(col)
			_overlay_im.surface_add_vertex(Vector3(pos.x, pos.y, 0.03))
			_overlay_im.surface_add_vertex(Vector3(pos.x + cos(a0) * r, pos.y + sin(a0) * r, 0.03))
			_overlay_im.surface_add_vertex(Vector3(pos.x + cos(a1) * r, pos.y + sin(a1) * r, 0.03))

	_overlay_im.surface_end()


# --- Flow field arrows ---

func _draw_flow_arrows() -> void:
	_flow_im.clear_surfaces()
	_flow_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var step := maxi(grid_resolution / 12, 1)
	var arrow_len := field_size / float(grid_resolution) * step * 0.6

	for gx in range(0, grid_resolution, step):
		for gy in range(0, grid_resolution, step):
			var flow: Vector2 = _flow_field[gx][gy]
			if flow.length_squared() < 0.001:
				continue

			var world := _grid_to_world(gx, gy)
			var dir := flow.normalized()
			var perp := dir.rotated(PI * 0.5)
			var z := 0.04

			var tip := world + dir * arrow_len
			var base_l := world + perp * arrow_len * 0.25
			var base_r := world - perp * arrow_len * 0.25

			var basin_id: int = _basin_grid[gx][gy]
			var col: Color = BASIN_COLORS[basin_id % BASIN_COLORS.size()]
			col.a = 0.55

			_flow_im.surface_set_color(col)
			_flow_im.surface_add_vertex(Vector3(tip.x, tip.y, z))
			_flow_im.surface_add_vertex(Vector3(base_l.x, base_l.y, z))
			_flow_im.surface_add_vertex(Vector3(base_r.x, base_r.y, z))

	_flow_im.surface_end()


# --- Order parameter bar (bottom-right) ---

func _draw_order_bar() -> void:
	_graph_im.clear_surfaces()
	_graph_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var bar_x := field_size * 0.5 + 0.3
	var bar_y := -field_size * 0.5
	var bar_w := 0.3
	var bar_h := field_size * 0.8
	var z := 0.0

	# Background
	var bg := Color(0.15, 0.15, 0.2, 0.5)
	_graph_im.surface_set_color(bg)
	_graph_im.surface_add_vertex(Vector3(bar_x, bar_y, z))
	_graph_im.surface_add_vertex(Vector3(bar_x + bar_w, bar_y, z))
	_graph_im.surface_add_vertex(Vector3(bar_x + bar_w, bar_y + bar_h, z))
	_graph_im.surface_set_color(bg)
	_graph_im.surface_add_vertex(Vector3(bar_x, bar_y, z))
	_graph_im.surface_add_vertex(Vector3(bar_x + bar_w, bar_y + bar_h, z))
	_graph_im.surface_add_vertex(Vector3(bar_x, bar_y + bar_h, z))

	# Filled portion
	var fill_h := bar_h * _order_parameter
	var col := COL_ORDER_LINE.lerp(COL_TRANSITION, 1.0 - _order_parameter)
	col.a = 0.8
	_graph_im.surface_set_color(col)
	_graph_im.surface_add_vertex(Vector3(bar_x, bar_y, z + 0.01))
	_graph_im.surface_add_vertex(Vector3(bar_x + bar_w, bar_y, z + 0.01))
	_graph_im.surface_add_vertex(Vector3(bar_x + bar_w, bar_y + fill_h, z + 0.01))
	_graph_im.surface_set_color(col)
	_graph_im.surface_add_vertex(Vector3(bar_x, bar_y, z + 0.01))
	_graph_im.surface_add_vertex(Vector3(bar_x + bar_w, bar_y + fill_h, z + 0.01))
	_graph_im.surface_add_vertex(Vector3(bar_x, bar_y + fill_h, z + 0.01))

	_graph_im.surface_end()


# --- Phase transition graph (order parameter vs temperature) ---

func _draw_phase_graph() -> void:
	_graph_im.clear_surfaces()
	if _order_history.size() < 2:
		return

	_graph_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	# Graph area
	var gx := -field_size * 0.5 - 2.5
	var gy := -field_size * 0.5
	var gw := 2.0
	var gh := field_size * 0.8
	var z := 0.0

	# Background
	var bg := Color(0.1, 0.1, 0.15, 0.5)
	_graph_im.surface_set_color(bg)
	_graph_im.surface_add_vertex(Vector3(gx, gy, z))
	_graph_im.surface_add_vertex(Vector3(gx + gw, gy, z))
	_graph_im.surface_add_vertex(Vector3(gx + gw, gy + gh, z))
	_graph_im.surface_set_color(bg)
	_graph_im.surface_add_vertex(Vector3(gx, gy, z))
	_graph_im.surface_add_vertex(Vector3(gx + gw, gy + gh, z))
	_graph_im.surface_add_vertex(Vector3(gx, gy + gh, z))

	# Plot order parameter history as line segments (as thin quads)
	var n := _order_history.size()
	var line_w := 0.02
	for i in range(n - 1):
		var x0 := gx + float(i) / float(n) * gw
		var x1 := gx + float(i + 1) / float(n) * gw
		var y0 := gy + _order_history[i] * gh
		var y1 := gy + _order_history[i + 1] * gh

		var col := COL_ORDER_LINE
		_graph_im.surface_set_color(col)
		_graph_im.surface_add_vertex(Vector3(x0, y0 - line_w, z + 0.01))
		_graph_im.surface_add_vertex(Vector3(x1, y1 + line_w, z + 0.01))
		_graph_im.surface_add_vertex(Vector3(x1, y1 - line_w, z + 0.01))
		_graph_im.surface_set_color(col)
		_graph_im.surface_add_vertex(Vector3(x0, y0 - line_w, z + 0.01))
		_graph_im.surface_add_vertex(Vector3(x0, y0 + line_w, z + 0.01))
		_graph_im.surface_add_vertex(Vector3(x1, y1 + line_w, z + 0.01))

	# Temperature indicator line (vertical at current position)
	var temp_x := gx + gw  # rightmost = current
	var temp_h := (_temperature / 2.0) * gh
	var tcol := COL_SUSCEPT_LINE
	tcol.a = 0.6
	_graph_im.surface_set_color(tcol)
	_graph_im.surface_add_vertex(Vector3(temp_x - 0.02, gy, z + 0.02))
	_graph_im.surface_add_vertex(Vector3(temp_x + 0.02, gy, z + 0.02))
	_graph_im.surface_add_vertex(Vector3(temp_x + 0.02, gy + temp_h, z + 0.02))
	_graph_im.surface_set_color(tcol)
	_graph_im.surface_add_vertex(Vector3(temp_x - 0.02, gy, z + 0.02))
	_graph_im.surface_add_vertex(Vector3(temp_x + 0.02, gy + temp_h, z + 0.02))
	_graph_im.surface_add_vertex(Vector3(temp_x - 0.02, gy + temp_h, z + 0.02))

	_graph_im.surface_end()


# =========================================================================
# Labels
# =========================================================================

func _update_labels() -> void:
	var mode_names := ["Stigmergy", "Phase Transition", "Attractor Basins"]
	_mode_label.text = "Mode: %s" % mode_names[_mode]

	match _mode:
		Mode.STIGMERGY:
			_info_label.text = "Agents: %d\nDeposit: %.1f\nEvaporation: %.3f\nDiffusion: %.2f" % [
				agent_count, deposit_rate, evaporation_rate, diffusion_rate
			]
			_stats_label.text = "Order: %.2f\nNoise: %.2f\nCoupling: %.1f" % [
				_order_parameter, noise_level, coupling_strength
			]
		Mode.PHASE_TRANSITION:
			_info_label.text = "Agents: %d\nTemperature: %.3f\nCoupling: %.1f\nSweep: %s" % [
				agent_count, _temperature, coupling_strength,
				"ON" if _phase_sweep_active else "OFF"
			]
			_stats_label.text = "Order |M|: %.3f\nSusceptibility: %.2f\n%s" % [
				_order_parameter, _susceptibility,
				"ORDERED" if _order_parameter > 0.7 else ("CRITICAL" if _order_parameter > 0.3 else "DISORDERED")
			]
		Mode.ATTRACTOR_BASINS:
			_info_label.text = "Agents: %d\nAttractors: %d\nNoise: %.2f" % [
				agent_count, num_attractors, noise_level
			]
			_stats_label.text = "Convergence: %.0f%%\nBasins: %d" % [
				_order_parameter * 100.0, num_attractors
			]


# =========================================================================
# apply_grid_config
# =========================================================================

func apply_grid_config(config: Dictionary) -> void:
	if config.has("agent_count"):
		agent_count = int(config["agent_count"])
	if config.has("grid_resolution"):
		grid_resolution = int(config["grid_resolution"])
	if config.has("field_size"):
		field_size = float(config["field_size"])
	if config.has("agent_speed"):
		agent_speed = float(config["agent_speed"])
	if config.has("deposit_rate"):
		deposit_rate = float(config["deposit_rate"])
	if config.has("evaporation_rate"):
		evaporation_rate = float(config["evaporation_rate"])
	if config.has("diffusion_rate"):
		diffusion_rate = float(config["diffusion_rate"])
	if config.has("coupling_strength"):
		coupling_strength = float(config["coupling_strength"])
	if config.has("noise_level"):
		noise_level = float(config["noise_level"])
	if config.has("num_attractors"):
		num_attractors = int(config["num_attractors"])
	if config.has("mode"):
		var m: String = str(config["mode"]).to_upper()
		match m:
			"STIGMERGY": _mode = Mode.STIGMERGY
			"PHASE_TRANSITION": _mode = Mode.PHASE_TRANSITION
			"ATTRACTOR_BASINS": _mode = Mode.ATTRACTOR_BASINS

	_reset_simulation()
