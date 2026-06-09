shader_type spatial;
render_mode unshaded, cull_disabled;

// ── CRT GLASS OVER A RENDERED TEXTURE ─────────────────────────────────────
// Companion to crt_terminal.gdshader. That one is a STANDALONE phosphor tube (no
// content — the readable text rode on top as Label3D). THIS one composites the CRT
// glass effects OVER an actual rendered image: the SubViewport texture of the 2D
// terminal Control (the "2D-in-3D" face). So the rich monospace terminal text is the
// real, sampled pixels, and the scanlines / flicker / bloom / aberration / vignette
// live ON TOP — animated by TIME so every screen syncs.
//
// `screen_tex` is the viewport's ViewportTexture, assigned per material by
// monitor_setup.gd after the 2D scene instance is live. When it is missing/blank the
// sample is just black and the shader degrades to a dark phosphor tube.

uniform sampler2D screen_tex : source_color, filter_linear, repeat_disable;
uniform vec3 phosphor : source_color = vec3(0.35, 1.0, 0.45); // tube glow tint
uniform float scan_speed = 1.0;        // rows scroll speed (× TIME)
uniform float scan_density = 220.0;    // scanline count across the panel height
uniform float flicker_amt = 0.06;      // brightness wobble amount (0 = steady)
uniform float glow = 0.35;             // soft phosphor bloom lift at the centre
uniform float vignette_amt = 0.45;     // corner darkening strength
uniform float aberration = 0.5;        // chromatic split at the horizontal edges
uniform float intensity = 1.0;         // master multiplier (crt_intensity export)

void fragment() {
	vec2 uv = UV;
	vec2 from_center = uv - vec2(0.5);

	// ── CHROMATIC ABERRATION ──
	// Sample R/G/B at slightly offset UVs, strongest at the L/R edges, so the rendered
	// text fringes like a misconverged beam near the glass corners.
	float edge = abs(from_center.x) * 2.0;          // 0 centre → 1 at the L/R edges
	float ab = edge * edge * aberration * 0.004;    // tiny UV offset
	float r = texture(screen_tex, uv + vec2(ab, 0.0)).r;
	float g = texture(screen_tex, uv).g;
	float b = texture(screen_tex, uv - vec2(ab, 0.0)).b;
	vec3 src = vec3(r, g, b);

	// ── ROLLING SCANLINES ──
	// A sine over UV.y scrolled by TIME so the bands creep upward in sync on every screen.
	float scan = sin((uv.y * scan_density) - (TIME * scan_speed * 6.2831853));
	float scan_band = mix(0.88, 1.0, scan * 0.5 + 0.5); // gentle — keeps text legible

	// ── FLICKER ──
	// Two desynced sines of TIME → a small global brightness wobble, identical per screen.
	float flick = 1.0 + flicker_amt * (
		sin(TIME * 11.0) * 0.5 + sin(TIME * 23.7 + 1.3) * 0.5);

	// ── SOFT PHOSPHOR BLOOM ──
	// Lift the image toward the phosphor tint near the centre; corners stay truer.
	float dist = length(from_center);
	float bloom = (1.0 - smoothstep(0.0, 0.85, dist)) * glow;
	vec3 col = src + phosphor * bloom * (0.3 + 0.7 * dot(src, vec3(0.333)));

	// Apply the rolling scanline darken + flicker.
	col *= scan_band * flick;

	// ── VIGNETTE ──
	float vig = 1.0 - vignette_amt * smoothstep(0.35, 0.98, dist);
	col *= vig;

	// Master intensity (crt_intensity).
	col *= intensity;

	// Keep a near-black albedo; the life is in EMISSION so the tube glows unlit.
	// Boosted so the small terminal text reads clearly through the glass.
	ALBEDO = src * 0.04;
	EMISSION = col * 1.7;
}
