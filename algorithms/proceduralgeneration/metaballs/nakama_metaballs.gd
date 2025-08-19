# Metaball System for Godot 4
# This implementation creates a Kouhei Nakama-inspired organic surface using metaballs

extends Node3D

# Configuration
@export var num_metaballs = 60
@export var container_size = Vector3(5.0, 5.0, 5.0)
@export var surface_threshold = 1.0
@export var base_radius = 0.4
@export var radius_variation = 0.3
@export var movement_speed = 0.5
@export var material_color: Color = Color(0.95, 0.85, 0.85)

# Metaball properties
var metaballs = []
var time = 0.0

# Node references
var mesh_instance: MeshInstance3D
var noise: FastNoiseLite

func _ready():
	# Initialize noise for organic movement
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.5
	
	# Create metaballs
	create_metaballs()
	
	# Create the mesh instance
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	# Create shader material
	var material = create_shader_material()
	mesh_instance.material_override = material
	
	# Set up lighting
	setup_lighting()

func create_metaballs():
	# Create the metaballs with random positions and radii
	for i in range(num_metaballs):
		# Create a pattern similar to the reference image
		# Concentrate balls in a circular pattern
		var distance_from_center = randf_range(1.0, 3.0)
		var angle = randf_range(0, TAU)
		var position = Vector3(
			cos(angle) * distance_from_center,
			sin(angle) * distance_from_center,
			randf_range(-0.5, 0.5)
		)
		
		var metaball = {
			"position": position,
			"radius": base_radius + randf_range(-radius_variation, radius_variation),
			"velocity": Vector3(
				randf_range(-1.0, 1.0),
				randf_range(-1.0, 1.0),
				randf_range(-1.0, 1.0)
			).normalized() * movement_speed
		}
		
		metaballs.append(metaball)

func create_shader_material():
	# Create a shader material for the metaball surface
	var material = ShaderMaterial.new()
	
	# Create the shader
	var shader = Shader.new()
	shader.code = """
	shader_type spatial;
	
	// Surface properties
	uniform vec4 albedo : source_color = vec4(0.95, 0.85, 0.85, 1.0);
	uniform float roughness : hint_range(0.0, 1.0) = 0.2;
	uniform float metallic : hint_range(0.0, 1.0) = 0.1;
	uniform float specular : hint_range(0.0, 1.0) = 0.6;
	
	// Subsurface scattering
	uniform float subsurface_scatter : hint_range(0.0, 1.0) = 0.3;
	uniform vec4 subsurface_color : source_color = vec4(0.95, 0.75, 0.75, 1.0);
	
	// Detail noise
	uniform sampler2D noise_texture;
	uniform float noise_scale = 10.0;
	uniform float noise_strength = 0.05;
	
	// Displacement
	uniform float displacement_amount = 0.03;
	uniform float time = 0.0;
	
	varying vec3 vertex_normal;
	varying vec3 vertex_tangent;
	varying vec3 vertex_binormal;
	
	void vertex() {
		// Store normals for fragment shader
		vertex_normal = NORMAL;
		vertex_tangent = TANGENT;
		vertex_binormal = BINORMAL;
		
		// Add subtle displacement along normal for surface details
		float noise_value = texture(noise_texture, UV * noise_scale + vec2(time * 0.05)).r;
		VERTEX += NORMAL * noise_value * displacement_amount;
	}
	
	void fragment() {
		// Base surface properties
		ALBEDO = albedo.rgb;
		ROUGHNESS = roughness;
		METALLIC = metallic;
		SPECULAR = specular;
		
		// Normal mapping for micro details
		vec3 normal_map = vec3(0.0);
		
		// Sample noise for normal perturbation
		vec2 uv_offset = UV * noise_scale + vec2(time * 0.05);
		float noise_x = texture(noise_texture, uv_offset + vec2(0.01, 0.0)).r - 
					   texture(noise_texture, uv_offset - vec2(0.01, 0.0)).r;
		float noise_y = texture(noise_texture, uv_offset + vec2(0.0, 0.01)).r - 
					   texture(noise_texture, uv_offset - vec2(0.0, 0.01)).r;
					   
		normal_map = vec3(noise_x, noise_y, 1.0) * 2.0 - 1.0;
		normal_map = normalize(normal_map);
		
		// Transform normal map from tangent to world space
		mat3 tbn = mat3(vertex_tangent, vertex_binormal, vertex_normal);
		NORMAL = normalize(tbn * normal_map);
		
		// Subsurface scattering
		SUBSURFACE_SCATTERING_STRENGTH = subsurface_scatter;
		SUBSURFACE_SCATTERING_COLOR = subsurface_color.rgb;
	}
	"""
	material.shader = shader
	
	# Set shader parameters
	material.set_shader_parameter("albedo", material_color)
	material.set_shader_parameter("roughness", 0.2)
	material.set_shader_parameter("metallic", 0.1)
	material.set_shader_parameter("specular", 0.6)
	material.set_shader_parameter("subsurface_scatter", 0.3)
	material.set_shader_parameter("subsurface_color", Color(0.95, 0.75, 0.75))
	material.set_shader_parameter("displacement_amount", 0.03)
	
	# Create noise texture for the details
	var noise_texture = NoiseTexture2D.new()
	noise_texture.noise = FastNoiseLite.new()
	noise_texture.noise.frequency = 0.8
	noise_texture.noise.fractal_octaves = 4
	noise_texture.width = 512
	noise_texture.height = 512
	material.set_shader_parameter("noise_texture", noise_texture)
	material.set_shader_parameter("noise_scale", 10.0)
	material.set_shader_parameter("noise_strength", 0.05)
	material.set_shader_parameter("time", 0.0)
	
	return material

