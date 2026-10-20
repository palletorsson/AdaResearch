shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, shadows_disabled;

uniform vec4 tint : source_color = vec4(1.0);

void fragment() {
	// Fade toward the silhouette; the light stays on the same moving body.
	float facing = max(dot(normalize(NORMAL), normalize(VIEW)), 0.0);
	ALBEDO = tint.rgb;
	ALPHA = 0.3 * pow(facing, 3.0);
}
