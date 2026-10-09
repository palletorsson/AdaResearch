shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 0.3);

void fragment() {
	float alpha = 0.0;
	if (UV.x < progress) {
		alpha = color.a;
	}
	
	ALBEDO = color.rgb;
	ALPHA = alpha;
}
