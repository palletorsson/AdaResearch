extends Node3D

# Interactive VR Dice Roll - Discrete Probability Distributions
# Demonstrates uniform distributions, expected values, and statistical variance

class_name DiceRollVR

# VR Settings
@export_category("VR Configuration")
@export var enable_vr: bool = true

# Dice Settings
@export_category("Dice Properties")
@export var dice_count: int = 2
@export var dice_size: float = 0.08
@export var throw_force: float = 8.0
@export var dice_materials: Array[StandardMaterial3D] = []

# Statistics Settings
@export_category("Statistics")
@export var max_rolls: int = 500
@export var show_distribution: bool = true
@export var show_expected_value: bool = true

# Visual Settings
@export_category("Visualization")
@export var histogram_size: Vector3 = Vector3(3.0, 2.0, 0.1)
@export var dice_spawn_height: float = 2.0

# Internal variables
var dice_instances: Array[RigidBody3D] = []
var roll_count: int = 0
var roll_results: Array[Array] = []
var sum_results: Array[int] = []
var individual_face_counts: Array[Array] = []

# VR Components
var xr_origin: XROrigin3D
var left_controller: XRController3D
var right_controller: XRController3D

# UI Elements
var stats_display: Label3D
var histogram_display: Node3D
var expected_value_line: Node3D

# Physics
var dice_spawn_area: Vector3 = Vector3(1.0, 0, 1.0)
var table_surface: StaticBody3D

func _ready():
	setup_vr()
	create_dice_set()
	setup_table()
	setup_ui()
	setup_histogram_display()
	initialize_statistics()

func setup_vr():
	"""Initialize VR system"""
	if enable_vr:
		var xr_interface = XRServer.find_interface("OpenXR")
		if xr_interface and xr_interface.is_initialized():
			get_viewport().use_xr = true
		else:
			enable_vr = false
	
	xr_origin = XROrigin3D.new()
	add_child(xr_origin)
	
	var xr_camera = XRCamera3D.new()
	xr_origin.add_child(xr_camera)
	
	if enable_vr:
		left_controller = XRController3D.new()
		left_controller.tracker = &"left_hand"
		left_controller.button_pressed.connect(_on_controller_button)
		xr_origin.add_child(left_controller)
		
		right_controller = XRController3D.new()
		right_controller.tracker = &"right_hand"
		right_controller.button_pressed.connect(_on_controller_button)
		xr_origin.add_child(right_controller)

func create_dice_set():
	"""Create set of interactive dice"""
	for i in range(dice_count):
		var die = create_single_die(i)
		dice_instances.append(die)
		add_child(die)

func create_single_die(index: int) -> RigidBody3D:
	"""Create a single die with physics"""
	var die = RigidBody3D.new()
	die.name = "Die_" + str(index)
	
	# Die mesh (cube)
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3.ONE * dice_size
	mesh_instance.mesh = box_mesh
	
	# Apply material
	if dice_materials.size() > index:
		mesh_instance.material_override = dice_materials[index]
	else:
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.from_hsv(float(index) / float(dice_count), 0.8, 0.9)
		material.metallic = 0.3
		material.roughness = 0.4
		mesh_instance.material_override = material
	
	# Collision shape
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3.ONE * dice_size
	collision_shape.shape = box_shape
	
	die.add_child(mesh_instance)
	die.add_child(collision_shape)
	
	# Add face numbers as labels
	add_die_face_numbers(die)
	
	return die

func add_die_face_numbers(die: RigidBody3D):
	"""Add number labels to each face of the die"""
	var face_positions = [
		Vector3(0, 0, dice_size/2),    # Front (1)
		Vector3(0, 0, -dice_size/2),   # Back (6)
		Vector3(dice_size/2, 0, 0),    # Right (2)
		Vector3(-dice_size/2, 0, 0),   # Left (5)
		Vector3(0, dice_size/2, 0),    # Top (3)
		Vector3(0, -dice_size/2, 0)    # Bottom (4)
	]
	
	var face_numbers = [1, 6, 2, 5, 3, 4]
	
	for i in range(6):
		var label = Label3D.new()
		label.text = str(face_numbers[i])
		label.position = face_positions[i]
		label.font_size = 24
		label.modulate = Color.BLACK
		die.add_child(label)

