shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// THE WARDROBE (boolean_cave, 2026-11-14; Palle: "apply the most fetish and queer shaders super extravaganza for the
// editor"). The skins a painted cave's strokes - and its block - can wear. Each stroke keeps its own colour (`hue`);
// the skin says what it is made of.
//
// Most are the project's own queer shaders, ported: theirs read UV, and a CSG cave has UVs that scale with each brush
// (a 1.3 m sphere and a 4 cm one would wear grain of different sizes), so here every pattern is laid in WORLD space,
// `cell` metres to a unit (the small cave finer than the big). Nothing moves the geometry - drag_extravaganza throbs
// its vertices, which is not a wall to stand inside in a headset - and `shimmer` scales whatever moves with time.
//
// COMFORT (a headset judge, then an extravaganza defender who cut back whatever dulled a skin; 2026-11-14): a cave
// lined with these is stood in for minutes, so
//   - every motion is a loop of TIME's rollover (rendering/limits/time/time_rollover_secs, 30 s in this project): a
//     drift leapt back at the wrap - holo moved 94 % of its pixels in one frame, every 30 s;
//   - a pattern finer than a few pixels (grain, flakes, studs, cords, bands, discs, creases) fades to its own average
//     instead of sizzling as the head sways;
//   - glints are taken from the head's centre, so both eyes see the same sparkle; a mirror's reflection from each eye,
//     so it sits behind the surface as a mirror's does - and a mirror keeps a faint grain at its own depth.
//
//   0 latex     algorithms/shaders/queer_collection_2/oil_slick_latex: deep and wet, an oil-slick spectrum on the rim
//   1 pvc       algorithms/shaders/queer_materials/pop_plastic: wet-look shine, creases that hang, studio streaks
//   2 rubber    matte, thick, a soft sheen at the edge
//   3 leather   algorithms/shaders/queer_materials/leather: grain and folds, a grey rim - and chrome studs
//   4 chrome    mirror metal, tinted by the stroke
//   5 glitter   flakes that catch the eye and let it go as you move (view-dependent; far off, bigger flakes)
//   6 sequin    drag: tilted discs in offset rows, each its own glint
//   7 holo      commons/resourses/shaders/foil_paper: holographic foil, the spectrum turning with the view
//   8 fishnet   a diamond net over a skin that glows through it
//   9 rainbow   the pride flag's six bands, banded through the world's height
//  10 neon      club neon: dark, its edges burning in the stroke's colour
//  11 pearl     algorithms/shaders/queer_collection_2/crushed_pearl: pale nacre, its colour arriving at the edge
//  12 velvet    algorithms/shaders/queer_materials/fur_velvet: the light gathered at the rim
//  13 drag      algorithms/shaders/book_of_shaders/drag_extravaganza: hot pink swirl, glitter, iridescence, all at once

uniform int mode : hint_range(0, 13) = 0;
uniform vec4 hue : source_color = vec4(0.86, 0.22, 0.52, 1.0);
uniform float cell = 1.0;
uniform float shimmer = 1.0;
// = rendering/limits/time/time_rollover_secs: TIME runs 0 .. rollover and starts again, so every motion below is a
// whole number of turns of it (COMFORT).
uniform float rollover = 30.0;

varying vec3 wpos;
varying vec3 wnrm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float h13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

vec3 h33(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.xxy + p.yxx) * p.zyx);
}

float vnoise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(mix(h13(i), h13(i + vec3(1.0, 0.0, 0.0)), f.x), mix(h13(i + vec3(0.0, 1.0, 0.0)), h13(i + vec3(1.0, 1.0, 0.0)), f.x), f.y);
	float b = mix(mix(h13(i + vec3(0.0, 0.0, 1.0)), h13(i + vec3(1.0, 0.0, 1.0)), f.x), mix(h13(i + vec3(0.0, 1.0, 1.0)), h13(i + vec3(1.0, 1.0, 1.0)), f.x), f.y);
	return mix(a, b, f.z);
}

vec3 spectrum(float t) {
	return 0.5 + 0.5 * cos(6.28318 * (vec3(t) + vec3(0.0, 0.33, 0.67)));
}

// The face's dominant plane: two world axes to lay a 2D pattern on (a seam where the dominant axis changes - a
// garment has seams too).
void plane_axes(vec3 n, out vec3 u, out vec3 v) {
	vec3 a = abs(n);
	if (a.x >= a.y && a.x >= a.z) { u = vec3(0.0, 0.0, 1.0); v = vec3(0.0, 1.0, 0.0); }
	else if (a.y >= a.z) { u = vec3(1.0, 0.0, 0.0); v = vec3(0.0, 0.0, 1.0); }
	else { u = vec3(1.0, 0.0, 0.0); v = vec3(0.0, 1.0, 0.0); }
}

