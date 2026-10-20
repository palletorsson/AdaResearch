shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.9: Basic UV tiling
// Uses fract() to repeat a pattern across a grid

uniform float grid_size : hint_range(1.0, 20.0) = 5.0;
uniform float shape_size : hint_range(0.1, 0.5) = 0.3;
uniform float animate : hint_range(0.0, 1.0) = 0.0;
uniform vec3 shape_color : source_color = vec3(0.0, 0.78, 0.85);
uniform vec3 bg_color : source_color = vec3(0.05, 0.05, 0.1);

void fragment() {
	vec2 uv = UV * grid_size;

	// Tile coordinate and local position
	vec2 tile_id = floor(uv);
	vec2 tile_uv = fract(uv) - 0.5; // centered -0.5 to 0.5

	// Animate size per tile
	float anim = 1.0 + animate * 0.3 * sin(TIME + tile_id.x * 1.3 + tile_id.y * 0.7);
	float r = shape_size * anim;

	// Circle in each tile
	float dist = length(tile_uv) - r;
	float circle = 1.0 - smoothstep(-0.01, 0.01, dist);

	// Tile borders
	vec2 edge = abs(tile_uv);
	float border = step(max(edge.x, edge.y), 0.49) - step(max(edge.x, edge.y), 0.48);
	border *= 0.15;

	// Color variation per tile
	vec3 tile_color = shape_color * (0.7 + 0.3 * fract(sin(dot(tile_id, vec2(12.9898, 78.233))) * 43758.5453));

	vec3 color = bg_color + vec3(border);
	color = mix(color, tile_color, circle);

	ALBEDO = color;
}
