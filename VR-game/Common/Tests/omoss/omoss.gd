extends Node3D

# Liquid Fabric Composition inspired by Albert Omoss style
# A 3D composition mixing glossy liquid surfaces with fabric-like materials

# Materials
var materials = {
	"glossy_purple": null,
	"glossy_red": null,
	"glossy_clear": null,
	"fabric_pink": null,
	"fabric_yellow": null,
	"fabric_purple": null,
	"granular_orange": null,
	"bubble_material": null
}

# Shape generators
var noise = FastNoiseLite.new()
var rng = RandomNumberGenerator.new()

func _ready():
	# Set up scene
	setup_environment()
	create_materials()
	create_composition()


func setup_environment():
	# Create environment with soft pink background
	var environment = WorldEnvironment.new()
	var env = Environment.new()
	
	# Pink background
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.98, 0.78, 0.85)
	
	# Ambient light
	env.ambient_light_color = Color(0.9, 0.8, 0.9)
	env.ambient_light_energy = 0.8
	
	# SSAO for depth
	env.ssao_enabled = true
	env.ssao_radius = 1.0
	env.ssao_intensity = 1.0
	
	# SSR for reflections
	env.ssr_enabled = true
	env.ssr_max_steps = 64
	env.ssr_fade_in = 0.15
	env.ssr_fade_out = 2.0
	env.ssr_depth_tolerance = 0.2
	
	# Enable glow
	env.glow_enabled = true
	env.glow_intensity = 0.3
	env.glow_bloom = 0.1
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	
	# Apply environment
	environment.environment = env
	add_child(environment)
	
	# Add lighting
	setup_lighting()

func setup_lighting():
	# Create soft key light
	var key_light = DirectionalLight3D.new()
	key_light.light_color = Color(1.0, 0.98, 0.95)
	key_light.light_energy = 2.0
	key_light.shadow_enabled = true
	key_light.rotation_degrees = Vector3(-45, 30, 0)
	add_child(key_light)
	
	# Create rim light
	var rim_light = DirectionalLight3D.new()
	rim_light.light_color = Color(0.9, 0.8, 1.0)
	rim_light.light_energy = 1.0
	rim_light.shadow_enabled = false
	rim_light.rotation_degrees = Vector3(-20, -140, 0)
	add_child(rim_light)
	
	# Create fill light
	var fill_light = OmniLight3D.new()
	fill_light.light_color = Color(0.95, 0.85, 0.9)
	fill_light.light_energy = 1.5
	fill_light.shadow_enabled = true
	fill_light.position = Vector3(-2, 0, 3)
	fill_light.omni_range = 8.0
	add_child(fill_light)

