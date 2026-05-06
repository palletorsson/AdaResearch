shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.11: Value noise
// Smooth interpolated noise with octaves control

uniform float scale : hint_range(1.0, 20.0) = 5.0;
uniform int octaves : hint_range(1, 8) = 4;
uniform float persistence : hint_range(0.1, 0.9) = 0.5;
uniform float speed : hint_range(0.0, 2.0) = 0.3;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	// Cubic Hermite for smooth interpolation
	vec2 u = f * f * (3.0 - 2.0 * f);

	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void fragment() {
	vec2 uv = UV * scale + TIME * speed;

	float value = 0.0;
	float amplitude = 0.5;
	float frequency = 1.0;
	float max_val = 0.0;

	for (int i = 0; i < octaves; i++) {
		value += amplitude * value_noise(uv * frequency);
		max_val += amplitude;
		amplitude *= persistence;
		frequency *= 2.0;
	}
	value /= max_val;

	ALBEDO = vec3(value);
}
