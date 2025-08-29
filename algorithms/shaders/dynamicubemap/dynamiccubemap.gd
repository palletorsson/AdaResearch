# DynamicCubemapVR.gd
# A mesmerizing VR scene with real-time reflective surfaces and dynamic cubemaps
extends Node3D

@export var reflective_object_count: int = 8
@export var reflection_update_rate: float = 30.0  # Updates per second
@export var reflection_resolution: int = 256
@export var animation_speed: float = 1.0
@export var metallic_strength: float = 0.95

var reflective_objects: Array[MeshInstance3D] = []
var reflection_probes: Array[ReflectionProbe] = []
var environment_objects: Array[MeshInstance3D] = []
var cubemap_cameras: Array[Camera3D] = []

# Custom reflection shader for enhanced effects
const REFLECTION_SHADER = """
shader_type spatial;
render_mode depth_draw_opaque, cull_disabled, diffuse_lambert, specular_schlick_ggx;

uniform float metallic_factor : hint_range(0.0, 1.0) = 0.95;
uniform float roughness_factor : hint_range(0.0, 1.0) = 0.05;
uniform vec4 base_tint : source_color = vec4(0.9, 0.95, 1.0, 1.0);
uniform float reflection_strength : hint_range(0.5, 2.0) = 1.2;
uniform float fresnel_power : hint_range(1.0, 8.0) = 3.0;
uniform float reflection_distortion : hint_range(0.0, 0.2) = 0.02;
uniform sampler2D reflection_texture;
uniform bool animate_distortion : hint_default(true, true) = true;

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 view_dir = normalize(world_position - (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz);
	vec3 reflect_dir = reflect(view_dir, world_normal);
	
	// Add animated distortion to reflections
	vec2 distortion = vec2(0.0);
	if (animate_distortion) {
		distortion = vec2(
			sin(TIME * 0.8 + world_position.x * 0.1) * reflection_distortion,
			cos(TIME * 1.2 + world_position.z * 0.1) * reflection_distortion
		);
	}
	
	// Sample reflection with distortion
	vec2 reflect_uv = reflect_dir.xy * 0.5 + 0.5 + distortion;
	vec3 reflection = texture(reflection_texture, reflect_uv).rgb;
	
	// Calculate fresnel for realistic reflection falloff
	float fresnel = pow(1.0 - abs(dot(world_normal, -view_dir)), fresnel_power);
	
	// Mix base color with reflection
	vec3 final_color = mix(base_tint.rgb, reflection, fresnel * reflection_strength);
	
	ALBEDO = final_color;
	METALLIC = metallic_factor;
	ROUGHNESS = roughness_factor;
	
	// Add subtle emission for glow
	EMISSION = reflection * 0.1 * fresnel;
}
"""

# Shader for creating dynamic environment textures
const ENVIRONMENT_SHADER = """
shader_type spatial;

uniform vec4 primary_color : source_color = vec4(0.3, 0.6, 1.0, 1.0);
uniform vec4 secondary_color : source_color = vec4(1.0, 0.4, 0.2, 1.0);
uniform float color_shift_speed : hint_range(0.5, 3.0) = 1.5;
uniform float pattern_scale : hint_range(0.1, 2.0) = 0.8;

varying vec3 world_pos;

float noise(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Create animated color patterns for reflections to catch
	vec3 pattern_pos = world_pos * pattern_scale + TIME * color_shift_speed * 0.2;
	float pattern = sin(pattern_pos.x) * cos(pattern_pos.y) * sin(pattern_pos.z);
	pattern = (pattern + 1.0) * 0.5; // Normalize to 0-1
	
	// Add noise for organic variation
	float noise_val = noise(world_pos + TIME * 0.1);
	pattern = mix(pattern, noise_val, 0.3);
	
	// Time-based color shifting
	float time_shift = sin(TIME * color_shift_speed) * 0.5 + 0.5;
	vec3 shifted_primary = mix(primary_color.rgb, secondary_color.rgb, time_shift);
	vec3 shifted_secondary = mix(secondary_color.rgb, primary_color.rgb, time_shift);
	
	vec3 final_color = mix(shifted_primary, shifted_secondary, pattern);
	
	ALBEDO = final_color;
	EMISSION = final_color * 0.2; // Slight glow for better reflections
}
"""

