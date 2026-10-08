shader_type spatial;
render_mode cull_disabled;
void fragment() {
	vec2 thread = abs(fract(UV * vec2(180.0,32.0)) - 0.5);
	vec2 aa = max(fwidth(UV * vec2(180.0,32.0)), vec2(0.015));
	float weave = max(1.0-smoothstep(0.10-aa.x,0.10+aa.x,thread.x),1.0-smoothstep(0.10-aa.y,0.10+aa.y,thread.y));
	ALBEDO = mix(vec3(0.22,0.12,0.15), vec3(0.54,0.32,0.36), weave*0.48+0.25);
	ROUGHNESS = 0.82;
}
