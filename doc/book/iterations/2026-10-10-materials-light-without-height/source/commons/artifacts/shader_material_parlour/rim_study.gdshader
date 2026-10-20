shader_type spatial;
render_mode cull_disabled;

uniform vec4 base_colour : source_color = vec4(0.075, 0.075, 0.10, 1.0);
uniform vec4 edge_colour : source_color = vec4(0.18, 0.84, 0.80, 1.0);
uniform float roughness : hint_range(0.05, 0.95) = 0.28;
uniform float rim_amount : hint_range(0.0, 1.5) = 0.8;

void fragment() {
	// Both built-ins are in view space. The meshes and their collisions stay fixed.
	float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float edge = pow(1.0 - facing, 3.0);
	ALBEDO = base_colour.rgb;
	ROUGHNESS = roughness;
	SPECULAR = 0.6;
	EMISSION = edge_colour.rgb * edge * rim_amount;
}