func _ready():
	setup_scene()
	create_environment_objects()
	create_reflective_objects() 
	setup_reflection_probes()
	start_animations()

func setup_scene():
	# Create environment optimized for reflections
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	
	# Rich environment for interesting reflections
	var sky_mat = env.sky.sky_material as ProceduralSkyMaterial
	sky_mat.sky_top_color = Color(0.2, 0.3, 0.8)
	sky_mat.sky_horizon_color = Color(0.8, 0.4, 0.2)
	sky_mat.ground_bottom_color = Color(0.1, 0.2, 0.1)
	sky_mat.ground_horizon_color = Color(0.3, 0.5, 0.3)
	
	env.ambient_light_energy = 0.4
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	
	var camera_env = get_viewport().get_camera_3d()
	if camera_env:
		camera_env.environment = env
	
	# Multiple lights for complex reflections
	create_dynamic_lighting()

func create_dynamic_lighting():
	# Main directional light
	var main_light = DirectionalLight3D.new()
	main_light.position = Vector3(8, 12, 6)
	main_light.look_at(Vector3.ZERO, Vector3.UP)
	main_light.light_energy = 1.2
	main_light.light_color = Color(1.0, 0.95, 0.8)
	add_child(main_light)
	
	# Moving colored lights for dynamic reflections
	for i in range(4):
		var light = OmniLight3D.new()
		light.light_energy = 3.0
		light.omni_range = 20.0
		light.name = "DynamicLight_" + str(i)
		
		var light_colors = [Color.CYAN, Color.MAGENTA, Color.YELLOW, Color.GREEN]
		light.light_color = light_colors[i]
		
		# Position lights
		var angle = i * PI * 0.5
		light.position = Vector3(cos(angle) * 12, 6, sin(angle) * 12)
		
		add_child(light)
		
		# Animate the lights for dynamic reflections
		animate_light(light, i)

func animate_light(light: OmniLight3D, index: int):
	var tween = create_tween()
	tween.set_loops()
	
	# Different movement patterns for each light
	match index:
		0:  # Circular orbit
			tween.tween_method(
				func(t): light.position = Vector3(cos(t) * 10, 8 + sin(t * 2) * 2, sin(t) * 10),
				0.0, PI * 2, 8.0 / animation_speed
			)
		1:  # Vertical figure-8
			tween.tween_method(
				func(t): light.position = Vector3(sin(t * 2) * 6, 4 + sin(t) * 4, cos(t) * 8),
				0.0, PI * 2, 10.0 / animation_speed
			)
		2:  # Spiral
			tween.tween_method(
				func(t): light.position = Vector3(cos(t) * (6 + sin(t * 3) * 2), 6, sin(t) * (6 + cos(t * 3) * 2)),
				0.0, PI * 4, 12.0 / animation_speed
			)
		3:  # Pendulum swing
			tween.tween_method(
				func(t): light.position = Vector3(sin(t) * 8, 5 + cos(t * 3) * 3, cos(t * 0.7) * 6),
				0.0, PI * 2, 6.0 / animation_speed
			)

func create_environment_objects():
	# Create colorful environment objects to be reflected
	for i in range(12):
		var env_object = MeshInstance3D.new()
		
		# Varied geometries for interesting reflections
		var geometries = [
			SphereMesh.new(), BoxMesh.new(), CylinderMesh.new(),
			TorusMesh.new(), create_gem_mesh(), create_pillar_mesh()
		]
		
		env_object.mesh = geometries[i % geometries.size()]
		env_object.name = "EnvObject_" + str(i)
		
		# Position in outer ring
		var angle = (float(i) / 12.0) * PI * 2.0
		var radius = 15.0 + sin(i * 0.8) * 3.0
		env_object.position = Vector3(
			cos(angle) * radius,
			sin(i * 0.6) * 4.0 + 2.0,
			sin(angle) * radius
		)
		
		# Create animated material
		var material = ShaderMaterial.new()
		var shader = Shader.new()
		shader.code = ENVIRONMENT_SHADER
		material.shader = shader
		
		# Set colors
		var hue = (float(i) / 12.0) * 360.0
		var primary = Color.from_hsv(hue / 360.0, 0.8, 1.0)
		var secondary = Color.from_hsv((hue + 120.0) / 360.0, 0.7, 0.9)
		
		material.set_shader_parameter("primary_color", primary)
		material.set_shader_parameter("secondary_color", secondary)
		material.set_shader_parameter("color_shift_speed", randf_range(0.8, 2.2))
		material.set_shader_parameter("pattern_scale", randf_range(0.5, 1.5))
		
		env_object.set_surface_override_material(0, material)
		
		add_child(env_object)
		environment_objects.append(env_object)
		
		# Animate environment objects
		animate_environment_object(env_object, i)

