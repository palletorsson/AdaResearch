shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.13: Ridged multifractal
// abs(noise) creates sharp ridges — mountain-like terrain

uniform float scale : hint_range(1.0, 10.0) = 4.0;
uniform int octaves : hint_range(1, 8) = 5;
uniform float gain : hint_range(0.1, 0.9) = 0.5;
uniform float lacunarity : hint_range(1.5, 3.0) = 2.0;
uniform float sharpness : hint_range(0.5, 3.0) = 1.5;
uniform float speed : hint_range(0.0, 1.0) = 0.1;

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

float ridged_fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	float frequency = 1.0;
	float prev = 1.0;

	for (int i = 0; i < octaves; i++) {
		float n = noise(p * frequency);
		n = 1.0 - abs(n * 2.0 - 1.0); // create ridges
		n = pow(n, sharpness);
		n *= prev; // weight by previous octave for sharper ridges
		value += n * amplitude;
		prev = n;
		frequency *= lacunarity;
		amplitude *= gain;
	}
	return value;
}

void fragment() {
	vec2 uv = UV * scale + TIME * speed;
	float f = ridged_fbm(uv);

	// Dramatic mountain-like coloring
	vec3 color = mix(vec3(0.1, 0.15, 0.3), vec3(0.9, 0.85, 0.8), f);
	color = mix(color, vec3(1.0, 0.95, 0.9), smoothstep(0.7, 1.0, f));

	ALBEDO = color;
}
