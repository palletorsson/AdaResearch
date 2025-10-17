# WebGLWaterVR.gd
# A mesmerizing VR scene with realistic water surface, reflections and waves
extends Node3D

@export var water_size: float = 50.0
@export var wave_height: float = 1.2
@export var wave_speed: float = 1.0
@export var reflection_quality: float = 0.5
@export var water_clarity: float = 0.8

var water_mesh: MeshInstance3D
var reflection_camera: Camera3D
var reflection_viewport: SubViewport
var water_material: ShaderMaterial

# Realistic water shader with waves, reflections, and refraction
const WATER_SHADER = """
shader_type spatial;
render_mode depth_draw_opaque, cull_disabled, diffuse_lambert, specular_schlick_ggx;

uniform float wave_height : hint_range(0.1, 3.0) = 1.0;
uniform float wave_speed : hint_range(0.1, 3.0) = 1.0;
uniform vec2 wave_direction_1  = vec2(1.0, 0.3);
uniform vec2 wave_direction_2  = vec2(0.2, 1.0);
uniform vec4 water_color_deep : source_color = vec4(0.0, 0.2, 0.5, 1.0);
uniform vec4 water_color_shallow : source_color = vec4(0.4, 0.8, 1.0, 1.0);
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.02;
uniform float fresnel_power : hint_range(1.0, 8.0) = 3.0;
uniform float foam_threshold : hint_range(0.0, 2.0) = 1.2;
uniform vec4 foam_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D reflection_texture : hint_default_black;
uniform float reflection_strength : hint_range(0.0, 1.0) = 0.8;
uniform float clarity : hint_range(0.1, 1.0) = 0.8;

varying vec3 world_position;
varying vec3 world_normal;
varying vec2 reflection_uv;

float wave(vec2 pos, vec2 direction, float amplitude, float frequency, float phase) {
	return amplitude * sin(dot(pos, direction) * frequency + phase);
}

vec3 calculate_wave_normal(vec2 pos, float time) {
	float wave_sample_1 = wave(pos, wave_direction_1, wave_height, 1.0, time * wave_speed);
	float wave_sample_2 = wave(pos, wave_direction_2, wave_height * 0.7, 1.3, time * wave_speed * 1.1);
	
	// Calculate derivatives for normal using finite differences
	float delta = 0.1;
	float dx = wave(pos + vec2(delta, 0.0), wave_direction_1, wave_height, 1.0, time * wave_speed) +
			   wave(pos + vec2(delta, 0.0), wave_direction_2, wave_height * 0.7, 1.3, time * wave_speed * 1.1) -
			   (wave_sample_1 + wave_sample_2);
	float dz = wave(pos + vec2(0.0, delta), wave_direction_1, wave_height, 1.0, time * wave_speed) +
			   wave(pos + vec2(0.0, delta), wave_direction_2, wave_height * 0.7, 1.3, time * wave_speed * 1.1) -
			   (wave_sample_1 + wave_sample_2);
	
	return normalize(vec3(-dx / delta, 1.0, -dz / delta));
}

void vertex() {
	world_position = VERTEX;
	
	// Apply wave displacement
	float wave1 = wave(VERTEX.xz, wave_direction_1, wave_height, 1.0, TIME * wave_speed);
	float wave2 = wave(VERTEX.xz, wave_direction_2, wave_height * 0.7, 1.3, TIME * wave_speed * 1.1);
	float wave3 = wave(VERTEX.xz * 2.0, normalize(vec2(0.5, 1.0)), wave_height * 0.3, 2.5, TIME * wave_speed * 0.8);
	
	world_position.y += wave1 + wave2 + wave3;
	
	// Calculate dynamic normal
	world_normal = calculate_wave_normal(VERTEX.xz, TIME);
	
	VERTEX = world_position;
	NORMAL = world_normal;
	
	// Calculate reflection UV
	vec4 projected = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(world_position, 1.0));
	reflection_uv = (projected.xy / projected.w) * 0.5 + 0.5;
}

void fragment() {
	// Sample reflection texture
	vec3 reflection = texture(reflection_texture, reflection_uv).rgb;
	
	// Calculate water depth effect (fake depth based on position)
	float depth = max(0.0, -world_position.y + 2.0);
	vec3 water_color = mix(water_color_shallow.rgb, water_color_deep.rgb, min(depth * 0.2, 1.0));
	
	// Fresnel effect for realistic water reflection
	vec3 view_dir = normalize(world_position - (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz);
	float fresnel = pow(1.0 - max(dot(world_normal, -view_dir), 0.0), fresnel_power);
	
	// Add foam on wave peaks
	float wave_peak_factor = world_normal.y;
	float foam = smoothstep(foam_threshold, foam_threshold + 0.3, wave_peak_factor + (wave_height * 0.5));
	
	// Mix water color with reflection based on fresnel
	vec3 final_color = mix(water_color, reflection * reflection_strength, fresnel * clarity);
	final_color = mix(final_color, foam_color.rgb, foam * 0.6);
	
	ALBEDO = final_color;
	METALLIC = metallic;
	ROUGHNESS = mix(roughness, 0.8, foam); // Rougher water where there's foam
	
	// Add subtle subsurface scattering effect
	EMISSION = water_color * fresnel * 0.05;
	
	// Alpha based on clarity and foam
	ALPHA = mix(clarity, 1.0, foam);
}
"""