func animate_environment_object(obj: MeshInstance3D, index: int):
	# Gentle rotation for dynamic reflections
	var tween = create_tween()
	tween.set_loops()
	
	var axis = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
	var speed = randf_range(15.0, 35.0) / animation_speed
	
	tween.tween_method(
		func(angle): obj.rotation = axis * angle,
		0.0, PI * 2.0, speed
	)

# Helper functions to create configured primitive meshes
func create_configured_sphere_mesh() -> ArrayMesh:
	var sphere = SphereMesh.new()
	sphere.radial_segments = 10  # Smooth sphere for reflections
	sphere.rings = 6
	sphere.radius = 1.0
	sphere.height = 2.0
	
	# Convert to ArrayMesh
	var mesh = ArrayMesh.new()
	var arrays = sphere.surface_get_arrays(0)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func create_configured_torus_mesh() -> ArrayMesh:
	var torus = TorusMesh.new()
	torus.inner_radius = 0.6
	torus.outer_radius = 1.4
	# Note: TorusMesh in Godot 4 doesn't have radial_segments or rings properties
	# The default subdivision will be used
	
	# Convert to ArrayMesh
	var mesh = ArrayMesh.new()
	var arrays = torus.surface_get_arrays(0)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func create_configured_cylinder_mesh() -> ArrayMesh:
	var cylinder = CylinderMesh.new()
	cylinder.height = 3.0
	cylinder.top_radius = 1.0
	cylinder.bottom_radius = 1.0
	# Note: CylinderMesh in Godot 4 doesn't have radial_segments property
	# The default subdivision will be used
	
	# Convert to ArrayMesh
	var mesh = ArrayMesh.new()
	var arrays = cylinder.surface_get_arrays(0)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh



func create_reflective_objects():
	# Create highly reflective objects that show dynamic reflections
	var reflective_geometries = [
		# Create and configure primitive meshes, then convert to ArrayMesh
		create_configured_sphere_mesh(),
		create_mirror_mesh(),
		create_configured_torus_mesh(),
		create_configured_cylinder_mesh(),
		create_crystal_ball_mesh(),
		create_reflective_panel_mesh()
	]
	
	for i in range(reflective_object_count):
		var reflective_obj = MeshInstance3D.new()
		reflective_obj.mesh = reflective_geometries[i % reflective_geometries.size()]
		reflective_obj.name = "ReflectiveObject_" + str(i)
		
		# Position in inner ring for best reflections
		var angle = (float(i) / float(reflective_object_count)) * PI * 2.0
		var radius = 6.0 + sin(i * 0.4) * 2.0
		reflective_obj.position = Vector3(
			cos(angle) * radius,
			sin(i * 0.5) * 2.0,
			sin(angle) * radius
		)
		
		# Scale for variety
		var scale = randf_range(0.8, 2.0)
		reflective_obj.scale = Vector3(scale, scale, scale)
		
		# Create reflection material
		create_reflection_material(reflective_obj, i)
		
		add_child(reflective_obj)
		reflective_objects.append(reflective_obj)

