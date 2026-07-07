// BONAN — Kristina Torsson, Vamlingbolaget. Found in the pistachio bowl
// during an evening yatzy game: the pattern was lying there all along.
// Chance as the source. Interpreted from the written record.
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
	vec2 g = uv * vec2(5.0, 4.0) * g_scale;
	if (mod(floor(g.y), 2.0) > 0.5) g.x += 0.5;
	vec2 id = floor(g);
	vec2 c = fract(g) - 0.5;
	// each bean tumbles at a chance angle — the yatzy throw
	float a = hash2(id) * 6.2832 * g_wobble;
	vec2 r = vec2(c.x * cos(a) - c.y * sin(a), c.x * sin(a) + c.y * cos(a));
	// kidney: circle minus an off-centre bite
	float body = length(r * vec2(1.0, 1.55));
	float bite = length((r - vec2(0.10, 0.0)) * vec2(1.0, 1.9));
	vec3 shell = vec3(0.91, 0.86, 0.72);      // pistachio cream
	vec3 bean = vec3(0.45, 0.58, 0.30);       // pistachio green
	vec3 dark = vec3(0.30, 0.38, 0.22);
	vec3 col = shell;
	if (body < 0.30 * g_weight && bite > 0.14) col = bean;
	if (body < 0.30 * g_weight && bite > 0.14 && r.x < -0.05) col = mix(bean, dark, 0.5);
	ALBEDO = col * g_tint;
}
