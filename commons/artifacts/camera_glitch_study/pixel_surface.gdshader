shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
uniform sampler2D camera_frame : source_color, filter_nearest, repeat_disable;
uniform sampler2D held_frame : source_color, filter_nearest, repeat_disable;
uniform bool has_held = false;
uniform int mode = 0;
uniform float amount : hint_range(0,1) = 0.8;

int wrap_index(int value, int count) { return ((value % count) + count) % count; }
vec3 pixel(ivec2 p, ivec2 size) {
	p=ivec2(wrap_index(p.x,size.x),wrap_index(p.y,size.y));
	return texture(camera_frame,(vec2(p)+vec2(.5))/vec2(size)).rgb;
}
void fragment() {
	ivec2 size=textureSize(camera_frame,0);
	ivec2 p=clamp(ivec2(UV*vec2(size)),ivec2(0),size-ivec2(1));
	ivec2 q=p;
	int offset=int(round(amount*float(size.x)*.22));
	int band=max(1,size.y/16);
	ivec2 block_size=max(ivec2(1),size/ivec2(8,6));
	ivec2 cell=min(p/block_size,ivec2(7,5));
	int cell_id=cell.y*8+cell.x;
	int rank=wrap_index(cell_id*13+7,48);
	if (mode==0) {
		q.x+=((p.y/band)%2==0 ? offset : -offset);
	} else if (mode==1) {
		int stride=size.x+int(round(amount*float(max(1,size.x/12))));
		int address=wrap_index(p.y*stride+p.x,size.x*size.y);
		q=ivec2(address%size.x,address/size.x);
	} else if (mode==2) {
		int repeat_count=1+int(round(amount*float(max(1,size.y/18))));
		q.y=(p.y/repeat_count)*repeat_count;
	} else if (mode==3) {
		ivec2 target=ivec2(rank%8,rank/8);
		q+=ivec2(round(vec2((target-cell)*block_size)*amount));
	} else if (mode==5) {
		if (p.y>=size.y*2/5 && p.y<size.y*3/5) q.x+=offset;
	} else if (mode==9 && (p.y%2)==1) {
		q.x=int(round(mix(float(p.x),float(size.x-1-p.x),amount)));
	}
	vec3 colour=pixel(q,size);
	if (mode==4) {
		int separation=int(round(amount*float(size.x)*.05));
		colour.r=pixel(p+ivec2(separation,0),size).r;
		colour.b=pixel(p-ivec2(separation,0),size).b;
	} else if (mode==6 && has_held && rank<int(round(amount*36.0))) {
		colour=texture(held_frame,(vec2(p)+vec2(.5))/vec2(size)).rgb;
	} else if (mode==7 && amount>0.0) {
		float levels=max(4.0,round(mix(256.0,4.0,amount)));
		colour=floor(colour*(levels-1.0)+vec3(.5))/(levels-1.0);
	} else if (mode==8 && rank<int(round(amount*24.0))) {
		colour=vec3(0.0);
	}
	ALBEDO=colour;
}
