extends Node3D

# Random Plant Variety Generator
# Creates diverse plant life by randomizing size, scale, and rotation

# Plant generation settings
@export_category("Plant Generation")
@export var number_of_plants: int = 100
@export var area_size: float = 20.0
@export var plant_density: float = 0.8

# Plant type probabilities
@export_category("Plant Types")
@export_range(0.0, 1.0) var tree_probability: float = 0.2
@export_range(0.0, 1.0) var bush_probability: float = 0.3
@export_range(0.0, 1.0) var flower_probability: float = 0.3
@export_range(0.0, 1.0) var grass_probability: float = 0.2

# Diversity settings
@export_category("Diversity Settings")
@export_range(0.0, 1.0) var size_variation: float = 0.5
@export_range(0.0, 1.0) var color_variation: float = 0.6 
@export_range(0.0, 1.0) var rotation_variation: float = 0.2
@export_range(0.0, 1.0) var leaf_density_variation: float = 0.4

# Materials
var trunk_material: StandardMaterial3D
var leaf_material: StandardMaterial3D
var flower_material: StandardMaterial3D
var grass_material: StandardMaterial3D

func _ready():
	randomize()
	
	# Create materials
	create_materials()
	
	# Create terrain
	create_terrain()
	
	# Generate plants
	generate_plants()
	
	# Add environment lighting
	setup_environment()

func create_materials():
	# Trunk material
	trunk_material = StandardMaterial3D.new()
	trunk_material.albedo_color = Color(0.45, 0.22, 0.06)
	trunk_material.roughness = 0.9
	
	# Leaf material (base green)
	leaf_material = StandardMaterial3D.new()
	leaf_material.albedo_color = Color(0.2, 0.5, 0.1)
	leaf_material.roughness = 0.8
	
	# Flower material (base pink)
	flower_material = StandardMaterial3D.new()
	flower_material.albedo_color = Color(0.9, 0.4, 0.7)
	flower_material.roughness = 0.7
	
	# Grass material
	grass_material = StandardMaterial3D.new()
	grass_material.albedo_color = Color(0.3, 0.6, 0.2)
	grass_material.roughness = 0.8

func create_terrain():
	var terrain = CSGBox3D.new()
	terrain.name = "Terrain"
	terrain.size = Vector3(area_size, 1.0, area_size)
	terrain.position = Vector3(0, -0.5, 0)
	
	var terrain_material = StandardMaterial3D.new()
	terrain_material.albedo_color = Color(0.3, 0.2, 0.1)
	terrain.material = terrain_material
	
	add_child(terrain)

func generate_plants():
	# Calculate actual number of plants based on density
	var actual_plants = int(number_of_plants * plant_density)
	
	# Create plant container
	var plants_container = Node3D.new()
	plants_container.name = "Plants"
	add_child(plants_container)
	
	# Generate plants
	for i in range(actual_plants):
		# Determine plant type based on probabilities
		var plant_type = determine_plant_type()
		
		# Calculate random position within area
		var position = Vector3(
			randf_range(-area_size/2, area_size/2),
			0,
			randf_range(-area_size/2, area_size/2)
		)
		
		# Create the plant
		match plant_type:
			"tree": create_tree(plants_container, position)
			"bush": create_bush(plants_container, position)
			"flower": create_flower(plants_container, position)
			"grass": create_grass(plants_container, position)

func determine_plant_type() -> String:
	# Normalize probabilities
	var total = tree_probability + bush_probability + flower_probability + grass_probability
	var normalized_tree = tree_probability / total
	var normalized_bush = bush_probability / total
	var normalized_flower = flower_probability / total
	var normalized_grass = grass_probability / total
	
	# Random selection
	var rand_val = randf()
	if rand_val < normalized_tree:
		return "tree"
	elif rand_val < normalized_tree + normalized_bush:
		return "bush"
	elif rand_val < normalized_tree + normalized_bush + normalized_flower:
		return "flower"
	else:
		return "grass"