func setup_table():
	"""Create table surface for dice to land on"""
	table_surface = StaticBody3D.new()
	
	var table_mesh = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(4.0, 4.0)
	table_mesh.mesh = plane_mesh
	
	var table_material = StandardMaterial3D.new()
	table_material.albedo_color = Color(0.2, 0.8, 0.2, 1.0)  # Green felt
	table_mesh.material_override = table_material
	
	var table_collision = CollisionShape3D.new()
	var plane_shape = BoxShape3D.new()
	plane_shape.size = Vector3(4.0, 0.1, 4.0)
	table_collision.shape = plane_shape
	
	table_surface.add_child(table_mesh)
	table_surface.add_child(table_collision)
	table_surface.position = Vector3(0, -0.05, 0)
	
	add_child(table_surface)

func setup_ui():
	"""Create statistics display"""
	stats_display = Label3D.new()
	stats_display.position = Vector3(-2.0, 2.0, -1.0)
	stats_display.text = "Dice Roll Statistics\nPress trigger to roll!"
	stats_display.font_size = 32
	stats_display.modulate = Color.WHITE
	add_child(stats_display)

func setup_histogram_display():
	"""Create histogram for distribution visualization"""
	histogram_display = Node3D.new()
	histogram_display.position = Vector3(2.0, 1.0, -1.0)
	add_child(histogram_display)
	
	# Background panel
	var bg = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(histogram_size.x, histogram_size.y)
	bg.mesh = plane
	
	var bg_material = StandardMaterial3D.new()
	bg_material.albedo_color = Color(0.1, 0.1, 0.1, 0.8)
	bg.material_override = bg_material
	
	histogram_display.add_child(bg)

func initialize_statistics():
	"""Initialize statistical tracking arrays"""
	for i in range(dice_count):
		individual_face_counts.append([0, 0, 0, 0, 0, 0])  # 6 faces per die

func _on_controller_button(button_name: String):
	"""Handle VR controller input"""
	if button_name == "trigger_click":
		roll_dice()

func _input(event):
	"""Handle desktop input"""
	if not enable_vr and event is InputEventKey:
		if event.pressed and event.keycode == KEY_SPACE:
			roll_dice()

func roll_dice():
	"""Execute dice roll with physics"""
	if roll_count >= max_rolls:
		return
	
	# Reset dice positions
	for i in range(dice_instances.size()):
		var die = dice_instances[i]
		var spawn_pos = Vector3(
			randf_range(-dice_spawn_area.x/2, dice_spawn_area.x/2),
			dice_spawn_height,
			randf_range(-dice_spawn_area.z/2, dice_spawn_area.z/2)
		)
		die.position = spawn_pos
		die.linear_velocity = Vector3.ZERO
		die.angular_velocity = Vector3.ZERO
		
		# Apply random throw force
		var throw_direction = Vector3(
			randf_range(-2.0, 2.0),
			randf_range(-1.0, 1.0),
			randf_range(-2.0, 2.0)
		)
		
		var spin = Vector3(
			randf_range(-10.0, 10.0),
			randf_range(-10.0, 10.0),
			randf_range(-10.0, 10.0)
		)
		
		die.apply_impulse(throw_direction * throw_force)
		die.apply_torque_impulse(spin)
	
	# Wait for dice to settle
	await get_tree().create_timer(3.0).timeout
	
	# Read results
	var roll_result = read_dice_values()
	record_roll_result(roll_result)
	update_display()

func read_dice_values() -> Array[int]:
	"""Determine face-up value for each die"""
	var results: Array[int] = []
	
	for die in dice_instances:
		var face_value = determine_face_up(die)
		results.append(face_value)
	
	return results

func determine_face_up(die: RigidBody3D) -> int:
	"""Determine which face is pointing up"""
	var up_vector = Vector3.UP
	var die_transform = die.transform
	
	# Check each face normal against world up
	var face_normals = [
		die_transform.basis.z,   # Front (1)
		-die_transform.basis.z,  # Back (6) 
		die_transform.basis.x,   # Right (2)
		-die_transform.basis.x,  # Left (5)
		die_transform.basis.y,   # Top (3)
		-die_transform.basis.y   # Bottom (4)
	]
	
	var face_values = [1, 6, 2, 5, 3, 4]
	var best_dot = -1.0
	var best_face = 1
	
	for i in range(6):
		var dot = face_normals[i].dot(up_vector)
		if dot > best_dot:
			best_dot = dot
			best_face = face_values[i]
	
	return best_face

func record_roll_result(result: Array[int]):
	"""Record roll results and update statistics"""
	roll_results.append(result)
	roll_count += 1
	
	# Calculate sum for multi-dice probability
	var sum_value = 0
	for i in range(result.size()):
		var face_value = result[i]
		sum_value += face_value
		
		# Update individual face counts
		individual_face_counts[i][face_value - 1] += 1
	
	sum_results.append(sum_value)

