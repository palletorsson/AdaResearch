shader_type spatial;

// Transparent volumetric: draw with alpha prepass, no culling, unshaded so emission shows.
render_mode blend_mix, unshaded, cull_disabled;

uniform float time_scale : hint_range(0.0, 2.0) = 0.25;
uniform float noise_scale : hint_range(0.1, 8.0) = 1.75;
uniform float density     : hint_range(0.0, 5.0) = 1.35;
uniform int   march_steps = 72;

uniform float fbm_detail   : hint_range(0.0, 1.0) = 0.8;  // mixes in extra octaves
uniform float warp_amount  : hint_range(0.0, 1.0) = 0.2;  // flow/noise warping
uniform float contrast     : hint_range(0.5, 2.0) = 1.15; // boosts mid/highs
uniform float edge_softness: hint_range(0.0, 0.2) = 0.04; // fade near box walls
uniform float jitter_amount: hint_range(0.0, 1.0) = 1.0;  // per-pixel step jitter

// Simple “lighting”
uniform vec3  light_dir =  vec3(0.4, 0.7, 0.3);
uniform float light_strength : hint_range(0.0, 5.0) = 1.6;
uniform float phase_g        : hint_range(-0.9, 0.9) = 0.2; // forward scattering
uniform float rim_strength   : hint_range(0.0, 2.0) = 0.5;
uniform float emission_boost : hint_range(0.0, 3.0) = 0.6;

// Color controls (fallback when no gradient provided)
uniform vec4 color1 : source_color = vec4(0.0, 0.45, 1.0, 1.0);
uniform vec4 color2 : source_color = vec4(0.4, 1.0, 1.0, 1.0);
uniform vec4 color3 : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// Optional 1D gradient (set a tiny horizontal gradient texture; x = 0..1)
uniform sampler2D gradient_tex : hint_default_black;

// Varyings (object-space ray)
varying vec3 v_ray_origin;
varying vec3 v_ray_dir;

// --------- 3D simplex noise (your original) ----------
vec3 mod289(vec3 x){ return x - floor(x*(1.0/289.0))*289.0; }
vec4 mod289(vec4 x){ return x - floor(x*(1.0/289.0))*289.0; }
vec4 permute(vec4 x){ return mod289(((x*34.0)+1.0)*x); }
vec4 taylor_inv_sqrt(vec4 r){ return 1.79284291400159 - 0.85373472095314*r; }
float snoise(vec3 v){
	const vec2 C=vec2(1.0/6.0,1.0/3.0); const vec4 D=vec4(0.0,0.5,1.0,2.0);
	vec3 i=floor(v+dot(v,C.yyy)); vec3 x0=v-i+dot(i,C.xxx);
	vec3 g=step(x0.yzx,x0.xyz); vec3 l=1.0-g; vec3 i1=min(g.xyz,l.zxy); vec3 i2=max(g.xyz,l.zxy);
	vec3 x1=x0-i1+C.xxx; vec3 x2=x0-i2+C.yyy; vec3 x3=x0-D.yyy;
	i=mod289(i);
	vec4 p=permute(permute(permute(i.z+vec4(0.0,i1.z,i2.z,1.0))+i.y+vec4(0.0,i1.y,i2.y,1.0))+i.x+vec4(0.0,i1.x,i2.x,1.0));
	float n_=0.142857142857; vec3 ns=n_*D.wyz-D.xzx;
	vec4 j=p-49.0*floor(p*ns.z*ns.z);
	vec4 x_=floor(j*ns.z); vec4 y_=floor(j-7.0*x_);
	vec4 x=x_*ns.x+ns.yyyy; vec4 y=y_*ns.x+ns.yyyy;
	vec4 h=1.0-abs(x)-abs(y);
	vec4 b0=vec4(x.xy,y.xy); vec4 b1=vec4(x.zw,y.zw);
	vec4 s0=floor(b0)*2.0+1.0; vec4 s1=floor(b1)*2.0+1.0;
	vec4 sh=-step(h,vec4(0.0));
	vec4 a0=b0.xzyw+s0.xzyw*sh.xxyy; vec4 a1=b1.xzyw+s1.xzyw*sh.zzww;
	vec3 p0=vec3(a0.xy,h.x); vec3 p1=vec3(a0.zw,h.y);
	vec3 p2=vec3(a1.xy,h.z); vec3 p3=vec3(a1.zw,h.w);
	vec4 norm=taylor_inv_sqrt(vec4(dot(p0,p0),dot(p1,p1),dot(p2,p2),dot(p3,p3)));
	p0*=norm.x; p1*=norm.y; p2*=norm.z; p3*=norm.w;
	vec4 m=max(0.6-vec4(dot(x0,x0),dot(x1,x1),dot(x2,x2),dot(x3,x3)),0.0); m*=m;
	return 42.0*dot(m*m, vec4(dot(p0,x0),dot(p1,x1),dot(p2,x2),dot(p3,x3)));
}

