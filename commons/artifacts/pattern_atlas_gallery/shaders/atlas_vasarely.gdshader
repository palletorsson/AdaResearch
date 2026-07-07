// Victor Vasarely - the deformed grid. A checkerboard displaced by a dome:
// figure from pure periodic modulation. Op art.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float g_scale : hint_range(0.3, 3.0) = 1.0;
uniform float g_weight : hint_range(0.4, 2.2) = 1.0;
uniform float g_wobble : hint_range(0.0, 2.5) = 1.0;
uniform vec3 g_tint : source_color = vec3(1.0, 1.0, 1.0);

void fragment() {
	vec2 p = UV - 0.5;
	float d = length(p);
	float R = 0.34 * g_weight;
	if (d < R) {
		float g = 1.0 - 0.42 * g_wobble * cos(d / R * 1.5708);
		p *= g;
	}
	vec2 q = (p + 0.5) * vec2(14.0, 10.0) * g_scale;
	float check = mod(floor(q.x) + floor(q.y), 2.0);
	bool inside = d < R * 0.62;
	vec3 col = check < 1.0 ? (inside ? vec3(0.08, 0.13, 0.24) : vec3(0.06, 0.06, 0.06))
	                       : (inside ? vec3(0.24, 0.49, 0.69) : vec3(0.93, 0.93, 0.89));
	ALBEDO = col * g_tint;
}
