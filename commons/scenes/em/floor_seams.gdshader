// THE FLOOR JOINTS, PAINTED (2026-08-28, Palle: "we could solve the floor lists
// in the whole museum with a shader instead?").
//
// They used to be geometry: em_detail's FloorSeams, 5 cm wide, 2 cm proud of the
// floor, walked out cell by cell on the 3 m module and rebuilt for every segment.
// Three things were wrong with that, and only the first was visible:
//
//   1. A strip laid over a cell the occupancy map merely CLAIMED was floor is a
//      line hanging in the air. _map_vestibule marks every annex cell as floor
//      unconditionally, so once a basin reached the enter room the joints ran
//      out over open water. Painted on the floor, a joint cannot cross a hole:
//      there is no surface there to paint.
//      A joint could not stop at a real edge either: the lattice walked whole
//      runs of cells, so a strip crossed a podium, a doorway or a stair nosing
//      as readily as it crossed open floor.
//   2. Thin near-horizontal proud edges, four to a strip. Counted rather than
//      guessed: Point_One is 22 x 34, so the lattice laid 8 joints running in z
//      and 13 running in x — about 21 strips, 84 arris edges, per hall, and the
//      museum deals 196 halls. This project has already measured that class of
//      edge as its single largest look fault (the antialiasing note in
//      endless_museum.gd: 99% of strong luminance steps crossing in ONE pixel).
//      Merged per segment, so the draw cost was never the problem — the edges
//      were.
//   3. The spacing was a constant in a static function. It is a uniform now.
//
// It stays a SHADOW rather than a second floor colour, which was the ruling when
// the geometry version shared the circulation material: this darkens and
// roughens, and adds no hue of its own.
//
// Runs as next_pass over the terrazzo, so the floor keeps its own material. The
// 1 mm lift along the normal is what keeps it off the z-fighting knife-edge; the
// old joint stood 20 mm proud, so this is twenty times flatter than what it
// replaces.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, shadows_disabled, unshaded;

// the structural module, shared with the ceiling bays (em_detail's BAY)
uniform float bay : hint_range(0.5, 12.0) = 3.0;
uniform float seam_w : hint_range(0.005, 0.4) = 0.05;
// how far the joint darkens the floor under it. A shadow, not a paint.
uniform float darken : hint_range(0.0, 1.0) = 0.30;
// the floor plane, and how far off it a surface may be and still take a joint.
// Every floor in this museum sits at y 0: podium tops (0.6, 1.0), platform tops
// (1 m and up), the roof deck (4.85) and a basin's own floor (-depth - 0.1) are
// all excluded by this alone, without any of them having to know about joints.
uniform float plane_y = 0.0;
uniform float plane_tol : hint_range(0.001, 1.0) = 0.05;

void vertex() {
	VERTEX += NORMAL * 0.001;
}

void fragment() {
	vec3 wp = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 wn = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	// UP-FACING ONLY. Without this the lattice climbs every wall the floor
	// material happens to reach and the museum reads as tiled rather than laid.
	if (wn.y < 0.99) {
		discard;
	}
	if (abs(wp.y - plane_y) > plane_tol) {
		discard;
	}
	// distance in metres to the nearest lattice line on each axis
	vec2 d = abs(fract(wp.xz / bay + 0.5) - 0.5) * bay;
	float half_w = seam_w * 0.5;
	// One pixel of feather, so the line resolves at a grazing angle instead of
	// aliasing — which is the whole reason the geometry version was a problem.
	// CLAMPED to the line's own half-width: a floor seen almost edge-on has a
	// huge fwidth, and unclamped the feather grew wider than the joint, so the
	// nearest few metres read as a soft grey band instead of a joint. Held here,
	// a distant joint fades out rather than shimmering, which is the right way
	// for a 5 cm line to leave the frame.
	float aa = clamp(max(fwidth(wp.x), fwidth(wp.z)) * 0.5, 0.0004, half_w * 0.9);
	float line = 1.0 - smoothstep(half_w - aa, half_w + aa, min(d.x, d.y));
	if (line <= 0.002) {
		discard;
	}
	ALBEDO = vec3(0.0);
	ALPHA = line * darken;
}
