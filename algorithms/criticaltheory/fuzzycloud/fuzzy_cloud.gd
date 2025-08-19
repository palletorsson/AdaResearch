extends Node3D

# Configuration
@export_category("Sculpture Configuration")
@export var num_blobs: int = 15
@export var blob_size_min: float = 1.0
@export var blob_size_max: float = 2.5
@export var hair_density: int = 3000  # Number of hair strands per blob
@export var hair_length_min: float = 0.3
@export var hair_length_max: float = 0.5
@export var generate_on_ready: bool = true

# Color configuration
@export_category("Appearance")
@export var blob_color: Color = Color(0.95, 0.93, 0.88)  # Slightly off-white/cream color
@export var hair_color: Color = Color(0.98, 0.96, 0.92)  # Slightly different shade for hairs
@export var randomize_colors: bool = true
@export var color_variation: float = 0.05  # How much the colors can vary

func _ready():
	if generate_on_ready:
		create_sculpture()
		setup_environment()

func create_sculpture():
	var sculpture = Node3D.new()
	sculpture.name = "DonovanSculpture"
	
	# Create a base platform for blobs if needed
	var base = create_base_platform()
	sculpture.add_child(base)
	
	# Create the blob cluster
	create_blob_cluster(sculpture)
	
	add_child(sculpture)

func create_base_platform():
	var base = MeshInstance3D.new()
	base.name = "BasePlatform"
	
	var mesh = CylinderMesh.new()
	mesh.top_radius = 4.0
	mesh.bottom_radius = 4.0
	mesh.height = 0.1
	base.mesh = mesh
	
	# Position the base slightly below the floor level
	base.position.y = -0.05
	
	# Create material for base
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.3, 0.3)
	material.roughness = 0.8
	base.material_override = material
	
	return base

func create_blob_cluster(parent):
	# Create the cluster of hairy blobs
	var cluster = Node3D.new()
	cluster.name = "BlobCluster"
	
	# Generate positions for blobs in a more organic cluster formation
	var positions = generate_cluster_positions(num_blobs)
	
	# Create each blob
	for i in range(num_blobs):
		var blob = create_hairy_blob(blob_size_min + randf() * (blob_size_max - blob_size_min))
		blob.position = positions[i]
		
		# Random rotation
		blob.rotation_degrees = Vector3(
			randf_range(0, 360),
			randf_range(0, 360),
			randf_range(0, 360)
		)
		
		cluster.add_child(blob)
	
	parent.add_child(cluster)

func generate_cluster_positions(count):
	var positions = []
	var center = Vector3.ZERO
	center.y = blob_size_max / 2  # Position above the ground
	
	# Create a base set of positions
	for i in range(count):
		var pos
		var attempts = 0
		var valid_position = false
		
		# Try to find a position that's not too close to existing blobs
		while not valid_position and attempts < 20:
			# Generate a position within an ellipsoid volume
			var angle = randf() * TAU
			var height = randf_range(-1.0, 1.0)
			var radius = sqrt(1.0 - height * height) * 2.5
			
			pos = Vector3(
				cos(angle) * radius,
				height * 1.5 + blob_size_max,  # Add blob_size_max to elevate everything
				sin(angle) * radius
			)
			
			# Check distance to other positions
			valid_position = true
			for existing_pos in positions:
				if pos.distance_to(existing_pos) < blob_size_max * 0.8:
					valid_position = false
					break
			
			attempts += 1
		
		# If we couldn't find a valid position, just use the last one
		positions.append(pos)
	
	# Now add some randomness but maintain the cluster shape
	for i in range(positions.size()):
		positions[i] += Vector3(
			randf_range(-0.5, 0.5),
			randf_range(-0.2, 0.2),
			randf_range(-0.5, 0.5)
		)
	
	return positions

func create_hairy_blob(size):
	var blob = Node3D.new()
	blob.name = "HairyBlob"
	
	# Create the core blob
	var core = create_blob_core(size)
	blob.add_child(core)
	
	# Create the hair
	create_hair_for_blob(blob, core, size)
	
	return blob

