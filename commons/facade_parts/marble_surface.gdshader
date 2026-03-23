shader_type spatial;
render_mode cull_disabled;

// Procedural marble surface shader.
// Supports Carrara (veined), Siena (swirled), and Breccia styles.

uniform vec4 base_color : source_color = vec4(0.92, 0.90, 0.86, 1.0);
uniform vec4 vein_color : source_color = vec4(0.65, 0.62, 0.58, 1.0);
uniform float vein_scale : hint_range(1.0, 20.0) = 6.0;
uniform float vein_intensity : hint_range(0.0, 1.0) = 0.5;
uniform int vein_style : hint_range(0, 2) = 0; // 0=veined(Carrara), 1=swirled(Siena), 2=breccia
uniform float roughness_base : hint_range(0.0, 1.0) = 0.35;
uniform float wear_amount : hint_range(0.0, 1.0) = 0.1;

// Noise functions
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

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

// Carrara-style veins: linear streaks with fbm distortion
float carrara_veins(vec2 uv) {
	vec2 p = uv * vein_scale;
	// Primary vein direction (mostly horizontal with drift)
	float drift = fbm(p * 0.3 + vec2(50.0, 20.0), 3) * 2.0;
	float vein = sin(p.y * 3.14159 + drift * 4.0);
	// Secondary fine veins
	float fine = sin(p.y * 8.0 + fbm(p * 0.5, 2) * 6.0) * 0.5;
	// Combine
	float combined = abs(vein) * 0.7 + abs(fine) * 0.3;
	return smoothstep(0.1, 0.6, combined);
}

// Siena-style swirls: turbulent flowing curves
float siena_swirls(vec2 uv) {
	vec2 p = uv * vein_scale;
	// Warped coordinates for flowing pattern
	float warp_x = fbm(p * 0.4 + vec2(0.0, 100.0), 4);
	float warp_y = fbm(p * 0.4 + vec2(100.0, 0.0), 4);
	vec2 warped = p + vec2(warp_x, warp_y) * 3.0;
	// Swirl pattern from sin of warped coords
	float swirl = sin(warped.x * 2.0 + warped.y * 1.5) * 0.5 + 0.5;
	// Layer detail
	float detail = fbm(warped * 0.8, 3);
	return mix(swirl, detail, 0.4);
}

// Breccia: angular fragments with different tones
float breccia_pattern(vec2 uv) {
	vec2 p = uv * vein_scale * 0.5;
	// Voronoi-like fragmentation
	vec2 i = floor(p);
	vec2 f = fract(p);
	float min_d = 1.0;
	float cell_val = 0.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 neighbor = vec2(float(x), float(y));
			vec2 point = vec2(hash(i + neighbor), hash(i + neighbor + vec2(37.0, 17.0)));
			float d = length(neighbor + point - f);
			if (d < min_d) {
				min_d = d;
				cell_val = hash(i + neighbor + vec2(73.0, 41.0));
			}
		}
	}
	// Edge darkening (vein between fragments)
	float edge = smoothstep(0.02, 0.08, min_d);
	return mix(0.0, cell_val, edge);
}

void fragment() {
	vec2 world_uv = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz * 2.0;

	float pattern;
	if (vein_style == 0) {
		pattern = carrara_veins(world_uv);
	} else if (vein_style == 1) {
		pattern = siena_swirls(world_uv);
	} else {
		pattern = breccia_pattern(world_uv);
	}

	vec3 color = mix(base_color.rgb, vein_color.rgb, pattern * vein_intensity);

	// Subtle surface variation
	float micro = value_noise(world_uv * 20.0) * 0.03;
	color += vec3(micro);

	// Wear: slight darkening in low spots
	if (wear_amount > 0.001) {
		float wear_noise = fbm(world_uv * 0.5 + vec2(200.0), 2);
		float wear_mask = smoothstep(0.3, 0.7, wear_noise) * wear_amount;
		color = mix(color, color * 0.85, wear_mask * 0.3);
	}

	ALBEDO = color;
	ROUGHNESS = roughness_base + value_noise(world_uv * 10.0) * 0.1;
	METALLIC = 0.0;
}
