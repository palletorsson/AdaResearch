# ===========================================================================
# AntColonyOptimization — Pheromone Heatmap & Multi-Source Foraging
# Ant colony optimization with pheromone evaporation gradient heatmap,
# multiple food sources with quality ratings, and realistic ant communication.
# Elevated features:
#   - ImmediateMesh pheromone evaporation gradient heatmap (cool→hot color ramp)
#   - Multiple food sources with quality ratings affecting pheromone deposit
#   - Realistic ant communication: tandem running, recruitment signals
#   - Configurable via apply_grid_config()
# License: CC BY-NC-SA 3.0 derivative
# ===========================================================================

class_name AntColonyOptimization
extends Node3D

# @identity
# essence: τ_ij(t+1) = (1-ρ)·τ_ij(t) + Σ_k(Δτ^k_ij) where Δτ ∝ food_quality — pheromone is collective memory that decays
# desire: to watch a trail appear between nest and food and feel the growing certainty of a route no ant planned — to see decision crystallize from repetition
# critical_parameter: evaporation_rate — near zero, old bad paths persist forever and the colony gets stuck; near 0.1, trails fade fast enough for rerouting but the field looks chaotic
# triggers: switching to MULTI_SOURCE mode reveals quality-weighted convergence: high-value food gets a brighter, wider trail even if it's farther away
# emerges: tandem-running pairs form spontaneously in COMMUNICATION mode, linking experienced and naive ants into temporary teacher-student dyads
# needs: [has] VR slider for evaporation rate and ant count; [has] mode cycle button and reset button; [missing] no slider for pheromone deposit strength or alpha/beta weights
# relationships: depends on pheromone stigmergy discovered in stigmergy_grid; AntColonyV2 is the large-scale terrain version; unlocks understanding of why shortest paths win (positive feedback)
# truth: the shortest path is not chosen — it is amplified; the colony is a distributed reinforcement learning system running on chemistry

## Ant Colony Optimization with pheromone gradient heatmap.
## COLONY mode shows standard ACO foraging with evaporation heatmap.
## COMMUNICATION mode highlights tandem running and recruitment signals.
## MULTI_SOURCE mode shows quality-weighted multi-source foraging.

# --- Configuration ---
@export var ant_count: int = 40
@export var grid_resolution: int = 32
@export var field_size: float = 6.0
@export var evaporation_rate: float = 0.02
@export var pheromone_deposit: float = 5.0
@export var alpha_weight: float = 1.0   # Pheromone importance
@export var beta_weight: float = 2.0    # Distance importance
@export var ant_speed: float = 3.0
@export var food_source_count: int = 4

# --- Mode ---
enum Mode { COLONY, COMMUNICATION, MULTI_SOURCE }
var _mode: int = Mode.COLONY

# --- Internal state ---
var _time: float = 0.0
var _pheromone_grid: Array = []   # 2D array of floats
var _ants: Array = []
var _food_sources: Array = []     # Array of {pos: Vector2, quality: float, remaining: float}
var _nest_pos: Vector2 = Vector2.ZERO
var _stats_food_collected: int = 0
var _stats_active_foragers: int = 0

# Communication state
var _recruitment_signals: Array = []   # {pos: Vector2, strength: float, target_food: int}
var _tandem_pairs: Array = []          # {leader: int, follower: int, progress: float}

# --- Rendering ---
var _heatmap_im: ImmediateMesh
var _heatmap_mi: MeshInstance3D
var _ants_im: ImmediateMesh
var _ants_mi: MeshInstance3D
var _trails_im: ImmediateMesh
var _trails_mi: MeshInstance3D
var _food_im: ImmediateMesh
var _food_mi: MeshInstance3D
var _nest_im: ImmediateMesh
var _nest_mi: MeshInstance3D
var _signals_im: ImmediateMesh
var _signals_mi: MeshInstance3D

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
var _evap_slider: Node3D
var _count_slider: Node3D

