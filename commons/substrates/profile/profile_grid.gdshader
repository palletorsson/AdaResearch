shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;

uniform vec4 grid_color : source_color = vec4(0.08, 0.15, 0.08, 0.5);
uniform vec4 axis_color : source_color = vec4(0.15, 0.3, 0.15, 0.8);
uniform float grid_divisions_x : hint_range(1.0, 20.0) = 10.0;
uniform float grid_divisions_y : hint_range(1.0, 20.0) = 8.0;
uniform float line_thickness : hint_range(0.001, 0.02) = 0.004;

void fragment() {
	// UV goes from 0..1 across the grid quad
	float x = UV.x;
	float y = UV.y;

	// Grid lines
	float gx = fract(x * grid_divisions_x);
	float gy = fract(y * grid_divisions_y);

	float line_x = step(gx, line_thickness * grid_divisions_x) + step(1.0 - gx, line_thickness * grid_divisions_x);
	float line_y = step(gy, line_thickness * grid_divisions_y) + step(1.0 - gy, line_thickness * grid_divisions_y);

	float grid = max(line_x, line_y);

	// Center axes (thicker)
	float center_x = smoothstep(0.5 - line_thickness * 2.0, 0.5, x) - smoothstep(0.5, 0.5 + line_thickness * 2.0, x);
	float center_y = smoothstep(0.5 - line_thickness * 2.0, 0.5, y) - smoothstep(0.5, 0.5 + line_thickness * 2.0, y);
	float axes = max(center_x, center_y);

	vec3 col = mix(grid_color.rgb * grid, axis_color.rgb, axes);
	float alpha = max(grid * grid_color.a, axes * axis_color.a);

	ALBEDO = col;
	ALPHA = alpha;
}
