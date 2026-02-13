shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.10: Animated random
// Time-varying noise — TV static effect

uniform float grid_size : hint_range(5.0, 200.0) = 50.0;
uniform float speed : hint_range(0.1, 30.0) = 10.0;
uniform float color_intensity : hint_range(0.0, 1.0) = 0.0;

float hash(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = floor(UV * grid_size);
	float t = floor(TIME * speed);

	float r = hash(vec3(uv, t));
	float g = hash(vec3(uv + vec2(1.0, 0.0), t));
	float b = hash(vec3(uv + vec2(0.0, 1.0), t));

	vec3 color = mix(vec3(r), vec3(r, g, b), color_intensity);

	// Scanline effect
	float scanline = 0.9 + 0.1 * sin(UV.y * grid_size * 3.14159);
	color *= scanline;

	ALBEDO = color;
}
