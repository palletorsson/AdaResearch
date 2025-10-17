extends Node3D

# Landscape parameters
@export var landscape_size := Vector2(50.0, 50.0)
@export var height_scale := 5.0
@export_range(1, 10) var terrain_octaves := 4
@export var terrain_seed := 0
@export_range(0.1, 5.0) var terrain_frequency := 0.8

# Plant generation parameters
@export_range(50, 500) var plant_count := 200
@export_range(1, 20) var strange_plant_types := 10
@export_range(0.0, 1.0) var mutation_factor := 0.7
@export_range(0.2, 5.0) var plant_scale_min := 0.5
@export_range(1.0, 10.0) var plant_scale_max := 5.0

# Color palettes inspired by Bosch
var paradise_colors = [
	Color(0.8, 0.9, 0.7), # Light green
	Color(0.6, 0.8, 0.9), # Light blue
	Color(0.9, 0.85, 0.7), # Cream
	Color(0.9, 0.7, 0.8), # Pink
	Color(0.7, 0.9, 0.9)  # Light turquoise
]

var pleasure_colors = [
	Color(0.9, 0.6, 0.7), # Pink
	Color(0.7, 0.8, 0.4), # Yellow-green
	Color(0.4, 0.7, 0.9), # Blue
	Color(0.9, 0.7, 0.5), # Peach
	Color(0.8, 0.4, 0.7)  # Magenta
]

var hell_colors = [
	Color(0.8, 0.3, 0.2), # Red
	Color(0.3, 0.3, 0.4), # Dark blue
	Color(0.2, 0.2, 0.2), # Dark gray
	Color(0.7, 0.6, 0.2), # Gold
	Color(0.4, 0.2, 0.3)  # Dark purple
]

# Various plant parts for generation
var stem_meshes = []
var bulb_meshes = []
var leaf_meshes = []

# Noise generators
var terrain_noise: FastNoiseLite
var plant_position_noise: FastNoiseLite
var plant_type_noise: FastNoiseLite

func _ready():
	# Set up noise generators
	randomize()
	terrain_seed = randi() if terrain_seed == 0 else terrain_seed
	
	terrain_noise = FastNoiseLite.new()
	terrain_noise.seed = terrain_seed
	terrain_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	terrain_noise.fractal_octaves = terrain_octaves
	terrain_noise.frequency = terrain_frequency
	
	plant_position_noise = FastNoiseLite.new()
	plant_position_noise.seed = terrain_seed + 1
	
	plant_type_noise = FastNoiseLite.new()
	plant_type_noise.seed = terrain_seed + 2
	
	# Generate terrain
	generate_terrain()
	
	# Create basic meshes for plant generation
	create_basic_plant_meshes()
	
	# Generate plants
	generate_plants()
	


func generate_terrain():
	# Create a gridmesh for the terrain
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = landscape_size
	plane_mesh.subdivide_width = 100
	plane_mesh.subdivide_depth = 100
	
	# Create a MeshInstance for the terrain
	var terrain = MeshInstance3D.new()
	terrain.mesh = plane_mesh
	add_child(terrain)
	
	# Apply height displacement to the terrain
	var surface_tool = SurfaceTool.new()
	surface_tool.create_from(plane_mesh, 0)
	var mesh_data = surface_tool.commit()
	
	var arrays = mesh_data.surface_get_arrays(0)
	var vertices = arrays[Mesh.ARRAY_VERTEX]
	var normals = arrays[Mesh.ARRAY_NORMAL]
	
	# Create a new array mesh for the modified terrain
	var array_mesh = ArrayMesh.new()
	arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	# Deform vertices based on noise
	for i in range(vertices.size()):
		var vertex = vertices[i]
		var noise_value = terrain_noise.get_noise_2d(vertex.x, vertex.z)
		vertex.y = noise_value * height_scale
		vertices[i] = vertex
	
	# Recalculate normals
	surface_tool.clear()
	# Note: create_from_blend_shape removed - blend shapes not available in this context
	# surface_tool.create_from_blend_shape(mesh_data, 0, "0")
	
	# Create a new mesh with the modified vertices
	arrays[Mesh.ARRAY_VERTEX] = vertices
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	surface_tool.create_from(array_mesh, 0)
	surface_tool.generate_normals()
	
	# Apply the modified mesh to the terrain
	terrain.mesh = surface_tool.commit()
	
	# Create a shader material for the terrain
	var terrain_material = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = """
	shader_type spatial;
	
	uniform sampler2D gradient_texture;
	uniform float height_scale = 5.0;
	
	varying float height;
	
	void vertex() {
		height = VERTEX.y / height_scale;
	}
	
	void fragment() {
		// Sample color from gradient based on height
		vec4 color = texture(gradient_texture, vec2(clamp(height * 0.5 + 0.5, 0.0, 1.0), 0.5));
		
		// Apply some variation based on position
		float variation = sin(FRAGCOORD.x * 0.01) * cos(FRAGCOORD.y * 0.01) * 0.1;
		
		ALBEDO = color.rgb + variation;
		ROUGHNESS = 0.8;
		METALLIC = 0.0;
	}
	"""
	
	# Create a gradient texture for the terrain
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.2, 0.3, 0.5))  # Water/low areas
	gradient.add_point(0.3, Color(0.7, 0.8, 0.5))  # Grass/land
	gradient.add_point(0.7, Color(0.8, 0.7, 0.6))  # Higher elevation
	gradient.add_point(1.0, Color(0.9, 0.9, 0.9))  # Peaks
	
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	
	terrain_material.shader = shader
	terrain_material.set_shader_parameter("gradient_texture", gradient_texture)
	terrain_material.set_shader_parameter("height_scale", height_scale)
	
	terrain.material_override = terrain_material

