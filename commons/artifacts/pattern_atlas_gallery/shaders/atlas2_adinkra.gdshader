// ADINKRA — the carvers and stampers of Gyaman and Asante, Ghana. Calabash
// stamps in comb-divided fields; every symbol is a NAMED proverb — stamped
// repetition as rhetoric, like kanga's jina: the pattern is a text.
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
	vec3 russet = vec3(0.52, 0.24, 0.14);
	vec3 ink = vec3(0.12, 0.09, 0.07);
	vec3 col = russet * (0.95 + 0.05 * vnoise(uv * 30.0));
	// comb lines dividing the cloth into fields
	vec2 g = uv * vec2(4.0, 3.0) * g_scale;
	vec2 sf = fract(g);
	for (int k = 0; k < 3; k++) {
		float off = 0.012 + float(k) * 0.02;
		if (abs(sf.x - off) < 0.006 || abs(sf.y - off) < 0.006) col = ink;
	}
	// the stamp per field
	vec2 id = floor(g);
	vec2 c = sf - 0.53;
	float pick = hash2(id);
	float r = length(c);
	float t = 0.028 * g_weight;
	if (pick < 0.34) {
		// Adinkrahene — concentric circles: greatness, leadership
		if (abs(r - 0.10) < t || abs(r - 0.19) < t || abs(r - 0.28) < t) col = ink;
	} else if (pick < 0.67) {
		// crosshatch stamp
		vec2 q = c * 6.5;
		if ((abs(fract(q.x) - 0.5) < 0.10 * g_weight || abs(fract(q.y) - 0.5) < 0.10 * g_weight) && max(abs(c.x), abs(c.y)) < 0.30) col = ink;
	} else {
		// dwennimmen-like horns: two arcs facing
		float th = atan(c.y, c.x);
		if (abs(r - 0.20) < t * 1.4 && abs(sin(th * 2.0)) > 0.45) col = ink;
		if (r < 0.06) col = ink;
	}
	ALBEDO = col * g_tint;
}