func _ready():
	setup_scene()
	create_water_surface()
	setup_reflection_system()
	start_water_animation()

func setup_scene():
	# Create realistic water environment
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	
	# Beautiful sky for water reflections
	var sky_mat = env.sky.sky_material as ProceduralSkyMaterial
	sky_mat.sky_top_color = Color(0.3, 0.6, 1.0)
	sky_mat.sky_horizon_color = Color(0.8, 0.9, 1.0)
	sky_mat.ground_bottom_color = Color(0.2, 0.4, 0.6)
	sky_mat.ground_horizon_color = Color(0.5, 0.7, 0.8)
	
	env.ambient_light_energy = 0.4
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	
	# Add subtle fog for atmosphere
	env.fog_enabled = true
	env.fog_light_color = Color(0.7, 0.8, 1.0)
	env.fog_light_energy = 0.2
	env.fog_sun_scatter = 0.1
	
	var camera_env = get_viewport().get_camera_3d()
	if camera_env:
		camera_env.environment = env
	
	# Add directional sunlight
	var sun_light = DirectionalLight3D.new()
	sun_light.position = Vector3(15, 20, 10)
	sun_light.look_at_from_position(sun_light.position, Vector3.ZERO, Vector3.UP)
	sun_light.light_energy = 1.0
	sun_light.light_color = Color(1.0, 0.95, 0.8)
	sun_light.shadow_enabled = true
	add_child(sun_light)

func create_water_surface():
	# Create large water plane with high subdivision for smooth waves
	var water_plane = PlaneMesh.new()
	water_plane.size = Vector2(water_size, water_size)
	water_plane.subdivide_width = 150
	water_plane.subdivide_depth = 150
	
	water_mesh = MeshInstance3D.new()
	water_mesh.mesh = water_plane
	water_mesh.name = "WaterSurface"
	
	# Create water material with shader
	water_material = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = WATER_SHADER
	water_material.shader = shader
	
	# Configure water properties
	water_material.set_shader_parameter("wave_height", wave_height)
	water_material.set_shader_parameter("wave_speed", wave_speed)
	water_material.set_shader_parameter("wave_direction_1", Vector2(1.0, 0.3).normalized())
	water_material.set_shader_parameter("wave_direction_2", Vector2(0.2, 1.0).normalized())
	water_material.set_shader_parameter("water_color_deep", Color(0.0, 0.2, 0.5))
	water_material.set_shader_parameter("water_color_shallow", Color(0.4, 0.8, 1.0))
	water_material.set_shader_parameter("metallic", 0.0)
	water_material.set_shader_parameter("roughness", 0.02)
	water_material.set_shader_parameter("fresnel_power", 3.0)
	water_material.set_shader_parameter("foam_threshold", 1.2)
	water_material.set_shader_parameter("foam_color", Color.WHITE)
	water_material.set_shader_parameter("reflection_strength", reflection_quality)
	water_material.set_shader_parameter("clarity", water_clarity)
	
	water_mesh.set_surface_override_material(0, water_material)
	add_child(water_mesh)

