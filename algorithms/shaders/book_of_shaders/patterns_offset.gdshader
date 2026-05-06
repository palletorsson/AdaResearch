shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.9: Offset rows
// Every other row is shifted — hex-like layouts

uniform float grid_size : hint_range(2.0, 16.0) = 6.0;
uniform float offset_amount : hint_range(0.0, 0.5) = 0.5;
uniform float dot_size : hint_range(0.05, 0.45) = 0.25;
uniform vec3 dot_color : source_color = vec3(0.95, 0.45, 0.15);
uniform vec3 bg_color : source_color = vec3(0.05, 0.05, 0.1);

void fragment() {
	vec2 uv = UV * grid_size;

	// Offset every other row
	float row = floor(uv.y);
	float row_offset = mod(row, 2.0) * offset_amount;
	uv.x += row_offset;

	vec2 tile_id = floor(uv);
	vec2 tile_uv = fract(uv) - 0.5;

	// Circle
	float dist = length(tile_uv) - dot_size;
	float circle = 1.0 - smoothstep(-0.01, 0.01, dist);

	// Color varies per row
	float row_hue = fract(row * 0.1);
	vec3 c = dot_color * (0.6 + 0.4 * row_hue);

	vec3 color = mix(bg_color, c, circle);

	ALBEDO = color;
}