func create_tree(parent, position):
	var tree = Node3D.new()
	tree.name = "Tree_" + str(parent.get_child_count())
	tree.position = position
	
	# Random rotation
	var rotation_range = PI * rotation_variation
	tree.rotation.y = randf_range(-PI, PI)  # Full rotation around Y
	tree.rotation.x = randf_range(-rotation_range/5, rotation_range/5)  # Slight tilt
	tree.rotation.z = randf_range(-rotation_range/5, rotation_range/5)  # Slight tilt
	
	# Random size variation
	var base_scale = 1.0 + randf_range(-size_variation, size_variation)
	var scale_variation_x = 1.0 + randf_range(-size_variation/2, size_variation/2)
	var scale_variation_z = 1.0 + randf_range(-size_variation/2, size_variation/2)
	tree.scale = Vector3(base_scale * scale_variation_x, base_scale, base_scale * scale_variation_z)
	
	# Create trunk
	var trunk = CSGCylinder3D.new()
	trunk.name = "Trunk"
	trunk.radius = 0.2
	trunk.height = 2.0 + randf_range(-0.5, 1.5) * size_variation
	trunk.position.y = trunk.height / 2
	
	# Variation in trunk material
	var trunk_mat = trunk_material.duplicate()
	trunk_mat.albedo_color = trunk_material.albedo_color.lightened(randf_range(-0.1, 0.1) * color_variation)
	trunk.material = trunk_mat
	
	tree.add_child(trunk)
	
	# Create foliage (crown)
	var crown_type = randi() % 3  # 0 = sphere, 1 = cone, 2 = multiple spheres
	
	match crown_type:
		0:  # Sphere crown
			var crown = CSGSphere3D.new()
			crown.name = "Crown"
			crown.radius = 0.8 + randf_range(-0.2, 0.4) * size_variation
			crown.position.y = trunk.height + crown.radius * 0.5
			
			var leaf_mat = leaf_material.duplicate()
			leaf_mat.albedo_color = leaf_material.albedo_color.lightened(randf_range(-0.2, 0.2) * color_variation)
			crown.material = leaf_mat
			
			tree.add_child(crown)
			
		1:  # Cone crown (pine tree)
			var crown = CSGCylinder3D.new()
			crown.name = "Crown" 
			crown.radius = 0.6 + randf_range(-0.2, 0.4) * size_variation
			#crown.radius_bottom = crown.radius
			#crown.radius_top = 0.0
			crown.height = 1.5 + randf_range(-0.3, 0.8) * size_variation
			crown.position.y = trunk.height + crown.height * 0.5
			crown.cone = true
			
			var leaf_mat = leaf_material.duplicate()
			leaf_mat.albedo_color = leaf_material.albedo_color.darkened(randf_range(0, 0.3) * color_variation)
			crown.material = leaf_mat
			
			tree.add_child(crown)
			
		2:  # Multiple spheres (oak-like)
			var num_spheres = 3 + randi() % 3
			var max_radius = 0.7 + randf_range(-0.2, 0.4) * size_variation
			
			for s in range(num_spheres):
				var crown_part = CSGSphere3D.new()
				crown_part.name = "CrownPart_" + str(s)
				crown_part.radius = max_radius * (0.7 + randf_range(0, 0.3))
				
				var offset_x = randf_range(-0.5, 0.5) * size_variation
				var offset_y = randf_range(-0.2, 0.4) * size_variation
				var offset_z = randf_range(-0.5, 0.5) * size_variation
				
				crown_part.position = Vector3(
					offset_x, 
					trunk.height + offset_y + crown_part.radius * 0.5,
					offset_z
				)
				
				var leaf_mat = leaf_material.duplicate()
				leaf_mat.albedo_color = leaf_material.albedo_color.lightened(randf_range(-0.2, 0.2) * color_variation)
				crown_part.material = leaf_mat
				
				tree.add_child(crown_part)
	
	parent.add_child(tree)
	return tree

func create_bush(parent, position):
	var bush = Node3D.new()
	bush.name = "Bush_" + str(parent.get_child_count())
	bush.position = position
	
	# Random rotation
	bush.rotation.y = randf_range(-PI, PI)
	
	# Random size variation
	var base_scale = 0.7 + randf_range(-size_variation, size_variation) * 0.5
	var scale_variation_x = 1.0 + randf_range(-size_variation, size_variation)
	var scale_variation_z = 1.0 + randf_range(-size_variation, size_variation)
	bush.scale = Vector3(base_scale * scale_variation_x, base_scale, base_scale * scale_variation_z)
	
	# Determine bush type
	var bush_type = randi() % 2  # 0 = rounded, 1 = irregular
	
	match bush_type:
		0:  # Rounded bush
			var main_bush = CSGSphere3D.new()
			main_bush.name = "MainBush"
			main_bush.radius = 0.6
			main_bush.position.y = main_bush.radius
			
			var leaf_mat = leaf_material.duplicate()
			leaf_mat.albedo_color = leaf_material.albedo_color.lightened(randf_range(-0.2, 0.2) * color_variation)
			main_bush.material = leaf_mat
			
			bush.add_child(main_bush)
			
		1:  # Irregular bush with multiple parts
			var num_parts = 2 + randi() % 3
			
			for p in range(num_parts):
				var bush_part = CSGSphere3D.new()
				bush_part.name = "BushPart_" + str(p)
				bush_part.radius = 0.4 + randf_range(-0.1, 0.2)
				
				var offset_x = randf_range(-0.4, 0.4)
				var offset_y = randf_range(0, 0.3)
				var offset_z = randf_range(-0.4, 0.4)
				
				bush_part.position = Vector3(offset_x, bush_part.radius + offset_y, offset_z)
				
				var leaf_mat = leaf_material.duplicate()
				leaf_mat.albedo_color = leaf_material.albedo_color.lightened(randf_range(-0.2, 0.2) * color_variation)
				bush_part.material = leaf_mat
				
				bush.add_child(bush_part)
	
	# Add some small flowers to certain bushes
	if randf() < 0.3:  # 30% chance of flowering bush
		add_flowers_to_bush(bush)
	
	parent.add_child(bush)
	return bush

