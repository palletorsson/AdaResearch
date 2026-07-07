// FJADER — Kristina Torsson, Vamlingbolaget. A beautiful feather in the
// henyard became the pattern: quill, barbs, the soft taper. Interpreted
// from the written record.
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
	vec2 g = uv * vec2(3.0, 2.0) * g_scale;
	vec2 id = floor(g);
	vec2 c = fract(g) - 0.5;
	if (mod(id.x + id.y, 2.0) < 1.0) c.y = -c.y;   // alternate feather direction
	vec3 ground = vec3(0.93, 0.88, 0.78);
	vec3 quill = vec3(0.42, 0.36, 0.28);
	vec3 vane = vec3(0.55, 0.60, 0.55);
	vec3 tipc = vec3(0.80, 0.45, 0.30);
	vec3 col = ground;
	// quill: vertical center line with taper
	float taper = smoothstep(0.48, -0.35, c.y);
	if (abs(c.x) < 0.012 * g_weight + 0.004 && abs(c.y) < 0.42) col = quill;
	// barbs: angled strokes off the quill, denser with g_weight
	float bar = fract((c.y + abs(c.x) * 1.1) * 14.0 * g_weight);
	float within = step(abs(c.x), 0.16 * taper) * step(abs(c.y), 0.40);
	if (within > 0.5 && bar < 0.42) col = vane;
	if (within > 0.5 && bar < 0.42 && c.y > 0.22) col = tipc;   // the warm tip
	ALBEDO = col * g_tint;
}
