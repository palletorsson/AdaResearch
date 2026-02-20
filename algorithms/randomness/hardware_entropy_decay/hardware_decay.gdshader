shader_type spatial;

// Hardware Entropy Decay Shader
// Driven by real VR hardware inputs: controller velocity, grip, head movement.
// Produces procedural dirt, scratches, rust, and grime on any surface.

// --- Control uniforms (fed from GDScript via VR hardware) ---
uniform float decay_amount : hint_range(0.0, 1.0) = 0.0;        // Overall decay level
uniform float scratch_intensity : hint_range(0.0, 1.0) = 0.0;   // From controller velocity
uniform float grime_buildup : hint_range(0.0, 1.0) = 0.0;       // From grip pressure accumulation
uniform float entropy_rate : hint_range(0.0, 1.0) = 0.0;        // From headset angular velocity
uniform vec2 touch_uv = vec2(0.5, 0.5);                         // Controller position mapped to surface UV
uniform float touch_radius : hint_range(0.0, 0.5) = 0.15;       // Radius of touch influence

// --- Appearance uniforms ---
uniform vec3 base_color : source_color = vec3(0.65, 0.68, 0.72);    // Clean surface color (light steel)
uniform vec3 rust_color : source_color = vec3(0.45, 0.18, 0.05);    // Deep rust/corrosion
uniform vec3 dirt_color : source_color = vec3(0.22, 0.18, 0.12);    // Dark grime
uniform vec3 scratch_color : source_color = vec3(0.82, 0.78, 0.72); // Bright scratch reveal (bare metal)

uniform float base_roughness : hint_range(0.0, 1.0) = 0.35;
uniform float base_metallic : hint_range(0.0, 1.0) = 0.65;
uniform float decay_roughness : hint_range(0.0, 1.0) = 0.92;
uniform float decay_metallic : hint_range(0.0, 1.0) = 0.08;

uniform float noise_scale : hint_range(1.0, 40.0) = 12.0;
uniform float scratch_noise_scale : hint_range(10.0, 200.0) = 80.0;
uniform float time_drift : hint_range(0.0, 1.0) = 0.05;          // Subtle time animation

// --- Hash functions for procedural noise ---
float hash21(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float hash31(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

// --- Value noise (smooth) ---
float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f); // smoothstep

	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));

	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// --- FBM (fractal Brownian motion) for organic noise ---
float fbm(vec2 p, int octaves) {
	float value = 0.0;
	float amplitude = 0.5;
	float frequency = 1.0;
	for (int i = 0; i < octaves; i++) {
		value += amplitude * value_noise(p * frequency);
		amplitude *= 0.5;
		frequency *= 2.0;
	}
	return value;
}

// --- Scratch pattern: directional streaks ---
float scratch_pattern(vec2 uv, float intensity) {
	// Multiple rotated line-noise layers simulate scratches
	float scratches = 0.0;

	// Layer 1: horizontal-ish scratches
	float s1 = value_noise(vec2(uv.x * scratch_noise_scale, uv.y * 8.0));
	s1 = smoothstep(0.72 - intensity * 0.3, 0.78, s1);
	scratches += s1;

	// Layer 2: diagonal scratches
	vec2 rot_uv = vec2(uv.x * 0.7 + uv.y * 0.7, -uv.x * 0.7 + uv.y * 0.7);
	float s2 = value_noise(vec2(rot_uv.x * scratch_noise_scale * 0.8, rot_uv.y * 6.0));
	s2 = smoothstep(0.76 - intensity * 0.25, 0.82, s2);
	scratches += s2 * 0.6;

	// Layer 3: fine micro-scratches
	float s3 = value_noise(uv * scratch_noise_scale * 2.0);
	s3 = smoothstep(0.82 - intensity * 0.18, 0.88, s3);
	scratches += s3 * 0.3;

	return clamp(scratches, 0.0, 1.0);
}

// --- Edge wear: damage concentrates at geometric edges ---
float edge_wear(vec2 uv, float amount) {
	// Simulate wear at UV boundaries and seams
	float edge_x = smoothstep(0.0, 0.08, uv.x) * smoothstep(1.0, 0.92, uv.x);
	float edge_y = smoothstep(0.0, 0.08, uv.y) * smoothstep(1.0, 0.92, uv.y);
	float edge_factor = 1.0 - edge_x * edge_y;
	return edge_factor * amount;
}

