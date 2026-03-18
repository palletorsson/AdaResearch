@tool
extends "res://commons/primitives/cubes/CubeSpawner.gd"

# MondrianSpawner.gd
# A slick, Mondrian-style implementation of the CubeSpawner.
# minimal, geometric, and deadly.

func _init() -> void:
	# Default settings for Mondrian mode
	spawn_interval = 3.0
	projectile_speed = 8.0
	max_projectiles = 5
	auto_start = true

func _ready() -> void:
	# Ensure projectile scene is loaded
	if not projectile_scene:
		projectile_scene = load("res://commons/primitives/cubes/projectile_cube.tscn")
	super._ready()

func _create_spawner_visual() -> void:
	"""Create a slick Mondrian-style visual"""
	# Remove any existing visual
	if mesh_instance:
		mesh_instance.queue_free()
	
	# Container for our slick visual
	var visual_root = Node3D.new()
	visual_root.name = "MondrianVisual"
	add_child(visual_root)
	
	# 1. The Black Frame (Outer shell)
	var frame = MeshInstance3D.new()
	var frame_mesh = BoxMesh.new()
	frame_mesh.size = Vector3(1.2, 1.2, 1.2)
	frame.mesh = frame_mesh
	
	var black_mat = StandardMaterial3D.new()
	black_mat.albedo_color = Color(0.1, 0.1, 0.1) # Dark black
	black_mat.metallic = 0.5
	black_mat.roughness = 0.2
	frame.material_override = black_mat
	visual_root.add_child(frame)
	
	# 2. The Core (Colored emitter)
	var core = MeshInstance3D.new()
	var core_mesh = BoxMesh.new()
	core_mesh.size = Vector3(0.8, 0.8, 0.9) # Slightly protruding
	core.mesh = core_mesh
	
	var color_mat = StandardMaterial3D.new()
	# Random Mondrian color for each spawner
	var colors = [Color(0.9, 0.1, 0.1), Color(0.1, 0.1, 0.9), Color(0.9, 0.9, 0.1)]
	color_mat.albedo_color = colors[randi() % colors.size()]
	color_mat.emission_enabled = true
	color_mat.emission = color_mat.albedo_color
	color_mat.emission_energy_multiplier = 2.0
	core.material_override = color_mat
	
	visual_root.add_child(core)
	
	# Store reference to core for pulsing effects
	mesh_instance = core # Reuse the variable for the effect tweening logic
	
	# warning_particles reference is handled in base class, we can override or leave as is.
	# Let's clean up default particles if they exist and make minimal ones
	if warning_particles:
		warning_particles.queue_free()
		
	# Create minimal geometric particles
	warning_particles = GPUParticles3D.new()
	warning_particles.name = "DigitalParticles"
	visual_root.add_child(warning_particles)
	
	var particle_mat = ParticleProcessMaterial.new()
	particle_mat.direction = Vector3(0, 0, -1) # Forward
	particle_mat.spread = 15.0
	particle_mat.gravity = Vector3(0, 0, 0)
	particle_mat.initial_velocity_min = 2.0
	particle_mat.initial_velocity_max = 4.0
	particle_mat.scale_min = 0.1
	particle_mat.scale_max = 0.2
	
	warning_particles.process_material = particle_mat
	
	var dot_mesh = BoxMesh.new()
	dot_mesh.size = Vector3(0.1, 0.1, 0.1)
	dot_mesh.material = color_mat
	warning_particles.draw_pass_1 = dot_mesh
	warning_particles.emitting = false

# Override to use the parent node for rotation, as our structure is slightly different
# Override to use the parent node for rotation, as our structure is slightly different
func _spawn_projectile() -> void:
	super._spawn_projectile()
	
	# Tuning: Reduce impact for Mondrian scene
	# Access the last spawned projectile from the active list
	if active_projectiles.size() > 0:
		var projectile = active_projectiles.back()
		if projectile and "my_knockback_force" in projectile:
			# Drastically reduce force to prevent flinging player
			projectile.my_knockback_force = 0.002 
			# print("MondrianSpawner: Tuned projectile force to %f" % projectile.my_knockback_force)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
