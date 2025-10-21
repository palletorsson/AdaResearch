# FatWireframeVR.gd
# A mesmerizing VR scene with thick, glowing wireframe objects
extends Node3D

@export var object_count: int = 12
@export var wireframe_thickness: float = 0.08
@export var animation_speed: float = 1.0
@export var glow_intensity: float = 2.0
@export var auto_rotate: bool = true

var wireframe_objects: Array[MeshInstance3D] = []
var wireframe_materials: Array[ShaderMaterial] = []
var base_geometries: Array[Mesh] = []

# Custom wireframe shader with thick, glowing edges
const WIREFRAME_SHADER = """
shader_type spatial;
render_mode depth_draw_opaque, cull_disabled, diffuse_lambert, specular_schlick_ggx;

uniform float line_thickness : hint_range(0.01, 0.2) = 0.05;
uniform vec4 wireframe_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform vec4 glow_color : source_color = vec4(0.2, 0.8, 1.0, 1.0);
uniform float glow_intensity : hint_range(0.5, 5.0) = 2.0;
uniform float pulse_speed : hint_range(0.5, 3.0) = 1.5;
uniform float thickness_pulse : hint_range(0.0, 1.0) = 0.3;
uniform float edge_falloff : hint_range(0.1, 2.0) = 0.8;
uniform bool animate_thickness = true;

varying vec3 world_position;
varying vec3 barycentric;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Calculate barycentric coordinates for wireframe effect
	// This is a simplified approach - in reality you'd pass this from vertex attributes
	barycentric = vec3(0.0);
	if (int(VERTEX_ID) % 3 == 0) barycentric.x = 1.0;
	else if (int(VERTEX_ID) % 3 == 1) barycentric.y = 1.0; 
	else barycentric.z = 1.0;
}

void fragment() {
	// Calculate distance to nearest edge using barycentric coordinates
	vec3 d = fwidth(barycentric);
	vec3 a3 = smoothstep(vec3(0.0), d * line_thickness * 10.0, barycentric);
	float edge_factor = min(min(a3.x, a3.y), a3.z);
	
	// Animate thickness if enabled
	float animated_thickness = line_thickness;
	if (animate_thickness) {
		float pulse = sin(TIME * pulse_speed + world_position.x * 0.1) * thickness_pulse;
		animated_thickness *= (1.0 + pulse);
	}
	
	// Create wireframe effect
	float wireframe = 1.0 - smoothstep(0.0, animated_thickness, edge_factor);
	
	if (wireframe < 0.1) {
		discard; // Only show the wireframe edges
	}
	
	// Create glow effect
	float glow = pow(wireframe, edge_falloff);
	
	// Pulse the entire wireframe
	float global_pulse = sin(TIME * pulse_speed * 0.7) * 0.2 + 0.8;
	
	// Mix wireframe and glow colors
	vec3 final_color = mix(wireframe_color.rgb, glow_color.rgb, glow * 0.5);
	
	ALBEDO = final_color;
	EMISSION = final_color * glow_intensity * glow * global_pulse;
	ALPHA = wireframe_color.a * wireframe;
}
"""

# Alternative edge-based wireframe shader for different objects
const EDGE_WIREFRAME_SHADER = """
shader_type spatial;
render_mode depth_draw_opaque, cull_disabled;

uniform vec4 line_color : source_color = vec4(1.0, 0.5, 0.0, 1.0);
uniform float line_width : hint_range(0.001, 0.01) = 0.003;
uniform float glow_strength : hint_range(0.5, 3.0) = 1.5;
uniform float animation_speed : hint_range(0.5, 3.0) = 1.0;

varying vec3 world_pos;
varying vec3 local_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	local_pos = VERTEX;
}

void fragment() {
	// Create wireframe by detecting edges using screen-space derivatives
	vec3 fw = fwidth(local_pos);
	vec3 edge_factor = step(fw * (line_width * 1000.0), abs(fract(local_pos * 8.0) - 0.5));
	float wireframe = 1.0 - min(min(edge_factor.x, edge_factor.y), edge_factor.z);
	
	if (wireframe < 0.5) {
		discard;
	}
	
	// Animate the glow
	float time_wave = sin(TIME * animation_speed + world_pos.x * 0.2 + world_pos.z * 0.3) * 0.3 + 0.7;
	
	ALBEDO = line_color.rgb;
	EMISSION = line_color.rgb * glow_strength * time_wave;
	ALPHA = line_color.a * wireframe;
}
"""

