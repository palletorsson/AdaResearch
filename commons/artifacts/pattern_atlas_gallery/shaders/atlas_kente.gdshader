// Kente - Ashanti & Ewe strip-weavers, Ghana. Strips sewn edge-to-edge;
// each block sequence a named proverb. The rule reproduced as a shader.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float g_scale : hint_range(0.3, 3.0) = 1.0;
uniform float g_weight : hint_range(0.4, 2.2) = 1.0;
uniform float g_wobble : hint_range(0.0, 2.5) = 1.0;
uniform vec3 g_tint : source_color = vec3(1.0, 1.0, 1.0);
float hash2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	vec2 uv = UV;
	float strip = floor(uv.x * 5.0 * g_scale);
	float sx = fract(uv.x * 5.0 * g_scale);
	float boff = hash2(vec2(strip, 7.0)) * 3.0;
	float block = floor(uv.y * 4.0 * g_scale + boff);
	float by = fract(uv.y * 4.0 * g_scale + boff);
	float kind = floor(hash2(vec2(strip, block)) * 3.0);
	vec3 gold = vec3(0.91, 0.70, 0.10);
	vec3 blk = vec3(0.09, 0.08, 0.06);
	vec3 red = vec3(0.70, 0.19, 0.11);
	vec3 grn = vec3(0.12, 0.42, 0.20);
	vec3 col = gold;
	if (kind < 1.0) {
		col = mod(floor(by * 8.0 * g_weight), 2.0) < 1.0 ? gold : blk;
	} else if (kind < 2.0) {
		float bar = mod(floor(sx * 7.0 * g_weight), 2.0);
		col = bar < 1.0 ? gold : (mod(floor(sx * 3.5), 2.0) < 1.0 ? red : grn);
	} else {
		vec2 q = fract(vec2(sx, by) * 2.0);
		col = (q.x > 0.15 && q.x < 0.85 && q.y > 0.15 && q.y < 0.85) ? blk : red;
	}
	if (sx > 0.96) col = blk * 0.8;
	ALBEDO = col * g_tint;
}
