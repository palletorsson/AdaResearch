shader_type spatial;
uniform bool show_grid = true;
uniform vec4 base_colour : source_color = vec4(1.0);

// Metre-based grid on the existing floor. Filter the ink edges so thin lines
// remain continuous at a grazing viewing angle without extra floor geometry.
varying vec2 floor_position;

void vertex() {
	floor_position = VERTEX.xz;
}

void fragment() {
	vec2 cell = (floor_position + vec2(6.0, 12.0)) / 2.0;
	vec2 distance_to_line = abs(fract(cell + 0.5) - 0.5) * 2.0;
	vec2 pixel_width = max(fwidth(floor_position), vec2(0.0001));
	vec2 ink = 1.0 - smoothstep(vec2(0.01) - pixel_width * 0.5,
		vec2(0.01) + pixel_width * 0.5, distance_to_line);
	ALBEDO = mix(base_colour.rgb, vec3(0.0), show_grid ? max(ink.x, ink.y) : 0.0);
	ROUGHNESS = 0.9;
}