func create_blob_core(size):
	var core = MeshInstance3D.new()
	core.name = "BlobCore"
	
	# Create a mesh for the blob core
	var mesh = SphereMesh.new()
	mesh.radius = size * 0.9  # Core is slightly smaller than the full blob size
	mesh.height = size * 1.8
	core.mesh = mesh
	
	# Create material for the core
	var material = StandardMaterial3D.new()
	var core_color = blob_color
	
	if randomize_colors:
		core_color = Color(
			blob_color.r + randf_range(-color_variation, color_variation),
			blob_color.g + randf_range(-color_variation, color_variation),
			blob_color.b + randf_range(-color_variation, color_variation)
		)
	
	material.albedo_color = core_color
	material.roughness = 0.7
	core.material_override = material
	
	return core

func create_hair_for_blob(parent_node, core_mesh, size):
	var hair_container = Node3D.new()
	hair_container.name = "HairContainer"
	
	# Get the mesh shape to distribute hair on the surface
	var sphere_shape = core_mesh.mesh
	var sphere_radius = sphere_shape.radius
	
	# Create an immediate geometry node for the hair
	var hair_node = ImmediateMesh.new()
	var hair_instance = MeshInstance3D.new()
	hair_instance.name = "HairMesh"
	hair_instance.mesh = hair_node
	
	# Create a material for the hair
	var material = StandardMaterial3D.new()
	var hair_col = hair_color
	
	if randomize_colors:
		hair_col = Color(
			hair_color.r + randf_range(-color_variation, color_variation),
			hair_color.g + randf_range(-color_variation, color_variation),
			hair_color.b + randf_range(-color_variation, color_variation)
		)
	
	material.albedo_color = hair_col
	material.roughness = 0.9
	material.metallic_specular = 0.1
	
	# Make sure to set as transparent so alpha works
	material.flags_transparent = true
	
	hair_instance.material_override = material
	
	# Calculate how many hair strands to generate
	var num_hair = int(hair_density * size)
	
	# Begin building the hair mesh
	hair_node.clear_surfaces()
	hair_node.surface_begin(Mesh.PRIMITIVE_LINES, material)
	
	# Generate the hair strands
	for i in range(num_hair):
		# Generate a random point on the sphere
		var theta = randf() * TAU
		var phi = acos(2.0 * randf() - 1.0)
		
		var x = sphere_radius * sin(phi) * cos(theta)
		var y = sphere_radius * sin(phi) * sin(theta)
		var z = sphere_radius * cos(phi)
		
		var start_point = Vector3(x, y, z)
		
		# Calculate hair length (longer hairs on top, shorter on bottom)
		var hair_length = hair_length_min + randf() * (hair_length_max - hair_length_min)
		
		# Hair direction radiates outward from center
		var direction = start_point.normalized()
		
		# End point of hair
		var end_point = start_point + direction * hair_length
		
		# Add slight random variation to the end point
		end_point += Vector3(
			randf_range(-0.05, 0.05),
			randf_range(-0.05, 0.05),
			randf_range(-0.05, 0.05)
		) * hair_length
		
		# Add the hair strand as a line
		hair_node.surface_add_vertex(start_point)
		hair_node.surface_add_vertex(end_point)

	
	hair_node.surface_end()
	
	hair_container.add_child(hair_instance)
	parent_node.add_child(hair_container)

func setup_environment():
	# Create camera
	var camera = Camera3D.new()
	camera.name = "MainCamera"
	camera.position = Vector3(0, 2, 8)
	camera.look_at(Vector3(0, 1.5, 0), Vector3.UP)
	add_child(camera)
	
	# Create lighting
	setup_lighting()
	
	# Create a gallery environment
	create_gallery_room()

func setup_lighting():
	# Create a world environment
	var env = WorldEnvironment.new()
	env.name = "Environment"
	
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.9, 0.9, 0.9)
	
	# Ambient light
	environment.ambient_light_color = Color(0.8, 0.8, 0.8)
	environment.ambient_light_energy = 0.2
	
	# Fog for depth effect
	environment.fog_enabled = true
	environment.fog_density = 0.002
	environment.fog_aerial_perspective = 0.5
	#environment.fog_height_min = -10.0
	#environment.fog_height_max = 10.0
	
	# Tonemap settings for better light distribution
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.0
	environment.tonemap_white = 6.0
	
	# SSAO for depth effect
	environment.ssao_enabled = true
	environment.ssao_radius = 2.0
	environment.ssao_intensity = 2.0
	
	env.environment = environment
	add_child(env)
	
	# Add spotlights as in gallery setting
	add_gallery_lights()

