extends Node3D

# Configurable range for cube removal
@export var x_min: float = 2.0
@export var x_max: float = 4.0
@export var y_min: float = 0.0
@export var y_max: float = 2.0
@export var z_min: float = 2.0  # Start from Z=2 to skip rows 0-1
@export var z_max: float = 21.0

# Visual enhancement parameters
@export var removal_speed: float = 1.0
@export var highlight_duration: float = 0.3
@export var show_removal_effects: bool = true
@export var show_progress_ui: bool = true

var timer: Timer
var all_boxes: Array = []
var initial_box_count: int = 0
var removed_count: int = 0

# Visual components
var camera: Camera3D
var ui_canvas: CanvasLayer
var progress_label: Label
var stats_label: Label
var removal_particles: GPUParticles3D
var highlight_material: StandardMaterial3D
var normal_material: StandardMaterial3D
var removed_material: StandardMaterial3D

func _ready():
	setup_visual_environment()
	setup_materials()
	setup_ui()
	setup_particles()
	
	# Create a timer that fires every 0.5 seconds
	timer = Timer.new()
	timer.wait_time = 0.5 / removal_speed
	timer.one_shot = false
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	
	# Find all boxes initially
	find_all_boxes()
	initial_box_count = all_boxes.size()
	
	# Display all found box names for inspection
	print("=== SCENE SCAN RESULTS ===")
	print("Found ", all_boxes.size(), " boxes total:")
	for i in range(all_boxes.size()):
		var box = all_boxes[i]
		if is_instance_valid(box):
			print("  ", i+1, ". Name: '", box.name, "' | Type: ", box.get_class(), " | Position: ", box.position)
		else:
			print("  ", i+1, ". [INVALID NODE]")
	print("=========================")
	
	# Start the timer
	timer.start()
	print("Started removing boxes every 0.5 seconds.")

func find_all_boxes():
	"""Find all box/cube nodes in the scene"""
	all_boxes.clear()
	var parent = get_parent()
	if not parent:
		print("No parent node found")
		return
	
	# Recursively find all boxes
	_find_boxes_recursive(parent)
	
	# Apply normal material to all found boxes
	apply_material_to_all_boxes(normal_material)

func _find_boxes_recursive(node: Node):
	"""Recursively search for box/cube nodes"""
	# Check if this node is a box/cube
	if _is_box_node(node):
		all_boxes.append(node)
		print("Found box: ", node.name, " at position: ", node.position)
	
	# Search children
	for child in node.get_children():
		_find_boxes_recursive(child)

func _is_box_node(node: Node) -> bool:
	"""Check if a node is an instance of cube_scene.tscn but NOT a teleport and NOT in rows 0-1"""
	
	# Don't remove teleport nodes
	var name_lower = node.name.to_lower()
	if name_lower.contains("teleport"):
		return false
	
	# Don't remove boxes in rows 0 and 1 (Z position 0 and 1)
	if node is Node3D:
		var pos3: Vector3 = (node as Node3D).position
		if pos3.z == 0.0 or pos3.z == 1.0:
			return false
	
	# Check if this node is an instance of cube_scene.tscn
	# Method 1: Check if the scene file path matches
	if node.scene_file_path == "res://commons/primitives/cubes/cube_scene.tscn":
		return true
	
	# Method 2: Check if it's a Node3D with specific structure
	if node.get_class() == "Node3D":
		# Look for characteristic children of cube_scene.tscn
		# This depends on the actual structure of your cube_scene.tscn
		# You might need to adjust this based on what's inside the scene
		var has_cube_characteristics = false
		
		# Check for common cube scene characteristics
		# (Adjust these based on your actual cube_scene.tscn structure)
		for child in node.get_children():
			if child.get_class() == "MeshInstance3D":
				has_cube_characteristics = true
				break
			elif child.get_class() == "CollisionShape3D":
				has_cube_characteristics = true
				break
		
		if has_cube_characteristics:
			return true
	
	return false

func cleanup_invalid_boxes():
	"""Remove invalid/freed boxes from the list"""
	var valid_boxes = []
	for box in all_boxes:
		if is_instance_valid(box):
			valid_boxes.append(box)
		else:
			print("Cleaned up invalid box reference")
	
	all_boxes = valid_boxes

func _on_timer_timeout():
	"""Called every 0.5 seconds to remove one box"""
	# Clean up invalid references first
	cleanup_invalid_boxes()
	
	if all_boxes.size() == 0:
		print("No more boxes to remove!")
		timer.stop()
		update_ui()
		return
	
	# Pick a random box to remove
	var random_index = randi() % all_boxes.size()
	var box_to_remove = all_boxes[random_index]
	
	# Check if the box is still valid
	if not is_instance_valid(box_to_remove):
		print("Box is no longer valid, removing from list")
		all_boxes.remove_at(random_index)
		return
	
	# Highlight the box before removal
	highlight_box_for_removal(box_to_remove)
	
	# Wait for highlight duration, then remove
	await get_tree().create_timer(highlight_duration).timeout
	
	# Get position for effects before removing
	var removal_position = box_to_remove.position
	
	# Remove it from our list first
	all_boxes.remove_at(random_index)
	removed_count += 1
	
	# Create removal effects
	create_removal_effect(removal_position)
	
	# Remove it from the scene
	print("Removing box: ", box_to_remove.name, " at position: ", removal_position)
	box_to_remove.queue_free()
	
	# Update UI
	update_ui()
	
	print("Boxes remaining: ", all_boxes.size())

# Manual function to start/stop the removal process
func start_removal():
	"""Start removing boxes every 0.5 seconds"""
	if timer:
		timer.start()
		print("Started box removal")

func stop_removal():
	"""Stop removing boxes"""
	if timer:
		timer.stop()
		print("Stopped box removal")

