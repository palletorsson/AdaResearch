# postprocessing_bloom.gd
# Scene with bloom post-processing effects and bright glowing objects
extends Node3D

@export var bloom_intensity: float = 1.5
@export var bloom_threshold: float = 0.8
@export var glow_object_count: int = 12
@export var animation_speed: float = 1.0

var bloom_objects: Array[MeshInstance3D] = []
var bloom_materials: Array[ShaderMaterial] = []
var bloom_environment: Environment

# Emissive material shader for bloom objects
const BLOOM_OBJECT_SHADER = """
shader_type spatial;
render_mode depth_draw_opaque, diffuse_lambert, specular_schlick_ggx;

uniform float emission_intensity : hint_range(0.5, 10.0) = 3.0;
uniform vec4 base_color : source_color = vec4(1.0, 0.5, 0.2, 1.0);
uniform vec4 emission_color : source_color = vec4(1.0, 0.8, 0.3, 1.0);
uniform float pulse_speed : hint_range(0.5, 3.0) = 1.5;
uniform float pulse_amount : hint_range(0.0, 2.0) = 0.8;
uniform float metallic : hint_range(0.0, 1.0) = 0.3;
uniform float roughness : hint_range(0.0, 1.0) = 0.4;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Pulsing emission effect
	float pulse = sin(TIME * pulse_speed + world_position.x * 0.1) * pulse_amount + 1.0;
	
	// Distance-based intensity variation
	float distance_factor = 1.0 + sin(world_position.y * 0.2 + TIME * 0.5) * 0.3;
	
	// Final emission calculation
	float total_emission = emission_intensity * pulse * distance_factor;
	
	ALBEDO = base_color.rgb;
	EMISSION = emission_color.rgb * total_emission;
	METALLIC = metallic;
	ROUGHNESS = roughness;
}
"""

# Particle shader for additional bloom sources
const BLOOM_PARTICLE_SHADER = """
shader_type spatial;
render_mode depth_draw_opaque, depth_test_disabled, vertex_lighting, particle_trails, alpha_to_coverage;

uniform float brightness : hint_range(1.0, 20.0) = 8.0;
uniform vec4 particle_color : source_color = vec4(0.3, 0.8, 1.0, 1.0);
uniform float size_variation : hint_range(0.5, 3.0) = 1.5;
uniform float flicker_speed : hint_range(0.5, 5.0) = 2.0;

varying float particle_brightness;

void vertex() {
	// Size variation over time
	float size_pulse = sin(TIME * flicker_speed + VERTEX.x + VERTEX.z) * size_variation + 2.0;
	
	// Make particles face camera
	vec3 camera_pos = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 to_camera = normalize(camera_pos - VERTEX);
	
	vec3 up = vec3(0.0, 1.0, 0.0);
	vec3 right = normalize(cross(to_camera, up));
	up = cross(right, to_camera);
	
	// Billboard with size variation
	vec2 scaled_uv = (UV - vec2(0.5)) * size_pulse;
	VERTEX += right * scaled_uv.x + up * scaled_uv.y;
	
	particle_brightness = size_pulse;
}

void fragment() {
	vec2 centered_uv = UV - vec2(0.5);
	float dist = length(centered_uv);
	
	if (dist > 0.5) {
		discard;
	}
	
	// Soft glow with bright center
	float glow = 1.0 - smoothstep(0.0, 0.5, dist);
	float core = 1.0 - smoothstep(0.0, 0.2, dist);
	
	float final_brightness = brightness * particle_brightness * (glow + core * 2.0);
	
	ALBEDO = particle_color.rgb;
	EMISSION = particle_color.rgb * final_brightness;
	ALPHA = particle_color.a * glow;
}
"""

func _ready():
	setup_bloom_environment()
	create_bloom_objects()
	create_bloom_particles()
	start_bloom_animations()

func setup_bloom_environment():
	# Create environment with bloom post-processing
	bloom_environment = Environment.new()
	bloom_environment.background_mode = Environment.BG_SKY
	bloom_environment.sky = Sky.new()
	bloom_environment.sky.sky_material = ProceduralSkyMaterial.new()
	
	# Dark background to make bloom more visible
	var sky_mat = bloom_environment.sky.sky_material as ProceduralSkyMaterial
	sky_mat.sky_top_color = Color(0.05, 0.05, 0.1)
	sky_mat.sky_horizon_color = Color(0.1, 0.05, 0.15)
	sky_mat.ground_bottom_color = Color(0.02, 0.02, 0.05)
	
	bloom_environment.ambient_light_energy = 0.05
	bloom_environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	
	# Enable bloom/glow post-processing
	bloom_environment.glow_enabled = true
	bloom_environment.glow_intensity = bloom_intensity
	bloom_environment.glow_strength = 1.2
	bloom_environment.glow_bloom = bloom_threshold
	bloom_environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	bloom_environment.glow_hdr_threshold = 1.0
	bloom_environment.glow_hdr_scale = 2.0
	bloom_environment.glow_hdr_luminance_cap = 12.0
	
	# Multi-level bloom for better quality
	# Note: In Godot 4, glow levels are automatically managed by the engine
	# The glow_intensity, glow_strength, and glow_bloom settings control the overall effect
	
	var camera_env = get_viewport().get_camera_3d()
	if camera_env:
		camera_env.environment = bloom_environment

