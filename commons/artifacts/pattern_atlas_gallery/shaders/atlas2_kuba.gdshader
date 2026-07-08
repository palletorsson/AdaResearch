// KUBA / SHOOWA — the weavers and embroiderers of the Kuba kingdom, DR
// Congo (men weave the raffia, women embroider). Angular interlace whose
// rule CHANGES section by section — improvisation as grammar, admired by
// Klee and Matisse. The stochastic rule, centuries early.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float g_scale : hint_range(0.3, 3.0) = 1.0;
uniform float g_weight : hint_range(0.4, 2.2) = 1.0;
uniform float g_wobble : hint_range(0.0, 2.5) = 1.0;
uniform vec3 g_tint : source_color = vec3(1.0, 1.0, 1.0);

float hash2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash2(i), b = hash2(i + vec2(1, 0)), c = hash2(i + vec2(0, 1)), d = hash2(i + vec2(1, 1));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 uv = UV;
	vec3 tan_ = vec3(0.80, 0.68, 0.48);
	vec3 blk = vec3(0.15, 0.12, 0.09);
	vec3 brick = vec3(0.55, 0.28, 0.16);
	// sections: the cloth is divided into irregular blocks, each with its OWN rule
	vec2 sect = floor(uv * vec2(3.0, 2.0) * g_scale);
	float rule = floor(hash2(sect) * 4.0);
	vec2 l = fract(uv * vec2(3.0, 2.0) * g_scale) * vec2(6.0, 5.0);
	vec3 col = tan_;
	float t = 0.16 * g_weight;
	if (rule < 1.0) {
		// diagonal key: zigzag lines
		float z = abs(fract(l.x + l.y) - 0.5);
		if (z < t) col = blk;
	} else if (rule < 2.0) {
		// opposed diagonal
		float z = abs(fract(l.x - l.y) - 0.5);
		if (z < t) col = blk;
		if (abs(fract(l.x - l.y + 0.5) - 0.5) < t * 0.5) col = brick;
	} else if (rule < 3.0) {
		// interlocking L / key meander
		vec2 k = fract(l) - 0.5;
		if (abs(k.x) < t || abs(k.y) < t) col = blk;
		if (max(abs(k.x), abs(k.y)) > 0.5 - t * 0.6) col = tan_;
	} else {
		// diamond chain
		vec2 k = fract(l) - 0.5;
		float d = abs(k.x) + abs(k.y);
		if (abs(d - 0.32) < t * 0.8) col = blk;
		if (d < 0.10) col = brick;
	}
	// section seams — the visible splice where the rule changes
	vec2 sf = fract(uv * vec2(3.0, 2.0) * g_scale);
	if (min(sf.x, sf.y) < 0.02 || max(sf.x, sf.y) > 0.98) col = mix(col, blk, 0.5);
	ALBEDO = col * g_tint;
}
