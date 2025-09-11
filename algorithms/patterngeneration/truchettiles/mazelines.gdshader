shader_type spatial;
render_mode blend_mix, cull_disabled;

uniform vec2 uv_scale = vec2(7.0,7.0);
uniform float line_w = 0.1;
uniform vec4 col_bg : source_color = vec4(0.02,0.0,0.06,1.0);
uniform vec4 col_ln : source_color = vec4(0.2,1.0,0.9,1.0);
uniform float glow = 1.0;

float hash(vec2 p){ return fract(sin(dot(p,vec2(157.31,253.17)))*43758.5453); }

void fragment(){
	vec2 tuv = UV * uv_scale;
	vec2 gid = floor(tuv);
	vec2 f = fract(tuv);

	// rotate 0/90
	if (hash(gid) > 0.5) f = f.yx;

	// draw a horizontal line mid + two quarter arcs connecting
	float line = 1.0 - smoothstep(line_w, line_w*0.6, abs(f.y-0.5));
	float arc1 = 1.0 - smoothstep(line_w, line_w*0.6, abs(length(f-vec2(0.0,0.5))-0.5));
	float arc2 = 1.0 - smoothstep(line_w, line_w*0.6, abs(length(f-vec2(1.0,0.5))-0.5));
	float m = max(line, max(arc1, arc2));

	vec3 col = mix(col_bg.rgb, col_ln.rgb, m);
	ALBEDO = col;
	EMISSION = col_ln.rgb * m * glow;
}
