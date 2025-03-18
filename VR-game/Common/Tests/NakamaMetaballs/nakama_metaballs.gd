# Metaball System for Godot 4
# This implementation creates a Kouhei Nakama-inspired organic surface using metaballs

extends Node3D

# Configuration
@export var num_metaballs = 200
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
var marching_cubes_node: Node
var marching_cubes_engine = null

func _ready():
	# Initialize noise for organic movement
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.5
	
	# Initialize marching cubes algorithm
	initialize_marching_cubes()
	
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

func initialize_marching_cubes():
	# Create a node to hold references
	marching_cubes_node = Node.new()
	marching_cubes_node.name = "MarchingCubes"
	add_child(marching_cubes_node)
	
	# Initialize the marching cubes implementation
	marching_cubes_engine = MarchingCubesImplementation.new()

func create_metaballs():
	# Create the metaballs with random positions and radii
	for i in range(num_metaballs):
		var metaball = {
			"position": Vector3(
				randf_range(-container_size.x/2, container_size.x/2),
				randf_range(-container_size.y/2, container_size.y/2),
				randf_range(-container_size.z/2, container_size.z/2)
			),
			"radius": base_radius + randf_range(-radius_variation, radius_variation),
			"velocity": Vector3(
				randf_range(-1.0, 1.0),
				randf_range(-1.0, 1.0),
				randf_range(-1.0, 1.0)
			).normalized() * movement_speed
		}
		
		# Create a pattern similar to the reference image
		# Concentrate balls in a circular pattern
		var distance_from_center = randf_range(1.0, 3.0)
		var angle = randf_range(0, TAU)
		metaball.position = Vector3(
			cos(angle) * distance_from_center,
			sin(angle) * distance_from_center,
			randf_range(-0.5, 0.5)
		)
		
		metaballs.append(metaball)

func create_standard_material():
	# Create a standard material for the metaball surface
	var material = StandardMaterial3D.new()
	
	# Set material properties to match the reference image
	material.albedo_color = material_color
	material.roughness = 0.2
	material.metallic = 0.1
	material.metallic_specular = 0.6
	material.subsurf_scatter_enabled = true
	material.subsurf_scatter_strength = 0.3
	material.subsurf_scatter_skin_mode = true
	
	return material

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
		SSS_STRENGTH = subsurface_scatter;
		SSS_TRANSMITTANCE_COLOR = subsurface_color.rgb;
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
	# Move metaballs in organic patterns
	for i in range(metaballs.size()):
		var mb = metaballs[i]
		
		# Use noise to create organic movement
		var noise_offset = time * 0.1 + i * 0.05
		mb.position.x += noise.get_noise_3d(noise_offset, 0, i * 0.1) * delta
		mb.position.y += noise.get_noise_3d(0, noise_offset, i * 0.1) * delta
		mb.position.z += noise.get_noise_3d(i * 0.1, noise_offset, 0) * delta
		
		# Keep within bounds with a soft boundary
		mb.position.x = clamp(mb.position.x, -container_size.x/2, container_size.x/2)
		mb.position.y = clamp(mb.position.y, -container_size.y/2, container_size.y/2)
		mb.position.z = clamp(mb.position.z, -container_size.z/2, container_size.z/2)
		
		# Apply a mild attraction to the center to maintain the circular pattern
		var center_dir = -mb.position.normalized()
		mb.position += center_dir * delta * 0.1
		
		# Pulse the radius slightly for added organic feel
		mb.radius = base_radius + sin(time * 0.5 + i * 0.2) * radius_variation * 0.5

func generate_mesh():
	# Calculate the density field for marching cubes
	# This is a simplified representation - in a real implementation,
	# you would use a proper marching cubes algorithm
	
	# For this example, we'll create a custom surface tool and build a mesh
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Build the mesh using metaball field
	build_metaball_mesh(st)
	
	st.generate_normals()
	st.generate_tangents()
	
	# Assign the mesh
	mesh_instance.mesh = st.commit()

func build_metaball_mesh(st):
	# In a real implementation, this would use marching cubes to generate
	# the isosurface of the metaball field.
	#
	# For this simplified example, we'll create a proxy mesh that
	# represents what the metaball surface might look like
	
	# Create a base sphere mesh
	var base_mesh = SphereMesh.new()
	base_mesh.radius = 3.0
	base_mesh.height = 6.0
	base_mesh.radial_segments = 64
	base_mesh.rings = 32
	
	# Convert the primitive mesh to an ArrayMesh first
	var temp_mesh_instance = MeshInstance3D.new()
	temp_mesh_instance.mesh = base_mesh
	var array_mesh = temp_mesh_instance.mesh.duplicate()
	
	# Now create the data tool
	var mdt = MeshDataTool.new()
	var err = mdt.create_from_surface(array_mesh, 0)
	if err != OK:
		print("Failed to create MeshDataTool: ", err)
		return
	
	# Modify each vertex based on metaball field
	for i in range(mdt.get_vertex_count()):
		var vertex = mdt.get_vertex(i)
		
		# Calculate metaball field influence at this point
		var field_value = calculate_metaball_field(vertex)
		
		# Offset the vertex based on the field
		var normal = mdt.get_vertex_normal(i)
		vertex += normal * (field_value - surface_threshold) * 0.2
		
		# Apply some noise for the detailed texture
		vertex += normal * noise.get_noise_3d(vertex.x * 2.0, vertex.y * 2.0, vertex.z * 2.0) * 0.1
		
		# Set the vertex position
		mdt.set_vertex(i, vertex)
	
	# Create a new ArrayMesh for the output
	var output_mesh = ArrayMesh.new()
	
	# Commit the changes to the output mesh
	err = mdt.commit_to_surface(output_mesh)
	if err != OK:
		print("Failed to commit MeshDataTool changes: ", err)
		# Fallback to the original mesh if there's an error
		mesh_instance.mesh = array_mesh
		return
	
	# Apply the modified mesh to our mesh instance
	mesh_instance.mesh = output_mesh
	
	# Clean up the temporary mesh instance
	temp_mesh_instance.queue_free()

