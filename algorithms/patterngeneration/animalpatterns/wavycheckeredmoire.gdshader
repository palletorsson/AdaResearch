shader_type spatial;
render_mode blend_mix, cull_disabled;

uniform vec2 uv_scale = vec2(10.0,10.0);
uniform float flake_size = 25.0;
uniform float sparkle = 1.6;
uniform float metallic : hint_range(0.0,1.0)=0.8;
uniform float roughness : hint_range(0.0,1.0)=0.2;

float hash(vec2 p){ return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }

void fragment(){
	vec2 uv = UV*uv_scale;
	vec2 iuv = floor(uv*flake_size);
	vec2 fuv = fract(uv*flake_size);
	float h = hash(iuv);
	float a = h*6.28318 + TIME*0.7;
	vec2 c = vec2(0.5)+0.35*vec2(cos(a), sin(a));
	float d = length(fuv - c);
	float flake = smoothstep(0.25, 0.0, d);
	vec3 base = vec3(0.05,0.01,0.08);
	vec3 irid = vec3(0.5+0.5*sin(a), 0.5+0.5*sin(a+2.1), 0.5+0.5*sin(a+4.2));
	vec3 col = mix(base, irid, flake);
	ALBEDO = col;
	EMISSION = col * flake * sparkle;
	METALLIC = metallic; ROUGHNESS = roughness;
}
