shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled, skip_vertex_transform;

// Psychedelic post-processing — SPATIAL version for VR fullscreen quad.

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap, repeat_disable;

uniform float intensity: hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float chromatic_amount: hint_range(0.0, 0.05, 0.001) = 0.015;
uniform float wave_speed: hint_range(0.0, 5.0, 0.1) = 1.5;
uniform float wave_amplitude: hint_range(0.0, 0.05, 0.001) = 0.02;
uniform float wave_frequency: hint_range(0.0, 20.0, 0.1) = 6.0;
uniform float hue_shift_speed: hint_range(0.0, 2.0, 0.01) = 0.3;
uniform float saturation_boost: hint_range(0.0, 2.0, 0.01) = 0.4;
uniform float vignette_strength: hint_range(0.0, 1.0, 0.01) = 0.4;
uniform float vignette_pulse_speed: hint_range(0.0, 5.0, 0.1) = 1.2;

vec3 rgb_to_hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv_to_rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void vertex() {
	// Fullscreen quad for VR — uses PROJECTION_MATRIX offset for asymmetric FOV.
	// QuadMesh must have subdivisions so inner vertices (length < 0.99) exist.
	// Outer edge vertices stay at screen boundary; inner ones get corrected center.
	// See: docs.godotengine.org/en/stable/tutorials/xr/xr_full_screen_effects.html
	vec2 vert_pos = VERTEX.xy;
	if (length(vert_pos) < 0.99) {
		vec4 offset = PROJECTION_MATRIX * vec4(0.0, 0.0, 1.0, 1.0);
		vert_pos += (offset.xy / offset.w);
	}
	POSITION = vec4(vert_pos, 1.0, 1.0);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float t = TIME;
	float i = intensity;

	vec3 color = texture(SCREEN_TEXTURE, uv).rgb;

	if (i >= 0.001) {
		// Wave distortion
		vec2 wave_uv = uv;
		wave_uv.x += sin(uv.y * wave_frequency + t * wave_speed) * wave_amplitude * i;
		wave_uv.y += cos(uv.x * wave_frequency * 0.8 + t * wave_speed * 1.3) * wave_amplitude * i * 0.7;
		wave_uv.x += sin(uv.y * 2.0 + t * 0.4) * wave_amplitude * i * 0.5;
		wave_uv.y += sin(uv.x * 2.5 + t * 0.3) * wave_amplitude * i * 0.4;

		// Chromatic aberration
		float ca = chromatic_amount * i;
		vec2 dir = wave_uv - vec2(0.5);
		float r = texture(SCREEN_TEXTURE, wave_uv + dir * ca).r;
		float g = texture(SCREEN_TEXTURE, wave_uv).g;
		float b = texture(SCREEN_TEXTURE, wave_uv - dir * ca).b;
		color = vec3(r, g, b);

		// Hue shift
		vec3 hsv = rgb_to_hsv(color);
		hsv.x = fract(hsv.x + hue_shift_speed * t * i);
		hsv.y = min(hsv.y + saturation_boost * i, 1.0);
		color = hsv_to_rgb(hsv);

		// Color pulsing
		float pulse = sin(t * 0.7) * 0.5 + 0.5;
		vec3 warm = vec3(1.05, 0.95, 0.85);
		vec3 cool = vec3(0.85, 0.95, 1.05);
		vec3 tint = mix(warm, cool, pulse);
		color *= mix(vec3(1.0), tint, i * 0.4);

		// Breathing vignette
		float vig_pulse = sin(t * vignette_pulse_speed) * 0.5 + 0.5;
		float dist = length(uv - vec2(0.5)) * 2.0;
		float vignette = 1.0 - smoothstep(0.3, 1.2, dist) * vignette_strength * i * (0.6 + 0.4 * vig_pulse);
		color *= vignette;

		// Brightness breathing
		float brightness = 1.0 + sin(t * 0.9) * 0.08 * i;
		color *= brightness;
	}

	ALBEDO = color;
}
