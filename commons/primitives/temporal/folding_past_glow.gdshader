shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never, shadows_disabled;

// GLOW FOR THE FOLDING FRAMES — a band with a hot core, not a line.
//
// 2026-08-31, Palle: "can we use some shader on the lines on folding past so
// that they glow more."
//
// WHY THIS IS NOT JUST A BRIGHTER MATERIAL. The frames were drawn as
// PRIMITIVE_LINES, and a line rasterises one pixel wide no matter what a shader
// says. Nothing written in a fragment can put light BESIDE a line. The usual way
// to get that light is screen-space bloom, and this project does not have it:
// commons/scenes/vr_staging.tscn carries `glow_intensity = 1.67` with no
// `glow_enabled`, so the effect is configured and switched off. Turning it on is
// one line and it would change every artifact in every map, which is not this
// artifact's decision to make.
//
// So the glow is built out of geometry instead, and stays inside this artifact.
// Each edge is a quad; UV.x runs -1..+1 ACROSS it and UV.y runs -1..+1 ALONG it;
// NORMAL carries the in-plane direction to expand sideways. The vertex stage
// pushes the corners out to make a band, the fragment stage puts a hot core down
// its middle and lets it fall off to the edges, and blend_add means overlapping
// frames accumulate light the way overlapping light actually does.
//
// AND WHY THE ENERGIES LOOK ABSURD. Both scenes tonemap with ACES at
// `tonemap_exposure = 0.16`. A linear 1.0 comes out of that near-black, which is
// why the old material's `emission_energy_multiplier = 0.8` read as a grey
// scratch. These defaults are calibrated against that exposure, not against a
// neutral one — if the exposure is ever raised, these come down.

// half-width of the band in WORLD metres, before the core/halo split
uniform float line_width = 0.04;
// how much of the half-width is the hot core (the rest is falloff)
uniform float core = 0.16;
uniform float core_energy = 7.0;
uniform float halo_energy = 2.2;
// higher = tighter halo hugging the core; 1.0 = linear falloff to the edge
uniform float halo_falloff = 2.6;
uniform float energy = 1.0;          // the one knob GDScript turns
uniform float pulse_speed = 0.0;
uniform float pulse_depth = 0.0;
// capture fixture: 0.0 freezes the pulse so a still is reproducible
uniform float time_scale = 1.0;

varying float v_across;
varying vec4 v_col;

void vertex() {
	// The frame is ONE closed band, not four overlapping ones. Every vertex sits
	// at a corner and carries the MITRE: NORMAL points along the corner's
	// bisector and UV.y is how far out along it the band's edge lies (sqrt(2) on
	// a right angle). Building it that way is not tidiness -- with blend_add,
	// four bands crossing at the corners add to each other, and the first
	// version drew a visible bright cross at all forty of them.
	float s = max(length(MODEL_MATRIX[0].xyz), 0.0001);
	VERTEX += normalize(NORMAL) * (UV.x * UV.y * line_width / s);

	// The instance transform scales x and y together (see _update_frames), and
	// the innermost frame is 0.85^10 ~ 0.20 of the outermost. Dividing by that
	// scale keeps every band the same width in the room, so the deep frames
	// recede by getting SMALLER and DIMMER rather than by getting thinner --
	// which would have read as the glow itself running out.

	v_across = UV.x;
	v_col = COLOR;               // MultiMesh instance colour: the age fade
}

void fragment() {
	float d = abs(v_across);
	float hot = 1.0 - smoothstep(0.0, core, d);
	float halo = pow(max(0.0, 1.0 - d), halo_falloff);
	float pulse = 1.0 + pulse_depth * sin(TIME * pulse_speed * time_scale);

	EMISSION = v_col.rgb * (hot * core_energy + halo * halo_energy) * energy * pulse;
	ALPHA = clamp(v_col.a * (hot + halo * 0.7), 0.0, 1.0);
}