# Colors
const COL_NEST := Color(0.6, 0.4, 0.2)
const COL_NEST_GLOW := Color(0.8, 0.55, 0.3)
const COL_ANT_SEARCH := Color(0.85, 0.25, 0.15)
const COL_ANT_RETURN := Color(0.2, 0.85, 0.25)
const COL_ANT_TANDEM := Color(0.95, 0.85, 0.15)
const COL_FOOD_HIGH := Color(0.15, 0.95, 0.3)
const COL_FOOD_LOW := Color(0.6, 0.8, 0.2)
const COL_FOOD_DEPLETED := Color(0.4, 0.4, 0.4, 0.4)
const COL_SIGNAL := Color(1.0, 0.8, 0.2, 0.5)
const COL_TRAIL := Color(0.9, 0.6, 0.1, 0.6)

# Heatmap color ramp (cool → hot)
const HEATMAP_COLORS: Array = [
	Color(0.05, 0.05, 0.2, 0.0),    # zero — transparent dark blue
	Color(0.1, 0.15, 0.5, 0.3),     # low — deep blue
	Color(0.1, 0.5, 0.7, 0.5),      # medium-low — cyan
	Color(0.2, 0.8, 0.3, 0.65),     # medium — green
	Color(0.9, 0.85, 0.1, 0.8),     # medium-high — yellow
	Color(1.0, 0.5, 0.05, 0.9),     # high — orange
	Color(1.0, 0.15, 0.05, 1.0),    # very high — red
]

# Ant inner class
class AntState:
	var pos: Vector2
	var vel: Vector2
	var has_food: bool = false
	var food_quality: float = 0.0
	var target_food_idx: int = -1
	var path: PackedVector2Array = PackedVector2Array()
	var wander_angle: float = 0.0
	var is_tandem_leader: bool = false
	var is_tandem_follower: bool = false
	var recruit_cooldown: float = 0.0

	func _init(start: Vector2) -> void:
		pos = start
		vel = Vector2(randf() - 0.5, randf() - 0.5).normalized() * 0.5
		wander_angle = randf() * TAU


func _ready() -> void:
	_create_materials()
	_create_mesh_instances()
	_create_labels()
	_create_vr_controls()
	_init_pheromone_grid()
	_spawn_food_sources()
	_spawn_ants()


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
	_heatmap_im = ImmediateMesh.new()
	_heatmap_mi = MeshInstance3D.new()
	_heatmap_mi.mesh = _heatmap_im
	_heatmap_mi.material_override = _mat_alpha
	add_child(_heatmap_mi)

	_trails_im = ImmediateMesh.new()
	_trails_mi = MeshInstance3D.new()
	_trails_mi.mesh = _trails_im
	_trails_mi.material_override = _mat_alpha
	add_child(_trails_mi)

	_food_im = ImmediateMesh.new()
	_food_mi = MeshInstance3D.new()
	_food_mi.mesh = _food_im
	_food_mi.material_override = _mat_unshaded
	add_child(_food_mi)

	_nest_im = ImmediateMesh.new()
	_nest_mi = MeshInstance3D.new()
	_nest_mi.mesh = _nest_im
	_nest_mi.material_override = _mat_unshaded
	add_child(_nest_mi)

	_ants_im = ImmediateMesh.new()
	_ants_mi = MeshInstance3D.new()
	_ants_mi.mesh = _ants_im
	_ants_mi.material_override = _mat_unshaded
	add_child(_ants_mi)

	_signals_im = ImmediateMesh.new()
	_signals_mi = MeshInstance3D.new()
	_signals_mi.mesh = _signals_im
	_signals_mi.material_override = _mat_alpha
	add_child(_signals_mi)


# =========================================================================
# Labels
# =========================================================================

