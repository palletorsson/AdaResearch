// orb_noise.gdshader
// The catalyst orb's surface — a 3D-noise-displaced sphere that mixes
// across a per-mode 3-colour palette. Each mode has its own palette
// (set via uniforms by the capture rig / mode dispatcher).
//
// Vertex displacement: each vertex pushed along its normal by a 3D
// noise sample, giving the orb an organic / breathing surface.
// Colour: noise value mixes the three palette colours so the orb is
// variegated rather than mono-tinted.

shader_type spatial;
// Unshaded: the orb is its own light source. The noise+palette mix
// IS the colour — no diffuse/specular response to scene lighting.
render_mode unshaded, blend_mix, depth_draw_opaque, cull_back;

// ── Palette (3 colours that the noise mixes between) ──────────────
uniform vec3 palette_a : source_color = vec3(0.20, 0.95, 0.55);
uniform vec3 palette_b : source_color = vec3(0.45, 1.00, 0.40);
uniform vec3 palette_c : source_color = vec3(0.80, 1.00, 0.65);

// ── Noise controls ───────────────────────────────────────────────
uniform float noise_scale     : hint_range(0.5, 20.0) = 5.0;
uniform float noise_amount    : hint_range(0.0, 0.5)  = 0.06;
uniform float time_scale      : hint_range(0.0, 5.0)  = 0.6;
uniform float emission_energy : hint_range(0.0, 6.0)  = 1.8;
uniform float halo_softness   : hint_range(0.0, 1.0)  = 0.35;


// ── 3D Simplex noise (Ashima Arts, public domain) ────────────────
vec3 mod289_v(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 mod289_v(vec4 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 permute(vec4 x) { return mod289_v(((x*34.0)+1.0)*x); }
vec4 taylorInvSqrt(vec4 r) { return 1.79284291400159 - 0.85373472095314 * r; }

float snoise(vec3 v) {
	const vec2 C = vec2(1.0/6.0, 1.0/3.0);
	const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);
	vec3 i  = floor(v + dot(v, C.yyy));
	vec3 x0 = v   - i + dot(i, C.xxx);
	vec3 g  = step(x0.yzx, x0.xyz);
	vec3 l  = 1.0 - g;
	vec3 i1 = min(g.xyz, l.zxy);
	vec3 i2 = max(g.xyz, l.zxy);
	vec3 x1 = x0 - i1 + C.xxx;
	vec3 x2 = x0 - i2 + 2.0 * C.xxx;
	vec3 x3 = x0 - D.yyy;
	i = mod289_v(i);
	vec4 p = permute( permute( permute(
		i.z + vec4(0.0, i1.z, i2.z, 1.0))
		+ i.y + vec4(0.0, i1.y, i2.y, 1.0))
		+ i.x + vec4(0.0, i1.x, i2.x, 1.0));
	float n_ = 0.142857142857;
	vec3 ns  = n_ * D.wyz - D.xzx;
	vec4 j  = p - 49.0 * floor(p * ns.z * ns.z);
	vec4 x_ = floor(j * ns.z);
	vec4 y_ = floor(j - 7.0 * x_);
	vec4 x = x_ * ns.x + ns.yyyy;
	vec4 y = y_ * ns.x + ns.yyyy;
	vec4 h = 1.0 - abs(x) - abs(y);
	vec4 b0 = vec4(x.xy, y.xy);
	vec4 b1 = vec4(x.zw, y.zw);
	vec4 s0 = floor(b0)*2.0 + 1.0;
	vec4 s1 = floor(b1)*2.0 + 1.0;
	vec4 sh = -step(h, vec4(0.0));
	vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy;
	vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww;
	vec3 p0 = vec3(a0.xy, h.x);
	vec3 p1 = vec3(a0.zw, h.y);
	vec3 p2 = vec3(a1.xy, h.z);
	vec3 p3 = vec3(a1.zw, h.w);
	vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2,p2), dot(p3,p3)));
	p0 *= norm.x; p1 *= norm.y; p2 *= norm.z; p3 *= norm.w;
	vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
	m = m * m;
	return 42.0 * dot(m*m, vec4(dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3)));
}


// ── Vertex: displace along normal by noise ───────────────────────
varying float v_noise;
varying vec3  v_normal_world;

void vertex() {
	// Sample noise in object space + time so the orb breathes.
	vec3 sample_pos = VERTEX * noise_scale + vec3(TIME * time_scale);
	float n = snoise(sample_pos);
	v_noise = n;
	// Push the vertex outward along its normal.
	VERTEX += NORMAL * n * noise_amount;
	v_normal_world = mat3(MODEL_MATRIX) * NORMAL;
}


// ── Fragment: mix palette by noise + view-angle halo ─────────────
void fragment() {
	// Re-map noise [-1, 1] → [0, 1].
	float t = clamp(v_noise * 0.5 + 0.5, 0.0, 1.0);

	// 3-stop palette mix: blend across palette_a → palette_b → palette_c.
	vec3 ab = mix(palette_a, palette_b, smoothstep(0.0, 0.5, t));
	vec3 col = mix(ab,       palette_c, smoothstep(0.5, 1.0, t));

	// Soft fresnel: edges brighter, centre uses the palette as-is.
	vec3 view_dir = normalize(-(INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz - (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz);
	float fresnel = pow(1.0 - clamp(dot(normalize(v_normal_world), view_dir), 0.0, 1.0), 2.0);

	// In unshaded mode, ALBEDO is the entire visible colour. We brighten
	// it with emission_energy so the palette colours saturate properly.
	vec3 final_col = col * emission_energy * (0.7 + 0.5 * fresnel);
	ALBEDO = final_col;
	ALPHA = mix(1.0, 0.85, fresnel * halo_softness);
}