func calculate_metaball_field(point):
	# Calculate the metaball field value at a given point
	var field_value = 0.0
	
	for mb in metaballs:
		var distance = point.distance_to(mb.position)
		
		# Metaball field function (inverse square)
		if distance < mb.radius * 3.0:
			field_value += pow(mb.radius / max(distance, 0.001), 2)
	
	return field_value

func setup_camera():
	# Create and position a camera to view the metaball system
	var camera = Camera3D.new()
	camera.position = Vector3(0, 0, 8)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	
	# Add depth of field for artistic effect
	camera.cull_mask = 1
	
	add_child(camera)

func setup_lighting():
	# Set up lighting to highlight the organic forms
	
	# Main directional light
	var dir_light = DirectionalLight3D.new()
	dir_light.position = Vector3(5, 5, 5)
	dir_light.look_at(Vector3.ZERO, Vector3.UP)
	dir_light.light_color = Color(1.0, 0.95, 0.9)
	dir_light.shadow_enabled = true
	add_child(dir_light)
	
	# Fill light
	var fill_light = DirectionalLight3D.new()
	fill_light.position = Vector3(-5, -2, 3)
	fill_light.look_at(Vector3.ZERO, Vector3.UP)
	fill_light.light_color = Color(0.9, 0.8, 0.85)
	fill_light.light_energy = 0.5
	add_child(fill_light)
	
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
	#env.fog_color = Color(0.9, 0.8, 0.8)
	
	# SSS and subsurface scattering effects
	#env.ss_reflections_enabled = true
	env.ssao_enabled = true
	env.ssao_radius = 0.5
	env.ssao_intensity = 2.0
	env.glow_enabled = true
	
	environment.environment = env
	add_child(environment)


# Marching Cubes Implementation Class
class MarchingCubesImplementation:
	# Grid settings
	var grid_size = 32
	var grid_scale = 0.2
	
	# Lookup tables for marching cubes
	var edge_table = []
	var tri_table = []
	
	# Constructor
	func _init():
		# Initialize lookup tables
		initialize_tables()
	
	# Initialize the edge and triangle tables for marching cubes algorithm
	func initialize_tables():
		# In a real implementation, you would fill these tables with
		# the standard marching cubes lookup data
		# This is a simplified placeholder
		edge_table = []
		tri_table = []
		
		# In a real implementation, you would populate these tables with
		# the standard marching cubes lookup data from literature
		for i in range(256):
			edge_table.append(0)
			tri_table.append([])
			for j in range(16):
				tri_table[i].append(-1)
	
	# Generate a mesh from a metaball field
	func generate_mesh(metaballs, threshold):
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		
		# Create grid
		var grid = []
		for x in range(grid_size+1):
			grid.append([])
			for y in range(grid_size+1):
				grid[x].append([])
				for z in range(grid_size+1):
					# Calculate grid point position
					var pos = Vector3(
						(x - grid_size/2) * grid_scale,
						(y - grid_size/2) * grid_scale,
						(z - grid_size/2) * grid_scale
					)
					
					# Calculate field value at this point
					var field_value = 0.0
					for mb in metaballs:
						var distance = pos.distance_to(mb.position)
						if distance < mb.radius * 3.0:
							field_value += pow(mb.radius / max(distance, 0.001), 2)
					
					grid[x][y].append(field_value)
		
		# March through the grid to create triangles
		for x in range(grid_size):
			for y in range(grid_size):
				for z in range(grid_size):
					march_cube(st, grid, x, y, z, threshold)
		
		st.generate_normals()
		st.generate_tangents()
		
		return st.commit()
	
	# Process a single cube in the marching cubes algorithm
	func march_cube(st, grid, x, y, z, threshold):
		# Get the 8 corners of the cube
		var corners = [
			Vector3(x, y, z),
			Vector3(x+1, y, z),
			Vector3(x+1, y+1, z),
			Vector3(x, y+1, z),
			Vector3(x, y, z+1),
			Vector3(x+1, y, z+1),
			Vector3(x+1, y+1, z+1),
			Vector3(x, y+1, z+1)
		]
		
		# Get field values at corners
		var field_values = []
		for corner in corners:
			field_values.append(grid[corner.x][corner.y][corner.z])
		
		# Determine which vertices are inside/outside the isosurface
		var cube_index = 0
		for i in range(8):
			if field_values[i] > threshold:
				cube_index |= 1 << i
		
		# In a real implementation, you would use the lookup tables to
		# determine which edges are intersected and create the triangles
		# This is simplified for this example
		
		# Placeholder for triangle generation
		# In a real implementation, you would use the edge_table and tri_table
		# to create the triangle mesh based on the cube_index