func _create_labels() -> void:
	_title_label = Label3D.new()
	_title_label.text = "Ant Colony Optimization"
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

	# Evaporation rate slider
	_evap_slider = SLIDER_SCENE.instantiate()
	_evap_slider.position = Vector3(1.2, ctrl_y, 0)
	add_child(_evap_slider)
	if _evap_slider.has_method("set_param_name"):
		_evap_slider.set_param_name("Evaporation")
	if _evap_slider.has_method("set_normalized_value"):
		_evap_slider.set_normalized_value(evaporation_rate / 0.1)
	if _evap_slider.has_signal("slider_moved"):
		_evap_slider.slider_moved.connect(_on_evap_changed)

	# Ant count slider
	_count_slider = SLIDER_SCENE.instantiate()
	_count_slider.position = Vector3(3.0, ctrl_y, 0)
	add_child(_count_slider)
	if _count_slider.has_method("set_param_name"):
		_count_slider.set_param_name("Ants")
	if _count_slider.has_method("set_normalized_value"):
		_count_slider.set_normalized_value(float(ant_count) / 80.0)
	if _count_slider.has_signal("slider_moved"):
		_count_slider.slider_moved.connect(_on_count_changed)


func _on_mode_pressed() -> void:
	_mode = (_mode + 1) % 3
	_update_labels()


func _on_reset_pressed() -> void:
	_reset_colony()


func _on_evap_changed(_val: float) -> void:
	if _evap_slider.has_method("get_normalized_value"):
		evaporation_rate = _evap_slider.get_normalized_value() * 0.1


func _on_count_changed(_val: float) -> void:
	if _count_slider.has_method("get_normalized_value"):
		var new_count := int(_count_slider.get_normalized_value() * 80.0)
		new_count = clampi(new_count, 5, 80)
		if new_count != ant_count:
			ant_count = new_count
			_spawn_ants()


# =========================================================================
# Pheromone grid
# =========================================================================

func _init_pheromone_grid() -> void:
	_pheromone_grid.clear()
	for x in range(grid_resolution):
		var row: Array = []
		row.resize(grid_resolution)
		row.fill(0.0)
		_pheromone_grid.append(row)


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


func _get_pheromone(pos: Vector2) -> float:
	var g := _world_to_grid(pos)
	return _pheromone_grid[g.x][g.y]


func _deposit_pheromone(pos: Vector2, amount: float) -> void:
	var g := _world_to_grid(pos)
	_pheromone_grid[g.x][g.y] += amount
	# Spread to neighbors (diffusion)
	var spread := amount * 0.15
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var nx: int = g.x + dx
			var ny: int = g.y + dy
			if nx >= 0 and nx < grid_resolution and ny >= 0 and ny < grid_resolution:
				_pheromone_grid[nx][ny] += spread / 8.0


func _evaporate_pheromones() -> void:
	var decay := 1.0 - evaporation_rate
	for x in range(grid_resolution):
		for y in range(grid_resolution):
			_pheromone_grid[x][y] *= decay


# =========================================================================
# Food sources
# =========================================================================

func _spawn_food_sources() -> void:
	_food_sources.clear()
	var half := field_size * 0.4
	for i in range(food_source_count):
		var angle := (float(i) / food_source_count) * TAU + 0.3
		var dist := half * (0.5 + randf() * 0.5)
		var quality := 0.3 + randf() * 0.7  # quality 0.3 to 1.0
		_food_sources.append({
			"pos": Vector2(cos(angle) * dist, sin(angle) * dist),
			"quality": quality,
			"remaining": 50.0 + quality * 100.0,
			"initial": 50.0 + quality * 100.0,
		})


# =========================================================================
# Ants
# =========================================================================

func _spawn_ants() -> void:
	_ants.clear()
	_tandem_pairs.clear()
	for i in range(ant_count):
		var a := AntState.new(_nest_pos)
		a.wander_angle = randf() * TAU
		_ants.append(a)


func _reset_colony() -> void:
	_init_pheromone_grid()
	_spawn_food_sources()
	_spawn_ants()
	_recruitment_signals.clear()
	_tandem_pairs.clear()
	_stats_food_collected = 0
	_time = 0.0


# =========================================================================
# Process
# =========================================================================

func _process(delta: float) -> void:
	_time += delta
	_evaporate_pheromones()
	_update_ants(delta)
	_update_recruitment_signals(delta)
	if _mode == Mode.COMMUNICATION:
		_update_tandem_pairs(delta)
	_update_labels()
	_draw_all()