func reset_and_find_boxes():
	"""Reset the process and find all boxes again"""
	stop_removal()
	find_all_boxes()
	initial_box_count = all_boxes.size()
	removed_count = 0
	update_ui()
	print("Reset complete. Found ", all_boxes.size(), " boxes.")

#=============================================================================
#  Visual Enhancement Functions
#=============================================================================

func setup_visual_environment():
	"""Set up lighting, camera, and environment for better visualization"""
	# Add environment
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.1, 0.1, 0.15)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.3, 0.3, 0.4)
	env.environment = environment
	add_child(env)
	
	# Add directional light
	var light = DirectionalLight3D.new()
	light.transform.basis = Basis.from_euler(Vector3(-0.5, 0.3, 0))
	light.light_energy = 1.2
	light.shadow_enabled = true
	add_child(light)
	
	# Add camera
	camera = Camera3D.new()
	camera.position = Vector3(10, 8, 10)
	camera.look_at_from_position(camera.position, Vector3(0, 0, 0), Vector3.UP)
	camera.fov = 60.0
	add_child(camera)

func setup_materials():
	"""Create materials for different box states"""
	# Normal box material
	normal_material = StandardMaterial3D.new()
	normal_material.albedo_color = Color(0.2, 0.6, 0.9, 1.0)
	normal_material.emission_enabled = true
	normal_material.emission = Color(0.1, 0.3, 0.4, 1.0)
	normal_material.metallic = 0.3
	normal_material.roughness = 0.4
	
	# Highlight material for boxes about to be removed
	highlight_material = StandardMaterial3D.new()
	highlight_material.albedo_color = Color(1.0, 0.3, 0.2, 1.0)
	highlight_material.emission_enabled = true
	highlight_material.emission = Color(0.8, 0.2, 0.1, 1.0)
	highlight_material.metallic = 0.8
	highlight_material.roughness = 0.2
	
	# Material for removed boxes (fade out effect)
	removed_material = StandardMaterial3D.new()
	removed_material.albedo_color = Color(0.5, 0.5, 0.5, 0.3)
	removed_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	removed_material.emission_enabled = true
	removed_material.emission = Color(0.2, 0.2, 0.2, 1.0)

func setup_ui():
	"""Set up user interface for progress tracking"""
	if not show_progress_ui:
		return
		
	ui_canvas = CanvasLayer.new()
	add_child(ui_canvas)
	
	# Progress label
	progress_label = Label.new()
	progress_label.position = Vector2(20, 20)
	progress_label.add_theme_font_size_override("font_size", 24)
	progress_label.text = "Random Box Removal Algorithm"
	ui_canvas.add_child(progress_label)
	
	# Stats label
	stats_label = Label.new()
	stats_label.position = Vector2(20, 60)
	stats_label.add_theme_font_size_override("font_size", 18)
	ui_canvas.add_child(stats_label)
	
	update_ui()

func setup_particles():
	"""Set up particle system for removal effects"""
	if not show_removal_effects:
		return
		
	removal_particles = GPUParticles3D.new()
	removal_particles.emitting = false
	removal_particles.amount = 50
	removal_particles.lifetime = 1.0
	removal_particles.explosiveness = 1.0
	
	# Configure particle properties
	removal_particles.process_material = ParticleProcessMaterial.new()
	var material = removal_particles.process_material as ParticleProcessMaterial
	material.direction = Vector3(0, 1, 0)
	material.initial_velocity_min = 2.0
	material.initial_velocity_max = 8.0
	material.gravity = Vector3(0, -9.8, 0)
	material.scale_min = 0.1
	material.scale_max = 0.3
	
	add_child(removal_particles)

func update_ui():
	"""Update the UI with current progress"""
	if not show_progress_ui or not stats_label:
		return
		
	var remaining = all_boxes.size()
	var progress_percent = (removed_count / float(initial_box_count)) * 100.0 if initial_box_count > 0 else 0.0
	
	stats_label.text = "Boxes Removed: %d / %d (%.1f%%)\nRemaining: %d" % [removed_count, initial_box_count, progress_percent, remaining]

func highlight_box_for_removal(box: Node3D):
	"""Highlight a box before removing it"""
	if not is_instance_valid(box):
		return
		
	# Find the mesh instance in the box and apply highlight material
	var mesh_instance = find_mesh_instance(box)
	if mesh_instance:
		mesh_instance.material_override = highlight_material
		
		# Add pulsing effect
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(mesh_instance, "scale", Vector3.ONE * 1.2, highlight_duration / 2)
		tween.tween_property(mesh_instance, "scale", Vector3.ONE, highlight_duration / 2)

func find_mesh_instance(node: Node) -> MeshInstance3D:
	"""Find the MeshInstance3D in a node hierarchy"""
	if node is MeshInstance3D:
		return node as MeshInstance3D
		
	for child in node.get_children():
		var result = find_mesh_instance(child)
		if result:
			return result
			
	return null

func create_removal_effect(position: Vector3):
	"""Create visual effect when a box is removed"""
	if not show_removal_effects or not removal_particles:
		return
		
	removal_particles.position = position
	removal_particles.restart()
	
	# Add screen shake effect
	if camera:
		var tween = create_tween()
		var original_pos = camera.position
		tween.tween_property(camera, "position", original_pos + Vector3(randf_range(-0.2, 0.2), randf_range(-0.2, 0.2), 0), 0.1)
		tween.tween_property(camera, "position", original_pos, 0.1)

func apply_material_to_all_boxes(material: StandardMaterial3D):
	"""Apply a material to all boxes in the scene"""
	for box in all_boxes:
		if is_instance_valid(box):
			var mesh_instance = find_mesh_instance(box)
			if mesh_instance:
				mesh_instance.material_override = material
