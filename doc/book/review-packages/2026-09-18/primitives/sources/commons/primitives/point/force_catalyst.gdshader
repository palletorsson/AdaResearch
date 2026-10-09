// Force-catalyst morph shader.
//
// At morph_t = 0 the geometry stays flush against its base sphere
// (the original interactive point). As morph_t climbs to 1 a low-
// frequency sine wave displaces the vertices along their normals,
// pulsing the surface outward into a "force field" shell. The
// fragment colour blends from the neutral base white to a warm
// force-orange, with emission tracking morph_t so the shape glows
// brighter as it engages.
//
// ── WHY THIS FILE STOPPED SAYING `unshaded` ───────────────────────────────
//
// It said `unshaded` from the day it was written, and under that render mode
// Godot outputs ALBEDO and nothing else: no key light, no fill, no rim, no
// SSAO, no reflection, and — the part that is easy to miss — NO EMISSION
// either. So the resting bead was `vec3(0.95, 0.95, 0.92)` on every single
// pixel of itself, and `emission_base` / `emission_force` were dead uniforms
// that had never once reached a frame.
//
// That is not a material that needs improving, it is the ABSENCE of a
// material, and it measured exactly like one. The published sweep frame
// (primitives-dna/interactive_point_origin_force__retention-none.png):
//
//     tonal spread  sd 0.0348      flat threshold 0.055
//     distinct cols 6              flat threshold 40
//     subject       60 x 60 px of a 760 px frame
//
// Six colours across a whole sphere, and five of those are the antialiased
// rim. A sphere is the single easiest shape in rendering to make read — one
// light gives it a terminator, a gradient and a highlight for free — and this
// one was throwing all of that away to save nothing.
//
// The morph is untouched. Every line of the displacement is the same
// arithmetic it always was, and at morph_t = 0 the displacement, the normal
// correction and the colour blend are all EXACTLY zero, so the shipped
// resting silhouette is the shipped resting silhouette to the byte.
//
// ── GRAIN SCALE (see interactive_point_origin_force.gd, which computes it) ──
//
// The grain textures arrive as uniforms from PbrKit's shared cache, sampled
// over the sphere's own UV. `grain_uv` is not a taste value: it is derived in
// GDScript from the bead's measured radius so the blob lands several pixels
// wide in the capture. Left unset, the hints below give a clean lit bead with
// a flat normal and a uniform roughness, which is a graceful fallback rather
// than a black object.
shader_type spatial;
render_mode depth_draw_opaque, cull_back;

// ── The morph. This is what the artifact teaches; nothing here changed. ──
uniform float morph_t : hint_range(0.0, 1.0) = 0.0;
uniform float pulse_amp = 0.06;            // max displacement at morph_t=1
uniform float pulse_freq = 6.0;            // spatial wave frequency
uniform float pulse_speed = 2.5;           // temporal wave speed
uniform vec4 base_color : source_color = vec4(0.95, 0.95, 0.92, 1.0);
uniform vec4 force_color : source_color = vec4(1.0, 0.55, 0.10, 1.0);

// Emission is LIVE for the first time, so these two are real numbers now.
//
// emission_base keeps its shipped 0.4. It is the reason a point is findable in
// an unlit room, which is the parent class's stated intent, and it is low
// enough that it lifts the shadow side without flattening the gradient the
// lights are there to draw.
//
// emission_force is LOWERED from 2.5. Under `unshaded` that number never
// reached a pixel; switched on as written it would put the red channel of the
// engaged shell straight through 255 and take the hue with it — the linter's
// CHANNEL CLIPPED fault, which kills a frame as surely as flatness does. 1.6
// is PbrKit.emissive()'s own default energy and it leaves the shell clearly
// self-lit above a diffuse that is now doing real work underneath it.
uniform float emission_base = 0.40;
uniform float emission_force = 1.60;