func _process(delta):
	time += delta
	
	# Update metaball positions
	update_metaballs(delta)
	
	# Generate the mesh
	generate_mesh()
	
	# Update shader time parameter
	if mesh_instance.material_override is ShaderMaterial:
		mesh_instance.material_override.set_shader_parameter("time", time)

func update_metaballs(delta):
	# Move metaballs in organic patterns, but skip every other frame for performance
	if Engine.get_frames_drawn() % 2 == 0:
		return
		
	# Only update a portion of metaballs each frame
	var update_count = min(30, metaballs.size())
	var start_idx = int(fmod(time * 5, metaballs.size()))
	
	for i in range(update_count):
		var idx = (start_idx + i) % metaballs.size()
		var mb = metaballs[idx]
		
		# Use noise to create organic movement - simplified for performance
		var noise_offset = time * 0.1 + idx * 0.05
		
		# Only calculate one noise value per frame and distribute it
		var noise_value = noise.get_noise_3d(noise_offset, 0, idx * 0.1) * delta
		mb.position.x += noise_value
		mb.position.y += noise_value * 0.8
		mb.position.z += noise_value * 0.6
		
		# Keep within bounds with a soft boundary - vectorized for better performance
		mb.position = mb.position.clamp(
			Vector3(-container_size.x/2, -container_size.y/2, -container_size.z/2),
			Vector3(container_size.x/2, container_size.y/2, container_size.z/2)
		)
		
		# Apply a mild attraction to the center to maintain the circular pattern
		var center_dir = -mb.position.normalized()
		mb.position += center_dir * delta * 0.1
		
		# Optimize the sin calculation - only update radius every few frames
		if i % 3 == 0:  
			mb.radius = base_radius + sin(time * 0.5 + idx * 0.2) * radius_variation * 0.5

func generate_mesh():
	# Generate a mesh based on metaballs using the marching cubes algorithm
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Create a simplified proxy mesh for the metaballs
	create_metaball_proxy_mesh(st)
	
	st.generate_normals()
	st.generate_tangents()
	
	# Assign the mesh
	mesh_instance.mesh = st.commit()