func create_materials():
	# Initialize noise for materials
	noise.seed = randi()
	noise.fractal_octaves = 4
	noise.frequency = 0.1
	
	# Glossy purple material (main dripping surface)
	materials.glossy_purple = StandardMaterial3D.new()
	materials.glossy_purple.albedo_color = Color(0.85, 0.45, 0.95)
	materials.glossy_purple.metallic = 0.2
	materials.glossy_purple.roughness = 0.1
	materials.glossy_purple.clearcoat_enabled = true
	materials.glossy_purple.clearcoat = 1.0
	materials.glossy_purple.clearcoat_roughness = 0.05
	
	# Glossy red material
	materials.glossy_red = StandardMaterial3D.new()
	materials.glossy_red.albedo_color = Color(0.95, 0.2, 0.3)
	materials.glossy_red.metallic = 0.2
	materials.glossy_red.roughness = 0.15
	materials.glossy_red.clearcoat_enabled = true
	materials.glossy_red.clearcoat = 1.0
	materials.glossy_red.clearcoat_roughness = 0.05
	
	# Clear glossy material for drips
	materials.glossy_clear = StandardMaterial3D.new()
	materials.glossy_clear.albedo_color = Color(0.9, 0.9, 0.95, 0.6)
	materials.glossy_clear.metallic = 0.3
	materials.glossy_clear.roughness = 0.05
	materials.glossy_clear.refraction_enabled = true
	materials.glossy_clear.refraction_scale = 0.05
	materials.glossy_clear.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	# Pink fabric material
	materials.fabric_pink = StandardMaterial3D.new()
	materials.fabric_pink.albedo_color = Color(0.95, 0.6, 0.75)
	materials.fabric_pink.roughness = 0.9
	materials.fabric_pink.metallic = 0.0
	
	# Add fabric normal map
	var pink_normal = NoiseTexture2D.new()
	pink_normal.noise = noise
	pink_normal.as_normal_map = true
	pink_normal.bump_strength = 2.0
	materials.fabric_pink.normal_enabled = true
	materials.fabric_pink.normal_texture = pink_normal
	
	# Yellow fabric material
	materials.fabric_yellow = StandardMaterial3D.new()
	materials.fabric_yellow.albedo_color = Color(0.95, 0.8, 0.2)
	materials.fabric_yellow.roughness = 0.85
	materials.fabric_yellow.metallic = 0.0
	
	# Add fabric normal map
	var yellow_normal = NoiseTexture2D.new()
	yellow_normal.noise = noise
	yellow_normal.as_normal_map = true
	yellow_normal.bump_strength = 2.0
	materials.fabric_yellow.normal_enabled = true
	materials.fabric_yellow.normal_texture = yellow_normal
	
	# Purple fabric material
	materials.fabric_purple = StandardMaterial3D.new()
	materials.fabric_purple.albedo_color = Color(0.75, 0.5, 0.95)
	materials.fabric_purple.roughness = 0.8
	materials.fabric_purple.metallic = 0.0
	
	# Add fabric normal map
	var purple_normal = NoiseTexture2D.new()
	purple_normal.noise = noise
	purple_normal.as_normal_map = true
	purple_normal.bump_strength = 2.5
	materials.fabric_purple.normal_enabled = true
	materials.fabric_purple.normal_texture = purple_normal
	
	# Granular orange material (for the bumpy sphere)
	materials.granular_orange = StandardMaterial3D.new()
	materials.granular_orange.albedo_color = Color(0.95, 0.6, 0.2)
	materials.granular_orange.roughness = 0.7
	materials.granular_orange.metallic = 0.2
	
	# Add granular normal map
	var granular_normal = NoiseTexture2D.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	noise.cellular_jitter = 1.0
	noise.frequency = 10.0
	granular_normal.noise = noise
	granular_normal.as_normal_map = true
	granular_normal.bump_strength = 5.0
	materials.granular_orange.normal_enabled = true
	materials.granular_orange.normal_texture = granular_normal
	
	# Bubble material (for small transparent elements)
	materials.bubble_material = StandardMaterial3D.new()
	materials.bubble_material.albedo_color = Color(0.85, 0.95, 0.85, 0.7)
	materials.bubble_material.metallic = 0.2
	materials.bubble_material.roughness = 0.0
	materials.bubble_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	materials.bubble_material.refraction_enabled = true
	materials.bubble_material.refraction_scale = 0.05

func create_composition():
	# Root node for the composition
	var composition = Node3D.new()
	composition.name = "LiquidComposition"
	add_child(composition)
	
	# Create base - fluid-like purple mass
	var base = create_fluid_mass(materials.glossy_purple, Vector3(0, 0, 0), Vector3(2.0, 0.8, 2.0))
	composition.add_child(base)
	
	# Add fabric layers
	create_fabric_layer(composition, materials.fabric_pink, Vector3(0, 0.4, 0), 0.8, 0.2)
	create_fabric_layer(composition, materials.fabric_yellow, Vector3(0, 0.75, 0), 1.0, 0.15)
	create_fabric_layer(composition, materials.fabric_purple, Vector3(0, 1.0, 0), 0.7, 0.2)
	
	# Add red glossy blob
	var red_blob = create_fluid_mass(materials.glossy_red, Vector3(0.5, 1.2, -0.3), Vector3(0.7, 0.5, 0.7))
	composition.add_child(red_blob)
	
	# Add textured orange sphere at top
	var orange_sphere = create_textured_sphere(materials.granular_orange, Vector3(-0.3, 1.8, 0.2), 0.5)
	composition.add_child(orange_sphere)
	
	# Add clear drips
	create_drip_elements(composition, 15)
	
	# Add green bubble extensions (similar to the green tentacle-like elements)
	create_bubble_extensions(composition, Vector3(-0.3, 2.0, 0.2), 8)