func create_basic_plant_meshes():
	# Create various stem types
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.1
	cylinder.bottom_radius = 0.2
	cylinder.height = 2.0
	stem_meshes.append(cylinder)
	
	var curved_cylinder = CylinderMesh.new()
	curved_cylinder.top_radius = 0.05
	curved_cylinder.bottom_radius = 0.15
	curved_cylinder.height = 3.0
	stem_meshes.append(curved_cylinder)
	
	# Create various bulb types
	var sphere = SphereMesh.new()
	sphere.radius = 0.5
	bulb_meshes.append(sphere)
	
	var capsule = CapsuleMesh.new()
	capsule.radius = 0.4
	capsule.height = 1.2
	bulb_meshes.append(capsule)
	
	# Create various leaf types
	var prism = PrismMesh.new()
	prism.size = Vector3(1.0, 0.1, 0.5)
	leaf_meshes.append(prism)
	
	var plane = PlaneMesh.new()
	plane.size = Vector2(0.8, 0.4)
	leaf_meshes.append(plane)

func generate_plants():
	# Create a root node for all plants
	var plants_root = Node3D.new()
	plants_root.name = "Plants"
	add_child(plants_root)
	
	# Generate predefined strange plant types
	var strange_plant_templates = []
	for i in range(strange_plant_types):
		strange_plant_templates.append(create_strange_plant_template(i))
	
	# Distribute plants across the terrain
	for i in range(plant_count):
		# Get a random position
		var pos_x = randf_range(-landscape_size.x/2, landscape_size.x/2)
		var pos_z = randf_range(-landscape_size.y/2, landscape_size.y/2)
		
		# Get height at this position
		var height = terrain_noise.get_noise_2d(pos_x, pos_z) * height_scale
		
		# Position slightly above terrain to avoid z-fighting
		var plant_position = Vector3(pos_x, height + 0.05, pos_z)
		
		# Choose which section of the triptych this plant belongs to
		var section = int(3.0 * (pos_x + landscape_size.x/2) / landscape_size.x)
		section = clamp(section, 0, 2)
		
		# Choose a plant template and instantiate it
		var template_idx = int(randf_range(0, strange_plant_types))
		var plant = strange_plant_templates[template_idx].duplicate()
		
		# Apply color palette based on section (left: paradise, middle: pleasure, right: hell)
		var palette
		match section:
			0: palette = paradise_colors
			1: palette = pleasure_colors
			2: palette = hell_colors
		
		# Apply random scale
		var scale_factor = randf_range(plant_scale_min, plant_scale_max)
		plant.scale = Vector3(scale_factor, scale_factor, scale_factor)
		
		# Slightly rotate the plant for variety
		plant.rotation.y = randf_range(0, TAU)
		plant.position = plant_position
		
		# Apply color palette to all materials in the plant
		apply_color_palette(plant, palette)
		
		# Add variation through mutation if desired
		if randf() < mutation_factor:
			mutate_plant(plant)
		
		plants_root.add_child(plant)

func create_strange_plant_template(template_id):
	var plant = Node3D.new()
	plant.name = "StrangePlant_" + str(template_id)
	
	# Deterministic but varied generation based on template_id
	var rng = RandomNumberGenerator.new()
	rng.seed = template_id + terrain_seed * 100
	
	# Choose base stem
	var stem_idx = rng.randi_range(0, stem_meshes.size() - 1)
	var stem = MeshInstance3D.new()
	stem.mesh = stem_meshes[stem_idx]
	stem.name = "Stem"
	
	# Create material for stem
	var stem_material = StandardMaterial3D.new()
	stem_material.albedo_color = Color(0.4, 0.6, 0.3)
	stem.material_override = stem_material
	
	plant.add_child(stem)
	
	# Number of bulbs and leaves
	var num_bulbs = rng.randi_range(1, 5)
	var num_leaves = rng.randi_range(2, 8)
	
	# Add bulbs
	for i in range(num_bulbs):
		var bulb_parent = Node3D.new()
		bulb_parent.name = "BulbParent_" + str(i)
		
		# Position bulb along stem with some randomness
		var height_along_stem = rng.randf_range(0.5, 1.2)
		bulb_parent.position.y = height_along_stem
		
		# Add some outward offset for some bulbs
		if rng.randf() > 0.5:
			var angle = rng.randf_range(0, TAU)
			var offset = rng.randf_range(0.2, 0.8)
			bulb_parent.position.x = cos(angle) * offset
			bulb_parent.position.z = sin(angle) * offset
		
		# Rotate bulb for uniqueness
		bulb_parent.rotation = Vector3(
			rng.randf_range(-0.5, 0.5),
			rng.randf_range(0, TAU),
			rng.randf_range(-0.5, 0.5)
		)
		
		var bulb_idx = rng.randi_range(0, bulb_meshes.size() - 1)
		var bulb = MeshInstance3D.new()
		bulb.mesh = bulb_meshes[bulb_idx]
		
		# Scale bulb randomly
		var bulb_scale = rng.randf_range(0.5, 1.5)
		bulb.scale = Vector3(bulb_scale, bulb_scale, bulb_scale)
		
		# Create material for bulb
		var bulb_material = StandardMaterial3D.new()
		bulb_material.albedo_color = Color(0.9, 0.4, 0.5)
		bulb.material_override = bulb_material
		
		bulb_parent.add_child(bulb)
		plant.add_child(bulb_parent)
		
		# Sometimes add smaller decorative elements to bulbs (Bosch-like details)
		if rng.randf() > 0.7:
			add_decorative_elements(bulb_parent, rng)
	
	# Add leaves
	for i in range(num_leaves):
		var leaf_parent = Node3D.new()
		leaf_parent.name = "LeafParent_" + str(i)
		
		# Position leaf along stem
		var height_along_stem = rng.randf_range(0.0, 1.0)
		leaf_parent.position.y = height_along_stem
		
		# Angle leaves outward
		var angle = rng.randf_range(0, TAU)
		var offset = rng.randf_range(0.1, 0.3)
		leaf_parent.position.x = cos(angle) * offset
		leaf_parent.position.z = sin(angle) * offset
		
		leaf_parent.rotation = Vector3(
			rng.randf_range(-0.2, 0.5),
			angle,
			rng.randf_range(-0.3, 0.3)
		)
		
		var leaf_idx = rng.randi_range(0, leaf_meshes.size() - 1)
		var leaf = MeshInstance3D.new()
		leaf.mesh = leaf_meshes[leaf_idx]
		
		# Create material for leaf
		var leaf_material = StandardMaterial3D.new()
		leaf_material.albedo_color = Color(0.3, 0.7, 0.4)
		leaf.material_override = leaf_material
		
		leaf_parent.add_child(leaf)
		plant.add_child(leaf_parent)
	
	# Sometimes add queer-form elements that are completely unexpected
	if rng.randf() > 0.5:
		add_queer_form_elements(plant, rng)
	
	return plant

