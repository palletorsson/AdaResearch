// Anni Albers - triangle studies. A grid of split cells; orientation the
// only free choice. Weave as formal grammar, written at the Bauhaus loom.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float g_scale : hint_range(0.3, 3.0) = 1.0;
uniform float g_weight : hint_range(0.4, 2.2) = 1.0;
uniform float g_wobble : hint_range(0.0, 2.5) = 1.0;
uniform vec3 g_tint : source_color = vec3(1.0, 1.0, 1.0);
float hash2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	vec2 g = UV * vec2(10.0, 7.0) * g_scale;
	vec2 id = floor(g);
	vec2 c = fract(g);
	float flip = step(0.5, hash2(id));
	float tri = flip > 0.5 ? step(c.x, c.y) : step(c.x + c.y, 1.0);
	float pick = hash2(id + vec2(tri * 13.0, 5.0));
	vec3 col = pick < 0.25 ? vec3(0.09, 0.08, 0.06)
	         : (pick < 0.5 ? vec3(0.91, 0.87, 0.78)
	         : (pick < 0.75 ? vec3(0.70, 0.29, 0.16) : vec3(0.54, 0.48, 0.40)));
	ALBEDO = col * g_tint;
}