func _ready():
	setup_scene()
	create_base_geometries()
	create_wireframe_objects()
	start_animations()

func setup_scene():
	# Create dark cyberpunk environment
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	
	# Dark, tech-noir atmosphere
	var sky_mat = env.sky.sky_material as ProceduralSkyMaterial
	sky_mat.sky_top_color = Color(0.01, 0.02, 0.05)
	sky_mat.sky_horizon_color = Color(0.02, 0.05, 0.1)
	sky_mat.ground_bottom_color = Color(0.005, 0.01, 0.02)
	
	env.ambient_light_energy = 0.1
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	
	# Add volumetric fog for glow enhancement
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.03
	env.volumetric_fog_emission = Color(0.02, 0.05, 0.1)
	
	var camera_env = get_viewport().get_camera_3d()
	if camera_env:
		camera_env.environment = env

# Helper function to convert any mesh to ArrayMesh
func convert_mesh_to_array_mesh(mesh: Mesh) -> ArrayMesh:
	var array_mesh = ArrayMesh.new()
	if mesh is ArrayMesh:
		return mesh
	elif mesh is PrimitiveMesh:
		var arrays = mesh.surface_get_arrays(0)
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return array_mesh
	else:
		# Fallback for other mesh types
		return ArrayMesh.new()

func create_base_geometries():
	# Create various geometric shapes for wireframe rendering
	base_geometries = [
		# Basic shapes - convert all to ArrayMesh for consistency
		convert_mesh_to_array_mesh(SphereMesh.new()),
		convert_mesh_to_array_mesh(BoxMesh.new()),
		convert_mesh_to_array_mesh(CylinderMesh.new()),
		
		# Complex shapes
		convert_mesh_to_array_mesh(TorusMesh.new()),
		create_icosphere_mesh(),
		create_geodesic_mesh(),
		
		# Mathematical shapes  
		create_klein_bottle_mesh(),
		create_mobius_strip_mesh(),
		
		# Architectural shapes
		create_pyramid_mesh(),
		create_prism_mesh(),
		create_dodecahedron_mesh(),
		create_tetrahedron_mesh()
	]
	
	# Configure mesh properties before conversion
	var sphere = SphereMesh.new()
	sphere.radial_segments = 6
	sphere.rings = 4
	base_geometries[0] = convert_mesh_to_array_mesh(sphere)
	
	var box = BoxMesh.new()
	box.size = Vector3(2, 2, 2)
	base_geometries[1] = convert_mesh_to_array_mesh(box)
	
	var cylinder = CylinderMesh.new()
	cylinder.height = 3.0
	base_geometries[2] = convert_mesh_to_array_mesh(cylinder)
	
	var torus = TorusMesh.new()
	torus.inner_radius = 0.8
	torus.outer_radius = 1.8
	base_geometries[3] = convert_mesh_to_array_mesh(torus)