// A painted studio for mirrors: the tower's even lilac sky leaves a mirror nothing to show (a judge: a block dressed in
// chrome read as a plain pale box), so a reflection also sees a dark floor, a hard horizon with a white line along it,
// and six tall strip softboxes round the world. rw: how far the reflection turns within one pixel - the line and the
// strips widen by half of it (a box filter widens a profile by half its own width) and dim to keep their light, so a
// rippled or far-off mirror does not sizzle and a near one stays crisp (COMFORT).
vec3 studio(vec3 R, vec3 tint, float rw) {
	float hw = 0.5 * rw;
	float sky = smoothstep(-0.02 - hw, 0.02 + hw, R.y);
	float line = (1.0 - smoothstep(0.0, 0.05 + hw, abs(R.y))) * 0.05 / (0.05 + hw);
	float strip = smoothstep(cos(min(3.0 * (0.1225 + hw), 1.5)), 0.98, abs(sin(atan(R.z, R.x) * 3.0))) * (1.0 - smoothstep(0.55, 0.75, abs(R.y - 0.15))) * 0.095 / (0.095 + hw);
	vec3 below = vec3(0.025, 0.02, 0.035);
	vec3 above = mix(vec3(0.32, 0.28, 0.4), tint, 0.3) * (0.55 + 0.45 * clamp(R.y, 0.0, 1.0));
	return mix(below, above, sky) + vec3(1.0) * (line * 0.8 + strip * 1.8);
}

// Sequins: discs in offset rows (scales), each tilted its own way; returns the glint, gives the disc mask, its tilted
// normal and `far` (0 while a disc is 4 px or more, 1 at 2 px). The pixel width is taken from the world position, not
// from the row coordinate, which jumps half a sequin at every row and at every seam between planes and so made whole
// rows read as far (COMFORT); far off, the discs lose their glint and their tilt too, not only their outline.
float sequins(vec3 p, vec3 n, vec3 to_eye, float size, out float disc, out vec3 tilt, out float far) {
	vec3 u; vec3 v;
	plane_axes(n, u, v);
	vec2 q = vec2(dot(p, u), dot(p, v)) / size;
	vec3 pw = fwidth(p);
	float w = max(dot(pw, abs(u)), dot(pw, abs(v))) / size;
	q.x += 0.5 * mod(floor(q.y), 2.0);
	vec2 id = floor(q);
	vec2 f = fract(q) - 0.5;
	disc = 1.0 - smoothstep(0.46 - w, 0.46 + w, length(f));
	far = smoothstep(0.25, 0.5, w);
	disc = mix(disc, 0.78, far);
	tilt = normalize(n + (h33(vec3(id, 3.0)) - 0.5) * 0.9);
	return pow(max(dot(tilt, to_eye), 0.0), 36.0) * disc * (1.0 - far);
}

// Glitter, one layer: in some cells a round flake about a jittered point (no 1 px slivers where a cell wall cuts the
// surface), whose facet leans out of the surface; it lights when its facet faces the eye.
float flake_layer(vec3 p, vec3 n, vec3 to_eye, float size, float w) {
	vec3 c = floor(p / size);
	vec3 f = fract(p / size) - 0.5 - (h33(c + 5.0) - 0.5) * 0.2;
	vec3 fp = f - n * dot(f, n);                      // in the surface's own plane: a whole round flake, whatever the cell depth
	float blob = 1.0 - smoothstep(0.38 - w, 0.38 + w, length(fp));
	vec3 facet = normalize((h33(c) * 2.0 - 1.0) + n * 1.3);
	float on = step(0.4, h13(c + 17.0));
	return pow(max(dot(facet, to_eye), 0.0), 90.0) * on * blob;
}

// Glitter flakes, so a moving head makes them twinkle. The cells double wherever a cell would fall under ~3 px - far
// off, at a grazing angle - so glitter keeps twinkling instead of sizzling, and never fades out (COMFORT). cid: the
// cell, for the colour.
float flakes(vec3 p, vec3 n, vec3 to_eye, float size, out vec3 cid) {
	float w0 = length(fwidth(p / size));
	float lod = max(0.0, log2(w0 / 0.3));
	float l0 = floor(lod);
	float s0 = size * exp2(l0);
	float a = flake_layer(p, n, to_eye, s0, w0 / exp2(l0));
	float b = flake_layer(p, n, to_eye, s0 * 2.0, w0 / exp2(l0 + 1.0));
	cid = floor(p / s0);
	return mix(a, b, fract(lod));
}

