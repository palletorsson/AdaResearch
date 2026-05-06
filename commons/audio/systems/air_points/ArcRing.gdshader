shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 albedo : source_color;
uniform float arc_end : hint_range(0.0, 1.0) = 0.5;
uniform float alpha_scintillation : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	// UV.x usually goes 0..1 around the torus.
	// We discard pixels beyond the arc_end fraction.
	if (UV.x > arc_end) {
		discard;
	}
	
	vec3 col = albedo.rgb;
	// Add subtle scintillation/noise for "alive" look
	if (alpha_scintillation > 0.0) {
		float noise = fract(sin(dot(UV, vec2(12.9898, 78.233))) * 43758.5453);
		col += noise * alpha_scintillation;
	}
	
	ALBEDO = col;
	ALPHA = albedo.a;
}