func add_decorative_elements(parent_node, rng):
	# Add small decorative elements that reference Bosch's style
	var num_elements = rng.randi_range(1, 3)
	
	for i in range(num_elements):
		var element = MeshInstance3D.new()
		element.name = "Decoration_" + str(i)
		
		# Choose a small mesh for decoration
		var mesh_type = rng.randi_range(0, 3)
		match mesh_type:
			0: # Small sphere
				var sphere = SphereMesh.new()
				sphere.radius = rng.randf_range(0.05, 0.15)
				element.mesh = sphere
			1: # Small cube
				var cube = BoxMesh.new()
				cube.size = Vector3.ONE * rng.randf_range(0.1, 0.2)
				element.mesh = cube
			2: # Small cylinder
				var cylinder = CylinderMesh.new()
				cylinder.top_radius = rng.randf_range(0.03, 0.08)
				cylinder.bottom_radius = rng.randf_range(0.03, 0.08)
				cylinder.height = rng.randf_range(0.1, 0.3)
				element.mesh = cylinder
			3: # Small torus
				var torus = TorusMesh.new()
				torus.inner_radius = rng.randf_range(0.03, 0.08)
				torus.outer_radius = rng.randf_range(0.08, 0.15)
				element.mesh = torus
		
		# Position around parent
		var angle = rng.randf_range(0, TAU)
		var radius = rng.randf_range(0.2, 0.5)
		element.position = Vector3(
			cos(angle) * radius,
			rng.randf_range(-0.2, 0.2),
			sin(angle) * radius
		)
		
		# Random rotation
		element.rotation = Vector3(
			rng.randf_range(0, TAU),
			rng.randf_range(0, TAU),
			rng.randf_range(0, TAU)
		)
		
		# Create material with bright color
		var element_material = StandardMaterial3D.new()
		element_material.albedo_color = Color(
			rng.randf_range(0.5, 1.0),
			rng.randf_range(0.5, 1.0),
			rng.randf_range(0.5, 1.0)
		)
		
		# Sometimes add emission for glow effects
		if rng.randf() > 0.7:
			element_material.emission_enabled = true
			element_material.emission = element_material.albedo_color
			element_material.emission_energy_multiplier = rng.randf_range(0.5, 2.0)
		
		element.material_override = element_material
		parent_node.add_child(element)

func add_queer_form_elements(plant_node, rng):
	# Add elements that break from traditional plant forms
	var num_elements = rng.randi_range(1, 4)
	
	for i in range(num_elements):
		var element = Node3D.new()
		element.name = "QueerForm_" + str(i)
		
		# Position somewhere on the plant
		element.position = Vector3(
			rng.randf_range(-0.5, 0.5),
			rng.randf_range(0.3, 1.5),
			rng.randf_range(-0.5, 0.5)
		)
		
		# Create a unique, non-traditional form
		var form_type = rng.randi_range(0, 5)
		match form_type:
			0: # Tubes growing in spiral
				create_spiral_tubes(element, rng)
			1: # Floating bubble cluster
				create_bubble_cluster(element, rng)
			2: # Geometric crystal formation
				create_crystal_formation(element, rng)
			3: # Membrane sheets
				create_membrane_sheets(element, rng)
			4: # Multi-pronged starburst
				create_starburst(element, rng)
			5: # Nested rings
				create_nested_rings(element, rng)
		
		plant_node.add_child(element)

func create_spiral_tubes(parent, rng):
	var num_tubes = rng.randi_range(3, 7)
	var spiral_radius = rng.randf_range(0.2, 0.5)
	var vertical_stretch = rng.randf_range(0.2, 0.8)
	
	for i in range(num_tubes):
		var tube = MeshInstance3D.new()
		var cylinder = CylinderMesh.new()
		cylinder.top_radius = rng.randf_range(0.02, 0.08)
		cylinder.bottom_radius = rng.randf_range(0.02, 0.08)
		cylinder.height = rng.randf_range(0.3, 0.7)
		tube.mesh = cylinder
		
		# Position in spiral pattern
		var angle = float(i) / float(num_tubes) * TAU
		var offset_angle = angle + TAU * float(i) / float(num_tubes) * 0.5
		tube.position = Vector3(
			cos(angle) * spiral_radius,
			sin(angle) * vertical_stretch,
			sin(angle) * spiral_radius
		)
		
		# Orient tube tangent to spiral
		var target_pos = Vector3(
			cos(offset_angle) * spiral_radius,
			sin(offset_angle) * vertical_stretch,
			sin(offset_angle) * spiral_radius
		)
		# Only orient if positions are different
		if not tube.position.is_equal_approx(target_pos):
			tube.look_at_from_position(tube.position, target_pos, Vector3.UP)
		
		# Create material
		var tube_material = StandardMaterial3D.new()
		tube_material.albedo_color = Color(
			rng.randf_range(0.7, 1.0),
			rng.randf_range(0.3, 0.8),
			rng.randf_range(0.3, 0.8)
		)
		tube.material_override = tube_material
		
		parent.add_child(tube)