func create_wireframe_objects():
	for i in range(object_count):
		var mesh_instance = MeshInstance3D.new()
		var geometry = base_geometries[i % base_geometries.size()]
		mesh_instance.mesh = geometry
		mesh_instance.name = "WireframeObject_" + str(i)
		
		# Position objects in interesting arrangements
		var arrangement = i % 4
		match arrangement:
			0:  # Circle arrangement
				var angle = (float(i) / float(object_count)) * PI * 2.0
				var radius = 8.0 + sin(i * 0.5) * 2.0
				mesh_instance.position = Vector3(cos(angle) * radius, sin(i * 0.3) * 3.0, sin(angle) * radius)
				
			1:  # Vertical stack
				mesh_instance.position = Vector3(
					sin(i * 0.8) * 3.0, 
					(i % 6) * 2.0 - 5.0, 
					cos(i * 0.8) * 3.0
				)
				
			2:  # Spiral arrangement
				var spiral_angle = i * 0.8
				var spiral_height = i * 0.8
				mesh_instance.position = Vector3(
					cos(spiral_angle) * (4.0 + spiral_height * 0.3),
					spiral_height - 6.0,
					sin(spiral_angle) * (4.0 + spiral_height * 0.3)
				)
				
			3:  # Random cloud
				mesh_instance.position = Vector3(
					randf_range(-8.0, 8.0),
					randf_range(-4.0, 4.0),
					randf_range(-8.0, 8.0)
				)
		
		# Scale objects
		var scale = randf_range(0.8, 2.2)
		mesh_instance.scale = Vector3(scale, scale, scale)
		
		# Create wireframe material
		var material = ShaderMaterial.new()
		var shader = Shader.new()
		
		# Use different shaders for variety
		if i % 2 == 0:
			shader.code = WIREFRAME_SHADER
		else:
			shader.code = EDGE_WIREFRAME_SHADER
		
		material.shader = shader
		
		# Set unique colors and properties
		var hue = (float(i) / float(object_count)) * 360.0 + randf_range(-30.0, 30.0)
		var saturation = randf_range(0.7, 1.0)
		var brightness = randf_range(0.8, 1.0)
		var wireframe_color = Color.from_hsv(hue / 360.0, saturation, brightness)
		
		var glow_hue = hue + randf_range(60.0, 120.0)
		if glow_hue > 360.0: glow_hue -= 360.0
		var glow_color = Color.from_hsv(glow_hue / 360.0, saturation * 0.8, brightness)
		
		if i % 2 == 0:
			# Barycentric wireframe shader parameters
			material.set_shader_parameter("wireframe_color", wireframe_color)
			material.set_shader_parameter("glow_color", glow_color)
			material.set_shader_parameter("glow_intensity", glow_intensity + randf_range(-0.5, 0.5))
			material.set_shader_parameter("line_thickness", wireframe_thickness + randf_range(-0.02, 0.02))
			material.set_shader_parameter("pulse_speed", randf_range(0.8, 2.5))
			material.set_shader_parameter("thickness_pulse", randf_range(0.1, 0.5))
			material.set_shader_parameter("animate_thickness", true)
		else:
			# Edge-based wireframe shader parameters
			material.set_shader_parameter("line_color", wireframe_color)
			material.set_shader_parameter("line_width", wireframe_thickness * 0.1)
			material.set_shader_parameter("glow_strength", glow_intensity)
			material.set_shader_parameter("animation_speed", randf_range(0.5, 2.0))
		
		mesh_instance.set_surface_override_material(0, material)
		
		add_child(mesh_instance)
		wireframe_objects.append(mesh_instance)
		wireframe_materials.append(material)

func start_animations():
	if auto_rotate:
		animate_object_rotations()
	
	animate_wireframe_effects()

