shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.5: pow() curve visualization
// Shows y = pow(x, exponent) — from linear to extreme curves

uniform float exponent : hint_range(0.1, 5.0) = 2.0;
uniform float line_width : hint_range(0.002, 0.03) = 0.008;
uniform vec3 bg_color : source_color = vec3(0.05, 0.05, 0.1);
uniform vec3 curve_color : source_color = vec3(0.95, 0.45, 0.15);
uniform vec3 fill_color : source_color = vec3(0.3, 0.15, 0.05);

void fragment() {
	vec2 uv = UV;

	// pow curve: y = pow(x, exponent)
	float func_val = pow(uv.x, exponent);
	float graph_y = 1.0 - func_val;

	// Background
	vec3 color = bg_color;

	// Grid
	for (int i = 1; i < 4; i++) {
		float pos = float(i) * 0.25;
		float gx = 1.0 - smoothstep(0.0, 0.001, abs(uv.x - pos));
		float gy = 1.0 - smoothstep(0.0, 0.001, abs(uv.y - pos));
		color += vec3(0.06) * (gx + gy);
	}

	// Diagonal reference (y = x, i.e. exponent=1)
	float diag = 1.0 - smoothstep(0.0, 0.003, abs(uv.y - (1.0 - uv.x)));
	color += vec3(0.12) * diag;

	// Fill below curve
	float fill = step(graph_y, uv.y) * 0.2;
	color = mix(color, fill_color, fill);

	// Draw the pow curve
	float dist = abs(uv.y - graph_y);
	float curve = 1.0 - smoothstep(0.0, line_width, dist);
	color = mix(color, curve_color, curve);

	ALBEDO = color;
}
