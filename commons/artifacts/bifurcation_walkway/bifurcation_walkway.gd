# bifurcation_walkway.gd
# A walkable corridor where X position = r parameter in the logistic map
# Walk through the phase transition: stable → period doubling → chaos

extends Node3D

class_name BifurcationWalkway

## Walkway dimensions
@export var walkway_length: float = 10.0
@export var walkway_width: float = 2.0
@export var walkway_height: float = 3.0

## Parameter range
@export var r_min: float = 2.5
@export var r_max: float = 4.0

## Visualization
@export var attractor_points: int = 50
@export var warmup_iterations: int = 100
@export var point_size: float = 0.05
@export var display_height: float = 2.0

## Colors
@export var stable_color: Color = Color(0.2, 0.5, 1.0)      # Blue - order
@export var edge_color: Color = Color(0.2, 1.0, 0.4)        # Green - edge of chaos
@export var chaos_color: Color = Color(1.0, 0.3, 0.2)       # Red - chaos

# Internal
var _point_meshes: Array[MeshInstance3D] = []
var _current_r: float = 2.5
var _floor_mesh: MeshInstance3D
var _r_label: Label3D
var _phase_label: Label3D
var _player_marker: MeshInstance3D

# Key r values
const R_STABLE = 3.0       # Below: single fixed point
const R_PERIOD2 = 3.44949  # Period-2 begins
const R_PERIOD4 = 3.54409  # Period-4 begins
const R_CHAOS = 3.56995    # Onset of chaos
const R_BAND3 = 3.82843    # Period-3 window (Li-Yorke chaos)

func _ready():
	_create_walkway()
	_create_attractor_display()
	_create_labels()
	_create_markers()

func _create_walkway():
	# Floor
	_floor_mesh = MeshInstance3D.new()
	_floor_mesh.name = "Floor"
	
	var floor_box = BoxMesh.new()
	floor_box.size = Vector3(walkway_length, 0.1, walkway_width)
	_floor_mesh.mesh = floor_box
	
	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.15, 0.15, 0.18)
	floor_mat.metallic = 0.3
	floor_mat.roughness = 0.7
	_floor_mesh.material_override = floor_mat
	
	_floor_mesh.position = Vector3(walkway_length / 2, -0.05, 0)
	add_child(_floor_mesh)
	
	# Floor collision
	var static_body = StaticBody3D.new()
	static_body.name = "FloorCollision"
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(walkway_length, 0.1, walkway_width)
	collision.shape = shape
	static_body.add_child(collision)
	static_body.position = Vector3(walkway_length / 2, -0.05, 0)
	add_child(static_body)
	
	# R-value markers on floor
	_create_floor_markers()

func _create_floor_markers():
	var markers = [
		[R_STABLE, "r=3.0\nStable"],
		[R_PERIOD2, "r≈3.45\nPeriod-2"],
		[R_CHAOS, "r≈3.57\nChaos"],
		[R_BAND3, "r≈3.83\nPeriod-3"]
	]
	
	for marker_data in markers:
		var r_val = marker_data[0]
		var text = marker_data[1]
		
		var x_pos = _r_to_x(r_val)
		
		# Line marker
		var line = MeshInstance3D.new()
		var line_mesh = BoxMesh.new()
		line_mesh.size = Vector3(0.02, 0.01, walkway_width)
		line.mesh = line_mesh
		
		var line_mat = StandardMaterial3D.new()
		line_mat.albedo_color = Color(0.5, 0.5, 0.5)
		line.material_override = line_mat
		
		line.position = Vector3(x_pos, 0.01, 0)
		add_child(line)
		
		# Label
		var label = Label3D.new()
		label.text = text
		label.pixel_size = 0.003
		label.font_size = 20
		label.position = Vector3(x_pos, 0.02, -walkway_width/2 - 0.1)
		label.rotation_degrees = Vector3(-90, 0, 0)
		label.modulate = Color(0.7, 0.7, 0.7)
		add_child(label)

func _create_attractor_display():
	# Create spheres for attractor visualization
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = point_size / 2
	sphere_mesh.height = point_size
	
	var mat = StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.5
	
	for i in range(attractor_points):
		var point = MeshInstance3D.new()
		point.mesh = sphere_mesh
		point.material_override = mat.duplicate()
		point.visible = false
		add_child(point)
		_point_meshes.append(point)

