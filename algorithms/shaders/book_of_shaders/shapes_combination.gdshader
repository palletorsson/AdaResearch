shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.7: Boolean combination of shapes
// Union, intersection, subtraction of circle and rectangle

uniform float operation : hint_range(0.0, 2.0) = 0.0; // 0=union, 1=intersection, 2=subtraction
uniform float circle_x : hint_range(-0.5, 0.5) = 0.3;
uniform float circle_y : hint_range(-0.5, 0.5) = 0.0;
uniform float circle_r : hint_range(0.1, 0.5) = 0.35;
uniform vec3 shape_color : source_color = vec3(0.0, 0.78, 0.85);
uniform vec3 bg_color : source_color = vec3(0.05, 0.05, 0.1);

float sdf_circle(vec2 p, vec2 center, float r) {
	return length(p - center) - r;
}

float sdf_box(vec2 p, vec2 b) {
	vec2 d = abs(p) - b;
	return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0);
}

float op_union(float d1, float d2) { return min(d1, d2); }
float op_intersection(float d1, float d2) { return max(d1, d2); }
float op_subtraction(float d1, float d2) { return max(-d1, d2); }

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;

	float d_circle = sdf_circle(uv, vec2(circle_x, circle_y), circle_r);
	float d_box = sdf_box(uv, vec2(0.35, 0.35));

	float dist;
	int op = int(round(operation));
	if (op == 0) {
		dist = op_union(d_circle, d_box);
	} else if (op == 1) {
		dist = op_intersection(d_circle, d_box);
	} else {
		dist = op_subtraction(d_circle, d_box);
	}

	float shape = 1.0 - smoothstep(-0.005, 0.005, dist);

	// Show individual shape outlines for reference
	float outline_c = 1.0 - smoothstep(0.0, 0.006, abs(d_circle));
	float outline_b = 1.0 - smoothstep(0.0, 0.006, abs(d_box));

	vec3 color = mix(bg_color, shape_color, shape);
	color = mix(color, vec3(0.9, 0.3, 0.3), outline_c * 0.3);
	color = mix(color, vec3(0.3, 0.9, 0.3), outline_b * 0.3);

	ALBEDO = color;
}
