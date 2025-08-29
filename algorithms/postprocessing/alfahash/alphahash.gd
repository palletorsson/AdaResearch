# AlphaHashVR.gd
# A mesmerizing VR scene with dithered transparency and ghostly materials
extends Node3D

@export var object_count: int = 15
@export var transparency_animation_speed: float = 1.0
@export var dither_scale: float = 1.0
@export var ghost_intensity: float = 0.7

var alpha_objects: Array[MeshInstance3D] = []
var alpha_materials: Array[ShaderMaterial] = []

# Alpha hash shader with dithered transparency
const ALPHA_HASH_SHADER = """
shader_type spatial;
render_mode depth_draw_opaque, depth_prepass_alpha, cull_disabled;

uniform float alpha_base : hint_range(0.1, 1.0) = 0.6;
uniform float alpha_variation : hint_range(0.0, 0.8) = 0.4;
uniform vec4 base_color : source_color = vec4(0.5, 0.8, 1.0, 1.0);
uniform vec4 ghost_color : source_color = vec4(1.0, 0.3, 0.8, 1.0);
uniform float dither_size : hint_range(0.5, 4.0) = 1.5;
uniform float time_offset : hint_range(0.0, 10.0) = 0.0;
uniform float pulse_frequency : hint_range(0.5, 3.0) = 1.2;
uniform float noise_scale : hint_range(0.1, 2.0) = 0.8;
uniform bool animate_alpha  = true;

varying vec3 world_position;
varying vec2 screen_position;

// Noise functions for dithering
float random(vec2 st) {
	return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 st) {
	vec2 i = floor(st);
	vec2 f = fract(st);
	
	float a = random(i);
	float b = random(i + vec2(1.0, 0.0));
	float c = random(i + vec2(0.0, 1.0));
	float d = random(i + vec2(1.0, 1.0));
	
	vec2 u = f * f * (3.0 - 2.0 * f);
	
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	screen_position = (PROJECTION_MATRIX * (VIEW_MATRIX * vec4(world_position, 1.0))).xy;
}

void fragment() {
	// Calculate base alpha with animation
	float animated_alpha = alpha_base;
	
	if (animate_alpha) {
		float time_wave = sin(TIME * pulse_frequency + time_offset + world_position.y * 0.1) * 0.5 + 0.5;
		animated_alpha = alpha_base + (time_wave * alpha_variation);
	}
	
	// Create dither pattern using screen space
	vec2 dither_coords = screen_position * dither_size * 100.0;
	float dither_threshold = random(floor(dither_coords));
	
	// Add noise-based variation
	vec2 noise_coords = world_position.xz * noise_scale + TIME * 0.1;
	float noise_value = noise(noise_coords) * 0.3;
	
	// Combine dithering with noise
	float final_alpha = animated_alpha + noise_value;
	
	// Alpha hash technique - use dithering for transparency
	if (final_alpha < dither_threshold) {
		discard;
	}
	
	// Color mixing based on alpha and position
	float height_factor = (world_position.y + 5.0) / 10.0;
	vec3 final_color = mix(base_color.rgb, ghost_color.rgb, height_factor);
	
	// Add subtle glow
	float edge_glow = 1.0 - abs(dot(NORMAL, VIEW));
	edge_glow = pow(edge_glow, 2.0);
	
	ALBEDO = final_color;
	EMISSION = final_color * edge_glow * 0.3;
	ALPHA = 1.0; // We handle transparency via discard
}
"""

