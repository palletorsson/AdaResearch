extends Node3D

# Configuration variables
@export_category("Sculpture Configuration")
@export var num_petals: int = 7
@export var num_tendrils: int = 3
@export var generate_on_ready: bool = true

# Color palettes
var kusama_colors = [
	Color(1.0, 0.2, 0.3),  # Red
	Color(1.0, 0.5, 0.7),  # Pink
	Color(0.2, 0.8, 0.4),  # Green
	Color(0.2, 0.7, 0.9),  # Blue
	Color(0.9, 0.8, 0.1),  # Yellow
	Color(0.8, 0.2, 0.8)   # Purple
]

func _ready():
	if generate_on_ready:
		generate_sculpture()

func generate_sculpture():
	# Create the center core
	var core = create_core()
	add_child(core)
	
	# Create the petals
	create_petals()
	
	# Create the tendrils
	create_tendrils()
	
	# Set up the environment
	setup_environment()

func create_core():
	var core = Node3D.new()
	core.name = "Core"
	
	# Create the main sphere
	var sphere = MeshInstance3D.new()
	sphere.name = "CoreSphere"
	
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.8
	sphere_mesh.height = 1.6
	sphere_mesh.radial_segments = 32
	sphere_mesh.rings = 16
	sphere.mesh = sphere_mesh
	
	# Create material for the core
	var material = StandardMaterial3D.new()
	material.albedo_color = kusama_colors[4]  # Yellow
	material.roughness = 0.1
	material.metallic = 0.1
	material.metallic_specular = 0.8
	
	sphere.material_override = material
	
	# Add polka dot pattern to the core
	add_polka_dots(sphere, material.albedo_color, 0.8, true)
	
	core.add_child(sphere)
	
	# Create the inner spiral
	var spiral = create_spiral(0.6, kusama_colors[4], kusama_colors[2])
	spiral.position.y = 0.1
	core.add_child(spiral)
	
	return core

func create_petals():
	for i in range(num_petals):
		var petal = create_petal(i)
		add_child(petal)

func create_petal(index):
	var petal = Node3D.new()
	petal.name = "Petal_" + str(index)
	
	# Calculate position around the core
	var angle = (2 * PI * index) / num_petals
	var radius = 1.5
	var petal_color = kusama_colors[index % kusama_colors.size()]
	
	# Create the petal mesh
	var petal_mesh = MeshInstance3D.new()
	petal_mesh.name = "PetalMesh"
	
	# Use a custom mesh for the petal shape
	var mesh = create_petal_mesh()
	petal_mesh.mesh = mesh
	
	# Create material for the petal
	var material = StandardMaterial3D.new()
	material.albedo_color = petal_color
	material.roughness = 0.1
	material.metallic = 0.1
	material.metallic_specular = 0.8
	
	petal_mesh.material_override = material
	
	# Rotate and position the petal
	petal_mesh.rotation_degrees = Vector3(0, 0, -40)
	petal.position = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
	petal.rotation_degrees = Vector3(0, rad_to_deg(angle), 0)
	
	# Add polka dots
	var invert_colors = (index % 2) == 0
	add_polka_dots(petal_mesh, material.albedo_color, 0.6, invert_colors)
	
	petal.add_child(petal_mesh)
	
	return petal

func create_petal_mesh():
	# Create a custom petal shape using a flattened torus
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var torus_mesh = TorusMesh.new()
	torus_mesh.inner_radius = 0.2
	torus_mesh.outer_radius = 1.0
	torus_mesh.rings = 32
	#torus_mesh.sections = 16
	
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(torus_mesh, 0)
	
	# Flatten and deform the torus to create a petal shape
	for i in range(mdt.get_vertex_count()):
		var vertex = mdt.get_vertex(i)
		
		# Reshape the torus into a petal
		vertex.y *= 0.3  # Flatten
		
		# Add some waviness to the edge
		var distance = Vector2(vertex.x, vertex.z).length()
		if distance > 0.7:
			var angle = atan2(vertex.z, vertex.x)
			var waviness = sin(angle * 5) * 0.1
			vertex.y += waviness
		
		mdt.set_vertex(i, vertex)
	
	var array_mesh = ArrayMesh.new()
	mdt.commit_to_surface(array_mesh)
	
	return array_mesh

