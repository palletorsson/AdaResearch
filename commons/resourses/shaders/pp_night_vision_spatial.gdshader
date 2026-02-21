shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled, skip_vertex_transform;

// Night vision — SPATIAL version for VR.

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap, repeat_disable;

uniform float intensity: hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float brightness_boost: hint_range(1.0, 4.0, 0.1) = 2.0;
uniform float noise_amount: hint_range(0.0, 0.3, 0.01) = 0.12;
uniform float scanline_density: hint_range(100.0, 1000.0, 10.0) = 400.0;
uniform float vignette_radius: hint_range(0.3, 1.0, 0.01) = 0.7;

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

	vec3 scene = texture(SCREEN_TEXTURE, uv).rgb;
	vec3 color = scene;

	if (i >= 0.001) {
		float lum = dot(scene, vec3(0.2126, 0.7152, 0.0722));
		lum *= mix(1.0, brightness_boost, i);

		vec3 nv_color = vec3(lum * 0.2, lum, lum * 0.15);

		// Scanlines
		float scanline = sin(uv.y * scanline_density + TIME * 2.0) * 0.5 + 0.5;
		scanline = mix(1.0, 0.85 + scanline * 0.15, i);
		nv_color *= scanline;

		// Noise
		float noise = rand(uv * 800.0 + vec2(TIME * 50.0, TIME * 30.0));
		nv_color += vec3(0.0, noise * noise_amount * i, 0.0);

		// Vignette
		float dist = length(uv - vec2(0.5)) * 2.0;
		float vig = 1.0 - smoothstep(vignette_radius, 1.3, dist);
		nv_color *= mix(1.0, vig, i);

		color = mix(scene, nv_color, i);
	}

	ALBEDO = color;
}