# Alternative stipple shader for variation
const STIPPLE_SHADER = """
shader_type spatial;
render_mode depth_draw_opaque, depth_prepass_alpha;

uniform float stipple_density : hint_range(0.1, 0.9) = 0.5;
uniform float stipple_size : hint_range(1.0, 8.0) = 3.0;
uniform vec4 color_a : source_color = vec4(0.2, 0.7, 1.0, 1.0);
uniform vec4 color_b : source_color = vec4(1.0, 0.2, 0.7, 1.0);
uniform float animation_speed : hint_range(0.5, 3.0) = 1.0;
uniform float depth_fade : hint_range(0.0, 1.0) = 0.3;

varying vec3 world_pos;
varying float vertex_distance;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vertex_distance = length((VIEW_MATRIX * vec4(world_pos, 1.0)).xyz);
}

void fragment() {
	// Create stipple pattern
	vec2 stipple_coords = world_pos.xz * stipple_size + TIME * animation_speed * 0.2;
	float stipple_noise = fract(sin(dot(stipple_coords, vec2(127.1, 311.7))) * 43758.5453);
	
	// Animate stipple density
	float animated_density = stipple_density + sin(TIME * animation_speed + world_pos.y) * 0.2;
	
	if (stipple_noise > animated_density) {
		discard;
	}
	
	// Color based on stipple pattern and depth
	vec3 final_color = mix(color_a.rgb, color_b.rgb, stipple_noise);
	
	// Fade with distance for depth effect
	float depth_alpha = 1.0 - (vertex_distance * depth_fade * 0.01);
	depth_alpha = clamp(depth_alpha, 0.1, 1.0);
	
	ALBEDO = final_color;
	EMISSION = final_color * (1.0 - stipple_noise) * 0.5;
	ALPHA = depth_alpha;
}
"""

func _ready():
	setup_scene()
	create_alpha_objects()
	start_transparency_animations()

func setup_scene():
	# Create ethereal, ghostly environment
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	
	# Misty, ethereal atmosphere
	var sky_mat = env.sky.sky_material as ProceduralSkyMaterial
	sky_mat.sky_top_color = Color(0.1, 0.05, 0.15)
	sky_mat.sky_horizon_color = Color(0.2, 0.1, 0.2)
	sky_mat.ground_bottom_color = Color(0.05, 0.02, 0.08)
	sky_mat.ground_horizon_color = Color(0.1, 0.05, 0.1)
	
	env.ambient_light_energy = 0.3
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	
	# Add volumetric fog for ghostly atmosphere
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.08
	env.volumetric_fog_emission = Color(0.1, 0.05, 0.15)
	env.volumetric_fog_emission_energy = 0.4
	
	var camera_env = get_viewport().get_camera_3d()
	if camera_env:
		camera_env.environment = env
	
	# Soft ambient lighting
	var ambient_light = DirectionalLight3D.new()
	ambient_light.position = Vector3(3, 8, 5)
	ambient_light.look_at(Vector3.ZERO, Vector3.UP)
	ambient_light.light_energy = 0.4
	ambient_light.light_color = Color(0.8, 0.9, 1.0)
	add_child(ambient_light)

func create_alpha_objects():
	# Create various geometric objects with alpha hash materials
	var geometries = [
		SphereMesh.new(),
		BoxMesh.new(),
		CylinderMesh.new(),
		TorusMesh.new(),
		create_octahedron_mesh(),
		create_truncated_pyramid_mesh(),
		create_star_mesh(),
		create_crystal_cluster_mesh()
	]
	
	# Configure geometries
	(geometries[0] as SphereMesh).radial_segments = 8
	(geometries[0] as SphereMesh).rings = 6
	(geometries[1] as BoxMesh).size = Vector3(2.2, 2.2, 2.2)
	(geometries[2] as CylinderMesh).height = 3.0
	(geometries[2] as CylinderMesh).top_radius = 1.0
	(geometries[3] as TorusMesh).inner_radius = 0.6
	(geometries[3] as TorusMesh).outer_radius = 1.4
	
	for i in range(object_count):
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = geometries[i % geometries.size()]
		mesh_instance.name = "AlphaObject_" + str(i)
		
		# Arrange objects in layered spiral
		var layer = i / 5
		var angle = (i % 5) * PI * 2.0 / 5.0 + layer * 0.3
		var radius = 6.0 + layer * 1.5
		var height = layer * 2.5 - 4.0
		
		mesh_instance.position = Vector3(
			cos(angle) * radius + sin(i * 0.3) * 1.5,
			height + sin(i * 0.7) * 1.0,
			sin(angle) * radius + cos(i * 0.3) * 1.5
		)
		
		# Random scale and rotation
		var scale = randf_range(0.8, 1.8)
		mesh_instance.scale = Vector3(scale, scale, scale)
		mesh_instance.rotation = Vector3(randf() * PI, randf() * PI, randf() * PI)
		
		# Create alpha hash material
		var material = ShaderMaterial.new()
		var shader = Shader.new()
		
		# Alternate between shaders for variety
		if i % 2 == 0:
			shader.code = ALPHA_HASH_SHADER
			setup_alpha_hash_material(material, i)
		else:
			shader.code = STIPPLE_SHADER
			setup_stipple_material(material, i)
		
		material.shader = shader
		mesh_instance.set_surface_override_material(0, material)
		
		add_child(mesh_instance)
		alpha_objects.append(mesh_instance)
		alpha_materials.append(material)

