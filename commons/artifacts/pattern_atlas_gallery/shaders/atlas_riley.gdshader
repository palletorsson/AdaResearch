// Bridget Riley - current. Parallel lines sinusoidally displaced by a
// band; the eye supplies the motion. Op art.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float g_scale : hint_range(0.3, 3.0) = 1.0;
uniform float g_weight : hint_range(0.4, 2.2) = 1.0;
uniform float g_wobble : hint_range(0.0, 2.5) = 1.0;
uniform vec3 g_tint : source_color = vec3(1.0, 1.0, 1.0);

void fragment() {
	vec2 uv = UV;
	float bump = exp(-pow((uv.y - 0.55) * 4.4, 2.0));
	float x = uv.x + sin(uv.y * 22.0 + uv.x * 9.0) * 0.02 * g_wobble * bump;
	float line = step(0.5, fract(x * 24.0 * g_scale));
	vec3 col = mix(vec3(0.07), vec3(0.94, 0.93, 0.89), line);
	ALBEDO = col * g_tint;
}
