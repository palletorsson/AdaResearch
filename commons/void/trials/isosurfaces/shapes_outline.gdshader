shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

varying vec3 barycentric;

void vertex() {
	int corner = VERTEX_ID % 3;
	barycentric = vec3(float(corner == 0), float(corner == 1), float(corner == 2));
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	clip.z += 0.00002 * clip.w;
	POSITION = clip;
}

void fragment() {
	vec3 edge = smoothstep(vec3(0.0), fwidth(barycentric) * 0.8, barycentric);
	ALBEDO = vec3(0.67, 0.99, 1.0);
	ALPHA = 0.6 * (1.0 - min(min(edge.x, edge.y), edge.z));
}