func create_bloom_objects():
	# Create various glowing geometric objects
	var geometries = [
		SphereMesh.new(),
		BoxMesh.new(),
		CylinderMesh.new(),
		TorusMesh.new()
	]
	
	# Configure geometries
	(geometries[0] as SphereMesh).radius = 0.8
	(geometries[1] as BoxMesh).size = Vector3(1.5, 1.5, 1.5)
	(geometries[2] as CylinderMesh).height = 2.0
	(geometries[2] as CylinderMesh).top_radius = 0.6
	(geometries[3] as TorusMesh).inner_radius = 0.4
	(geometries[3] as TorusMesh).outer_radius = 1.0
	
	for i in range(glow_object_count):
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = geometries[i % geometries.size()]
		mesh_instance.name = "BloomObject_" + str(i)
		
		# Position objects in interesting arrangements
		var arrangement = i % 3
		match arrangement:
			0:  # Circular arrangement
				var angle = (float(i) / float(glow_object_count)) * PI * 2.0
				var radius = 8.0 + sin(i * 0.5) * 2.0
				mesh_instance.position = Vector3(
					cos(angle) * radius,
					sin(i * 0.7) * 3.0,
					sin(angle) * radius
				)
			1:  # Vertical column
				mesh_instance.position = Vector3(
					sin(i * 0.8) * 4.0,
					(i % 6) * 1.5 - 4.0,
					cos(i * 0.8) * 4.0
				)
			2:  # Random scatter
				mesh_instance.position = Vector3(
					randf_range(-10.0, 10.0),
					randf_range(-3.0, 6.0),
					randf_range(-10.0, 10.0)
				)
		
		# Scale objects
		var scale = randf_range(0.5, 1.5)
		mesh_instance.scale = Vector3(scale, scale, scale)
		
		# Create bloom material
		var material = ShaderMaterial.new()
		var shader = Shader.new()
		shader.code = BLOOM_OBJECT_SHADER
		material.shader = shader
		
		# Set unique colors and properties
		var hue = (float(i) / float(glow_object_count)) * 360.0 + randf_range(-30.0, 30.0)
		var base_color = Color.from_hsv(hue / 360.0, 0.8, 0.6)
		var emission_color = Color.from_hsv(hue / 360.0, 0.9, 1.0)
		
		material.set_shader_parameter("emission_intensity", randf_range(2.0, 6.0))
		material.set_shader_parameter("base_color", base_color)
		material.set_shader_parameter("emission_color", emission_color)
		material.set_shader_parameter("pulse_speed", randf_range(0.8, 2.5))
		material.set_shader_parameter("pulse_amount", randf_range(0.4, 1.2))
		material.set_shader_parameter("metallic", randf_range(0.1, 0.6))
		material.set_shader_parameter("roughness", randf_range(0.2, 0.7))
		
		mesh_instance.set_surface_override_material(0, material)
		
		add_child(mesh_instance)
		bloom_objects.append(mesh_instance)
		bloom_materials.append(material)

func create_bloom_particles():
	# Create floating bright particles for additional bloom sources
	var particles = GPUParticles3D.new()
	particles.emitting = true
	particles.amount = 200
	particles.lifetime = 8.0
	particles.preprocess = 2.0
	particles.visibility_aabb = AABB(Vector3(-15, -5, -15), Vector3(30, 20, 30))
	
	# Particle mesh
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(0.3, 0.3)
	particles.draw_pass_1 = quad_mesh
	
	# Bloom particle material
	var particle_material = ShaderMaterial.new()
	var particle_shader = Shader.new()
	particle_shader.code = BLOOM_PARTICLE_SHADER
	particle_material.shader = particle_shader
	
	particle_material.set_shader_parameter("brightness", 12.0)
	particle_material.set_shader_parameter("particle_color", Color(0.8, 0.4, 1.0, 0.8))
	particle_material.set_shader_parameter("size_variation", 2.0)
	particle_material.set_shader_parameter("flicker_speed", 3.0)
	
	particles.material_override = particle_material
	
	# Particle behavior
	var process_material = ParticleProcessMaterial.new()
	process_material.direction = Vector3(0, 1, 0)
	process_material.initial_velocity_min = 0.5
	process_material.initial_velocity_max = 2.0
	process_material.gravity = Vector3(0, -0.2, 0)
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_material.emission_box_extents = Vector3(12, 0.5, 12)
	
	# Gentle swirling motion
	process_material.turbulence_enabled = true
	process_material.turbulence_noise_strength = 0.8
	process_material.turbulence_noise_scale = 0.1
	
	particles.process_material = process_material
	particles.position.y = -2
	particles.name = "BloomParticles"
	
	add_child(particles)

