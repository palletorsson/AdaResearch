# materials_transmission.gd
# Scene with glass and crystal materials featuring realistic transmission effects
extends Node3D

@export var object_count: int = 8
@export var transmission_strength: float = 1.0
@export var refraction_intensity: float = 0.3
@export var animation_speed: float = 1.0

var transmission_objects: Array[MeshInstance3D] = []
var transmission_materials: Array[ShaderMaterial] = []

# Advanced transmission shader with refraction and reflection
const TRANSMISSION_SHADER = """
shader_type spatial;
render_mode depth_draw_opaque, cull_disabled, diffuse_lambert, specular_schlick_ggx, depth_prepass_alpha;

uniform float transmission : hint_range(0.0, 1.0) = 0.9;
uniform float ior : hint_range(1.0, 3.0) = 1.5;
uniform vec4 base_color : source_color = vec4(0.9, 0.95, 1.0, 0.1);
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.0;
uniform float refraction_strength : hint_range(0.0, 1.0) = 0.5;
uniform sampler2D screen_texture : hint_screen_texture;
uniform sampler2D depth_texture : hint_depth_texture;
uniform float fresnel_power : hint_range(1.0, 8.0) = 3.0;
uniform float thickness : hint_range(0.0, 5.0) = 1.0;
uniform vec4 transmission_color : source_color = vec4(0.8, 0.9, 1.0, 1.0);

varying vec3 world_position;
varying vec3 world_normal;
varying vec3 view_direction;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	
	vec3 camera_pos = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	view_direction = normalize(camera_pos - world_position);
}

void fragment() {
	// Calculate fresnel for realistic glass behavior
	float fresnel = pow(1.0 - max(dot(world_normal, view_direction), 0.0), fresnel_power);
	
	// Get screen UV for refraction sampling
	vec2 screen_uv = SCREEN_UV;
	
	// Calculate refraction offset based on surface normal and view direction
	vec3 refracted_ray = refract(-view_direction, world_normal, 1.0 / ior);
	vec2 refraction_offset = refracted_ray.xy * refraction_strength * 0.1;
	
	// Sample background with refraction offset
	vec2 refracted_uv = screen_uv + refraction_offset;
	refracted_uv = clamp(refracted_uv, 0.0, 1.0);
	vec3 refracted_color = texture(screen_texture, refracted_uv).rgb;
	
	// Apply transmission color tinting
	refracted_color *= transmission_color.rgb;
	
	// Calculate depth-based transmission falloff
	float scene_depth = texture(depth_texture, screen_uv).r;
	float fragment_depth = FRAGCOORD.z;
	float depth_diff = abs(scene_depth - fragment_depth);
	float transmission_factor = exp(-depth_diff * thickness);
	
	// Mix base color with transmitted light
	vec3 transmitted = mix(base_color.rgb, refracted_color, transmission * transmission_factor);
	
	// Reflection component (simplified)
	vec3 reflection = base_color.rgb * fresnel;
	
	// Final color combines transmission and reflection
	vec3 final_color = mix(transmitted, reflection, fresnel * 0.3);
	
	ALBEDO = final_color;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	
	// Fresnel-based alpha for glass-like appearance
	ALPHA = mix(base_color.a, 1.0, fresnel * 0.7);
}
"""

# Simple glass shader for comparison
const SIMPLE_GLASS_SHADER = """
shader_type spatial;
render_mode depth_draw_opaque, cull_disabled, diffuse_lambert, specular_schlick_ggx, depth_prepass_alpha;

uniform float transparency : hint_range(0.0, 1.0) = 0.8;
uniform vec4 glass_color : source_color = vec4(0.9, 0.95, 1.0, 0.2);
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.05;
uniform float rim_power : hint_range(0.5, 4.0) = 2.0;

varying vec3 view_dir;

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 camera_pos = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	view_dir = normalize(camera_pos - world_pos);
}

void fragment() {
	// Simple rim lighting for glass effect
	float rim = 1.0 - abs(dot(NORMAL, view_dir));
	rim = pow(rim, rim_power);
	
	vec3 final_color = glass_color.rgb + rim * 0.5;
	
	ALBEDO = final_color;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	ALPHA = mix(glass_color.a, transparency, rim);
}
"""

