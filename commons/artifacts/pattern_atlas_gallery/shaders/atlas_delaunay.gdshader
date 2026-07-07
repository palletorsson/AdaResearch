// Sonia Delaunay - simultane. Quartered concentric discs; the colour
// pairs do the motion. Orphism across textile and paint.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float g_scale : hint_range(0.3, 3.0) = 1.0;
uniform float g_weight : hint_range(0.4, 2.2) = 1.0;
uniform float g_wobble : hint_range(0.0, 2.5) = 1.0;
uniform vec3 g_tint : source_color = vec3(1.0, 1.0, 1.0);
float hash2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	vec2 g = UV * vec2(3.0, 2.0) * g_scale;
	vec2 id = floor(g);
	vec2 c = fract(g) - 0.5;
	float r = length(c) * 2.2;
	float hemi = step(0.0, c.y);
	float ring = floor(r * 4.0 * g_weight);
	float h = hash2(id);
	vec3 a = h < 0.33 ? vec3(0.85, 0.25, 0.28) : (h < 0.66 ? vec3(0.93, 0.62, 0.25) : vec3(0.11, 0.20, 0.34));
	vec3 b = h < 0.33 ? vec3(0.11, 0.20, 0.34) : (h < 0.66 ? vec3(0.14, 0.28, 0.31) : vec3(0.93, 0.90, 0.83));
	vec3 col = vec3(0.94, 0.91, 0.84);
	if (r < 1.0) col = mod(ring + hemi, 2.0) < 1.0 ? a : b;
	ALBEDO = col * g_tint;
}
