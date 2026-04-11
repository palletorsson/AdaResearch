shader_type spatial;
render_mode cull_disabled;

// Procedural marble surface shader.
// Supports Carrara (veined), Siena (swirled), and Breccia styles.
// Siena mode uses domain-warped fbm for Giallo di Siena marble
// with warm golden-amber swirling veins on cream/ivory base.

uniform vec4 base_color : source_color = vec4(0.92, 0.90, 0.86, 1.0);
uniform vec4 vein_color : source_color = vec4(0.65, 0.62, 0.58, 1.0);
uniform float vein_scale : hint_range(1.0, 20.0) = 6.0;
uniform float vein_intensity : hint_range(0.0, 1.0) = 0.5;
uniform int vein_style : hint_range(0, 2) = 0; // 0=veined(Carrara), 1=swirled(Siena), 2=breccia
uniform float roughness_base : hint_range(0.0, 1.0) = 0.35;
uniform float wear_amount : hint_range(0.0, 1.0) = 0.1;
uniform float subsurface_strength : hint_range(0.0, 1.0) = 0.0;

// ---------------------------------------------------------------------------
// Noise primitives
// ---------------------------------------------------------------------------

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float hash3(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
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

// Gradient noise (smoother than value noise, better for marble veining)
float grad_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	// Quintic interpolation for smoother results
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
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

// FBM using gradient noise — smoother, better for domain warping
float fbm_smooth(vec2 p, int octaves) {
	float v = 0.0;
	float a = 0.5;
	mat2 rot = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)); // Rotate each octave to break axis alignment
	for (int i = 0; i < octaves; i++) {
		v += a * grad_noise(p);
		p = rot * p * 2.1 + vec2(100.0);
		a *= 0.5;
	}
	return v;
}

// ---------------------------------------------------------------------------
// Carrara-style veins: linear streaks with fbm distortion
// ---------------------------------------------------------------------------

float carrara_veins(vec2 uv) {
	vec2 p = uv * vein_scale;
	float drift = fbm(p * 0.3 + vec2(50.0, 20.0), 3) * 2.0;
	float vein = sin(p.y * 3.14159 + drift * 4.0);
	float fine = sin(p.y * 8.0 + fbm(p * 0.5, 2) * 6.0) * 0.5;
	float combined = abs(vein) * 0.7 + abs(fine) * 0.3;
	return smoothstep(0.1, 0.6, combined);
}

// ---------------------------------------------------------------------------
// Siena-style: domain-warped fbm for Giallo di Siena swirling veins
// Uses double domain warping (warp-the-warp) for organic turbulent flow.
// ---------------------------------------------------------------------------

float siena_swirls(vec2 uv) {
	vec2 p = uv * vein_scale;

	// --- First domain warp layer (large-scale flow) ---
	float warp1_x = fbm_smooth(p * 0.35 + vec2(0.0, 100.0), 5);
	float warp1_y = fbm_smooth(p * 0.35 + vec2(100.0, 0.0), 5);
	vec2 q = p + vec2(warp1_x, warp1_y) * 4.0;

	// --- Second domain warp layer (warp the warp — creates turbulent swirls) ---
	float warp2_x = fbm_smooth(q * 0.45 + vec2(37.2, 81.4), 4);
	float warp2_y = fbm_smooth(q * 0.45 + vec2(64.9, 12.6), 4);
	vec2 r = q + vec2(warp2_x, warp2_y) * 2.5;

	// --- Primary swirl pattern from doubly-warped coordinates ---
	// Multiple sine waves at different angles create flowing vein bands
	float swirl1 = sin(r.x * 1.8 + r.y * 1.2) * 0.5 + 0.5;
	float swirl2 = sin(r.x * 0.7 - r.y * 2.1 + 1.3) * 0.5 + 0.5;
	float primary = mix(swirl1, swirl2, 0.4);

	// --- Fine vein detail layer ---
	// Thinner veins using abs(sin) for sharper lines
	vec2 s = r * 1.5 + vec2(fbm_smooth(r * 0.3, 3) * 2.0);
	float fine_vein = abs(sin(s.x * 3.0 + s.y * 2.0));
	fine_vein = 1.0 - smoothstep(0.0, 0.15, fine_vein); // Narrow bright veins

	// --- Micro turbulence (crystalline texture) ---
	float micro = fbm_smooth(r * 2.0 + vec2(200.0, 150.0), 3);

	// --- Combine layers ---
	float combined = primary * 0.55 + fine_vein * 0.25 + micro * 0.20;

	// Soft contrast shaping
	combined = smoothstep(0.15, 0.85, combined);

	return combined;
}

