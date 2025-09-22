shader_type spatial;
render_mode specular_schlick_ggx, vertex_lighting,  diffuse_burley, depth_draw_opaque, depth_test_disabled, shadows_disabled,  cull_back,  depth_prepass_alpha;

uniform float wave_speed : hint_range(0.01, 2.0) = 0.1;
uniform float wave_strength : hint_range(0.01, 1.0) = 0.163;
uniform float normal_scale : hint_range(0.01, 2.0) = 0.181;
uniform vec3 water_color : source_color = vec3(0.0, 0.3, 0.535);
uniform float transparency : hint_range(0.0, 1.0) = 0.672;
uniform float refraction_amount : hint_range(0.0, 1.0) = 0.03;
uniform sampler2D normal_map : hint_normal;
uniform float fresnel_power : hint_range(0.1, 5.0) = 1.5;
uniform vec3 deep_water_color : source_color = vec3(0.0, 0.1, 0.3);

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;

	// Add vertex wave displacement for more realistic water movement
	float wave_height = sin(world_position.x * 2.0 + TIME * wave_speed) *
	                   cos(world_position.z * 1.5 + TIME * wave_speed * 0.8) *
	                   wave_strength * 0.1;
	VERTEX.y += wave_height;
}

void fragment() {
	vec2 uv = UV;

	// Create animated UV coordinates for normal map sampling
	vec2 uv1 = uv + vec2(TIME * wave_speed * 0.1, TIME * wave_speed * 0.05);
	vec2 uv2 = uv * 1.3 + vec2(-TIME * wave_speed * 0.08, TIME * wave_speed * 0.12);

	// Sample normal map twice for more complex water surface
	vec3 normal1 = texture(normal_map, uv1).rgb;
	vec3 normal2 = texture(normal_map, uv2).rgb;

	// Combine normals
	vec3 normal = normalize(mix(normal1, normal2, 0.5) * 2.0 - 1.0);

	// Create wave effect for additional surface variation
	float wave = sin(uv.x * 10.0 + TIME * wave_speed) * wave_strength;
	wave += sin(uv.y * 8.0 + TIME * wave_speed * 0.7) * wave_strength * 0.5;
	wave += sin((uv.x + uv.y) * 6.0 + TIME * wave_speed * 1.2) * wave_strength * 0.3;

	// Apply normal map influence and wave distortion
	normal.xy *= normal_scale;
	normal.xy += vec2(wave * 0.1);
	normal = normalize(normal);

	// Calculate fresnel effect for more realistic water appearance
	vec3 view_dir = normalize(CAMERA_POSITION_WORLD - world_position);
	float fresnel = pow(1.0 - max(dot(view_dir, normal), 0.0), fresnel_power);

	// Mix water colors based on fresnel and depth
	vec3 final_color = mix(water_color, deep_water_color, fresnel * 0.7);

	// Set material properties
	ALBEDO = final_color;
	NORMAL_MAP = normal;
	ROUGHNESS = mix(0.1, 0.3, fresnel);  // Smoother when viewed straight on
	METALLIC = 0.0;
	ALPHA = mix(transparency, transparency * 0.5, fresnel);  // More transparent at edges

	// Note: REFRACTION property doesn't exist in Godot 4
	// Refraction is handled through material properties instead

	// Add emission for underwater glow and surface highlights
	EMISSION = final_color * (0.1 + fresnel * 0.2);
}