extends Node3D

# Configuration
@export var meadow_size: float = 10.0
@export var mushroom_count: int = 100
@export var mushroom_density: float = 0.8
@export var mushroom_variety: int = 5
@export var add_glowing_mushrooms: bool = true
@export var add_ground_cover: bool = true

# References
var mushroom_types = []
var mushrooms = []
var ground = null

func _ready():
	# Create the ground first
	create_ground()
	
	# Create mushroom templates
	create_mushroom_templates()
	
	# Place mushrooms
	generate_mushroom_field()
	
	# Add ambient lighting
	create_ambient_lighting()
	
	# Add ground details
	if add_ground_cover:
		add_ground_details()

func create_ground():
	# Create a procedural ground
	ground = Node3D.new()
	ground.name = "Ground"
	
	# Add a mesh for the ground
	var ground_mesh = MeshInstance3D.new()
	ground_mesh.name = "GroundMesh"
	
	# Create a plane with subdivisions for slight height variation
	var plane = PlaneMesh.new()
	plane.size = Vector2(meadow_size, meadow_size)
	plane.subdivide_depth = 20
	plane.subdivide_width = 20
	ground_mesh.mesh = plane
	
	# Create ground material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.35, 0.25)  # Dark soil color
	material.roughness = 0.9
	ground_mesh.material_override = material
	
	# Add collision
	var static_body = StaticBody3D.new()
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(meadow_size, 0.1, meadow_size)
	collision.shape = shape
	static_body.add_child(collision)
	ground.add_child(static_body)
	
	# Add to scene
	ground.add_child(ground_mesh)
	add_child(ground)
	
	# Add subtle height noise to ground
	add_height_noise_to_ground(ground_mesh)

func add_height_noise_to_ground(ground_mesh):
	# Get the mesh to modify
	var mesh = ground_mesh.mesh
	if not mesh is ArrayMesh:
		return
	
	# Access the mesh data
	var surface_tool = SurfaceTool.new()
	surface_tool.create_from(mesh, 0)
	var array_mesh = surface_tool.commit()
	var mesh_data = array_mesh.surface_get_arrays(0)
	var vertices = mesh_data[Mesh.ARRAY_VERTEX]
	
	# Apply noise to each vertex
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.2
	
	for i in range(vertices.size()):
		var vertex = vertices[i]
		var noise_value = noise.get_noise_2d(vertex.x, vertex.z) * 0.3
		vertices[i].y = noise_value
	
	# Update the mesh
	mesh_data[Mesh.ARRAY_VERTEX] = vertices
	array_mesh.surface_set_arrays(0, mesh_data)
	ground_mesh.mesh = array_mesh

func create_mushroom_templates():
	# Create different mushroom types
	for i in range(mushroom_variety):
		var template = create_mushroom_template(i)
		mushroom_types.append(template)
	
	# Create special glowing mushrooms if enabled
	if add_glowing_mushrooms:
		var glowing_mushroom = create_glowing_mushroom()
		mushroom_types.append(glowing_mushroom)

func create_mushroom_template(type_index):
	# Create a mushroom base node
	var mushroom = Node3D.new()
	mushroom.name = "Mushroom_Template_" + str(type_index)
	
	# Different types of mushrooms
	match type_index:
		0: create_standard_mushroom(mushroom, 0.2, 0.15, Color(0.8, 0.6, 0.4))  # Tan mushroom
		1: create_standard_mushroom(mushroom, 0.15, 0.1, Color(0.8, 0.2, 0.2))  # Red mushroom
		2: create_flat_cap_mushroom(mushroom, 0.25, Color(0.5, 0.4, 0.3))       # Brown flat mushroom
		3: create_tall_thin_mushroom(mushroom, 0.35, Color(0.9, 0.9, 0.8))      # Tall white mushroom
		4: create_puffball_mushroom(mushroom, 0.12, Color(0.9, 0.9, 0.85))      # White puffball
	
	return mushroom

