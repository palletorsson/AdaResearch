shader_type spatial;

// DRAG EXTRAVAGANZA — The final shader. Everything maxed out.
// Extreme pink, chromatic aberration, iridescence, pulsing, glitter, LOUD.
// This is not subtle. This is not tasteful. This is DRAG.

uniform float pulse_speed : hint_range(0.5, 5.0) = 2.0;
uniform float chrome_strength : hint_range(0.0, 2.0) = 1.0;
uniform float glitter_density : hint_range(10.0, 100.0) = 50.0;
uniform float pink_intensity : hint_range(0.5, 3.0) = 1.5;

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

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p *= 2.0;
		a *= 0.5;
	}
	return v;
}

void vertex() {
	// THROB — the whole surface breathes
	float throb = 1.0 + 0.05 * sin(TIME * pulse_speed * 2.0);
	VERTEX *= throb;

	// Wave displacement
	float wave = sin(VERTEX.x * 3.0 + TIME * pulse_speed) * cos(VERTEX.z * 3.0 + TIME * pulse_speed * 0.7);
	VERTEX.y += wave * 0.03;
}

void fragment() {
	vec2 uv = UV;

	// EXTREME PINK base
	vec3 hot_pink = vec3(1.0, 0.08, 0.58) * pink_intensity;
	vec3 magenta = vec3(1.0, 0.0, 1.0) * pink_intensity;
	vec3 fuchsia = vec3(0.93, 0.0, 0.73) * pink_intensity;

	// Swirling color base
	float swirl = fbm(uv * 3.0 + TIME * 0.3);
	vec3 base = mix(hot_pink, magenta, swirl);
	base = mix(base, fuchsia, fbm(uv * 5.0 - TIME * 0.2));

	// IRIDESCENCE — view-dependent color shift
	float NdotV = dot(normalize(NORMAL), normalize(VIEW));
	float iridescence = 0.5 + 0.5 * sin(NdotV * 12.0 + TIME * pulse_speed);
	vec3 iris_color = vec3(
		0.5 + 0.5 * sin(NdotV * 8.0 + 0.0 + TIME),
		0.5 + 0.5 * sin(NdotV * 8.0 + 2.094 + TIME),
		0.5 + 0.5 * sin(NdotV * 8.0 + 4.188 + TIME)
	);

	// CHROMATIC ABERRATION — fake it by shifting normal-based color
	float chroma_r = smoothstep(0.0, 0.3, NdotV + chrome_strength * 0.1);
	float chroma_b = smoothstep(0.0, 0.3, NdotV - chrome_strength * 0.1);
	vec3 chroma = vec3(chroma_r, NdotV, chroma_b);

	// GLITTER — sparkle points
	vec2 glitter_uv = floor(uv * glitter_density);
	float glitter = hash(glitter_uv + floor(TIME * 8.0));
	glitter = pow(glitter, 20.0); // Most cells dark, rare ones BRIGHT
	vec3 glitter_color = vec3(1.0, 0.8, 0.9) * glitter * 3.0;

	// COMBINE EVERYTHING
	vec3 color = base;
	color = mix(color, iris_color * pink_intensity, 0.3);
	color += chroma * chrome_strength * 0.2;
	color += glitter_color;

	// Pulsing emission — breathe
	float pulse = 0.5 + 0.5 * sin(TIME * pulse_speed);

	ALBEDO = clamp(color, vec3(0.0), vec3(1.0));
	METALLIC = 0.4;
	ROUGHNESS = 0.15;
	SPECULAR = 1.0;
	EMISSION = color * 0.4 * pulse;

	// RIM LIGHT — dramatic edge glow
	float rim = 1.0 - clamp(NdotV, 0.0, 1.0);
	rim = pow(rim, 2.0);
	EMISSION += hot_pink * rim * 0.8;
}