func animate_object_rotations():
	# Add rotation animations to each object
	for i in range(wireframe_objects.size()):
		var obj = wireframe_objects[i]
		var tween = create_tween()
		tween.set_loops(0)  # Finite loops instead of infinite
		
		# Different rotation patterns
		match i % 3:
			0:  # Slow tumble
				var axis = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
				var speed = randf_range(15.0, 30.0) / animation_speed
				tween.tween_method(
					func(angle): obj.rotation = axis * angle,
					0.0, PI * 2.0, speed
				)
				
			1:  # Dual axis rotation
				var tween_x = create_tween()
				var tween_y = create_tween()
				tween_x.set_loops(0)  # Finite loops instead of infinite
				tween_y.set_loops(0)  # Finite loops instead of infinite
				
				tween_x.tween_property(obj, "rotation:x", PI * 2.0, 20.0 / animation_speed)
				tween_y.tween_property(obj, "rotation:y", PI * 2.0, 15.0 / animation_speed)
				
			2:  # Oscillating rotation
				tween.tween_method(
					func(t): obj.rotation = Vector3(sin(t) * 0.5, t, cos(t) * 0.3),
					0.0, PI * 4.0, 25.0 / animation_speed
				)

func animate_wireframe_effects():
	# Animate shader properties for pulsing effects
	for i in range(wireframe_materials.size()):
		var material = wireframe_materials[i]
		
		# Animate glow intensity
		var glow_tween = create_tween()
		glow_tween.set_loops(0)  # Finite loops instead of infinite
		var base_glow = glow_intensity
		var glow_variation = randf_range(0.5, 1.5)
		
		glow_tween.tween_method(
			func(value): 
				if material.shader and material.shader.code.contains("glow_intensity"):
					material.set_shader_parameter("glow_intensity", value),
			base_glow * 0.5,
			base_glow * (1.0 + glow_variation),
			randf_range(2.0, 5.0) / animation_speed
		)
		
		# Animate thickness for some objects
		if i % 3 == 0:
			var thickness_tween = create_tween()
			thickness_tween.set_loops(0)  # Finite loops instead of infinite
			
			thickness_tween.tween_method(
				func(value):
					if material.shader and material.shader.code.contains("line_thickness"):
						material.set_shader_parameter("line_thickness", value),
				wireframe_thickness * 0.5,
				wireframe_thickness * 2.0,
				randf_range(3.0, 7.0) / animation_speed
			)