// ---------------------------------------------------------------------------
// Breccia: angular fragments with different tones
// ---------------------------------------------------------------------------

float breccia_pattern(vec2 uv) {
	vec2 p = uv * vein_scale * 0.5;
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
	float edge = smoothstep(0.02, 0.08, min_d);
	return mix(0.0, cell_val, edge);
}

// ---------------------------------------------------------------------------
// Fragment
// ---------------------------------------------------------------------------

void fragment() {
	// VERTEX in fragment() is in view space; convert to world space via INV_VIEW_MATRIX.
	// Project onto the plane most aligned with the surface normal so the pattern
	// is visible regardless of panel orientation (vertical walls use XY, floors use XZ).
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 world_n = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 abs_n = abs(world_n);
	vec2 world_uv;
	if (abs_n.z >= abs_n.x && abs_n.z >= abs_n.y) {
		world_uv = world_pos.xy;  // facing Z — vertical wall panels
	} else if (abs_n.y >= abs_n.x) {
		world_uv = world_pos.xz;  // facing Y — horizontal / floor panels
	} else {
		world_uv = world_pos.yz;  // facing X — side panels
	}
	world_uv *= 2.0;

	float pattern;
	if (vein_style == 0) {
		pattern = carrara_veins(world_uv);
	} else if (vein_style == 1) {
		pattern = siena_swirls(world_uv);
	} else {
		pattern = breccia_pattern(world_uv);
	}

	vec3 color = mix(base_color.rgb, vein_color.rgb, pattern * vein_intensity);

	// Subtle warm color variation across the surface (large-scale)
	float color_shift = value_noise(world_uv * 1.5 + vec2(50.0)) * 0.04;
	color += vec3(color_shift, color_shift * 0.7, color_shift * 0.3);

	// Micro surface sparkle (crystalline mineral flecks)
	float micro = value_noise(world_uv * 25.0) * 0.025;
	color += vec3(micro);

	// Wear: slight darkening in low spots
	if (wear_amount > 0.001) {
		float wear_noise = fbm(world_uv * 0.5 + vec2(200.0), 2);
		float wear_mask = smoothstep(0.3, 0.7, wear_noise) * wear_amount;
		color = mix(color, color * 0.85, wear_mask * 0.3);
	}

	ALBEDO = color;

	// Polished marble: low roughness with micro-variation
	float roughness_variation = value_noise(world_uv * 12.0) * 0.08;
	ROUGHNESS = roughness_base + roughness_variation;
	METALLIC = 0.0;
	SPECULAR = 0.5;

	// Subsurface scattering hint — gives marble its warm translucent glow
	if (subsurface_strength > 0.001) {
		BACKLIGHT = vec3(subsurface_strength * 0.3);
		// Warm SSS tint — light passing through marble picks up warm amber tone
		SSS_STRENGTH = subsurface_strength;
	}

	// Normal perturbation from pattern gradient (finite differences)
	float eps = 0.005;
	float nx = 0.0;
	float ny = 0.0;
	if (vein_style == 0) {
		nx = carrara_veins(world_uv + vec2(eps, 0.0)) - carrara_veins(world_uv - vec2(eps, 0.0));
		ny = carrara_veins(world_uv + vec2(0.0, eps)) - carrara_veins(world_uv - vec2(0.0, eps));
	} else if (vein_style == 1) {
		nx = siena_swirls(world_uv + vec2(eps, 0.0)) - siena_swirls(world_uv - vec2(eps, 0.0));
		ny = siena_swirls(world_uv + vec2(0.0, eps)) - siena_swirls(world_uv - vec2(0.0, eps));
	}
	// Breccia (style 2) skips normal perturbation — fragment edges are sharp enough
	vec3 perturbed_normal = normalize(vec3(-nx * 0.3, -ny * 0.3, 1.0));
	NORMAL_MAP = perturbed_normal * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 0.4;
}
