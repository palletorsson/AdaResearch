# random_walk_terrarium.gd
# Random walk visualization in a glass terrarium
# Shows 2D and 3D random walks with trails
#
# Algorithm: Simulates random walks (uniform 2D, uniform 3D, and Lévy flight)
# inside a bounded glass terrarium. Each walker takes discrete steps in uniformly
# random directions; boundary reflection keeps walkers contained. Mean squared
# displacement (MSD) is tracked to demonstrate diffusion scaling laws.
#
# QFEP: Random walk as pure E(S) — no memory, no direction, maximum entropy

extends Node3D

class_name RandomWalkTerrarium

# --- Constants ---
const WALKER_RADIUS := 0.012
const WALKER_HEIGHT := 0.024
const WALL_THICKNESS := 0.005
const BASE_THICKNESS := 0.01
const BASE_OVERHANG := 0.02
const GLASS_ALPHA := 0.15
const TRAIL_MAX_ALPHA := 0.6
const EMISSION_ENERGY := 0.5
const LEVY_STEP_CAP := 10.0
const LEVY_OFFSET := 0.01
const LEVY_EXPONENT := -0.5
const LABEL_PIXEL_SIZE := 0.002
const STATS_PIXEL_SIZE := 0.0012
const BTN_LABEL_PIXEL_SIZE := 0.001
const BTN_LABEL_Y_OFFSET := -0.022
const BTN_SCALE := Vector3(0.7, 0.7, 0.7)
const PANEL_SIZE := Vector3(0.35, 0.1, 0.01)
const MAX_CATCHUP_STEPS := 5

## Half-extents of the terrarium box (x, y, z)
@export var terrarium_size: Vector3 = Vector3(0.5, 0.4, 0.5)

## Number of random walkers to simulate
@export_range(1, 20) var num_walkers: int = 5
## Distance each walker moves per step
@export_range(0.001, 0.1, 0.001) var step_size: float = 0.015
## How many walk steps are taken per second
@export_range(1.0, 120.0, 1.0) var steps_per_second: float = 30.0
## Maximum number of trail points kept per walker
@export_range(10, 1000) var trail_length: int = 200

## Walk mode
enum WalkMode { WALK_2D, WALK_3D, LEVY_FLIGHT }
@export var walk_mode: WalkMode = WalkMode.WALK_3D:
	set(value):
		walk_mode = value
		_reset_walkers()

## Colors assigned to each walker (wraps if fewer than num_walkers)
@export var walker_colors: Array[Color] = [
	Color(1.0, 0.3, 0.3),
	Color(0.3, 1.0, 0.4),
	Color(0.3, 0.5, 1.0),
	Color(1.0, 0.8, 0.3),
	Color(0.8, 0.3, 1.0)
]

# State
var _walker_positions: Array[Vector3] = []
var _walker_trails: Array[PackedVector3Array] = []
var _step_timer: float = 0.0
var _total_steps: int = 0

# Visuals
var _glass_box: Node3D
var _walker_mm: MultiMesh
var _trail_meshes: Array[MeshInstance3D] = []
var _trail_ims: Array[ImmediateMesh] = []
var _trail_mat: StandardMaterial3D
var _info_label: Label3D
var _stats_label: Label3D
var _control_panel: Node3D
var _reset_area: Node

const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")

func _ready():
	_create_terrarium()
	_create_walkers()
	_create_labels()
	_create_vr_controls()
	_reset_walkers()

func _exit_tree():
	if _reset_area and _reset_area.button_pressed.is_connected(_reset_walkers):
		_reset_area.button_pressed.disconnect(_reset_walkers)

## Builds the glass box enclosure: base slab and four transparent walls.
func _create_terrarium():
	_glass_box = Node3D.new()
	_glass_box.name = "GlassBox"
	add_child(_glass_box)

	# Base (solid)
	var base = MeshInstance3D.new()
	base.name = "Base"
	var base_mesh = BoxMesh.new()
	base_mesh.size = Vector3(terrarium_size.x + BASE_OVERHANG, BASE_THICKNESS, terrarium_size.z + BASE_OVERHANG)
	base.mesh = base_mesh
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.1, 0.1, 0.12)
	base.material_override = base_mat
	base.position = Vector3(0, -BASE_THICKNESS / 2.0, 0)
	_glass_box.add_child(base)

	# Glass walls (shared material)
	var glass_mat = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.7, 0.85, 1.0, GLASS_ALPHA)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	# Front/back walls (shared mesh)
	var fb_mesh = BoxMesh.new()
	fb_mesh.size = Vector3(terrarium_size.x, terrarium_size.y, WALL_THICKNESS)
	for z_sign in [-1, 1]:
		var wall = MeshInstance3D.new()
		wall.mesh = fb_mesh
		wall.material_override = glass_mat
		wall.position = Vector3(0, terrarium_size.y / 2.0, z_sign * terrarium_size.z / 2.0)
		_glass_box.add_child(wall)

	# Left/right walls (shared mesh)
	var lr_mesh = BoxMesh.new()
	lr_mesh.size = Vector3(WALL_THICKNESS, terrarium_size.y, terrarium_size.z)
	for x_sign in [-1, 1]:
		var wall = MeshInstance3D.new()
		wall.mesh = lr_mesh
		wall.material_override = glass_mat
		wall.position = Vector3(x_sign * terrarium_size.x / 2.0, terrarium_size.y / 2.0, 0)
		_glass_box.add_child(wall)