# Crystal shader with internal reflections
const CRYSTAL_SHADER = """
shader_type spatial;
render_mode depth_draw_opaque, cull_disabled, diffuse_lambert, specular_schlick_ggx;

uniform vec4 crystal_color : source_color = vec4(0.7, 0.9, 1.0, 0.3);
uniform float internal_reflection : hint_range(0.0, 2.0) = 1.0;
uniform float facet_strength : hint_range(0.0, 2.0) = 0.8;
uniform float sparkle_intensity : hint_range(0.0, 3.0) = 1.5;
uniform float time_scale : hint_range(0.1, 3.0) = 1.0;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	// Create faceted crystal effect
	vec3 facet_normal = normalize(world_normal + sin(world_pos * 5.0) * facet_strength);
	
	// Calculate view direction
	vec3 camera_pos = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 view_dir = normalize(camera_pos - world_pos);
	
	// Internal reflection calculation
	float internal_refl = pow(1.0 - abs(dot(facet_normal, view_dir)), 2.0);
	internal_refl *= internal_reflection;
	
	// Sparkle effect based on facet angles
	float sparkle = sin(world_pos.x * 8.0 + TIME * time_scale) * 
				   sin(world_pos.y * 6.0 + TIME * time_scale * 0.7) *
				   sin(world_pos.z * 10.0 + TIME * time_scale * 1.3);
	sparkle = max(0.0, sparkle) * sparkle_intensity;
	
	// Combine effects
	vec3 final_color = crystal_color.rgb + internal_refl + sparkle;
	
	ALBEDO = final_color;
	METALLIC = 0.0;
	ROUGHNESS = 0.1;
	ALPHA = crystal_color.a;
}
"""

func _ready():
	setup_transmission_environment()
	create_transmission_objects()
	start_transmission_animations()

func setup_transmission_environment():
	# Create environment optimized for transmission materials
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	
	# Bright sky for transmission effects
	var sky_mat = env.sky.sky_material as ProceduralSkyMaterial
	sky_mat.sky_top_color = Color(0.7, 0.8, 1.0)
	sky_mat.sky_horizon_color = Color(0.9, 0.95, 1.0)
	sky_mat.ground_bottom_color = Color(0.8, 0.85, 0.9)
	
	env.ambient_light_energy = 0.4
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	
	# Enable screen-space effects for transmission
	env.ssao_enabled = true
	env.ssao_radius = 2.0
	env.ssao_intensity = 1.0
	
	var camera_env = get_viewport().get_camera_3d()
	if camera_env:
		camera_env.environment = env
	
	# Add directional light for transmission highlights
	var light = DirectionalLight3D.new()
	light.position = Vector3(5, 10, 5)
	light.look_at_from_position(light.position, Vector3.ZERO, Vector3.UP)
	light.light_energy = 1.2
	light.shadow_enabled = true
	add_child(light)

func create_transmission_objects():
	# Create various geometric objects with transmission materials
	var geometries = [
		SphereMesh.new(),
		BoxMesh.new(),
		CylinderMesh.new(),
		TorusMesh.new(),
		PrismMesh.new()
	]
	
	# Configure geometries
	(geometries[0] as SphereMesh).radius = 1.0
	(geometries[1] as BoxMesh).size = Vector3(1.5, 1.5, 1.5)
	(geometries[2] as CylinderMesh).height = 2.0
	(geometries[2] as CylinderMesh).top_radius = 0.6
	(geometries[3] as TorusMesh).inner_radius = 0.4
	(geometries[3] as TorusMesh).outer_radius = 1.0
	(geometries[4] as PrismMesh).left_to_right = 1.5
	(geometries[4] as PrismMesh).size = Vector3(1.5, 2.0, 1.5)
	
	for i in range(object_count):
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = geometries[i % geometries.size()]
		mesh_instance.name = "TransmissionObject_" + str(i)
		
		# Position objects in interesting arrangements
		var angle = (float(i) / float(object_count)) * PI * 2.0
		var radius = 6.0 + sin(i * 0.7) * 2.0
		mesh_instance.position = Vector3(
			cos(angle) * radius,
			sin(i * 0.5) * 2.0,
			sin(angle) * radius
		)
		
		# Scale objects
		var scale = randf_range(0.8, 1.2)
		mesh_instance.scale = Vector3(scale, scale, scale)
		
		# Create transmission material based on object type
		var material = ShaderMaterial.new()
		var shader = Shader.new()
		
		match i % 3:
			0:  # Advanced transmission
				shader.code = TRANSMISSION_SHADER
				material.set_shader_parameter("transmission", transmission_strength)
				material.set_shader_parameter("ior", randf_range(1.3, 1.8))
				material.set_shader_parameter("refraction_strength", refraction_intensity)
				material.set_shader_parameter("fresnel_power", randf_range(2.0, 5.0))
				material.set_shader_parameter("thickness", randf_range(0.5, 2.0))
				
				var hue = randf_range(0.5, 0.7)  # Blue-green range
				var base_color = Color.from_hsv(hue, 0.3, 0.9)
				material.set_shader_parameter("base_color", base_color)
				material.set_shader_parameter("transmission_color", base_color * 1.2)
				
			1:  # Simple glass
				shader.code = SIMPLE_GLASS_SHADER
				material.set_shader_parameter("transparency", transmission_strength)
				material.set_shader_parameter("rim_power", randf_range(1.5, 3.0))
				
				var hue = randf_range(0.55, 0.65)  # Blue range
				var glass_color = Color.from_hsv(hue, 0.2, 0.95)
				material.set_shader_parameter("glass_color", glass_color)
				
			2:  # Crystal
				shader.code = CRYSTAL_SHADER
				material.set_shader_parameter("internal_reflection", randf_range(0.8, 1.5))
				material.set_shader_parameter("facet_strength", randf_range(0.5, 1.2))
				material.set_shader_parameter("sparkle_intensity", randf_range(1.0, 2.5))
				material.set_shader_parameter("time_scale", randf_range(0.8, 2.0))
				
				var hue = randf_range(0.6, 0.8)  # Blue-purple range
				var crystal_color = Color.from_hsv(hue, 0.4, 0.9)
				material.set_shader_parameter("crystal_color", crystal_color)
		
		material.shader = shader
		mesh_instance.set_surface_override_material(0, material)
		
		add_child(mesh_instance)
		transmission_objects.append(mesh_instance)
		transmission_materials.append(material)