func add_flowers_to_bush(bush):
	var num_flowers = randi() % 8 + 3
	var bush_radius = 0.6  # Approximate radius
	
	for i in range(num_flowers):
		var flower = CSGSphere3D.new()
		flower.name = "BushFlower_" + str(i)
		flower.radius = 0.05 + randf() * 0.04
		
		# Position on the surface
		var angle = randf() * 2 * PI
		var height = randf() * PI
		var x = bush_radius * sin(height) * cos(angle)
		var y = bush_radius * cos(height) + bush_radius
		var z = bush_radius * sin(height) * sin(angle)
		
		flower.position = Vector3(x, y, z)
		
		# Randomize flower color
		var flower_mat = flower_material.duplicate()
		
		# Randomly choose flower color
		var color_type = randi() % 4
		match color_type:
			0: flower_mat.albedo_color = Color(0.9, 0.4, 0.7)  # Pink
			1: flower_mat.albedo_color = Color(1.0, 1.0, 0.4)  # Yellow
			2: flower_mat.albedo_color = Color(1.0, 0.5, 0.0)  # Orange
			3: flower_mat.albedo_color = Color(0.7, 0.7, 1.0)  # Light Blue
		
		flower_mat.albedo_color = flower_mat.albedo_color.lightened(randf_range(-0.2, 0.2) * color_variation)
		flower.material = flower_mat
		
		bush.add_child(flower)

