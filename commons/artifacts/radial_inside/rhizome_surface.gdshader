shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// SURFACES FOR A GROWN BODY (2026-09-03).
//
// arch_surface.gdshader draws its seams from a per-quad 0..1 unwrap. A marched
// mesh has no quads and no UVs, so that whole idea is unavailable here — and
// good, because a panel joint is the wrong seam for a body that was never
// assembled.
//
// THE SUTURE IS THE SEAM. dream_iso bakes two things into every vertex while it
// marches: which PART of the field is nearest, as that limb's own dealt hue, and
// how close the RUNNER-UP was, as alpha. Where alpha is 1 the two are tied — and
// a tie is exactly the locus where two limbs of the rhizome smooth-unioned into
// each other. It is the morphogenic equivalent of a joint, it is a property of
// the field rather than of a parameterisation, and it is free.
//
// So a limb keeps its identity across its whole length, and the places where the
// body FUSED glow. Walking it, you can read the plan off the walls: colour tells
// you which limb you are in, and light tells you where it joins another.
//
// Everything else is triplanar in world space, because a marched surface has no
// UVs to hang a texture on and world triplanar is the only projection that does
// not care.

// 0 wetflesh · 1 nacre · 2 chitin · 3 film · 4 lymph · 5 bone
uniform int mode : hint_range(0, 5) = 0;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 suture_color : source_color = vec4(1.0, 0.30, 0.62, 1.0);
/// How much of the limb's own dealt hue survives. 0 = the whole body one colour.
uniform float limb_mix : hint_range(0.0, 1.0) = 0.85;
/// Where the suture starts to light. 0.55 lights only a genuine fusion; lower it
/// and the whole body glows, because on a smooth-union surface SOMETHING is
/// always second-nearest.
uniform float suture_floor : hint_range(0.0, 0.99) = 0.55;
uniform float suture_energy : hint_range(0.0, 8.0) = 2.6;
uniform float grain : hint_range(0.0, 4.0) = 1.0;
uniform float glow : hint_range(0.0, 2.0) = 0.35;
uniform float seed_offset = 0.0;

varying vec3 wpos;
varying vec3 wnrm;

const float TAU_ = 6.2831853;


float h11(float p) {
	return fract(sin(p * 127.1) * 43758.5453);
}


// World-space value noise, sampled triplanar-free because it is 3D already.
float vnoise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n = 0.0;
	float w = 0.0;
	for (int k = 0; k < 8; k++) {
		vec3 o = vec3(float(k & 1), float((k >> 1) & 1), float((k >> 2) & 1));
		vec3 g = i + o;
		float hv = h11(g.x * 1.0 + g.y * 57.0 + g.z * 113.0 + seed_offset);
		vec3 d = abs(f - o);
		float ww = (1.0 - d.x) * (1.0 - d.y) * (1.0 - d.z);
		n += hv * ww;
		w += ww;
	}
	return n / max(w, 0.0001);
}


void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize(mat3(MODEL_MATRIX) * NORMAL);
}


void fragment() {
	vec3 n = normalize(NORMAL);
	vec3 v = normalize(VIEW);
	float cosv = clamp(dot(n, v), 0.0, 1.0);
	float fres = pow(1.0 - cosv, 4.0);

	// THE LIMB'S OWN HUE, from the marcher's per-vertex attribution.
	vec3 limb = mix(tint.rgb, COLOR.rgb * tint.rgb, limb_mix);

	// THE SUTURE. COLOR.a is 1 at a perfect tie and falls to 0 a blend-width
	// away. Remapped above a floor because on a smooth-union body something is
	// ALWAYS second-nearest — without the floor the entire surface is a seam,
	// which is the same as having none.
	float su = smoothstep(suture_floor, 1.0, COLOR.a);

	float bump = vnoise3(wpos * (0.9 * grain));
	float fine = vnoise3(wpos * (5.5 * grain));

	vec3 col = limb;
	float rough = 0.35;
	float metal = 0.0;
	vec3 emit = vec3(0.0);
	float clear = 0.6;
	float clear_r = 0.10;
	float rim = 0.6;

	if (mode == 0) {
		// WET FLESH. Deep, glossy, slightly mottled — the animal register.
		col = limb * mix(0.62, 1.05, bump);
		rough = mix(0.10, 0.28, fine);
		clear = 1.0;
		clear_r = 0.03;
		emit = limb * (0.06 + fres * 0.30) * (0.4 + glow);
		rim = 1.0;
	} else if (mode == 1) {
		// NACRE. Pale, the limb's colour arriving only at the grazing angle.
		col = mix(vec3(0.93, 0.91, 0.93), limb, 0.26 + 0.20 * bump);
		rough = 0.16;
		metal = 0.30;
		clear = 0.9;
		emit = limb * (0.08 + fres * 0.95) * (0.5 + glow);
		rim = 1.0;
	} else if (mode == 2) {
		// CHITIN. Hard, dark, plated — the machine register, and the one that
		// makes the fused parts read as a fault rather than as more of the same.
		col = limb * mix(0.18, 0.42, step(0.5, fine));
		rough = mix(0.12, 0.55, bump);
		metal = 0.55;
		clear = 0.7;
		clear_r = 0.05;
		emit = limb * glow * 0.10;
		rim = 0.5;
	} else if (mode == 3) {
		// FILM. One hue sweep across the visible angle range, no positional
		// noise — the only iridescence that survives at architectural scale.
		float phase = TAU_ * (0.24 + 0.16 * COLOR.a) / max(cosv, 0.34);
		vec3 irid = 0.5 + 0.5 * cos(phase + vec3(0.0, 2.094, 4.188));
		col = mix(limb * 0.66, irid, 0.55);
		rough = 0.09;
		metal = 0.55;
		emit = irid * glow * 0.55;
		rim = 1.0;
	} else if (mode == 4) {
		// LYMPH. Translucent, cold, lit from inside — the register where the
		// building stops pretending to be a building.
		col = mix(limb, vec3(0.72, 0.86, 0.95), 0.42);
		rough = 0.22;
		clear = 1.0;
		clear_r = 0.02;
		emit = mix(limb, vec3(0.55, 0.85, 1.0), 0.5) * (0.22 + fres * 0.85) * (0.5 + glow);
		rim = 1.0;
	} else {
		// BONE. Dry chalk with a fine grain — the one matte register, and the
		// contrast that lets every other one read as wet.
		col = mix(vec3(0.90, 0.88, 0.83), limb, 0.20) * mix(0.86, 1.06, fine);
		rough = 0.94;
		clear = 0.0;
		emit = vec3(0.0);
		rim = 0.30;
	}

	// THE FUSION LIGHTS. Added to emission, so it reads in a cavity with no sun
	// and blooms under glow — the wayfinding in a building whose plan is its own
	// anatomy. On BONE it is deliberately dimmer: a dry surface that glows reads
	// as a mistake rather than as a seam.
	float se = suture_energy * (mode == 5 ? 0.35 : 1.0);
	col = mix(col, suture_color.rgb, su * 0.45);
	emit += suture_color.rgb * su * se;

	ALBEDO = clamp(col, vec3(0.0), vec3(1.0));
	ROUGHNESS = rough;
	METALLIC = metal;
	SPECULAR = 0.6;
	EMISSION = emit;
	CLEARCOAT = clear;
	CLEARCOAT_ROUGHNESS = clear_r;
	RIM = rim;
	RIM_TINT = 0.7;
}