func create_standard_mushroom(mushroom, cap_size, stem_height, color):
	# Create stem
	var stem = MeshInstance3D.new()
	stem.name = "Stem"
	
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = cap_size * 0.2
	cylinder.bottom_radius = cap_size * 0.25
	cylinder.height = stem_height
	cylinder.radial_segments = 8
	stem.mesh = cylinder
	
	var stem_material = StandardMaterial3D.new()
	stem_material.albedo_color = color.lightened(0.3)  # Lighter stem
	stem.material_override = stem_material
	
	# Position stem
	stem.position.y = stem_height / 2
	
	# Create cap
	var cap = MeshInstance3D.new()
	cap.name = "Cap"
	
	var hemisphere = SphereMesh.new()
	hemisphere.radius = cap_size
	hemisphere.height = cap_size * 1.2
	hemisphere.radial_segments = 16
	hemisphere.rings = 8
	cap.mesh = hemisphere
	
	# Flatten the bottom of the cap
	cap.scale.y = 0.5
	
	# Position cap on top of stem
	cap.position.y = stem_height
	
	var cap_material = StandardMaterial3D.new()
	cap_material.albedo_color = color
	cap.material_override = cap_material
	
	# Add to mushroom
	mushroom.add_child(stem)
	mushroom.add_child(cap)
	
	# Add gills under cap
	add_gills(mushroom, cap_size, stem_height, color)

func add_gills(mushroom, cap_size, stem_height, color):
	var gills = MeshInstance3D.new()
	gills.name = "Gills"
	
	var disc = CylinderMesh.new()
	disc.top_radius = cap_size * 0.95
	disc.bottom_radius = cap_size * 0.95
	disc.height = 0.01
	disc.radial_segments = 16
	gills.mesh = disc
	
	# Position gills under cap
	gills.position.y = stem_height - 0.01
	
	var gill_material = StandardMaterial3D.new()
	gill_material.albedo_color = color.darkened(0.3)  # Darker gills
	gills.material_override = gill_material
	
	mushroom.add_child(gills)

func create_flat_cap_mushroom(mushroom, cap_size, color):
	# Create stem
	var stem = MeshInstance3D.new()
	stem.name = "Stem"
	
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = cap_size * 0.15
	cylinder.bottom_radius = cap_size * 0.2
	cylinder.height = cap_size * 0.6
	cylinder.radial_segments = 8
	stem.mesh = cylinder
	
	var stem_material = StandardMaterial3D.new()
	stem_material.albedo_color = color.lightened(0.2)
	stem.material_override = stem_material
	
	# Position stem
	stem.position.y = (cap_size * 0.6) / 2
	
	# Create flat cap
	var cap = MeshInstance3D.new()
	cap.name = "Cap"
	
	var disc = CylinderMesh.new()
	disc.top_radius = cap_size
	disc.bottom_radius = cap_size
	disc.height = cap_size * 0.2
	disc.radial_segments = 16
	cap.mesh = disc
	
	# Position cap on top of stem
	cap.position.y = cap_size * 0.6
	
	var cap_material = StandardMaterial3D.new()
	cap_material.albedo_color = color
	cap.material_override = cap_material
	
	# Add to mushroom
	mushroom.add_child(stem)
	mushroom.add_child(cap)

func create_tall_thin_mushroom(mushroom, height, color):
	# Create stem
	var stem = MeshInstance3D.new()
	stem.name = "Stem"
	
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.03
	cylinder.bottom_radius = 0.04
	cylinder.height = height
	cylinder.radial_segments = 8
	stem.mesh = cylinder
	
	var stem_material = StandardMaterial3D.new()
	stem_material.albedo_color = color
	stem.material_override = stem_material
	
	# Position stem
	stem.position.y = height / 2
	
	# Create small cap
	var cap = MeshInstance3D.new()
	cap.name = "Cap"
	
	var cone = CylinderMesh.new()
	cone.top_radius = 0.01
	cone.bottom_radius = 0.06
	cone.height = 0.1
	cone.radial_segments = 8
	cap.mesh = cone
	
	# Position cap on top of stem
	cap.position.y = height + 0.05
	
	var cap_material = StandardMaterial3D.new()
	cap_material.albedo_color = color.darkened(0.1)
	cap.material_override = cap_material
	
	# Add to mushroom
	mushroom.add_child(stem)
	mushroom.add_child(cap)

func create_puffball_mushroom(mushroom, size, color):
	# Create just a simple sphere for puffball
	var puffball = MeshInstance3D.new()
	puffball.name = "Puffball"
	
	var sphere = SphereMesh.new()
	sphere.radius = size
	sphere.height = size * 2
	sphere.radial_segments = 16
	sphere.rings = 8
	puffball.mesh = sphere
	
	# Position slightly buried in ground
	puffball.position.y = size * 0.8
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	puffball.material_override = material
	
	# Add texture/bumps to puffball
	add_puffball_texture(puffball, color)
	
	# Add to mushroom
	mushroom.add_child(puffball)

