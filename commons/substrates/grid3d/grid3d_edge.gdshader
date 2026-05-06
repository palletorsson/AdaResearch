shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform float metallic : hint_range(0.0, 1.0) = 0.05;
uniform float roughness : hint_range(0.0, 1.0) = 0.6;

varying flat float v_emission;
varying flat vec4 v_color;

void vertex() {
	v_color = COLOR;
	v_emission = INSTANCE_CUSTOM.r;
}

void fragment() {
	ALBEDO = v_color.rgb;
	ALPHA = v_color.a;
	METALLIC = metallic;
	ROUGHNESS = roughness;

	float em = max(v_emission, 0.0);
	EMISSION = v_color.rgb * em;
}
