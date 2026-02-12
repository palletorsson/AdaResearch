shader_type spatial;
render_mode blend_mix, cull_back;

// Per-instance color comes from MultiMesh COLOR
// Per-instance custom_data:
//   .r = emission energy (0.0 = dark, 1.5 = bright birth flash)
//   .g = cell age (0.0 = newborn, 1.0 = old)
//   .b = state (0 = dead, 1 = alive, 2+ = custom states)
//   .a = spare

uniform float metallic : hint_range(0.0, 1.0) = 0.05;
uniform float roughness : hint_range(0.0, 1.0) = 0.55;
uniform float idle_pulse_strength : hint_range(0.0, 0.15) = 0.04;
uniform float idle_pulse_speed : hint_range(0.0, 8.0) = 2.0;
uniform float rim_power : hint_range(0.5, 8.0) = 3.0;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.25;

void fragment() {
	vec3 cell_color = COLOR.rgb;
	float emission_energy = INSTANCE_CUSTOM.r;
	float cell_age = INSTANCE_CUSTOM.g;

	// Idle breathing — each instance slightly offset by its color hash
	float phase_offset = dot(cell_color, vec3(17.0, 31.0, 47.0));
	float pulse = sin(TIME * idle_pulse_speed + phase_offset) * idle_pulse_strength;

	// Soften emission with age (newborns flash brighter)
	float age_factor = mix(1.0, 0.7, clamp(cell_age, 0.0, 1.0));

	// Final emission
	float final_emission = max(0.0, emission_energy * age_factor + pulse);

	// Rim light — subtle edge glow for physical presence
	float rim = pow(1.0 - max(dot(NORMAL, VIEW), 0.0), rim_power);

	ALBEDO = cell_color * 0.4; // cells are mostly emission-driven, albedo stays dark
	METALLIC = metallic;
	ROUGHNESS = roughness;
	EMISSION = cell_color * final_emission + cell_color * rim * rim_strength * final_emission;
}