func create_bubble_cluster(parent, rng):
	var num_bubbles = rng.randi_range(5, 12)
	
	for i in range(num_bubbles):
		var bubble = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = rng.randf_range(0.05, 0.2)
		bubble.mesh = sphere
		
		# Random position in cluster
		bubble.position = Vector3(
			rng.randf_range(-0.3, 0.3),
			rng.randf_range(-0.3, 0.3),
			rng.randf_range(-0.3, 0.3)
		)
		
		# Create translucent material
		var bubble_material = StandardMaterial3D.new()
		bubble_material.albedo_color = Color(
			rng.randf_range(0.7, 1.0),
			rng.randf_range(0.7, 1.0),
			rng.randf_range(0.7, 1.0),
			rng.randf_range(0.2, 0.7) # Alpha
		)
		bubble_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		bubble_material.metallic = rng.randf_range(0.1, 0.5)
		bubble_material.roughness = rng.randf_range(0.0, 0.3)
		
		bubble.material_override = bubble_material
		parent.add_child(bubble)

func create_crystal_formation(parent, rng):
	var num_crystals = rng.randi_range(3, 8)
	
	for i in range(num_crystals):
		var crystal = MeshInstance3D.new()
		var prism = PrismMesh.new()
		prism.size = Vector3(
			rng.randf_range(0.05, 0.15),
			rng.randf_range(0.2, 0.5),
			rng.randf_range(0.05, 0.15)
		)
		crystal.mesh = prism
		
		# Position around central point
		var angle = rng.randf_range(0, TAU)
		var radius = rng.randf_range(0.0, 0.2)
		crystal.position = Vector3(
			cos(angle) * radius,
			rng.randf_range(-0.1, 0.3),
			sin(angle) * radius
		)
		
		# Orient outward from center
		crystal.rotation = Vector3(
			rng.randf_range(-0.3, 0.3),
			angle + PI,
			rng.randf_range(-0.3, 0.3)
		)
		
		# Create material with shiny, crystalline properties
		var crystal_material = StandardMaterial3D.new()
		crystal_material.albedo_color = Color(
			rng.randf_range(0.4, 0.9),
			rng.randf_range(0.4, 0.9),
			rng.randf_range(0.4, 0.9)
		)
		crystal_material.metallic = rng.randf_range(0.3, 0.8)
		crystal_material.roughness = rng.randf_range(0.0, 0.2)
		
		crystal.material_override = crystal_material
		parent.add_child(crystal)

func create_membrane_sheets(parent, rng):
	var num_sheets = rng.randi_range(2, 5)
	
	for i in range(num_sheets):
		var sheet = MeshInstance3D.new()
		var plane = PlaneMesh.new()
		plane.size = Vector2(
			rng.randf_range(0.3, 0.7),
			rng.randf_range(0.3, 0.7)
		)
		sheet.mesh = plane
		
		# Position with overlapping sheets
		sheet.position = Vector3(
			rng.randf_range(-0.1, 0.1),
			rng.randf_range(-0.05, 0.15) * i,
			rng.randf_range(-0.1, 0.1)
		)
		
		# Random orientation
		sheet.rotation = Vector3(
			rng.randf_range(0, TAU),
			rng.randf_range(0, TAU),
			rng.randf_range(0, TAU)
		)
		
		# Create translucent, membrane-like material
		var sheet_material = StandardMaterial3D.new()
		sheet_material.albedo_color = Color(
			rng.randf_range(0.6, 0.9),
			rng.randf_range(0.6, 0.9),
			rng.randf_range(0.6, 0.9),
			rng.randf_range(0.3, 0.6) # Alpha
		)
		sheet_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sheet_material.cull_mode = BaseMaterial3D.CULL_DISABLED # Double-sided
		
		sheet.material_override = sheet_material
		parent.add_child(sheet)

func create_starburst(parent, rng):
	var num_spikes = rng.randi_range(5, 12)
	
	for i in range(num_spikes):
		var spike = MeshInstance3D.new()
		var cylinder = CylinderMesh.new()
		cylinder.top_radius = 0.01
		cylinder.bottom_radius = rng.randf_range(0.03, 0.07)
		cylinder.height = rng.randf_range(0.2, 0.6)
		spike.mesh = cylinder
		
		# Position in starburst pattern
		var phi = rng.randf_range(0, PI)
		var theta = float(i) / float(num_spikes) * TAU
		
		var x = sin(phi) * cos(theta)
		var y = sin(phi) * sin(theta)
		var z = cos(phi)
		
		spike.position = Vector3.ZERO
		spike.look_at_from_position(spike.position, Vector3(x, y, z), Vector3.UP)
		spike.rotation_degrees.x += 90 # Correct cylinder orientation
		
		# Create material
		var spike_material = StandardMaterial3D.new()
		spike_material.albedo_color = Color(
			rng.randf_range(0.5, 1.0),
			rng.randf_range(0.3, 0.8),
			rng.randf_range(0.3, 1.0)
		)
		
		# Sometimes add emission
		if rng.randf() > 0.5:
			spike_material.emission_enabled = true
			spike_material.emission = spike_material.albedo_color
			spike_material.emission_energy_multiplier = rng.randf_range(0.3, 1.5)
		
		spike.material_override = spike_material
		parent.add_child(spike)

func create_nested_rings(parent, rng):
	var num_rings = rng.randi_range(3, 6)
	
	for i in range(num_rings):
		var ring = MeshInstance3D.new()
		var torus = TorusMesh.new()
		
		var scale_factor = 1.0 - (float(i) / float(num_rings)) * 0.7
		torus.inner_radius = rng.randf_range(0.1, 0.2) * scale_factor
		torus.outer_radius = rng.randf_range(0.2, 0.4) * scale_factor
		ring.mesh = torus
		
		# Slightly offset each ring
		ring.position = Vector3(
			rng.randf_range(-0.05, 0.05) * i,
			rng.randf_range(-0.05, 0.05) * i,
			rng.randf_range(-0.05, 0.05) * i
		)
		
		# Rotate rings differently
		ring.rotation = Vector3(
			rng.randf_range(0, TAU),
			rng.randf_range(0, TAU),
			rng.randf_range(0, TAU)
		)
		
		# Create material
		var ring_material = StandardMaterial3D.new()
		ring_material.albedo_color = Color(
			rng.randf_range(0.5, 0.9),
			rng.randf_range(0.5, 0.9),
			rng.randf_range(0.5, 0.9)
		)
		
		# Add iridescence to some rings
		if rng.randf() > 0.6:
			ring_material.metallic = rng.randf_range(0.3, 0.9)
			ring_material.roughness = rng.randf_range(0.0, 0.3)
		
		ring.material_override = ring_material
		parent.add_child(ring)



