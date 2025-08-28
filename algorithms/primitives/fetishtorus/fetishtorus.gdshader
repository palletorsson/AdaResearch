shader_type spatial;

uniform float inner_color_speed = 0.5;
uniform float outer_color_speed = 0.7;
uniform float gradient_spread = 0.5;
uniform vec3 light_dir;

void vertex() {
	// A simple vertex shader, no transformation needed for this effect.
}

void fragment() {
	// Calculate a simple time-based color for a fluid effect
	vec3 inner_color = vec3(0.5 + sin(TIME * inner_color_speed) * 0.5, 0.5 + cos(TIME * inner_color_speed * 1.2) * 0.5, 0.5 + sin(TIME * inner_color_speed * 1.5) * 0.5);
	vec3 outer_color = vec3(0.5 + cos(TIME * outer_color_speed) * 0.5, 0.5 + sin(TIME * outer_color_speed * 1.2) * 0.5, 0.5 + cos(TIME * outer_color_speed * 1.5) * 0.5);

	// Determine the color based on the fragment's position relative to the center
	float dist_from_center = distance(UV, vec2(0.5, 0.5));
	float gradient = smoothstep(0.0, gradient_spread, dist_from_center);

	vec3 fluid_color = mix(inner_color, outer_color, gradient);

	// The `NORMAL` is provided by the engine. We can use it to create a lighting effect.
	float light_intensity = dot(NORMAL, light_dir);
	ALBEDO = fluid_color * (1.0 + light_intensity * 0.5);
	
	// Add a subtle metallic or specular feel
	ROUGHNESS = 0.2;
	METALLIC = 0.5;
}