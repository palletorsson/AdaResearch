shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.11: Simplex noise
// More isotropic than Perlin, uses simplex grid

uniform float scale : hint_range(1.0, 20.0) = 5.0;
uniform int octaves : hint_range(1, 6) = 3;
uniform float persistence : hint_range(0.1, 0.9) = 0.5;
uniform float speed : hint_range(0.0, 2.0) = 0.3;
uniform float colorize : hint_range(0.0, 1.0) = 0.0;

vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec2 mod289_2(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec3 permute(vec3 x) { return mod289((x * 34.0 + 1.0) * x); }

float simplex_noise(vec2 v) {
	const vec4 C = vec4(0.211324865405187, 0.366025403784439,
						-0.577350269189626, 0.024390243902439);
	vec2 i = floor(v + dot(v, C.yy));
	vec2 x0 = v - i + dot(i, C.xx);
	vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
	vec4 x12 = x0.xyxy + C.xxzz;
	x12.xy -= i1;
	i = mod289_2(i);
	vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0)) + i.x + vec3(0.0, i1.x, 1.0));
	vec3 m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.0);
	m = m * m;
	m = m * m;
	vec3 x = 2.0 * fract(p * C.www) - 1.0;
	vec3 h = abs(x) - 0.5;
	vec3 ox = floor(x + 0.5);
	vec3 a0 = x - ox;
	m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);
	vec3 g;
	g.x = a0.x * x0.x + h.x * x0.y;
	g.yz = a0.yz * x12.xz + h.yz * x12.yw;
	return 130.0 * dot(m, g);
}

void fragment() {
	vec2 uv = UV * scale + TIME * speed;

	float value = 0.0;
	float amplitude = 0.5;
	float frequency = 1.0;

	for (int i = 0; i < octaves; i++) {
		value += amplitude * simplex_noise(uv * frequency);
		amplitude *= persistence;
		frequency *= 2.0;
	}
	value = value * 0.5 + 0.5;

	vec3 color;
	if (colorize > 0.5) {
		// Map noise to a cool palette
		color.r = 0.5 + 0.5 * sin(value * 6.28 + 0.0);
		color.g = 0.5 + 0.5 * sin(value * 6.28 + 2.094);
		color.b = 0.5 + 0.5 * sin(value * 6.28 + 4.188);
	} else {
		color = vec3(value);
	}

	ALBEDO = color;
}