func add_gallery_lights():
	# Main directional light
	var dir_light = DirectionalLight3D.new()
	dir_light.name = "MainLight"
	dir_light.position = Vector3(5, 8, 5)
	dir_light.look_at(Vector3(0, 0, 0), Vector3.UP)
	dir_light.light_color = Color(1.0, 0.98, 0.95)
	dir_light.light_energy = 0.8
	dir_light.shadow_enabled = true
	add_child(dir_light)
	
	# Create several spotlights to mimic gallery lighting
	var spots = Node3D.new()
	spots.name = "SpotLights"
	
	for i in range(6):
		var spot = SpotLight3D.new()
		spot.name = "SpotLight_" + str(i)
		
		var angle = i * PI / 3
		var radius = 3.0
		
		spot.position = Vector3(
			cos(angle) * radius,
			5.0,  # Height of ceiling
			sin(angle) * radius
		)
		
		spot.rotation_degrees = Vector3(-90, 0, 0)  # Point downward
		
		# Light properties
		spot.light_color = Color(1.0, 0.98, 0.9)
		spot.light_energy = 15.0
		spot.light_specular = 0.5
		spot.spot_range = 8.0
		spot.spot_angle = 25.0
		spot.spot_angle_attenuation = 0.8
		spot.shadow_enabled = true
		
		spots.add_child(spot)
	
	
	add_child(spots)

func create_gallery_room():
	var room = Node3D.new()
	room.name = "GalleryRoom"
	
	# Floor
	var floor = MeshInstance3D.new()
	floor.name = "Floor"
	
	var floor_mesh = PlaneMesh.new()
	floor_mesh.size = Vector2(15.0, 15.0)
	floor.mesh = floor_mesh
	
	var floor_material = StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.7, 0.7, 0.7)
	floor_material.roughness = 0.2
	floor.material_override = floor_material
	
	room.add_child(floor)
	
	# Walls
	var walls = Node3D.new()
	walls.name = "Walls"
	
	for i in range(4):
		var wall = MeshInstance3D.new()
		wall.name = "Wall_" + str(i)
		
		var wall_mesh = PlaneMesh.new()
		wall_mesh.size = Vector2(15.0, 6.0)
		wall.mesh = wall_mesh
		
		var wall_material = StandardMaterial3D.new()
		wall_material.albedo_color = Color(0.95, 0.95, 0.95)
		wall_material.roughness = 0.1
		wall.material_override = wall_material
		
		# Position and rotate the wall
		var angle = i * PI / 2
		wall.position = Vector3(
			sin(angle) * 7.5,
			3.0,
			cos(angle) * 7.5
		)
		wall.rotation_degrees.y = i * 90 + 180
		
		walls.add_child(wall)

	
	room.add_child(walls)
	
	# Ceiling
	var ceiling = MeshInstance3D.new()
	ceiling.name = "Ceiling"
	
	var ceiling_mesh = PlaneMesh.new()
	ceiling_mesh.size = Vector2(15.0, 15.0)
	ceiling.mesh = ceiling_mesh
	
	ceiling.position = Vector3(0, 6.0, 0)
	ceiling.rotation_degrees.x = 180
	
	var ceiling_material = StandardMaterial3D.new()
	ceiling_material.albedo_color = Color(0.9, 0.9, 0.9)
	ceiling_material.roughness = 0.3
	ceiling.material_override = ceiling_material
	
	room.add_child(ceiling)
	
	add_child(room)

