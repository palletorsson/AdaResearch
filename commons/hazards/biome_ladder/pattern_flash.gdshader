shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
uniform float pulse : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	float edge = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	float border = 1.0 - smoothstep(0.025, 0.055, edge);
	ALBEDO = vec3(1.0);
	ALPHA = pulse * (0.14 + border * 0.78);
}