func start_bloom_animations():
	# Animate bloom objects
	animate_bloom_objects()
	
	# Animate environment bloom settings
	animate_bloom_settings()

func animate_bloom_objects():
	for i in range(bloom_objects.size()):
		var obj = bloom_objects[i]
		
		# Rotation animation
		var rot_tween = create_tween()
		rot_tween.set_loops()
		var rot_axis = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
		var rot_speed = randf_range(20.0, 40.0) / animation_speed
		rot_tween.tween_method(
			func(angle): obj.rotation = rot_axis * angle,
			0.0, PI * 2.0, rot_speed
		)
		
		# Floating animation
		var original_pos = obj.position
		var float_tween = create_tween()
		float_tween.set_loops()
		var float_height = randf_range(0.5, 1.5)
		var float_speed = randf_range(3.0, 6.0) / animation_speed
		float_tween.tween_method(
			func(offset): obj.position = original_pos + Vector3(0, sin(offset) * float_height, 0),
			0.0, PI * 2.0, float_speed
		)

func animate_bloom_settings():
	# Animate global bloom intensity
	var bloom_tween = create_tween()
	bloom_tween.set_loops()
	bloom_tween.tween_method(
		func(intensity): bloom_environment.glow_intensity = intensity,
		bloom_intensity * 0.5,
		bloom_intensity * 1.5,
		4.0 / animation_speed
	)
	bloom_tween.tween_method(
		func(intensity): bloom_environment.glow_intensity = intensity,
		bloom_intensity * 1.5,
		bloom_intensity * 0.5,
		4.0 / animation_speed
	)
	
	# Animate bloom threshold
	var threshold_tween = create_tween()
	threshold_tween.set_loops()
	threshold_tween.tween_method(
		func(threshold): bloom_environment.glow_bloom = threshold,
		bloom_threshold * 0.6,
		bloom_threshold * 1.2,
		6.0 / animation_speed
	)
	threshold_tween.tween_method(
		func(threshold): bloom_environment.glow_bloom = threshold,
		bloom_threshold * 1.2,
		bloom_threshold * 0.6,
		6.0 / animation_speed
	)

func _process(_delta):
	# Optional: Update bloom based on user input or other factors
	update_dynamic_bloom()

func update_dynamic_bloom():
	# Example: Pulse bloom with time
	var time_factor = sin(Time.get_time_dict_from_system()["second"] * 0.5) * 0.2 + 1.0
	
	# Update material emission intensities
	for material in bloom_materials:
		var base_emission = material.get_shader_parameter("emission_intensity")
		# This creates a subtle global pulse effect
		# material.set_shader_parameter("emission_intensity", base_emission * time_factor)

# Function to add more bloom objects dynamically
func add_bloom_object(position: Vector3, color: Color, intensity: float = 3.0):
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.6
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = sphere_mesh
	mesh_instance.position = position
	
	var material = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = BLOOM_OBJECT_SHADER
	material.shader = shader
	
	material.set_shader_parameter("emission_intensity", intensity)
	material.set_shader_parameter("base_color", color * 0.7)
	material.set_shader_parameter("emission_color", color)
	material.set_shader_parameter("pulse_speed", 1.5)
	material.set_shader_parameter("pulse_amount", 0.6)
	
	mesh_instance.set_surface_override_material(0, material)
	add_child(mesh_instance)
	
	bloom_objects.append(mesh_instance)
	bloom_materials.append(material)

# Preset bloom configurations
func set_bloom_preset(preset: String):
	match preset:
		"subtle":
			bloom_environment.glow_intensity = 0.8
			bloom_environment.glow_bloom = 1.0
			bloom_environment.glow_strength = 0.8
		"dramatic":
			bloom_environment.glow_intensity = 2.5
			bloom_environment.glow_bloom = 0.5
			bloom_environment.glow_strength = 1.8
		"dreamy":
			bloom_environment.glow_intensity = 1.8
			bloom_environment.glow_bloom = 0.6
			bloom_environment.glow_strength = 1.4
			bloom_environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
		"neon":
			bloom_environment.glow_intensity = 3.0
			bloom_environment.glow_bloom = 0.3
			bloom_environment.glow_strength = 2.0
			bloom_environment.glow_hdr_scale = 4.0
		_: # "default"
			bloom_environment.glow_intensity = bloom_intensity
			bloom_environment.glow_bloom = bloom_threshold
			bloom_environment.glow_strength = 1.2
