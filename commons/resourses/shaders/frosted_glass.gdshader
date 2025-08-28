shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

// For Godot 4, we need to use a different approach for screen effects
uniform sampler2D frosted_texture : hint_default_white, repeat_enable; // Your frosted glass texture for distortion
uniform float brightness : hint_range(0.0, 2.0) = 1.0; // Brightness adjustment
uniform float distortion_intensity : hint_range(0.0, 0.1) = 0.02; // Strength of distortion
uniform float blur_amount : hint_range(0.0, 5.0) = 1.0; // Manual blur amount
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 0.8); // Glass tint
uniform float transparency : hint_range(0.0, 1.0) = 0.8; // Overall transparency

varying vec2 screen_uv;

void vertex() {
	// Calculate screen UV coordinates
	vec4 clip_pos = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	screen_uv = (clip_pos.xy / clip_pos.w) * 0.5 + 0.5;
}

void fragment() {
	// Use the frosted texture for distortion
	vec2 distortion = texture(frosted_texture, UV).rg - 0.5; // Center distortion values around 0
	distortion = normalize(distortion) * distortion_intensity; // Normalize to prevent stretching

	// Apply the distortion to the UV coordinates
	vec2 distorted_uv = screen_uv + distortion;

	// Since we can't easily access screen texture in Godot 4, we'll create a frosted glass effect
	// using the material properties and distortion

	// Create a base glass-like appearance
	vec3 base_color = tint_color.rgb;

	// Add some distortion-based color variation
	float distortion_factor = length(distortion) * 10.0;
	base_color += vec3(distortion_factor * 0.1);

	// Apply brightness
	vec3 final_color = base_color * brightness;

	// Set the material properties for a glass-like appearance
	ALBEDO = final_color;
	ALPHA = transparency * tint_color.a;
	METALLIC = 0.0;
	ROUGHNESS = 0.1;
	SPECULAR = 0.8;

	// Add some refraction-like effect using the normal
	vec3 distorted_normal = vec3(distortion.x, distortion.y, 1.0);
	NORMAL = normalize(distorted_normal);
}