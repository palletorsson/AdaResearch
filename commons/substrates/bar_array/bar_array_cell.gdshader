shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform float metallic : hint_range(0.0, 1.0) = 0.15;
uniform float roughness : hint_range(0.0, 1.0) = 0.35;

varying flat float v_emission;
varying flat float v_instance_id;
varying flat vec4 v_color;

void vertex() {
	v_color = COLOR;	v_instance_id = float(INSTANCE_ID);
	v_emission = INSTANCE_CUSTOM.r;
}

void fragment() {
	ALBEDO = v_color.rgb;
	METALLIC = metallic;
	ROUGHNESS = roughness;

	// Emission from instance custom data + subtle idle breathing
	float breath = sin(TIME * 2.0 + v_instance_id * 0.37) * 0.03;
	float em = max(v_emission + breath, 0.0);
	EMISSION = v_color.rgb * em;
}
