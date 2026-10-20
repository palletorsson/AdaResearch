shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
uniform sampler2D camera_frame : source_color, filter_linear, repeat_disable;
uniform sampler2D held_frame : source_color, filter_linear, repeat_disable;
uniform int mode = 0;
uniform float amount : hint_range(0,1) = 0.8;
uniform bool has_held = false;
void vertex() {
	if (mode==1) {
		float light=dot(textureLod(camera_frame,UV,0.0).rgb,vec3(.2126,.7152,.0722));
		VERTEX.z+=amount*1.2*light;
	}
}
void fragment() {
	vec2 uv=UV;
	if (mode==7) uv.x=fract(uv.x+amount*.071*floor(uv.y*16.0));
	vec3 colour=texture(camera_frame,uv).rgb;
	if (mode==6 && has_held && mod(floor(UV.y*16.0),2.0)>0.5) {
		colour=mix(colour,texture(held_frame,UV).rgb,amount);
	}
	if (mode==8 && dot(colour,vec3(.2126,.7152,.0722))<amount*.6) discard;
	ALBEDO=colour;
}
