extends Node3D
class_name RigidBodySphereSpawner

# Spawning parameters
@export var sphere_count: int = 20
@export var spawn_radius: float = 30.0
@export var height_offset: float = 5.0
@export var auto_spawn: bool = true
@export var spawn_interval: float = 1.5
@export var max_spheres: int = 100

# Physics parameters
@export var sphere_mass: float = 1.0
@export var sphere_bounce: float = 0.6
@export var sphere_friction: float = 0.8
@export var initial_force_min: float = 5.0
@export var initial_force_max: float = 15.0
@export var gravity_scale: float = 1.0

# Visual parameters
@export var sphere_size_min: float = 0.3
@export var sphere_size_max: float = 1.2
@export var sphere_colors: Array[Color] = [
	Color(0.8, 0.2, 0.4, 1.0),  # Red
	Color(0.2, 0.8, 0.4, 1.0),  # Green
	Color(0.2, 0.4, 0.8, 1.0),  # Blue
	Color(0.8, 0.8, 0.2, 1.0),  # Yellow
	Color(0.8, 0.2, 0.8, 1.0),  # Magenta
	Color(0.2, 0.8, 0.8, 1.0),  # Cyan
	Color(1.0, 0.5, 0.2, 1.0),  # Orange
	Color(0.5, 0.2, 1.0, 1.0)   # Purple
]

# Material properties
@export var metallic: float = 0.0
@export var roughness: float = 0.4
@export var emission_enabled: bool = true
@export var emission_energy: float = 0.3

# Internal variables
var terrain_reference: QueerNoiseTerrain
var spheres: Array[RigidBody3D] = []
var spawn_timer: float = 0.0
var time_elapsed: float = 0.0
var sphere_mesh: SphereMesh
var sphere_material: StandardMaterial3D

# Collision layers
@export var collision_layer: int = 1
@export var collision_mask: int = 1

func _ready():
	"""Initialize the rigidbody sphere spawner system"""
	setup_sphere_system()
	find_terrain_reference()
	if auto_spawn:
		spawn_initial_spheres()

func _process(delta):
	"""Main update loop"""
	time_elapsed += delta
	
	if auto_spawn:
		spawn_timer += delta
		if spawn_timer >= spawn_interval and spheres.size() < max_spheres:
			spawn_timer = 0.0
			spawn_single_sphere()
	
	cleanup_fallen_spheres()

func setup_sphere_system():
	"""Setup the sphere mesh and material"""
	# Create sphere mesh
	sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 1.0
	sphere_mesh.height = 2.0
	sphere_mesh.rings = 16
	sphere_mesh.radial_segments = 32
	
	# Create base material
	sphere_material = StandardMaterial3D.new()
	sphere_material.metallic = metallic
	sphere_material.roughness = roughness
	sphere_material.emission_enabled = emission_enabled
	sphere_material.emission_energy_multiplier = emission_energy
	
	print("RigidBody Sphere Spawner: System setup complete!")

func find_terrain_reference():
	"""Find the terrain reference for height sampling"""
	# Look for terrain in parent or sibling nodes
	var parent = get_parent()
	if parent is QueerNoiseTerrain:
		terrain_reference = parent
		print("Found terrain reference in parent")
		return
	
	# Look in siblings
	if parent:
		for child in parent.get_children():
			if child is QueerNoiseTerrain:
				terrain_reference = child
				print("Found terrain reference in sibling")
				return
	
	# Look globally
	var terrain_nodes = get_tree().get_nodes_in_group("terrain")
	if terrain_nodes.size() > 0:
		terrain_reference = terrain_nodes[0]
		print("Found terrain reference globally")
	else:
		print("WARNING: No terrain reference found!")

func spawn_initial_spheres():
	"""Spawn the initial set of spheres"""
	print("Spawning ", sphere_count, " initial rigidbody spheres...")
	for i in range(sphere_count):
		spawn_single_sphere()

