# random_walk_terrarium.gd
# Random walk visualization in a glass terrarium
# Shows 2D and 3D random walks with trails
#
# QFEP: Random walk as pure E(S) — no memory, no direction, maximum entropy

extends Node3D

class_name RandomWalkTerrarium

## Terrarium size
@export var terrarium_size: Vector3 = Vector3(0.5, 0.4, 0.5)

## Walk parameters
@export var num_walkers: int = 5
@export var step_size: float = 0.015
@export var steps_per_second: float = 30.0
@export var trail_length: int = 200

## Walk mode
enum WalkMode { WALK_2D, WALK_3D, LEVY_FLIGHT }
@export var walk_mode: WalkMode = WalkMode.WALK_3D:
	set(value):
		walk_mode = value
		_reset_walkers()

## Colors
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
var _walker_meshes: Array[MeshInstance3D] = []
var _trail_meshes: Array[MeshInstance3D] = []
var _info_label: Label3D
var _stats_label: Label3D
var _control_panel: Node3D

const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")

func _ready():
	_create_terrarium()
	_create_walkers()
	_create_labels()
	_create_vr_controls()
	_reset_walkers()

func _create_terrarium():
	_glass_box = Node3D.new()
	_glass_box.name = "GlassBox"
	add_child(_glass_box)
	
	# Base (solid)
	var base = MeshInstance3D.new()
	base.name = "Base"
	var base_mesh = BoxMesh.new()
	base_mesh.size = Vector3(terrarium_size.x + 0.02, 0.01, terrarium_size.z + 0.02)
	base.mesh = base_mesh
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.1, 0.1, 0.12)
	base.material_override = base_mat
	base.position = Vector3(0, -0.005, 0)
	_glass_box.add_child(base)
	
	# Glass walls
	var glass_mat = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.7, 0.85, 1.0, 0.15)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	# Front/back walls
	for z_sign in [-1, 1]:
		var wall = MeshInstance3D.new()
		var wall_mesh = BoxMesh.new()
		wall_mesh.size = Vector3(terrarium_size.x, terrarium_size.y, 0.005)
		wall.mesh = wall_mesh
		wall.material_override = glass_mat
		wall.position = Vector3(0, terrarium_size.y/2, z_sign * terrarium_size.z/2)
		_glass_box.add_child(wall)
	
	# Left/right walls
	for x_sign in [-1, 1]:
		var wall = MeshInstance3D.new()
		var wall_mesh = BoxMesh.new()
		wall_mesh.size = Vector3(0.005, terrarium_size.y, terrarium_size.z)
		wall.mesh = wall_mesh
		wall.material_override = glass_mat
		wall.position = Vector3(x_sign * terrarium_size.x/2, terrarium_size.y/2, 0)
		_glass_box.add_child(wall)

func _create_walkers():
	for i in range(num_walkers):
		# Walker sphere
		var walker = MeshInstance3D.new()
		walker.name = "Walker%d" % i
		var sphere = SphereMesh.new()
		sphere.radius = 0.012
		sphere.height = 0.024
		walker.mesh = sphere
		
		var color = walker_colors[i % walker_colors.size()]
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.5
		walker.material_override = mat
		
		_walker_meshes.append(walker)
		add_child(walker)
		
		# Trail mesh
		var trail = MeshInstance3D.new()
		trail.name = "Trail%d" % i
		_trail_meshes.append(trail)
		add_child(trail)
		
		# Init state
		_walker_positions.append(Vector3.ZERO)
		_walker_trails.append(PackedVector3Array())

func _create_labels():
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 16
	_info_label.position = Vector3(0, terrarium_size.y + 0.08, 0)
	_info_label.text = "RANDOM WALK"
	add_child(_info_label)
	
	_stats_label = Label3D.new()
	_stats_label.name = "StatsLabel"
	_stats_label.pixel_size = 0.0012
	_stats_label.font_size = 12
	_stats_label.position = Vector3(terrarium_size.x/2 + 0.1, terrarium_size.y/2, 0)
	add_child(_stats_label)

