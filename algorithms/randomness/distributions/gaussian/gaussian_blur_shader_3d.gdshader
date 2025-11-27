shader_type spatial;

// Gaussian blur parameters
uniform float blur_amount : hint_range(0.0, 20.0) = 0.0;
uniform sampler2D circle_texture : hint_default_white;

// Gaussian blur function
vec4 gaussian_blur(sampler2D tex, vec2 uv, float blur_radius) {
	if (blur_radius < 0.5) {
		return texture(tex, uv);
	}

	vec4 color = vec4(0.0);
	float total_weight = 0.0;

	int samples = int(ceil(blur_radius * 2.0));
	float sigma = blur_radius / 2.0;

	// Calculate pixel size
	vec2 tex_size = vec2(textureSize(tex, 0));
	vec2 pixel_size = 1.0 / tex_size;

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
		vec2 offset = vec2(0.0, float(y) * pixel_size.y);
		color += texture(tex, uv + offset) * weight;
		total_weight += weight;
	}

	color /= total_weight;

	// Blend horizontal and vertical for approximate 2D blur
	return (horizontal_result + color) * 0.5;
}

void fragment() {
	// Apply Gaussian blur to the texture
	vec4 albedo_color;
	if (blur_amount > 0.0) {
		albedo_color = gaussian_blur(circle_texture, UV, blur_amount);
	} else {
		albedo_color = texture(circle_texture, UV);
	}

	ALBEDO = albedo_color.rgb;
	ALPHA = albedo_color.a;
}