func create_tendrils():
	for i in range(num_tendrils):
		var tendril = create_tendril(i)
		add_child(tendril)

func create_tendril(index):
	var tendril = Node3D.new()
	tendril.name = "Tendril_" + str(index)
	
	# Calculate position 
	var angle = (2 * PI * index) / num_tendrils + (PI / num_petals)
	var radius = 2.0
	
	# Create the tendril using a path of spheres
	var segments = 5 + randi() % 3
	var base_color = kusama_colors[(index + 2) % kusama_colors.size()]
	
	for i in range(segments):
		var segment = MeshInstance3D.new()
		segment.name = "TendrilSegment_" + str(i)
		
		var segment_mesh = SphereMesh.new()
		segment_mesh.radius = 0.3 - (i * 0.03)
		segment_mesh.height = segment_mesh.radius * 2
		segment_mesh.radial_segments = 16
		segment_mesh.rings = 8
		segment.mesh = segment_mesh
		
		# Create material for the segment
		var material = StandardMaterial3D.new()
		material.albedo_color = base_color
		material.roughness = 0.1
		material.metallic = 0.1
		material.metallic_specular = 0.8
		
		segment.material_override = material
		
		# Position along a curved path
		var segment_angle = angle + (i * 0.2)
		var segment_radius = radius + i * 0.5
		var height_curve = sin(i * 0.8) * 0.5
		
		segment.position = Vector3(
			cos(segment_angle) * segment_radius,
			height_curve,
			sin(segment_angle) * segment_radius
		)
		
		# Add some dots to the tendril segments
		if i % 2 == 0:
			add_polka_dots(segment, base_color, 0.3, true)
		
		tendril.add_child(segment)
	
	return tendril

func create_spiral(radius, base_color, dot_color):
	var spiral = Node3D.new()
	spiral.name = "Spiral"
	
	var rings = 5
	var segments_per_ring = 12
	
	for ring in range(rings):
		var ring_radius = radius * (1.0 - (float(ring) / rings) * 0.8)
		
		for segment in range(segments_per_ring):
			var segment_mesh = MeshInstance3D.new()
			segment_mesh.name = "SpiralSegment_" + str(ring) + "_" + str(segment)
			
			var cube = BoxMesh.new()
			cube.size = Vector3(0.2, 0.1, 0.2)
			segment_mesh.mesh = cube
			
			# Position in a spiral pattern
			segment_mesh.position = Vector3(
				cos((2 * PI * segment) / segments_per_ring) * ring_radius,
				-0.2 + (float(ring) / rings) * 0.4,  # Slight height variation
				sin((2 * PI * segment) / segments_per_ring) * ring_radius
			)
			
			
			# Rotate to face center using a new transform
			var target = Vector3(0, segment_mesh.position.y, 0)
			var new_basis = Basis().looking_at(target - segment_mesh.position, Vector3.UP)
			segment_mesh.transform = Transform3D(new_basis, segment_mesh.position)
		
			# Create material
			var material = StandardMaterial3D.new()
			
			# Alternate colors
			if (ring + segment) % 2 == 0:
				material.albedo_color = base_color
			else:
				material.albedo_color = dot_color
					
			material.roughness = 0.2
			material.metallic = 0.1
			
			segment_mesh.material_override = material
			
			spiral.add_child(segment_mesh)
	
	return spiral