func create_fluid_mass(material, position, scale_vec):
	var fluid = Node3D.new()
	fluid.position = position
	
	# Create base mesh
	var base_mesh = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 1.0
	sphere_mesh.height = 2.0
	base_mesh.mesh = sphere_mesh
	base_mesh.scale = scale_vec
	base_mesh.material_override = material
	
	# Add some deformations to make it look more fluid-like
	var deform_count = randi() % 5 + 5
	for i in range(deform_count):
		var deform = MeshInstance3D.new()
		var deform_mesh = SphereMesh.new()
		deform_mesh.radius = randf_range(0.3, 0.7)
		deform_mesh.height = deform_mesh.radius * 2
		deform.mesh = deform_mesh
		
		# Random position on the surface
		var angle = randf_range(0, TAU)
		var elevation = randf_range(-1.0, 1.0)
		var radius = randf_range(0.7, 1.1)
		deform.position = Vector3(
			cos(angle) * radius * scale_vec.x,
			elevation * scale_vec.y,
			sin(angle) * radius * scale_vec.z
		)
		
		deform.material_override = material
		fluid.add_child(deform)
	
	return fluid

func create_fabric_layer(parent, material, position, radius, height):
	var fabric = Node3D.new()
	fabric.position = position
	
	# Create base cloth-like shape using many small quads with noise-based displacement
	var segments = 12
	var cloth_shape = ImmediateMesh.new()
	var cloth_instance = MeshInstance3D.new()
	cloth_instance.mesh = cloth_shape
	
	# Reset noise for fabric
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 2.0
	
	# Generate fabric mesh
	cloth_shape.clear_surfaces()
	cloth_shape.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	
	for i in range(segments):
		var angle1 = TAU * i / segments
		var angle2 = TAU * (i + 1) / segments
		
		for j in range(segments):
			var radius1 = radius * (1.0 - 0.2 * sin(j * 0.5))
			var radius2 = radius * (1.0 - 0.2 * sin((j + 1) * 0.5))
			
			var height_factor1 = j / float(segments)
			var height_factor2 = (j + 1) / float(segments)
			
			var y1 = -height * height_factor1
			var y2 = -height * height_factor2
			
			# Add noise for more organic cloth-like shape
			var noise_val1 = noise.get_noise_2d(cos(angle1) * 10, sin(angle1) * 10) * 0.2
			var noise_val2 = noise.get_noise_2d(cos(angle2) * 10, sin(angle2) * 10) * 0.2
			
			var v1 = Vector3(cos(angle1) * radius1, y1 + noise_val1, sin(angle1) * radius1)
			var v2 = Vector3(cos(angle2) * radius1, y1 + noise_val2, sin(angle2) * radius1)
			var v3 = Vector3(cos(angle2) * radius2, y2 + noise_val2, sin(angle2) * radius2)
			var v4 = Vector3(cos(angle1) * radius2, y2 + noise_val1, sin(angle1) * radius2)
			
			# Calculate normal for proper lighting
			var normal1 = (v2 - v1).cross(v3 - v1).normalized()
			var normal2 = (v3 - v1).cross(v4 - v1).normalized()
			
			# Create quad (two triangles)
			# Triangle 1
			cloth_shape.surface_set_normal(normal1)
			cloth_shape.surface_set_uv(Vector2(i / float(segments), j / float(segments)))
			cloth_shape.surface_add_vertex(v1)
			
			cloth_shape.surface_set_normal(normal1)
			cloth_shape.surface_set_uv(Vector2((i + 1) / float(segments), j / float(segments)))
			cloth_shape.surface_add_vertex(v2)
			
			cloth_shape.surface_set_normal(normal1)
			cloth_shape.surface_set_uv(Vector2((i + 1) / float(segments), (j + 1) / float(segments)))
			cloth_shape.surface_add_vertex(v3)
			
			# Triangle 2
			cloth_shape.surface_set_normal(normal2)
			cloth_shape.surface_set_uv(Vector2(i / float(segments), j / float(segments)))
			cloth_shape.surface_add_vertex(v1)
			
			cloth_shape.surface_set_normal(normal2)
			cloth_shape.surface_set_uv(Vector2((i + 1) / float(segments), (j + 1) / float(segments)))
			cloth_shape.surface_add_vertex(v3)
			
			cloth_shape.surface_set_normal(normal2)
			cloth_shape.surface_set_uv(Vector2(i / float(segments), (j + 1) / float(segments)))
			cloth_shape.surface_add_vertex(v4)
	
	cloth_shape.surface_end()
	
	fabric.add_child(cloth_instance)
	parent.add_child(fabric)

