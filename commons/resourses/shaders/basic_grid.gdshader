shader_type spatial;

render_mode blend_mix, depth_draw_opaque, cull_back, unshaded;

uniform vec3 line_color : source_color = vec3(0.3, 0.9, 1.0);
uniform vec3 fill_color : source_color = vec3(0.2, 0.2, 0.2);
uniform vec3 alt_color : source_color = vec3(0.5, 0.5, 0.5);
uniform float line_width : hint_range(0.1, 10.0) = 3.5;
uniform float emission_strength : hint_range(0.0, 5.0) = 2.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Use derivatives of world position to detect edges
	vec3 dx = dFdx(world_pos);
	vec3 dy = dFdy(world_pos);

	// Calculate face normal from position derivatives
	vec3 face_normal = normalize(cross(dx, dy));

	// Get view-space position derivatives for edge detection
	vec2 uv_dx = dFdx(UV);
	vec2 uv_dy = dFdy(UV);

	// Calculate edge detection based on UV derivatives
	float edge_x = length(uv_dx);
	float edge_y = length(uv_dy);

	// Create grid pattern based on UV coordinates
	vec2 grid_uv = fract(UV * 100.0);
	float grid_x = smoothstep(0.0, line_width * 0.01, grid_uv.x) * smoothstep(0.0, line_width * 0.01, 1.0 - grid_uv.x);
	float grid_y = smoothstep(0.0, line_width * 0.01, grid_uv.y) * smoothstep(0.0, line_width * 0.01, 1.0 - grid_uv.y);

	float edge_intensity = 1.0 - min(grid_x, grid_y);

	// Use world position to create alternating pattern
	float pattern = sin(world_pos.x * 20.0 + world_pos.y * 20.0 + world_pos.z * 20.0);
	vec3 base_color = (pattern > 0.0) ? fill_color : alt_color;

	// Mix edge and fill colors
	vec3 color = mix(base_color, line_color, edge_intensity);

	ALBEDO = color;
	EMISSION = line_color * edge_intensity * emission_strength;
	ALPHA = 1.0;
}