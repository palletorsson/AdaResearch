shader_type spatial;
render_mode cull_disabled, diffuse_burley;

varying vec3 rock_position;

void vertex() {
	rock_position = VERTEX;
}

void fragment() {
	float ripple = sin(rock_position.z * 3.5 + sin(rock_position.x * 5.0)) * 0.16;
	float grain = sin(rock_position.x * 58.0 + rock_position.z * 39.0) *
		sin(rock_position.y * 71.0 - rock_position.z * 47.0) * 0.026;
	float strata = sin((rock_position.y + ripple) * 22.0) * 0.5 + 0.5;
	float mineral = smoothstep(0.26, 0.94, strata + grain);
	vec3 stone = mix(vec3(0.22, 0.19, 0.27), vec3(0.64, 0.34, 0.49), mineral);
	ALBEDO = stone;
	ROUGHNESS = 0.87;
	EMISSION = stone * 0.16;
}
