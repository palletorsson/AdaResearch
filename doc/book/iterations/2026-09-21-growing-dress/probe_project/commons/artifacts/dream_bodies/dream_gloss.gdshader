shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// THE QUEER GLOSS, AS A SHADER (2026-09-03, Palle: "add crazy queer glossy
// fetish art — materials shaders").
//
// dream_skin.gd already deals latex, patent, oil slick and chrome out of
// StandardMaterial3D. This file exists for the things a StandardMaterial3D
// CANNOT do, because they are functions of the VIEW and of position, not of a
// texture:
//
//   THIN-FILM INTERFERENCE. An oil slick is not a rainbow texture. Its hue at a
//   point is set by the film's thickness divided by the cosine of the viewing
//   angle — so the colour SLIDES as the body turns, and one still shows magenta
//   at the shoulder and cyan at the hip because those two points are seen at
//   different angles. Painted into an albedo map that is a pattern; computed
//   here it is the physics, and it reads correctly on a shape nobody unwrapped.
//
//   A DIFFRACTION GRATING. Holographic foil splits white light along the ruling
//   direction. That is a function of view angle AND surface position together,
//   which no single texture lookup can be.
//
//   AN ENVIRONMENT FOR A MIRROR. The corpus's standing note is that metallic 1.0
//   with nothing to reflect photographs BLACK (gehry_metal). The capture plate
//   has no sky, so this shader carries one: a procedural horizon with a bright
//   band and vertical streaks, sampled by the reflection vector. A mirror here
//   cannot photograph black because it is reflecting something drawn on purpose.
//
//   HARNESS, LACE, BUCKLE, CAGE, ZIP — drawn in the fragment, in the body's own
//   object space, so ANY dream body can wear one without a single new triangle
//   and without a UV map. Straps are not decals here; they change albedo,
//   roughness AND metallic, so a strap over latex reads as a different material
//   crossing the same limb, which is the whole look.
//
// EVERYTHING IS VISIBLE IN ONE STILL. Nothing animates. The corpus's rule for a
// DNA axis is that the evidence is a single PNG, so a rate or a pulse would be
// an axis that cannot be photographed.

// ── the surface ────────────────────────────────────────────────────────────
// 0 latex · 1 patent · 2 oilslick · 3 holo · 4 pvc · 5 chrome
uniform int mode : hint_range(0, 5) = 0;
uniform vec4 base_color : source_color = vec4(1.0, 0.18, 0.62, 1.0);
uniform vec4 accent_color : source_color = vec4(0.15, 0.85, 0.95, 1.0);
uniform float film_scale : hint_range(0.2, 6.0) = 2.2;
uniform float grating : hint_range(2.0, 60.0) = 18.0;
uniform float sheen : hint_range(0.0, 2.0) = 1.0;
uniform float glow : hint_range(0.0, 2.0) = 0.35;

// ── the harness ────────────────────────────────────────────────────────────
// 0 bare · 1 strap · 2 lace · 3 buckle · 4 cage · 5 zip
uniform int harness : hint_range(0, 5) = 0;
uniform vec4 harness_color : source_color = vec4(0.06, 0.05, 0.09, 1.0);
uniform vec4 hardware_color : source_color = vec4(0.86, 0.87, 0.92, 1.0);
uniform float harness_scale : hint_range(0.5, 8.0) = 2.6;
// THE BODY'S OWN HEIGHT, so a harness is worn rather than tiled. The first
// version placed the belt at a fixed object-space y and it landed on the
// ANKLES: object units mean nothing without the body's scale. Every strap here
// is positioned as a FRACTION of this, so the same shader belts a 1.7 m idol
// and a 0.6 m figurine at the same place on each.
uniform float body_h : hint_range(0.2, 4.0) = 1.65;
uniform float seed_offset = 0.0;

varying vec3 obj_pos;
varying vec3 obj_nrm;
varying vec3 world_pos;
varying vec3 world_nrm;

const float TAU_ = 6.2831853;

