shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.8: UV Rotation
// Rotate a cross pattern around center with adjustable angle

uniform float angle : hint_range(-6.28, 6.28) = 0.0;
uniform float auto_rotate : hint_range(0.0, 2.0) = 0.0;
uniform vec3 shape_color : source_color = vec3(0.95, 0.45, 0.15);
uniform vec3 bg_color : source_color = vec3(0.05, 0.05, 0.1);

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;

	// Apply rotation
	float a = angle + TIME * auto_rotate;
	float cs = cos(a);
	float sn = sin(a);
	vec2 rotated = vec2(uv.x * cs - uv.y * sn, uv.x * sn + uv.y * cs);

	// Cross shape on rotated coords
	float cross = 0.0;
	cross = max(cross, (1.0 - smoothstep(0.0, 0.02, abs(rotated.x) - 0.06)) * step(abs(rotated.y), 0.4));
	cross = max(cross, (1.0 - smoothstep(0.0, 0.02, abs(rotated.y) - 0.06)) * step(abs(rotated.x), 0.4));

	// Grid on original coords
	float grid = 0.0;
	for (int i = -2; i <= 2; i++) {
		float pos = float(i) * 0.5;
		grid += (1.0 - smoothstep(0.0, 0.002, abs(uv.x - pos))) * 0.12;
		grid += (1.0 - smoothstep(0.0, 0.002, abs(uv.y - pos))) * 0.12;
	}

	// Angle arc visualization
	float r = length(uv);
	float uv_angle = atan(uv.y, uv.x);
	float arc = 0.0;
	if (r > 0.5 && r < 0.55) {
		float norm_a = mod(a, 6.28318);
		float norm_uv = mod(uv_angle, 6.28318);
		if (norm_uv < norm_a) {
			arc = 0.5;
		}
	}

	vec3 color = bg_color + vec3(grid);
	color += vec3(0.0, 0.3, 0.35) * arc;
	color = mix(color, shape_color, cross);

	ALBEDO = color;
}
