extends Node3D

# Interactive VR Coin Flip - Basic Probability Visualization
# Demonstrates fundamental probability concepts through coin flipping

class_name CoinFlipVR

# VR Settings
@export_category("VR Configuration")
@export var enable_vr: bool = true
@export var hand_tracking: bool = true

# Coin Settings
@export_category("Coin Properties")
@export var coin_size: float = 0.1
@export var flip_force: float = 5.0
@export var spin_torque: float = 10.0
@export var coin_material_heads: StandardMaterial3D
@export var coin_material_tails: StandardMaterial3D

# Statistics Settings
@export_category("Statistics")
@export var max_flips: int = 1000
@export var show_real_time_probability: bool = true
@export var show_expected_vs_actual: bool = true

# Visual Settings
@export_category("Visualization")
@export var chart_size: Vector3 = Vector3(2.0, 1.5, 0.1)
@export var update_frequency: float = 0.1

# Internal variables
var coin_instance: RigidBody3D
var flip_count: int = 0
var heads_count: int = 0
var tails_count: int = 0
var flip_results: Array[bool] = []

# VR Components
var xr_interface: XRInterface
var xr_origin: XROrigin3D
var left_controller: XRController3D
var right_controller: XRController3D

# UI Elements
var stats_panel: Control
var probability_chart: Node3D
var results_display: Label3D

# Physics
var coin_start_position: Vector3
var is_flipping: bool = false

func _ready():
	setup_vr()
	create_coin()
	setup_ui()
	setup_statistics_visualization()
	coin_start_position = Vector3(0, 1.5, -0.5)

func setup_vr():
	"""Initialize VR system"""
	if enable_vr:
		xr_interface = XRServer.find_interface("OpenXR")
		if xr_interface and xr_interface.is_initialized():
			print("VR Interface found and initialized")
			get_viewport().use_xr = true
		else:
			print("VR not available, using desktop mode")
			enable_vr = false
	
	# Create XR Origin
	xr_origin = XROrigin3D.new()
	add_child(xr_origin)
	
	# Add camera
	var xr_camera = XRCamera3D.new()
	xr_origin.add_child(xr_camera)
	
	if enable_vr:
		# Add controllers
		left_controller = XRController3D.new()
		left_controller.tracker = &"left_hand"
		left_controller.button_pressed.connect(_on_controller_button)
		xr_origin.add_child(left_controller)
		
		right_controller = XRController3D.new()
		right_controller.tracker = &"right_hand"
		right_controller.button_pressed.connect(_on_controller_button)
		xr_origin.add_child(right_controller)

func create_coin():
	"""Create interactive 3D coin"""
	coin_instance = RigidBody3D.new()
	coin_instance.position = coin_start_position
	
	# Coin mesh (cylinder)
	var mesh_instance = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.height = 0.01
	cylinder_mesh.top_radius = coin_size
	cylinder_mesh.bottom_radius = coin_size
	mesh_instance.mesh = cylinder_mesh
	
	# Collision shape
	var collision_shape = CollisionShape3D.new()
	var cylinder_shape = CylinderShape3D.new()
	cylinder_shape.height = 0.01
	cylinder_shape.radius = coin_size
	collision_shape.shape = cylinder_shape
	
	coin_instance.add_child(mesh_instance)
	coin_instance.add_child(collision_shape)
	
	# Materials for heads/tails
	if not coin_material_heads:
		coin_material_heads = StandardMaterial3D.new()
		coin_material_heads.albedo_color = Color.GOLD
		coin_material_heads.metallic = 0.8
		coin_material_heads.roughness = 0.2
	
	if not coin_material_tails:
		coin_material_tails = StandardMaterial3D.new()
		coin_material_tails.albedo_color = Color.SILVER
		coin_material_tails.metallic = 0.8
		coin_material_tails.roughness = 0.2
	
	mesh_instance.material_override = coin_material_heads
	
	add_child(coin_instance)

func setup_ui():
	"""Create VR-friendly UI for statistics display"""
	# 3D Label for results
	results_display = Label3D.new()
	results_display.position = Vector3(0, 2.0, -1.0)
	results_display.text = "Coin Flip Statistics\nPress trigger to flip!"
	results_display.font_size = 48
	results_display.modulate = Color.WHITE
	add_child(results_display)

func setup_statistics_visualization():
	"""Create real-time probability visualization"""
	probability_chart = Node3D.new()
	probability_chart.position = Vector3(1.5, 1.5, -1.0)
	add_child(probability_chart)
	
	# Create chart background
	var chart_background = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(chart_size.x, chart_size.y)
	chart_background.mesh = plane_mesh
	
	var bg_material = StandardMaterial3D.new()
	bg_material.albedo_color = Color(0.1, 0.1, 0.1, 0.8)
	chart_background.material_override = bg_material
	probability_chart.add_child(chart_background)

func _on_controller_button(button_name: String):
	"""Handle VR controller input"""
	if button_name == "trigger_click" or button_name == "grip_click":
		flip_coin()

