shader_type spatial;

uniform vec4 base_color : source_color = vec4(0.92, 0.9, 0.87, 1.0);
uniform vec4 vein_color : source_color = vec4(0.4, 0.38, 0.35, 1.0);
uniform float vein_scale : hint_range(1.0, 20.0) = 8.0;
uniform float vein_intensity : hint_range(0.0, 1.0) = 0.6;
uniform float roughness : hint_range(0.0, 1.0) = 0.25;
uniform float normal_strength : hint_range(0.0, 2.0) = 0.5;
uniform float subsurface_strength : hint_range(0.0, 1.0) = 0.15;

// ---- Simplex-style 3D noise (hash-based) ----

vec3 mod289_3(vec3 x) {
	return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 mod289_4(vec4 x) {
	return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x) {
	return mod289_4(((x * 34.0) + 10.0) * x);
}

vec4 taylor_inv_sqrt(vec4 r) {
	return 1.79284291400159 - 0.85373472095314 * r;
}

// Classic 3D simplex noise by Ashima Arts (Stefan Gustavson)
float snoise(vec3 v) {
	const vec2 C = vec2(1.0 / 6.0, 1.0 / 3.0);
	const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);

	vec3 i = floor(v + dot(v, C.yyy));
	vec3 x0 = v - i + dot(i, C.xxx);

	vec3 g = step(x0.yzx, x0.xyz);
	vec3 l = 1.0 - g;
	vec3 i1 = min(g.xyz, l.zxy);
	vec3 i2 = max(g.xyz, l.zxy);

	vec3 x1 = x0 - i1 + C.xxx;
	vec3 x2 = x0 - i2 + C.yyy;
	vec3 x3 = x0 - D.yyy;

	i = mod289_3(i);
	vec4 p = permute(permute(permute(
		i.z + vec4(0.0, i1.z, i2.z, 1.0))
		+ i.y + vec4(0.0, i1.y, i2.y, 1.0))
		+ i.x + vec4(0.0, i1.x, i2.x, 1.0));

	float n_ = 0.142857142857;
	vec3 ns = n_ * D.wyz - D.xzx;

	vec4 j = p - 49.0 * floor(p * ns.z * ns.z);

	vec4 x_ = floor(j * ns.z);
	vec4 y_ = floor(j - 7.0 * x_);

	vec4 x = x_ * ns.x + ns.yyyy;
	vec4 y = y_ * ns.x + ns.yyyy;
	vec4 h = 1.0 - abs(x) - abs(y);

	vec4 b0 = vec4(x.xy, y.xy);
	vec4 b1 = vec4(x.zw, y.zw);

	vec4 s0 = floor(b0) * 2.0 + 1.0;
	vec4 s1 = floor(b1) * 2.0 + 1.0;
	vec4 sh = -step(h, vec4(0.0));

	vec4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
	vec4 a1 = b1.xzyw + s1.xzyw * sh.zzww;

	vec3 p0 = vec3(a0.xy, h.x);
	vec3 p1 = vec3(a0.zw, h.y);
	vec3 p2 = vec3(a1.xy, h.z);
	vec3 p3 = vec3(a1.zw, h.w);

	vec4 norm = taylor_inv_sqrt(vec4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
	p0 *= norm.x;
	p1 *= norm.y;
	p2 *= norm.z;
	p3 *= norm.w;

	vec4 m = max(0.5 - vec4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
	m = m * m;
	return 105.0 * dot(m * m, vec4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)));
}

// ---- Domain-warped FBM for swirling marble veins ----

// FBM with octave rotation to break axis alignment
float fbm_marble(vec3 p, int octaves) {
	float value = 0.0;
	float amplitude = 0.5;
	float frequency = 1.0;

	for (int i = 0; i < octaves; i++) {
		value += amplitude * snoise(p * frequency);
		// Rotate sampling direction each octave
		p = vec3(
			p.x * 0.8 - p.z * 0.6,
			p.y,
			p.x * 0.6 + p.z * 0.8
		) + vec3(100.0);
		frequency *= 2.1;
		amplitude *= 0.47;
	}
	return value;
}

