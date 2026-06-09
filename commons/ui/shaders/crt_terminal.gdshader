shader_type spatial;
render_mode unshaded, cull_disabled;

// ── CRT TERMINAL SCREEN GLASS ─────────────────────────────────────────────
// A phosphor "tube" for the monitor_setup info screens. This is the SCREEN GLASS
// only — the readable text rides ON TOP as Label3D (so it stays crisp and
// capture-safe in headless --no-window renders). This shader animates the glass:
// rolling scanlines, a faint flicker, a soft phosphor bloom, corner vignette and a
// subtle chromatic-aberration edge tint, emitted so the tube glows in the dark.
//
// SYNC: every animated term below is driven by the built-in `TIME` uniform, which
// the engine feeds identically to every material instance using this shader. No
// per-node time is passed in, so every monitor's glass scrolls, flickers and
// breathes in lockstep automatically — a whole wall pulsing as one.

uniform vec3 phosphor : source_color = vec3(0.35, 1.0, 0.45); // tube glow colour
uniform float scan_speed = 1.0;        // rows scroll speed (× TIME)
uniform float scan_density = 220.0;    // scanline count across the panel height
uniform float flicker_amt = 0.06;      // brightness wobble amount (0 = steady)
uniform float glow = 0.6;              // soft bloom toward phosphor (centre lift)
uniform float vignette_amt = 0.5;      // corner darkening strength
uniform float aberration = 0.5;        // chromatic tint at the horizontal edges
uniform float intensity = 1.0;         // master multiplier (crt_intensity export)

void fragment() {
	vec2 uv = UV;

	// Dark phosphor base — a near-black tube with a faint phosphor cast.
	vec3 base = phosphor * 0.06;

	// ── ROLLING SCANLINES ──
	// A sine over UV.y, scrolled by TIME*scan_speed so the bands creep upward in
	// sync on every screen. `scan_density` sets how many lines span the panel.
	float scan = sin((uv.y * scan_density) - (TIME * scan_speed * 6.2831853));
	// Map -1..1 → a soft 0.55..1.0 darken band (subtle, keeps text legible).
	float scan_band = mix(0.55, 1.0, scan * 0.5 + 0.5);

	// ── FLICKER ──
	// Two desynced sines of TIME → a small global brightness wobble. Same TIME on
	// every instance ⇒ every tube flickers together.
	float flick = 1.0 + flicker_amt * (
		sin(TIME * 11.0) * 0.5 + sin(TIME * 23.7 + 1.3) * 0.5);

	// ── SOFT GLOW / BLOOM ──
	// Lift the centre toward full phosphor; corners stay dimmer. Distance from the
	// panel centre drives a smooth falloff that biases the colour to `phosphor`.
	vec2 from_center = uv - vec2(0.5);
	float dist = length(from_center);
	float bloom = (1.0 - smoothstep(0.0, 0.85, dist)) * glow;
	vec3 col = base + phosphor * bloom;

	// Apply the rolling scanline darken + the flicker wobble.
	col *= scan_band * flick;

	// ── CHROMATIC ABERRATION ──
	// Tint the left/right edges: push red one way and blue the other, strongest at
	// the horizontal extremes. Cheap fake of lens/beam misconvergence on the glass.
	float edge = abs(from_center.x) * 2.0; // 0 centre → 1 at the L/R edges
	float ab = edge * edge * aberration;
	col.r += ab * 0.18;
	col.b += ab * 0.18;

	// ── VIGNETTE ──
	// Darken the corners. Radial falloff multiplied back in so the tube reads round.
	float vig = 1.0 - vignette_amt * smoothstep(0.35, 0.95, dist);
	col *= vig;

	// Master intensity (crt_intensity). Keep the base albedo dark; the life is in
	// EMISSION so the tube glows in an unlit room.
	col *= intensity;

	ALBEDO = base * intensity;
	EMISSION = col;
}
