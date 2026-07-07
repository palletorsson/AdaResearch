// VARMA BACKEN — Kristina Torsson, Vamlingbolaget. From the meadow edges of
// Sudret: Lojtnantshjarta (bleeding heart), Kaprifol, Akleia. The winding
// line that suspends the grid's order. Interpreted from the written record.
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
	vec2 uv = dreamwarp(UV) * g_scale;
	vec3 warm = vec3(0.96, 0.90, 0.74);       // the warm slope
	vec3 stem = vec3(0.33, 0.48, 0.28);
	vec3 heart = vec3(0.85, 0.42, 0.55);      // bleeding-heart pink
	vec3 gold = vec3(0.90, 0.66, 0.25);       // honeysuckle
	vec3 col = warm;
	// winding stems: vertical sines, offset per column
	float cx = uv.x * 3.0;
	float lane = floor(cx);
	float u = fract(cx);
	float sway = sin(uv.y * 6.28 * 1.5 + hash2(vec2(lane, 3.0)) * 6.28) * 0.18 * g_wobble;
	float d = abs(u - 0.5 - sway);
	if (d < 0.025 * g_weight) col = stem;
	// hanging hearts along the stem: rows of pendants
	float row = floor(uv.y * 6.0);
	float ry = fract(uv.y * 6.0);
	vec2 hp = vec2(u - 0.5 - sway, ry - 0.42);
	hp.x *= 1.4;
	float hd = length(hp - vec2(0.0, clamp(hp.y, -0.03, 0.0)));
	if (mod(row + lane, 2.0) < 1.0 && hd < 0.085 * g_weight) col = heart;
	if (mod(row + lane, 2.0) < 1.0 && hd < 0.03 * g_weight) col = warm;   // the drop's split
	// honeysuckle flecks
	vec2 g = fract(uv * vec2(6.0, 5.0)) - 0.5;
	if (mod(floor(uv.x * 6.0) + floor(uv.y * 5.0), 3.0) < 1.0 && length(g) < 0.06 * g_weight) col = gold;
	ALBEDO = col * g_tint;
}
