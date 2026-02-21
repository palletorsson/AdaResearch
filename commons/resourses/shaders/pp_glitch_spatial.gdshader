shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled, skip_vertex_transform;

// Digital glitch — SPATIAL version for VR.

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap, repeat_disable;

uniform float intensity: hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float scanline_strength: hint_range(0.0, 1.0, 0.01) = 0.3;
uniform float rgb_split: hint_range(0.0, 0.03, 0.001) = 0.01;
uniform float block_size: hint_range(2.0, 64.0, 1.0) = 16.0;
uniform float glitch_rate: hint_range(0.0, 10.0, 0.1) = 3.0;

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

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
		float t = floor(TIME * glitch_rate);

		// Block displacement
		vec2 block = floor(uv * block_size);
		float block_noise = rand(block + vec2(t, 0.0));
		float do_glitch = step(1.0 - i * 0.3, block_noise);
		float shift = (rand(block + vec2(t * 1.3, 7.0)) - 0.5) * 0.1 * i * do_glitch;
		vec2 glitch_uv = uv + vec2(shift, 0.0);

		// RGB split
		float split = rgb_split * i;
		float r = texture(SCREEN_TEXTURE, glitch_uv + vec2(split, 0.0)).r;
		float g = texture(SCREEN_TEXTURE, glitch_uv).g;
		float b = texture(SCREEN_TEXTURE, glitch_uv - vec2(split, 0.0)).b;
		color = vec3(r, g, b);

		// Scanlines
		float scanline = sin(uv.y * 800.0) * 0.5 + 0.5;
		scanline = mix(1.0, scanline, scanline_strength * i);
		color *= scanline;

		// Line glitch
		float line_noise = rand(vec2(floor(uv.y * 200.0), t));
		if (line_noise > 1.0 - i * 0.05) {
			color += vec3(0.3) * i;
		}

		// Static noise
		float noise = rand(uv * 500.0 + vec2(TIME * 100.0, 0.0));
		color = mix(color, vec3(noise), i * 0.08);
	}

	ALBEDO = color;
}