# Apply a color palette to all materials in the plant
static func apply_color_palette(plant, palette):
	# Apply color palette to all materials in the plant
	# This recursively traverses the plant node to apply colors from the palette
	
	# Iterate through all children
	for child in plant.get_children():
		# If it's a MeshInstance with a material, change its color
		if child is MeshInstance3D and child.material_override:
			var material = child.material_override
			if material is StandardMaterial3D:
				# Select a random color from the palette
				var color_idx = randi() % palette.size()
				material.albedo_color = palette[color_idx]
				
				# Modify emission to match if it's enabled
				if material.emission_enabled:
					material.emission = palette[color_idx]
		
		# Recursively process any children of this node
		if child.get_child_count() > 0:
			apply_color_palette(child, palette)

# Add variation through mutation
static func mutate_plant(plant):
	# Add variation through mutation by making unexpected changes to the plant
	# This creates more surreal and queer forms inspired by Bosch's work
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# Choose a mutation type
	var mutation_type = rng.randi_range(0, 5)
	
	match mutation_type:
		0: # Add fusion of unexpected parts
			add_fused_elements(plant, rng)
		1: # Extreme scale variations
			apply_extreme_scale_mutations(plant, rng)
		2: # Hybrid form that combines features
			create_hybrid_form(plant, rng)
		3: # Add humanoid or creature-like features (Bosch-style)
			add_creature_features(plant, rng)
		4: # Distortion of existing elements
			apply_distortion(plant, rng)
		5: # Metamorphosis - plant transforming into something else
			apply_metamorphosis(plant, rng)

# Helper functions for mutations
static func add_fused_elements(plant, rng):
	# Fuse unexpected elements together
	var num_fusions = rng.randi_range(1, 3)
	
	for i in range(num_fusions):
		# Create a container for fused elements
		var fusion = Node3D.new()
		fusion.name = "Fusion_" + str(i)
		
		# Pick random position on plant
		fusion.position = Vector3(
			rng.randf_range(-0.2, 0.2),
			rng.randf_range(0.3, 1.2),
			rng.randf_range(-0.2, 0.2)
		)
		
		# Mix elements from different categories
		var elements = []
		elements.append(create_random_mesh(rng, "organic"))
		elements.append(create_random_mesh(rng, "geometric"))
		if rng.randf() > 0.5:
			elements.append(create_random_mesh(rng, "symbolic"))
		
		# Position elements with overlapping
		for j in range(elements.size()):
			var element = elements[j]
			element.position = Vector3(
				rng.randf_range(-0.1, 0.1),
				rng.randf_range(-0.1, 0.1) * j,
				rng.randf_range(-0.1, 0.1)
			)
			element.rotation = Vector3(
				rng.randf_range(0, TAU),
				rng.randf_range(0, TAU),
				rng.randf_range(0, TAU)
			)
			fusion.add_child(element)
		
		plant.add_child(fusion)

static func apply_extreme_scale_mutations(plant, rng):
	# Find random mesh instances to apply extreme scaling to
	var mesh_instances = []
	find_all_mesh_instances(plant, mesh_instances)
	
	if mesh_instances.size() > 0:
		var num_mutations = rng.randi_range(1, min(3, mesh_instances.size()))
		
		for i in range(num_mutations):
			var idx = rng.randi_range(0, mesh_instances.size() - 1)
			var mesh_instance = mesh_instances[idx]
			
			# Apply extreme scale in one dimension
			var scale_axis = rng.randi_range(0, 2)
			var extreme_scale = rng.randf_range(2.0, 5.0)
			
			var new_scale = mesh_instance.scale
			match scale_axis:
				0: new_scale.x *= extreme_scale
				1: new_scale.y *= extreme_scale
				2: new_scale.z *= extreme_scale
			
			mesh_instance.scale = new_scale
			
			# Remove from list to avoid double mutations
			mesh_instances.remove_at(idx)