func _create_labels():
	# R value label
	_r_label = Label3D.new()
	_r_label.name = "RLabel"
	_r_label.pixel_size = 0.003
	_r_label.font_size = 36
	_r_label.position = Vector3(0, display_height + 0.5, 0)
	add_child(_r_label)
	
	# Phase label
	_phase_label = Label3D.new()
	_phase_label.name = "PhaseLabel"
	_phase_label.pixel_size = 0.002
	_phase_label.font_size = 28
	_phase_label.position = Vector3(0, display_height + 0.2, 0)
	add_child(_phase_label)
	
	# Title at entrance
	var title = Label3D.new()
	title.text = "BIFURCATION WALKWAY\n← Order    Chaos →"
	title.pixel_size = 0.004
	title.font_size = 32
	title.position = Vector3(0, 1.5, 0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

func _create_markers():
	# Player position marker (visual indicator on floor)
	_player_marker = MeshInstance3D.new()
	_player_marker.name = "PlayerMarker"
	
	var marker_mesh = CylinderMesh.new()
	marker_mesh.top_radius = 0.1
	marker_mesh.bottom_radius = 0.15
	marker_mesh.height = 0.02
	_player_marker.mesh = marker_mesh
	
	var marker_mat = StandardMaterial3D.new()
	marker_mat.albedo_color = Color(1, 1, 1, 0.5)
	marker_mat.emission_enabled = true
	marker_mat.emission = Color(1, 1, 1)
	marker_mat.emission_energy_multiplier = 0.3
	_player_marker.material_override = marker_mat
	
	_player_marker.position = Vector3(0, 0.02, 0)
	add_child(_player_marker)

func _r_to_x(r: float) -> float:
	# Map r value to X position on walkway
	var t = (r - r_min) / (r_max - r_min)
	return t * walkway_length

func _x_to_r(x: float) -> float:
	# Map X position to r value
	var t = clampf(x / walkway_length, 0.0, 1.0)
	return r_min + t * (r_max - r_min)

func _process(_delta):
	# Find player or camera
	var player_x = _find_player_x()
	if player_x < 0:
		return
	
	_current_r = _x_to_r(player_x)
	_update_attractor_display()
	_update_labels()
	_update_marker(player_x)

func _find_player_x() -> float:
	# Try to find XR camera or regular camera
	var camera = get_viewport().get_camera_3d()
	if camera:
		var local_pos = to_local(camera.global_position)
		return local_pos.x
	return -1.0

func _update_attractor_display():
	# Calculate logistic map attractor for current r
	var x = 0.5
	
	# Warmup iterations
	for i in range(warmup_iterations):
		x = _current_r * x * (1.0 - x)
	
	# Collect attractor points
	var attractor_values: Array[float] = []
	for i in range(attractor_points):
		x = _current_r * x * (1.0 - x)
		attractor_values.append(x)
	
	# Get color based on r
	var color = _get_phase_color(_current_r)
	
	# Update point positions
	var x_pos = _r_to_x(_current_r)
	for i in range(attractor_points):
		var point = _point_meshes[i]
		var y = attractor_values[i] * display_height + 0.5
		
		point.position = Vector3(x_pos, y, 0)
		point.visible = true
		
		var mat = point.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = color
			mat.emission = color

func _get_phase_color(r: float) -> Color:
	if r < R_STABLE:
		return stable_color
	elif r < R_CHAOS:
		# Transition zone
		var t = (r - R_STABLE) / (R_CHAOS - R_STABLE)
		return stable_color.lerp(edge_color, t)
	else:
		# Chaos zone
		var t = minf((r - R_CHAOS) / (r_max - R_CHAOS), 1.0)
		return edge_color.lerp(chaos_color, t)

func _get_phase_name(r: float) -> String:
	if r < R_STABLE:
		return "STABLE FIXED POINT"
	elif r < R_PERIOD2:
		return "FIXED POINT"
	elif r < R_PERIOD4:
		return "PERIOD-2 CYCLE"
	elif r < R_CHAOS:
		return "PERIOD DOUBLING"
	elif r < R_BAND3 - 0.02:
		return "CHAOS"
	elif r < R_BAND3 + 0.02:
		return "PERIOD-3 WINDOW"
	else:
		return "CHAOS"

func _update_labels():
	var x_pos = _r_to_x(_current_r)
	
	_r_label.position.x = x_pos
	_r_label.text = "r = %.4f" % _current_r
	_r_label.modulate = _get_phase_color(_current_r)
	
	_phase_label.position.x = x_pos
	_phase_label.text = _get_phase_name(_current_r)
	_phase_label.modulate = _get_phase_color(_current_r)

func _update_marker(player_x: float):
	_player_marker.position.x = clampf(player_x, 0, walkway_length)
	_player_marker.material_override.albedo_color = _get_phase_color(_current_r)
	_player_marker.material_override.emission = _get_phase_color(_current_r)

## External API for testing without player
func set_r(r: float):
	_current_r = clampf(r, r_min, r_max)
	_update_attractor_display()
	_update_labels()
	_update_marker(_r_to_x(_current_r))
