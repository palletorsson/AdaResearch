// RUTAN OSCILLERAR — the teenage room in Vamlingbo: checkered floor,
// mirrors, satin, neon silk. 'A check pattern that begins to oscillate
// before the eyes' — the queer CGI room before CGI. TIME-animated.
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
	// the check breathes: scale oscillates gently, moire against itself
	float osc = 1.0 + 0.08 * sin(TIME * 0.9) * g_wobble;
	vec2 q1 = uv * 10.0 * g_scale;
	vec2 q2 = uv * 10.0 * g_scale * osc + vec2(0.5 * sin(TIME * 0.35), 0.0);
	float c1 = mod(floor(q1.x) + floor(q1.y), 2.0);
	float c2 = mod(floor(q2.x) + floor(q2.y), 2.0);
	vec3 blk = vec3(0.07, 0.07, 0.09);
	vec3 wht = vec3(0.92, 0.92, 0.95);
	vec3 neonA = vec3(0.95, 0.25, 0.75);     // neon silk
	vec3 neonB = vec3(0.25, 0.95, 0.75);
	vec3 col = c1 < 1.0 ? blk : wht;
	// where the two checks disagree, the neon bleeds through — the oscillation
	if (abs(c1 - c2) > 0.5) col = mix(neonA, neonB, 0.5 + 0.5 * sin(TIME * 0.5 + uv.x * 4.0));
	// satin sheen sweep
	float sheen = pow(max(0.0, sin(uv.x * 3.1 + uv.y * 1.7 + TIME * 0.6)), 8.0);
	col += sheen * 0.15 * g_weight;
	ALBEDO = col * g_tint;
}