func setup_alpha_hash_material(material: ShaderMaterial, index: int):
	# Configure alpha hash shader parameters
	var hue_a = (float(index) / float(object_count)) * 360.0
	var hue_b = hue_a + 180.0  # Complementary color
	if hue_b > 360.0: hue_b -= 360.0
	
	var color_a = Color.from_hsv(hue_a / 360.0, 0.8, 0.9)
	var color_b = Color.from_hsv(hue_b / 360.0, 0.6, 1.0)
	
	material.set_shader_parameter("base_color", color_a)
	material.set_shader_parameter("ghost_color", color_b)
	material.set_shader_parameter("alpha_base", ghost_intensity + randf_range(-0.2, 0.2))
	material.set_shader_parameter("alpha_variation", randf_range(0.2, 0.6))
	material.set_shader_parameter("dither_size", dither_scale + randf_range(-0.3, 0.3))
	material.set_shader_parameter("time_offset", randf() * 10.0)
	material.set_shader_parameter("pulse_frequency", randf_range(0.8, 2.0))
	material.set_shader_parameter("noise_scale", randf_range(0.5, 1.2))

func setup_stipple_material(material: ShaderMaterial, index: int):
	# Configure stipple shader parameters
	var hue_a = (float(index) / float(object_count)) * 360.0 + 60.0
	var hue_b = hue_a + 120.0
	if hue_b > 360.0: hue_b -= 360.0
	
	var color_a = Color.from_hsv(hue_a / 360.0, 0.7, 0.8)
	var color_b = Color.from_hsv(hue_b / 360.0, 0.8, 1.0)
	
	material.set_shader_parameter("color_a", color_a)
	material.set_shader_parameter("color_b", color_b)
	material.set_shader_parameter("stipple_density", ghost_intensity + randf_range(-0.1, 0.1))
	material.set_shader_parameter("stipple_size", dither_scale + randf_range(-0.5, 0.5))
	material.set_shader_parameter("animation_speed", transparency_animation_speed)
	material.set_shader_parameter("depth_fade", randf_range(0.1, 0.5))

func start_transparency_animations():
	# Animate transparency and ghostly effects
	animate_alpha_waves()
	animate_object_movements()

