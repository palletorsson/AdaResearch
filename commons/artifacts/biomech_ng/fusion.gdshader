// fusion.gdshader — the smooth flesh<->metal seam shader.
//
// The hero fix. The marching-cubes mesh carries a PER-VERTEX flesh-ness factor
// f in COLOR.r (continuous in [0,1], computed from the two sub-fields at each
// vertex). Because f is interpolated smoothly across every triangle, lerping
// the WHOLE material by f turns the flesh/metal boundary into a continuous
// gradient melt — no per-triangle binary split, so no sawtooth seam.
//
// f = 0  -> METAL  (dark steel, metallic, tight, faint emission floor so it reads)
// f = 1  -> FLESH  (deep salmon, dielectric, soft, subsurface, own-tone glow)
// f ~0.5 -> CHAR   (a thin oxidised darkening band: the believable melt line)
//
// COLOR.g / COLOR.b are reserved for extra masks (g = vein proximity, unused
// here but packed so the artifact can reuse it). Only COLOR.r drives the blend.

shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 metal_albedo : source_color = vec3(0.13, 0.15, 0.18);
uniform vec3 flesh_albedo : source_color = vec3(0.60, 0.11, 0.13);
uniform vec3 accent       : source_color = vec3(0.35, 0.95, 0.95);
uniform float metal_floor : hint_range(0.0, 1.0) = 0.20;  // emission floor on steel
uniform float flesh_floor : hint_range(0.0, 1.0) = 0.25;  // own-tone glow on flesh
uniform float char_depth  : hint_range(0.0, 1.0) = 0.55;  // how dark the melt line gets
uniform float char_width  : hint_range(0.02, 0.5) = 0.16; // width of the char band in f
uniform float wet         : hint_range(0.0, 1.0) = 0.0;   // 0 matte; 1 wet latex/patent finish
uniform float iridescence : hint_range(0.0, 1.0) = 0.0;   // oil-slick fresnel hue shift on edges

varying float v_flesh;

void vertex() {
	// f arrives in the vertex colour's red channel (written by color_func in
	// MorphoPrimitive.marching_cubes). Pass it to the fragment stage; the GPU
	// interpolates it smoothly across each triangle for a gradient seam.
	v_flesh = COLOR.r;
}

void fragment() {
	float f = clamp(v_flesh, 0.0, 1.0);

	// Oxidised melt line: a smooth dip in albedo centred on the seam (f≈0.5).
	// 1.0 away from the seam, dropping to (1 - char_depth) at f=0.5. Tasteful —
	// it reads as charred metal bleeding into scorched flesh, not a black gash.
	float seam = 1.0 - smoothstep(0.0, char_width, abs(f - 0.5));
	float char_mul = 1.0 - char_depth * seam;

	// Lerp every surface property between METAL (f=0) and FLESH (f=1).
	vec3 base_albedo = mix(metal_albedo, flesh_albedo, f);
	ALBEDO = base_albedo * char_mul;

	METALLIC = mix(0.85, 0.0, f);
	ROUGHNESS = mix(0.40, 0.85, f);
	SPECULAR = mix(0.55, 0.35, f);

	// Emission: steel keeps a small floor so it never reads as a black void;
	// flesh gets a warmer own-tone glow. Both scaled by char_mul so the seam
	// also darkens its glow (a cooling-metal look).
	vec3 metal_emit = metal_albedo * metal_floor;
	vec3 flesh_emit = flesh_albedo * 0.7 * flesh_floor;
	EMISSION = mix(metal_emit, flesh_emit, f) * char_mul;

	// Per-vertex subsurface: flesh reads soft and translucent, steel does not.
	SSS_STRENGTH = f * 0.3;

	// A faint accent rim only on the flesh side — picks up the core's cyan on
	// the fleshy lobes, leaving the steel cold. RIM is dielectric-friendly.
	RIM = f * 0.25;
	RIM_TINT = 0.4;

	// ── Queer / bio / fetish finish ───────────────────────────────────────
	// Wet latex / patent: drop roughness, lay a clearcoat coat, sharpen the rim
	// so the whole skin reads as a glossy wet membrane fused to a chrome shell.
	if (wet > 0.001) {
		ROUGHNESS = mix(ROUGHNESS, mix(0.05, 0.16, f), wet);
		SPECULAR = mix(SPECULAR, 0.7, wet);
		CLEARCOAT = wet * 0.8;
		CLEARCOAT_ROUGHNESS = 0.05;
		RIM = mix(RIM, 0.45 + 0.3 * f, wet);
	}

	// Oil-slick iridescence: a view-angle (Fresnel) rainbow added at grazing
	// edges — holographic, queer materiality bleeding off the silhouette.
	if (iridescence > 0.001) {
		float fres = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 3.0);
		vec3 irid = 0.5 + 0.5 * cos(6.28318 * (fres + vec3(0.0, 0.33, 0.67)));
		EMISSION += iridescence * fres * irid * 0.6;
	}
}
