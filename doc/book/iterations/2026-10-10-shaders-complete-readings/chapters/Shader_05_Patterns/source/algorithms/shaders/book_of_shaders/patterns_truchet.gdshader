shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.9: Truchet tiles
// Random quarter-circle arcs creating labyrinthine patterns

uniform float grid_size : hint_range(2.0, 20.0) = 8.0;
uniform float line_thickness : hint_range(0.01, 0.2) = 0.08;
uniform float seed : hint_range(0.0, 100.0) = 42.0;
uniform vec3 line_color : source_color = vec3(0.0, 0.78, 0.85);
uniform vec3 bg_color : source_color = vec3(0.05, 0.05, 0.1);

float hash(vec2 p) {
	return fract(sin(dot(p + vec2(seed), vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV * grid_size;
	vec2 tile_id = floor(uv);
	vec2 tile_uv = fract(uv);

	// Random choice per tile: 0 or 1
	float choice = step(0.5, hash(tile_id));

	// Mirror tile_uv based on choice
	if (choice > 0.5) {
		tile_uv.x = 1.0 - tile_uv.x;
	}

	// Draw quarter circles from two corners
	float d1 = abs(length(tile_uv) - 0.5) - line_thickness;
	float d2 = abs(length(tile_uv - vec2(1.0, 1.0)) - 0.5) - line_thickness;

	float arc = min(d1, d2);
	float line = 1.0 - smoothstep(-0.01, 0.01, arc);

	vec3 color = mix(bg_color, line_color, line);

	ALBEDO = color;
}
