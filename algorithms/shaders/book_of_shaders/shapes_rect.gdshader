shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.7: SDF Rectangle
// Box distance field with adjustable width and height

uniform float width : hint_range(0.05, 0.9) = 0.5;
uniform float height : hint_range(0.05, 0.9) = 0.4;
uniform float corner_radius : hint_range(0.0, 0.2) = 0.0;
uniform vec3 shape_color : source_color = vec3(0.95, 0.45, 0.15);
uniform vec3 bg_color : source_color = vec3(0.05, 0.05, 0.1);

float sdf_box(vec2 p, vec2 b, float r) {
	vec2 d = abs(p) - b + vec2(r);
	return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0) - r;
}

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;

	float dist = sdf_box(uv, vec2(width, height), corner_radius);

	// Rect shape
	float rect = 1.0 - smoothstep(-0.005, 0.005, dist);

	// Distance visualization rings
	float rings = 0.5 + 0.5 * cos(dist * 30.0);
	vec3 dist_color = mix(vec3(0.1, 0.3, 0.15), vec3(0.3, 0.1, 0.1), step(0.0, dist)) * rings * 0.3;

	vec3 color = mix(bg_color + dist_color, shape_color, rect);

	// Outline
	float outline = 1.0 - smoothstep(0.0, 0.008, abs(dist));
	color = mix(color, vec3(1.0), outline * 0.4);

	ALBEDO = color;
}