func add_puffball_texture(puffball, color):
	# Add small bumps on the puffball surface
	var bump_count = 12
	
	for i in range(bump_count):
		var bump = MeshInstance3D.new()
		bump.name = "Bump_" + str(i)
		
		var small_sphere = SphereMesh.new()
		small_sphere.radius = 0.02
		small_sphere.radial_segments = 6
		small_sphere.rings = 4
		bump.mesh = small_sphere
		
		# Random position on the puffball surface
		var phi = randf() * PI * 2
		var theta = randf() * PI
		var radius = 0.12  # Puffball radius
		
		var pos_x = radius * sin(theta) * cos(phi)
		var pos_y = radius * sin(theta) * sin(phi)
		var pos_z = radius * cos(theta)
		
		bump.position = Vector3(pos_x, pos_y, pos_z)
		
		var bump_material = StandardMaterial3D.new()
		bump_material.albedo_color = color.darkened(0.1)
		bump.material_override = bump_material
		
		puffball.add_child(bump)

func create_glowing_mushroom():
	# Create a special glowing mushroom
	var mushroom = Node3D.new()
	mushroom.name = "Mushroom_Template_Glowing"
	
	# Create thin stem
	var stem = MeshInstance3D.new()
	stem.name = "Stem"
	
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.02
	cylinder.bottom_radius = 0.03
	cylinder.height = 0.18
	cylinder.radial_segments = 8
	stem.mesh = cylinder
	
	var stem_material = StandardMaterial3D.new()
	stem_material.albedo_color = Color(0.7, 0.9, 0.8)
	stem_material.emission_enabled = true
	stem_material.emission = Color(0.2, 0.5, 0.4)
	stem_material.emission_energy = 0.5
	stem.material_override = stem_material
	
	# Position stem
	stem.position.y = 0.09
	
	# Create glowing cap
	var cap = MeshInstance3D.new()
	cap.name = "Cap"
	
	var dome = SphereMesh.new()
	dome.radius = 0.08
	dome.height = 0.1
	dome.radial_segments = 16
	dome.rings = 8
	cap.mesh = dome
	
	# Flatten into dome shape
	cap.scale.y = 0.6
	
	# Position cap on top of stem
	cap.position.y = 0.18
	
	var cap_material = StandardMaterial3D.new()
	cap_material.albedo_color = Color(0.2, 0.8, 0.7)
	cap_material.emission_enabled = true
	cap_material.emission = Color(0.0, 0.7, 0.6)
	cap_material.emission_energy = 2.0
	cap.material_override = cap_material
	
	# Add to mushroom
	mushroom.add_child(stem)
	mushroom.add_child(cap)
	
	# Add glow effect
	var glow = OmniLight3D.new()
	glow.name = "GlowLight"
	glow.light_color = Color(0.0, 0.7, 0.6)
	glow.light_energy = 0.5
	glow.omni_range = 1.0
	glow.position.y = 0.2
	mushroom.add_child(glow)
	
	return mushroom

func generate_mushroom_field():
	# Create a container for all mushrooms
	var field = Node3D.new()
	field.name = "MushroomField"
	add_child(field)
	
	# Generate positions
	var positions = generate_mushroom_positions()
	
	# Place mushrooms
	for i in range(positions.size()):
		var pos = positions[i]
		
		# Determine mushroom type
		var type_index = randi() % mushroom_types.size()
		
		# For glowing mushrooms, use sparingly
		if type_index == mushroom_types.size() - 1 && add_glowing_mushrooms:
			# Only 5% chance for glowing mushrooms
			if randf() > 0.05:
				type_index = randi() % (mushroom_types.size() - 1)
		
		# Instantiate mushroom
		var mushroom = mushroom_types[type_index].duplicate()
		mushroom.name = "Mushroom_" + str(i)
		
		# Position mushroom
		mushroom.position = pos
		
		# Randomize rotation and scale
		mushroom.rotation_degrees.y = randf() * 360
		
		var scale_factor = 0.7 + randf() * 0.6  # 0.7 to 1.3
		mushroom.scale = Vector3(scale_factor, scale_factor, scale_factor)
		
		# Add to field
		field.add_child(mushroom)
		mushrooms.append(mushroom)
	
	# Organize some mushrooms into fairy rings and clusters
	create_mushroom_patterns()

func generate_mushroom_positions():
	var positions = []
	
	# Distribute based on meadow size and density
	var area = meadow_size * meadow_size
	var target_count = mushroom_count * mushroom_density
	
	# Create a noise generator for distribution
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.5
	
	# Generate positions
	for _i in range(target_count):
		var pos_x = randf() * meadow_size - meadow_size / 2
		var pos_z = randf() * meadow_size - meadow_size / 2
		
		# Use noise to make distribution more natural
		var noise_val = noise.get_noise_2d(pos_x * 2, pos_z * 2)
		
		# Skip if noise value is too low (creates natural clearings)
		if noise_val < -0.3:
			continue
		
		# Get ground height at this position
		var ground_height = get_ground_height(pos_x, pos_z)
		
		positions.append(Vector3(pos_x, ground_height, pos_z))
	
	return positions

