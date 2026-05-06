shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D texture_albedo : source_color;
uniform float reveal_height : hint_range(0.0, 1.0) = 1.0;
uniform vec3 edge_color : source_color = vec3(0.1, 0.1, 0.1); // Dark fade
uniform float edge_width = 0.02;

void fragment() {
	vec4 tex_col = texture(texture_albedo, UV);
	
	// Reveal from bottom (UV.y = 1.0) to top (UV.y = 0.0)
	// Visible range: UV.y >= (1.0 - reveal_height)
	float threshold = 1.0 - reveal_height;
	
	if (UV.y < threshold) {
		discard;
	}
	
	ALBEDO = tex_col.rgb;
	
	// Edge Effect
	float dist = UV.y - threshold;
	if (dist < edge_width) {
		float glow = 1.0 - (dist / edge_width);
		ALBEDO = mix(ALBEDO, edge_color, glow);
	}
}
