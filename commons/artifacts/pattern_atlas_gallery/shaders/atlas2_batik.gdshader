// BATIK — the batik makers of Java, canting hands and cap stampers, largely
// women (UNESCO-listed craft). Hot wax resists the dye; the CRACKLE is where
// the wax broke — the fault-lines are the proof a hand was there.
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
	vec3 soga = vec3(0.45, 0.29, 0.14);      // soga brown
	vec3 cream = vec3(0.92, 0.86, 0.70);
	vec3 indigo = vec3(0.16, 0.18, 0.32);
	// kawung: four ellipses around each grid point
	vec2 g = uv * vec2(5.0, 4.0) * g_scale;
	vec2 id = floor(g);
	vec2 c = fract(g) - 0.5;
	vec3 col = soga;
	for (int i = 0; i < 4; i++) {
		float a = float(i) * 1.5708 + 0.7854;
		vec2 p = c - vec2(cos(a), sin(a)) * 0.27;
		vec2 q = vec2(p.x * cos(a) + p.y * sin(a), -p.x * sin(a) + p.y * cos(a));
		if (length(q * vec2(1.0, 2.1)) < 0.20 * g_weight) col = cream;
		if (length(q * vec2(1.0, 2.1)) < 0.07 * g_weight) col = indigo;
	}
	// the crackle: ridges of value noise, only through the waxed (cream) zones
	float n = vnoise(uv * 26.0);
	float crack = smoothstep(0.028 * g_wobble, 0.0, abs(n - 0.5));
	if (col == cream || crack > 0.0) col = mix(col, indigo * 0.8, crack * 0.8 * step(0.4, distance(col, soga)));
	ALBEDO = col * g_tint;
}