func get_ground_height(x, z):
	# In a real implementation, you would raycast to the ground
	# For this example, we'll use a simple noise function
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.2
	
	return noise.get_noise_2d(x, z) * 0.3

func create_mushroom_patterns():
	# Create fairy rings
	var ring_count = int(meadow_size / 5)
	
	for _i in range(ring_count):
		create_fairy_ring()
	
	# Create clusters
	var cluster_count = int(meadow_size / 3)
	
	for _i in range(cluster_count):
		create_mushroom_cluster()

func create_fairy_ring():
	# Choose a random center point
	var center_x = randf() * meadow_size - meadow_size / 2
	var center_z = randf() * meadow_size - meadow_size / 2
	
	# Choose a radius
	var radius = 1.0 + randf() * 2.0
	
	# Choose a mushroom type for the ring
	var type_index = randi() % (mushroom_types.size() - (1 if add_glowing_mushrooms else 0))
	
	# Number of mushrooms in the ring
	var count = int(radius * 8)
	
	for i in range(count):
		var angle = (2.0 * PI / count) * i
		var pos_x = center_x + cos(angle) * radius
		var pos_z = center_z + sin(angle) * radius
		
		# Skip if outside meadow
		if abs(pos_x) > meadow_size / 2 or abs(pos_z) > meadow_size / 2:
			continue
		
		# Get ground height
		var ground_height = get_ground_height(pos_x, pos_z)
		
		# Create mushroom
		var mushroom = mushroom_types[type_index].duplicate()
		mushroom.name = "FairyRing_Mushroom_" + str(i)
		
		# Position and rotate
		mushroom.position = Vector3(pos_x, ground_height, pos_z)
		mushroom.rotation_degrees.y = randf() * 360
		
		# Slightly varied scale
		var scale_factor = 0.8 + randf() * 0.4
		mushroom.scale = Vector3(scale_factor, scale_factor, scale_factor)
		
		# Add to scene
		get_node("MushroomField").add_child(mushroom)
		mushrooms.append(mushroom)

func create_mushroom_cluster():
	# Choose a random center point
	var center_x = randf() * meadow_size - meadow_size / 2
	var center_z = randf() * meadow_size - meadow_size / 2
	
	# Choose cluster size
	var cluster_size = 0.5 + randf() * 1.0
	
	# Choose a mushroom type for the cluster
	var type_index = randi() % mushroom_types.size()
	
	# Number of mushrooms in the cluster
	var count = 5 + randi() % 10
	
	for _i in range(count):
		var angle = randf() * PI * 2
		var distance = randf() * cluster_size
		
		var pos_x = center_x + cos(angle) * distance
		var pos_z = center_z + sin(angle) * distance
		
		# Skip if outside meadow
		if abs(pos_x) > meadow_size / 2 or abs(pos_z) > meadow_size / 2:
			continue
		
		# Get ground height
		var ground_height = get_ground_height(pos_x, pos_z)
		
		# Create mushroom
		var mushroom = mushroom_types[type_index].duplicate()
		mushroom.name = "Cluster_Mushroom_" + str(_i)
		
		# Position and rotate
		mushroom.position = Vector3(pos_x, ground_height, pos_z)
		mushroom.rotation_degrees.y = randf() * 360
		
		# Varied scale - smaller ones more common in clusters
		var scale_factor = 0.5 + randf() * 0.7
		mushroom.scale = Vector3(scale_factor, scale_factor, scale_factor)
		
		# Add to scene
		get_node("MushroomField").add_child(mushroom)
		mushrooms.append(mushroom)

func create_ambient_lighting():
	# Add ambient light for the scene
	var ambient = DirectionalLight3D.new()
	ambient.name = "AmbientLight"
	
	# Set light properties
	ambient.light_color = Color(0.9, 0.9, 1.0)
	ambient.light_energy = 0.8
	ambient.shadow_enabled = true
	
	# Position light
	ambient.rotation_degrees = Vector3(-45, 45, 0)
	
	add_child(ambient)
	
	# Add some fog for atmosphere
	add_atmospheric_fog()

