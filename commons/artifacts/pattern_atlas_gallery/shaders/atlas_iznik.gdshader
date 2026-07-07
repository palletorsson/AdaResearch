// Iznik - fritware potters of Ottoman Iznik, 16-17c. Four-fold floral
// geometry: rosette, tulip, quarter-corners. Cobalt, turquoise, bole red.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float g_scale : hint_range(0.3, 3.0) = 1.0;
uniform float g_weight : hint_range(0.4, 2.2) = 1.0;
uniform float g_wobble : hint_range(0.0, 2.5) = 1.0;
uniform vec3 g_tint : source_color = vec3(1.0, 1.0, 1.0);

void fragment() {
	vec2 c = UV - 0.5;
	float r = length(c);
	float th = atan(c.y, c.x);
	vec3 white = vec3(0.95, 0.93, 0.87);
	vec3 cobalt = vec3(0.11, 0.27, 0.53);
	vec3 turq = vec3(0.18, 0.55, 0.55);
	vec3 bole = vec3(0.75, 0.22, 0.17);
	vec3 col = white;
	float pet8 = abs(cos(th * floor(4.0 * g_scale + 0.5)));
	if (r < 0.13 + pet8 * 0.10 * g_weight) col = mod(floor(th / 0.7854), 2.0) < 1.0 ? cobalt : turq;
	if (r < 0.055) col = bole;
	vec2 a = abs(c);
	vec2 t = vec2(max(a.x, a.y), min(a.x, a.y));
	float tu = length(vec2(t.x - 0.42, t.y));
	if (tu < 0.075 * g_weight && t.y < 0.05) col = bole;
	vec2 q = 0.5 - a;
	float qr = length(q);
	float qth = atan(q.y, q.x);
	if (qr < 0.10 + abs(cos(qth * floor(4.0 * g_scale + 0.5))) * 0.06) col = turq;
	if (qr < 0.045) col = cobalt;
	ALBEDO = col * g_tint;
}