// Directional FBM — stretched along one axis for vein flow
float fbm_vein(vec3 p) {
	vec3 stretched = vec3(p.x * 0.5, p.y * 2.0, p.z * 0.7);
	return fbm_marble(stretched, 5);
}

// Domain-warped veining — warp coordinates with fbm, then sample fbm again
float domain_warped_veins(vec3 p) {
	// First warp layer
	float warp_x = fbm_marble(p + vec3(0.0, 0.0, 100.0), 4);
	float warp_y = fbm_marble(p + vec3(100.0, 0.0, 0.0), 4);
	float warp_z = fbm_marble(p + vec3(0.0, 100.0, 0.0), 4);
	vec3 q = p + vec3(warp_x, warp_y, warp_z) * 2.5;

	// Second warp layer (warp the warp) for extra turbulence
	float warp2_x = fbm_marble(q * 0.8 + vec3(37.2, 81.4, 12.8), 3);
	float warp2_y = fbm_marble(q * 0.8 + vec3(64.9, 12.6, 53.1), 3);
	vec3 r = q + vec3(warp2_x, warp2_y, 0.0) * 1.5;

	return fbm_vein(r);
}

// Secondary turbulence layer for fine detail
float turbulence(vec3 p) {
	float value = 0.0;
	float amplitude = 0.5;
	float frequency = 1.0;

	for (int i = 0; i < 3; i++) {
		value += amplitude * abs(snoise(p * frequency));
		frequency *= 2.3;
		amplitude *= 0.45;
	}
	return value;
}

void fragment() {
	// World-space coordinates for seamless tiling across geometry
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 uv3 = world_pos * vein_scale;

	// Primary vein pattern (domain-warped for swirling organic flow)
	float vein_primary = domain_warped_veins(uv3);

	// Secondary fine veins (offset sampling for variation)
	float vein_secondary = domain_warped_veins(uv3 * 1.5 + vec3(31.7, 17.3, 5.9));

	// Fine turbulence detail
	float detail = turbulence(uv3 * 2.5 + vec3(7.1, 13.2, 29.8));

	// Combine vein layers
	float vein = vein_primary * 0.55 + vein_secondary * 0.30 + detail * 0.15;

	// Sharpen veins with a smooth threshold
	vein = smoothstep(-0.15, 0.45, vein) * vein_intensity;

	// Mix base and vein colors
	vec3 color = mix(base_color.rgb, vein_color.rgb, vein);

	// Subtle warm color variation across the surface (large-scale drift)
	float color_shift = snoise(world_pos * vein_scale * 0.12) * 0.035;
	color += vec3(color_shift, color_shift * 0.75, color_shift * 0.5);

	ALBEDO = color;
	ROUGHNESS = roughness;
	METALLIC = 0.0;
	SPECULAR = 0.5;

	// Subsurface scattering — polished marble has a warm translucent glow
	if (subsurface_strength > 0.001) {
		SSS_STRENGTH = subsurface_strength;
		BACKLIGHT = vec3(subsurface_strength * 0.3);
	}

	// Normal perturbation from noise gradient (finite differences)
	float eps = 0.01;
	float nx = domain_warped_veins(uv3 + vec3(eps, 0.0, 0.0)) - domain_warped_veins(uv3 - vec3(eps, 0.0, 0.0));
	float ny = domain_warped_veins(uv3 + vec3(0.0, eps, 0.0)) - domain_warped_veins(uv3 - vec3(eps, 0.0, 0.0));
	vec3 perturbed_normal = normalize(vec3(-nx * normal_strength, -ny * normal_strength, 1.0));
	NORMAL_MAP = perturbed_normal * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = normal_strength;
}
