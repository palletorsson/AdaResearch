// Indigo shibori - resist-dyers of Japan, Yoruba Nigeria, worldwide.
// Fold, bind, stitch: the binding decides the symmetry.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float g_scale : hint_range(0.3, 3.0) = 1.0;
uniform float g_weight : hint_range(0.4, 2.2) = 1.0;
uniform float g_wobble : hint_range(0.0, 2.5) = 1.0;
uniform vec3 g_tint : source_color = vec3(1.0, 1.0, 1.0);
float hash2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	vec2 g = UV * vec2(4.0, 3.0) * g_scale;
	vec2 id = floor(g);
	vec2 c = fract(g) - 0.5;
	float th = atan(c.y, c.x);
	float wob = (hash2(id + floor(th * 4.5)) - 0.5) * 0.06 * g_wobble;
	float r = length(c) + wob;
	vec3 indigo = vec3(0.13, 0.20, 0.47);
	vec3 white = vec3(0.93, 0.91, 0.85);
	vec3 col = indigo * (0.92 + 0.08 * hash2(UV * 40.0));
	float band = abs(sin(r * 21.0 * g_weight));
	if (band > 0.82 && r < 0.45) col = mix(indigo, white, (band - 0.82) / 0.18);
	ALBEDO = col * g_tint;
}
