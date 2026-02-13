shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.10: Random per-cell values
// Grid of cells each with a random color

uniform float grid_size : hint_range(2.0, 30.0) = 10.0;
uniform float color_mode : hint_range(0.0, 2.0) = 0.0; // 0=gray, 1=colored, 2=stepped

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec3 hash3(vec2 p) {
	return vec3(
		hash(p),
		hash(p + vec2(37.0, 17.0)),
		hash(p + vec2(59.0, 83.0))
	);
}

void fragment() {
	vec2 uv = UV * grid_size;
	vec2 cell_id = floor(uv);
	vec2 cell_uv = fract(uv);

	int mode = int(round(color_mode));

	vec3 color;
	if (mode == 0) {
		// Grayscale
		color = vec3(hash(cell_id));
	} else if (mode == 1) {
		// Full color
		color = hash3(cell_id);
	} else {
		// Stepped: quantized to a few values
		float h = hash(cell_id);
		float stepped = floor(h * 4.0) / 3.0;
		color = vec3(stepped);
	}

	// Cell border
	vec2 edge = smoothstep(vec2(0.0), vec2(0.05), cell_uv) * smoothstep(vec2(0.0), vec2(0.05), 1.0 - cell_uv);
	color *= edge.x * edge.y * 0.3 + 0.7;

	ALBEDO = color;
}
