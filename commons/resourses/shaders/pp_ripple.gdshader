shader_type canvas_item;

// Concentric ripple post-processing effect.
// CanvasLayer + ColorRect fullscreen overlay.

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap, repeat_disable;

uniform float intensity: hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float ripple_frequency: hint_range(1.0, 30.0, 0.1) = 10.0;
uniform float ripple_speed: hint_range(0.0, 10.0, 0.1) = 3.0;
uniform float ripple_amplitude: hint_range(0.0, 0.05, 0.001) = 0.02;
uniform float wave_speed: hint_range(0.0, 5.0, 0.1) = 1.5;
uniform float wave_amplitude: hint_range(0.0, 0.05, 0.001) = 0.015;

void fragment() {
	vec2 uv = SCREEN_UV;
	float i = intensity;

	if (i < 0.001) {
		COLOR = texture(SCREEN_TEXTURE, uv);
		return;
	}

	// Center-based concentric ripples
	vec2 center = uv - vec2(0.5);
	float dist = length(center);
	float ripple = sin(dist * ripple_frequency * PI - TIME * ripple_speed) * ripple_amplitude * i;
	vec2 dir = normalize(center + vec2(0.0001));
	vec2 ripple_uv = uv + dir * ripple;

	// Secondary wave distortion
	ripple_uv.x += sin(ripple_uv.y * 8.0 + TIME * wave_speed) * wave_amplitude * i;
	ripple_uv.y += cos(ripple_uv.x * 6.0 + TIME * wave_speed * 0.8) * wave_amplitude * i * 0.7;

	// Slight color tint that pulses
	vec3 color = texture(SCREEN_TEXTURE, ripple_uv).rgb;
	float pulse = sin(TIME * 1.5) * 0.5 + 0.5;
	vec3 tint = mix(vec3(0.9, 0.95, 1.1), vec3(1.1, 0.95, 0.9), pulse);
	color *= mix(vec3(1.0), tint, i * 0.3);

	COLOR = vec4(color, 1.0);
}