func create_reflection_material(obj: MeshInstance3D, index: int):
	# Create either standard PBR reflection or custom shader reflection
	if index % 2 == 0:
		# Standard PBR material with high metallic/low roughness
		var material = StandardMaterial3D.new()
		material.metallic = metallic_strength
		material.roughness = 0.05
		material.albedo_color = Color(0.9, 0.95, 1.0)
		
		# Add subtle color tint
		var hue = (float(index) / float(reflective_object_count)) * 360.0
		var tint = Color.from_hsv(hue / 360.0, 0.2, 1.0)
		material.albedo_color = material.albedo_color * tint
		
		obj.set_surface_override_material(0, material)
		
	else:
		# Custom shader with enhanced reflection effects
		var material = ShaderMaterial.new()
		var shader = Shader.new()
		shader.code = REFLECTION_SHADER
		material.shader = shader
		
		var hue = (float(index) / float(reflective_object_count)) * 360.0 + 180.0
		var tint = Color.from_hsv(hue / 360.0, 0.3, 1.0)
		
		material.set_shader_parameter("metallic_factor", metallic_strength)
		material.set_shader_parameter("roughness_factor", 0.02)
		material.set_shader_parameter("base_tint", tint)
		material.set_shader_parameter("reflection_strength", randf_range(1.0, 1.5))
		material.set_shader_parameter("fresnel_power", randf_range(2.0, 5.0))
		material.set_shader_parameter("reflection_distortion", randf_range(0.01, 0.05))
		
		obj.set_surface_override_material(0, material)

func setup_reflection_probes():
	# Create reflection probes for real-time environment capture
	for i in range(reflective_objects.size()):
		var probe = ReflectionProbe.new()
		probe.name = "ReflectionProbe_" + str(i)
		
		# Position probe at reflective object location
		probe.position = reflective_objects[i].position
		
		# Configure probe settings
		probe.size = Vector3(4, 4, 4)  # Capture area
		probe.origin_offset = Vector3.ZERO
		probe.update_mode = ReflectionProbe.UPDATE_ALWAYS  # Real-time updates
		
				# Set quality based on performance needs (Godot 4 doesn't have resolution constants)
		# Instead, adjust the capture area and quality through other properties
		match reflection_resolution:
			128:
				probe.size = Vector3(3, 3, 3)  # Smaller capture area for performance
				probe.max_distance = 8.0
			256:
				probe.size = Vector3(4, 4, 4)  # Medium capture area
				probe.max_distance = 12.0
			512:
				probe.size = Vector3(5, 5, 5)  # Larger capture area for quality
				probe.max_distance = 16.0
			_:
				probe.size = Vector3(4, 4, 4)  # Default medium quality
				probe.max_distance = 12.0
		
		add_child(probe)
		reflection_probes.append(probe)

func start_animations():
	# Animate reflective objects for dynamic reflection changes
	animate_reflective_objects()
	
	# Update reflection probes at specified rate
	start_reflection_updates()

func animate_reflective_objects():
	for i in range(reflective_objects.size()):
		var obj = reflective_objects[i]
		var original_pos = obj.position
		
		# Floating movement
		var float_tween = create_tween()
		float_tween.set_loops()
		
		var float_pattern = i % 3
		match float_pattern:
			0:  # Vertical bobbing
				float_tween.tween_method(
					func(offset): obj.position = original_pos + Vector3(0, sin(offset) * 1.5, 0),
					0.0, PI * 2.0, randf_range(4.0, 8.0) / animation_speed
				)
				
			1:  # Circular floating
				var float_radius = 1.2
				float_tween.tween_method(
					func(t): obj.position = original_pos + Vector3(cos(t) * float_radius, sin(t * 2) * 0.8, sin(t) * float_radius),
					0.0, PI * 2.0, randf_range(6.0, 10.0) / animation_speed
				)
				
			2:  # Figure-8 floating
				float_tween.tween_method(
					func(t): obj.position = original_pos + Vector3(sin(t * 2) * 1.0, sin(t) * 1.2, cos(t) * 0.8),
					0.0, PI * 2.0, randf_range(8.0, 12.0) / animation_speed
				)
		
		# Rotation animation
		var rot_tween = create_tween()
		rot_tween.set_loops()
		
		var rot_axis = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
		rot_tween.tween_method(
			func(angle): obj.rotation = rot_axis * angle,
			0.0, PI * 2.0, randf_range(20.0, 40.0) / animation_speed
		)

