extends Node3D

# =============================================================================
# Gradient Descent Visualization
# =============================================================================
# Demonstrates gradient descent optimization on a procedural noise terrain.
# A glowing walker sphere follows the negative gradient downhill, leaving a
# trail. The gradient vector is shown as a red arrow. When the walker converges
# (gradient magnitude drops below threshold), a celebration effect plays.
# =============================================================================

enum RunState { RUNNING, COMPLETE }

# --- Color Palette -----------------------------------------------------------
const COLOR_TERRAIN := Color(0.25, 0.55, 0.32)    # Green terrain
const COLOR_WALKER := Color(1.0, 0.85, 0.2)       # Gold walker
const COLOR_PATH := Color(1.0, 0.9, 0.3)          # Yellow path trail
const COLOR_GRADIENT := Color(0.9, 0.3, 0.3)      # Red gradient arrow
const COLOR_CONVERGED := Color(0.3, 0.85, 0.4)    # Green for convergence

# --- Export: Terrain ---------------------------------------------------------
@export_category("Terrain")
@export_range(20, 120, 2)
var grid_resolution: int = 80
@export var grid_size: float = 20.0
@export var height_scale: float = 4.0
@export var noise_frequency: float = 0.15
@export_range(1, 8, 1)
var noise_octaves: int = 4
@export var noise_lacunarity: float = 2.0
@export var noise_gain: float = 0.5
@export var noise_seed: int = 20241101

# --- Export: Descent Algorithm -----------------------------------------------
@export_category("Descent Algorithm")
@export var walker_start: Vector2 = Vector2(6.0, -5.0)
@export var learning_rate: float = 0.85:
	set(v):
		learning_rate = clamp(v, 0.01, 5.0)
@export var step_interval: float = 0.18
@export var gradient_sample_distance: float = 0.25
@export var gradient_visual_scale: float = 2.0
@export var max_steps: int = 160
@export var stop_gradient_magnitude: float = 0.02
@export var show_gradient: bool = true

# --- Scene references --------------------------------------------------------
@onready var terrain_mesh: MeshInstance3D = $Terrain
@onready var walker_mesh: MeshInstance3D = $Walker
@onready var path_mesh: MeshInstance3D = $Path
@onready var gradient_mesh: MeshInstance3D = $GradientIndicator
@onready var info_label: Label3D = $HUD/InfoLabel

const POINT_RADIUS := 0.35

var _noise := FastNoiseLite.new()
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _path_points: Array[Vector3] = []
var _current_position: Vector2 = Vector2.ZERO
var _state: RunState = RunState.RUNNING
var _step_index: int = 0
var _time_accumulator: float = 0.0
var _walker_mat: StandardMaterial3D   # Cached walker material for tween effects
var _title_label: Label3D             # In-scene title
var _stats_label: Label3D             # Secondary stats display

func _ready() -> void:
	_rng.randomize()
	_init_noise()
	_generate_terrain()
	_configure_walker()
	_build_controls()
	reset_descent(false)

func _init_noise() -> void:
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.frequency = noise_frequency
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = noise_octaves
	_noise.fractal_lacunarity = noise_lacunarity
	_noise.fractal_gain = noise_gain
	_noise.seed = noise_seed

func _generate_terrain() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var resolution := grid_resolution
	for z in range(resolution):
		for x in range(resolution):
			var v00 := _vertex_for_grid(x, z)
			var v10 := _vertex_for_grid(x + 1, z)
			var v01 := _vertex_for_grid(x, z + 1)
			var v11 := _vertex_for_grid(x + 1, z + 1)
			_add_triangle(st, v00, v10, v11)
			_add_triangle(st, v00, v11, v01)
	var mesh := st.commit()
	terrain_mesh.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = COLOR_TERRAIN
	material.roughness = 0.75
	material.metallic = 0.15
	material.specular = 0.4
	material.emission_enabled = true
	material.emission = COLOR_TERRAIN * 0.08
	terrain_mesh.material_override = material