float hash1(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n = 0.0;
	for (int k = 0; k < 2; k++) {
		float z = float(k);
		float a = hash1(i.xy + vec2(0.0, 0.0) + (i.z + z) * 37.0);
		float b = hash1(i.xy + vec2(1.0, 0.0) + (i.z + z) * 37.0);
		float c = hash1(i.xy + vec2(0.0, 1.0) + (i.z + z) * 37.0);
		float d = hash1(i.xy + vec2(1.0, 1.0) + (i.z + z) * 37.0);
		float lay = mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
		n = mix(n, lay, z == 0.0 ? 0.0 : f.z);
		if (k == 0) { n = lay; }
	}
	return n;
}

// The rainbow the whole file turns on: a thickness and a viewing cosine become
// three phase-shifted cosines, which is interference and not a palette.
vec3 interference(float thickness, float cosv) {
	float phase = TAU_ * thickness / max(cosv, 0.08);
	return 0.5 + 0.5 * cos(phase + vec3(0.0, 2.094, 4.188));
}

// The sky a mirror gets to reflect, because the capture plate has none.
//
// THE REFLECTION VECTOR MUST BE IN WORLD SPACE. Godot's NORMAL and VIEW are
// VIEW-space in the fragment shader, so reflecting with them gives a sky that
// is bolted to the camera: every surface samples nearly the same spot, the
// gradient never turns with the body, and the whole figure lands in the dark
// half. The first sweep photographed chrome as a near-black silhouette — which
// is the exact failure this function exists to prevent, arrived at from the
// other direction. It takes a world vector now, built in fragment() from
// CAMERA_POSITION_WORLD and the world normal.
vec3 fake_env(vec3 r) {
	float up = clamp(r.y * 0.5 + 0.5, 0.0, 1.0);
	// a floor, so no reflected direction is ever black
	vec3 sky = mix(vec3(0.22, 0.21, 0.28), vec3(0.86, 0.89, 0.98), smoothstep(0.34, 0.90, up));
	// a bright horizon band, which is what makes chrome read as chrome
	sky += vec3(1.0, 0.96, 0.90) * smoothstep(0.10, 0.0, abs(up - 0.5)) * 1.1;
	// vertical streaks, so a curved mirror shows something moving across it
	float streak = 0.5 + 0.5 * sin(atan(r.z, r.x) * 9.0 + seed_offset);
	sky += vec3(0.35, 0.30, 0.40) * streak * smoothstep(0.28, 0.72, up);
	return sky;
}

// One strap band: 1.0 on the leather, 0.0 off it. `d` is a signed coordinate
// that runs across the strap.
float band(float d, float half_width, float edge) {
	return smoothstep(half_width, half_width - edge, abs(d));
}

void vertex() {
	obj_pos = VERTEX;
	obj_nrm = normalize(NORMAL);
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_nrm = normalize(mat3(MODEL_MATRIX) * NORMAL);
}

