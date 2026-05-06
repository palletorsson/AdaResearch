shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.6: mix() between two colors
// Shows the interpolation with adjustable t parameter

uniform vec3 color_a : source_color = vec3(0.0, 0.78, 0.85);
uniform vec3 color_b : source_color = vec3(0.95, 0.45, 0.15);
uniform float t_value : hint_range(0.0, 1.0) = 0.5;
uniform float show_gradient : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 uv = UV;

	// Flat mixed color
	vec3 mixed = mix(color_a, color_b, t_value);

	// Gradient version: t varies with x
	vec3 gradient = mix(color_a, color_b, uv.x);

	// Blend between flat and gradient
	vec3 color = mix(mixed, gradient, show_gradient);

	// Show the t_value position as a vertical line on the gradient
	if (show_gradient > 0.5) {
		float line = 1.0 - smoothstep(0.0, 0.004, abs(uv.x - t_value));
		color = mix(color, vec3(1.0), line * 0.8);

		// Show the two source colors as bars at top and bottom
		if (uv.y < 0.08) {
			color = color_b;
		} else if (uv.y > 0.92) {
			color = color_a;
		}
	}

	ALBEDO = color;
}