func animate_alpha_waves():
	# Create waves of transparency that flow through objects
	for i in range(alpha_materials.size()):
		var material = alpha_materials[i]
		
		# Create transparency wave animation
		var alpha_tween = create_tween()
		alpha_tween.set_loops()
		
		var wave_duration = randf_range(4.0, 8.0) / transparency_animation_speed
		var delay = i * 0.2  # Stagger animations
		
		# Use tween_interval for delay (Godot 4 compatible)
		alpha_tween.tween_interval(delay)
		alpha_tween.tween_method(
			func(alpha_val):
				if material.shader.code.contains("alpha_base"):
					material.set_shader_parameter("alpha_base", alpha_val)
				elif material.shader.code.contains("stipple_density"):
					material.set_shader_parameter("stipple_density", alpha_val),
			ghost_intensity * 0.3,
			ghost_intensity * 1.2,
			wave_duration * 0.5
		)
		alpha_tween.tween_method(
			func(alpha_val):
				if material.shader.code.contains("alpha_base"):
					material.set_shader_parameter("alpha_base", alpha_val)  
				elif material.shader.code.contains("stipple_density"):
					material.set_shader_parameter("stipple_density", alpha_val),
			ghost_intensity * 1.2,
			ghost_intensity * 0.3,
			wave_duration * 0.5
		)

func animate_object_movements():
	# Add gentle floating and rotation to enhance ghostly effect
	for i in range(alpha_objects.size()):
		var obj = alpha_objects[i]
		var original_pos = obj.position
		
		# Floating animation
		var float_tween = create_tween()
		float_tween.set_loops()
		var float_height = randf_range(0.5, 1.5)
		var float_speed = randf_range(3.0, 6.0) / transparency_animation_speed
		
		float_tween.tween_method(
			func(offset): obj.position = original_pos + Vector3(0, sin(offset) * float_height, 0),
			0.0, PI * 2.0, float_speed
		)
		
		# Gentle rotation
		var rot_tween = create_tween()
		rot_tween.set_loops()
		var rot_axis = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
		var rot_speed = randf_range(20.0, 40.0) / transparency_animation_speed
		
		rot_tween.tween_method(
			func(angle): obj.rotation = rot_axis * angle,
			0.0, PI * 2.0, rot_speed
		)
		
		# Phase some objects in and out of existence
		if i % 4 == 0:
			create_phase_animation(obj, i)

func create_phase_animation(obj: Node3D, index: int):
	# Make some objects fade in and out completely
	var phase_tween = create_tween()
	phase_tween.set_loops()
	
	var phase_duration = randf_range(8.0, 15.0) / transparency_animation_speed
	var delay = index * 0.5
	
	# Use tween_interval for delays (Godot 4 compatible)
	phase_tween.tween_interval(delay)
	phase_tween.tween_property(obj, "visible", false, 0.1)
	phase_tween.tween_interval(2.0)
	phase_tween.tween_property(obj, "visible", true, 0.1)
	phase_tween.tween_interval(phase_duration)

