shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.9: Brick pattern
// Classic brick wall with mortar lines

uniform float rows : hint_range(2.0, 20.0) = 8.0;
uniform float cols : hint_range(1.0, 10.0) = 4.0;
uniform float mortar : hint_range(0.01, 0.1) = 0.04;
uniform vec3 brick_color_a : source_color = vec3(0.6, 0.2, 0.15);
uniform vec3 brick_color_b : source_color = vec3(0.5, 0.18, 0.12);
uniform vec3 mortar_color : source_color = vec3(0.7, 0.7, 0.65);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	uv.y *= rows;
	uv.x *= cols;

	// Offset every other row by half
	float row = floor(uv.y);
	uv.x += mod(row, 2.0) * 0.5;

	vec2 tile_id = floor(uv);
	vec2 tile_uv = fract(uv);

	// Mortar gaps
	float mortar_x = step(tile_uv.x, mortar) + step(1.0 - mortar, tile_uv.x);
	float mortar_y = step(tile_uv.y, mortar * 0.7) + step(1.0 - mortar * 0.7, tile_uv.y);
	float is_mortar = clamp(mortar_x + mortar_y, 0.0, 1.0);

	// Brick color variation
	float h = hash(tile_id);
	vec3 brick = mix(brick_color_a, brick_color_b, h);
	// Subtle shade variation within brick
	brick *= 0.9 + 0.1 * hash(tile_uv * 50.0 + tile_id);

	vec3 color = mix(brick, mortar_color, is_mortar);

	ALBEDO = color;
}
