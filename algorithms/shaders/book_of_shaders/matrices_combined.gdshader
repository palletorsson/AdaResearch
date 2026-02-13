shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.8: Combined transforms
// Translate, rotate, and scale all together — order matters!

uniform float translate_x : hint_range(-0.5, 0.5) = 0.0;
uniform float translate_y : hint_range(-0.5, 0.5) = 0.0;
uniform float rotation : hint_range(-6.28, 6.28) = 0.0;
uniform float scale_val : hint_range(0.3, 3.0) = 1.0;
uniform float auto_animate : hint_range(0.0, 1.0) = 0.0;
uniform vec3 shape_color : source_color = vec3(0.0, 0.78, 0.85);

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;

	// Animation offsets
	float anim_t = TIME * auto_animate;
	float tx = translate_x + sin(anim_t * 0.7) * 0.2 * auto_animate;
	float ty = translate_y + cos(anim_t * 0.5) * 0.2 * auto_animate;
	float rot = rotation + anim_t * 0.5;
	float sc = scale_val + sin(anim_t * 0.3) * 0.3 * auto_animate;

	// Apply transforms: translate → rotate → scale
	uv -= vec2(tx, ty);
	float cs = cos(rot);
	float sn = sin(rot);
	uv = vec2(uv.x * cs - uv.y * sn, uv.x * sn + uv.y * cs);
	uv /= sc;

	// Draw an L-shape (asymmetric, so rotation is visible)
	float d = 1e10;
	// Vertical bar
	vec2 p1 = abs(uv - vec2(-0.1, 0.0));
	d = min(d, max(p1.x - 0.06, p1.y - 0.25));
	// Horizontal bar
	vec2 p2 = abs(uv - vec2(0.05, -0.19));
	d = min(d, max(p2.x - 0.21, p2.y - 0.06));

	float shape = 1.0 - smoothstep(-0.005, 0.005, d);

	// Grid on original space
	vec2 orig = UV * 2.0 - 1.0;
	float grid = 0.0;
	for (int i = -2; i <= 2; i++) {
		float pos = float(i) * 0.5;
		grid += (1.0 - smoothstep(0.0, 0.002, abs(orig.x - pos))) * 0.1;
		grid += (1.0 - smoothstep(0.0, 0.002, abs(orig.y - pos))) * 0.1;
	}

	vec3 bg = vec3(0.05, 0.05, 0.1) + vec3(grid);
	vec3 color = mix(bg, shape_color, shape);

	ALBEDO = color;
}