func add_polka_dots(mesh_instance, base_color, dot_size_factor = 1.0, invert_colors = false):
	# Get the mesh bounds
	var mesh = mesh_instance.mesh
	var aabb = mesh.get_aabb()
	
	# Choose dot color (contrasting with base)
	var dot_color
	if base_color.r + base_color.g + base_color.b > 1.5:
		dot_color = Color(0.9, 0.1, 0.1) if invert_colors else Color(1, 1, 1)
	else:
		dot_color = Color(1, 1, 1) if invert_colors else Color(0.9, 0.1, 0.1)
	
	# Number of dots based on mesh size
	var mesh_size = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
	var num_dots = int(15 * mesh_size * dot_size_factor)
	
	# Create dots
	for i in range(num_dots):
		var dot = MeshInstance3D.new()
		dot.name = "Dot_" + str(i)
		
		# Create dot mesh
		var sphere = SphereMesh.new()
		
		# Vary dot sizes
		var dot_size_variation = randf_range(0.05, 0.15) * dot_size_factor
		sphere.radius = dot_size_variation
		sphere.height = dot_size_variation * 2
		sphere.radial_segments = 8
		sphere.rings = 4
		
		dot.mesh = sphere
		
		# Create material for dot
		var material = StandardMaterial3D.new()
		material.albedo_color = dot_color
		material.roughness = 0.2
		
		dot.material_override = material
		
		# Distribute dots on the surface
		# This is a simplified approach - in a full implementation,
		# you would project points onto the actual mesh surface
		var theta = randf_range(0, PI)
		var phi = randf_range(0, 2 * PI)
		
		var x = sin(theta) * cos(phi)
		var y = sin(theta) * sin(phi)
		var z = cos(theta)
		
		var surface_point = Vector3(x, y, z)
		
		# Scale based on mesh dimensions and position at the surface
		surface_point.x *= aabb.size.x * 0.5
		surface_point.y *= aabb.size.y * 0.5
		surface_point.z *= aabb.size.z * 0.5
		
		dot.position = surface_point
		
		# Push the dot slightly above the surface to prevent z-fighting
		dot.position = dot.position.normalized() * (dot.position.length() + 0.01)
		
		mesh_instance.add_child(dot)

func setup_environment():
	# Create a camera

	
	# Create lighting
	var light = DirectionalLight3D.new()
	light.name = "DirectionalLight"
	light.position = Vector3(5, 5, 5)
	light.look_at(Vector3(0, 0, 0), Vector3.UP)
	light.light_energy = 1.0
	light.shadow_enabled = true
	add_child(light)
	
	# Add some fill lights
	var fill_light1 = OmniLight3D.new()
	fill_light1.name = "FillLight1"
	fill_light1.position = Vector3(-3, 1, 5)
	fill_light1.light_energy = 0.5
	add_child(fill_light1)
	
	var fill_light2 = OmniLight3D.new()
	fill_light2.name = "FillLight2"
	fill_light2.position = Vector3(3, 1, -5)
	fill_light2.light_energy = 0.5
	add_child(fill_light2)
	
	# Create environment
	var world_environment = WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.9, 0.9, 0.9)
	environment.ambient_light_color = Color(0.6, 0.6, 0.6)
	environment.ambient_light_energy = 0.3
	
	# Enable bloom for the glossy sculpture
	environment.glow_enabled = true
	environment.glow_intensity = 0.2
	environment.glow_bloom = 0.1
	
	world_environment.environment = environment
	add_child(world_environment)
	
	# Create a floor
	var floor_node = MeshInstance3D.new()
	floor_node.name = "Floor"
	
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(20, 20)
	floor_node.mesh = plane_mesh
	
	var floor_material = StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.3, 0.3, 0.3)
	floor_material.roughness = 0.9
	
	floor_node.material_override = floor_material
	floor_node.position = Vector3(0, -0.5, 0)
	
	add_child(floor_node)