func setup_reflection_system():
	# Create reflection viewport and camera
	reflection_viewport = SubViewport.new()
	reflection_viewport.size = Vector2i(512, 512) # Adjustable quality
	reflection_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(reflection_viewport)
	
	reflection_camera = Camera3D.new()
	reflection_camera.name = "ReflectionCamera"
	reflection_viewport.add_child(reflection_camera)
	
	# Set up reflection texture
	var reflection_texture = reflection_viewport.get_texture()
	water_material.set_shader_parameter("reflection_texture", reflection_texture)

func start_water_animation():
	# The water surface animates automatically via shader TIME uniform
	# Start reflection camera animation
	animate_reflection_camera()

func animate_reflection_camera():
	# Update reflection camera to match main camera but mirrored
	var main_camera = get_viewport().get_camera_3d()
	if main_camera and reflection_camera:
		# Position reflection camera as mirror of main camera across water plane
		var cam_pos = main_camera.global_position
		var reflected_pos = Vector3(cam_pos.x, -cam_pos.y, cam_pos.z)
		reflection_camera.global_position = reflected_pos
		
		# Mirror the rotation
		var cam_transform = main_camera.global_transform
		cam_transform.origin = reflected_pos
		cam_transform.basis.y = -cam_transform.basis.y
		cam_transform.basis.z = -cam_transform.basis.z
		reflection_camera.global_transform = cam_transform
		
		# Match camera properties
		reflection_camera.fov = main_camera.fov
		reflection_camera.near = main_camera.near
		reflection_camera.far = main_camera.far

func _process(_delta):
	# Update reflection camera every frame
	animate_reflection_camera()
	
	# Optional: Update water properties based on external conditions
	update_water_conditions()

func update_water_conditions():
	# This function can be used to dynamically adjust water based on weather, time, etc.
	# For now, we'll add some subtle variation
	var time_factor = sin(Time.get_time_dict_from_system()["second"] * 0.1) * 0.1 + 0.9
	water_material.set_shader_parameter("wave_speed", wave_speed * time_factor)

# Additional environment objects for reflection
func add_reflection_objects():
	# Add some objects around the water for interesting reflections
	
	# Floating platforms
	for i in range(4):
		var platform = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(3, 0.3, 3)
		platform.mesh = box
		
		var angle = i * PI * 0.5
		platform.position = Vector3(cos(angle) * 15, 1.5, sin(angle) * 15)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.8, 0.6, 0.4)
		material.roughness = 0.3
		material.metallic = 0.1
		platform.set_surface_override_material(0, material)
		
		add_child(platform)
	
	# Some tall pillars
	for i in range(6):
		var pillar = MeshInstance3D.new()
		var cylinder = CylinderMesh.new()
		cylinder.height = randf_range(5, 12)
		cylinder.top_radius = 0.5
		cylinder.bottom_radius = 0.8
		pillar.mesh = cylinder
		
		var angle = randf() * PI * 2
		var radius = randf_range(20, 35)
		pillar.position = Vector3(cos(angle) * radius, cylinder.height * 0.5, sin(angle) * radius)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.6, 0.7, 0.8)
		material.roughness = 0.8
		pillar.set_surface_override_material(0, material)
		
		add_child(pillar)

# Call this in _ready() if you want environment objects
func _ready_with_environment():
	setup_scene()
	create_water_surface()
	setup_reflection_system()
	add_reflection_objects()
	start_water_animation()
