// SASHIKO / HITOMEZASHI — the farm households of northern Japan, mostly
// women: mending as pattern. One coin-flip per row and per column; a stitch
// appears where the bits agree — an XOR rule, and mazes emerge. The purest
// binary pattern in the atlas.
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
	vec3 indigo = vec3(0.14, 0.19, 0.38);
	vec3 thread = vec3(0.93, 0.92, 0.86);
	float N = 22.0 * g_scale;
	vec2 g = uv * N;
	vec2 id = floor(g);
	vec2 f = fract(g);
	vec3 col = indigo * (0.94 + 0.06 * vnoise(uv * 60.0));
	float t = 0.09 * g_weight;
	// row bit decides horizontal stitch phase; column bit the vertical
	float rowbit = step(0.5, hash2(vec2(0.0, id.y)));
	float colbit = step(0.5, hash2(vec2(id.x, 0.0)));
	// horizontal stitch on this cell's bottom edge if (i + rowbit) even
	if (f.y < t && mod(id.x + rowbit, 2.0) < 1.0) col = thread;
	// vertical stitch on left edge if (j + colbit) even
	if (f.x < t && mod(id.y + colbit, 2.0) < 1.0) col = thread;
	ALBEDO = col * g_tint;
}