func start_reflection_updates():
	# Update reflection probes at specified rate for performance
	var update_timer = Timer.new()
	update_timer.timeout.connect(update_reflections)
	update_timer.wait_time = 1.0 / reflection_update_rate
	update_timer.autostart = true
	add_child(update_timer)

func update_reflections():
	# Force update of reflection probes for real-time reflections
	for probe in reflection_probes:
		if probe and is_instance_valid(probe):
			# Update probe position to follow object if needed
			var obj_index = reflection_probes.find(probe)
			if obj_index >= 0 and obj_index < reflective_objects.size():
				probe.position = reflective_objects[obj_index].position

# Create custom geometric meshes optimized for reflections
func create_mirror_mesh() -> ArrayMesh:
	# Create a flat mirror panel
	var plane = PlaneMesh.new()
	plane.size = Vector2(3.0, 3.0)
	plane.subdivide_width = 1
	plane.subdivide_depth = 1
	
	# Convert PlaneMesh to ArrayMesh
	var mesh = ArrayMesh.new()
	var arrays = plane.surface_get_arrays(0)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func create_crystal_ball_mesh() -> ArrayMesh:
	# High-subdivision sphere for perfect reflections
	var sphere = SphereMesh.new()
	sphere.radial_segments = 12  # High subdivision for smooth reflections
	sphere.rings = 8
	sphere.radius = 1.2
	sphere.height = 2.4
	
	# Convert SphereMesh to ArrayMesh
	var mesh = ArrayMesh.new()
	var arrays = sphere.surface_get_arrays(0)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func create_reflective_panel_mesh() -> ArrayMesh:
	# Curved reflective panel
	var mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	var width_segments = 16
	var height_segments = 8
	var curve_strength = 0.8
	
	for i in range(height_segments + 1):
		for j in range(width_segments + 1):
			var u = float(j) / float(width_segments)
			var v = float(i) / float(height_segments)
			
			var x = (u - 0.5) * 4.0
			var y = (v - 0.5) * 3.0
			var z = sin(u * PI) * curve_strength  # Curved surface
			
			vertices.append(Vector3(x, y, z))
			normals.append(Vector3(-sin(u * PI) * curve_strength, 0, 1).normalized())
			uvs.append(Vector2(u, v))
	
	# Create triangle indices
	for i in range(height_segments):
		for j in range(width_segments):
			var base = i * (width_segments + 1) + j
			
			indices.append_array([
				base, base + width_segments + 1, base + 1,
				base + 1, base + width_segments + 1, base + width_segments + 2
			])
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func create_gem_mesh() -> ArrayMesh:
	# Multi-faceted gem for complex reflections
	var mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	
	# Create gem with multiple facets
	var top = Vector3(0, 1.5, 0)
	var bottom = Vector3(0, -0.5, 0)
	
	# Ring of vertices around middle
	var ring_count = 8
	for i in range(ring_count):
		var angle = (float(i) / float(ring_count)) * PI * 2.0
		vertices.append(Vector3(cos(angle), 0.3, sin(angle)))
	
	vertices.append(top)
	vertices.append(bottom)
	
	var top_idx = vertices.size() - 2
	var bottom_idx = vertices.size() - 1
	
	# Create faceted faces
	for i in range(ring_count):
		var next_i = (i + 1) % ring_count
		
		# Top facets
		indices.append_array([top_idx, i, next_i])
		# Bottom facets  
		indices.append_array([bottom_idx, next_i, i])
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func create_pillar_mesh() -> ArrayMesh:
	# Tall reflective pillar
	var cylinder = CylinderMesh.new()
	cylinder.height = 4.0
	cylinder.top_radius = 0.3
	cylinder.bottom_radius = 0.5
	cylinder.radial_segments = 12
	
	# Convert CylinderMesh to ArrayMesh
	var mesh = ArrayMesh.new()
	var arrays = cylinder.surface_get_arrays(0)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _process(_delta):
	# Update any dynamic reflection effects
	update_reflection_distortions()

func update_reflection_distortions():
	# Optional: Add real-time distortion effects to reflections
	pass
