// Bingata - stencil-dyers of Ryukyu / Okinawa. Stencil-and-paste resist;
// bright motifs repeated in an offset grid on yellow ground.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float g_scale : hint_range(0.3, 3.0) = 1.0;
uniform float g_weight : hint_range(0.4, 2.2) = 1.0;
uniform float g_wobble : hint_range(0.0, 2.5) = 1.0;
uniform vec3 g_tint : source_color = vec3(1.0, 1.0, 1.0);
float hash2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	vec2 g = UV * vec2(4.0, 3.0) * g_scale;
	if (mod(floor(g.y), 2.0) > 0.5) g.x += 0.5;
	vec2 id = floor(g);
	vec2 c = fract(g) - 0.5;
	vec3 bg = vec3(0.94, 0.77, 0.24);
	float h = hash2(id);
	vec3 pet = h < 0.33 ? vec3(0.85, 0.31, 0.19) : (h < 0.66 ? vec3(0.18, 0.50, 0.53) : vec3(0.76, 0.31, 0.53));
	vec3 col = bg;
	for (int i = 0; i < 5; i++) {
		float a = float(i) / 5.0 * 6.2832 - 1.5708;
		vec2 p = c - vec2(cos(a), sin(a)) * 0.16;
		if (length(p) < 0.115 * g_weight) col = pet;
	}
	if (length(c) < 0.075 * g_weight) col = pet * 0.45;
	float w = abs(c.y + 0.34 - sin(c.x * 12.0) * 0.03);
	if (w < 0.014 && abs(c.x) < 0.32) col = vec3(0.95, 0.94, 0.89);
	ALBEDO = col * g_tint;
}
