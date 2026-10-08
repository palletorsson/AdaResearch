shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;
uniform int finish = 0;
uniform float motion = 0.0;
uniform float clock = 0.0;
varying vec3 place;
void vertex(){ place = VERTEX; }
void fragment(){
 vec3 p=place;
 float phase=clock;
 float weave=sin(p.x*2.3+sin(p.z*1.6+phase)*1.8)+sin(p.y*3.4+p.z*.7)*.6;
 float vein=abs(sin(weave*3.5+p.y*1.2));
 float facing=clamp(dot(normalize(NORMAL),normalize(VIEW)),0.0,1.0);
 float edge=pow(1.0-facing,2.6);
 float thinfilm=.5+.5*sin(facing*9.0+weave*.65);
 float trace=1.0-smoothstep(.045,.105,vein);
 if(finish==0){
  vec3 pearl=mix(vec3(.13,.12,.44),vec3(.84,.32,.60),thinfilm);
  ALBEDO=mix(pearl,vec3(.58,.75,.97),edge*.8);
  METALLIC=.48; ROUGHNESS=.20+.14*vein;
  EMISSION=ALBEDO*.075+vec3(.24,.18,.48)*trace*.18;
 }else if(finish==1){
  ALBEDO=mix(vec3(.38,.10,.012),vec3(.80,.34,.05),.4+.4*vein);
  METALLIC=.62; ROUGHNESS=.20+.12*vein;
  EMISSION=vec3(1.0,.23,.009)*trace*.23;
 }else if(finish==2){
  float seam=1.0-smoothstep(.045,.085,abs(sin(p.y*1.9+sin(p.z*1.2)*.6)));
  ALBEDO=mix(vec3(.06,.075,.11),vec3(.15,.19,.26),smoothstep(.25,.92,vein));
  METALLIC=.88; ROUGHNESS=.10+.065*vein;
  EMISSION=vec3(.8,.10,.38)*seam*.55;
 }else{
  ALBEDO=vec3(.62,.60,.55); METALLIC=0.0; ROUGHNESS=.9; EMISSION=vec3(0.0);
 }
 SPECULAR=.7;
}