func spawn_single_sphere():
	"""Spawn a single rigidbody sphere"""
	# Generate random spawn position within radius
	var angle = randf() * TAU
	var distance = randf() * spawn_radius
	var spawn_pos = Vector3(
		cos(angle) * distance,
		0.0,  # Will be adjusted to terrain height
		sin(angle) * distance
	)
	
	# Adjust height to terrain if available
	if terrain_reference:
		spawn_pos.y = terrain_reference.get_height_at_world_position(spawn_pos) + height_offset
	else:
		spawn_pos.y = height_offset
	
	# Create rigidbody
	var rigidbody = RigidBody3D.new()
	rigidbody.name = "RigidSphere_" + str(spheres.size())
	rigidbody.position = spawn_pos
	rigidbody.mass = sphere_mass
	rigidbody.gravity_scale = gravity_scale
	rigidbody.collision_layer = collision_layer
	rigidbody.collision_mask = collision_mask
	
	# Create collision shape
	var collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	var sphere_size = randf_range(sphere_size_min, sphere_size_max)
	sphere_shape.radius = sphere_size
	collision_shape.shape = sphere_shape
	rigidbody.add_child(collision_shape)
	
	# Create mesh instance
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = sphere_mesh
	mesh_instance.scale = Vector3.ONE * sphere_size
	
	# Create unique material for this sphere
	var sphere_mat = sphere_material.duplicate()
	var color_index = randi() % sphere_colors.size()
	sphere_mat.albedo_color = sphere_colors[color_index]
	sphere_mat.emission = sphere_colors[color_index] * emission_energy
	
	mesh_instance.material_override = sphere_mat
	rigidbody.add_child(mesh_instance)
	
	# Apply physics material
	var physics_material = PhysicsMaterial.new()
	physics_material.bounce = sphere_bounce
	physics_material.friction = sphere_friction
	rigidbody.physics_material_override = physics_material
	
	# Apply initial force
	var force_direction = Vector3(
		randf_range(-1.0, 1.0),
		randf_range(0.2, 1.0),  # Slight upward bias
		randf_range(-1.0, 1.0)
	).normalized()
	
	var force_magnitude = randf_range(initial_force_min, initial_force_max)
	rigidbody.apply_central_impulse(force_direction * force_magnitude)
	
	# Add some random angular velocity for spinning
	var angular_velocity = Vector3(
		randf_range(-5.0, 5.0),
		randf_range(-5.0, 5.0),
		randf_range(-5.0, 5.0)
	)
	rigidbody.angular_velocity = angular_velocity
	
	add_child(rigidbody)
	spheres.append(rigidbody)
	
	print("Spawned rigidbody sphere at position: ", spawn_pos, " with force: ", force_direction * force_magnitude)

func spawn_sphere_at_position(pos: Vector3, force: Vector3 = Vector3.ZERO):
	"""Spawn a sphere at a specific position with optional force"""
	# Adjust height to terrain if available
	var spawn_pos = pos
	if terrain_reference:
		spawn_pos.y = terrain_reference.get_height_at_world_position(pos) + height_offset
	else:
		spawn_pos.y = pos.y + height_offset
	
	# Create rigidbody
	var rigidbody = RigidBody3D.new()
	rigidbody.name = "RigidSphere_" + str(spheres.size())
	rigidbody.position = spawn_pos
	rigidbody.mass = sphere_mass
	rigidbody.gravity_scale = gravity_scale
	rigidbody.collision_layer = collision_layer
	rigidbody.collision_mask = collision_mask
	
	# Create collision shape
	var collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	var sphere_size = randf_range(sphere_size_min, sphere_size_max)
	sphere_shape.radius = sphere_size
	collision_shape.shape = sphere_shape
	rigidbody.add_child(collision_shape)
	
	# Create mesh instance
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = sphere_mesh
	mesh_instance.scale = Vector3.ONE * sphere_size
	
	# Create material
	var sphere_mat = sphere_material.duplicate()
	var color_index = randi() % sphere_colors.size()
	sphere_mat.albedo_color = sphere_colors[color_index]
	sphere_mat.emission = sphere_colors[color_index] * emission_energy
	
	mesh_instance.material_override = sphere_mat
	rigidbody.add_child(mesh_instance)
	
	# Apply physics material
	var physics_material = PhysicsMaterial.new()
	physics_material.bounce = sphere_bounce
	physics_material.friction = sphere_friction
	rigidbody.physics_material_override = physics_material
	
	# Apply force if provided
	if force != Vector3.ZERO:
		rigidbody.apply_central_impulse(force)
	else:
		# Apply random force
		var force_direction = Vector3(
			randf_range(-1.0, 1.0),
			randf_range(0.2, 1.0),
			randf_range(-1.0, 1.0)
		).normalized()
		var force_magnitude = randf_range(initial_force_min, initial_force_max)
		rigidbody.apply_central_impulse(force_direction * force_magnitude)
	
	add_child(rigidbody)
	spheres.append(rigidbody)
	
	print("Spawned rigidbody sphere at specific position: ", spawn_pos)

