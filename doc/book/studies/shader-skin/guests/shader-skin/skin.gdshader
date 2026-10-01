shader_type spatial;

uniform vec3 body_colour : source_color;
uniform vec3 band_colour : source_color;
uniform float bands : hint_range(1.0, 16.0) = 6.0;
uniform float softness : hint_range(0.01, 0.5) = 0.1;
uniform float drift : hint_range(0.0, 1.0) = 0.0;
uniform float grain : hint_range(0.0, 1.0) = 0.6;
uniform vec3 rim_colour : source_color;
uniform float rim_power : hint_range(0.25, 8.0) = 3.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float low = mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x);
	float high = mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x);
	return mix(low, high, u.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 5; i++) {
		value += amplitude * noise(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	float wave = 0.5 + 0.5 * sin((UV.y * bands + TIME * drift) * TAU);
	float band = smoothstep(0.5 - softness, 0.5 + softness, wave);
	float cloud = fbm(UV * vec2(24.0, 12.0));
	ALBEDO = mix(band_colour, body_colour, band) * mix(1.0, cloud, grain);
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	EMISSION = rim_colour * pow(1.0 - facing, rim_power);
}
