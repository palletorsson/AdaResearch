shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.5: smoothstep() visualization
// Draws the smoothstep curve with adjustable edge0 and edge1

uniform float edge0 : hint_range(0.0, 1.0) = 0.2;
uniform float edge1 : hint_range(0.0, 1.0) = 0.8;
uniform float line_width : hint_range(0.002, 0.03) = 0.008;
uniform vec3 bg_color : source_color = vec3(0.05, 0.05, 0.1);
uniform vec3 curve_color : source_color = vec3(0.0, 0.78, 0.85);
uniform vec3 fill_color : source_color = vec3(0.0, 0.3, 0.35);

void fragment() {
	vec2 uv = UV;

	// Evaluate smoothstep at this x position
	float func_val = smoothstep(edge0, edge1, uv.x);

	// Map function output to screen y (inverted: 0 at bottom, 1 at top)
	float graph_y = 1.0 - func_val;

	// Fill below the curve
	float fill = step(graph_y, uv.y) * 0.3;
	vec3 color = mix(bg_color, fill_color, fill);

	// Grid
	float grid = 0.0;
	for (int i = 1; i < 4; i++) {
		float pos = float(i) * 0.25;
		grid += step(pos - 0.001, uv.x) * step(uv.x, pos + 0.001) * 0.15;
		grid += step(pos - 0.001, uv.y) * step(uv.y, pos + 0.001) * 0.15;
	}
	color += vec3(grid);

	// Draw the curve
	float dist_to_curve = abs(uv.y - graph_y);
	float curve_line = 1.0 - smoothstep(0.0, line_width, dist_to_curve);
	color = mix(color, curve_color, curve_line);

	// Edge markers
	float e0_line = 1.0 - smoothstep(0.0, 0.003, abs(uv.x - edge0));
	float e1_line = 1.0 - smoothstep(0.0, 0.003, abs(uv.x - edge1));
	color = mix(color, vec3(0.95, 0.45, 0.15), e0_line * 0.6);
	color = mix(color, vec3(0.95, 0.45, 0.15), e1_line * 0.6);

	ALBEDO = color;
}
