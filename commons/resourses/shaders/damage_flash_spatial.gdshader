shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled, skip_vertex_transform;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint_color : source_color = vec4(0.7, 0.0, 0.0, 1.0);
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void vertex() {
	// Fill the screen like the mushroom effect — POSITION from VERTEX in clip space
	POSITION = vec4(VERTEX.xy, 0.0, 1.0);
}

void fragment() {
	vec4 screen = texture(SCREEN_TEXTURE, SCREEN_UV);
	// Mix screen with red tint based on intensity
	vec3 tinted = mix(screen.rgb, tint_color.rgb, intensity * 0.6);
	// Vignette: darken edges more than center
	vec2 uv_centered = SCREEN_UV * 2.0 - 1.0;
	float vignette = 1.0 - dot(uv_centered, uv_centered) * 0.3;
	tinted *= mix(1.0, vignette, intensity);
	ALBEDO = tinted;
	ALPHA = mix(0.0, 0.9, intensity);
}