void fragment() {
	vec3 n = normalize(NORMAL);
	vec3 v = normalize(VIEW);
	vec3 wn = normalize(world_nrm);
	// THE ENGINE FLIPS NORMAL ON A BACK FACE. IT CANNOT FLIP MINE.
	// Godot negates the built-in NORMAL for back-facing fragments under both
	// cull_front and cull_disabled — measured, not assumed. But world_nrm is a
	// varying this shader computed for itself in vertex(), and nothing touches
	// it. Seen from INSIDE a closed shell — which is the whole subject of the
	// architecture this shader is about to carry — every reflection would be
	// sampled through the wall, and chrome would show a sky that is behind the
	// viewer. Guarded on FRONT_FACING so one shader stays correct on both sides
	// of the same surface. Do NOT also flip NORMAL: that would undo the engine's
	// own flip, which is the foliage idiom in tree.gdshader and is wrong here.
	if (!FRONT_FACING) {
		wn = -wn;
	}
	vec3 wv = normalize(CAMERA_POSITION_WORLD - world_pos);
	vec3 refl = reflect(-wv, wn);
	float cosv = clamp(dot(n, v), 0.0, 1.0);
	float fres = pow(1.0 - cosv, 5.0);
	// MARKS ARE MEASURED IN THE BODY, NOT IN METRES. Every spatial frequency here
	// was tuned against a 1.7 m statue. Put the same shader on a 36 m interior and
	// the film's noise runs about a hundred cycles across a wall: not an oil slick,
	// a moire. body_h already carries the object's own size for the harness, so it
	// normalises the marks too — at the 1.65 default this is exactly 1.0 and every
	// existing body is untouched.
	float mscale = 1.65 / max(body_h, 0.2);
	vec3 col = base_color.rgb;
	float rough = 0.12;
	float metal = 0.0;
	vec3 emit = vec3(0.0);
	float clear = 1.0;
	float clear_r = 0.03;

	if (mode == 0) {
		// LATEX. Rubber whitens where it stretches over a curve, and the
		// highlight is stretched, not round — so the grazing angle both
		// lightens the colour and lifts the specular.
		float stretch = pow(1.0 - cosv, 2.0);
		col = mix(base_color.rgb, mix(base_color.rgb, vec3(1.0), 0.75), stretch * 0.85);
		rough = mix(0.10, 0.26, stretch);
		emit = base_color.rgb * glow * 0.35;
		clear = 0.9;
	} else if (mode == 1) {
		// PATENT. A colour under a hard varnish: the body stays deep and almost
		// all the light comes back off the coat.
		col = base_color.rgb * 0.55;
		rough = 0.035;
		metal = 0.20;
		clear_r = 0.015;
		emit = base_color.rgb * glow * 0.18 + vec3(fres) * 0.25;
	} else if (mode == 2) {
		// OIL SLICK. Near-black body, every colour from the film.
		float thick = film_scale * (0.55 + 0.45 * vnoise(obj_pos * (3.1 * mscale) + seed_offset));
		vec3 irid = interference(thick, cosv);
		col = mix(base_color.rgb * 0.12, irid, 0.88);
		rough = 0.06;
		metal = 0.75;
		emit = irid * glow * 0.7;
	} else if (mode == 3) {
		// HOLO. A ruled grating: the rainbow runs ALONG the ruling and shifts
		// with the angle, so the bands bend around the body.
		float g = dot(obj_pos, normalize(vec3(0.2, 1.0, 0.35))) * (grating * mscale) + seed_offset;
		vec3 rainbow = 0.5 + 0.5 * cos(g + cosv * 9.0 + vec3(0.0, 2.094, 4.188));
		col = mix(rainbow, accent_color.rgb, 0.18);
		rough = 0.05;
		metal = 0.55;
		emit = rainbow * glow * 1.15;
	} else if (mode == 4) {
		// PVC. Soft, slightly translucent, lit from inside at the edges — the
		// inflatable register rather than the fetish-club one.
		col = mix(base_color.rgb, vec3(1.0), 0.18);
		rough = 0.20;
		emit = mix(base_color.rgb, accent_color.rgb, 0.35) * (0.25 + fres * 1.5) * glow;
		clear = 0.75;
		clear_r = 0.08;
	} else {
		// CHROME, with a sky to reflect.
		vec3 env = fake_env(refl);
		col = env * mix(vec3(0.95), base_color.rgb, 0.20);
		rough = 0.08;
		metal = 0.85;
		// a mirror lit only by reflection still needs to REACH the film: the
		// capture plate's key light is weak and ACES pulls the rest down
		emit = env * (0.45 + glow * 0.30);
	}

	// RIM, on everything: latex, patent and nacre all catch the room at the
	// silhouette, and it is what keeps a dark body off a black plate.
	col += mix(base_color.rgb, accent_color.rgb, 0.5) * fres * sheen * 0.55;

	// ── the harness ────────────────────────────────────────────────────────
	if (harness > 0) {
		// hy runs 0 at the sole to 1 at the crown, whatever the body is, so a
		// waist is 0.55 here and not "some number of object units"
		float hy = clamp(obj_pos.y / max(body_h, 0.05), 0.0, 1.4);
		vec3 p = obj_pos * harness_scale;
		float az = atan(obj_pos.z, obj_pos.x) / TAU_;   // -0.5 .. 0.5 around the body
		float front = smoothstep(-0.05, 0.25, obj_nrm.z);   // 1 on the chest, 0 on the back
		float mask = 0.0;
		float hard = 0.0;
		if (harness == 1) {
			// STRAP: a chest band, an under-bust band, and two shoulder diagonals
			mask = band(hy - 0.72, 0.026, 0.008);
			mask = max(mask, band(hy - 0.62, 0.022, 0.008));
			mask = max(mask, band(fract((p.x * 0.55 + hy * 2.1)) - 0.5, 0.045, 0.015)
				* step(0.55, hy) * step(hy, 0.85));
			mask = max(mask, band(fract((-p.x * 0.55 + hy * 2.1)) - 0.5, 0.045, 0.015)
				* step(0.55, hy) * step(hy, 0.85));
		} else if (harness == 2) {
			// LACE: a corset over the torso — two eyelet rails and the crossing
			float in_torso = step(0.42, hy) * step(hy, 0.80);
			float rail = band(abs(p.x) - 0.30, 0.035, 0.012) * in_torso;
			float cross_a = band(fract(p.x * 1.30 + hy * 6.0) - 0.5, 0.040, 0.015);
			float cross_b = band(fract(-p.x * 1.30 + hy * 6.0) - 0.5, 0.040, 0.015);
			mask = max(rail, max(cross_a, cross_b) * step(abs(p.x), 0.32) * in_torso * front);
			hard = band(length(vec2(abs(p.x) - 0.30, fract(hy * 12.0) - 0.5)), 0.14, 0.05) * in_torso;
		} else if (harness == 3) {
			// BUCKLE: one wide belt at the waist, a plate on the front, studs along it
			float belt = band(hy - 0.55, 0.045, 0.010);
			mask = belt;
			hard = belt * band(length(vec2(p.x * 1.1, (hy - 0.55) * 22.0)), 0.30, 0.08) * front;
			hard = max(hard, belt * band(length(vec2(fract(az * 14.0) - 0.5,
				(hy - 0.55) * 26.0)), 0.16, 0.06));
		} else if (harness == 4) {
			// CAGE: a lattice of thin straps all over, the whole body bound
			mask = max(band(fract(hy * 7.0) - 0.5, 0.055, 0.020),
				band(fract(az * 8.0) - 0.5, 0.075, 0.028));
			hard = band(length(vec2(fract(hy * 7.0) - 0.5, fract(az * 8.0) - 0.5)), 0.10, 0.04);
		} else {
			// ZIP: one closed run of teeth up the FRONT, hem to throat
			float run = step(0.22, hy) * step(hy, 0.86) * front;
			float tape = band(p.x, 0.075, 0.015) * run;
			float teeth = band(fract(hy * 46.0) - 0.5, 0.28, 0.10) * band(p.x, 0.048, 0.010) * run;
			mask = tape;
			hard = teeth;
		}
		mask = clamp(mask, 0.0, 1.0);
		hard = clamp(hard, 0.0, 1.0) * mask;
		// the strap is a DIFFERENT material crossing the body, not a printed
		// stripe: its own colour, its own roughness, its own metal
		col = mix(col, harness_color.rgb * (0.7 + 0.6 * cosv), mask * 0.94);
		rough = mix(rough, 0.30, mask);
		metal = mix(metal, 0.0, mask);
		emit = mix(emit, harness_color.rgb * 0.05, mask);
		col = mix(col, hardware_color.rgb * (0.5 + fake_env(refl) * 0.8), hard);
		rough = mix(rough, 0.14, hard);
		metal = mix(metal, 1.0, hard);
	}

	ALBEDO = clamp(col, vec3(0.0), vec3(1.0));
	ROUGHNESS = rough;
	METALLIC = metal;
	SPECULAR = 0.7;
	EMISSION = emit;
	CLEARCOAT = clear;
	CLEARCOAT_ROUGHNESS = clear_r;
	RIM = 0.7;
	RIM_TINT = 0.6;
}