func create_textured_sphere(material, position, radius):
	var sphere_node = Node3D.new()
	sphere_node.position = position
	
	# Base sphere
	var sphere = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2.0
	sphere_mesh.radial_segments = 32
	sphere_mesh.rings = 24
	sphere.mesh = sphere_mesh
	sphere.material_override = material
	
	# Add bumps to the sphere
	var bump_count = 40
	for i in range(bump_count):
		var bump = MeshInstance3D.new()
		var bump_mesh = SphereMesh.new()
		var bump_size = randf_range(0.05, 0.15) * radius
		bump_mesh.radius = bump_size
		bump_mesh.height = bump_size * 2.0
		bump.mesh = bump_mesh
		
		# Position on sphere surface
		var angle1 = randf_range(0, TAU)
		var angle2 = randf_range(0, PI)
		var pos = Vector3(
			sin(angle2) * cos(angle1),
			sin(angle2) * sin(angle1),
			cos(angle2)
		) * radius
		
		bump.position = pos
		bump.material_override = material
		sphere_node.add_child(bump)
	
	sphere_node.add_child(sphere)
	return sphere_node

func create_drip_elements(parent, count):
	for i in range(count):
		var drip = MeshInstance3D.new()
		
		# Create different drip shapes
		var drip_type = randi() % 3
		
		match drip_type:
			0:  # Droplet
				var droplet_mesh = SphereMesh.new()
				droplet_mesh.radius = randf_range(0.05, 0.15)
				droplet_mesh.height = droplet_mesh.radius * 2.0
				drip.mesh = droplet_mesh
			1:  # Elongated drip
				var drip_mesh = CapsuleMesh.new()
				drip_mesh.radius = randf_range(0.03, 0.08)
				drip_mesh.height = randf_range(0.2, 0.5)
				drip.mesh = drip_mesh
			2:  # Small puddle
				var puddle_mesh = SphereMesh.new()
				puddle_mesh.radius = randf_range(0.1, 0.2)
				puddle_mesh.height = puddle_mesh.radius * 0.5  # Flattened
				drip.mesh = puddle_mesh
				drip.rotation_degrees.x = 90  # Lie flat
		
		# Random position around the composition
		var angle = randf_range(0, TAU)
		var radius = randf_range(0.5, 1.5)
		var height = randf_range(0.0, 1.5)
		
		drip.position = Vector3(
			cos(angle) * radius,
			height,
			sin(angle) * radius
		)
		
		drip.material_override = materials.glossy_clear
		parent.add_child(drip)

func create_bubble_extensions(parent, origin_position, count):
	for i in range(count):
		var extension = Node3D.new()
		var extension_length = randf_range(0.3, 0.8)
		var segment_count = 5
		
		# Direction from origin with randomness
		var angle_horizontal = randf_range(0, TAU)
		var angle_vertical = randf_range(-PI/3, PI/3)
		
		var direction = Vector3(
			cos(angle_horizontal) * cos(angle_vertical),
			sin(angle_vertical),
			sin(angle_horizontal) * cos(angle_vertical)
		).normalized()
		
		# Create segments
		var prev_pos = origin_position
		for j in range(segment_count):
			var segment = MeshInstance3D.new()
			var segment_size = randf_range(0.05, 0.1) * (1.0 - j / float(segment_count))
			
			var segment_mesh = SphereMesh.new()
			segment_mesh.radius = segment_size
			segment_mesh.height = segment_size * 2
			segment.mesh = segment_mesh
			
			# Add some noise to the direction
			var noise_factor = 0.3
			var noise_direction = Vector3(
				randf_range(-noise_factor, noise_factor),
				randf_range(-noise_factor, noise_factor),
				randf_range(-noise_factor, noise_factor)
			)
			
			direction = (direction + noise_direction * 0.2).normalized()
			
			# Calculate position
			var segment_distance = extension_length / segment_count
			var pos = prev_pos + direction * segment_distance
			segment.position = pos
			prev_pos = pos
			
			segment.material_override = materials.bubble_material
			extension.add_child(segment)
		
		parent.add_child(extension)



# Optional: add subtle animation
func _process(delta):
	var composition = get_node("LiquidComposition")
	if composition:
		# Add very subtle movement
		composition.rotate_y(delta * 0.05)