func cleanup_fallen_spheres():
	"""Remove spheres that have fallen too far or are too old"""
	var spheres_to_remove = []
	
	for i in range(spheres.size() - 1, -1, -1):
		var sphere = spheres[i]
		if not is_instance_valid(sphere):
			spheres.remove_at(i)
			continue
		
		# Remove spheres that have fallen too far below terrain
		var distance_from_origin = sphere.position.length()
		if sphere.position.y < -50.0 or distance_from_origin > spawn_radius * 3.0:
			sphere.queue_free()
			spheres.remove_at(i)
			print("Removed fallen sphere")

func clear_all_spheres():
	"""Remove all spheres"""
	for sphere in spheres:
		if is_instance_valid(sphere):
			sphere.queue_free()
	spheres.clear()
	print("Cleared all rigidbody spheres")

func set_sphere_parameters(params: Dictionary):
	"""Update sphere parameters dynamically"""
	if params.has("sphere_count"):
		sphere_count = params.sphere_count
	if params.has("spawn_radius"):
		spawn_radius = params.spawn_radius
	if params.has("height_offset"):
		height_offset = params.height_offset
	if params.has("sphere_mass"):
		sphere_mass = params.sphere_mass
	if params.has("sphere_bounce"):
		sphere_bounce = params.sphere_bounce
	if params.has("sphere_friction"):
		sphere_friction = params.sphere_friction

func get_sphere_stats() -> Dictionary:
	"""Get current sphere statistics"""
	var active_count = 0
	var total_kinetic_energy = 0.0
	var average_height = 0.0
	
	for sphere in spheres:
		if is_instance_valid(sphere):
			active_count += 1
			total_kinetic_energy += sphere.linear_velocity.length_squared() * sphere.mass * 0.5
			average_height += sphere.position.y
	
	if active_count > 0:
		average_height /= active_count
	
	return {
		"active_spheres": active_count,
		"max_spheres": max_spheres,
		"spawn_radius": spawn_radius,
		"average_height": average_height,
		"total_kinetic_energy": total_kinetic_energy
	}

func apply_force_to_all_spheres(force: Vector3):
	"""Apply a force to all active spheres"""
	for sphere in spheres:
		if is_instance_valid(sphere):
			sphere.apply_central_force(force)

func apply_impulse_to_all_spheres(impulse: Vector3):
	"""Apply an impulse to all active spheres"""
	for sphere in spheres:
		if is_instance_valid(sphere):
			sphere.apply_central_impulse(impulse)

func set_gravity_scale(scale: float):
	"""Set gravity scale for all spheres"""
	gravity_scale = scale
	for sphere in spheres:
		if is_instance_valid(sphere):
			sphere.gravity_scale = scale

# Debug functions
func _input(event):
	"""Handle input for debugging"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_S:
				spawn_single_sphere()
				print("Spawned debug sphere")
			KEY_C:
				clear_all_spheres()
				print("Cleared all spheres")
			KEY_I:
				print("Sphere stats: ", get_sphere_stats())
			KEY_F:
				# Apply upward force to all spheres
				apply_impulse_to_all_spheres(Vector3(0, 10, 0))
				print("Applied upward impulse to all spheres")
			KEY_G:
				# Toggle gravity
				var new_gravity = 0.0 if gravity_scale > 0.0 else 1.0
				set_gravity_scale(new_gravity)
				print("Gravity scale set to: ", new_gravity)