func _vertex_for_grid(x: int, z: int) -> Vector3:
	var fx := float(x) / float(grid_resolution)
	var fz := float(z) / float(grid_resolution)
	var world_x := fx * grid_size - grid_size * 0.5
	var world_z := fz * grid_size - grid_size * 0.5
	var height := _sample_height(world_x, world_z)
	return Vector3(world_x, height, world_z)

func _add_triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal := (b - a).cross(c - a).normalized()
	st.set_normal(normal)
	st.add_vertex(a)
	st.set_normal(normal)
	st.add_vertex(b)
	st.set_normal(normal)
	st.add_vertex(c)

func _sample_height(x: float, z: float) -> float:
	return _noise.get_noise_2d(x, z) * height_scale

func _configure_walker() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = POINT_RADIUS
	sphere.height = POINT_RADIUS * 2.0
	sphere.radial_segments = 16
	sphere.rings = 8
	walker_mesh.mesh = sphere
	_walker_mat = StandardMaterial3D.new()
	_walker_mat.albedo_color = COLOR_WALKER
	_walker_mat.emission_enabled = true
	_walker_mat.emission = COLOR_WALKER * 0.6
	_walker_mat.roughness = 0.25
	_walker_mat.metallic = 0.35
	walker_mesh.material_override = _walker_mat

# =============================================================================
# In-scene 3D UI controls & labels
# =============================================================================

func _build_controls() -> void:
	"""Add in-scene Label3D headers and stats panel."""
	# Title
	_title_label = Label3D.new()
	_title_label.text = "Gradient Descent"
	_title_label.font_size = 72
	_title_label.modulate = COLOR_WALKER
	_title_label.position = Vector3(0, height_scale + 3.0, -grid_size * 0.5 - 1.0)
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_title_label)

	# Learning-rate label
	_stats_label = Label3D.new()
	_stats_label.font_size = 40
	_stats_label.modulate = Color.WHITE
	_stats_label.position = Vector3(0, height_scale + 1.8, -grid_size * 0.5 - 1.0)
	_stats_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_stats_label)

# =============================================================================
# Per-frame update
# =============================================================================

func _process(delta: float) -> void:
	if _state != RunState.RUNNING:
		return
	_time_accumulator += delta
	if _time_accumulator >= step_interval:
		_time_accumulator -= step_interval
		_perform_descent_step()

func reset_descent(randomise: bool = true) -> void:
	_state = RunState.RUNNING
	_step_index = 0
	_path_points.clear()
	_time_accumulator = 0.0
	var start := walker_start
	if randomise:
		start = Vector2(
			_rand_range(-grid_size * 0.45, grid_size * 0.45),
			_rand_range(-grid_size * 0.45, grid_size * 0.45)
		)
	_current_position = _clamp_to_domain(start)
	_update_walker_transform()
	_path_points.append(walker_mesh.global_position)
	_update_path_mesh()
	_update_gradient_mesh(Vector2.ZERO)
	_update_info_label(Vector2.ZERO)

func _perform_descent_step() -> void:
	if _step_index >= max_steps:
		_finalize_descent()
		return
	var gradient := _estimate_gradient(_current_position)
	var magnitude := gradient.length()
	if magnitude < stop_gradient_magnitude:
		_finalize_descent()
		return
	_current_position -= gradient * learning_rate
	_current_position = _clamp_to_domain(_current_position)
	_update_walker_transform()
	_path_points.append(walker_mesh.global_position)
	_update_path_mesh()
	_update_gradient_mesh(gradient)
	_update_info_label(gradient)
	_step_index += 1

func _finalize_descent() -> void:
	_state = RunState.COMPLETE
	_update_gradient_mesh(Vector2.ZERO)
	_update_info_label(Vector2.ZERO)
	_play_convergence_effect()

func _estimate_gradient(pos: Vector2) -> Vector2:
	var eps := gradient_sample_distance
	var base_x := _sample_height(pos.x + eps, pos.y)
	var base_xm := _sample_height(pos.x - eps, pos.y)
	var base_z := _sample_height(pos.x, pos.y + eps)
	var base_zm := _sample_height(pos.x, pos.y - eps)
	var grad_x := (base_x - base_xm) / (2.0 * eps)
	var grad_z := (base_z - base_zm) / (2.0 * eps)
	return Vector2(grad_x, grad_z)

