extends Node3D
class_name SoftBodyStopper

# Configuration
@export var stop_after_seconds: float = 4.0
@export var soft_body_scene_path: String = "res://algorithms/physicssimulation/softbodies/softbodystop/softbodybody.tscn"
@export var auto_start: bool = true
@export var show_timer: bool = true

# Internal variables
var target_soft_body: SoftBody3D
var stop_timer: Timer
var ui_label: Label
var is_stopped: bool = false

func _ready():
	find_target_soft_body()
	setup_stop_timer()
	setup_ui()
	
	if auto_start:
		start_timer()
	
	print("ðŸŽ¯ SoftBody Stopper ready - target: ", target_soft_body.name if target_soft_body else "NOT FOUND")

func find_target_soft_body():
	"""Find the soft body to control"""
	
	# Method 1: Try to find by scene path
	var soft_body_scene = load(soft_body_scene_path)
	if soft_body_scene:
		print("âœ… Found soft body scene: ", soft_body_scene_path)
	
	# Method 2: Search through current scene tree
	target_soft_body = find_soft_body_in_scene()
	
	if target_soft_body:
		print("ðŸŽ¯ Target soft body found: ", target_soft_body.name)
		print("   Position: ", target_soft_body.global_position)
		print("   Stiffness: ", target_soft_body.linear_stiffness)
		print("   Mass: ", target_soft_body.total_mass)
	else:
		print("âŒ No soft body found! Make sure the soft body exists in the scene.")

func find_soft_body_in_scene() -> SoftBody3D:
	"""Search for SoftBody3D nodes in the current scene"""
	
	# Get the main scene (stopscene.tscn)
	var root = get_tree().current_scene
	
	# Search for SoftBody3D nodes
	var soft_bodies = find_nodes_of_type(root, SoftBody3D)
	
	if soft_bodies.size() > 0:
		print("ðŸ” Found %d soft body nodes:" % soft_bodies.size())
		for i in range(soft_bodies.size()):
			var sb = soft_bodies[i] as SoftBody3D
			print("   %d: %s at %s" % [i, sb.name, sb.global_position])
		
		# Return the first one found
		return soft_bodies[0] as SoftBody3D
	
	return null

func find_nodes_of_type(node: Node, node_type) -> Array:
	"""Recursively find all nodes of a specific type"""
	var found_nodes = []
	
	# Check current node
	if node.get_class() == str(node_type).get_slice(":", 0):
		found_nodes.append(node)
	
	# Also check with is operator for more reliable type checking
	if node is SoftBody3D:
		if not found_nodes.has(node):
			found_nodes.append(node)
	
	# Check children
	for child in node.get_children():
		found_nodes.append_array(find_nodes_of_type(child, node_type))
	
	return found_nodes

func setup_stop_timer():
	"""Setup the timer to stop the soft body"""
	
	stop_timer = Timer.new()
	stop_timer.name = "StopTimer"
	stop_timer.wait_time = stop_after_seconds
	stop_timer.one_shot = true
	stop_timer.timeout.connect(_on_stop_timeout)
	add_child(stop_timer)

func setup_ui():
	"""Setup UI display"""
	
	if not show_timer:
		return
	
	var canvas = CanvasLayer.new()
	canvas.name = "TimerUI"
	
	ui_label = Label.new()
	ui_label.position = Vector2(50, 50)
	ui_label.add_theme_font_size_override("font_size", 24)
	ui_label.text = "SoftBody Timer: %.1fs" % stop_after_seconds
	
	canvas.add_child(ui_label)
	add_child(canvas)

func start_timer():
	"""Start the stop timer"""
	
	if not target_soft_body:
		print("âŒ Cannot start timer - no soft body found!")
		return
	
	if stop_timer:
		stop_timer.start()
		print("â° Timer started - will stop soft body in %.1f seconds" % stop_after_seconds)

func _process(_delta):
	"""Update UI display"""
	
	if ui_label and stop_timer and not is_stopped:
		var time_left = stop_timer.time_left
		ui_label.text = "SoftBody Timer: %.1fs" % time_left
		
		# Change color as time runs out
		if time_left < 2.0:
			ui_label.add_theme_color_override("font_color", Color.RED)
		elif time_left < 3.0:
			ui_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			ui_label.add_theme_color_override("font_color", Color.WHITE)

func _on_stop_timeout():
	"""Called when timer expires - stop the soft body"""
	
	print("â° TIMEOUT - Stopping soft body!")
	stop_soft_body()

func stop_soft_body():
	"""Stop the target soft body"""
	
	if not target_soft_body:
		print("âŒ Cannot stop - no soft body found!")
		return
	
	if is_stopped:
		print("âš ï¸  Soft body already stopped!")
		return
	
	is_stopped = true
	
	print("ðŸ›‘ Stopping soft body: ", target_soft_body.name)
	
	# Method 1: Freeze the soft body
	freeze_soft_body()
	
	# Update UI
	if ui_label:
		ui_label.text = "SoftBody STOPPED!"
		ui_label.add_theme_color_override("font_color", Color.RED)