func _create_vr_controls():
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, -0.08, terrarium_size.z/2 + 0.15)
	_control_panel.rotation_degrees = Vector3(-30, 180, 0)
	add_child(_control_panel)
	
	# Panel
	var panel_back = MeshInstance3D.new()
	var panel_mesh = BoxMesh.new()
	panel_mesh.size = Vector3(0.35, 0.1, 0.01)
	panel_back.mesh = panel_mesh
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.08, 0.08, 0.1)
	panel_mat.metallic = 0.3
	panel_back.material_override = panel_mat
	_control_panel.add_child(panel_back)
	
	# Mode buttons
	var modes = ["2D", "3D", "LÉVY"]
	for i in range(modes.size()):
		var btn = PUSH_BUTTON.instantiate()
		btn.name = "Mode%d" % i
		btn.position = Vector3(-0.1 + i * 0.1, 0.02, -0.005)
		btn.scale = Vector3(0.7, 0.7, 0.7)
		_control_panel.add_child(btn)
		_add_button_label(btn, modes[i])
		
		var mode_idx = i
		var area = btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(): walk_mode = mode_idx as WalkMode)
	
	# Reset button
	var reset_btn = PUSH_BUTTON.instantiate()
	reset_btn.name = "ResetBtn"
	reset_btn.position = Vector3(0, -0.025, -0.005)
	reset_btn.scale = Vector3(0.7, 0.7, 0.7)
	_control_panel.add_child(reset_btn)
	_add_button_label(reset_btn, "RESET")
	var reset_area = reset_btn.get_node_or_null("InteractableAreaButton")
	if reset_area:
		reset_area.button_pressed.connect(_reset_walkers)

func _add_button_label(btn: Node, text: String):
	var lbl = Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.001
	lbl.font_size = 8
	lbl.position = Vector3(0, -0.022, 0.01)
	btn.add_child(lbl)

func _reset_walkers():
	_total_steps = 0
	for i in range(num_walkers):
		_walker_positions[i] = Vector3(0, terrarium_size.y/2, 0)
		_walker_trails[i].clear()
		_walker_meshes[i].position = _walker_positions[i]

func _process(delta):
	_step_timer += delta
	var interval = 1.0 / steps_per_second
	
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
		_walker_meshes[i].position = new_pos

func _generate_step() -> Vector3:
	match walk_mode:
		WalkMode.WALK_2D:
			var angle = randf() * TAU
			return Vector3(cos(angle), 0, sin(angle)) * step_size
		
		WalkMode.WALK_3D:
			# Random direction on unit sphere
			var theta = randf() * TAU
			var phi = acos(2 * randf() - 1)
			return Vector3(
				sin(phi) * cos(theta),
				sin(phi) * sin(theta),
				cos(phi)
			) * step_size
		
		WalkMode.LEVY_FLIGHT:
			# Lévy flight: occasional large jumps
			var angle = randf() * TAU
			var phi = acos(2 * randf() - 1)
			var direction = Vector3(
				sin(phi) * cos(angle),
				sin(phi) * sin(angle),
				cos(phi)
			)
			# Power-law step size
			var u = randf()
			var levy_step = step_size * pow(u + 0.01, -0.5)
			levy_step = minf(levy_step, step_size * 10)  # Cap max jump
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

func _update_trails():
	for i in range(num_walkers):
		var trail = _walker_trails[i]
		if trail.size() < 2:
			_trail_meshes[i].mesh = null
			continue
		
		var color = walker_colors[i % walker_colors.size()]
		
		var immediate_mesh = ImmediateMesh.new()
		immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		
		for j in range(trail.size()):
			var alpha = float(j) / float(trail.size())
			immediate_mesh.surface_set_color(Color(color.r, color.g, color.b, alpha * 0.6))
			immediate_mesh.surface_add_vertex(trail[j])
		
		immediate_mesh.surface_end()
		_trail_meshes[i].mesh = immediate_mesh
		
		var mat = StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_trail_meshes[i].material_override = mat

func _update_stats():
	# Calculate mean squared displacement
	var sum_sq_disp = 0.0
	for i in range(num_walkers):
		var disp = _walker_positions[i] - Vector3(0, terrarium_size.y/2, 0)
		sum_sq_disp += disp.length_squared()
	var msd = sum_sq_disp / num_walkers
	
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
