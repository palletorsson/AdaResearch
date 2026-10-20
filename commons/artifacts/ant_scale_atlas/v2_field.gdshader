shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D trail_texture : filter_linear, repeat_disable;
void fragment() {
	// Original texture channels: red = food, blue = home. Display only.
	vec3 trail = texture(trail_texture, UV).rgb;
	vec3 dark = vec3(0.018, 0.028, 0.044);
	vec3 home = vec3(0.07, 0.64, 0.77) * pow(trail.b, 0.55);
	vec3 food = vec3(0.91, 0.16, 0.32) * pow(trail.r, 0.55);
	ALBEDO = min(dark + home + food, vec3(1.0));
}
