shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.12: Voronoi diagram
// Color regions by nearest random point

uniform float scale : hint_range(2.0, 15.0) = 5.0;
uniform float speed : hint_range(0.0, 2.0) = 0.5;
uniform float show_points : hint_range(0.0, 1.0) = 1.0;
uniform float show_borders : hint_range(0.0, 1.0) = 0.0;

vec2 random2(vec2 p) {
	return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV * scale;
	vec2 i_st = floor(uv);
	vec2 f_st = fract(uv);

	float min_dist = 1e10;
	float second_dist = 1e10;
	vec2 min_point = vec2(0.0);
	vec2 min_cell = vec2(0.0);

	// Search 3x3 neighborhood
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 neighbor = vec2(float(x), float(y));
			vec2 point = random2(i_st + neighbor);
			// Animate points
			point = 0.5 + 0.5 * sin(TIME * speed + 6.2831 * point);
			vec2 diff = neighbor + point - f_st;
			float dist = length(diff);
			if (dist < min_dist) {
				second_dist = min_dist;
				min_dist = dist;
				min_point = point;
				min_cell = i_st + neighbor;
			} else if (dist < second_dist) {
				second_dist = dist;
			}
		}
	}

	// Color by cell
	vec3 cell_color = vec3(
		fract(sin(dot(min_cell, vec2(12.9898, 78.233))) * 43758.5453),
		fract(sin(dot(min_cell, vec2(39.346, 11.135))) * 43758.5453),
		fract(sin(dot(min_cell, vec2(73.156, 52.235))) * 43758.5453)
	);
	cell_color = mix(cell_color * 0.3, cell_color, 0.7);

	// Distance gradient within cell
	vec3 color = cell_color * (1.0 - min_dist * 0.5);

	// Borders (F2 - F1)
	if (show_borders > 0.5) {
		float border = second_dist - min_dist;
		float edge = 1.0 - smoothstep(0.0, 0.05, border);
		color = mix(color, vec3(1.0), edge);
	}

	// Draw points
	if (show_points > 0.5) {
		float point_dot = 1.0 - smoothstep(0.0, 0.04, min_dist);
		color = mix(color, vec3(1.0), point_dot);
	}

	ALBEDO = color;
}
