shader_type spatial;
render_mode blend_mix, cull_disabled;

uniform vec2 uv_scale = vec2(6.0,6.0);
uniform float puff : hint_range(0.0,2.0)=1.0;
uniform vec4 col_fabric : source_color = vec4(0.05,0.02,0.08,1.0);
uniform vec4 col_stitch : source_color = vec4(1.0,0.2,0.8,1.0);
uniform float stitch_width = 0.06;

vec2 hex(vec2 p){
	p *= uv_scale;
	const vec2 h = vec2(1.0, 1.7320508);
	vec2 q = vec2(p.x*2.0/h.x, (p.y + floor(0.5+p.x))*2.0/h.y);
	return fract(q) - 0.5;
}

void fragment(){
	vec2 p = hex(UV);
	float d = max(abs(p.x)+p.y*0.57735, -p.y*1.1547); // hex distance proxy
	float edge = smoothstep(stitch_width, stitch_width*0.6, abs(d));
	float dome = 1.0 - smoothstep(0.0, 0.5, length(p))*puff;
	vec3 col = col_fabric.rgb * (0.6 + 0.4*dome);
	col = mix(col, col_stitch.rgb, edge);
	ALBEDO = col;
	ROUGHNESS = 0.5 - 0.2*dome;
	METALLIC = 0.0;
	EMISSION = col_stitch.rgb * edge * 0.6;
}
