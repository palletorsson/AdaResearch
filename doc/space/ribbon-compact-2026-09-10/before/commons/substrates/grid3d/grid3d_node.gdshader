shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform float metallic : hint_range(0.0, 1.0) = 0.2;
uniform float roughness : hint_range(0.0, 1.0) = 0.3;

varying flat float v_emission;
varying flat vec4 v_color;

void vertex() {
	v_color = COLOR;
	v_emission = INSTANCE_CUSTOM.r;
}

void fragment() {
	ALBEDO = v_color.rgb;
	METALLIC = metallic;
	ROUGHNESS = roughness;

	// Emission + idle pulse
	float pulse = sin(TIME * 1.5 + float(INSTANCE_ID) * 0.73) * 0.04;
	float em = max(v_emission + pulse, 0.0);
	EMISSION = v_color.rgb * em;
}