# =========================================================================
# Ant update logic
# =========================================================================

func _update_ants(delta: float) -> void:
	_stats_active_foragers = 0
	var half := field_size * 0.5

	for i in range(_ants.size()):
		var ant: AntState = _ants[i]
		ant.recruit_cooldown = maxf(ant.recruit_cooldown - delta, 0.0)

		if ant.is_tandem_follower:
			continue  # movement handled by tandem pair logic

		if ant.has_food:
			# Return to nest
			var to_nest := (_nest_pos - ant.pos)
			var dist_nest := to_nest.length()
			if dist_nest < 0.2:
				# Arrived at nest
				ant.has_food = false
				_stats_food_collected += 1
				# Deposit pheromone along path (stronger for higher quality food)
				var deposit_amount := pheromone_deposit * ant.food_quality
				var path_len := ant.path.size()
				for pi in range(path_len):
					# More pheromone near food, less near nest (inverse distance weighting)
					var weight := float(pi + 1) / float(path_len)
					_deposit_pheromone(ant.path[pi], deposit_amount * weight / float(path_len) * 10.0)
				ant.path = PackedVector2Array()
				# Communication: emit recruitment signal
				if _mode == Mode.COMMUNICATION and ant.food_quality > 0.5 and ant.recruit_cooldown <= 0.0:
					_recruitment_signals.append({
						"pos": _nest_pos,
						"strength": ant.food_quality,
						"target_food": ant.target_food_idx,
						"radius": 0.0,
					})
					ant.recruit_cooldown = 3.0
			else:
				var move_dir := to_nest.normalized()
				ant.pos += move_dir * ant_speed * delta
				ant.path.append(ant.pos)
				_deposit_pheromone(ant.pos, pheromone_deposit * 0.05 * ant.food_quality)
		else:
			_stats_active_foragers += 1
			# Forage: follow pheromone gradient + random wander
			var best_dir := _sense_pheromone(ant)
			# Random wander component
			ant.wander_angle += (randf() - 0.5) * 2.0 * delta
			var wander_dir := Vector2(cos(ant.wander_angle), sin(ant.wander_angle))
			# Blend pheromone attraction with wander
			var pheromone_strength := _get_pheromone(ant.pos)
			var blend := clampf(pheromone_strength / 5.0, 0.0, 0.7)
			var move_dir := (best_dir * blend + wander_dir * (1.0 - blend)).normalized()
			ant.pos += move_dir * ant_speed * delta
			ant.path.append(ant.pos)

			# Keep in bounds
			ant.pos.x = clampf(ant.pos.x, -half, half)
			ant.pos.y = clampf(ant.pos.y, -half, half)
			if absf(ant.pos.x) >= half or absf(ant.pos.y) >= half:
				ant.wander_angle += PI * 0.5

			# Check food sources
			for fi in range(_food_sources.size()):
				var food: Dictionary = _food_sources[fi]
				if food["remaining"] <= 0.0:
					continue
				var dist_food := ant.pos.distance_to(food["pos"])
				if dist_food < 0.4:
					ant.has_food = true
					ant.food_quality = food["quality"]
					ant.target_food_idx = fi
					food["remaining"] -= 1.0
					break

			# In MULTI_SOURCE mode, ants prefer higher quality sources
			if _mode == Mode.MULTI_SOURCE and not ant.has_food:
				_bias_toward_quality(ant)


func _sense_pheromone(ant: AntState) -> Vector2:
	# Sample pheromone in 3 directions (left, forward, right) like real ants
	var fwd := Vector2(cos(ant.wander_angle), sin(ant.wander_angle))
	var left := fwd.rotated(-PI * 0.25)
	var right := fwd.rotated(PI * 0.25)
	var sense_dist := 0.4

	var p_fwd := _get_pheromone(ant.pos + fwd * sense_dist)
	var p_left := _get_pheromone(ant.pos + left * sense_dist)
	var p_right := _get_pheromone(ant.pos + right * sense_dist)

	# Weight by alpha
	p_fwd = pow(p_fwd + 0.01, alpha_weight)
	p_left = pow(p_left + 0.01, alpha_weight)
	p_right = pow(p_right + 0.01, alpha_weight)

	var total := p_fwd + p_left + p_right
	if total < 0.001:
		return fwd
	return (fwd * p_fwd + left * p_left + right * p_right).normalized()