func freeze_soft_body():
	"""Stop the soft body using SoftBody3D-compatible methods"""
	
	# Method 1: Disable physics processing entirely
	target_soft_body.set_process_mode(Node.PROCESS_MODE_DISABLED)
	
	# Method 2: Apply extreme damping to stop any movement
	target_soft_body.damping_coefficient = 100.0
	
	# Method 3: Make it completely rigid
	target_soft_body.linear_stiffness = 1.0
	
	# Store original values for later restoration
	target_soft_body.set_meta("original_damping", 0.01)
	target_soft_body.set_meta("original_stiffness", 0.5)
	

	print("ðŸ§Š Soft body stopped successfully!")

func _get_soft_body_material(soft_body: SoftBody3D, surface_index: int = 0) -> Material:
	"""Resolve material safely for SoftBody3D instances in Godot 4."""
	if soft_body.material_override != null:
		return soft_body.material_override
	
	var override_material = soft_body.get_surface_override_material(surface_index)
	if override_material != null:
		return override_material
	
	var active_material = soft_body.get_active_material(surface_index)
	if active_material != null:
		return active_material
	
	if soft_body.mesh != null and surface_index < soft_body.mesh.get_surface_count():
		return soft_body.mesh.surface_get_material(surface_index)
	
	return null

func disable_soft_body():
	"""Alternative: Disable physics processing"""
	
	target_soft_body.set_process_mode(Node.PROCESS_MODE_DISABLED)
	
	# Visual feedback - gray out
	var material = _get_soft_body_material(target_soft_body, 0)
	if material is StandardMaterial3D:
		var std_mat = material as StandardMaterial3D
		std_mat.albedo_color = Color(0.3, 0.3, 0.3, 0.6)  # Gray out
	
	print("ðŸš« Soft body disabled!")

func high_damping_stop():
	"""Alternative: Use high damping to gradually stop"""
	
	target_soft_body.damping_coefficient = 10.0
	target_soft_body.drag_coefficient = 10.0
	
	print("ðŸŒ Applied high damping - soft body will slow down gradually")

func restart_soft_body():
	"""Restart/unfreeze the soft body"""
	
	if not target_soft_body or not is_stopped:
		return
	
	print("ðŸ”„ Restarting soft body...")
	
	# Re-enable processing
	target_soft_body.set_process_mode(Node.PROCESS_MODE_INHERIT)
	
	# Restore original physics properties
	if target_soft_body.has_meta("original_damping"):
		target_soft_body.damping_coefficient = target_soft_body.get_meta("original_damping")
	
	if target_soft_body.has_meta("original_stiffness"):
		target_soft_body.linear_stiffness = target_soft_body.get_meta("original_stiffness")
	
	if target_soft_body.has_meta("original_layer"):
		target_soft_body.collision_layer = target_soft_body.get_meta("original_layer")
		target_soft_body.collision_mask = target_soft_body.get_meta("original_mask")
	
	# Reset drag if it exists
	if target_soft_body.has_method("set_drag_coefficient"):
		target_soft_body.drag_coefficient = 0.0
	
	# Restore original visual
	var material = _get_soft_body_material(target_soft_body, 0)
	if material is StandardMaterial3D and target_soft_body.has_meta("original_color"):
		var std_mat = material as StandardMaterial3D
		std_mat.emission_enabled = false
		std_mat.albedo_color = target_soft_body.get_meta("original_color")
	
	is_stopped = false
	
	# Restart timer
	if stop_timer:
		stop_timer.start(stop_after_seconds)
	
	if ui_label:
		ui_label.add_theme_color_override("font_color", Color.WHITE)
	
	print("âœ… Soft body restarted!")

func _input(event):
	"""Handle input for manual control"""
	
	if event.is_action_pressed("ui_accept"):  # Space key
		if is_stopped:
			restart_soft_body()
		else:
			print("ðŸ›‘ Manual stop requested")
			stop_timer.stop()
			stop_soft_body()
	
	if event.is_action_pressed("ui_select"):  # Enter key
		if target_soft_body:
			print("ðŸ“Š Soft body info:")
			print("   Name: ", target_soft_body.name)
			print("   Position: ", target_soft_body.global_position)
			print("   Velocity: ", target_soft_body.linear_velocity)
			print("   Frozen: ", target_soft_body.freeze)
			print("   Stiffness: ", target_soft_body.linear_stiffness)
			print("   Damping: ", target_soft_body.damping_coefficient)
	
	if event.is_action_pressed("ui_cancel"):  # Escape key
		if target_soft_body:
			# Apply a random impulse to make it interesting
			var random_impulse = Vector3(
				randf_range(-5, 5),
				randf_range(5, 10),
				randf_range(-5, 5)
			)
			target_soft_body.apply_central_impulse(random_impulse)
			print("ðŸ’¥ Applied random impulse: ", random_impulse)

# Public functions for external control

func stop_now():
	"""Public function to stop immediately"""
	stop_timer.stop()
	stop_soft_body()

func set_timer(seconds: float):
	"""Public function to set timer duration"""
	stop_after_seconds = seconds
	if stop_timer:
		stop_timer.wait_time = seconds

func get_soft_body() -> SoftBody3D:
	"""Public function to get reference to the soft body"""
	return target_soft_body
