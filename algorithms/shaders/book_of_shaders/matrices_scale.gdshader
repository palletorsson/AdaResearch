shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.8: UV Scale
// Scale UV space with adjustable factor — zooming in and out

uniform float scale_x : hint_range(0.2, 4.0) = 1.0;
uniform float scale_y : hint_range(0.2, 4.0) = 1.0;
uniform float uniform_scale : hint_range(0.2, 4.0) = 1.0;
uniform vec3 shape_color : source_color = vec3(0.0, 0.78, 0.85);
uniform vec3 bg_color : source_color = vec3(0.05, 0.05, 0.1);

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;

	// Apply scale (divide to zoom in when scale > 1)
	uv /= vec2(scale_x, scale_y) * uniform_scale;

	// Draw a square with circle inside
	float box = max(abs(uv.x), abs(uv.y)) - 0.3;
	float circ = length(uv) - 0.2;

	float shape_box = 1.0 - smoothstep(-0.005, 0.005, box);
	float shape_circ = 1.0 - smoothstep(-0.005, 0.005, circ);

	// Grid on scaled space
	float grid = 0.0;
	for (int i = -4; i <= 4; i++) {
		float pos = float(i) * 0.25;
		grid += (1.0 - smoothstep(0.0, 0.002, abs(uv.x - pos))) * 0.1;
		grid += (1.0 - smoothstep(0.0, 0.002, abs(uv.y - pos))) * 0.1;
	}

	vec3 color = bg_color + vec3(grid);
	color = mix(color, shape_color * 0.5, shape_box * 0.4);
	color = mix(color, shape_color, shape_circ);

	ALBEDO = color;
}
