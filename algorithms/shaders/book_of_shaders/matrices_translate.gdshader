shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.8: UV Translation
// Move a cross pattern around UV space with adjustable offset

uniform float offset_x : hint_range(-0.5, 0.5) = 0.0;
uniform float offset_y : hint_range(-0.5, 0.5) = 0.0;
uniform float animate : hint_range(0.0, 1.0) = 0.0;
uniform vec3 shape_color : source_color = vec3(0.0, 0.78, 0.85);
uniform vec3 bg_color : source_color = vec3(0.05, 0.05, 0.1);

void fragment() {
	vec2 uv = UV;

	// Apply translation
	float anim_x = animate * sin(TIME * 0.8) * 0.3;
	float anim_y = animate * cos(TIME * 0.6) * 0.3;
	uv -= vec2(offset_x + anim_x, offset_y + anim_y);

	// Remap to centered coords
	vec2 p = uv * 2.0 - 1.0;

	// Draw a cross shape
	float cross = 0.0;
	cross = max(cross, 1.0 - smoothstep(0.0, 0.02, abs(p.x) - 0.08));
	cross *= step(abs(p.y), 0.3);
	float arm2 = 1.0 - smoothstep(0.0, 0.02, abs(p.y) - 0.08);
	arm2 *= step(abs(p.x), 0.3);
	cross = max(cross, arm2);

	// Original position ghost (subtle)
	vec2 orig = UV * 2.0 - 1.0;
	float ghost = 0.0;
	ghost = max(ghost, (1.0 - smoothstep(0.0, 0.02, abs(orig.x) - 0.08)) * step(abs(orig.y), 0.3));
	ghost = max(ghost, (1.0 - smoothstep(0.0, 0.02, abs(orig.y) - 0.08)) * step(abs(orig.x), 0.3));

	// Grid
	float grid = 0.0;
	for (int i = -4; i <= 4; i++) {
		float pos = float(i) * 0.25;
		grid += (1.0 - smoothstep(0.0, 0.001, abs(UV.x - (pos * 0.5 + 0.5)))) * 0.15;
		grid += (1.0 - smoothstep(0.0, 0.001, abs(UV.y - (pos * 0.5 + 0.5)))) * 0.15;
	}

	vec3 color = bg_color + vec3(grid);
	color = mix(color, shape_color * 0.2, ghost * 0.3);
	color = mix(color, shape_color, cross);

	ALBEDO = color;
}
