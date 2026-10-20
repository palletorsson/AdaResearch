shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never, shadows_disabled;
uniform vec4 glow_colour : source_color = vec4(0.68, 0.83, 1.0, 1.0);
uniform float strength = 0.30;
void fragment() {
	float rim = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 2.6);
	float breath = 0.92 + 0.08 * sin(TIME * 1.8);
	ALBEDO = glow_colour.rgb;
	ALPHA = rim * strength * breath;
}
