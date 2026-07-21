shader_type spatial;
render_mode unshaded, blend_mix, cull_back, shadows_disabled;

// biome-presence — the ground answers the standing life.
//
// GridBiomeComponent bakes a small presence texture (one texel per grid
// cell: RGB = blended kingdom color, A = influence) from every ACTIVE,
// UNMUTED declared cell — seeds, halos, claimed fields, reaction-opened
// vacuums. This shader draws it as a soft stain on per-cell quads seated
// on the real structure heights (one MultiMesh, biome-6 discipline).
//
// The stain BREATHES — a slow phase-offset pulse so non-moving life reads
// as alive without moving — and it is rebuilt on every reaction, so a CA
// claim visibly spreads its ground. Muted cells contribute nothing: the
// declared vacuum stays dry (sieve Q3).
//
// Per-instance CUSTOM carries the cell address (col, row); UV is derived
// from it so linear filtering blends the stain smoothly across quads.

uniform sampler2D presence_tex : filter_linear, repeat_disable;
uniform float grid_cols = 8.0;
uniform float grid_rows = 8.0;
uniform float stain_alpha = 0.55;
uniform float breath_speed = 0.7;

varying vec2 v_uv;

void vertex() {
	// unit plane (1x1, VERTEX.xz in -0.5..0.5) scaled to the cell; INSTANCE_CUSTOM
	// holds (col, row) — texel center plus the vertex offset = smooth UV.
	vec2 cell = INSTANCE_CUSTOM.xy;
	v_uv = vec2(
		(cell.x + 0.5 + VERTEX.x) / grid_cols,
		(cell.y + 0.5 + VERTEX.z) / grid_rows);
}

void fragment() {
	vec4 p = texture(presence_tex, v_uv);
	// slow breath, phase scattered over the field so it shimmers, not throbs
	float breath = 0.85 + 0.15 * sin(TIME * breath_speed + (v_uv.x * 13.0 + v_uv.y * 7.0));
	// grain so the stain reads as ground moisture, not a decal
	float grain = 0.9 + 0.2 * fract(sin(dot(floor(v_uv * vec2(grid_cols, grid_rows) * 6.0),
		vec2(12.9898, 78.233))) * 43758.5453);
	ALBEDO = p.rgb;
	ALPHA = clamp(p.a * stain_alpha * breath * grain, 0.0, 1.0);
	EMISSION = p.rgb * p.a * 0.3 * breath;
}