func _bias_toward_quality(ant: AntState) -> void:
	# In multi-source mode, occasionally nudge ants toward known high-quality sources
	if randf() > 0.02:
		return
	var best_idx := -1
	var best_score := 0.0
	for fi in range(_food_sources.size()):
		var food: Dictionary = _food_sources[fi]
		if food["remaining"] <= 0.0:
			continue
		var dist: float = ant.pos.distance_to(food["pos"])
		var score: float = food["quality"] / maxf(dist, 0.5)
		if score > best_score:
			best_score = score
			best_idx = fi
	if best_idx >= 0:
		var target: Vector2 = _food_sources[best_idx]["pos"]
		ant.wander_angle = ant.pos.angle_to_point(target)


# =========================================================================
# Communication systems
# =========================================================================

func _update_recruitment_signals(delta: float) -> void:
	var alive: Array = []
	for sig in _recruitment_signals:
		sig["radius"] += delta * 2.0
		sig["strength"] -= delta * 0.3
		if sig["strength"] > 0.0 and sig["radius"] < field_size:
			alive.append(sig)
	_recruitment_signals = alive


func _update_tandem_pairs(delta: float) -> void:
	# Try to form new tandem pairs from recruitment signals
	for sig in _recruitment_signals:
		if sig["strength"] < 0.3:
			continue
		var target_idx: int = sig["target_food"]
		if target_idx < 0 or target_idx >= _food_sources.size():
			continue
		if _food_sources[target_idx]["remaining"] <= 0.0:
			continue
		# Find an idle ant near the signal
		for i in range(_ants.size()):
			var ant: AntState = _ants[i]
			if ant.has_food or ant.is_tandem_leader or ant.is_tandem_follower:
				continue
			if ant.pos.distance_to(sig["pos"]) < sig["radius"] and randf() < 0.01:
				# Find a leader (ant that knows the food location)
				for j in range(_ants.size()):
					var leader: AntState = _ants[j]
					if j == i or leader.is_tandem_leader or leader.is_tandem_follower:
						continue
					if not leader.has_food and leader.target_food_idx == target_idx and leader.recruit_cooldown <= 0.0:
						# Form tandem pair
						leader.is_tandem_leader = true
						ant.is_tandem_follower = true
						_tandem_pairs.append({
							"leader": j,
							"follower": i,
							"target": _food_sources[target_idx]["pos"],
							"progress": 0.0,
						})
						break
				break

	# Move tandem pairs
	var active_pairs: Array = []
	for pair in _tandem_pairs:
		var leader: AntState = _ants[pair["leader"]]
		var follower: AntState = _ants[pair["follower"]]
		var target: Vector2 = pair["target"]

		pair["progress"] += delta * ant_speed * 0.5
		var dir := (target - leader.pos).normalized()
		leader.pos += dir * ant_speed * delta * 0.7
		# Follower follows with slight delay
		var follow_dir := (leader.pos - follower.pos).normalized()
		follower.pos += follow_dir * ant_speed * delta * 0.65

		if leader.pos.distance_to(target) < 0.5:
			# Arrived — release pair
			leader.is_tandem_leader = false
			follower.is_tandem_follower = false
			follower.wander_angle = follower.pos.angle_to_point(target)
		else:
			active_pairs.append(pair)
	_tandem_pairs = active_pairs


# =========================================================================
# Drawing
# =========================================================================

func _draw_all() -> void:
	_draw_heatmap()
	_draw_nest()
	_draw_food()
	_draw_ants()
	_draw_signals()


