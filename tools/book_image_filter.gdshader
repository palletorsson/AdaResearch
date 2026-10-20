shader_type canvas_item;
render_mode unshaded;
// Reproducible screenshot treatments. No geometry or marks are invented.
uniform sampler2D source_image : filter_linear, repeat_disable;
uniform vec2 source_size = vec2(1600.0,1200.0);
uniform int treatment = 0; // 0 contour, 1 hatch, 2 ink, 3 faint page ink, 4 continuous tone
uniform float line_width = 1.0;
uniform float sensitivity = 0.11;
// Independently control faint-stroke contrast without widening the contours.
uniform float edge_softness : hint_range(0.001, 0.5) = 0.18;
// Treatment 4 preserves luminance gradients. No spatial blur or edge threshold.
uniform float tone_white : hint_range(0.01, 1.0) = 0.94;
uniform float tone_black : hint_range(0.0, 0.99) = 0.06;
uniform vec4 paper : source_color = vec4(0.953,0.941,0.906,1.0);
uniform vec4 ink : source_color = vec4(0.075,0.082,0.078,1.0);

float value_at(vec2 uv) {
	return dot(texture(source_image,uv).rgb,vec3(0.2126,0.7152,0.0722));
}
void fragment() {
	vec2 d = line_width / source_size;
	float a=value_at(UV+vec2(-d.x,-d.y)); float b=value_at(UV+vec2(0.0,-d.y)); float c=value_at(UV+vec2(d.x,-d.y));
	float e=value_at(UV+vec2(-d.x,0.0)); float f=value_at(UV+vec2(d.x,0.0));
	float g=value_at(UV+vec2(-d.x,d.y)); float h=value_at(UV+vec2(0.0,d.y)); float i=value_at(UV+vec2(d.x,d.y));
	float gx=-a-2.0*e-g+c+2.0*f+i;
	float gy=-a-2.0*b-c+g+2.0*h+i;
	float edge=smoothstep(sensitivity,sensitivity+edge_softness,length(vec2(gx,gy)));
	float centre=value_at(UV);
	float mark=edge;
	vec2 px=UV*source_size;
	if(treatment==1) {
		// Regular print hatching follows existing dark regions, not a new motion path.
		float line=1.0-smoothstep(0.65,1.35,abs(mod(px.x+px.y,7.0)-3.5));
		float cross=1.0-smoothstep(0.5,1.2,abs(mod(px.x-px.y,9.0)-4.5));
		mark=max(mark,line*(1.0-smoothstep(0.42,0.72,centre)));
		mark=max(mark,cross*(1.0-smoothstep(0.12,0.30,centre)));
	}
	if(treatment==2) mark=max(edge,1.0-smoothstep(0.31,0.47,centre));
	if(treatment==3) {
		// Measure each existing dark stroke against nearby paper. This keeps
		// partially faded digits without making a second outline around glyphs.
		// Flat blank paper still produces no ink; no text is reconstructed.
		vec2 radius=vec2(4.0)/source_size;
		float local_paper=centre;
		for(int x=-1;x<=1;x++) {
			for(int y=-1;y<=1;y++) local_paper=max(local_paper,value_at(UV+vec2(float(x),float(y))*radius));
		}
		mark=smoothstep(sensitivity,sensitivity+edge_softness,local_paper-centre);
	}
	if(treatment==4) mark=clamp((tone_white-centre)/max(tone_white-tone_black,0.001),0.0,1.0);
	COLOR=mix(paper,ink,clamp(mark,0.0,1.0));
}