## Creates walker spheres via MultiMesh, trail ImmediateMeshes, and state arrays.
func _create_walkers():
	# Walker spheres via MultiMesh (single draw call)
	var sphere := SphereMesh.new()
	sphere.radius = WALKER_RADIUS
	sphere.height = WALKER_HEIGHT

	_walker_mm = MultiMesh.new()
	_walker_mm.transform_format = MultiMesh.TRANSFORM_3D
	_walker_mm.use_colors = true
	_walker_mm.mesh = sphere
	_walker_mm.instance_count = num_walkers

	for i in num_walkers:
		var color = walker_colors[i % walker_colors.size()]
		_walker_mm.set_instance_color(i, color)
		_walker_mm.set_instance_transform(i, Transform3D(Basis(), Vector3.ZERO))

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Walkers"
	mmi.multimesh = _walker_mm
	var walker_mat := StandardMaterial3D.new()
	walker_mat.vertex_color_use_as_albedo = true
	walker_mat.emission_enabled = true
	walker_mat.emission = Color.WHITE
	walker_mat.emission_energy_multiplier = EMISSION_ENERGY
	mmi.material_override = walker_mat
	add_child(mmi)

	# Shared trail material (reused every frame)
	_trail_mat = StandardMaterial3D.new()
	_trail_mat.vertex_color_use_as_albedo = true
	_trail_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_trail_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	# Pre-size state arrays
	_walker_positions.resize(num_walkers)
	_walker_trails.resize(num_walkers)
	_trail_meshes.resize(num_walkers)
	_trail_ims.resize(num_walkers)

	for i in num_walkers:
		var im := ImmediateMesh.new()
		_trail_ims[i] = im

		var trail_mi := MeshInstance3D.new()
		trail_mi.name = "Trail%d" % i
		trail_mi.mesh = im
		trail_mi.material_override = _trail_mat
		_trail_meshes[i] = trail_mi
		add_child(trail_mi)

		_walker_positions[i] = Vector3.ZERO
		_walker_trails[i] = PackedVector3Array()

## Adds the title and statistics labels above / beside the terrarium.
func _create_labels():
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = LABEL_PIXEL_SIZE
	_info_label.font_size = 16
	_info_label.position = Vector3(0, terrarium_size.y + 0.08, 0)
	_info_label.text = "RANDOM WALK"
	add_child(_info_label)

	_stats_label = Label3D.new()
	_stats_label.name = "StatsLabel"
	_stats_label.pixel_size = STATS_PIXEL_SIZE
	_stats_label.font_size = 12
	_stats_label.position = Vector3(terrarium_size.x / 2.0 + 0.1, terrarium_size.y / 2.0, 0)
	add_child(_stats_label)

## Creates the VR button panel with mode-switch and reset buttons.
func _create_vr_controls():
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, -0.08, terrarium_size.z / 2.0 + 0.15)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)

	# Panel background
	var panel_back = MeshInstance3D.new()
	var panel_mesh = BoxMesh.new()
	panel_mesh.size = PANEL_SIZE
	panel_back.mesh = panel_mesh
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.08, 0.08, 0.1)
	panel_mat.metallic = 0.3
	panel_back.material_override = panel_mat
	panel_back.position.z = -0.01
	_control_panel.add_child(panel_back)

	# Mode buttons
	var modes = ["2D", "3D", "LÉVY"]
	for i in range(modes.size()):
		var btn = PUSH_BUTTON.instantiate()
		btn.name = "Mode%d" % i
		btn.position = Vector3(-0.1 + i * 0.1, 0.02, 0)
		btn.scale = BTN_SCALE
		_control_panel.add_child(btn)
		_add_button_label(btn, modes[i])

		var mode_idx = i
		var area = btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): walk_mode = mode_idx as WalkMode)

	# Reset button
	var reset_btn = PUSH_BUTTON.instantiate()
	reset_btn.name = "ResetBtn"
	reset_btn.position = Vector3(0, -0.025, 0)
	reset_btn.rotation_degrees.x = -30
	reset_btn.scale = BTN_SCALE
	_control_panel.add_child(reset_btn)
	_add_button_label(reset_btn, "RESET")
	_reset_area = reset_btn.get_node_or_null("InteractableAreaButton")
	if _reset_area:
		_reset_area.button_pressed.connect(_reset_walkers)

