shader_type spatial;
render_mode cull_disabled;
// A floor of square tiles, five, four or three at every corner, drawn round the one who walks it.
// Every fragment of the deck is a place at some distance and bearing from the walker; that place is carried into
// the tile the walker stands in (vinv) and folded across the tile's edges until it lies in that tile.
// Complex numbers are vec2. kind is the curvature's sign: -1 five at a corner, 0 four, 1 three.
uniform int kind = -1;
uniform vec2 body = vec2(0.0);
uniform vec2 vinv_a = vec2(1.0, 0.0);
uniform vec2 vinv_b = vec2(0.0);
uniform vec2 g_a = vec2(1.0, 0.0);
uniform vec2 g_b = vec2(0.0);
uniform bool home_on = false;
uniform float deck_r = 2.6;
uniform float horizon = 3.0;       // five at a corner: the rim that keeps this distance from the walker
uniform float centre_far = 2.0;    // the edges' circles: how far their centres lie (negative: on the far side)
uniform float sigma = 1.8;         // and their radius
uniform float half_w = 0.275;      // half a tile, in the picture's own unit
uniform vec3 tile_colour : source_color = vec3(0.86, 0.83, 0.76);
uniform vec3 line_colour : source_color = vec3(0.16, 0.17, 0.2);
uniform vec3 home_colour : source_color = vec3(0.76, 0.07, 0.11);
uniform vec3 rim_colour : source_color = vec3(0.2, 0.2, 0.24);
const vec2 DIRS[4] = vec2[4](vec2(1.0, 0.0), vec2(0.0, 1.0), vec2(-1.0, 0.0), vec2(0.0, -1.0));
varying vec2 at;

void vertex() {
	at = VERTEX.xz;
}

vec2 cmul(vec2 a, vec2 b) { return vec2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x); }
vec2 cdiv(vec2 a, vec2 b) { return vec2(a.x * b.x + a.y * b.y, a.y * b.x - a.x * b.y) / max(dot(b, b), 1e-12); }
vec2 conj(vec2 a) { return vec2(a.x, -a.y); }
vec2 carry(vec2 a, vec2 b, vec2 z) { return cdiv(cmul(a, z) + b, cmul(-float(kind) * conj(b), z) + conj(a)); }

bool beyond(vec2 z, int i) {
	vec2 q = z - centre_far * DIRS[i];
	float l2 = dot(q, q);
	return kind < 0 ? l2 < sigma * sigma : l2 > sigma * sigma;
}

void fragment() {
	if (length(at) > deck_r) discard;
	vec2 p = at - body;
	float far = length(p);
	vec2 dir = far > 1e-5 ? p / far : vec2(1.0, 0.0);
	float d = far;
	float fade = 0.0;
	if (kind < 0) {
		float part = min(far / horizon, 0.999);
		d = horizon * atanh(part);
		fade = smoothstep(0.82, 0.985, far / horizon);
	}
	float t = 0.5 * d;
	if (kind < 0) t = tanh(0.5 * d);
	else if (kind > 0) t = clamp(tan(0.5 * d), -1e4, 1e4);
	vec2 w = dir * t;
	vec2 z = carry(vinv_a, vinv_b, w);
	vec2 zh = carry(g_a, g_b, w);
	float edge = 1e3;
	if (kind == 0) {
		z = mod(z + vec2(half_w), 2.0 * half_w) - vec2(half_w);
		edge = (half_w - max(abs(z.x), abs(z.y))) * 2.0;
	} else {
		for (int n = 0; n < 14; n++) {
			bool moved = false;
			for (int i = 0; i < 4; i++) {
				if (beyond(z, i)) {
					vec2 c = centre_far * DIRS[i];
					vec2 q = z - c;
					z = c + q * (sigma * sigma / max(dot(q, q), 1e-12));
					moved = true;
				}
			}
			if (!moved) break;
		}
		float scale = 2.0 / (1.0 + float(kind) * dot(z, z));
		for (int i = 0; i < 4; i++) edge = min(edge, abs(length(z - centre_far * DIRS[i]) - sigma) * scale);
	}
	vec3 colour = mix(line_colour, tile_colour, smoothstep(0.018, 0.04, edge));
	if (2.0 * length(z) < 0.05) colour = line_colour;
	// home: the tile the walker stood on, with an arrow that pointed north when it was set
	bool home = home_on;
	if (home) {
		if (kind == 0) home = max(abs(zh.x), abs(zh.y)) <= half_w;
		else for (int i = 0; i < 4; i++) { if (beyond(zh, i)) home = false; }
	}
	if (home) {
		vec2 u = zh / half_w;
		bool shaft = abs(u.x) < 0.08 && u.y > -0.42 && u.y < 0.55;
		bool head = u.y <= -0.42 && u.y > -0.78 && abs(u.x) < (u.y + 0.78) * 0.85;
		colour = (shaft || head) ? vec3(0.96, 0.94, 0.9) : mix(line_colour, home_colour, smoothstep(0.018, 0.04, edge));
	}
	ALBEDO = mix(colour, rim_colour, fade);
	ROUGHNESS = 0.9;
}
