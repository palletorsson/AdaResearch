shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.10: Basic GPU random
// The classic fract(sin(dot())) pseudorandom function

uniform float scale : hint_range(1.0, 500.0) = 100.0;
uniform float seed_x : hint_range(0.0, 100.0) = 12.9898;
uniform float seed_y : hint_range(0.0, 100.0) = 78.233;
uniform float threshold : hint_range(0.0, 1.0) = 0.5;
uniform float show_threshold : hint_range(0.0, 1.0) = 0.0;

float random(vec2 st) {
	return fract(sin(dot(st, vec2(seed_x, seed_y))) * 43758.5453123);
}

void fragment() {
	vec2 uv = UV * scale;

	float r = random(floor(uv) / scale);

	vec3 color;
	if (show_threshold > 0.5) {
		// Black/white based on threshold
		color = vec3(step(threshold, r));
	} else {
		// Raw grayscale noise
		color = vec3(r);
	}

	ALBEDO = color;
}
