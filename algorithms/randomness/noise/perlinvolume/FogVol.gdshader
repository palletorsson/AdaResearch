shader_type fog;

// ---------- Artistic controls ----------
uniform float base_density       : hint_range(0.0, 2.0) = 0.6;
uniform vec3  albedo_tint        : source_color = vec3(0.60, 0.85, 1.0);
uniform vec3  emission_tint      : source_color = vec3(0.10, 0.18, 0.28);
uniform float emission_strength  : hint_range(0.0, 2.0) = 0.25;

// Optional gradient palette: x = noise value (0..1)
uniform sampler2D palette : hint_default_white;

// ---------- Animation & zoom ----------
uniform vec3  scroll_dir         = vec3(0.0, 0.0, 0.35); // world-units/sec
uniform float base_scale         : hint_range(0.001, 10.0) = 0.9; // initial frequency
uniform float zoom_speed         : hint_range(0.0, 1.0)   = 0.05; // >0 means zoom OUT over time

// ---------- Fades & shaping ----------
uniform float height_fade_start  = 2.0;   // start fading above this world Y
uniform float height_fade_range  = 3.0;   // fade distance
uniform float edge_radius        = 1.5;   // spherical-ish fade from volume center
uniform float edge_softness      = 0.75;  // how soft the edge falloff is (0..3)

// ---------- Noise (fast gradient noise / FBM) ----------
uniform int   octaves            : hint_range(1,4) = 3;
uniform float lacunarity         : hint_range(1.5,3.0) = 2.0;
uniform float gain               : hint_range(0.2,0.8) = 0.5;

// --- 3D value/gradient noise (compact & fast) ---
vec3 hash3(vec3 p){
	p = vec3(
		dot(p, vec3(127.1, 311.7,  74.7)),
		dot(p, vec3(269.5, 183.3, 246.1)),
		dot(p, vec3(113.5, 271.9, 124.6))
	);
	return fract(sin(p)*43758.5453);
}

float noise3d(vec3 p){
	vec3 i = floor(p);
	vec3 f = fract(p);
	// smooth cubic curve
	vec3 u = f*f*(3.0-2.0*f);

	// 8 corners
	float n000 = dot(hash3(i+vec3(0,0,0)), f-vec3(0,0,0));
	float n100 = dot(hash3(i+vec3(1,0,0)), f-vec3(1,0,0));
	float n010 = dot(hash3(i+vec3(0,1,0)), f-vec3(0,1,0));
	float n110 = dot(hash3(i+vec3(1,1,0)), f-vec3(1,1,0));
	float n001 = dot(hash3(i+vec3(0,0,1)), f-vec3(0,0,1));
	float n101 = dot(hash3(i+vec3(1,0,1)), f-vec3(1,0,1));
	float n011 = dot(hash3(i+vec3(0,1,1)), f-vec3(0,1,1));
	float n111 = dot(hash3(i+vec3(1,1,1)), f-vec3(1,1,1));

	// trilinear + smoothstep
	float nx00 = mix(n000, n100, u.x);
	float nx10 = mix(n010, n110, u.x);
	float nx01 = mix(n001, n101, u.x);
	float nx11 = mix(n011, n111, u.x);
	float nxy0 = mix(nx00, nx10, u.y);
	float nxy1 = mix(nx01, nx11, u.y);
	return mix(nxy0, nxy1, u.z)*0.5 + 0.5; // remap to 0..1
}

float fbm(vec3 p){
	float amp = 0.5;
	float freq = 1.0;
	float v = 0.0;
	for (int i = 0; i < 4; i++){
		if (i >= octaves) break;
		v += noise3d(p*freq) * amp;
		freq *= lacunarity;
		amp *= gain;
	}
	return v;
}

void fog(){
	// --- World-anchored animated coordinates ---
	// Zooming out: gradually lower the frequency over time.
	float zoom_factor = max(0.001, exp(-zoom_speed * TIME)); // decays from 1 -> 0
	float scale = base_scale * zoom_factor;

	vec3 p = WORLD_POSITION * scale + scroll_dir * TIME;

	// Core density from FBM (keep octaves small for perf)
	float n = fbm(p);

	// Height fade (fade out as Y rises)
	float h = 1.0 - smoothstep(height_fade_start, height_fade_start + height_fade_range, WORLD_POSITION.y);

	// Spherical-ish edge fade using distance to volume center (OBJECT_POSITION)
	float dist = length(WORLD_POSITION - OBJECT_POSITION);
	float edge = 1.0 - smoothstep(edge_radius, edge_radius + max(0.001, edge_softness), dist);

	// Final density (clamped a bit to avoid banding)
	float d = clamp(n * base_density * h * edge, 0.0, 2.0);
	DENSITY = d;

	// Color: palette (if provided) * tint; otherwise just tint.
	vec3 pal = texture(palette, vec2(n, 0.0)).rgb;
	vec3 col = mix(albedo_tint, pal, 0.75); // blend in palette if not white
	ALBEDO = col;

	// Emission gives the fog a gentle glow so it’s visible even in shade.
	EMISSION = emission_tint * (emission_strength * d);
}