static func create_hybrid_form(plant, rng):
	# Create a hybrid form by combining multiple shapes
	var hybrid = Node3D.new()
	hybrid.name = "Hybrid"
	
	# Position on plant
	hybrid.position = Vector3(
		rng.randf_range(-0.3, 0.3),
		rng.randf_range(0.5, 1.5),
		rng.randf_range(-0.3, 0.3)
	)
	
	# Create base shape
	var base_shape = MeshInstance3D.new()
	var base_type = rng.randi_range(0, 2)
	match base_type:
		0: # Bulbous base
			var sphere = SphereMesh.new()
			sphere.radius = rng.randf_range(0.2, 0.4)
			base_shape.mesh = sphere
		1: # Elongated base
			var capsule = CapsuleMesh.new()
			capsule.radius = rng.randf_range(0.15, 0.3)
			capsule.height = rng.randf_range(0.4, 0.8)
			base_shape.mesh = capsule
		2: # Angular base
			var box = BoxMesh.new()
			box.size = Vector3(
				rng.randf_range(0.3, 0.5),
				rng.randf_range(0.3, 0.5),
				rng.randf_range(0.3, 0.5)
			)
			base_shape.mesh = box
	
	# Create material for base
	var base_material = StandardMaterial3D.new()
	base_material.albedo_color = Color(
		rng.randf_range(0.4, 0.9),
		rng.randf_range(0.4, 0.9),
		rng.randf_range(0.4, 0.9)
	)
	base_shape.material_override = base_material
	
	hybrid.add_child(base_shape)
	
	# Add appendages or extensions
	var num_appendages = rng.randi_range(2, 5)
	
	for i in range(num_appendages):
		var appendage = MeshInstance3D.new()
		var app_type = rng.randi_range(0, 3)
		
		match app_type:
			0: # Tentacle-like
				var cylinder = CylinderMesh.new()
				cylinder.top_radius = rng.randf_range(0.02, 0.05)
				cylinder.bottom_radius = rng.randf_range(0.05, 0.1)
				cylinder.height = rng.randf_range(0.3, 0.7)
				appendage.mesh = cylinder
			1: # Horn-like
				var prism = PrismMesh.new()
				prism.size = Vector3(
					rng.randf_range(0.05, 0.15),
					rng.randf_range(0.2, 0.5),
					rng.randf_range(0.05, 0.15)
				)
				appendage.mesh = prism
			2: # Bubble-like
				var sphere = SphereMesh.new()
				sphere.radius = rng.randf_range(0.1, 0.2)
				appendage.mesh = sphere
			3: # Flat extension
				var plane = PlaneMesh.new()
				plane.size = Vector2(
					rng.randf_range(0.2, 0.4),
					rng.randf_range(0.2, 0.4)
				)
				appendage.mesh = plane
		
		# Position around base
		var phi = rng.randf_range(0, PI)
		var theta = float(i) / float(num_appendages) * TAU
		
		var radius = rng.randf_range(0.2, 0.3)
		var x = sin(phi) * cos(theta) * radius
		var y = sin(phi) * sin(theta) * radius
		var z = cos(phi) * radius
		
		appendage.position = Vector3(x, y, z)
		
		# Orient outward from center
		appendage.look_at_from_position(appendage.position, appendage.position * 2, Vector3.UP)
		
		# Create material with contrasting color
		var app_material = StandardMaterial3D.new()
		app_material.albedo_color = Color(
			rng.randf_range(0.4, 0.9),
			rng.randf_range(0.4, 0.9),
			rng.randf_range(0.4, 0.9)
		)
		# Make color different from base
		app_material.albedo_color = app_material.albedo_color.inverted()
		
		appendage.material_override = app_material
		hybrid.add_child(appendage)
	
	plant.add_child(hybrid)

static func add_creature_features(plant, rng):
	# Add elements that resemble parts of creatures (eyes, mouths, etc.)
	# Typical in Bosch's surreal creature designs
	
	var feature_type = rng.randi_range(0, 3)
	
	match feature_type:
		0: # Eyes
			add_eyes(plant, rng)
		1: # Mouth-like opening
			add_mouth(plant, rng)
		2: # Fin or wing-like structures
			add_fins(plant, rng)
		3: # Egg-like pods
			add_eggs(plant, rng)

static func apply_distortion(plant, rng):
	# Apply distortion to existing mesh instances
	var mesh_instances = []
	find_all_mesh_instances(plant, mesh_instances)
	
	if mesh_instances.size() > 0:
		var num_distortions = rng.randi_range(1, min(3, mesh_instances.size()))
		
		for i in range(num_distortions):
			var idx = rng.randi_range(0, mesh_instances.size() - 1)
			var mesh_instance = mesh_instances[idx]
			
			# Apply random twist or bend
			var distortion_type = rng.randi_range(0, 1)
			match distortion_type:
				0: # Twist
					mesh_instance.rotation = Vector3(
						mesh_instance.rotation.x + rng.randf_range(-PI/2, PI/2),
						mesh_instance.rotation.y + rng.randf_range(-PI/2, PI/2),
						mesh_instance.rotation.z + rng.randf_range(-PI/2, PI/2)
					)
				1: # Bend (apply non-uniform scale)
					var bend_dir = rng.randi_range(0, 2)
					var bend_factor = rng.randf_range(0, 2.0) + 0.5
					
					var new_scale = mesh_instance.scale
					match bend_dir:
						0: new_scale.x *= bend_factor
						1: new_scale.y *= bend_factor
						2: new_scale.z *= bend_factor
					
					mesh_instance.scale = new_scale
			
			# Remove from list to avoid double mutations
			mesh_instances.remove_at(idx)

static func apply_metamorphosis(plant, rng):
	# Transform part of the plant into something completely different
	var meta_node = Node3D.new()
	meta_node.name = "Metamorphosis"
	
	# Position on the plant
	meta_node.position = Vector3(
		rng.randf_range(-0.3, 0.3),
		rng.randf_range(0.5, 1.2),
		rng.randf_range(-0.3, 0.3)
	)
	
	# Choose metamorphosis type
	var meta_type = rng.randi_range(0, 2)
	
	match meta_type:
		0: # Architectural element (Bosch often included bizarre buildings)
			create_architectural_element(meta_node, rng)
		1: # Musical instrument (common in Bosch's work)
			create_musical_instrument(meta_node, rng)
		2: # Fruit/food with faces (another Bosch motif)
			create_animated_fruit(meta_node, rng)
	
	plant.add_child(meta_node)

# Additional helper functions
static func find_all_mesh_instances(node, mesh_instances):
	# Recursively find all MeshInstance3D nodes
	for child in node.get_children():
		if child is MeshInstance3D:
			mesh_instances.append(child)
		
		if child.get_child_count() > 0:
			find_all_mesh_instances(child, mesh_instances)

