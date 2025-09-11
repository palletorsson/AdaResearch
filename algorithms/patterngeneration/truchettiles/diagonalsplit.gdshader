shader_type spatial;
render_mode blend_mix, cull_disabled;

uniform vec2 uv_scale = vec2(8.0,8.0);
uniform vec4 col_a : source_color = vec4(0.02,0.02,0.08,1.0);
uniform vec4 col_b : source_color = vec4(0.9,0.1,1.0,1.0);
uniform float edge_soft = 0.02;
float hash(vec2 p){ return fract(sin(dot(p,vec2(12.9898,78.233)))*43758.5453); }

void fragment(){
	vec2 tuv = UV * uv_scale;
	vec2 gid = floor(tuv);
	vec2 f = fract(tuv);

	// random flip / transpose per tile
	if (hash(gid) > 0.5) f = vec2(1.0-f.x, f.y);
	if (hash(gid+3.0) > 0.5) f = f.yx;

	float d = f.x - f.y; // diagonal
	float t = smoothstep(-edge_soft, edge_soft, d);
	vec3 col = mix(col_a.rgb, col_b.rgb, t);
	ALBEDO = col;
}