func _update_walker_transform() -> void:
	"""Smoothly tween the walker to its new position instead of snapping."""
	var y := _sample_height(_current_position.x, _current_position.y)
	var target_pos := Vector3(_current_position.x, y + POINT_RADIUS, _current_position.y)
	var tw := create_tween()
	tw.tween_property(walker_mesh, "global_position", target_pos, 0.12).set_ease(Tween.EASE_OUT)
	# Quick scale pulse on each step for visual feedback
	tw.parallel().tween_property(walker_mesh, "scale", Vector3.ONE * 1.25, 0.06).set_ease(Tween.EASE_OUT)
	tw.tween_property(walker_mesh, "scale", Vector3.ONE, 0.06).set_ease(Tween.EASE_IN)

func _play_convergence_effect() -> void:
	"""Visual celebration when the walker reaches a local minimum."""
	if not _walker_mat:
		return
	# Flash walker green, then back to gold
	var tw := create_tween()
	tw.tween_property(_walker_mat, "emission", COLOR_CONVERGED * 1.5, 0.15)
	tw.tween_property(_walker_mat, "emission", COLOR_WALKER * 0.6, 0.8)
	# Scale pop
	var tw2 := create_tween()
	tw2.tween_property(walker_mesh, "scale", Vector3.ONE * 1.8, 0.2).set_ease(Tween.EASE_OUT)
	tw2.tween_property(walker_mesh, "scale", Vector3.ONE, 0.5).set_ease(Tween.EASE_IN_OUT)

func _update_path_mesh() -> void:
	var immediate := path_mesh.mesh as ImmediateMesh
	if immediate == null:
		immediate = ImmediateMesh.new()
		path_mesh.mesh = immediate
	immediate.clear_surfaces()
	if _path_points.size() < 2:
		return
	immediate.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	immediate.surface_set_color(COLOR_PATH)
	for point in _path_points:
		immediate.surface_add_vertex(point)
	immediate.surface_end()

func _update_gradient_mesh(gradient: Vector2) -> void:
	var immediate := gradient_mesh.mesh as ImmediateMesh
	if immediate == null:
		immediate = ImmediateMesh.new()
		gradient_mesh.mesh = immediate
	immediate.clear_surfaces()
	if not show_gradient or gradient.length() <= 0.0001:
		return
	var start := walker_mesh.global_position + Vector3(0.0, 0.3, 0.0)
	var end := start + Vector3(-gradient.x, 0.0, -gradient.y) * gradient_visual_scale
	immediate.surface_begin(Mesh.PRIMITIVE_LINES)
	immediate.surface_set_color(COLOR_GRADIENT)
	immediate.surface_add_vertex(start)
	immediate.surface_add_vertex(end)
	immediate.surface_end()

func _update_info_label(gradient: Vector2) -> void:
	if info_label == null:
		return
	var slope := gradient.length()
	var status := "running"
	if _state == RunState.COMPLETE:
		status = "converged" if slope < stop_gradient_magnitude else "max steps"
	info_label.text = "Step %d / %d\n|grad| = %.03f\nState: %s" % [
		_step_index,
		max_steps,
		slope,
		status,
	]
	# Update secondary stats label
	if _stats_label:
		_stats_label.text = "LR: %.2f  |  Height: %.2f  |  Pos: (%.1f, %.1f)" % [
			learning_rate,
			_sample_height(_current_position.x, _current_position.y),
			_current_position.x,
			_current_position.y,
		]



func _clamp_to_domain(pos: Vector2) -> Vector2:
	var half := grid_size * 0.5
	return Vector2(
		clamp(pos.x, -half, half),
		clamp(pos.y, -half, half)
	)

func _rand_range(min_value: float, max_value: float) -> float:
	return _rng.randf_range(min_value, max_value)