static func create_random_mesh(rng, type):
	# Create a random mesh based on the type
	var mesh_instance = MeshInstance3D.new()
	
	if type == "organic":
		var mesh_type = rng.randi_range(0, 2)
		match mesh_type:
			0: # Blob-like
				var sphere = SphereMesh.new()
				sphere.radius = rng.randf_range(0.1, 0.2)
				mesh_instance.mesh = sphere
			1: # Elongated
				var capsule = CapsuleMesh.new()
				capsule.radius = rng.randf_range(0.05, 0.1)
				capsule.height = rng.randf_range(0.2, 0.4)
				mesh_instance.mesh = capsule
			2: # Curved
				var torus = TorusMesh.new()
				torus.inner_radius = rng.randf_range(0.03, 0.08)
				torus.outer_radius = rng.randf_range(0.1, 0.2)
				mesh_instance.mesh = torus
	
	elif type == "geometric":
		var mesh_type = rng.randi_range(0, 3)
		match mesh_type:
			0: # Cube
				var box = BoxMesh.new()
				box.size = Vector3.ONE * rng.randf_range(0.1, 0.25)
				mesh_instance.mesh = box
			1: # Pyramid
				var prism = PrismMesh.new()
				prism.size = Vector3(
					rng.randf_range(0.1, 0.2),
					rng.randf_range(0.1, 0.3),
					rng.randf_range(0.1, 0.2)
				)
				mesh_instance.mesh = prism
			2: # Cylinder
				var cylinder = CylinderMesh.new()
				cylinder.top_radius = rng.randf_range(0.05, 0.1)
				cylinder.bottom_radius = rng.randf_range(0.05, 0.1)
				cylinder.height = rng.randf_range(0.1, 0.3)
				mesh_instance.mesh = cylinder
			3: # Flat plane
				var plane = PlaneMesh.new()
				plane.size = Vector2(
					rng.randf_range(0.1, 0.2),
					rng.randf_range(0.1, 0.2)
				)
				mesh_instance.mesh = plane
	
	elif type == "symbolic":
		var mesh_type = rng.randi_range(0, 1)
		match mesh_type:
			0: # Ring (symbol of union/eternity)
				var torus = TorusMesh.new()
				torus.inner_radius = rng.randf_range(0.05, 0.1)
				torus.outer_radius = rng.randf_range(0.12, 0.2)
				mesh_instance.mesh = torus
			1: # Star-like (multiple points)
				var prism = PrismMesh.new()
				prism.size = Vector3(
					rng.randf_range(0.05, 0.15),
					rng.randf_range(0.15, 0.3),
					rng.randf_range(0.05, 0.15)
				)
				mesh_instance.mesh = prism
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(
		rng.randf_range(0.3, 0.9),
		rng.randf_range(0.3, 0.9),
		rng.randf_range(0.3, 0.9)
	)
	mesh_instance.material_override = material
	
	return mesh_instance

static func add_eyes(plant, rng):
	# Add surreal eye-like features to the plant
	var num_eyes = rng.randi_range(1, 4)
	var eye_parent = Node3D.new()
	eye_parent.name = "Eyes"
	
	# Position on plant
	eye_parent.position = Vector3(
		rng.randf_range(-0.2, 0.2),
		rng.randf_range(0.5, 1.2),
		rng.randf_range(-0.2, 0.2)
	)
	
	for i in range(num_eyes):
		# Create eye
		var eye = Node3D.new()
		eye.name = "Eye_" + str(i)
		
		# Position eyes in a cluster
		eye.position = Vector3(
			rng.randf_range(-0.15, 0.15),
			rng.randf_range(-0.15, 0.15),
			rng.randf_range(-0.15, 0.15)
		)
		
		# Create eyeball
		var eyeball = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = rng.randf_range(0.08, 0.15)
		eyeball.mesh = sphere
		
		# Create eyeball material (white/off-white)
		var eyeball_material = StandardMaterial3D.new()
		eyeball_material.albedo_color = Color(
			rng.randf_range(0.85, 1.0),
			rng.randf_range(0.85, 1.0),
			rng.randf_range(0.85, 1.0)
		)
		eyeball.material_override = eyeball_material
		
		eye.add_child(eyeball)
		
		# Create iris
		var iris = MeshInstance3D.new()
		var iris_mesh = SphereMesh.new()
		iris_mesh.radius = sphere.radius * 0.6
		iris.mesh = iris_mesh
		
		# Position iris slightly forward of eyeball
		iris.position.z = -sphere.radius * 0.6
		
		# Create iris material (colored)
		var iris_material = StandardMaterial3D.new()
		
		# Choose unusual eye colors for surreal effect
		var eye_colors = [
			Color(0.1, 0.5, 0.9), # Blue
			Color(0.1, 0.7, 0.3), # Green
			Color(0.8, 0.6, 0.1), # Amber
			Color(0.7, 0.1, 0.1), # Red
			Color(0.6, 0.1, 0.7)  # Purple
		]
		
		iris_material.albedo_color = eye_colors[rng.randi_range(0, eye_colors.size() - 1)]
		iris.material_override = iris_material
		
		eye.add_child(iris)
		
		# Create pupil
		var pupil = MeshInstance3D.new()
		var pupil_mesh = SphereMesh.new()
		pupil_mesh.radius = iris_mesh.radius * 0.5
		pupil.mesh = pupil_mesh
		
		# Position pupil slightly forward of iris
		pupil.position.z = -sphere.radius * 0.65
		
		# Create pupil material (black)
		var pupil_material = StandardMaterial3D.new()
		pupil_material.albedo_color = Color(0.0, 0.0, 0.0)
		pupil.material_override = pupil_material
		
		eye.add_child(pupil)
		
		eye_parent.add_child(eye)
	
	plant.add_child(eye_parent)

static func add_mouth(plant, rng):
	# Add a surreal mouth-like opening
	var mouth = Node3D.new()
	mouth.name = "Mouth"
	
	# Position on plant
	mouth.position = Vector3(
		rng.randf_range(-0.3, 0.3),
		rng.randf_range(0.3, 1.0),
		rng.randf_range(-0.3, 0.3)
	)
	
	# Create mouth opening (torus for lips)
	var lips = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = rng.randf_range(0.05, 0.1)
	torus.outer_radius = rng.randf_range(0.15, 0.25)
	lips.mesh = torus
	
	# Create material for lips
	var lip_material = StandardMaterial3D.new()
	lip_material.albedo_color = Color(
		rng.randf_range(0.7, 0.9),
		rng.randf_range(0.2, 0.4),
		rng.randf_range(0.2, 0.4)
	)
	lips.material_override = lip_material
	
	mouth.add_child(lips)
	
	plant.add_child(mouth)

