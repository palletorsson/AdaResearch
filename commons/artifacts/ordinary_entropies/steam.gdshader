shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float clock = 0.0;
uniform float warmth = 1.0;
void fragment() {
	vec2 p=UV;
	float wobble=sin(p.y*17.0-clock*1.4)*0.09+sin(p.y*31.0+clock)*0.035;
	float width=mix(0.06,0.36,1.0-p.y);
	float column=exp(-pow((p.x-0.5-wobble)/width,2.0)*3.0);
	float wisps=0.55+0.45*sin(p.y*34.0+clock*2.2+sin(p.x*23.0));
	ALBEDO=vec3(0.92,0.93,0.92);
	ALPHA=column*wisps*sin(p.y*3.14159)*0.72*warmth;
}