func add_atmospheric_fog():
	# Add fog
	var environment = WorldEnvironment.new()
	environment.name = "Environment"
	
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.07, 0.1)
	
	# Add fog
	env.fog_enabled = true
	#env.fog_color = Color(0.2, 0.25, 0.3)
	env.fog_density = 0.02
	
	# Add ambient light
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = Color(0.2, 0.25, 0.3)
	env.ambient_light_energy = 0.5
	
	environment.environment = env
	add_child(environment)

func add_ground_details():
	# Add grass and small plants
	add_grass()
	
	# Add rocks
	add_rocks()
	
	# Add fallen leaves
	add_fallen_leaves()

func add_grass():
	# Create a MultiMeshInstance for grass
	var grass = MultiMeshInstance3D.new()
	grass.name = "Grass"
	
	# Create grass blade mesh
	var grass_mesh = CylinderMesh.new()
	grass_mesh.top_radius = 0.01
	grass_mesh.bottom_radius = 0.03
	grass_mesh.height = 0.2
	grass_mesh.radial_segments = 3
	
	# Create multimesh
	var multi_mesh = MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.mesh = grass_mesh
	
	# Set instance count based on meadow size
	var instance_count = int(meadow_size * meadow_size * 10)
	multi_mesh.instance_count = instance_count
	
	# Create grass material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.4, 0.2)
	grass_mesh.material = material
	
	# Set transforms for each instance
	for i in range(instance_count):
		var pos_x = randf() * meadow_size - meadow_size / 2
		var pos_z = randf() * meadow_size - meadow_size / 2
		
		# Get ground height
		var ground_height = get_ground_height(pos_x, pos_z)
		
		var transform = Transform3D()
		transform.origin = Vector3(pos_x, ground_height, pos_z)
		
		# Randomize rotation
		transform.basis = Basis(Vector3.UP, randf() * PI * 2)
		# Randomize scale
		var scale = 0.7 + randf() * 0.6
		transform.basis = transform.basis.scaled(Vector3(scale, scale + randf() * 0.5, scale))
		
		multi_mesh.set_instance_transform(i, transform)
	
	grass.multimesh = multi_mesh
	add_child(grass)

func add_rocks():
	# Add some rocks
	var rock_count = int(meadow_size * 2)
	var rocks = Node3D.new()
	rocks.name = "Rocks"
	
	for i in range(rock_count):
		var rock = MeshInstance3D.new()
		rock.name = "Rock_" + str(i)
		
		var mesh_type = randi() % 3
		var size_val = 0.1 + randf() * 0.3

		match mesh_type:
			0:
				var sphere = SphereMesh.new()
				sphere.radius = size_val  # SphereMesh uses a float radius
				rock.mesh = sphere
			1:
				var box = BoxMesh.new()
				box.size = Vector3(size_val, size_val * 0.7, size_val)
				rock.mesh = box
			2:
				var prism = PrismMesh.new()
				prism.size = Vector3(size_val, size_val * 0.7, size_val)       # PrismMesh expects a float for its base size
			
				rock.mesh = prism

				# Random rotation
				rock.rotation_degrees = Vector3(
					randf() * 30,
					randf() * 360,
					randf() * 30
				)
		
		# Create rock material
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.5, 0.5, 0.5).darkened(randf() * 0.3)
		material.roughness = 0.9
		rock.material_override = material
		
		rocks.add_child(rock)
	
	add_child(rocks)

func add_fallen_leaves():
	# Add fallen leaves
	var leaf_count = int(meadow_size * meadow_size * 2)
	var leaves = MultiMeshInstance3D.new()
	leaves.name = "FallenLeaves"
	
	# Create leaf mesh
	var leaf_mesh = PrismMesh.new()
	leaf_mesh.size = Vector3(0.1, 0.01, 0.15)
	
	# Create multimesh
	var multi_mesh = MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.mesh = leaf_mesh
	multi_mesh.instance_count = leaf_count
	
	# Create leaf material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.3, 0.1)
	leaf_mesh.material = material
	
	# Set transforms for each instance
	for i in range(leaf_count):
		var pos_x = randf() * meadow_size - meadow_size / 2
		var pos_z = randf() * meadow_size - meadow_size / 2
		
		# Get ground height
		var ground_height = get_ground_height(pos_x, pos_z)
		
		var transform = Transform3D()
		transform.origin = Vector3(pos_x, ground_height + 0.01, pos_z)
		
		# Randomize rotation
		transform.basis = Basis.from_euler(Vector3(
			randf() * 0.2,
			randf() * PI * 2,
			randf() * 0.2
		))

		transform.basis = Basis(Vector3.UP, randf() * PI * 2)
		multi_mesh.set_instance_transform(i, transform)
	
	leaves.multimesh = multi_mesh
	add_child(leaves)
