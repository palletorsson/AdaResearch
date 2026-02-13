shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.11: Gradient (Perlin-like) noise
// Uses random gradient vectors at lattice points

uniform float scale : hint_range(1.0, 20.0) = 5.0;
uniform int octaves : hint_range(1, 8) = 4;
uniform float persistence : hint_range(0.1, 0.9) = 0.5;
uniform float speed : hint_range(0.0, 2.0) = 0.2;
uniform float contrast : hint_range(0.5, 3.0) = 1.5;

vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float gradient_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0); // quintic interpolation

	float a = dot(hash2(i), f);
	float b = dot(hash2(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0));
	float c = dot(hash2(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0));
	float d = dot(hash2(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0));

	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void fragment() {
	vec2 uv = UV * scale + TIME * speed;

	float value = 0.0;
	float amplitude = 0.5;
	float frequency = 1.0;

	for (int i = 0; i < octaves; i++) {
		value += amplitude * gradient_noise(uv * frequency);
		amplitude *= persistence;
		frequency *= 2.0;
	}

	value = value * contrast * 0.5 + 0.5;
	value = clamp(value, 0.0, 1.0);

	ALBEDO = vec3(value);
}
