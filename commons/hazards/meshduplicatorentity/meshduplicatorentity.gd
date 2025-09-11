# MeshDuplicatorEntity.gd
# Entity that finds and duplicates meshes in the scene, causing visual chaos
extends Node3D
class_name MeshDuplicatorEntity

# Duplication settings
@export var scan_radius: float = 20.0
@export var duplication_interval: float = 3.0
@export var max_duplicates_per_mesh: int = 5
@export var max_total_duplicates: int = 50
@export var duplicate_lifetime: float = 15.0

# Chaos settings
@export var random_position_offset: float = 5.0
@export var random_scale_variation: float = 2.0
@export var random_rotation: bool = true
@export var glitch_materials: bool = true
@export var duplicate_physics: bool = false

# Visual effects
@export var entity_color: Color = Color(1.0, 0.0, 1.0, 1.0)  # Magenta
@export var scan_effect_color: Color = Color(0.0, 1.0, 1.0, 0.5)  # Cyan
@export var duplication_effect_intensity: float = 2.0

# Audio
@export var scan_sound: AudioStream
@export var duplicate_sound: AudioStream
@export var glitch_sound: AudioStream

# Internal state
var duplication_timer: float = 0.0
var scanned_meshes: Array = []
var created_duplicates: Array = []
var scan_particles: GPUParticles3D
var entity_mesh: MeshInstance3D
var audio_player: AudioStreamPlayer3D

# Scanning state
var is_scanning: bool = false
var scan_timer: float = 0.0
var current_scan_target: MeshInstance3D

# Duplicate tracking
class DuplicateData:
	var mesh_instance: MeshInstance3D
	var original_mesh: MeshInstance3D
	var creation_time: float
	var glitch_timer: float = 0.0
	var is_glitching: bool = false
	
	func _init(instance: MeshInstance3D, original: MeshInstance3D):
		mesh_instance = instance
		original_mesh = original
		creation_time = Time.get_time_dict_from_system().second + Time.get_time_dict_from_system().minute * 60

signal mesh_found(mesh_instance: MeshInstance3D)
signal mesh_duplicated(original: MeshInstance3D, duplicate: MeshInstance3D)
signal chaos_level_increased(level: int)
signal entity_overloaded()

func _ready():
	# Create entity appearance
	_create_entity_mesh()
	
	# Setup scanning effects
	_create_scan_effects()
	
	# Setup audio
	_setup_audio()
	
	# Add to group for identification
	add_to_group("mesh_duplicator")
	
	print("MeshDuplicatorEntity: Chaos entity initialized")

func _create_entity_mesh():
	entity_mesh = MeshInstance3D.new()
	
	# Create otherworldly appearance
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.8
	sphere_mesh.height = 1.6
	entity_mesh.mesh = sphere_mesh
	
	# Create chaotic material
	var entity_material = StandardMaterial3D.new()
	entity_material.albedo_color = entity_color
	entity_material.emission_enabled = true
	entity_material.emission = entity_color
	entity_material.emission_energy = 3.0
	entity_material.metallic = 0.8
	entity_material.roughness = 0.1
	entity_material.flags_transparent = true
	entity_material.albedo_color.a = 0.8
	entity_mesh.material_override = entity_material
	
	add_child(entity_mesh)
	
	# Add rotating details
	_create_entity_details()

func _create_entity_details():
	# Create orbiting "data fragments"
	for i in range(6):
		var fragment = MeshInstance3D.new()
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(0.1, 0.1, 0.1)
		fragment.mesh = box_mesh
		
		var fragment_material = StandardMaterial3D.new()
		fragment_material.albedo_color = Color(randf(), randf(), randf(), 1.0)
		fragment_material.emission_enabled = true
		fragment_material.emission = fragment_material.albedo_color
		fragment_material.emission_energy = 2.0
		fragment.material_override = fragment_material
		
		# Position in orbit
		var angle = (float(i) / 6.0) * 2.0 * PI
		var radius = 1.5
		fragment.position = Vector3(cos(angle) * radius, sin(angle * 2) * 0.5, sin(angle) * radius)
		
		entity_mesh.add_child(fragment)