func _draw_heatmap() -> void:
	_heatmap_im.clear_surfaces()

	# Find max pheromone for normalization
	var max_pher := 0.01
	for x in range(grid_resolution):
		for y in range(grid_resolution):
			max_pher = maxf(max_pher, _pheromone_grid[x][y])

	var cell_w := field_size / float(grid_resolution)
	var half := field_size * 0.5

	_heatmap_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in range(grid_resolution):
		for y in range(grid_resolution):
			var val: float = _pheromone_grid[x][y]
			if val < 0.01:
				continue

			var t := clampf(val / max_pher, 0.0, 1.0)
			var col := _sample_heatmap_color(t)

			var wx := -half + x * cell_w
			var wy := -half + y * cell_w
			var z := -0.01  # slightly behind ants

			# Two triangles per cell
			_heatmap_im.surface_set_color(col)
			_heatmap_im.surface_add_vertex(Vector3(wx, wy, z))
			_heatmap_im.surface_add_vertex(Vector3(wx + cell_w, wy, z))
			_heatmap_im.surface_add_vertex(Vector3(wx + cell_w, wy + cell_w, z))

			_heatmap_im.surface_set_color(col)
			_heatmap_im.surface_add_vertex(Vector3(wx, wy, z))
			_heatmap_im.surface_add_vertex(Vector3(wx + cell_w, wy + cell_w, z))
			_heatmap_im.surface_add_vertex(Vector3(wx, wy + cell_w, z))

	_heatmap_im.surface_end()


func _sample_heatmap_color(t: float) -> Color:
	# Sample from the color ramp
	var n := HEATMAP_COLORS.size() - 1
	var idx := t * n
	var lo := int(floorf(idx))
	var hi := mini(lo + 1, n)
	var frac := idx - lo
	return HEATMAP_COLORS[lo].lerp(HEATMAP_COLORS[hi], frac)


func _draw_nest() -> void:
	_nest_im.clear_surfaces()
	_nest_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	# Draw nest as octagon
	var r := 0.35
	var pulse := 1.0 + sin(_time * 2.0) * 0.05
	r *= pulse
	var segments := 8
	var col := COL_NEST.lerp(COL_NEST_GLOW, sin(_time * 3.0) * 0.5 + 0.5)
	for i in range(segments):
		var a0 := float(i) / segments * TAU
		var a1 := float(i + 1) / segments * TAU
		_nest_im.surface_set_color(col)
		_nest_im.surface_add_vertex(Vector3(_nest_pos.x, _nest_pos.y, 0.02))
		_nest_im.surface_add_vertex(Vector3(_nest_pos.x + cos(a0) * r, _nest_pos.y + sin(a0) * r, 0.02))
		_nest_im.surface_add_vertex(Vector3(_nest_pos.x + cos(a1) * r, _nest_pos.y + sin(a1) * r, 0.02))

	_nest_im.surface_end()


