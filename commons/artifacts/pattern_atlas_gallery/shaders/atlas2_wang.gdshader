// WANG TILES — Hao Wang (1961), Robert Berger (1966). Squares with colored
// edges; adjacent edges must match. Whether a tile set can tile the plane at
// all is UNDECIDABLE — the domino problem reduces to halting. Here every
// edge color is derived from the shared edge itself, so the tiling is legal
// by construction: craft-fit as theorem.
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

vec3 edge_col(float h) {
	return h < 0.25 ? vec3(0.79, 0.25, 0.20) :
	       h < 0.50 ? vec3(0.95, 0.77, 0.24) :
	       h < 0.75 ? vec3(0.16, 0.42, 0.58) : vec3(0.24, 0.55, 0.36);
}
void fragment() {
	vec2 g = UV * vec2(6.0, 4.0) * g_scale;
	vec2 id = floor(g);
	vec2 c = fract(g) - 0.5;
	// which triangle of the tile? (N/E/S/W by dominant axis)
	bool horiz = abs(c.x) > abs(c.y);
	vec3 col;
	if (horiz) {
		float e = c.x > 0.0 ? 1.0 : 0.0;            // E or W edge
		col = edge_col(hash2(vec2(id.x + e, id.y) * 1.7 + 0.31));   // shared with neighbor
	} else {
		float e = c.y > 0.0 ? 1.0 : 0.0;            // N or S edge
		col = edge_col(hash2(vec2(id.x, id.y + e) * 2.3 + 7.77));
	}
	// tile seams + diagonals
	float seam = min(abs(abs(c.x) - 0.5), abs(abs(c.y) - 0.5));
	float diag = abs(abs(c.x) - abs(c.y));
	if (diag < 0.015 * g_weight) col *= 0.55;
	if (seam < 0.02 * g_weight) col = vec3(0.12, 0.11, 0.10);
	ALBEDO = col * g_tint;
}