func _create_scan_effects():
	# Create scanning particle system
	scan_particles = GPUParticles3D.new()
	scan_particles.emitting = false
	scan_particles.amount = 100
	scan_particles.lifetime = 2.0
	
	var scan_material = ParticleProcessMaterial.new()
	scan_material.direction = Vector3(0, 0, 1)
	scan_material.spread = 45.0
	scan_material.initial_velocity_min = 5.0
	scan_material.initial_velocity_max = 15.0
	scan_material.gravity = Vector3(0, 0, 0)
	scan_material.scale_min = 0.1
	scan_material.scale_max = 0.3
	
	# Scan effect colors
	var scan_gradient = Gradient.new()
	scan_gradient.add_point(0.0, scan_effect_color)
	scan_gradient.add_point(0.5, Color(scan_effect_color.r, scan_effect_color.g, scan_effect_color.b, 0.7))
	scan_gradient.add_point(1.0, Color(scan_effect_color.r * 0.3, scan_effect_color.g * 0.3, scan_effect_color.b * 0.3, 0.0))
	
	var scan_texture = GradientTexture1D.new()
	scan_texture.gradient = scan_gradient
	scan_material.color_ramp = scan_texture
	
	scan_particles.process_material = scan_material
	scan_particles.draw_pass_1 = QuadMesh.new()
	add_child(scan_particles)

func _setup_audio():
	audio_player = AudioStreamPlayer3D.new()
	add_child(audio_player)

func _process(delta):
	duplication_timer += delta
	scan_timer += delta
	
	# Animate entity
	_animate_entity(delta)
	
	# Perform scanning
	if duplication_timer >= duplication_interval:
		_start_scan()
		duplication_timer = 0.0
	
	# Update scanning state
	if is_scanning:
		_update_scanning(delta)
	
	# Update duplicates (glitch effects, cleanup)
	_update_duplicates(delta)

func _animate_entity(delta):
	if entity_mesh:
		# Rotate the entity
		entity_mesh.rotation.y += delta * 2.0
		entity_mesh.rotation.x += delta * 0.5
		
		# Animate orbiting fragments
		for child in entity_mesh.get_children():
			if child is MeshInstance3D:
				child.rotation.y += delta * 3.0
				child.rotation.z += delta * 2.0

func _start_scan():
	if created_duplicates.size() >= max_total_duplicates:
		emit_signal("entity_overloaded")
		print("MeshDuplicatorEntity: Maximum duplicates reached!")
		return
	
	print("MeshDuplicatorEntity: Starting mesh scan...")
	is_scanning = true
	scan_timer = 0.0
	
	# Find meshes in range
	_scan_for_meshes()
	
	# Start scan effects
	if scan_particles:
		scan_particles.emitting = true
	
	# Play scan sound
	if scan_sound:
		audio_player.stream = scan_sound
		audio_player.play()

func _scan_for_meshes():
	scanned_meshes.clear()
	
	# Get all nodes in scene
	var all_nodes = _get_all_scene_nodes(get_tree().current_scene)
	
	for node in all_nodes:
		if node is MeshInstance3D and node != entity_mesh:
			var distance = global_position.distance_to(node.global_position)
			if distance <= scan_radius:
				scanned_meshes.append(node)
				emit_signal("mesh_found", node)
	
	print("MeshDuplicatorEntity: Found ", scanned_meshes.size(), " meshes to duplicate")

func _get_all_scene_nodes(node: Node) -> Array:
	var nodes = [node]
	for child in node.get_children():
		nodes.append_array(_get_all_scene_nodes(child))
	return nodes

func _update_scanning(delta):
	if scan_timer >= 1.0:  # Scan for 1 second
		_complete_scan()
		is_scanning = false

func _complete_scan():
	if scan_particles:
		scan_particles.emitting = false
	
	if scanned_meshes.size() > 0:
		# Choose random mesh to duplicate
		var target_mesh = scanned_meshes[randi() % scanned_meshes.size()]
		_duplicate_mesh(target_mesh)

