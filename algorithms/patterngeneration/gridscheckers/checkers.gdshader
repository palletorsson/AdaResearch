shader_type spatial;
render_mode blend_mix, cull_disabled;

uniform vec2 uv_scale = vec2(20.0, 20.0);
uniform vec4 col_a : source_color = vec4(0.05,0.02,0.08,1.0);
uniform vec4 col_b : source_color = vec4(1.0,1.0,1.0,1.0);
uniform float glow = 0.8;

void fragment(){
	vec2 uv = UV * uv_scale;
	float c = mod(floor(uv.x)+floor(uv.y), 2.0);
	vec3 col = mix(col_a.rgb, col_b.rgb, c);
	ALBEDO = col;
	EMISSION = col * glow * c;
}