func update_display():
	"""Update statistics display and visualizations"""
	var display_text = "Dice Roll Statistics\n"
	display_text += "Rolls: %d/%d\n\n" % [roll_count, max_rolls]
	
	# Individual die statistics
	for i in range(dice_count):
		display_text += "Die %d:\n" % (i + 1)
		for face in range(6):
			var count = individual_face_counts[i][face]
			var percentage = float(count) / float(roll_count) * 100.0 if roll_count > 0 else 0.0
			display_text += "  %d: %d (%.1f%%)\n" % [face + 1, count, percentage]
		display_text += "\n"
	
	# Sum statistics (for multiple dice)
	if dice_count > 1:
		var sum_average = calculate_average_sum()
		var expected_average = float(dice_count) * 3.5  # Expected value per die is 3.5
		display_text += "Sum Average: %.2f\n" % sum_average
		display_text += "Expected: %.2f\n" % expected_average
		display_text += "Variance: %.2f" % calculate_sum_variance()
	
	stats_display.text = display_text
	update_histogram()

func calculate_average_sum() -> float:
	"""Calculate average of sum results"""
	if sum_results.is_empty():
		return 0.0
	
	var total = 0
	for sum_val in sum_results:
		total += sum_val
	
	return float(total) / float(sum_results.size())

func calculate_sum_variance() -> float:
	"""Calculate variance of sum results"""
	if sum_results.size() < 2:
		return 0.0
	
	var mean = calculate_average_sum()
	var variance_sum = 0.0
	
	for sum_val in sum_results:
		variance_sum += pow(sum_val - mean, 2)
	
	return variance_sum / float(sum_results.size() - 1)

func update_histogram():
	"""Update histogram display for sum distribution"""
	# Clear existing bars
	for child in histogram_display.get_children():
		if child.name.begins_with("bar_"):
			child.queue_free()
	
	if dice_count < 2 or roll_count == 0:
		return
	
	# Count occurrences of each sum
	var min_sum = dice_count
	var max_sum = dice_count * 6
	var sum_counts = {}
	
	for i in range(min_sum, max_sum + 1):
		sum_counts[i] = 0
	
	for sum_val in sum_results:
		if sum_val in sum_counts:
			sum_counts[sum_val] += 1
	
	# Create histogram bars
	var max_count = 0
	for count in sum_counts.values():
		max_count = max(max_count, count)
	
	if max_count == 0:
		return
	
	var bar_width = histogram_size.x / float(max_sum - min_sum + 1)
	
	for sum_val in range(min_sum, max_sum + 1):
		var count = sum_counts[sum_val]
		var height = float(count) / float(max_count) * histogram_size.y
		
		create_histogram_bar(sum_val, height, bar_width, min_sum, max_sum)

func create_histogram_bar(sum_value: int, height: float, width: float, min_sum: int, max_sum: int):
	"""Create a single histogram bar"""
	var bar = MeshInstance3D.new()
	bar.name = "bar_" + str(sum_value)
	
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(width * 0.8, height, 0.05)
	bar.mesh = box_mesh
	
	# Color based on theoretical probability
	var color_intensity = get_theoretical_probability(sum_value)
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(color_intensity, 0.5, 1.0 - color_intensity)
	material.emission = material.albedo_color * 0.3
	bar.material_override = material
	
	# Position
	var x_offset = float(sum_value - min_sum) / float(max_sum - min_sum) * histogram_size.x
	x_offset -= histogram_size.x / 2.0
	bar.position = Vector3(x_offset, height/2 - histogram_size.y/2, 0.01)
	
	histogram_display.add_child(bar)

func get_theoretical_probability(sum_value: int) -> float:
	"""Get theoretical probability for a sum value"""
	if dice_count != 2:
		return 0.5  # Simplified for visualization
	
	# For 2 dice, theoretical probabilities
	var probabilities = {
		2: 1.0/36.0, 3: 2.0/36.0, 4: 3.0/36.0, 5: 4.0/36.0, 6: 5.0/36.0, 7: 6.0/36.0,
		8: 5.0/36.0, 9: 4.0/36.0, 10: 3.0/36.0, 11: 2.0/36.0, 12: 1.0/36.0
	}
	
	return probabilities.get(sum_value, 0.0) * 6.0  # Scale for visualization

func get_statistics_summary() -> Dictionary:
	"""Return comprehensive statistics"""
	return {
		"roll_count": roll_count,
		"dice_count": dice_count,
		"roll_results": roll_results.duplicate(),
		"sum_results": sum_results.duplicate(),
		"individual_face_counts": individual_face_counts.duplicate(),
		"average_sum": calculate_average_sum(),
		"expected_sum": float(dice_count) * 3.5,
		"sum_variance": calculate_sum_variance()
	}