// ── The finish. Textures come from PbrKit's cache — no new VRAM. ──
uniform sampler2D grain_rough : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D grain_norm : hint_normal, filter_linear_mipmap, repeat_enable;
// (u, v) repeats of the grain across the sphere's UV square. Isotropic in
// METRES OF SURFACE ARC, which is why u is twice v: a sphere's u spans 2*pi*r
// and its v spans pi*r, so equal tiling in UV would give blobs twice as wide
// as they are tall. Default is r = 0.03 m at 7 tiles/m.
uniform vec2 grain_uv = vec2(1.3195, 0.6597);
// Mean of the ramped grain, so the roughness variation STRADDLES the target
// instead of sitting under it. Same correction PbrKit._rough applies.
uniform float grain_mean = 0.85;
// Rest: a satin instrument bead — a readable highlight with a real lobe, not
// a mirror with one microfacet value and nothing to reflect. Engaged: hazier,
// because a field scatters and because a tight specular under a live emission
// is how a bright surface clips.
uniform float rough_rest = 0.38;
uniform float rough_force = 0.62;
// NOT cut "to be safe". Micro normal is the only thing making a smooth ball
// read as a moulded object rather than as a gradient, and the failure mode is
// a grain sized wrong for the body — which is handled in grain_uv above, not
// here. 0.30 sits between PbrKit.hard_plastic's 0.10 and brushed_metal's 0.30,
// on the "visibly moulded" side, because the bead is photographed close.
uniform float normal_depth = 0.30;
// The cheapest thing that separates a 60 px sphere from its backdrop.
uniform float rim_amount = 0.26;

void vertex() {
	// Pulse along the local normal. Use VERTEX.xyz to vary the wave
	// across the mesh so the displacement reads as a rippling shell,
	// not a uniform inflate.
	float phase = TIME * pulse_speed
		+ VERTEX.x * pulse_freq
		+ VERTEX.y * pulse_freq * 0.8
		+ VERTEX.z * pulse_freq * 1.2;
	float w = sin(phase);
	w = w * 0.5 + 0.5;                  // [0, 1]
	float disp = morph_t * pulse_amp * (0.4 + 0.6 * w);
	VERTEX += NORMAL * disp;

	// The ripple's OWN slope, so the engaged shell is shaded by the wave it
	// actually has instead of by the sphere it used to be. Now that the
	// surface is lit, a displaced mesh carrying its undisplaced normals reads
	// as a lumpy ball lit as if it were smooth.
	//
	// d(disp)/dVERTEX = morph_t * pulse_amp * 0.6 * dw/dVERTEX, and
	// dw/dVERTEX = 0.5 * cos(phase) * (freq, freq*0.8, freq*1.2).
	// At morph_t = 0 this is zero to the byte and NORMAL is returned
	// untouched — the resting bead cannot be affected by any of it.
	vec3 grad = 0.3 * morph_t * pulse_amp * cos(phase)
		* vec3(pulse_freq, pulse_freq * 0.8, pulse_freq * 1.2);
	NORMAL = normalize(NORMAL - (grad - dot(grad, NORMAL) * NORMAL));
}

void fragment() {
	vec2 guv = UV * grain_uv;
	float g = texture(grain_rough, guv).r;

	vec3 col = mix(base_color.rgb, force_color.rgb, morph_t);

	// ONE modulation, and it is centred rather than subtractive: cool in the
	// pits, warm on the highs, mean 1.0. Three separate "slight" darkenings is
	// how a cream object arrives at charcoal, so there is no AO map and no
	// baked wear anywhere on this surface — this is the only one. It exists
	// because a neutral bead has no hue variation at all, and hue variation is
	// half of what "distinct colours" measures.
	ALBEDO = col * mix(vec3(0.940, 0.955, 0.990), vec3(1.045, 1.015, 0.965), g);

	METALLIC = 0.0;
	SPECULAR = 0.5;
	float target = mix(rough_rest, rough_force, morph_t);
	ROUGHNESS = clamp(target / grain_mean * g, 0.04, 0.95);

	NORMAL_MAP = texture(grain_norm, guv).rgb;
	NORMAL_MAP_DEPTH = normal_depth;

	RIM = rim_amount;
	RIM_TINT = 0.35;

	EMISSION = col * mix(emission_base, emission_force, morph_t);
}
