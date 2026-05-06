shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 trace_color : source_color = vec4(0.2, 1.0, 0.4, 1.0);
uniform float emission_energy : hint_range(0.0, 3.0) = 0.8;
uniform float glow_falloff : hint_range(0.0, 1.0) = 0.3;

void vertex() {
	// Use vertex color from ImmediateMesh
}

void fragment() {
	ALBEDO = COLOR.rgb;
	METALLIC = 0.0;
	ROUGHNESS = 0.4;

	// Emission with slight pulse
	float pulse = sin(TIME * 2.0) * 0.05;
	EMISSION = COLOR.rgb * (emission_energy + pulse);
}