# Create complex geometric meshes
func create_icosphere_mesh() -> ArrayMesh:
	# Create an icosphere for smooth wireframes
	var sphere = SphereMesh.new()
	sphere.radial_segments = 8  # Horizontal segments
	sphere.rings = 6  # Vertical rings
	
	# Convert SphereMesh to ArrayMesh
	var mesh = ArrayMesh.new()
	var arrays = sphere.surface_get_arrays(0)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func create_geodesic_mesh() -> ArrayMesh:
	# Create geodesic pattern
	var mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	
	# Golden ratio
	var phi = (1.0 + sqrt(5.0)) / 2.0
	var a = 1.0
	var b = 1.0 / phi
	
	# 12 vertices of icosahedron
	var ico_vertices = [
		Vector3(0, b, -a), Vector3(b, a, 0), Vector3(-b, a, 0),
		Vector3(0, b, a), Vector3(0, -b, a), Vector3(-a, 0, b),
		Vector3(0, -b, -a), Vector3(a, 0, -b), Vector3(a, 0, b),
		Vector3(-a, 0, -b), Vector3(b, -a, 0), Vector3(-b, -a, 0)
	]
	
	# Normalize vertices to unit sphere
	for vertex in ico_vertices:
		vertices.append(vertex.normalized() * 1.5)
	
	# 20 triangular faces of icosahedron
	var faces = [
		[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
		[1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
		[3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
		[4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]
	]
	
	for face in faces:
		indices.append_array(face)
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func create_klein_bottle_mesh() -> ArrayMesh:
	# Simplified Klein bottle approximation
	var mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	
	var segments = 24
	var rings = 16
	
	for i in range(rings):
		for j in range(segments):
			var u = (float(i) / float(rings - 1)) * PI * 2.0
			var v = (float(j) / float(segments - 1)) * PI * 2.0
			
			# Klein bottle parametric equations (simplified)
			var x = (2.0 + cos(u / 2.0) * sin(v) - sin(u / 2.0) * sin(2.0 * v)) * cos(u)
			var y = (2.0 + cos(u / 2.0) * sin(v) - sin(u / 2.0) * sin(2.0 * v)) * sin(u)
			var z = sin(u / 2.0) * sin(v) + cos(u / 2.0) * sin(2.0 * v)
			
			vertices.append(Vector3(x, y, z) * 0.8)
	
	# Create indices for triangles
	for i in range(rings - 1):
		for j in range(segments - 1):
			var current = i * segments + j
			var next = current + segments
			
			indices.append_array([
				current, next, current + 1,
				current + 1, next, next + 1
			])
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func create_mobius_strip_mesh() -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	
	var segments = 40
	var width_segments = 8
	
	for i in range(segments):
		for j in range(width_segments):
			var u = (float(i) / float(segments - 1)) * PI * 2.0
			var v = (float(j) / float(width_segments - 1) - 0.5) * 0.8
			
			# Möbius strip parametric equations
			var x = (1.0 + v * cos(u / 2.0)) * cos(u)
			var y = v * sin(u / 2.0)
			var z = (1.0 + v * cos(u / 2.0)) * sin(u)
			
			vertices.append(Vector3(x, y, z) * 2.0)
	
	# Create triangular faces
	for i in range(segments - 1):
		for j in range(width_segments - 1):
			var current = i * width_segments + j
			var next = current + width_segments
			
			indices.append_array([
				current, next, current + 1,
				current + 1, next, next + 1
			])
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func create_pyramid_mesh() -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var vertices = PackedVector3Array([
		Vector3(0, 2, 0),      # Top
		Vector3(-1, 0, -1),    # Base corners
		Vector3(1, 0, -1),
		Vector3(1, 0, 1),
		Vector3(-1, 0, 1)
	])
	
	var indices = PackedInt32Array([
		0, 1, 2,  0, 2, 3,  0, 3, 4,  0, 4, 1,  # Sides
		1, 4, 3,  1, 3, 2   # Base (two triangles)
	])
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func create_prism_mesh() -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	
	# Hexagonal prism
	var sides = 6
	var height = 2.0
	var radius = 1.5
	
	# Top and bottom vertices
	for ring in range(2):
		var y = height * 0.5 if ring == 0 else -height * 0.5
		for i in range(sides):
			var angle = (float(i) / float(sides)) * PI * 2.0
			vertices.append(Vector3(cos(angle) * radius, y, sin(angle) * radius))
	
	# Create faces
	for i in range(sides):
		var next_i = (i + 1) % sides
		
		# Side faces
		indices.append_array([
			i, i + sides, next_i,
			next_i, i + sides, next_i + sides
		])
		
		# Top and bottom faces
		indices.append_array([0, next_i, i])  # Top (center assumed at 0)
		indices.append_array([sides, sides + i, sides + next_i])  # Bottom
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func create_dodecahedron_mesh() -> ArrayMesh:
	# Simplified dodecahedron (12 pentagonal faces)
	var mesh = ArrayMesh.new()
	
	# Use a UV sphere as base and convert to ArrayMesh
	var sphere = SphereMesh.new()
	sphere.radial_segments = 6
	sphere.rings = 4
	
	# Convert SphereMesh to ArrayMesh
	var arrays = sphere.surface_get_arrays(0)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func create_tetrahedron_mesh() -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var vertices = PackedVector3Array([
		Vector3(1, 1, 1),
		Vector3(1, -1, -1),  
		Vector3(-1, 1, -1),
		Vector3(-1, -1, 1)
	])
	
	var indices = PackedInt32Array([
		0, 1, 2,  0, 2, 3,  0, 3, 1,  1, 3, 2
	])
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _process(_delta):
	# Update any time-based effects if needed
	update_dynamic_effects()

func update_dynamic_effects():
	# Optional: Add dynamic effects based on time or VR controller input
	pass
