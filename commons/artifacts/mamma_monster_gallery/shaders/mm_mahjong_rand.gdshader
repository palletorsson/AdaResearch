// MAH-JONG RAND — Kristina Torsson, Helena Henschen, Veronika Nygren, 1966.
// The soft, colorful clothes that were meant to change people: stripe as
// ideology, jersey as program. The analog edge kept alive in the wobble.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float g_scale : hint_range(0.3, 3.0) = 1.0;
uniform float g_weight : hint_range(0.4, 2.2) = 1.0;
uniform float g_wobble : hint_range(0.0, 2.5) = 1.0;
uniform float g_dream : hint_range(0.0, 1.0) = 0.35;
uniform vec3 g_tint : source_color = vec3(1.0, 1.0, 1.0);

float hash2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash2(i), b = hash2(i + vec2(1, 0)), c = hash2(i + vec2(0, 1)), d = hash2(i + vec2(1, 1));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}
// the Mothers Dream oscillation: every 280 frames the AI got more freedom.
// Here the dream breathes on TIME — pattern and dream trading places.
vec2 dreamwarp(vec2 uv) {
	float breath = 0.5 + 0.5 * sin(TIME * 0.22);         // the slow 280-frame cycle
	float amp = g_dream * breath * 0.12 * g_wobble;
	return uv + amp * vec2(vnoise(uv * 5.0 + TIME * 0.05) - 0.5,
	                       vnoise(uv * 5.0 + 31.7 - TIME * 0.04) - 0.5) * 2.0;
}

void fragment() {
	vec2 uv = dreamwarp(UV);
	// the analog imperfection: each stripe edge wavers slightly
	float y = uv.y * 9.0 * g_scale + (vnoise(vec2(uv.x * 3.0, uv.y * 40.0)) - 0.5) * 0.22 * g_wobble;
	float band = floor(y);
	float pick = mod(band, 5.0);
	vec3 col =
		pick < 1.0 ? vec3(0.78, 0.22, 0.24) :   // rod
		pick < 2.0 ? vec3(0.90, 0.55, 0.15) :   // orange
		pick < 3.0 ? vec3(0.34, 0.28, 0.52) :   // lila
		pick < 4.0 ? vec3(0.24, 0.45, 0.32) :   // gron
		             vec3(0.92, 0.87, 0.74);    // ull-vit
	// knit texture
	col *= 0.94 + 0.06 * step(0.5, fract(uv.x * 120.0 * g_weight));
	ALBEDO = col * g_tint;
}
