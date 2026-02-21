shader_type canvas_item;

// Pixelation / mosaic post-processing effect.
// Reduces resolution and optionally adds color quantization.

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap, repeat_disable;

uniform float intensity: hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float pixel_size: hint_range(1.0, 32.0, 1.0) = 8.0;
uniform float color_levels: hint_range(2.0, 64.0, 1.0) = 16.0;
uniform float edge_strength: hint_range(0.0, 1.0, 0.01) = 0.3;

void fragment() {
	vec2 uv = SCREEN_UV;
	float i = intensity;

	if (i < 0.001) {
		COLOR = texture(SCREEN_TEXTURE, uv);
		return;
	}

	// Pixelation — snap UV to grid
	float px = mix(1.0, pixel_size, i);
	vec2 viewport = vec2(textureSize(SCREEN_TEXTURE, 0));
	vec2 grid_uv = floor(uv * viewport / px) * px / viewport;

	vec3 color = texture(SCREEN_TEXTURE, grid_uv).rgb;

	// Color quantization (posterize)
	float levels = mix(256.0, color_levels, i);
	color = floor(color * levels + 0.5) / levels;

	// Simple edge detection within pixel blocks
	if (edge_strength > 0.01 && i > 0.1) {
		vec2 offset = px / viewport;
		vec3 n = texture(SCREEN_TEXTURE, grid_uv + vec2(0.0, -offset.y)).rgb;
		vec3 s = texture(SCREEN_TEXTURE, grid_uv + vec2(0.0, offset.y)).rgb;
		vec3 e = texture(SCREEN_TEXTURE, grid_uv + vec2(offset.x, 0.0)).rgb;
		vec3 w = texture(SCREEN_TEXTURE, grid_uv + vec2(-offset.x, 0.0)).rgb;
		float edge = length(n - s) + length(e - w);
		edge = smoothstep(0.1, 0.5, edge);
		color = mix(color, vec3(0.0), edge * edge_strength * i);
	}

	COLOR = vec4(color, 1.0);
}
