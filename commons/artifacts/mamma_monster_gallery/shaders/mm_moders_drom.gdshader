// MODERS DROM — Mothers Dream (2023), Palle Torsson after Kristina Torsson.
// 25,000 frames; every 280 the AI given more freedom. Here the whole cycle
// lives in one shader: a pattern field breathing between weave and dream.
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
	// the freedom cycle: dream amplitude rises and falls like the 280 frames
	float freedom = (0.5 + 0.5 * sin(TIME * 0.15)) * max(g_dream, 0.15);
	vec2 uv = UV;
	// deep domain warp — the img2img drift, forest tableau underneath
	vec2 w = uv;
	for (int i = 0; i < 3; i++) {
		w += freedom * 0.22 * vec2(vnoise(w * 3.0 + float(i) * 7.3 + TIME * 0.03) - 0.5,
		                           vnoise(w * 3.0 + 13.1 - float(i) * 4.7 - TIME * 0.02) - 0.5) * 2.0;
	}
	// the mother-pattern beneath: stripes x beans x check, chosen by region
	float region = vnoise(w * 2.0);
	vec3 col;
	if (region < 0.36) {
		float band = mod(floor(w.y * 9.0 * g_scale), 5.0);
		col = band < 1.0 ? vec3(0.78, 0.22, 0.24) : band < 2.0 ? vec3(0.90, 0.55, 0.15)
		    : band < 3.0 ? vec3(0.34, 0.28, 0.52) : band < 4.0 ? vec3(0.24, 0.45, 0.32)
		    : vec3(0.92, 0.87, 0.74);
	} else if (region < 0.62) {
		vec2 c = fract(w * 5.0 * g_scale) - 0.5;
		col = length(c * vec2(1.0, 1.5)) < 0.30 ? vec3(0.45, 0.58, 0.30) : vec3(0.91, 0.86, 0.72);
	} else {
		float ck = mod(floor(w.x * 10.0 * g_scale) + floor(w.y * 10.0 * g_scale), 2.0);
		col = ck < 1.0 ? vec3(0.07, 0.07, 0.09) : vec3(0.92, 0.92, 0.95);
	}
	// forest light through the dream
	col = mix(col, vec3(0.20, 0.42, 0.30), freedom * 0.35 * vnoise(w * 1.3 + 5.0));
	ALBEDO = col * g_tint;
}