func _input(event):
	"""Handle desktop input for testing"""
	if not enable_vr and event is InputEventKey:
		if event.pressed and event.keycode == KEY_SPACE:
			flip_coin()

func flip_coin():
	"""Execute coin flip with physics simulation"""
	if is_flipping or flip_count >= max_flips:
		return
	
	is_flipping = true
	
	# Reset coin position
	coin_instance.position = coin_start_position
	coin_instance.linear_velocity = Vector3.ZERO
	coin_instance.angular_velocity = Vector3.ZERO
	
	# Apply random flip force
	var flip_direction = Vector3(
		randf_range(-1.0, 1.0),
		flip_force,
		randf_range(-1.0, 1.0)
	)
	
	var spin_axis = Vector3(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized()
	
	coin_instance.apply_impulse(flip_direction)
	coin_instance.apply_torque_impulse(spin_axis * spin_torque)
	
	# Wait for coin to settle
	await get_tree().create_timer(2.0).timeout
	
	# Determine result
	var result = determine_coin_result()
	record_flip_result(result)
	update_display()
	
	is_flipping = false

func determine_coin_result() -> bool:
	"""Determine if coin landed heads (true) or tails (false)"""
	# Check coin's up vector
	var up_vector = coin_instance.transform.basis.y
	var world_up = Vector3.UP
	var dot_product = up_vector.dot(world_up)
	
	# If coin is facing up, it's heads
	var is_heads = dot_product > 0
	
	# Update coin material based on result
	var mesh_instance = coin_instance.get_child(0) as MeshInstance3D
	if is_heads:
		mesh_instance.material_override = coin_material_heads
	else:
		mesh_instance.material_override = coin_material_tails
	
	return is_heads

func record_flip_result(is_heads: bool):
	"""Record flip result and update statistics"""
	flip_results.append(is_heads)
	flip_count += 1
	
	if is_heads:
		heads_count += 1
	else:
		tails_count += 1

func update_display():
	"""Update statistics display"""
	var heads_probability = float(heads_count) / float(flip_count) if flip_count > 0 else 0.0
	var tails_probability = float(tails_count) / float(flip_count) if flip_count > 0 else 0.0
	
	var display_text = "Coin Flip Statistics\n"
	display_text += "Flips: %d/%d\n" % [flip_count, max_flips]
	display_text += "Heads: %d (%.1f%%)\n" % [heads_count, heads_probability * 100]
	display_text += "Tails: %d (%.1f%%)\n" % [tails_count, tails_probability * 100]
	display_text += "Expected: 50%/50%\n"
	
	if flip_count > 10:
		var deviation = abs(heads_probability - 0.5) * 100
		display_text += "Deviation: ±%.1f%%" % deviation
	
	results_display.text = display_text
	
	update_probability_chart(heads_probability)

func update_probability_chart(heads_prob: float):
	"""Update visual probability chart"""
	# Clear existing chart elements
	for child in probability_chart.get_children():
		if child.name.begins_with("bar_"):
			child.queue_free()
	
	if flip_count == 0:
		return
	
	# Create bars for heads and tails probability
	create_probability_bar("heads", heads_prob, Vector3(-0.3, 0, 0.01), Color.GOLD)
	create_probability_bar("tails", 1.0 - heads_prob, Vector3(0.3, 0, 0.01), Color.SILVER)
	
	# Expected probability line
	create_probability_line(0.5, Color.RED)

func create_probability_bar(name: String, probability: float, position: Vector3, color: Color):
	"""Create 3D bar for probability visualization"""
	var bar = MeshInstance3D.new()
	bar.name = "bar_" + name
	
	var box_mesh = BoxMesh.new()
	var bar_height = probability * chart_size.y
	box_mesh.size = Vector3(0.2, bar_height, 0.05)
	bar.mesh = box_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission = color * 0.3
	bar.material_override = material
	
	bar.position = position + Vector3(0, bar_height/2 - chart_size.y/2, 0)
	probability_chart.add_child(bar)

func create_probability_line(expected_prob: float, color: Color):
	"""Create line showing expected probability"""
	var line = MeshInstance3D.new()
	line.name = "expected_line"
	
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(chart_size.x, 0.01, 0.02)
	line.mesh = box_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission = color * 0.5
	line.material_override = material
	
	var line_y = (expected_prob - 0.5) * chart_size.y
	line.position = Vector3(0, line_y, 0.02)
	probability_chart.add_child(line)

func reset_experiment():
	"""Reset all statistics"""
	flip_count = 0
	heads_count = 0
	tails_count = 0
	flip_results.clear()
	update_display()

func get_statistics_summary() -> Dictionary:
	"""Return comprehensive statistics"""
	if flip_count == 0:
		return {}
	
	var heads_prob = float(heads_count) / float(flip_count)
	
	return {
		"total_flips": flip_count,
		"heads_count": heads_count,
		"tails_count": tails_count,
		"heads_probability": heads_prob,
		"tails_probability": 1.0 - heads_prob,
		"expected_heads": 0.5,
		"expected_tails": 0.5,
		"deviation_from_expected": abs(heads_prob - 0.5),
		"flip_sequence": flip_results.duplicate()
	}