# Additional helper function to generate a grid pattern
func create_grid_pattern(mesh_instance, base_color, line_color, grid_size = 0.2):
	var grid_material = ShaderMaterial.new()
	
	# Create shader
	var shader = Shader.new()
	shader.code = """
	shader_type spatial;
	
	uniform vec4 base_color : source_color;
	uniform vec4 line_color : source_color;
	uniform float grid_size;
	
	void fragment() {
		// Create grid lines
		vec2 grid = fract(UV / grid_size);
		float line_width = 0.05;
		
		// Check if we're on a grid line
		float is_line = step(grid.x, line_width) + step(1.0 - line_width, grid.x) +
					   step(grid.y, line_width) + step(1.0 - line_width, grid.y);
		
		// Mix base color with line color
		ALBEDO = mix(base_color.rgb, line_color.rgb, clamp(is_line, 0.0, 1.0));
		ROUGHNESS = 0.2;
		METALLIC = 0.1;
	}
	"""
	grid_material.shader = shader
	
	# Set shader parameters
	grid_material.set_shader_parameter("base_color", base_color)
	grid_material.set_shader_parameter("line_color", line_color)
	grid_material.set_shader_parameter("grid_size", grid_size)
	
	mesh_instance.material_override = grid_material


# Entry point for manual generation
func generate():
	clear_children()
	generate_sculpture()

func clear_children():
	for child in get_children():
		remove_child(child)
		child.queue_free()


# Custom class for petal generation with Bezier curves
class PetalGenerator:
	var control_points = []
	var subdivisions = 10
	var thickness = 0.2
	
	func _init(p0, p1, p2, p3, p_thickness = 0.2):
		control_points = [p0, p1, p2, p3]
		thickness = p_thickness
	
	func evaluate_bezier(t):
		var t2 = t * t
		var t3 = t2 * t
		var mt = 1 - t
		var mt2 = mt * mt
		var mt3 = mt2 * mt
		
		return control_points[0] * mt3 + \
			   control_points[1] * 3 * mt2 * t + \
			   control_points[2] * 3 * mt * t2 + \
			   control_points[3] * t3
	
	func generate_petal_mesh():
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		
		var points = []
		var normals = []
		
		# Generate points along the curve
		for i in range(subdivisions + 1):
			var t = float(i) / subdivisions
			var point = evaluate_bezier(t)
			points.append(point)
			
			# Calculate tangent and normal
			var tangent
			if i < subdivisions:
				var next_point = evaluate_bezier((i + 1.0) / subdivisions)
				tangent = (next_point - point).normalized()
			else:
				var prev_point = evaluate_bezier((i - 1.0) / subdivisions)
				tangent = (point - prev_point).normalized()
			
			# Assuming curve is mostly in XZ plane, use Y as up
			var normal = Vector3(0, 1, 0).cross(tangent).normalized()
			normals.append(normal)
		
		# Generate the mesh vertices
		for i in range(subdivisions):
			var p0 = points[i]
			var p1 = points[i + 1]
			var n0 = normals[i]
			var n1 = normals[i + 1]
			
			# Create a "ribbon" with width
			var v0 = p0 + n0 * thickness
			var v1 = p0 - n0 * thickness
			var v2 = p1 + n1 * thickness
			var v3 = p1 - n1 * thickness
			
			# Triangle 1
			st.add_normal(Vector3.UP)
			st.add_uv(Vector2(0, float(i) / subdivisions))
			st.add_vertex(v0)
			
			st.add_normal(Vector3.UP)
			st.add_uv(Vector2(1, float(i) / subdivisions))
			st.add_vertex(v1)
			
			st.add_normal(Vector3.UP)
			st.add_uv(Vector2(0, float(i + 1) / subdivisions))
			st.add_vertex(v2)
			
			# Triangle 2
			st.add_normal(Vector3.UP)
			st.add_uv(Vector2(1, float(i) / subdivisions))
			st.add_vertex(v1)
			
			st.add_normal(Vector3.UP)
			st.add_uv(Vector2(1, float(i + 1) / subdivisions))
			st.add_vertex(v3)
			
			st.add_normal(Vector3.UP)
			st.add_uv(Vector2(0, float(i + 1) / subdivisions))
			st.add_vertex(v2)
		
		st.generate_normals()
		return st.commit()
