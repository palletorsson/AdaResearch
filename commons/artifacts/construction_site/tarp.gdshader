shader_type spatial;
render_mode cull_disabled;
uniform vec4 base_color : source_color = vec4(0.19, 0.25, 0.40, 1.0);
uniform float wind_amplitude = 0.045;
uniform float wind_speed = 0.32;

void vertex() {
	// Top and sides stay tied; only the hanging interior moves. No CPU simulation.
	float free_cloth = sin(UV.x * 3.14159265) * UV.y;
	VERTEX.z += wind_amplitude * free_cloth * (sin(TIME * wind_speed + UV.x * 6.0 + UV.y * 3.0) + 0.3 * sin(TIME * wind_speed * 0.63 + UV.y * 9.0));
}

void fragment() {
	float fold = 0.94 + 0.06 * sin(UV.x * 96.0 + UV.y * 2.0);
	ALBEDO = base_color.rgb * fold;
	ROUGHNESS = 0.88;
}