# Create custom geometric meshes
func create_octahedron_mesh() -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var vertices = PackedVector3Array([
		Vector3(0, 1, 0),   # Top
		Vector3(0, -1, 0),  # Bottom
		Vector3(1, 0, 0),   # Right
		Vector3(-1, 0, 0),  # Left
		Vector3(0, 0, 1),   # Front
		Vector3(0, 0, -1)   # Back
	])
	
	var indices = PackedInt32Array([
		0, 2, 4,  0, 4, 3,  0, 3, 5,  0, 5, 2,  # Top faces
		1, 4, 2,  1, 3, 4,  1, 5, 3,  1, 2, 5   # Bottom faces
	])
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func create_truncated_pyramid_mesh() -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	
	var base_size = 2.0
	var top_size = 1.0
	var height = 2.5
	
	# Bottom vertices
	vertices.append_array([
		Vector3(-base_size, -height/2, -base_size),
		Vector3(base_size, -height/2, -base_size),
		Vector3(base_size, -height/2, base_size),
		Vector3(-base_size, -height/2, base_size)
	])
	
	# Top vertices  
	vertices.append_array([
		Vector3(-top_size, height/2, -top_size),
		Vector3(top_size, height/2, -top_size),
		Vector3(top_size, height/2, top_size),
		Vector3(-top_size, height/2, top_size)
	])
	
	# Create faces
	var face_indices = [
		[0, 1, 5, 4], [1, 2, 6, 5], [2, 3, 7, 6], [3, 0, 4, 7],  # Sides
		[0, 3, 2, 1], [4, 5, 6, 7]  # Bottom and top
	]
	
	for face in face_indices:
		# Convert quads to triangles
		indices.append_array([face[0], face[1], face[2]])
		indices.append_array([face[0], face[2], face[3]])
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func create_star_mesh() -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	
	var points = 6
	var outer_radius = 1.5
	var inner_radius = 0.7
	var depth = 0.3
	
	# Create star shape with depth (front and back faces)
	for face in range(2):
		var z = depth if face == 0 else -depth
		
		# Center vertex for each face
		vertices.append(Vector3(0, 0, z))
		var center_idx = vertices.size() - 1
		
		# Outer and inner vertices
		for i in range(points * 2):
			var angle = (float(i) / float(points * 2)) * PI * 2.0
			var radius = outer_radius if i % 2 == 0 else inner_radius
			vertices.append(Vector3(cos(angle) * radius, sin(angle) * radius, z))
			
			# Create triangles from center
			if i > 0:
				var prev_idx = vertices.size() - 2
				var curr_idx = vertices.size() - 1
				if face == 0:
					indices.append_array([center_idx, prev_idx, curr_idx])
				else:
					indices.append_array([center_idx, curr_idx, prev_idx])  # Reverse winding
		
		# Close the star
		if vertices.size() > center_idx + 2:
			var first_idx = center_idx + 1
			var last_idx = vertices.size() - 1
			if face == 0:
				indices.append_array([center_idx, last_idx, first_idx])
			else:
				indices.append_array([center_idx, first_idx, last_idx])
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func create_crystal_cluster_mesh() -> ArrayMesh:
	# Create a cluster of crystal spikes
	var mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	
	var crystal_count = 5
	var base_radius = 0.8
	
	for crystal in range(crystal_count):
		var angle = (float(crystal) / float(crystal_count)) * PI * 2.0
		var height = randf_range(1.5, 2.5)
		var radius = randf_range(0.2, 0.4)
		
		var base_center = Vector3(cos(angle) * base_radius * 0.3, 0, sin(angle) * base_radius * 0.3)
		var tip = base_center + Vector3(0, height, 0)
		
		var base_start_idx = vertices.size()
		
		# Create crystal base (hexagon)
		for i in range(6):
			var hex_angle = (float(i) / 6.0) * PI * 2.0
			vertices.append(base_center + Vector3(cos(hex_angle) * radius, 0, sin(hex_angle) * radius))
		
		# Add tip vertex
		vertices.append(tip)
		var tip_idx = vertices.size() - 1
		
		# Create faces
		for i in range(6):
			var next_i = (i + 1) % 6
			# Side face
			indices.append_array([base_start_idx + i, tip_idx, base_start_idx + next_i])
			# Base face (if crystal == 0, create shared base)
			if crystal == 0:
				indices.append_array([base_start_idx + next_i, base_start_idx + i, base_start_idx])
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _process(_delta):
	# Update dynamic transparency effects
	update_transparency_waves()

func update_transparency_waves():
	# Create waves of transparency that move through the scene
	var time = Time.get_time_dict_from_system()["second"]
	
	for i in range(alpha_materials.size()):
		var material = alpha_materials[i]
		var obj_pos = alpha_objects[i].position
		
		# Create position-based transparency waves
		var wave_influence = sin(time * transparency_animation_speed + obj_pos.x * 0.2 + obj_pos.z * 0.15) * 0.5 + 0.5
		
		# Update dither size based on wave
		var base_dither = dither_scale
		var wave_dither = base_dither * (0.8 + wave_influence * 0.4)
		
		if material.shader.code.contains("dither_size"):
			material.set_shader_parameter("dither_size", wave_dither)
		elif material.shader.code.contains("stipple_size"):
			material.set_shader_parameter("stipple_size", wave_dither + 1.0)
