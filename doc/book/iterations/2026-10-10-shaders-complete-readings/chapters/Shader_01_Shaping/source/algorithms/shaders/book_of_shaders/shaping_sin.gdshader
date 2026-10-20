shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.5: sin() wave visualization
// Animated sine wave with adjustable frequency and amplitude

uniform float frequency : hint_range(0.5, 10.0) = 3.0;
uniform float amplitude : hint_range(0.1, 0.5) = 0.4;
uniform float phase_speed : hint_range(0.0, 5.0) = 1.0;
uniform float line_width : hint_range(0.002, 0.03) = 0.008;
uniform vec3 bg_color : source_color = vec3(0.05, 0.05, 0.1);
uniform vec3 wave_color : source_color = vec3(0.0, 0.78, 0.85);

void fragment() {
	vec2 uv = UV;

	// sin wave: y = 0.5 + amplitude * sin(frequency * x * TAU + TIME * phase_speed)
	float func_val = 0.5 + amplitude * sin(frequency * uv.x * 6.28318 + TIME * phase_speed);

	// Map to screen coords (inverted y)
	float graph_y = 1.0 - func_val;

	// Background with subtle gradient
	vec3 color = bg_color + vec3(0.02) * uv.y;

	// Center line
	float center_line = 1.0 - smoothstep(0.0, 0.002, abs(uv.y - 0.5));
	color += vec3(0.1) * center_line;

	// Grid
	for (int i = 1; i < 4; i++) {
		float pos = float(i) * 0.25;
		float gx = 1.0 - smoothstep(0.0, 0.001, abs(uv.x - pos));
		float gy = 1.0 - smoothstep(0.0, 0.001, abs(uv.y - pos));
		color += vec3(0.06) * (gx + gy);
	}

	// Draw wave
	float dist = abs(uv.y - graph_y);
	float wave = 1.0 - smoothstep(0.0, line_width, dist);
	color = mix(color, wave_color, wave);

	// Fill below wave with subtle glow
	float fill = smoothstep(graph_y + 0.05, graph_y, uv.y) * 0.15;
	color += wave_color * fill;

	ALBEDO = color;
}
