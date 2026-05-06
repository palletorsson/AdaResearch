shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.5: step() function visualization
// Draws a 2D graph of step(threshold, x) across UV space
// Background shows the step gradient, line draws the function curve

uniform float threshold : hint_range(0.0, 1.0) = 0.5;
uniform float line_width : hint_range(0.001, 0.05) = 0.01;
uniform vec3 bg_color_low : source_color = vec3(0.05, 0.05, 0.1);
uniform vec3 bg_color_high : source_color = vec3(0.0, 0.78, 0.85);
uniform vec3 line_color : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 grid_color : source_color = vec3(0.15, 0.15, 0.2);

void fragment() {
	vec2 uv = UV;

	// The function: y = step(threshold, x)
	float func_val = step(threshold, uv.x);

	// Background gradient showing the output value
	vec3 bg = mix(bg_color_low, bg_color_high, step(threshold, uv.x) * 0.3);

	// Grid lines
	float grid = 0.0;
	grid += step(0.498, uv.x) * step(uv.x, 0.502); // vertical center
	grid += step(0.498, uv.y) * step(uv.y, 0.502); // horizontal center
	// Grid every 0.25
	for (int i = 1; i < 4; i++) {
		float pos = float(i) * 0.25;
		grid += step(pos - 0.001, uv.x) * step(uv.x, pos + 0.001) * 0.3;
		grid += step(pos - 0.001, uv.y) * step(uv.y, pos + 0.001) * 0.3;
	}
	bg = mix(bg, grid_color, clamp(grid, 0.0, 1.0));

	// Draw the function curve: y position is (1.0 - func_val) mapped to UV.y
	// Since step has a discontinuity, draw horizontal segments and vertical jump
	float curve = 0.0;

	// Horizontal line at y=0 for x < threshold
	if (uv.x < threshold - 0.005) {
		float dist_to_line = abs(uv.y - 1.0); // y=0 maps to uv.y=1.0 (bottom)
		curve = 1.0 - smoothstep(0.0, line_width, dist_to_line);
	}

	// Horizontal line at y=1 for x > threshold
	if (uv.x > threshold + 0.005) {
		float dist_to_line = abs(uv.y - 0.0); // y=1 maps to uv.y=0.0 (top)
		curve = max(curve, 1.0 - smoothstep(0.0, line_width, dist_to_line));
	}

	// Vertical jump at threshold
	float dist_to_threshold = abs(uv.x - threshold);
	if (dist_to_threshold < line_width * 0.5) {
		curve = max(curve, 0.6); // Dashed-looking vertical
	}

	// Threshold marker line (vertical, subtle)
	float threshold_line = 1.0 - smoothstep(0.0, 0.003, abs(uv.x - threshold));
	bg = mix(bg, vec3(0.95, 0.45, 0.15), threshold_line * 0.5);

	vec3 final_color = mix(bg, line_color, curve);

	ALBEDO = final_color;
}