void fragment() {
	vec3 N = normalize(NORMAL);
	vec3 V = normalize(VIEW);
	float nv = clamp(dot(N, V), 0.0, 1.0);
	float rim = 1.0 - nv;
	vec3 to_eye = normalize(CAMERA_POSITION_WORLD - wpos);    // in a headset the head's centre: glints the same in both eyes
	vec3 to_eye_r = normalize(mat3(INV_VIEW_MATRIX) * V);     // this eye: a reflection sits behind the surface (COMFORT)
	vec3 wn = normalize(wnrm);
	bool bent = false;
	float ph = TIME * TAU / rollover;                         // one turn per rollover (COMFORT)
	vec3 orbit = vec3(sin(ph), cos(ph), sin(ph + 2.1)) * shimmer;   // what drifted now circles, and comes back
	float turn = TIME / rollover * step(0.001, shimmer);      // 0 .. 1 per rollover: a whole turn of the spectrum

	vec3 col = hue.rgb;
	float rough = 0.4;
	float metal = 0.0;
	float spec = 0.5;
	float clear = 0.0;
	float clear_r = 0.1;
	float rim_amount = 0.0;
	float rim_tint = 0.5;
	vec3 emit = vec3(0.0);

	if (mode == 0) {
		// LATEX: deep, saturated, wet; the oil slick lives on the grazing edge
		float n1 = vnoise(wpos * 2.0 / cell + orbit * 0.25);
		col = hue.rgb * 0.2;
		rough = 0.05 + n1 * 0.05;
		spec = 1.0;
		clear = 1.0;
		clear_r = 0.02;
		vec3 sheen = spectrum(rim * 1.6 + n1 * 0.3 + turn) * pow(rim, 4.0);
		emit = sheen * 0.8 + hue.rgb * pow(rim, 6.0) * 0.5;
	} else if (mode == 1) {
		// PVC, the wet look: a mirror-wet plastic, creases that hang, the studio's streaks down every crease
		vec3 q = wpos / cell * vec3(7.0, 0.6, 7.0);
		float cfade = 1.0 - smoothstep(0.25, 0.6, length(fwidth(q)));     // COMFORT: creases under ~3 px smooth out
		vec3 g = vec3(vnoise(q + vec3(7.0, 0.0, 0.0)), vnoise(q + vec3(0.0, 13.0, 0.0)), vnoise(q + vec3(0.0, 0.0, 29.0))) - 0.5;
		g.y *= 0.3;
		wn = normalize(wn + g * 0.6 * cfade);
		bent = true;
		col = hue.rgb * 0.3;
		rough = clamp(length(fwidth(wn)), 0.02, 0.3);            // COMFORT: what still bends within a pixel blurs
		spec = 1.0;
		clear = 1.0;
		clear_r = rough * 0.5;                                            // COMFORT: the coat too, not a mirror of the sun's pinpricks
		vec3 R = reflect(-to_eye_r, wn);
		// the creases smoothed away still blur the studio, so a far wall reads as gloss, not a white light box (COMFORT)
		emit = studio(R, vec3(1.0), length(fwidth(R)) + 0.6 * (1.0 - cfade)) * (0.08 + 0.92 * pow(rim, 4.0)) * 1.2;
	} else if (mode == 2) {
		// RUBBER: thick and matte, the light lying soft along its edge; a faint talc bloom, so two eyes have something
		// on the surface to agree on (COMFORT: a flat colour gives a headset no depth to hold)
		vec3 tq = wpos * 25.0 / cell;
		float talc = mix(vnoise(tq), 0.5, smoothstep(0.35, 0.8, length(fwidth(tq))));   // and it fades before it could sizzle
		col = hue.rgb * 0.62 * (0.92 + 0.16 * talc);
		rough = 0.66;
		spec = 0.3;
		rim_amount = 0.25;
		rim_tint = 0.4;
		emit = hue.rgb * 0.04;
	} else if (mode == 3) {
		// LEATHER: grain and folds (queer_materials/leather), a grey rim - and, every other cell, a chrome stud
		float grain = vnoise(wpos * 60.0 / cell);
		float folds = vnoise(wpos * 4.0 / cell);
		vec3 gq = wpos * 60.0 / cell;
		float gfade = 1.0 - smoothstep(0.3, 0.7, length(fwidth(gq)));       // COMFORT: grain under ~2 px goes
		vec3 gn = vec3(vnoise(gq + vec3(3.1, 0.0, 0.0)), vnoise(gq + vec3(0.0, 7.7, 0.0)), vnoise(gq + vec3(0.0, 0.0, 13.3))) - 0.5;
		wn = normalize(wn + gn * 0.16 * gfade);
		bent = true;
		col = mix(vec3(0.025), hue.rgb * 0.3, 0.65) * (0.8 + 0.2 * folds);   // COMFORT: x1.5 - still black, but its folds read
		rough = 0.32 + (1.0 - mix(grain, 0.5, 1.0 - gfade)) * 0.2;                 // the grain's roughness fades with it
		spec = 0.5;
		metal = 0.1;
		emit = vec3(0.2) * smoothstep(0.55, 1.0, rim) * 0.6;
		vec3 u; vec3 v;
		plane_axes(wnrm, u, v);
		float pitch = 0.09 * cell;
		vec2 q = vec2(dot(wpos, u), dot(wpos, v)) / pitch;
		vec3 pw = fwidth(wpos);
		float aw = max(dot(pw, abs(u)), dot(pw, abs(v))) / pitch;
		float sfar = smoothstep(0.1, 0.24, aw);                             // COMFORT: studs 10 px apart fold into the hide, gone at 4 px
		vec2 id = floor(q);
		vec2 f = fract(q) - 0.5;
		// a pyramid stud (four crisp faces, so it reads as metal from any side) in a sunken dark collar, every other cell;
		// antialiased, and each set its own way, so a wall of them does not flash in unison (COMFORT)
		float rs = 0.2;
		float m = max(abs(f.x), abs(f.y));
		float every = 1.0 - step(0.5, mod(id.x + id.y, 2.0));
		float stud = every * (1.0 - smoothstep(rs - aw, rs + aw, m)) * (1.0 - sfar);
		float collar = every * (1.0 - smoothstep(rs + 0.06 - aw, rs + 0.06 + aw, m)) * (1.0 - sfar) - stud;
		col = mix(col * (1.0 - 0.055 * sfar), vec3(0.88, 0.88, 0.92), 0.08 * sfar);   // far: 8 % chrome, 5.5 % collar, folded in
		vec2 side = abs(f.x) > abs(f.y) ? vec2(sign(f.x), 0.0) : vec2(0.0, sign(f.y));
		vec3 jit = (h33(vec3(id, 9.0)) - 0.5) * 0.3;
		vec3 sn = normalize(wnrm * 0.75 + (u * side.x + v * side.y) * 0.66 + jit);
		wn = normalize(mix(wn, sn, stud));
		col = mix(mix(col, vec3(0.005), collar), vec3(0.88, 0.88, 0.92), stud);
		metal = mix(metal, 1.0, stud);
		rough = mix(mix(rough, 0.85, collar), 0.12, stud);
		spec = mix(spec, 1.0, stud);
		emit = mix(emit * (1.0 - collar), vec3(1.0) * pow(max(dot(sn, to_eye), 0.0), 20.0) * 0.5, stud);
	} else if (mode == 4) {
		// CHROME: a mirror, tinted by the stroke - its reflection from each eye, and a brushed grain at the wall's own depth,
		// so a cave of mirrors still shows where its walls are (COMFORT)
		vec3 tint = mix(vec3(1.0), hue.rgb, 0.35);
		col = tint * 0.15;
		metal = 1.0;
		rough = 0.04;
		spec = 1.0;
		vec3 R = reflect(-to_eye_r, wn);
		vec3 bq = vec3(wpos.x * 40.0, wpos.y * 1.5, wpos.z * 40.0) / cell;
		float br = mix(vnoise(bq), 0.5, smoothstep(0.3, 0.7, length(fwidth(bq))));
		emit = studio(R, tint, length(fwidth(R))) * tint * 0.85 * (0.88 + 0.12 * br);
	} else if (mode == 5) {
		// GLITTER: each flake flashes its own colour
		col = hue.rgb * 0.5;
		rough = 0.28;
		metal = 0.6;
		spec = 0.8;
		vec3 fc;
		float tw = flakes(wpos, wn, to_eye, 0.012 * cell, fc);
		emit = mix(vec3(1.0), spectrum(h13(fc + 41.0)), 0.55) * tw * 4.0 + hue.rgb * 0.07;
	} else if (mode == 6) {
		// SEQUINS: discs in offset rows (scales), each tilted its own way, each its own glint
		float disc;
		vec3 tilt;
		float far;
		float glint = sequins(wpos, wnrm, to_eye, 0.024 * cell, disc, tilt, far);
		wn = normalize(mix(wnrm, tilt, disc * (1.0 - far)));
		bent = true;
		col = mix(hue.rgb * 0.08, hue.rgb, disc);
		metal = mix(0.2, 1.0, disc);
		rough = mix(mix(0.6, 0.08, disc), 0.3, far);
		spec = 1.0;
		emit = (hue.rgb + vec3(0.4)) * glint * 2.5;
	} else if (mode == 7) {
		// HOLO: foil whose spectrum turns with the view, crossed by fine diffraction lines. The view is the head's centre:
		// foil's colour lies ON the foil, and two eyes shown two colours at one point fight (COMFORT). Bands under ~5 px
		// a cycle give their mean.
		float k = dot(reflect(-to_eye, wn), vec3(0.45, 0.75, 0.45)) * 3.0 + dot(wpos, vec3(0.7, 1.1, 0.4)) * 0.6 / cell + turn;
		vec3 rb = mix(vec3(0.5), spectrum(k), 1.0 - smoothstep(0.2, 0.45, fwidth(k)));
		col = mix(vec3(0.8, 0.8, 0.85), mix(rb, hue.rgb, 0.15), 0.55);
		metal = 0.85;
		rough = 0.1;
		spec = 1.0;
		float phase = dot(wpos, vec3(40.0, 0.0, 40.0)) / cell;
		float lines = mix(0.5 + 0.5 * sin(phase), 0.5, clamp(fwidth(phase) / 3.0, 0.0, 1.0));
		emit = rb * (0.2 + 0.3 * lines) * pow(rim, 1.5);
	} else if (mode == 8) {
		// FISHNET: a diamond net, its cord black and glossy, the skin glowing through
		vec3 u; vec3 v;
		plane_axes(wnrm, u, v);
		vec2 q = vec2(dot(wpos, u), dot(wpos, v)) / (0.06 * cell);
		vec2 r = vec2(q.x + q.y, q.x - q.y);
		vec2 g = abs(fract(r) - 0.5);
		float mg = min(g.x, g.y);
		float w = fwidth(mg);
		float cord = 1.0 - smoothstep(0.035 - w, 0.075 + w, mg);
		cord = max(cord, 1.0 - smoothstep(0.07, 0.1, length(g)));               // a knot where two cords cross
		vec2 rw2 = fwidth(r);
		cord = mix(cord, 0.32, smoothstep(0.125, 0.25, max(rw2.x, rw2.y)));     // far: the net's average, no moire - from either cord (COMFORT)
		col = mix(hue.rgb * 0.85, vec3(0.012), cord);
		rough = mix(0.45, 0.22, cord);
		spec = mix(0.5, 0.85, cord);
		emit = hue.rgb * (1.0 - cord) * 0.5;
	} else if (mode == 9) {
		// RAINBOW: the six bands of the flag, through the world's height
		float b = -wpos.y / (0.12 * cell);                                        // red on top, as the flag hangs
		float fb = fract(b);
		float k = mod(floor(b), 6.0);
		vec3 c0 = vec3(0.89, 0.01, 0.01);
		vec3 c1 = vec3(1.0, 0.55, 0.0);
		vec3 c2 = vec3(1.0, 0.93, 0.0);
		vec3 c3 = vec3(0.0, 0.5, 0.15);
		vec3 c4 = vec3(0.0, 0.3, 1.0);
		vec3 c5 = vec3(0.46, 0.03, 0.53);
		vec3 a = c0;
		vec3 nx = c1;
		if (k > 4.5) { a = c5; nx = c0; }
		else if (k > 3.5) { a = c4; nx = c5; }
		else if (k > 2.5) { a = c3; nx = c4; }
		else if (k > 1.5) { a = c2; nx = c3; }
		else if (k > 0.5) { a = c1; nx = c2; }
		col = mix(a, nx, smoothstep(0.9, 1.0, fb));
		rough = 0.25;
		spec = 0.7;
		clear = 0.6;
		clear_r = 0.08;
		emit = col * 0.18;
	} else if (mode == 10) {
		// NEON: club neon - dark, the edges burning in the stroke's colour, tube rings round it breathing every 3 s
		col = vec3(0.02);
		rough = 0.3;
		spec = 0.5;
		emit = hue.rgb * (pow(rim, 2.2) * 2.4 + 0.05) * (0.85 + 0.15 * sin(ph * 10.0) * shimmer);
		float d = abs(fract(wpos.y / (0.45 * cell)) - 0.5) * 0.45 * cell;
		float aa = fwidth(d);
		float cw = 0.0065 * cell;
		// COMFORT: the tube's core at least a pixel wide, its light spread when it would be thinner (no crawling line)
		float core = (1.0 - smoothstep(cw - 0.0025 * cell - aa, cw + 0.0025 * cell + aa, d)) * cw / max(cw, aa);
		emit += mix(hue.rgb, vec3(1.0), core) * (core * 2.2 + exp(-d / (0.03 * cell))) * (1.0 - smoothstep(0.5, 0.8, abs(wn.y)));
	} else if (mode == 11) {
		// PEARL: pale nacre, its colour arriving only at the edge
		float n1 = vnoise(wpos * 3.0 / cell);
		vec3 orient = mix(vec3(1.0, 0.78, 0.88), vec3(0.80, 0.95, 0.90), n1);
		col = mix(vec3(0.96, 0.94, 0.95), mix(orient, hue.rgb, 0.25), 0.12 + 0.4 * rim);
		rough = 0.2;
		spec = 0.8;
		clear = 1.0;
		clear_r = 0.05;
		emit = vec3(0.95, 0.92, 0.96) * 0.1 + orient * pow(rim, 2.0) * 0.35;
	} else if (mode == 12) {
		// VELVET: the light gathered at the rim, the face itself deep
		vec3 fq = wpos * 140.0 / cell;
		float fibre = mix(vnoise(fq), 0.5, smoothstep(0.35, 0.8, length(fwidth(fq))));   // COMFORT: no fibre sizzle
		col = hue.rgb * 0.18;
		rough = 0.96;
		spec = 0.2;
		rim_amount = 1.0;
		rim_tint = 1.0;
		emit = (hue.rgb * 1.2 + vec3(0.08)) * pow(rim, 1.25) * (0.75 + 0.25 * fibre);
	} else {
		// DRAG: everything at once - a hot pink swirl, iridescence, glitter, a burning rim. The swirl still circles;
		// where the sequins are sewn on does not (they slid across the dress), and the grazing pink rim is trimmed
		// (0.8 -> 0.55), where the pink burnt out to a flat sheet that hid the form (COMFORT)
		float sw = vnoise(wpos * 1.5 / cell + orbit * 0.5) * 0.65 + vnoise(wpos * 3.0 / cell - orbit * 0.35) * 0.35;
		float sewn = vnoise(wpos * 1.5 / cell) * 0.65 + vnoise(wpos * 3.0 / cell) * 0.35;
		vec3 base = mix(vec3(1.0, 0.08, 0.58), vec3(1.0, 0.0, 1.0), sw);
		base = mix(base, hue.rgb, 0.1);
		vec3 iris = spectrum(nv * 1.3 + 4.0 * turn);
		col = mix(base, iris, 0.2);
		metal = 0.4;
		rough = 0.15;
		spec = 1.0;
		vec3 fc;
		float tw = flakes(wpos, wn, to_eye, 0.01 * cell, fc);
		emit = col * 0.22 + vec3(1.0, 0.8, 0.9) * tw * 3.0 + vec3(1.0, 0.08, 0.58) * pow(rim, 2.0) * 0.55;
		float disc;
		vec3 tilt;
		float far;
		float glint = sequins(wpos, wnrm, to_eye, 0.03 * cell, disc, tilt, far);
		float worn = smoothstep(0.58, 0.64, sewn) * disc;
		if (worn > 0.0) {
			wn = normalize(mix(wn, tilt, worn * (1.0 - far)));
			bent = true;
			metal = mix(metal, 1.0, worn);
			rough = mix(rough, mix(0.08, 0.3, far), worn);
			emit += (vec3(1.0, 0.3, 0.7) + vec3(0.4)) * glint * 2.5 * worn;
		}
	}

	if (bent) NORMAL = normalize((VIEW_MATRIX * vec4(wn, 0.0)).xyz);
	ALBEDO = clamp(col, vec3(0.0), vec3(1.0));
	ROUGHNESS = rough;
	METALLIC = metal;
	SPECULAR = spec;
	EMISSION = emit;
	CLEARCOAT = clear;
	CLEARCOAT_ROUGHNESS = clear_r;
	RIM = rim_amount;
	RIM_TINT = rim_tint;
}
