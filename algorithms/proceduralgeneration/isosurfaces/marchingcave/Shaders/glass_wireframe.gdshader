shader_type spatial;
render_mode cull_disabled;

uniform vec4 glass_color : source_color = vec4(0.2, 0.4, 1.0, 1.0);
uniform vec4 outline_color : source_color = vec4(1.0, 0.0, 0.5, 1.0);
uniform float outline_width : hint_range(0.5, 5.0) = 1.5;

varying vec3 barycentric;

void vertex() {
	// Assign barycentric coords based on vertex ID
	int vid = VERTEX_ID % 3;
	if (vid == 0) barycentric = vec3(1.0, 0.0, 0.0);
	else if (vid == 1) barycentric = vec3(0.0, 1.0, 0.0);
	else barycentric = vec3(0.0, 0.0, 1.0);
}

void fragment() {
	// Edge factor from barycentrics
	vec3 d = fwidth(barycentric);
	vec3 a3 = smoothstep(vec3(0.0), d * outline_width, barycentric);
	float edge = 1.0 - min(min(a3.x, a3.y), a3.z);

	// Mix between glass fill and outline
	vec3 color = mix(glass_color.rgb, outline_color.rgb, edge);

	ALBEDO = color;

	// Glassy appearance
	METALLIC = 0.1;
	ROUGHNESS = 0.1;

	// Edge glow
	EMISSION = outline_color.rgb * edge * 1.2;
}