func _draw_food() -> void:
	_food_im.clear_surfaces()
	_food_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for fi in range(_food_sources.size()):
		var food: Dictionary = _food_sources[fi]
		var pos: Vector2 = food["pos"]
		var quality: float = food["quality"]
		var remaining_ratio: float = food["remaining"] / maxf(food["initial"], 1.0)

		var col: Color
		if remaining_ratio <= 0.0:
			col = COL_FOOD_DEPLETED
		else:
			col = COL_FOOD_LOW.lerp(COL_FOOD_HIGH, quality)
			col.a = 0.5 + remaining_ratio * 0.5

		# Size reflects remaining amount
		var r := 0.15 + remaining_ratio * 0.2 + quality * 0.1
		var pulse := 1.0 + sin(_time * 3.0 + fi * 1.5) * 0.08
		r *= pulse

		# Draw as hexagon
		var segments := 6
		for i in range(segments):
			var a0 := float(i) / segments * TAU
			var a1 := float(i + 1) / segments * TAU
			_food_im.surface_set_color(col)
			_food_im.surface_add_vertex(Vector3(pos.x, pos.y, 0.01))
			_food_im.surface_add_vertex(Vector3(pos.x + cos(a0) * r, pos.y + sin(a0) * r, 0.01))
			_food_im.surface_add_vertex(Vector3(pos.x + cos(a1) * r, pos.y + sin(a1) * r, 0.01))

		# Quality rating ring (in MULTI_SOURCE mode)
		if _mode == Mode.MULTI_SOURCE and remaining_ratio > 0.0:
			var ring_r: float = r + 0.15
			var ring_col := Color(1.0, 1.0, 0.3, quality * 0.6)
			for i in range(12):
				var a0 := float(i) / 12.0 * TAU
				var a1 := float(i + 1) / 12.0 * TAU
				var inner: float = ring_r - 0.04
				_food_im.surface_set_color(ring_col)
				_food_im.surface_add_vertex(Vector3(pos.x + cos(a0) * inner, pos.y + sin(a0) * inner, 0.01))
				_food_im.surface_add_vertex(Vector3(pos.x + cos(a0) * ring_r, pos.y + sin(a0) * ring_r, 0.01))
				_food_im.surface_add_vertex(Vector3(pos.x + cos(a1) * ring_r, pos.y + sin(a1) * ring_r, 0.01))
				_food_im.surface_set_color(ring_col)
				_food_im.surface_add_vertex(Vector3(pos.x + cos(a0) * inner, pos.y + sin(a0) * inner, 0.01))
				_food_im.surface_add_vertex(Vector3(pos.x + cos(a1) * ring_r, pos.y + sin(a1) * ring_r, 0.01))
				_food_im.surface_add_vertex(Vector3(pos.x + cos(a1) * inner, pos.y + sin(a1) * inner, 0.01))

	_food_im.surface_end()


func _draw_ants() -> void:
	_ants_im.clear_surfaces()
	_ants_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var ant_r := 0.07
	for i in range(_ants.size()):
		var ant: AntState = _ants[i]

		var col: Color
		if ant.is_tandem_leader or ant.is_tandem_follower:
			col = COL_ANT_TANDEM
		elif ant.has_food:
			col = COL_ANT_RETURN
		else:
			col = COL_ANT_SEARCH

		# Draw ant as diamond (direction-indicating)
		var fwd := Vector2(cos(ant.wander_angle), sin(ant.wander_angle))
		var side := fwd.rotated(PI * 0.5)
		var p := ant.pos
		var z := 0.05

		# Front point
		var front := p + fwd * ant_r * 1.5
		# Back point
		var back := p - fwd * ant_r
		# Side points
		var left := p + side * ant_r * 0.7
		var right := p - side * ant_r * 0.7

		_ants_im.surface_set_color(col)
		_ants_im.surface_add_vertex(Vector3(front.x, front.y, z))
		_ants_im.surface_add_vertex(Vector3(left.x, left.y, z))
		_ants_im.surface_add_vertex(Vector3(back.x, back.y, z))

		_ants_im.surface_set_color(col)
		_ants_im.surface_add_vertex(Vector3(front.x, front.y, z))
		_ants_im.surface_add_vertex(Vector3(back.x, back.y, z))
		_ants_im.surface_add_vertex(Vector3(right.x, right.y, z))

	_ants_im.surface_end()