## Attaches a small Label3D beneath a push button.
func _add_button_label(btn: Node, text: String):
	var lbl = Label3D.new()
	lbl.text = text
	lbl.pixel_size = BTN_LABEL_PIXEL_SIZE
	lbl.font_size = 8
	lbl.position = Vector3(0, BTN_LABEL_Y_OFFSET, 0)
	btn.add_child(lbl)

func _reset_walkers():
	if _walker_positions.is_empty():
		return
	_total_steps = 0
	for i in range(num_walkers):
		_walker_positions[i] = Vector3(0, terrarium_size.y / 2.0, 0)
		_walker_trails[i].clear()
		if _walker_mm:
			_walker_mm.set_instance_transform(i, Transform3D(Basis(), _walker_positions[i]))

func _process(delta):
	var interval = 1.0 / maxf(steps_per_second, 0.001)
	_step_timer = minf(_step_timer + delta, interval * MAX_CATCHUP_STEPS)

	while _step_timer >= interval:
		_step_timer -= interval
		_step_all_walkers()

	_update_trails()
	_update_stats()

func _step_all_walkers():
	_total_steps += 1

	for i in range(num_walkers):
		var step = _generate_step()
		var new_pos = _walker_positions[i] + step

		# Boundary reflection
		new_pos = _reflect_boundaries(new_pos)

		# Record trail
		_walker_trails[i].append(_walker_positions[i])
		if _walker_trails[i].size() > trail_length:
			_walker_trails[i] = _walker_trails[i].slice(1)

		_walker_positions[i] = new_pos
		_walker_mm.set_instance_transform(i, Transform3D(Basis(), new_pos))

func _generate_step() -> Vector3:
	match walk_mode:
		WalkMode.WALK_2D:
			var angle = randf() * TAU
			return Vector3(cos(angle), 0, sin(angle)) * step_size

		WalkMode.WALK_3D:
			# Random direction on unit sphere
			var theta = randf() * TAU
			var phi = acos(2.0 * randf() - 1.0)
			return Vector3(
				sin(phi) * cos(theta),
				sin(phi) * sin(theta),
				cos(phi)
			) * step_size

		WalkMode.LEVY_FLIGHT:
			# Lévy flight: occasional large jumps
			var angle = randf() * TAU
			var phi = acos(2.0 * randf() - 1.0)
			var direction = Vector3(
				sin(phi) * cos(angle),
				sin(phi) * sin(angle),
				cos(phi)
			)
			# Power-law step size
			var u = randf()
			var levy_step = step_size * pow(u + LEVY_OFFSET, LEVY_EXPONENT)
			levy_step = minf(levy_step, step_size * LEVY_STEP_CAP)
			return direction * levy_step

	return Vector3.ZERO

func _reflect_boundaries(pos: Vector3) -> Vector3:
	var half = terrarium_size / 2.0

	if pos.x < -half.x: pos.x = -half.x + (-half.x - pos.x)
	if pos.x > half.x: pos.x = half.x - (pos.x - half.x)
	if pos.z < -half.z: pos.z = -half.z + (-half.z - pos.z)
	if pos.z > half.z: pos.z = half.z - (pos.z - half.z)

	if walk_mode != WalkMode.WALK_2D:
		if pos.y < 0: pos.y = -pos.y
		if pos.y > terrarium_size.y: pos.y = terrarium_size.y - (pos.y - terrarium_size.y)
	else:
		pos.y = terrarium_size.y / 2.0

	return pos

## Rebuilds trail line strips from cached ImmediateMeshes (no per-frame allocation).
func _update_trails():
	for i in range(num_walkers):
		var trail = _walker_trails[i]
		if trail.size() < 2:
			_trail_ims[i].clear_surfaces()
			continue

		var color = walker_colors[i % walker_colors.size()]

		_trail_ims[i].clear_surfaces()
		_trail_ims[i].surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

		for j in range(trail.size()):
			var alpha = float(j) / float(trail.size())
			_trail_ims[i].surface_set_color(Color(color.r, color.g, color.b, alpha * TRAIL_MAX_ALPHA))
			_trail_ims[i].surface_add_vertex(trail[j])

		_trail_ims[i].surface_end()

## Computes mean squared displacement and updates the stats label.
func _update_stats():
	var sum_sq_disp = 0.0
	for i in range(num_walkers):
		var disp = _walker_positions[i] - Vector3(0, terrarium_size.y / 2.0, 0)
		sum_sq_disp += disp.length_squared()
	var msd = sum_sq_disp / maxf(num_walkers, 1)

	var mode_names = ["2D", "3D", "Lévy"]
	_stats_label.text = "%s Walk\nSteps: %d\nMSD: %.4f" % [mode_names[walk_mode], _total_steps, msd]

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: walk_mode = WalkMode.WALK_2D
			KEY_2: walk_mode = WalkMode.WALK_3D
			KEY_3: walk_mode = WalkMode.LEVY_FLIGHT
			KEY_R: _reset_walkers()

func set_mode(m: WalkMode):
	walk_mode = m

func reset():
	_reset_walkers()

func apply_grid_config(config_data: Dictionary) -> void:
	pass
