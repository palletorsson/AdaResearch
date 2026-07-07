// Ikat - resist-dyers of Indonesia, Central Asia, Japan, India. The pattern
// is dyed into the threads BEFORE weaving: the blur is the signature.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float g_scale : hint_range(0.3, 3.0) = 1.0;
uniform float g_weight : hint_range(0.4, 2.2) = 1.0;
uniform float g_wobble : hint_range(0.0, 2.5) = 1.0;
uniform vec3 g_tint : source_color = vec3(1.0, 1.0, 1.0);
float hash1(float p) { return fract(sin(p * 127.1) * 43758.5453); }

void fragment() {
	vec2 uv = UV;
	float row = floor(uv.y * 90.0);
	uv.x += (hash1(row) - 0.5) * 0.035 * g_wobble;
	vec2 cell = fract(uv * vec2(3.0, 2.0) * g_scale) - 0.5;
	float dia = abs(cell.x) + abs(cell.y);
	vec3 bg = vec3(0.10, 0.14, 0.30);
	vec3 fg = vec3(0.90, 0.86, 0.76);
	vec3 ac = vec3(0.68, 0.19, 0.11);
	vec2 id = floor(uv * vec2(3.0, 2.0) * g_scale);
	vec3 mote = mod(id.x + id.y, 3.0) < 1.0 ? ac : fg;
	vec3 col = bg;
	if (dia < 0.34 * g_weight) col = mote;
	if (dia < 0.16 / max(g_weight, 0.6)) col = bg;
	col *= 0.92 + 0.08 * step(0.5, fract(uv.y * 90.0));
	ALBEDO = col * g_tint;
}
