shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled, skip_vertex_transform;

// DIAGNOSTIC TEST: Solid red tint overlay — no SCREEN_TEXTURE reading.
// If this is visible in VR, the quad renders but SCREEN_TEXTURE is the problem.
// If this is NOT visible, the quad itself is not rendering.

uniform float intensity: hint_range(0.0, 1.0, 0.01) = 0.0;

void vertex() {
	vec2 vert_pos = VERTEX.xy;
	if (length(vert_pos) < 0.99) {
		vec4 offset = PROJECTION_MATRIX * vec4(0.0, 0.0, 1.0, 1.0);
		vert_pos += (offset.xy / offset.w);
	}
	POSITION = vec4(vert_pos, 1.0, 1.0);
}

void fragment() {
	// Pure red tint with alpha controlled by intensity.
	// Does NOT read SCREEN_TEXTURE at all.
	ALBEDO = vec3(1.0, 0.0, 0.0);
	ALPHA = intensity * 0.5;  // Semi-transparent red overlay
}
