// Save this as water.shader (or paste into the ShaderMaterial's shader code)
shader_type spatial;

// Use a blend mode for transparency.
render_mode blend_mix, cull_back;

// Uniforms to control water appearance:
uniform float wave_speed : hint_range(0.0, 10.0) = 1.0;
uniform float wave_strength : hint_range(0.0, 1.0) = 0.05;
uniform sampler2D normal_map : hint_normal;
uniform float normal_scale : hint_range(0.0, 2.0) = 0.5;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform vec3 water_color  = vec3(0.0, 0.3, 0.5);
uniform float transparency : hint_range(0.0, 1.0) = 0.5;
uniform float refraction_amount : hint_range(0.0, 0.1) = 0.02;

void fragment() {
	// Time-scaled UV for animated waves.
	vec2 wave_uv = UV + vec2(TIME * wave_speed, TIME * wave_speed);

	// Sample the normal map.
	vec3 normal_sample = texture(normal_map, wave_uv).rgb;
	// Convert from [0,1] to [-1,1]
	normal_sample = normal_sample * 2.0 - 1.0;
	normal_sample.xy *= normal_scale;

	// Combine with the vertex normal.
	vec3 perturbed_normal = normalize(NORMAL + normal_sample);

	// Use the perturbed normal’s xy to offset the screen UV for a refraction effect.
	vec2 screen_uv = SCREEN_UV;
	screen_uv += perturbed_normal.xy * refraction_amount;

	// Sample the screen texture to simulate refracted background.
	vec4 screen_tex = texture(SCREEN_TEXTURE, screen_uv);

	// Mix the water color with the refracted scene.
	// Adjust the mix factor as needed (here 50% refraction).
	vec3 final_color = mix(water_color, screen_tex.rgb, 0.5);

	ALBEDO = final_color;

	// Set alpha to control see-through transparency.
	ALPHA = transparency;

	// Use a low roughness for a shiny water surface.
	ROUGHNESS = 0.05;
	// Use a high specular value.
	SPECULAR = 1.0;
}
