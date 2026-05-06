shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled, skip_vertex_transform;

// Edge detection / outline — SPATIAL version for VR.

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap, repeat_disable;

uniform float intensity: hint_range(0.0, 1.0, 0.01) = 0.0;
uniform vec4 edge_color: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 background_color: source_color = vec4(0.0, 0.0, 0.05, 1.0);
uniform float threshold: hint_range(0.0, 1.0, 0.01) = 0.15;
uniform bool show_original = true;

float luminance(vec3 c) {
	return dot(c, vec3(0.2126, 0.7152, 0.0722));
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
		vec2 pixel = 1.0 / vec2(textureSize(SCREEN_TEXTURE, 0));

		float tl = luminance(texture(SCREEN_TEXTURE, uv + vec2(-pixel.x, -pixel.y)).rgb);
		float tc = luminance(texture(SCREEN_TEXTURE, uv + vec2(0.0, -pixel.y)).rgb);
		float tr = luminance(texture(SCREEN_TEXTURE, uv + vec2(pixel.x, -pixel.y)).rgb);
		float ml = luminance(texture(SCREEN_TEXTURE, uv + vec2(-pixel.x, 0.0)).rgb);
		float mr = luminance(texture(SCREEN_TEXTURE, uv + vec2(pixel.x, 0.0)).rgb);
		float bl = luminance(texture(SCREEN_TEXTURE, uv + vec2(-pixel.x, pixel.y)).rgb);
		float bc = luminance(texture(SCREEN_TEXTURE, uv + vec2(0.0, pixel.y)).rgb);
		float br = luminance(texture(SCREEN_TEXTURE, uv + vec2(pixel.x, pixel.y)).rgb);

		float gx = -tl - 2.0 * ml - bl + tr + 2.0 * mr + br;
		float gy = -tl - 2.0 * tc - tr + bl + 2.0 * bc + br;
		float edge = sqrt(gx * gx + gy * gy);
		edge = smoothstep(threshold, threshold + 0.1, edge);

		if (show_original) {
			color = mix(scene, edge_color.rgb, edge * i);
		} else {
			vec3 edge_result = mix(background_color.rgb, edge_color.rgb, edge);
			color = mix(scene, edge_result, i);
		}
	}

	ALBEDO = color;
}
