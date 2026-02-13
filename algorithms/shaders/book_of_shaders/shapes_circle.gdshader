shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.7: SDF Circle
// Signed distance field circle with adjustable radius and edge softness

uniform float radius : hint_range(0.05, 0.5) = 0.3;
uniform float softness : hint_range(0.0, 0.1) = 0.01;
uniform vec3 shape_color : source_color = vec3(0.0, 0.78, 0.85);
uniform vec3 bg_color : source_color = vec3(0.05, 0.05, 0.1);
uniform float show_distance : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0; // Center: remap to -1..1

	// SDF: distance from center minus radius
	float dist = length(uv) - radius;

	// Visualize the distance field
	vec3 dist_vis = vec3(0.0);
	if (show_distance > 0.5) {
		// Color rings showing distance
		float rings = 0.5 + 0.5 * cos(dist * 40.0);
		dist_vis = mix(vec3(0.1, 0.4, 0.5), vec3(0.5, 0.1, 0.1), step(0.0, dist)) * rings;
	}

	// Sharp/soft circle
	float circle = 1.0 - smoothstep(-softness, softness, dist);

	vec3 color;
	if (show_distance > 0.5) {
		color = mix(dist_vis, shape_color, circle * 0.7);
	} else {
		color = mix(bg_color, shape_color, circle);
	}

	// Outline at distance = 0
	float outline = 1.0 - smoothstep(0.0, 0.005, abs(dist));
	color = mix(color, vec3(1.0), outline * 0.5);

	ALBEDO = color;
}
