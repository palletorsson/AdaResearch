shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled, skip_vertex_transform;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;

void vertex() {
	POSITION = vec4(VERTEX.xy, 0.0, 1.0);
}

void fragment() {
	ALBEDO = vec3(0.7, 0.0, 0.0);
	ALPHA = intensity * 0.6;
}