func _duplicate_mesh(original_mesh: MeshInstance3D):
	if not is_instance_valid(original_mesh):
		return
	
	# Check if we've already duplicated this mesh too many times
	var duplicate_count = _count_duplicates_of_mesh(original_mesh)
	if duplicate_count >= max_duplicates_per_mesh:
		print("MeshDuplicatorEntity: Max duplicates reached for mesh: ", original_mesh.name)
		return
	
	# Create duplicate
	var duplicate = original_mesh.duplicate()
	duplicate.name = original_mesh.name + "_DUPLICATE_" + str(randi())
	
	# Randomize position
	var random_offset = Vector3(
		randf_range(-random_position_offset, random_position_offset),
		randf_range(-random_position_offset * 0.5, random_position_offset),
		randf_range(-random_position_offset, random_position_offset)
	)
	duplicate.global_position = original_mesh.global_position + random_offset
	
	# Randomize scale
	if random_scale_variation > 0:
		var scale_factor = randf_range(0.5, random_scale_variation)
		duplicate.scale = original_mesh.scale * scale_factor
	
	# Randomize rotation
	if random_rotation:
		duplicate.rotation = Vector3(
			randf() * 2.0 * PI,
			randf() * 2.0 * PI,
			randf() * 2.0 * PI
		)
	
	# Apply glitch material
	if glitch_materials:
		_apply_glitch_material(duplicate)
	
	# Add physics if enabled
	if duplicate_physics:
		_add_physics_to_duplicate(duplicate)
	
	# Add to scene
	get_tree().current_scene.add_child(duplicate)
	
	# Track the duplicate
	var duplicate_data = DuplicateData.new(duplicate, original_mesh)
	created_duplicates.append(duplicate_data)
	
	# Create duplication effect
	_create_duplication_effect(duplicate.global_position)
	
	# Play duplicate sound
	if duplicate_sound:
		audio_player.stream = duplicate_sound
		audio_player.play()
	
	emit_signal("mesh_duplicated", original_mesh, duplicate)
	print("MeshDuplicatorEntity: Duplicated mesh: ", original_mesh.name)
	
	# Check chaos level
	_check_chaos_level()

func _count_duplicates_of_mesh(original_mesh: MeshInstance3D) -> int:
	var count = 0
	for duplicate_data in created_duplicates:
		if is_instance_valid(duplicate_data.mesh_instance) and duplicate_data.original_mesh == original_mesh:
			count += 1
	return count

func _apply_glitch_material(duplicate: MeshInstance3D):
	# Create glitchy material
	var glitch_material = StandardMaterial3D.new()
	
	# Random chaotic colors
	glitch_material.albedo_color = Color(
		randf(),
		randf(),
		randf(),
		randf_range(0.5, 1.0)
	)
	
	# Glitch effects
	glitch_material.emission_enabled = true
	glitch_material.emission = Color(randf(), randf(), randf())
	glitch_material.emission_energy = randf_range(1.0, 5.0)
	glitch_material.metallic = randf()
	glitch_material.roughness = randf()
	
	# Random transparency
	if randf() < 0.3:  # 30% chance of transparency
		glitch_material.flags_transparent = true
		glitch_material.albedo_color.a = randf_range(0.3, 0.8)
	
	# Random shader effects
	if randf() < 0.2:  # 20% chance of wireframe
		glitch_material.flags_use_point_size = true
		glitch_material.wireframe = true
	
	duplicate.material_override = glitch_material

func _add_physics_to_duplicate(duplicate: MeshInstance3D):
	# Convert to RigidBody3D for chaos physics
	var parent = duplicate.get_parent()
	var rigid_body = RigidBody3D.new()
	rigid_body.name = duplicate.name + "_PHYSICS"
	rigid_body.global_position = duplicate.global_position
	rigid_body.rotation = duplicate.rotation
	rigid_body.scale = duplicate.scale
	
	# Move mesh to rigid body
	duplicate.get_parent().remove_child(duplicate)
	rigid_body.add_child(duplicate)
	duplicate.position = Vector3.ZERO
	duplicate.rotation = Vector3.ZERO
	
	# Create collision shape (approximate)
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	
	# Try to get mesh bounds
	if duplicate.mesh:
		var aabb = duplicate.mesh.get_aabb()
		box_shape.size = aabb.size * duplicate.scale
	else:
		box_shape.size = Vector3(1, 1, 1)  # Default size
	
	collision_shape.shape = box_shape
	rigid_body.add_child(collision_shape)
	
	# Add some random force
	rigid_body.linear_velocity = Vector3(
		randf_range(-5, 5),
		randf_range(0, 10),
		randf_range(-5, 5)
	)
	rigid_body.angular_velocity = Vector3(
		randf_range(-3, 3),
		randf_range(-3, 3),
		randf_range(-3, 3)
	)
	
	parent.add_child(rigid_body)
	
	# Update our tracking to point to the rigid body's mesh
	for duplicate_data in created_duplicates:
		if duplicate_data.mesh_instance == duplicate:
			duplicate_data.mesh_instance = duplicate

