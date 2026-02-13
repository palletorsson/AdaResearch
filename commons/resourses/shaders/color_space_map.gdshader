shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_disabled;

uniform float opacity : hint_range(0.0, 1.0) = 0.35;
uniform float grid_density : hint_range(2.0, 24.0) = 8.0;
uniform float grid_thickness : hint_range(0.01, 0.25) = 0.08;
uniform float grid_strength : hint_range(0.0, 1.0) = 0.65;
uniform float emission_strength : hint_range(0.0, 2.0) = 0.45;
uniform float color_lift : hint_range(0.0, 0.5) = 0.1;
uniform vec3 cube_size = vec3(1.0);

varying vec3 local_vertex;

float grid_line(float value, float density, float thickness) {
	float cell = abs(fract(value * density) - 0.5);
	float width = clamp(thickness * 0.5, 0.001, 0.2);
	return 1.0 - smoothstep(width, width + 0.02, cell);
}

void vertex() {
	local_vertex = VERTEX;
}

void fragment() {
	vec3 safe_size = max(cube_size, vec3(0.0001));
	vec3 normalized_local = local_vertex / safe_size;
	vec3 rgb = clamp(normalized_local + vec3(0.5), vec3(0.0), vec3(1.0));

	float gx = grid_line(rgb.x, grid_density, grid_thickness);
	float gy = grid_line(rgb.y, grid_density, grid_thickness);
	float gz = grid_line(rgb.z, grid_density, grid_thickness);
	float grid = max(max(gx, gy), gz);

	vec3 base_color = mix(rgb, vec3(1.0), color_lift);
	vec3 final_color = mix(base_color, vec3(1.0), grid * grid_strength);

	ALBEDO = final_color;
	EMISSION = final_color * (0.2 + grid * grid_strength) * emission_strength;
	METALLIC = 0.0;
	ROUGHNESS = 0.45;

	float alpha = opacity + grid * (1.0 - opacity) * 0.8;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
