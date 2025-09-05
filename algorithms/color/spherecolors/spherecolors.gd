extends Node3D

# 3D Geometry Color Plates - Inspired by Three.js geometry colors
# Color plates represented as geometric forms in 3D space

@export_category("Geometry Settings")
@export var geometry_type: String = "Icosphere"  # "Icosphere", "Cube", "Cylinder", "Torus"
@export var geometry_resolution: int = 3
@export var geometry_scale: float = 0.5
@export var plate_thickness: float = 0.15
@export var plate_separation: float = 0.02

@export_category("Color Settings")
@export var color_mode: String = "Rainbow"  # "Rainbow", "HSV_Sweep", "RGB_Cube", "Gradient", "Random"
@export var color_intensity: float = 1.0
@export var color_variation_speed: float = 0.5
@export var use_vertex_colors: bool = true
@export var color_interpolation: bool = true

@export_category("Animation")
@export var rotation_speed: Vector3 = Vector3(0.2, 0.3, 0.1)
@export var pulse_amplitude: float = 0.1
@export var pulse_frequency: float = 1.0
@export var color_wave_speed: float = 1.0
@export var enable_morphing: bool = true

@export_category("Auto Slideshow")
@export var slideshow_enabled: bool = true
@export var slide_duration: float = 8.0  # Seconds per color mode
@export var transition_duration: float = 2.0  # Transition time between modes

@export_category("Rendering")
@export var wireframe_overlay: bool = false
@export var emission_strength: float = 0.3
@export var metallic_factor: float = 0.1
@export var roughness_factor: float = 0.6

# Geometry data
var base_vertices: PackedVector3Array = []
var base_indices: PackedInt32Array = []
var vertex_colors: PackedColorArray = []
var face_colors: Array = []

# Mesh instances
var color_plates: Array = []
var wireframe_mesh: MeshInstance3D
var main_geometry: MeshInstance3D

# Animation variables
var time: float = 0.0
var original_scale: float
var slideshow_timer: float = 0.0
var current_slide_index: int = 0
var color_modes_list: Array = ["Rainbow", "HSV_Sweep", "RGB_Cube", "Gradient", "Random"]

func _ready():
	original_scale = geometry_scale
	setup_environment()
	generate_geometry()
	create_color_plates()
	if wireframe_overlay:
		create_wireframe()
	setup_camera_orbit()

func _process(delta):
	time += delta
	
	# Handle automatic slideshow
	if slideshow_enabled:
		handle_slideshow(delta)
	
	#animate_geometry(delta)
	update_colors(delta)
	if enable_morphing:
		apply_morphing(delta)

func setup_environment():
	# Create atmospheric environment
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.08)
	env.ambient_light_color = Color(0.1, 0.15, 0.25)
	env.ambient_light_energy = 0.2
	
	# Add subtle fog
	env.fog_enabled = true
	env.fog_light_color = Color(0.2, 0.3, 0.5)
	env.fog_light_energy = 0.1
	env.fog_density = 0.005
	
	# Glow effects for color plates
	env.glow_enabled = true
	env.glow_intensity = 1.0
	env.glow_strength = 0.8
	env.glow_bloom = 0.2
	
	var world_env = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	
	# Add directional light
	var dir_light = DirectionalLight3D.new()
	dir_light.position = Vector3(5, 10, 5)
	dir_light.look_at(Vector3.ZERO, Vector3.UP)
	dir_light.light_energy = 0.8
	dir_light.light_color = Color(1.0, 0.95, 0.9)
	dir_light.shadow_enabled = true
	add_child(dir_light)

func generate_geometry():
	match geometry_type:
		"Icosphere":
			generate_icosphere()
		"Cube":
			generate_subdivided_cube()
		"Cylinder":
			generate_cylinder()
		"Torus":
			generate_torus()
		_:
			generate_icosphere()
	
	generate_colors()

