shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled, skip_vertex_transform;

// Concentric ripple post-processing — SPATIAL version for VR.

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap, repeat_disable;

uniform float intensity: hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float ripple_frequency: hint_range(1.0, 30.0, 0.1) = 10.0;
uniform float ripple_speed: hint_range(0.0, 10.0, 0.1) = 3.0;
uniform float ripple_amplitude: hint_range(0.0, 0.05, 0.001) = 0.02;
uniform float wave_speed: hint_range(0.0, 5.0, 0.1) = 1.5;
uniform float wave_amplitude: hint_range(0.0, 0.05, 0.001) = 0.015;

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
	float i = intensity;

	vec3 color = texture(SCREEN_TEXTURE, uv).rgb;

	if (i >= 0.001) {
		vec2 center = uv - vec2(0.5);
		float dist = length(center);
		float ripple = sin(dist * ripple_frequency * PI - TIME * ripple_speed) * ripple_amplitude * i;
		vec2 dir = normalize(center + vec2(0.0001));
		vec2 ripple_uv = uv + dir * ripple;

		ripple_uv.x += sin(ripple_uv.y * 8.0 + TIME * wave_speed) * wave_amplitude * i;
		ripple_uv.y += cos(ripple_uv.x * 6.0 + TIME * wave_speed * 0.8) * wave_amplitude * i * 0.7;

		color = texture(SCREEN_TEXTURE, ripple_uv).rgb;
		float pulse = sin(TIME * 1.5) * 0.5 + 0.5;
		vec3 tint = mix(vec3(0.9, 0.95, 1.1), vec3(1.1, 0.95, 0.9), pulse);
		color *= mix(vec3(1.0), tint, i * 0.3);
	}

	ALBEDO = color;
}
