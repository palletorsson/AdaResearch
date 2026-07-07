// Zellige / girih - al-Andalus & Maghreb tile-cutters (maalem). The
// eight-point star: two rotated squares tessellating with the cross.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float g_scale : hint_range(0.3, 3.0) = 1.0;
uniform float g_weight : hint_range(0.4, 2.2) = 1.0;
uniform float g_wobble : hint_range(0.0, 2.5) = 1.0;
uniform vec3 g_tint : source_color = vec3(1.0, 1.0, 1.0);

float sqr(vec2 p, float s) { vec2 d = abs(p); return max(d.x, d.y) - s; }

void fragment() {
	vec2 g = fract(UV * vec2(4.0, 3.0) * g_scale) - 0.5;
	vec3 ground = vec3(0.08, 0.37, 0.32);
	vec3 white = vec3(0.95, 0.93, 0.87);
	vec3 terra = vec3(0.70, 0.29, 0.16 * g_weight);
	vec3 cobalt = vec3(0.11, 0.27, 0.53);
	float cs = cos(0.7854); float sn = sin(0.7854);
	vec2 rot = vec2(g.x * cs - g.y * sn, g.x * sn + g.y * cs);
	float star = min(sqr(g, 0.30 * g_weight), sqr(rot, 0.30 * g_weight));
	vec3 col = ground;
	if (star < 0.0) col = terra;
	if (star < -0.045) col = white;
	if (min(sqr(g, 0.16 * g_weight), sqr(rot, 0.16 * g_weight)) < 0.0) col = cobalt;
	if (star > 0.0 && star < 0.02) col = white;
	ALBEDO = col * g_tint;
}