func _create_duplication_effect(position: Vector3):
	# Create flashy duplication particles
	var effect_particles = GPUParticles3D.new()
	effect_particles.global_position = position
	effect_particles.emitting = true
	effect_particles.amount = 50
	effect_particles.lifetime = 1.5
	effect_particles.one_shot = true
	
	var effect_material = ParticleProcessMaterial.new()
	effect_material.direction = Vector3(0, 1, 0)
	effect_material.spread = 45.0
	effect_material.initial_velocity_min = 8.0
	effect_material.initial_velocity_max = 15.0
	effect_material.gravity = Vector3(0, -5.0, 0)
	effect_material.scale_min = 0.2
	effect_material.scale_max = 0.8
	
	# Chaotic colors
	var effect_gradient = Gradient.new()
	effect_gradient.add_point(0.0, Color(1, 0, 1, 1))  # Magenta
	effect_gradient.add_point(0.5, Color(0, 1, 1, 0.8))  # Cyan
	effect_gradient.add_point(1.0, Color(1, 1, 0, 0))  # Yellow to transparent
	
	var effect_texture = GradientTexture1D.new()
	effect_texture.gradient = effect_gradient
	effect_material.color_ramp = effect_texture
	
	effect_particles.process_material = effect_material
	effect_particles.draw_pass_1 = QuadMesh.new()
	add_child(effect_particles)
	
	# Clean up effect
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 3.0
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(effect_particles.queue_free)
	add_child(cleanup_timer)
	cleanup_timer.start()

func _update_duplicates(delta):
	var duplicates_to_remove = []
	var current_time = Time.get_time_dict_from_system().second + Time.get_time_dict_from_system().minute * 60
	
	for i in range(created_duplicates.size()):
		var duplicate_data = created_duplicates[i]
		
		# Check if duplicate still exists
		if not is_instance_valid(duplicate_data.mesh_instance):
			duplicates_to_remove.append(i)
			continue
		
		# Update glitch effects
		duplicate_data.glitch_timer += delta
		if duplicate_data.glitch_timer >= 2.0:  # Glitch every 2 seconds
			_apply_random_glitch(duplicate_data)
			duplicate_data.glitch_timer = 0.0
		
		# Check lifetime
		var age = current_time - duplicate_data.creation_time
		if age >= duplicate_lifetime:
			duplicates_to_remove.append(i)
			_destroy_duplicate(duplicate_data)
	
	# Remove expired duplicates
	for i in range(duplicates_to_remove.size() - 1, -1, -1):
		created_duplicates.remove_at(duplicates_to_remove[i])

func _apply_random_glitch(duplicate_data: DuplicateData):
	if not is_instance_valid(duplicate_data.mesh_instance):
		return
	
	var glitch_type = randi() % 4
	
	match glitch_type:
		0:  # Color glitch
			_glitch_color(duplicate_data.mesh_instance)
		1:  # Scale glitch
			_glitch_scale(duplicate_data.mesh_instance)
		2:  # Position glitch
			_glitch_position(duplicate_data.mesh_instance)
		3:  # Visibility glitch
			_glitch_visibility(duplicate_data.mesh_instance)

func _glitch_color(mesh_instance: MeshInstance3D):
	if mesh_instance.material_override:
		var material = mesh_instance.material_override
		if material is StandardMaterial3D:
			material.albedo_color = Color(randf(), randf(), randf(), material.albedo_color.a)
			material.emission = Color(randf(), randf(), randf())

func _glitch_scale(mesh_instance: MeshInstance3D):
	var glitch_scale = randf_range(0.5, 2.0)
	mesh_instance.scale = mesh_instance.scale * glitch_scale

func _glitch_position(mesh_instance: MeshInstance3D):
	var glitch_offset = Vector3(
		randf_range(-2, 2),
		randf_range(-1, 3),
		randf_range(-2, 2)
	)
	mesh_instance.global_position += glitch_offset

