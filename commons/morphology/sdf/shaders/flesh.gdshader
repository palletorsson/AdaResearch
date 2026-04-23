// flesh.gdshader
// For creature skin, bodies, heads. Subsurface-ish glow via fresnel
// approximation, warm interior color, and a subtle worldspace noise
// pattern that reads as pores or wetness.

shader_type spatial;

uniform vec3 skin_color : source_color = vec3(0.85, 0.68, 0.55);
uniform vec3 interior_color : source_color = vec3(0.95, 0.45, 0.35);
uniform float sss_strength : hint_range(0.0, 1.0) = 0.4;
uniform float rim_power : hint_range(0.5, 6.0) = 3.0;
uniform float pore_scale : hint_range(0.5, 20.0) = 8.0;
uniform float pore_strength : hint_range(0.0, 0.3) = 0.05;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.55;

float hash(vec3 p) {
	return fract(sin(dot(p, vec3(12.9898, 78.233, 45.164))) * 43758.5453);
}

void fragment() {
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	// Fake subsurface: back-rim tinted with interior color.
	vec3 col = mix(skin_color, interior_color, fresnel * sss_strength);

	// Pore variation
	float pores = hash(floor(VERTEX * pore_scale));
	col *= 1.0 - pore_strength * pores;

	ALBEDO = col;
	ROUGHNESS = roughness_val;
	METALLIC = 0.0;
	EMISSION = interior_color * fresnel * sss_strength * 0.2;
}