func create_flower(parent, position):
	var flower = Node3D.new()
	flower.name = "Flower_" + str(parent.get_child_count())
	flower.position = position
	
	# Random rotation
	flower.rotation.y = randf_range(-PI, PI)
	
	# Random size variation
	var base_scale = 0.3 + randf_range(-size_variation/2, size_variation/2)
	flower.scale = Vector3(base_scale, base_scale, base_scale)
	
	# Create stem
	var stem = CSGCylinder3D.new()
	stem.name = "Stem"
	stem.radius = 0.02
	stem.height = 0.3 + randf_range(-0.1, 0.2) * size_variation
	stem.position.y = stem.height / 2
	
	var stem_mat = leaf_material.duplicate()
	stem_mat.albedo_color = Color(0.2, 0.5, 0.1).darkened(0.3)
	stem.material = stem_mat
	
	flower.add_child(stem)
	
	# Determine flower style
	var flower_style = randi() % 3  # 0 = basic, 1 = daisy, 2 = complex
	
	match flower_style:
		0:  # Basic flower (simple sphere)
			var bloom = CSGSphere3D.new()
			bloom.name = "Bloom"
			bloom.radius = 0.1 + randf_range(-0.03, 0.05) * size_variation
			bloom.position.y = stem.height
			
			# Randomize flower color
			var flower_mat = flower_material.duplicate()
			
			# Randomly choose flower color
			var color_type = randi() % 5
			match color_type:
				0: flower_mat.albedo_color = Color(0.9, 0.4, 0.7)  # Pink
				1: flower_mat.albedo_color = Color(1.0, 1.0, 0.4)  # Yellow
				2: flower_mat.albedo_color = Color(1.0, 0.5, 0.0)  # Orange
				3: flower_mat.albedo_color = Color(0.7, 0.7, 1.0)  # Light Blue
				4: flower_mat.albedo_color = Color(1.0, 0.3, 0.3)  # Red
			
			flower_mat.albedo_color = flower_mat.albedo_color.lightened(randf_range(-0.2, 0.2) * color_variation)
			bloom.material = flower_mat
			
			flower.add_child(bloom)
			
		1:  # Daisy-like (center + petals)
			# Center
			var center = CSGSphere3D.new()
			center.name = "Center"
			center.radius = 0.06 + randf_range(-0.01, 0.02) * size_variation
			center.position.y = stem.height
			
			var center_mat = StandardMaterial3D.new()
			center_mat.albedo_color = Color(1.0, 0.9, 0.2)  # Yellow center
			center.material = center_mat
			
			flower.add_child(center)
			
			# Petals
			var num_petals = 5 + randi() % 8
			for p in range(num_petals):
				var petal = CSGSphere3D.new()
				petal.name = "Petal_" + str(p)
				petal.radius = 0.06 + randf_range(-0.01, 0.01) * size_variation
				
				var angle = 2 * PI * p / num_petals
				var petal_offset = 0.1
				var x = cos(angle) * petal_offset
				var z = sin(angle) * petal_offset
				
				petal.position = Vector3(x, stem.height, z)
				
				var petal_mat = StandardMaterial3D.new()
				petal_mat.albedo_color = Color(1.0, 1.0, 1.0) # White petals
				petal_mat.albedo_color = petal_mat.albedo_color.lightened(randf_range(-0.1, 0.1) * color_variation)
				petal.material = petal_mat
				
				flower.add_child(petal)
			
		2:  # Complex flower
			# Main bloom
			var bloom = CSGSphere3D.new()
			bloom.name = "Bloom"
			bloom.radius = 0.08 + randf_range(-0.02, 0.03) * size_variation
			bloom.position.y = stem.height
			
			# Choose an exotic color
			var bloom_mat = StandardMaterial3D.new()
			var color_type = randi() % 4
			match color_type:
				0: bloom_mat.albedo_color = Color(0.8, 0.2, 0.6)  # Magenta
				1: bloom_mat.albedo_color = Color(0.5, 0.0, 0.5)  # Purple
				2: bloom_mat.albedo_color = Color(0.9, 0.4, 0.0)  # Orange
				3: bloom_mat.albedo_color = Color(0.0, 0.5, 0.8)  # Blue
			
			bloom_mat.albedo_color = bloom_mat.albedo_color.lightened(randf_range(-0.2, 0.2) * color_variation)
			bloom.material = bloom_mat
			
			flower.add_child(bloom)
			
			# Additional parts
			var num_parts = 2 + randi() % 3
			for p in range(num_parts):
				var part = CSGSphere3D.new()
				part.name = "BloomPart_" + str(p)
				part.radius = 0.05 + randf_range(-0.02, 0.02) * size_variation
				
				var offset_x = randf_range(-0.07, 0.07)
				var offset_y = randf_range(0.02, 0.07)
				var offset_z = randf_range(-0.07, 0.07)
				
				part.position = Vector3(offset_x, stem.height + offset_y, offset_z)
				
				var part_mat = bloom_mat.duplicate()
				part_mat.albedo_color = part_mat.albedo_color.lightened(randf_range(-0.1, 0.3) * color_variation)
				part.material = part_mat
				
				flower.add_child(part)
	
	# Add some leaves to the stem
	if randf() < 0.7:  # 70% chance of having leaves
		var num_leaves = 1 + randi() % 2
		for l in range(num_leaves):
			var leaf = CSGSphere3D.new()
			leaf.name = "Leaf_" + str(l)
			
			# Flatten the sphere to make it leaf-like
			leaf.radius = 0.06 + randf_range(-0.02, 0.02) * size_variation
			leaf.scale = Vector3(1.0, 0.3, 1.0)
			
			var height = randf_range(0.1, 0.6) * stem.height
			var angle = randf() * 2 * PI
			var offset = 0.05
			
			leaf.position = Vector3(cos(angle) * offset, height, sin(angle) * offset)
			leaf.rotation.y = angle
			
			var leaf_mat = leaf_material.duplicate()
			leaf_mat.albedo_color = leaf_material.albedo_color.lightened(randf_range(-0.1, 0.1) * color_variation)
			leaf.material = leaf_mat
			
			flower.add_child(leaf)
	
	parent.add_child(flower)
	return flower