func start_transmission_animations():
	# Animate transmission objects
	for i in range(transmission_objects.size()):
		var obj = transmission_objects[i]
		
		# Rotation animation
		var rot_tween = create_tween()
		rot_tween.set_loops()
		var rot_axis = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
		var rot_speed = randf_range(15.0, 30.0) / animation_speed
		rot_tween.tween_method(
			func(angle): obj.rotation = rot_axis * angle,
			0.0, PI * 2.0, rot_speed
		)
		
		# Floating animation
		var original_pos = obj.position
		var float_tween = create_tween()
		float_tween.set_loops()
		var float_height = randf_range(0.3, 0.8)
		var float_speed = randf_range(2.0, 4.0) / animation_speed
		float_tween.tween_method(
			func(offset): obj.position = original_pos + Vector3(0, sin(offset) * float_height, 0),
			0.0, PI * 2.0, float_speed
		)

func _process(_delta):
	# Optional: Update transmission parameters dynamically
	update_dynamic_transmission()

func update_dynamic_transmission():
	# Example: Pulse transmission strength with time
	var time_factor = sin(Time.get_time_dict_from_system()["second"] * 0.3) * 0.1 + 1.0
	
	# Update material transmission parameters
	for i in range(transmission_materials.size()):
		var material = transmission_materials[i]
		var material_type = i % 3
		
		match material_type:
			0:  # Advanced transmission
				var base_transmission = material.get_shader_parameter("transmission")
				material.set_shader_parameter("transmission", base_transmission * time_factor)
			1:  # Simple glass
				var base_transparency = material.get_shader_parameter("transparency")
				material.set_shader_parameter("transparency", base_transparency * time_factor)
			2:  # Crystal
				var base_sparkle = material.get_shader_parameter("sparkle_intensity")
				material.set_shader_parameter("sparkle_intensity", base_sparkle * time_factor)

# Function to add more transmission objects dynamically
func add_transmission_object(position: Vector3, material_type: String = "advanced"):
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.8
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = sphere_mesh
	mesh_instance.position = position
	
	var material = ShaderMaterial.new()
	var shader = Shader.new()
	
	match material_type:
		"advanced":
			shader.code = TRANSMISSION_SHADER
			material.set_shader_parameter("transmission", transmission_strength)
			material.set_shader_parameter("ior", 1.5)
			material.set_shader_parameter("refraction_strength", refraction_intensity)
		"simple":
			shader.code = SIMPLE_GLASS_SHADER
			material.set_shader_parameter("transparency", transmission_strength)
		"crystal":
			shader.code = CRYSTAL_SHADER
			material.set_shader_parameter("sparkle_intensity", 1.5)
	
	material.shader = shader
	mesh_instance.set_surface_override_material(0, material)
	add_child(mesh_instance)
	
	transmission_objects.append(mesh_instance)
	transmission_materials.append(material)

# Preset transmission configurations
func set_transmission_preset(preset: String):
	match preset:
		"subtle":
			transmission_strength = 0.6
			refraction_intensity = 0.2
		"dramatic":
			transmission_strength = 1.0
			refraction_intensity = 0.5
		"crystal_clear":
			transmission_strength = 0.9
			refraction_intensity = 0.4
		_: # "default"
			transmission_strength = 1.0
			refraction_intensity = 0.3