func _glitch_visibility(mesh_instance: MeshInstance3D):
	mesh_instance.visible = !mesh_instance.visible
	
	# Make it visible again after a short time
	var visibility_timer = Timer.new()
	visibility_timer.wait_time = randf_range(0.1, 0.5)
	visibility_timer.one_shot = true
	visibility_timer.timeout.connect(func(): mesh_instance.visible = true)
	add_child(visibility_timer)
	visibility_timer.start()

func _destroy_duplicate(duplicate_data: DuplicateData):
	if is_instance_valid(duplicate_data.mesh_instance):
		# Create destruction effect
		_create_destruction_effect(duplicate_data.mesh_instance.global_position)
		
		# Remove the duplicate
		duplicate_data.mesh_instance.queue_free()
		print("MeshDuplicatorEntity: Destroyed duplicate: ", duplicate_data.mesh_instance.name)

func _create_destruction_effect(position: Vector3):
	# Create implosion effect
	var destruction_particles = GPUParticles3D.new()
	destruction_particles.global_position = position
	destruction_particles.emitting = true
	destruction_particles.amount = 30
	destruction_particles.lifetime = 1.0
	destruction_particles.one_shot = true
	
	var destruction_material = ParticleProcessMaterial.new()
	destruction_material.direction = Vector3(0, 0, 0)  # Implode towards center
	destruction_material.spread = 0.0
	destruction_material.initial_velocity_min = -10.0  # Negative for implosion
	destruction_material.initial_velocity_max = -5.0
	destruction_material.gravity = Vector3(0, 0, 0)
	destruction_material.scale_min = 0.1
	destruction_material.scale_max = 0.4
	
	var destruction_gradient = Gradient.new()
	destruction_gradient.add_point(0.0, Color.WHITE)
	destruction_gradient.add_point(0.5, Color.RED)
	destruction_gradient.add_point(1.0, Color(0, 0, 0, 0))
	
	var destruction_texture = GradientTexture1D.new()
	destruction_texture.gradient = destruction_gradient
	destruction_material.color_ramp = destruction_texture
	
	destruction_particles.process_material = destruction_material
	destruction_particles.draw_pass_1 = QuadMesh.new()
	add_child(destruction_particles)
	
	# Play glitch sound
	if glitch_sound:
		audio_player.stream = glitch_sound
		audio_player.play()
	
	# Clean up
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 2.0
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(destruction_particles.queue_free)
	add_child(cleanup_timer)
	cleanup_timer.start()

func _check_chaos_level():
	var chaos_level = created_duplicates.size() / 10  # Every 10 duplicates = 1 chaos level
	if chaos_level > 0:
		emit_signal("chaos_level_increased", chaos_level)

# Public API
func set_chaos_mode(enabled: bool):
	if enabled:
		duplication_interval = max(0.5, duplication_interval * 0.5)  # Faster duplication
		max_duplicates_per_mesh = max_duplicates_per_mesh * 2
		random_scale_variation = random_scale_variation * 2
		glitch_materials = true
		duplicate_physics = true
	else:
		duplication_interval = duplication_interval * 2
		max_duplicates_per_mesh = max(1, max_duplicates_per_mesh / 2)
		random_scale_variation = max(1.0, random_scale_variation * 0.5)
		glitch_materials = false
		duplicate_physics = false

func get_duplicate_count() -> int:
	return created_duplicates.size()

func clear_all_duplicates():
	for duplicate_data in created_duplicates:
		_destroy_duplicate(duplicate_data)
	created_duplicates.clear()
	print("MeshDuplicatorEntity: Cleared all duplicates")

func target_specific_mesh(mesh_name: String):
	# Find and duplicate a specific mesh by name
	var all_nodes = _get_all_scene_nodes(get_tree().current_scene)
	for node in all_nodes:
		if node is MeshInstance3D and node.name.contains(mesh_name):
			_duplicate_mesh(node)
			break

func set_duplication_rate(new_interval: float):
	duplication_interval = max(0.1, new_interval)

func get_chaos_statistics() -> Dictionary:
	return {
		"total_duplicates": created_duplicates.size(),
		"scanned_meshes": scanned_meshes.size(),
		"is_scanning": is_scanning,
		"chaos_level": created_duplicates.size() / 10,
		"max_reached": created_duplicates.size() >= max_total_duplicates
	}

func destroy_entity():
	clear_all_duplicates()
	queue_free()
