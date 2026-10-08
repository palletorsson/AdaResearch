shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// ARCHITECTURE-SCALE SURFACES (2026-09-03, Palle: "add queer and nice surface
// shaders?" — for radial_inside, the walkable interior).
//
// WHY NOT JUST USE dream_gloss.gdshader. Because it was tuned against a 1.7 m
// statue and the first 36 m render proved what that costs: interference is a
// function of the VIEWING ANGLE, and across a wall you can walk the length of,
// every angle is present at once. The whole surface bands. What reads as an oil
// slick on a hip reads as psychedelic candy floss on a hall.
//
// So the marks here are chosen for a surface you move THROUGH rather than walk
// AROUND:
//
//   PER-PANEL COLOUR. Every facet carries its own hue, baked into vertex COLOR
//   at build time. That is Palle's own phrase for the source work made literal —
//   "a surrealist colour and sculptural assemblage" — and it is the one thing
//   that makes thirty metres of wall worth walking without any high-frequency
//   noise anywhere in it. A panel is a decision, not a texture.
//
//   SEAMS THAT LIGHT. Each quad is unwrapped 0..1, so the distance to the panel
//   edge is free, and the seam is drawn from it. In the reference frames the cut
//   edges are the ONLY light in the picture; here they are the wayfinding, since
//   a windowless interior has no sun and no horizon.
//
//   IRIDESCENCE FROM ANGLE ALONE. No positional noise: the hue is a function of
//   the grazing angle only, so it slides as you TURN and holds still as you walk.
//   That is the difference between a film and a pattern, and at this scale it is
//   the only version that survives.
//
// EVERYTHING IS VISIBLE STANDING STILL. Nothing animates: a room whose surfaces
// need time to be understood cannot be photographed, and this project's evidence
// is a frame.

// 0 panel · 1 film · 2 velvet · 3 wetstone · 4 nacre · 5 flesh
uniform int mode : hint_range(0, 5) = 0;
uniform vec4 base_color : source_color = vec4(0.62, 0.24, 0.92, 1.0);
uniform vec4 accent_color : source_color = vec4(0.15, 0.85, 0.95, 1.0);
uniform vec4 seam_color : source_color = vec4(1.0, 0.28, 0.62, 1.0);
/// How much of each panel's own dealt hue survives. 0 = every panel the same.
uniform float panel_mix : hint_range(0.0, 1.0) = 0.85;
/// Seam half-width in panel units. A panel is one quad, so 0.03 is a hairline.
uniform float seam_w : hint_range(0.0, 0.25) = 0.035;
uniform float seam_energy : hint_range(0.0, 8.0) = 3.0;
uniform float gloss : hint_range(0.0, 1.0) = 0.7;
uniform float glow : hint_range(0.0, 2.0) = 0.3;
uniform float seed_offset = 0.0;

varying vec3 obj_pos;
varying vec3 world_nrm;
varying vec3 world_pos;

const float TAU_ = 6.2831853;


// The film: hue from the grazing angle, and from nothing else.
// ONE SWEEP, NOT EIGHT. The phase is TAU * thickness / cos, so a thickness of
// 1.35 with a 0.14 floor runs from 8.5 to 60 radians across the visible angle
// range — about eight full cycles, which is eight concentric rainbows on one
// wall. That is a moire, and it is what the first architectural render came back
// as. Thin the film and raise the floor and the same expression gives roughly
// three quarters of a cycle: the hue slides ONCE as the surface turns away,
// which is what a film on a big smooth thing actually looks like.
vec3 angle_film(float cosv, float thickness) {
	float phase = TAU_ * thickness / max(cosv, 0.34);
	return 0.5 + 0.5 * cos(phase + vec3(0.0, 2.094, 4.188));
}


void vertex() {
	obj_pos = VERTEX;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_nrm = normalize(mat3(MODEL_MATRIX) * NORMAL);
}


void fragment() {
	vec3 n = normalize(NORMAL);
	vec3 v = normalize(VIEW);
	float cosv = clamp(dot(n, v), 0.0, 1.0);
	float fres = pow(1.0 - cosv, 4.0);

	// THE PANEL'S OWN HUE, baked into vertex COLOR by the builder. Interpolation
	// across a quad is harmless because every corner of a panel carries the SAME
	// colour — flat by construction, without needing a flat interpolator.
	vec3 panel = mix(base_color.rgb, COLOR.rgb, panel_mix);

	// distance to the panel's edge, in panel units, from its own 0..1 unwrap
	vec2 uv = UV;
	float edge = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
	float seam = 1.0 - smoothstep(0.0, max(seam_w, 0.001), edge);

	vec3 col = panel;
	float rough = 0.30;
	float metal = 0.0;
	vec3 emit = vec3(0.0);
	float clear = gloss;
	float clear_r = 0.06;
	float rim = 0.5;

	if (mode == 0) {
		// PANEL. Flat dealt colour, a hard coat, and the seam doing all the work.
		rough = mix(0.42, 0.10, gloss);
		clear_r = 0.04;
		emit = panel * glow * 0.20;
	} else if (mode == 1) {
		// FILM. The panel hue underneath, the angle's hue over it — so a wall is
		// one colour ahead of you and another where it curves away.
		vec3 irid = angle_film(cosv, 0.26 + 0.16 * fract(COLOR.a * 7.0 + seed_offset));
		col = mix(panel * 0.70, irid, 0.52);
		rough = 0.10;
		metal = 0.55;
		emit = irid * glow * 0.55;
		rim = 1.0;
	} else if (mode == 2) {
		// VELVET. Deep and dry in the middle, blazing at the silhouette — the one
		// that makes a large curved surface legible in a room with no sun.
		col = panel * 0.42;
		rough = 0.86;
		clear = 0.0;
		emit = mix(panel, accent_color.rgb, 0.5) * fres * 1.15 * (0.4 + glow);
		rim = 1.0;
	} else if (mode == 3) {
		// WET STONE. Dark, poured, and only the seams and the highlight visible.
		col = panel * 0.26;
		rough = 0.06;
		metal = 0.15;
		clear = 1.0;
		clear_r = 0.02;
		emit = panel * glow * 0.10;
	} else if (mode == 4) {
		// NACRE. Pale body, the colour arriving only at the grazing angle.
		col = mix(vec3(0.94, 0.92, 0.94), panel, 0.28);
		rough = 0.18;
		metal = 0.30;
		clear = 0.9;
		emit = mix(panel, accent_color.rgb, fres) * (0.10 + fres * 0.9) * (0.5 + glow);
		rim = 1.0;
	} else {
		// FLESH. Warm, soft, lit slightly from within — what the cartilage wants,
		// and what a wall wants where the building stops being a building.
		col = mix(panel, vec3(1.0, 0.72, 0.70), 0.30);
		rough = 0.42;
		clear = 0.5;
		clear_r = 0.16;
		emit = mix(panel, vec3(1.0, 0.42, 0.46), 0.6) * (0.16 + fres * 0.55) * (0.5 + glow);
		rim = 0.85;
	}

	// THE SEAM IS A LIGHT, NOT A LINE. It is added to EMISSION rather than to
	// albedo, so it survives a dark room and blooms under the museum's glow —
	// which is the whole reason a windowless interior is navigable at all.
	col = mix(col, seam_color.rgb, seam * 0.55);
	emit += seam_color.rgb * seam * seam_energy;

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