func generate_icosphere():
	# Generate icosphere using iterative subdivision
	base_vertices.clear()
	base_indices.clear()
	
	# Start with icosahedron vertices
	var t = (1.0 + sqrt(5.0)) / 2.0  # Golden ratio
	
	# 12 vertices of icosahedron
	var initial_vertices = [
		Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
		Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)
	]
	
	for vertex in initial_vertices:
		base_vertices.append(vertex.normalized() * geometry_scale)
	
	# 20 triangular faces of icosahedron
	var initial_faces = [
		[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
		[1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
		[3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
		[4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]
	]
	
	for face in initial_faces:
		base_indices.append_array([face[0], face[1], face[2]])
	
	# Subdivide for more resolution
	for subdivision in range(geometry_resolution):
		subdivide_mesh()

func generate_subdivided_cube():
	base_vertices.clear()
	base_indices.clear()
	
	var subdivisions = geometry_resolution + 1
	var step = 2.0 / subdivisions
	
	# Generate cube faces with subdivisions
	var faces = [
		{"normal": Vector3(0, 0, 1), "u": Vector3(1, 0, 0), "v": Vector3(0, 1, 0)},   # Front
		{"normal": Vector3(0, 0, -1), "u": Vector3(-1, 0, 0), "v": Vector3(0, 1, 0)}, # Back
		{"normal": Vector3(1, 0, 0), "u": Vector3(0, 0, -1), "v": Vector3(0, 1, 0)},  # Right
		{"normal": Vector3(-1, 0, 0), "u": Vector3(0, 0, 1), "v": Vector3(0, 1, 0)},  # Left
		{"normal": Vector3(0, 1, 0), "u": Vector3(1, 0, 0), "v": Vector3(0, 0, -1)},  # Top
		{"normal": Vector3(0, -1, 0), "u": Vector3(1, 0, 0), "v": Vector3(0, 0, 1)}   # Bottom
	]
	
	for face in faces:
		var start_vertex = base_vertices.size()
		
		# Generate vertices for this face
		for y in range(subdivisions + 1):
			for x in range(subdivisions + 1):
				var u = (x * step - 1.0)
				var v = (y * step - 1.0)
				var pos = face.normal + face.u * u + face.v * v
				base_vertices.append(pos.normalized() * geometry_scale)
		
		# Generate indices for this face
		for y in range(subdivisions):
			for x in range(subdivisions):
				var i = start_vertex + y * (subdivisions + 1) + x
				
				# Two triangles per quad
				base_indices.append_array([i, i + 1, i + subdivisions + 1])
				base_indices.append_array([i + 1, i + subdivisions + 2, i + subdivisions + 1])

func generate_cylinder():
	base_vertices.clear()
	base_indices.clear()
	
	var radial_segments = (geometry_resolution + 1) * 8
	var height_segments = geometry_resolution + 1
	var radius = geometry_scale * 0.5
	var height = geometry_scale
	
	# Generate vertices
	for y in range(height_segments + 1):
		var v = float(y) / height_segments
		var pos_y = (v - 0.5) * height
		
		for x in range(radial_segments + 1):
			var u = float(x) / radial_segments
			var angle = u * PI * 2
			
			var pos_x = cos(angle) * radius
			var pos_z = sin(angle) * radius
			
			base_vertices.append(Vector3(pos_x, pos_y, pos_z))
	
	# Generate indices
	for y in range(height_segments):
		for x in range(radial_segments):
			var i = y * (radial_segments + 1) + x
			
			base_indices.append_array([i, i + 1, i + radial_segments + 1])
			base_indices.append_array([i + 1, i + radial_segments + 2, i + radial_segments + 1])

func generate_torus():
	base_vertices.clear()
	base_indices.clear()
	
	var major_segments = (geometry_resolution + 1) * 12
	var minor_segments = (geometry_resolution + 1) * 8
	var major_radius = geometry_scale * 0.6
	var minor_radius = geometry_scale * 0.2
	
	# Generate vertices
	for i in range(major_segments + 1):
		var u = float(i) / major_segments * PI * 2
		
		for j in range(minor_segments + 1):
			var v = float(j) / minor_segments * PI * 2
			
			var cos_u = cos(u)
			var sin_u = sin(u)
			var cos_v = cos(v)
			var sin_v = sin(v)
			
			var x = (major_radius + minor_radius * cos_v) * cos_u
			var y = minor_radius * sin_v
			var z = (major_radius + minor_radius * cos_v) * sin_u
			
			base_vertices.append(Vector3(x, y, z))
	
	# Generate indices
	for i in range(major_segments):
		for j in range(minor_segments):
			var a = i * (minor_segments + 1) + j
			var b = a + 1
			var c = a + minor_segments + 1
			var d = c + 1
			
			base_indices.append_array([a, b, c])
			base_indices.append_array([b, d, c])

func subdivide_mesh():
	var new_vertices = base_vertices.duplicate()
	var new_indices = PackedInt32Array()
	var edge_map = {}
	
	# Process each triangle
	for i in range(0, base_indices.size(), 3):
		var v1 = base_indices[i]
		var v2 = base_indices[i + 1] 
		var v3 = base_indices[i + 2]
		
		# Get or create midpoint vertices
		var m1 = get_or_create_midpoint(v1, v2, new_vertices, edge_map)
		var m2 = get_or_create_midpoint(v2, v3, new_vertices, edge_map)
		var m3 = get_or_create_midpoint(v3, v1, new_vertices, edge_map)
		
		# Create 4 new triangles
		new_indices.append_array([v1, m1, m3])
		new_indices.append_array([v2, m2, m1])
		new_indices.append_array([v3, m3, m2])
		new_indices.append_array([m1, m2, m3])
	
	base_vertices = new_vertices
	base_indices = new_indices

func get_or_create_midpoint(v1: int, v2: int, vertices: PackedVector3Array, edge_map: Dictionary) -> int:
	var key = str(min(v1, v2)) + "_" + str(max(v1, v2))
	
	if key in edge_map:
		return edge_map[key]
	
	var midpoint = (vertices[v1] + vertices[v2]) * 0.5
	midpoint = midpoint.normalized() * geometry_scale  # Project to sphere surface
	
	vertices.append(midpoint)
	var index = vertices.size() - 1
	edge_map[key] = index
	return index

func generate_colors():
	vertex_colors.clear()
	face_colors.clear()
	
	match color_mode:
		"Rainbow":
			generate_rainbow_colors()
		"HSV_Sweep":
			generate_hsv_sweep()
		"RGB_Cube":
			generate_rgb_cube_colors()
		"Gradient":
			generate_gradient_colors()
		"Random":
			generate_random_colors()
		_:
			generate_rainbow_colors()

func generate_rainbow_colors():
	for i in range(base_vertices.size()):
		var vertex = base_vertices[i]
		var angle = atan2(vertex.z, vertex.x) + PI
		var hue = angle / (PI * 2)
		var saturation = 0.8 + 0.2 * sin(vertex.y * 0.1)
		var value = 0.7 + 0.3 * cos(vertex.length() * 0.05)
		
		var color = Color.from_hsv(hue, saturation, value) * color_intensity
		vertex_colors.append(color)
	
	# Generate face colors (average of vertex colors)
	for i in range(0, base_indices.size(), 3):
		var c1 = vertex_colors[base_indices[i]]
		var c2 = vertex_colors[base_indices[i + 1]]
		var c3 = vertex_colors[base_indices[i + 2]]
		face_colors.append((c1 + c2 + c3) / 3.0)

func generate_hsv_sweep():
	for i in range(base_vertices.size()):
		var vertex = base_vertices[i]
		var normalized_y = (vertex.y / geometry_scale + 1.0) * 0.5
		var hue = normalized_y
		var saturation = 0.9
		var value = 0.8 + 0.2 * sin(vertex.length() * 0.1)
		
		var color = Color.from_hsv(hue, saturation, value) * color_intensity
		vertex_colors.append(color)
	
	generate_face_colors_from_vertices()

func generate_rgb_cube_colors():
	for i in range(base_vertices.size()):
		var vertex = base_vertices[i].normalized()
		var r = (vertex.x + 1.0) * 0.5
		var g = (vertex.y + 1.0) * 0.5
		var b = (vertex.z + 1.0) * 0.5
		
		var color = Color(r, g, b) * color_intensity
		vertex_colors.append(color)
	
	generate_face_colors_from_vertices()

func generate_gradient_colors():
	for i in range(base_vertices.size()):
		var vertex = base_vertices[i]
		var factor = (vertex.length() - geometry_scale * 0.5) / (geometry_scale * 0.5)
		factor = clamp(factor, 0.0, 1.0)
		
		var color1 = Color(0.2, 0.4, 0.8)
		var color2 = Color(0.8, 0.2, 0.4)
		var color = color1.lerp(color2, factor) * color_intensity
		vertex_colors.append(color)
	
	generate_face_colors_from_vertices()

func generate_random_colors():
	for i in range(base_vertices.size()):
		var color = Color(randf(), randf(), randf()) * color_intensity
		vertex_colors.append(color)
	
	generate_face_colors_from_vertices()

func generate_face_colors_from_vertices():
	face_colors.clear()
	for i in range(0, base_indices.size(), 3):
		var c1 = vertex_colors[base_indices[i]]
		var c2 = vertex_colors[base_indices[i + 1]]
		var c3 = vertex_colors[base_indices[i + 2]]
		face_colors.append((c1 + c2 + c3) / 3.0)

func create_color_plates():
	color_plates.clear()
	
	# Create individual plates for each face
	for i in range(0, base_indices.size(), 3):
		var face_index = i / 3
		if face_index >= face_colors.size():
			continue
			
		var plate = create_single_color_plate(i, face_colors[face_index])
		add_child(plate)
		color_plates.append(plate)

func create_single_color_plate(triangle_start: int, color: Color) -> MeshInstance3D:
	var plate = MeshInstance3D.new()
	
	# Get triangle vertices
	var v1 = base_vertices[base_indices[triangle_start]]
	var v2 = base_vertices[base_indices[triangle_start + 1]]
	var v3 = base_vertices[base_indices[triangle_start + 2]]
	
	# Calculate face normal and center
	var normal = (v2 - v1).cross(v3 - v1).normalized()
	var center = (v1 + v2 + v3) / 3.0
	
	# Create plate geometry (extruded triangle)
	var mesh = create_plate_mesh(v1, v2, v3, normal)
	plate.mesh = mesh
	
	# Create material with face color
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * emission_strength
	material.emission_energy = 1.0
	material.metallic = metallic_factor
	material.roughness = roughness_factor
	
	if wireframe_overlay:
		material.flags_use_point_size = true
		material.wireframe = false
	
	plate.material_override = material
	
	return plate

func create_plate_mesh(v1: Vector3, v2: Vector3, v3: Vector3, normal: Vector3) -> ArrayMesh:
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	var normals = PackedVector3Array()
	
	# Offset vertices slightly outward for plate separation
	var offset = normal * plate_separation
	var v1_out = v1 + offset
	var v2_out = v2 + offset
	var v3_out = v3 + offset
	
	# Offset inward for thickness
	var thickness_offset = normal * plate_thickness
	var v1_in = v1_out + thickness_offset
	var v2_in = v2_out + thickness_offset
	var v3_in = v3_out + thickness_offset
	
	# Front face
	vertices.append_array([v1_out, v2_out, v3_out])
	normals.append_array([normal, normal, normal])
	
	# Back face
	vertices.append_array([v3_in, v2_in, v1_in])
	normals.append_array([-normal, -normal, -normal])
	
	# Side faces (simplified)
	var side_normal1 = (v2_out - v1_out).cross(normal).normalized()
	vertices.append_array([v1_out, v1_in, v2_out, v2_in])
	normals.append_array([side_normal1, side_normal1, side_normal1, side_normal1])
	
	# Indices for triangulation
	indices.append_array([0, 1, 2])  # Front
	indices.append_array([3, 4, 5])  # Back
	indices.append_array([6, 7, 8, 8, 9, 6])  # Side (as two triangles)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_NORMAL] = normals
	
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func create_wireframe():
	wireframe_mesh = MeshInstance3D.new()
	
	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = base_vertices
	arrays[Mesh.ARRAY_INDEX] = base_indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	wireframe_mesh.mesh = mesh
	
	var wireframe_material = StandardMaterial3D.new()
	wireframe_material.wireframe = true
	wireframe_material.albedo_color = Color(0.5, 0.5, 0.5, 0.3)
	wireframe_material.flags_transparent = true
	wireframe_mesh.material_override = wireframe_material
	
	add_child(wireframe_mesh)

func setup_camera_orbit():
	# Add camera with orbital movement
	var camera = Camera3D.new()
	camera.position = Vector3(0, 0, geometry_scale * 2.5)
	camera.fov = 60
	add_child(camera)

func handle_slideshow(delta):
	slideshow_timer += delta
	
	if slideshow_timer >= slide_duration:
		# Simply change to next color mode without transitions
		current_slide_index = (current_slide_index + 1) % color_modes_list.size()
		var new_color_mode = color_modes_list[current_slide_index]
		
		# Change color mode and regenerate colors
		color_mode = new_color_mode
		generate_colors()
		update_existing_plate_colors()
		
		# Reset timer
		slideshow_timer = 0.0

func update_existing_plate_colors():
	# Update the colors of existing plates without recreating them
	for i in range(color_plates.size()):
		if i < color_plates.size() and i < face_colors.size():
			var plate = color_plates[i]
			if plate and is_instance_valid(plate):
				var material = plate.material_override as StandardMaterial3D
				if material:
					var new_color = face_colors[i]
					material.albedo_color = new_color
					material.emission = new_color * emission_strength

func animate_geometry(delta):
	# Rotate the entire geometry
	rotation += rotation_speed * delta
	
	# Pulsing scale
	var pulse = 1.0 + sin(time * pulse_frequency) * pulse_amplitude
	scale = Vector3.ONE * pulse

func update_colors(delta):
	# Animate colors over time
	var color_time_offset = time * color_wave_speed
	
	for i in range(color_plates.size()):
		if i < color_plates.size():
			var plate = color_plates[i]
			var material = plate.material_override as StandardMaterial3D
			
			if material:
				var base_color = face_colors[i] if i < face_colors.size() else Color.WHITE
				var wave_factor = sin(color_time_offset + i * 0.1) * 0.3 + 0.7
				var animated_color = base_color * wave_factor * color_intensity
				
				material.albedo_color = animated_color
				material.emission = animated_color * emission_strength

func apply_morphing(delta):
	# Subtle vertex displacement for organic feel
	for i in range(color_plates.size()):
		if i < color_plates.size():
			var plate = color_plates[i]
			var displacement = sin(time + i * 0.1) * 0.02
			var original_pos = Vector3.ZERO  # You'd store original positions
			# Apply subtle position changes (implementation would require storing original positions)

func _input(event):
	# Removed all input handling for clean automatic slideshow
	pass