func create_metaball_proxy_mesh(st):
	# Create a surface that approximates what metaballs would look like
	# This is a workaround to avoid implementing full marching cubes
	
	# Create a sphere that will be our base shape
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 3.0
	sphere_mesh.height = 6.0
	sphere_mesh.radial_segments = 64
	sphere_mesh.rings = 32
	
	# Create an array mesh from the sphere
	var array_mesh = ArrayMesh.new()
	var temp_st = SurfaceTool.new()
	temp_st.create_from(sphere_mesh, 0)
	temp_st.commit(array_mesh)
	
	# Create a mesh data tool to modify the sphere mesh
	var mdt = MeshDataTool.new()
	var err = mdt.create_from_surface(array_mesh, 0)
	if err != OK:
		print("Failed to create MeshDataTool: ", err)
		# Fallback to a simple sphere if we can't modify the mesh
		st.create_from(sphere_mesh, 0)
		return
	
	# Modify each vertex based on metaball field
	for i in range(mdt.get_vertex_count()):
		var vertex = mdt.get_vertex(i)
		
		# Calculate metaball field influence at this point
		var field_value = calculate_metaball_field(vertex)
		
		# Get normal for this vertex
		var normal = mdt.get_vertex_normal(i)
		
		# Offset the vertex based on the field and add some noise
		# for organic detail
		vertex += normal * (field_value - surface_threshold) * 0.2
		vertex += normal * noise.get_noise_3d(
			vertex.x * 2.0, 
			vertex.y * 2.0, 
			vertex.z * 2.0
		) * 0.1
		
		# Set the modified vertex
		mdt.set_vertex(i, vertex)
	
	# Create a new mesh from our modified data
	var output_mesh = ArrayMesh.new()
	mdt.commit_to_surface(output_mesh)
	
	# Add the output mesh to our surface tool
	st.append_from(output_mesh, 0, Transform3D.IDENTITY)

func calculate_metaball_field(point):
	# Calculate the metaball field value at a given point
	var field_value = 0.0
	
	for mb in metaballs:
		var distance = point.distance_to(mb.position)
		
		# Metaball field function (inverse square)
		if distance < mb.radius * 3.0:
			field_value += pow(mb.radius / max(distance, 0.001), 2)
	
	return field_value

func setup_lighting():
	# Set up lighting to highlight the organic forms
	
	# Main directional light
	var dir_light = DirectionalLight3D.new()
	dir_light.position = Vector3(5, 5, 5)
	dir_light.light_color = Color(1.0, 0.95, 0.9)
	dir_light.shadow_enabled = true
	add_child(dir_light)
	dir_light.look_at(Vector3.ZERO, Vector3.UP)
	
	# Fill light
	var fill_light = DirectionalLight3D.new()
	fill_light.position = Vector3(-5, -2, 3)
	fill_light.light_color = Color(0.9, 0.8, 0.85)
	fill_light.light_energy = 0.5
	add_child(fill_light)
	fill_light.look_at(Vector3.ZERO, Vector3.UP)
	
	# Rim light for the organic highlights
	var rim_light = OmniLight3D.new()
	rim_light.position = Vector3(0, 0, -5)
	rim_light.light_color = Color(1.0, 0.9, 0.9)
	rim_light.light_energy = 0.8
	rim_light.omni_range = 10
	add_child(rim_light)
	
	# Set up environment
	var environment = WorldEnvironment.new()
	var env = Environment.new()
	
	# Sky settings
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.9, 0.8, 0.8)
	
	# Ambient light
	env.ambient_light_color = Color(0.9, 0.8, 0.8)
	env.ambient_light_energy = 0.2
	
	# Fog for depth
	env.fog_enabled = true
	env.fog_density = 0.01
	
	# Post-processing effects
	env.ssao_enabled = true
	env.ssao_radius = 0.5
	env.ssao_intensity = 2.0
	env.glow_enabled = true
	
	environment.environment = env
	add_child(environment)
