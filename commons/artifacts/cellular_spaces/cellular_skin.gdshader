shader_type spatial;
render_mode cull_disabled;

uniform vec3 dark_tone : source_color = vec3(0.22,0.23,0.09);
uniform vec3 light_tone : source_color = vec3(0.79,0.77,0.54);
uniform vec3 seam_tone : source_color = vec3(1.0,0.93,0.60);
uniform float frequency = 0.65;
uniform float contrast = 0.6;
varying vec3 local_position;

vec3 feature(vec3 p) {
	return 0.15+0.7*fract(sin(vec3(dot(p,vec3(127.1,311.7,74.7)),dot(p,vec3(269.5,183.3,246.1)),dot(p,vec3(113.5,271.9,124.6))))*43758.5453);
}
void vertex() {local_position=VERTEX;}
void fragment() {
	vec3 p=local_position*frequency;
	vec3 cell=floor(p),f=fract(p);
	float f1=10.0,f2=10.0;
	for(int z=-1;z<=1;z++)for(int y=-1;y<=1;y++)for(int x=-1;x<=1;x++) {
		vec3 offset=vec3(float(x),float(y),float(z));
		float d=length(offset+feature(cell+offset)-f);
		if(d<f1){f2=f1;f1=d;}else{f2=min(f2,d);}
	}
	float ridge=1.0-smoothstep(0.025,0.095,f2-f1);
	vec3 colour=mix(dark_tone,light_tone,smoothstep(0.35,0.90,f1));
	ALBEDO=mix(light_tone,colour,contrast);
	EMISSION=seam_tone*(ridge*0.40+0.01);
	ROUGHNESS=0.7;
	METALLIC=0.0;
	if(dot(NORMAL,VIEW)<0.0){NORMAL=-NORMAL;}
}
