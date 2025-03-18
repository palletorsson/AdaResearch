shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform vec4 glass_color : source_color = vec4(1.0, 1.0, 1.0, 0.1);
uniform float glass_roughness : hint_range(0.0, 1.0) = 0.05;
uniform float glass_metallic : hint_range(0.0, 1.0) = 0.0;
uniform float glass_specular : hint_range(0.0, 1.0) = 0.5;
uniform float refraction_scale : hint_range(0.0, 1.0) = 0.1;
uniform float ior : hint_range(1.0, 2.0) = 1.45;
uniform float fresnel_power : hint_range(1.0, 5.0) = 2.0;
uniform float edge_tint : hint_range(0.0, 1.0) = 0.1;
uniform float thickness = 0.1;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;

varying vec3 world_normal;
varying vec3 world_view;

void vertex() {
	world_normal = NORMAL;

}

void fragment() {
	// Calculate Fresnel effect
	vec3 normal = normalize(world_normal);
	vec3 view = normalize(world_view);
	float fresnel = pow(clamp(1.0 - dot(normal, -view), 0.0, 1.0), fresnel_power);

	// Set up material surface properties
	ALBEDO = glass_color.rgb;
	ALPHA = glass_color.a;
	METALLIC = glass_metallic;
	ROUGHNESS = glass_roughness;
	SPECULAR = glass_specular;

	// Apply refraction
	vec3 refraction_normal = NORMAL;
	vec2 screen_uv = SCREEN_UV;

	// Calculate refraction offset
	vec2 refraction_offset = refraction_normal.xy * refraction_scale;

	// Apply IOR adjustment to refraction offset
	refraction_offset *= (ior - 1.0);

	// Apply thickness to refraction offset
	refraction_offset *= thickness;

	// Get the screen color at the refracted point
	vec3 refraction_color = texture(SCREEN_TEXTURE, screen_uv + refraction_offset).rgb;

	// Apply fresnel to adjust transparency and reflectivity
	float final_alpha = mix(glass_color.a, 1.0, fresnel * edge_tint);

	// Apply the refraction and fresnel to the final output
	ALBEDO = mix(refraction_color, glass_color.rgb, final_alpha);
	EMISSION = refraction_color * (1.0 - final_alpha) * 0.3;

	// Enhanced specular highlights
	SPECULAR = mix(glass_specular, 1.0, fresnel);
}