static func add_fins(plant, rng):
	# Add fin or wing-like structures
	var num_fins = rng.randi_range(2, 5)
	var fin_parent = Node3D.new()
	fin_parent.name = "Fins"
	
	# Position on plant
	fin_parent.position = Vector3(
		rng.randf_range(-0.2, 0.2),
		rng.randf_range(0.4, 1.0),
		rng.randf_range(-0.2, 0.2)
	)
	
	for i in range(num_fins):
		var fin = MeshInstance3D.new()
		
		# Create fin shape
		var plane = PlaneMesh.new()
		plane.size = Vector2(
			rng.randf_range(0.2, 0.5),
			rng.randf_range(0.3, 0.7)
		)
		fin.mesh = plane
		
		# Position fins in a radial pattern
		var angle = float(i) / float(num_fins) * TAU
		fin.rotation = Vector3(
			rng.randf_range(-0.5, 0.5),
			angle,
			rng.randf_range(-0.5, 0.5)
		)
		
		# Create fin material (translucent, colorful)
		var fin_material = StandardMaterial3D.new()
		fin_material.albedo_color = Color(
			rng.randf_range(0.4, 0.9),
			rng.randf_range(0.4, 0.9),
			rng.randf_range(0.4, 0.9),
			rng.randf_range(0.3, 0.7) # Alpha
		)
		fin_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		fin_material.cull_mode = BaseMaterial3D.CULL_DISABLED # Double-sided
		
		fin.material_override = fin_material
		fin_parent.add_child(fin)
	
	plant.add_child(fin_parent)

static func add_eggs(plant, rng):
	# Add egg or pod-like structures
	var num_eggs = rng.randi_range(3, 7)
	var egg_parent = Node3D.new()
	egg_parent.name = "Eggs"
	
	# Position on plant
	egg_parent.position = Vector3(
		rng.randf_range(-0.3, 0.3),
		rng.randf_range(0.2, 0.8),
		rng.randf_range(-0.3, 0.3)
	)
	
	for i in range(num_eggs):
		var egg = MeshInstance3D.new()
		
		# Create egg shape
		var sphere = SphereMesh.new()
		sphere.radius = rng.randf_range(0.05, 0.12)
		egg.mesh = sphere
		
		# Position eggs in a cluster
		egg.position = Vector3(
			rng.randf_range(-0.2, 0.2),
			rng.randf_range(-0.1, 0.1),
			rng.randf_range(-0.2, 0.2)
		)
		
		# Create material for egg
		var egg_material = StandardMaterial3D.new()
		egg_material.albedo_color = Color(
			rng.randf_range(0.6, 0.9),
			rng.randf_range(0.6, 0.9),
			rng.randf_range(0.6, 0.9)
		)
		
		egg.material_override = egg_material
		egg_parent.add_child(egg)
	
	plant.add_child(egg_parent)

static func create_architectural_element(parent, rng):
	# Create a small surreal architectural element
	var architecture = Node3D.new()
	
	# Create base
	var base = MeshInstance3D.new()
	var base_mesh = CylinderMesh.new()
	base_mesh.top_radius = rng.randf_range(0.15, 0.25)
	base_mesh.bottom_radius = rng.randf_range(0.2, 0.3)
	base_mesh.height = rng.randf_range(0.3, 0.5)
	base.mesh = base_mesh
	
	# Create material
	var base_material = StandardMaterial3D.new()
	base_material.albedo_color = Color(
		rng.randf_range(0.5, 0.7),
		rng.randf_range(0.5, 0.7),
		rng.randf_range(0.5, 0.7)
	)
	base.material_override = base_material
	
	architecture.add_child(base)
	
	parent.add_child(architecture)

static func create_musical_instrument(parent, rng):
	# Create a surreal musical instrument
	var instrument = Node3D.new()
	
	# Create base tube
	var tube = MeshInstance3D.new()
	var tube_mesh = CylinderMesh.new()
	tube_mesh.top_radius = rng.randf_range(0.03, 0.06)
	tube_mesh.bottom_radius = rng.randf_range(0.08, 0.15)
	tube_mesh.height = rng.randf_range(0.4, 0.7)
	tube.mesh = tube_mesh
	
	# Material for the tube (metallic)
	var tube_material = StandardMaterial3D.new()
	tube_material.albedo_color = Color(
		rng.randf_range(0.7, 0.9),
		rng.randf_range(0.6, 0.8),
		rng.randf_range(0.3, 0.5)
	)
	tube_material.metallic = rng.randf_range(0.7, 1.0)
	tube.material_override = tube_material
	
	instrument.add_child(tube)
	
	parent.add_child(instrument)

static func create_animated_fruit(parent, rng):
	# Create a fruit or food with face (common in Bosch)
	var fruit = Node3D.new()
	
	# Create fruit body
	var body = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = rng.randf_range(0.15, 0.25)
	body.mesh = sphere
	
	# Create material for fruit
	var fruit_material = StandardMaterial3D.new()
	fruit_material.albedo_color = Color(
		rng.randf_range(0.7, 1.0),
		rng.randf_range(0.3, 0.8),
		rng.randf_range(0.3, 0.8)
	)
	body.material_override = fruit_material
	
	fruit.add_child(body)
	
	# Add face features (simple eye and mouth)
	var eye = MeshInstance3D.new()
	var eye_mesh = SphereMesh.new()
	eye_mesh.radius = sphere.radius * 0.15
	eye.mesh = eye_mesh
	eye.position = Vector3(0, sphere.radius * 0.3, -sphere.radius * 0.8)
	
	var eye_material = StandardMaterial3D.new()
	eye_material.albedo_color = Color(0.1, 0.1, 0.1)
	eye.material_override = eye_material
	
	fruit.add_child(eye)
	
	parent.add_child(fruit)
