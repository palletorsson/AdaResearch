shader_type spatial;

// QUEER WATER — Dreamy, impossible water in extreme pink/purple
// Not realistic water. Dream water. Memory water. Queer water.

uniform float wave_speed : hint_range(0.5, 3.0) = 1.0;
uniform float wave_scale : hint_range(1.0, 10.0) = 4.0;
uniform float dream_intensity : hint_range(0.0, 2.0) = 1.0;
uniform vec3 deep_color : source_color = vec3(0.3, 0.0, 0.5);
uniform vec3 surface_color : source_color = vec3(1.0, 0.3, 0.8);

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

void vertex() {
	// Dream waves
	float wave1 = sin(VERTEX.x * wave_scale + TIME * wave_speed) * 0.05;
	float wave2 = cos(VERTEX.z * wave_scale * 0.7 + TIME * wave_speed * 1.3) * 0.04;
	float wave3 = sin((VERTEX.x + VERTEX.z) * wave_scale * 0.5 + TIME * wave_speed * 0.8) * 0.03;
	VERTEX.y += wave1 + wave2 + wave3;
}

void fragment() {
	vec2 uv = UV;

	// Flowing noise
	float n1 = noise(uv * wave_scale + TIME * wave_speed * 0.3);
	float n2 = noise(uv * wave_scale * 2.0 - TIME * wave_speed * 0.2);
	float flow = n1 * 0.6 + n2 * 0.4;

	// Color: deep purple to hot pink
	vec3 color = mix(deep_color, surface_color, flow);

	// Iridescent shimmer
	float NdotV = dot(normalize(NORMAL), normalize(VIEW));
	float shimmer = pow(1.0 - NdotV, 3.0);
	vec3 iris = vec3(
		0.5 + 0.5 * sin(NdotV * 6.0 + TIME + 0.0),
		0.5 + 0.5 * sin(NdotV * 6.0 + TIME + 2.0),
		0.5 + 0.5 * sin(NdotV * 6.0 + TIME + 4.0)
	);
	color = mix(color, iris * surface_color, shimmer * dream_intensity * 0.5);

	// Caustic-like patterns
	float caustic = noise(uv * 8.0 + TIME * 0.5);
	caustic = pow(caustic, 3.0) * 2.0;
	color += vec3(1.0, 0.5, 0.8) * caustic * 0.15 * dream_intensity;

	ALBEDO = color;
	ROUGHNESS = 0.05;
	METALLIC = 0.1;
	SPECULAR = 0.8;
	EMISSION = color * 0.15 * dream_intensity;

	// Transparency for that underwater dream feeling
	ALPHA = 0.85;
}