// --- Touch influence: localized decay from controller position ---
float touch_influence(vec2 uv) {
	float dist = distance(uv, touch_uv);
	float influence = smoothstep(touch_radius, touch_radius * 0.2, dist);
	return influence;
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * time_drift;

	// ---- Compute decay layers ----

	// 1. Base organic decay (rust/corrosion) - large scale blobs
	float organic_noise = fbm(uv * noise_scale + vec2(t * 0.3, t * 0.17), 5);
	float decay_mask = smoothstep(
		0.5 - decay_amount * 0.55,
		0.5 + decay_amount * 0.15,
		organic_noise
	);

	// 2. Grime accumulation - collects in crevices (inverted high-freq noise)
	float grime_noise = fbm(uv * noise_scale * 1.8 + vec2(t * 0.1, -t * 0.08), 4);
	float grime_mask = smoothstep(0.3, 0.6, grime_noise) * grime_buildup;
	// Grime settles downward (gravity-like bias toward bottom of UV)
	grime_mask *= mix(1.0, 1.5, uv.y);
	grime_mask = clamp(grime_mask, 0.0, 1.0);

	// 3. Scratches - driven by controller velocity
	float scratch_mask = scratch_pattern(uv, scratch_intensity) * scratch_intensity;

	// 4. Touch-localized decay - concentrated where controller points
	float touch = touch_influence(uv);
	float localized_decay = touch * (scratch_intensity + grime_buildup) * 0.5;

	// 5. Edge wear
	float edges = edge_wear(uv, decay_amount * 0.6 + entropy_rate * 0.4);

	// 6. Entropy-driven micro-detail (headset movement adds fine grain)
	float entropy_grain = (hash21(uv * 512.0 + t) - 0.5) * entropy_rate * 0.12;

	// ---- Combine all layers ----

	// Total decay factor
	float total_decay = clamp(
		decay_mask * 0.7 + grime_mask * 0.3 + edges * 0.5 + localized_decay * 0.6,
		0.0, 1.0
	);

	// Color blending
	vec3 color = base_color;

	// Apply rust/corrosion
	color = mix(color, rust_color, decay_mask * decay_amount);

	// Apply grime on top
	color = mix(color, dirt_color, grime_mask);

	// Apply scratches (reveal bare metal underneath)
	color = mix(color, scratch_color, scratch_mask * 0.8);

	// Apply edge wear darkening
	color = mix(color, dirt_color * 0.6, edges);

	// Apply touch-localized tint
	color = mix(color, rust_color * 1.2, localized_decay * 0.4);

	// Add entropy grain
	color += entropy_grain;

	// ---- PBR properties ----
	float roughness = mix(base_roughness, decay_roughness, total_decay);
	// Scratches reduce roughness locally (polished streaks)
	roughness = mix(roughness, base_roughness * 0.7, scratch_mask * 0.5);

	float metallic = mix(base_metallic, decay_metallic, total_decay);
	// Scratches reveal metal underneath
	metallic = mix(metallic, base_metallic * 1.2, scratch_mask * 0.4);

	// ---- Normal perturbation for depth ----
	float bump_strength = 0.15 + decay_amount * 0.35;
	float dx = fbm((uv + vec2(0.001, 0.0)) * noise_scale, 3) - fbm((uv - vec2(0.001, 0.0)) * noise_scale, 3);
	float dy = fbm((uv + vec2(0.0, 0.001)) * noise_scale, 3) - fbm((uv - vec2(0.0, 0.001)) * noise_scale, 3);
	// Scratch normal contribution
	float sdx = value_noise((uv + vec2(0.001, 0.0)) * scratch_noise_scale) - value_noise((uv - vec2(0.001, 0.0)) * scratch_noise_scale);
	float sdy = value_noise((uv + vec2(0.0, 0.001)) * scratch_noise_scale) - value_noise((uv - vec2(0.0, 0.001)) * scratch_noise_scale);

	vec3 normal = normalize(vec3(
		-(dx * bump_strength + sdx * scratch_intensity * 0.2),
		-(dy * bump_strength + sdy * scratch_intensity * 0.2),
		1.0
	));
	NORMAL_MAP = normal * 0.5 + 0.5;

	// ---- Emission: hot spots at freshly decayed areas ----
	float emission_mask = clamp(localized_decay * entropy_rate * 2.0, 0.0, 1.0);
	vec3 emission = mix(vec3(0.0), vec3(0.8, 0.25, 0.05), emission_mask * 0.3);

	// ---- Output ----
	ALBEDO = clamp(color, vec3(0.0), vec3(1.0));
	ROUGHNESS = clamp(roughness, 0.0, 1.0);
	METALLIC = clamp(metallic, 0.0, 1.0);
	EMISSION = emission;
}
