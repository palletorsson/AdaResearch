shader_type spatial;
render_mode blend_mix, cull_disabled;

uniform vec2 uv_scale = vec2(2.0, 12.0);
uniform float line_width = 0.15;
uniform float speed = 1.0;
uniform vec4 col_bg : source_color = vec4(0.0,0.02,0.06,1.0);
uniform vec4 col_ln : source_color = vec4(1.0,0.6,0.0,1.0);
uniform float glow = 1.0;

void fragment(){
	vec2 uv = UV * uv_scale;
	uv.y += TIME*speed;
	float band = 1.0 - smoothstep(line_width, line_width*0.6, abs(fract(uv.y)-0.5));
	vec3 col = mix(col_bg.rgb, col_ln.rgb, band);
	ALBEDO = col;
	EMISSION = col_ln.rgb * band * glow;
}