// fBM (multi-octave noise 0..1)
float fbm(vec3 p){
	float a=0.5, s=0.0;
	for(int i=0;i<5;i++){
		s += a * snoise(p);
		p = p*2.02 + vec3(13.1, 7.7, 5.3);
		a *= 0.5;
	}
	return s*0.5 + 0.5;
}

// Little hash for jitter
float hash12(vec2 p){
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

// Ray-box intersection in object space (unit cube centered at 0)
vec2 ray_box_intersect(vec3 ro, vec3 rd){
	vec3 mn = vec3(-0.5), mx = vec3(0.5);
	vec3 inv = 1.0/rd;
	vec3 t0 = (mn - ro) * inv;
	vec3 t1 = (mx - ro) * inv;
	vec3 tminv = min(t0, t1);
	vec3 tmaxv = max(t0, t1);
	float tmin = max(max(tminv.x, tminv.y), tminv.z);
	float tmax = min(min(tmaxv.x, tmaxv.y), tmaxv.z);
	return vec2(tmin, tmax);
}

// Distance to box boundary (for soft edges)
float box_inner_edge(vec3 p){
	float hw = 0.5;
	float k = hw - max(max(abs(p.x), abs(p.y)), abs(p.z)); // 0 at wall, >0 inside
	return smoothstep(0.0, edge_softness, k);
}

// Color ramp (use gradient if provided)
vec3 ramp(float t){
	if (textureSize(gradient_tex, 0).x > 0) {
		return texture(gradient_tex, vec2(clamp(t,0.0,1.0), 0.5)).rgb;
	}
	vec3 c = mix(color1.rgb, color2.rgb, smoothstep(0.0, 0.6, t));
	return mix(c, color3.rgb,  smoothstep(0.6, 1.0, t));
}

// Simple phase function (Henyey–Greenstein-ish)
float phase(float cosTheta, float g){
	float g2 = g*g;
	return (1.0 - g2) / pow(1.0 + g2 - 2.0*g*cosTheta, 1.5);
}

void vertex(){
	// Object-space ray origin & dir
	v_ray_origin = (inverse(MODEL_MATRIX) * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz;
	vec3 world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 world_dir    = normalize(world_vertex - CAMERA_POSITION_WORLD);
	v_ray_dir = (inverse(MODEL_MATRIX) * vec4(world_dir, 0.0)).xyz;
}

void fragment(){
	vec2 tspan = ray_box_intersect(v_ray_origin, v_ray_dir);
	float tmin = max(tspan.x, 0.0);
	float tmax = tspan.y;
	if (tmin >= tmax) { discard; }

	float step_size = (tmax - tmin) / float(max(march_steps,1));

	// Per-pixel jitter to reduce banding
	float jitter = mix(0.0, hash12(FRAGCOORD.xy), jitter_amount);

	vec3  accum_rgb = vec3(0.0);
	float accum_a   = 0.0;

	vec3 V = normalize(-v_ray_dir);                 // view direction in object space
	vec3 L = normalize((inverse(MODEL_MATRIX) * vec4(normalize(light_dir), 0.0)).xyz);

	for (int i = 0; i < march_steps; i++){
		float t = tmin + (float(i) + jitter) * step_size;
		vec3 pos = v_ray_origin + v_ray_dir * t;

		// Animated coordinates with light flow warp
		vec3 p = pos * noise_scale + vec3(0.0, 0.0, TIME * time_scale);
		if (warp_amount > 0.0){
			vec3 w = vec3(snoise(p + 17.3), snoise(p + 3.7), snoise(p - 9.1));
			p += w * warp_amount;
		}

		// Base noise + fBM detail
		float n  = snoise(p) * 0.5 + 0.5;
		if (fbm_detail > 0.0){
			float d = fbm(p * 0.75);
			n = mix(n, d, fbm_detail);
		}

		// Contrast & edge softening
		n = pow(clamp(n,0.0,1.0), 1.0/contrast);
		float edge = box_inner_edge(pos);
		float alpha = density * step_size * n * edge;

		// Simple lighting: forward scattering + rim
		float cosLV = dot(L, V);
		float scatter = phase(cosLV, phase_g) * light_strength;
		float rim = pow(1.0 - max(dot(V, normalize(vec3(
			// approximate gradient via forward differences (cheap)
			snoise(p + vec3(0.01,0.0,0.0)) - snoise(p),
			snoise(p + vec3(0.0,0.01,0.0)) - snoise(p),
			snoise(p + vec3(0.0,0.0,0.01)) - snoise(p)
		))), 0.0), 2.0) * rim_strength;

		float shade = 0.35 + scatter + rim; // ambient + extras

		vec3 col = ramp(n) * shade;
		vec3 src = col;

		// Pre-multiplied-ish front-to-back blending
		float trans = (1.0 - accum_a);
		accum_rgb += src * alpha * trans;
		accum_a   += alpha * trans;

		if (accum_a >= 0.99) break;
	}

	ALBEDO   = accum_rgb;
	ALPHA    = accum_a;
	EMISSION = accum_rgb * emission_boost;
}
