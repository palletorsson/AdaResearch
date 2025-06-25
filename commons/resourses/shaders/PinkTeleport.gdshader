shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque, blend_mix, diffuse_burley, specular_schlick_ggx;

// Color parameters
uniform vec4 violet_color : source_color = vec4(0.5, 0.0, 1.0, 1.0);
uniform vec4 pink_color : source_color = vec4(1.0, 0.0, 0.5, 1.0);
uniform vec4 accent_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// Animation parameters
uniform float portal_speed : hint_range(0.1, 5.0) = 2.0;
uniform float pulse_speed : hint_range(0.1, 3.0) = 1.5;
uniform float wave_frequency : hint_range(1.0, 10.0) = 4.0;

// Effect intensity
uniform float energy : hint_range(0.0, 5.0) = 2.0;
uniform float transparency : hint_range(0.0, 1.0) = 0.8;
uniform float rim_power : hint_range(1.0, 6.0) = 3.0;
uniform float distortion_strength : hint_range(0.0, 0.5) = 0.1;

// Texture slots for additional effects
uniform sampler2D noise_texture : source_color, hint_default_black;
uniform sampler2D gradient_texture : source_color, hint_default_white;

varying vec3 world_position;
varying vec3 local_position;
varying vec3 view_direction;

void vertex() {
	world_position = VERTEX;
	local_position = VERTEX;
	view_direction = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 1.0, 0.0)).xyz;
}

void fragment() {
	vec2 uv = UV;
	float time = TIME;

	// Create circular coordinates for portal effect
	vec2 center = vec2(0.5, 0.5);
	vec2 centered_uv = uv - center;
	float radius = length(centered_uv);
	float angle = atan(centered_uv.y, centered_uv.x);

	// Animated spiral effect
	float spiral = sin(radius * wave_frequency - time * portal_speed + angle * 3.0) * 0.5 + 0.5;

	// Pulsing rings
	float rings = sin(radius * 15.0 - time * pulse_speed) * 0.5 + 0.5;
	rings = smoothstep(0.3, 0.7, rings);

	// Color mixing based on radius and spiral
	float color_mix = spiral * (1.0 - radius) + rings * 0.3;
	color_mix = clamp(color_mix, 0.0, 1.0);

	// Blend between violet and pink
	vec3 base_color = mix(violet_color.rgb, pink_color.rgb, color_mix);

	// Add animated highlights
	float highlight = sin(time * 2.0 + radius * 5.0) * 0.5 + 0.5;
	highlight *= (1.0 - radius * 0.8); // Fade towards edges
	base_color = mix(base_color, accent_color.rgb, highlight * 0.3);

	// Create swirling pattern
	vec2 swirl_uv = uv + vec2(
		sin(time * 1.5 + uv.y * 10.0) * distortion_strength,
		cos(time * 1.2 + uv.x * 8.0) * distortion_strength
	);

	// Sample noise for texture variation
	vec3 noise = texture(noise_texture, swirl_uv + time * 0.1).rgb;
	base_color += noise * 0.2;

	// Create rim lighting effect
	vec3 normal = normalize(NORMAL);
	vec3 view_dir = normalize(view_direction);
	float rim = 1.0 - max(dot(normal, view_dir), 0.0);
	rim = pow(rim, rim_power);

	// Apply rim lighting with pink accent
	base_color = mix(base_color, pink_color.rgb * 1.5, rim * 0.4);

	// Portal center glow
	float center_glow = 1.0 - smoothstep(0.0, 0.3, radius);
	center_glow *= sin(time * 3.0) * 0.3 + 0.7; // Pulsing center
	base_color += accent_color.rgb * center_glow * 0.5;

	// Dynamic transparency based on radius and animation
	float alpha = transparency;
	alpha *= (1.0 - radius * 0.3); // More transparent at edges
	alpha *= (spiral * 0.3 + 0.7); // Animated transparency

	// Add energy boost
	base_color *= energy;

	// Final color output
	ALBEDO = base_color;
	ALPHA = alpha;
	EMISSION = base_color * 0.8; // Make it glow

	// Add some roughness variation for interesting reflections
	ROUGHNESS = 0.1 + noise.r * 0.3;
	METALLIC = 0.2;
}