# Enhanced version of the hair system using MultiMesh for better performance
func create_optimized_hair_for_blob(parent_node, core_mesh, size):
	var hair_container = Node3D.new()
	hair_container.name = "OptimizedHairContainer"
	
	# Get the mesh shape to distribute hair on the surface
	var sphere_shape = core_mesh.mesh
	var sphere_radius = sphere_shape.radius
	
	# Create a small hair strand mesh
	var hair_mesh = CylinderMesh.new()
	hair_mesh.top_radius = 0.003
	hair_mesh.bottom_radius = 0.005
	hair_mesh.height = hair_length_max
	hair_mesh.radial_segments = 4
	hair_mesh.rings = 1
	
	# Create the multimesh instance
	var mm = MultiMeshInstance3D.new()
	mm.name = "HairMultiMesh"
	
	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = hair_mesh
	
	# Set the number of instances
	var num_hair = int(hair_density * size)
	multimesh.instance_count = num_hair
	
	# Create a material for the hair
	var material = StandardMaterial3D.new()
	var hair_col = hair_color
	
	if randomize_colors:
		hair_col = Color(
			hair_color.r + randf_range(-color_variation, color_variation),
			hair_color.g + randf_range(-color_variation, color_variation),
			hair_color.b + randf_range(-color_variation, color_variation)
		)
	
	material.albedo_color = hair_col
	material.roughness = 0.9
	material.metallic_specular = 0.1
	
	# Apply material to hair mesh
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = hair_mesh
	mesh_instance.material_override = material
	
	# Generate transforms for each hair instance
	for i in range(num_hair):
		# Generate a random point on the sphere
		var theta = randf() * TAU
		var phi = acos(2.0 * randf() - 1.0)
		
		var x = sphere_radius * sin(phi) * cos(theta)
		var y = sphere_radius * sin(phi) * sin(theta)
		var z = sphere_radius * cos(phi)
		
		var pos = Vector3(x, y, z)
		
		# Calculate hair length
		var hair_length = hair_length_min + randf() * (hair_length_max - hair_length_min)
		var scale_factor = hair_length / hair_length_max
		
		# Hair direction radiates outward from center
		var direction = pos.normalized()
		
		# Create transform for this hair strand
		var basis = Basis()
		
		# Make the hair strand point outward
		var up = Vector3(0, 1, 0)
		if direction.is_equal_approx(up) or direction.is_equal_approx(-up):
			basis = Basis(Vector3(1, 0, 0), Vector3(0, 0, 1), direction)
		else:
			var right = direction.cross(up).normalized()
			var forward = right.cross(direction).normalized()
			basis = Basis(right, direction, forward)
		
		# Apply slight random rotation
		basis = basis.rotated(direction, randf() * TAU)
		
		# Create transform with position, rotation, and scale
		var transform = Transform3D(basis, pos)
		transform = transform.scaled(Vector3(1.0, scale_factor, 1.0))
		
		# Set the transform
		multimesh.set_instance_transform(i, transform)

	
	mm.multimesh = multimesh
	hair_container.add_child(mm)
	parent_node.add_child(hair_container)

# Alternative hair implementation using a particle system
func create_particle_hair_for_blob(parent_node, core_mesh, size):
	var particles = GPUParticles3D.new()
	particles.name = "HairParticles"
	
	# Get the mesh shape
	var sphere_shape = core_mesh.mesh
	var sphere_radius = sphere_shape.radius
	
	# Create a sphere emission shape
	var emission_shape = SphereMesh.new()
	emission_shape.radius = sphere_radius
	emission_shape.height = sphere_radius * 2
	
	# Create the particle material
	var particle_material = ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_material.emission_sphere_radius = sphere_radius
	
	# Make particles emit outward
	particle_material.direction = Vector3(0, 0, 0)
	particle_material.spread = 0
	particle_material.gravity = Vector3(0, 0, 0)
	
	# Particle properties
	particle_material.initial_velocity_min = 0.1
	particle_material.initial_velocity_max = 0.5
	particle_material.damping = 100.0  # High damping to stop quickly
	
	# Color and appearance
	var hair_col = hair_color
	if randomize_colors:
		hair_col = Color(
			hair_color.r + randf_range(-color_variation, color_variation),
			hair_color.g + randf_range(-color_variation, color_variation),
			hair_color.b + randf_range(-color_variation, color_variation)
		)
	
	particle_material.color = hair_col
	
	# Set up the particles
	particles.amount = hair_density
	particles.lifetime = 100  # Very long life so they stay in place
	particles.explosiveness = 1.0  # All emit at once
	particles.one_shot = true
	particles.process_material = particle_material
	
	# Create the visual mesh for each particle
	var hair_mesh = CylinderMesh.new()
	hair_mesh.top_radius = 0.001
	hair_mesh.bottom_radius = 0.003
	hair_mesh.height = 0.3
	
	particles.draw_pass_1 = hair_mesh
	
	parent_node.add_child(particles)
