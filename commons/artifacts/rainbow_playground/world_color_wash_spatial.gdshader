shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled, skip_vertex_transform;

// Fullscreen chromatic world-colour wash — SPATIAL version for VR headsets.
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform vec3 tint_color: source_color = vec3(1.0, 0.3, 0.6);
uniform float intensity: hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float dream_wave: hint_range(0.0, 1.0, 0.01) = 0.0;

void vertex() {
	vec2 vert_pos = VERTEX.xy;
	if (length(vert_pos) < 0.99) {
		vec4 offset = PROJECTION_MATRIX * vec4(0.0, 0.0, 1.0, 1.0);
		vert_pos += (offset.xy / offset.w);
	}
	POSITION = vec4(vert_pos, 1.0, 1.0);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float i = clamp(intensity, 0.0, 1.0);
	vec3 scene = texture(SCREEN_TEXTURE, uv).rgb;
	if (i >= 0.001) {
		float w = clamp(dream_wave, 0.0, 1.0) * i * 0.65;
		if (w > 0.001) {
			uv.x += sin(uv.y * 6.0 + TIME * 1.5) * 0.006 * w;
			uv.y += cos(uv.x * 5.0 + TIME * 1.2) * 0.005 * w;
			scene = texture(SCREEN_TEXTURE, uv).rgb;
		}
		float lum = dot(scene, vec3(0.299, 0.587, 0.114));
		vec3 shadow_col = tint_color * (0.28 + 0.55 * lum);
		vec3 highlight_col = mix(tint_color, vec3(1.0), 0.45) * (0.45 + 0.75 * lum);
		vec3 washed = mix(shadow_col, highlight_col, smoothstep(0.15, 0.85, lum));
		vec3 multiplied = scene * mix(vec3(1.0), tint_color * 1.35 + vec3(0.06), 0.72);
		vec3 target = mix(multiplied, washed, 0.52);
		scene = mix(scene, target, i * 0.58);
	}
	ALBEDO = scene;
}
