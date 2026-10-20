shader_type spatial;
render_mode unshaded;

// Procedural noise synthesis — Worley, Simplex, and FBM
// Demonstrates different noise functions and their visual characteristics

uniform float noise_scale : hint_range(1.0, 20.0) = 6.0;
uniform float octaves_float : hint_range(1.0, 8.0) = 4.0;
uniform float noise_type : hint_range(0.0, 2.0) = 0.0;
uniform float lacunarity : hint_range(1.5, 3.0) = 2.0;

// ─── Simplex noise helpers ───

vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec2 mod289_2(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec3 permute(vec3 x) { return mod289(((x * 34.0) + 10.0) * x); }

float simplex2d(vec2 v) {
	const vec4 C = vec4(0.211324865405187,  // (3.0 - sqrt(3.0)) / 6.0
	                    0.366025403784439,  // 0.5 * (sqrt(3.0) - 1.0)
	                   -0.577350269189626,  // -1.0 + 2.0 * C.x
	                    0.024390243902439); // 1.0 / 41.0

	// First corner
	vec2 i = floor(v + dot(v, C.yy));
	vec2 x0 = v - i + dot(i, C.xx);

	// Other corners
	vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
	vec4 x12 = x0.xyxy + C.xxzz;
	x12.xy -= i1;

	// Permutations
	i = mod289_2(i);
	vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0)) + i.x + vec3(0.0, i1.x, 1.0));

	vec3 m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.0);
	m = m * m;
	m = m * m;

	// Gradients
	vec3 x_grad = 2.0 * fract(p * C.www) - 1.0;
	vec3 h = abs(x_grad) - 0.5;
	vec3 ox = floor(x_grad + 0.5);
	vec3 a0 = x_grad - ox;

	m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);

	vec3 g;
	g.x = a0.x * x0.x + h.x * x0.y;
	g.yz = a0.yz * x12.xz + h.yz * x12.yw;

	return 130.0 * dot(m, g);
}

// ─── Worley (cellular) noise ───

vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453);
}

float worley(vec2 uv) {
	vec2 cell = floor(uv);
	vec2 frac_uv = fract(uv);
	float min_d = 1.0;

	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 neighbor = vec2(float(x), float(y));
			vec2 point = hash2(cell + neighbor);
			// Subtle animation
			point = 0.5 + 0.45 * sin(TIME * 0.2 + 6.2831 * point);
			vec2 diff = neighbor + point - frac_uv;
			min_d = min(min_d, length(diff));
		}
	}
	return min_d;
}

// ─── Value noise for FBM base ───

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f); // smoothstep

	float a = fract(sin(dot(i, vec2(127.1, 311.7))) * 43758.5453);
	float b = fract(sin(dot(i + vec2(1.0, 0.0), vec2(127.1, 311.7))) * 43758.5453);
	float c = fract(sin(dot(i + vec2(0.0, 1.0), vec2(127.1, 311.7))) * 43758.5453);
	float d = fract(sin(dot(i + vec2(1.0, 1.0), vec2(127.1, 311.7))) * 43758.5453);

	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 uv = UV * noise_scale;
	int octaves = int(round(octaves_float));
	int mode = int(round(noise_type));
	vec3 color;

	if (mode == 0) {
		// Simplex noise with FBM
		float val = 0.0;
		float amp = 0.5;
		float freq = 1.0;
		vec2 p = uv;
		for (int i = 0; i < 8; i++) {
			if (i >= octaves) break;
			val += amp * simplex2d(p * freq);
			freq *= lacunarity;
			amp *= 0.5;
		}
		val = val * 0.5 + 0.5; // remap to 0..1

		// Cool-warm gradient
		vec3 cold = vec3(0.1, 0.2, 0.45);
		vec3 mid = vec3(0.4, 0.7, 0.5);
		vec3 warm = vec3(0.9, 0.6, 0.15);
		if (val < 0.5) {
			color = mix(cold, mid, val * 2.0);
		} else {
			color = mix(mid, warm, (val - 0.5) * 2.0);
		}
	} else if (mode == 1) {
		// Worley noise with FBM
		float val = 0.0;
		float amp = 0.6;
		float freq = 1.0;
		for (int i = 0; i < 8; i++) {
			if (i >= octaves) break;
			val += amp * worley(uv * freq);
			freq *= lacunarity;
			amp *= 0.45;
		}
		val = clamp(val, 0.0, 1.0);

		// Organic purple-teal palette
		vec3 deep = vec3(0.08, 0.05, 0.18);
		vec3 cell_col = vec3(0.15, 0.65, 0.7);
		vec3 bright = vec3(0.9, 0.85, 0.7);
		color = mix(deep, cell_col, smoothstep(0.0, 0.4, val));
		color = mix(color, bright, smoothstep(0.5, 0.9, val));
	} else {
		// Domain-warped simplex — turbulence
		vec2 q = vec2(simplex2d(uv), simplex2d(uv + vec2(5.2, 1.3)));
		vec2 r = vec2(simplex2d(uv + 4.0 * q + vec2(1.7, 9.2) + TIME * 0.05),
		              simplex2d(uv + 4.0 * q + vec2(8.3, 2.8) + TIME * 0.07));

		float val = simplex2d(uv + 4.0 * r) * 0.5 + 0.5;

		// Marble-like palette
		vec3 base = vec3(0.9, 0.88, 0.82);
		vec3 vein = vec3(0.15, 0.12, 0.2);
		vec3 accent = vec3(0.6, 0.3, 0.15);
		float vein_pattern = pow(abs(sin(val * 12.0 + length(q) * 6.0)), 3.0);
		color = mix(base, vein, vein_pattern * 0.7);
		color = mix(color, accent, smoothstep(0.4, 0.6, val) * 0.3);
	}

	ALBEDO = color;
}
