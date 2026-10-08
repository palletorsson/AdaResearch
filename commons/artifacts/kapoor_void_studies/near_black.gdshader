shader_type spatial;
render_mode cull_disabled;

// An authored near-black study, not Vantablack or a claim about Kapoor's pigment.
// UV position lets the rim barely register while the bowl's centre stays unreadable.
uniform vec3 abyss_color : source_color = vec3(0.00035, 0.00018, 0.0010);
uniform vec3 edge_color : source_color = vec3(0.008, 0.0011, 0.014);
uniform float edge_width : hint_range(0.02, 0.5) = 0.19;

void fragment() {
	float radial = length(UV * 2.0 - vec2(1.0));
	float edge = smoothstep(1.0 - edge_width, 1.0, radial);
	ALBEDO = mix(abyss_color, edge_color, edge);
	ROUGHNESS = 0.98;
	METALLIC = 0.0;
	SPECULAR = 0.03;
	EMISSION = mix(abyss_color * 0.12, edge_color * 0.32, edge);
}