func _draw_signals() -> void:
	_signals_im.clear_surfaces()
	if _mode != Mode.COMMUNICATION:
		return

	_signals_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	# Draw recruitment signal expanding rings
	for sig in _recruitment_signals:
		var r: float = sig["radius"]
		var strength: float = sig["strength"]
		var col := COL_SIGNAL
		col.a = strength * 0.4
		var segments := 24
		var thickness := 0.06
		var inner := r - thickness
		if inner < 0.0:
			inner = 0.0
		var center: Vector2 = sig["pos"]

		for si in range(segments):
			var a0 := float(si) / segments * TAU
			var a1 := float(si + 1) / segments * TAU
			_signals_im.surface_set_color(col)
			_signals_im.surface_add_vertex(Vector3(center.x + cos(a0) * inner, center.y + sin(a0) * inner, 0.03))
			_signals_im.surface_add_vertex(Vector3(center.x + cos(a0) * r, center.y + sin(a0) * r, 0.03))
			_signals_im.surface_add_vertex(Vector3(center.x + cos(a1) * r, center.y + sin(a1) * r, 0.03))
			_signals_im.surface_set_color(col)
			_signals_im.surface_add_vertex(Vector3(center.x + cos(a0) * inner, center.y + sin(a0) * inner, 0.03))
			_signals_im.surface_add_vertex(Vector3(center.x + cos(a1) * r, center.y + sin(a1) * r, 0.03))
			_signals_im.surface_add_vertex(Vector3(center.x + cos(a1) * inner, center.y + sin(a1) * inner, 0.03))

	# Draw tandem pair connections
	for pair in _tandem_pairs:
		var leader: AntState = _ants[pair["leader"]]
		var follower: AntState = _ants[pair["follower"]]
		var col := COL_ANT_TANDEM
		col.a = 0.6
		var w := 0.03
		var dir := (leader.pos - follower.pos).normalized()
		var perp := dir.rotated(PI * 0.5)

		var p0 := follower.pos + perp * w
		var p1 := follower.pos - perp * w
		var p2 := leader.pos + perp * w
		var p3 := leader.pos - perp * w

		_signals_im.surface_set_color(col)
		_signals_im.surface_add_vertex(Vector3(p0.x, p0.y, 0.04))
		_signals_im.surface_add_vertex(Vector3(p1.x, p1.y, 0.04))
		_signals_im.surface_add_vertex(Vector3(p2.x, p2.y, 0.04))
		_signals_im.surface_set_color(col)
		_signals_im.surface_add_vertex(Vector3(p1.x, p1.y, 0.04))
		_signals_im.surface_add_vertex(Vector3(p3.x, p3.y, 0.04))
		_signals_im.surface_add_vertex(Vector3(p2.x, p2.y, 0.04))

	_signals_im.surface_end()


# =========================================================================
# Labels
# =========================================================================

func _update_labels() -> void:
	var mode_names := ["Colony", "Communication", "Multi-Source"]
	_mode_label.text = "Mode: %s" % mode_names[_mode]

	_info_label.text = "Ants: %d\nEvaporation: %.3f\nFood sources: %d" % [
		ant_count, evaporation_rate, _food_sources.size()
	]

	var active_food := 0
	var total_remaining := 0.0
	for food in _food_sources:
		if food["remaining"] > 0.0:
			active_food += 1
			total_remaining += food["remaining"]

	_stats_label.text = "Collected: %d\nForaging: %d\nActive sources: %d\nRemaining: %d" % [
		_stats_food_collected, _stats_active_foragers, active_food, int(total_remaining)
	]


# =========================================================================
# apply_grid_config
# =========================================================================

func apply_grid_config(config: Dictionary) -> void:
	if config.has("ant_count"):
		ant_count = int(config["ant_count"])
	if config.has("evaporation_rate"):
		evaporation_rate = float(config["evaporation_rate"])
	if config.has("pheromone_deposit"):
		pheromone_deposit = float(config["pheromone_deposit"])
	if config.has("alpha_weight"):
		alpha_weight = float(config["alpha_weight"])
	if config.has("beta_weight"):
		beta_weight = float(config["beta_weight"])
	if config.has("ant_speed"):
		ant_speed = float(config["ant_speed"])
	if config.has("field_size"):
		field_size = float(config["field_size"])
	if config.has("grid_resolution"):
		grid_resolution = int(config["grid_resolution"])
	if config.has("food_source_count"):
		food_source_count = int(config["food_source_count"])
	if config.has("mode"):
		var m: String = str(config["mode"]).to_upper()
		match m:
			"COLONY": _mode = Mode.COLONY
			"COMMUNICATION": _mode = Mode.COMMUNICATION
			"MULTI_SOURCE": _mode = Mode.MULTI_SOURCE

	# Re-initialize with new params
	_reset_colony()