func create_grass(parent, position):
	var grass_clump = Node3D.new()
	grass_clump.name = "Grass_" + str(parent.get_child_count())
	grass_clump.position = position
	
	# Random rotation
	grass_clump.rotation.y = randf_range(-PI, PI)
	
	# Random overall size
	var base_scale = 0.5 + randf_range(-size_variation/2, size_variation/2)
	grass_clump.scale = Vector3(base_scale, base_scale, base_scale)
	
	# Determine grass type
	var grass_type = randi() % 3  # 0 = short, 1 = medium, 2 = tall
	var grass_height = 0.2  # Default height
	
	match grass_type:
		0: grass_height = 0.15 + randf_range(-0.05, 0.05)  # Short grass
		1: grass_height = 0.3 + randf_range(-0.1, 0.1)     # Medium grass
		2: grass_height = 0.5 + randf_range(-0.1, 0.15)    # Tall grass
	
	# Generate individual grass blades
	var num_blades = 5 + randi() % 10
	for b in range(num_blades):
		var blade = CSGCylinder3D.new()
		blade.name = "Blade_" + str(b)
		
		# Thin at the top, thicker at the bottom
		blade.radius= 0.01
		#blade.radius_bottom = 0.02 + randf_range(0, 0.01)
		blade.height = grass_height * (0.7 + randf_range(0, 0.6))
		
		# Position within the clump
		var offset_radius = 0.15
		var angle = randf() * 2 * PI
		var dist = randf() * offset_radius
		var x = cos(angle) * dist
		var z = sin(angle) * dist
		
		blade.position = Vector3(x, blade.height/2, z)
		
		# Tilt the grass blade slightly
		var tilt_angle = randf_range(0, 0.3)
		var tilt_direction = randf() * 2 * PI
		
		blade.rotation.x = cos(tilt_direction) * tilt_angle
		blade.rotation.z = sin(tilt_direction) * tilt_angle
		
		# Vary the grass color
		var grass_mat = grass_material.duplicate()
		var color_variation_amount = randf_range(-0.15, 0.15) * color_variation
		
		if grass_type == 0:  # Short grass tends to be more yellowish
			grass_mat.albedo_color = grass_material.albedo_color.lightened(0.1 + color_variation_amount)
		elif grass_type == 2:  # Tall grass tends to be darker
			grass_mat.albedo_color = grass_material.albedo_color.darkened(0.1 + color_variation_amount)
		else:
			grass_mat.albedo_color = grass_material.albedo_color.lightened(color_variation_amount)
		
		blade.material = grass_mat
		
		grass_clump.add_child(blade)
		
	# Add small flowers to some grass clumps
	if grass_type > 0 and randf() < 0.2:  # Only taller grass, 20% chance
		var num_flowers = randi() % 3 + 1
		for f in range(num_flowers):
			var small_flower = CSGSphere3D.new()
			small_flower.name = "GrassFlower_" + str(f)
			small_flower.radius = 0.03 + randf_range(-0.01, 0.01)
			
			var offset_radius = 0.1
			var angle = randf() * 2 * PI
			var dist = randf() * offset_radius
			var x = cos(angle) * dist
			var z = sin(angle) * dist
			var y = grass_height * 0.7 + randf_range(0, grass_height * 0.3)
			
			small_flower.position = Vector3(x, y, z)
			
			var flower_mat = flower_material.duplicate()
			
			# Randomly choose flower color
			var color_type = randi() % 3
			match color_type:
				0: flower_mat.albedo_color = Color(1.0, 1.0, 0.4)  # Yellow
				1: flower_mat.albedo_color = Color(1.0, 1.0, 1.0)  # White
				2: flower_mat.albedo_color = Color(0.7, 0.2, 0.6)  # Purple
			
			flower_mat.albedo_color = flower_mat.albedo_color.lightened(randf_range(-0.1, 0.1) * color_variation)
			small_flower.material = flower_mat
			
			grass_clump.add_child(small_flower)
	
	parent.add_child(grass_clump)
	return grass_clump

func setup_environment():
	# Create a camera for better viewing
	var camera = Camera3D.new()
	camera.name = "Camera"
	camera.position = Vector3(0, 5, 10)
	camera.look_at_from_position(camera.position, Vector3(0, 0, 0), Vector3.UP)
	add_child(camera)
	
	# Create directional light for sun
	var sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.position = Vector3(10, 10, 10)
	sun.look_at_from_position(sun.position, Vector3(0, 0, 0), Vector3.UP)
	sun.light_energy = 1.2
	add_child(sun)
	
	# Create ambient light
	var environment = Environment.new()
	environment.ambient_light_color = Color(0.5, 0.6, 0.7)
	environment.ambient_light_energy = 0.5
	
	var world_env = WorldEnvironment.new()
	world_env.environment = environment
	add_child(world_env)
