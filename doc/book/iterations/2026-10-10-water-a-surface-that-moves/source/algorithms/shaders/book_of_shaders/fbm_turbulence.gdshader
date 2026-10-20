shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.13: Turbulence
// abs() of noise at each octave — creates flame/smoke-like patterns

uniform float scale : hint_range(1.0, 10.0) = 4.0;
uniform int octaves : hint_range(1, 8) = 5;
uniform float gain : hint_range(0.1, 0.9) = 0.5;
uniform float speed : hint_range(0.0, 2.0) = 0.5;
uniform vec3 color_low : source_color = vec3(0.1, 0.0, 0.2);
uniform vec3 color_high : source_color = vec3(0.95, 0.45, 0.15);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			   mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float turbulence(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	float frequency = 1.0;
	for (int i = 0; i < octaves; i++) {
		value += amplitude * abs(noise(p * frequency) * 2.0 - 1.0);
		frequency *= 2.0;
		amplitude *= gain;
	}
	return value;
}

void fragment() {
	vec2 uv = UV * scale;
	uv.y -= TIME * speed; // Scroll upward like fire

	float f = turbulence(uv);

	vec3 color = mix(color_low, color_high, f);
	// Hot center glow
	color += vec3(1.0, 0.6, 0.2) * smoothstep(0.6, 1.0, f) * 0.5;

	ALBEDO = color;
}
