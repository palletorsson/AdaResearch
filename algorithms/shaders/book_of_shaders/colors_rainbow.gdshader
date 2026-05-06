shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.6: Rainbow using sin() RGB offsets
// Classic demoscene rainbow technique with animation

uniform float speed : hint_range(0.0, 5.0) = 1.0;
uniform float frequency : hint_range(1.0, 10.0) = 3.0;
uniform float phase_r : hint_range(0.0, 6.28) = 0.0;
uniform float phase_g : hint_range(0.0, 6.28) = 2.094;
uniform float phase_b : hint_range(0.0, 6.28) = 4.188;

void fragment() {
	vec2 uv = UV;

	float t = uv.x * frequency + TIME * speed;

	float r = 0.5 + 0.5 * sin(t + phase_r);
	float g = 0.5 + 0.5 * sin(t + phase_g);
	float b = 0.5 + 0.5 * sin(t + phase_b);

	// Add vertical variation
	float vy = 0.5 + 0.5 * sin(uv.y * 3.14159);
	vec3 color = vec3(r, g, b) * (0.7 + 0.3 * vy);

	ALBEDO = color;
}
