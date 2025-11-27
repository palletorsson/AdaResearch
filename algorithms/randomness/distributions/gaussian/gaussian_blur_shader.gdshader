shader_type canvas_item;

// Gaussian blur parameters
uniform float blur_amount : hint_range(0.0, 20.0) = 0.0;

// Gaussian blur function
vec4 gaussian_blur(sampler2D tex, vec2 uv, vec2 pixel_size, float blur_radius) {
	if (blur_radius < 0.5) {
		return texture(tex, uv);
	}

	vec4 color = vec4(0.0);
	float total_weight = 0.0;

	int samples = int(ceil(blur_radius * 2.0));
	float sigma = blur_radius / 2.0;

	// Horizontal pass
	for (int x = -samples; x <= samples; x++) {
		float weight = exp(-float(x * x) / (2.0 * sigma * sigma));
		vec2 offset = vec2(float(x) * pixel_size.x, 0.0);
		color += texture(tex, uv + offset) * weight;
		total_weight += weight;
	}

	color /= total_weight;
	vec4 horizontal_result = color;

	// Vertical pass
	color = vec4(0.0);
	total_weight = 0.0;

	for (int y = -samples; y <= samples; y++) {
		float weight = exp(-float(y * y) / (2.0 * sigma * sigma));
		// For vertical pass, we'd ideally sample from horizontal result
		// This is a simplified version - for better quality use two-pass rendering
		vec2 offset = vec2(0.0, float(y) * pixel_size.y);
		color += texture(tex, uv + offset) * weight;
		total_weight += weight;
	}

	color /= total_weight;

	// Blend horizontal and vertical for approximate 2D blur
	return (horizontal_result + color) * 0.5;
}

void fragment() {
	vec2 uv = UV;
	vec2 pixel_size = TEXTURE_PIXEL_SIZE;

	// Apply Gaussian blur to the texture
	if (blur_amount > 0.0) {
		COLOR = gaussian_blur(TEXTURE, uv, pixel_size, blur_amount);
	} else {
		COLOR = texture(TEXTURE, uv);
	}
}
