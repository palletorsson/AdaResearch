shader_type spatial;
render_mode cull_disabled;

// Mosaic floor aging shader — works with vertex colors from procedural meshes.
// Adds wear, dust, fade, and cracks based on world-space noise.

uniform vec4 base_color : source_color = vec4(0.8, 0.75, 0.65, 1.0);
uniform float wear_amount : hint_range(0.0, 1.0) = 0.3;
uniform float dust_amount : hint_range(0.0, 1.0) = 0.2;
uniform float fade_amount : hint_range(0.0, 1.0) = 0.15;
uniform float crack_density : hint_range(0.0, 1.0) = 0.1;
uniform float roughness_base : hint_range(0.0, 1.0) = 0.75;

// Simple hash for noise
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Value noise
float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractal Brownian motion
float fbm(vec2 p, int octaves) {
	float v = 0.0;
	float a = 0.5;
	vec2 shift = vec2(100.0);
	for (int i = 0; i < octaves; i++) {
		v += a * value_noise(p);
		p = p * 2.0 + shift;
		a *= 0.5;
	}
	return v;
}

// Voronoi for cracks
float voronoi_cracks(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d1 = 1.0;
	float d2 = 1.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 neighbor = vec2(float(x), float(y));
			vec2 point = hash(i + neighbor) * vec2(hash(i + neighbor + vec2(37.0, 17.0)));
			// Use a simpler random for the second component
			point = vec2(hash(i + neighbor), hash(i + neighbor + vec2(53.0, 29.0)));
			float d = length(neighbor + point - f);
			if (d < d1) {
				d2 = d1;
				d1 = d;
			} else if (d < d2) {
				d2 = d;
			}
		}
	}
	return d2 - d1;
}

void fragment() {
	vec3 color = base_color.rgb;
	vec2 world_uv = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz * 8.0;

	float final_roughness = roughness_base;

	// 1. WEAR — slight color shift and darkening from use
	if (wear_amount > 0.001) {
		float wear_noise = fbm(world_uv * 0.5 + vec2(50.0, 30.0), 3);
		float wear_mask = smoothstep(0.3, 0.7, wear_noise) * wear_amount;
		// Darken and warm slightly
		color = mix(color, color * vec3(0.85, 0.82, 0.78), wear_mask * 0.5);
		// Add subtle surface variation
		float micro = value_noise(world_uv * 4.0) * 0.08 * wear_amount;
		color += vec3(micro * 0.5, micro * 0.3, micro * 0.1);
		final_roughness = mix(final_roughness, 0.9, wear_mask * 0.3);
	}

	// 2. DUST — warm sandy overlay in low areas
	if (dust_amount > 0.001) {
		float dust_noise = fbm(world_uv * 0.3 + vec2(200.0, 100.0), 3);
		float dust_mask = smoothstep(0.35, 0.65, dust_noise) * dust_amount;
		vec3 dust_color = vec3(0.72, 0.65, 0.55); // Sandy dust
		color = mix(color, dust_color, dust_mask * 0.3);
		final_roughness = mix(final_roughness, 0.95, dust_mask * 0.2);
	}

	// 3. FADE — desaturation from sun/age
	if (fade_amount > 0.001) {
		float fade_noise = fbm(world_uv * 0.2 + vec2(300.0, 200.0), 2);
		float fade_mask = smoothstep(0.4, 0.7, fade_noise) * fade_amount;
		float luminance = dot(color, vec3(0.299, 0.587, 0.114));
		vec3 faded = mix(color, vec3(luminance), fade_mask * 0.4);
		// Also lighten slightly
		color = mix(color, faded + vec3(0.05), fade_mask * 0.5);
	}

	// 4. CRACKS — thin dark lines
	if (crack_density > 0.001) {
		float cracks = voronoi_cracks(world_uv * 3.0);
		float crack_line = 1.0 - smoothstep(0.0, 0.04 * (1.0 - crack_density * 0.7), cracks);
		float crack_mask = crack_line * crack_density;
		color = mix(color, color * 0.25, crack_mask);
	}

	ALBEDO = color;
	ROUGHNESS = final_roughness;
}
