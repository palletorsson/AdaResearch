shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.5: Combined shaping functions
// Overlays step, smoothstep, sin, pow on one graph with blend control

uniform float blend : hint_range(0.0, 1.0) = 0.5;
uniform float threshold : hint_range(0.0, 1.0) = 0.5;
uniform float exponent : hint_range(0.1, 5.0) = 2.0;
uniform float freq : hint_range(0.5, 8.0) = 2.0;
uniform float line_width : hint_range(0.002, 0.02) = 0.006;

void fragment() {
	vec2 uv = UV;
	vec3 bg = vec3(0.05, 0.05, 0.1);

	// Grid
	for (int i = 1; i < 4; i++) {
		float pos = float(i) * 0.25;
		float gx = 1.0 - smoothstep(0.0, 0.001, abs(uv.x - pos));
		float gy = 1.0 - smoothstep(0.0, 0.001, abs(uv.y - pos));
		bg += vec3(0.05) * (gx + gy);
	}

	// Four functions
	float f_step = step(threshold, uv.x);
	float f_smooth = smoothstep(threshold - 0.2, threshold + 0.2, uv.x);
	float f_sin = 0.5 + 0.5 * sin(freq * uv.x * 6.28318 + TIME);
	float f_pow = pow(uv.x, exponent);

	// Draw each as a colored line
	vec3 color = bg;

	// step — red
	float d1 = abs(uv.y - (1.0 - f_step));
	float l1 = 1.0 - smoothstep(0.0, line_width, d1);
	color = mix(color, vec3(0.9, 0.2, 0.2), l1 * 0.8);

	// smoothstep — cyan
	float d2 = abs(uv.y - (1.0 - f_smooth));
	float l2 = 1.0 - smoothstep(0.0, line_width, d2);
	color = mix(color, vec3(0.0, 0.78, 0.85), l2 * 0.8);

	// sin — green
	float d3 = abs(uv.y - (1.0 - f_sin));
	float l3 = 1.0 - smoothstep(0.0, line_width, d3);
	color = mix(color, vec3(0.2, 0.9, 0.3), l3 * 0.8);

	// pow — orange
	float d4 = abs(uv.y - (1.0 - f_pow));
	float l4 = 1.0 - smoothstep(0.0, line_width, d4);
	color = mix(color, vec3(0.95, 0.45, 0.15), l4 * 0.8);

	// Blended function (interpolate between all four)
	float blended = mix(mix(f_step, f_smooth, blend), mix(f_sin, f_pow, blend), blend);
	float db = abs(uv.y - (1.0 - blended));
	float lb = 1.0 - smoothstep(0.0, line_width * 1.5, db);
	color = mix(color, vec3(1.0, 1.0, 1.0), lb);

	ALBEDO = color;
}
