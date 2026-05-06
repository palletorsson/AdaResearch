shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, diffuse_burley, specular_disabled;

uniform float time : hint_range(0.0, 1000.0) = 0.0;
uniform float scale : hint_range(1.0, 50.0) = 20.0;
uniform float animation_speed : hint_range(0.0, 5.0) = 1.0;
uniform bool animate = true;
uniform float intensity : hint_range(0.0, 2.0) = 1.0;

// --- pass world position manually ---
varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// --- utility functions ---
vec2 random2(vec2 p) {
	return fract(sin(vec2(dot(p, vec2(127.1, 311.7)),
	                      dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

vec3 voronoi(vec2 x, float rnd, float t) {
	vec2 n = floor(x);
	vec2 f = fract(x);
	vec2 mg, mr;
	float md = 8.0;

	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 g = vec2(float(i), float(j));
			vec2 o = random2(n + g) * rnd;
			if (animate) {
				o = 0.5 + 0.5 * sin(t + 6.2831 * o);
			}
			vec2 r = g + o - f;
			float d = dot(r, r);
			if (d < md) {
				md = d;
				mr = r;
				mg = g;
			}
		}
	}

	md = 8.0;
	for (int j = -2; j <= 2; j++) {
		for (int i = -2; i <= 2; i++) {
			vec2 g = mg + vec2(float(i), float(j));
			vec2 o = random2(n + g) * rnd;
			if (animate) {
				o = 0.5 + 0.5 * sin(t + 6.2831 * o);
			}
			vec2 r = g + o - f;
			if (dot(mr - r, mr - r) > 0.00001) {
				md = min(md, dot(0.5 * (mr + r), normalize(r - mr)));
			}
		}
	}
	return vec3(md, mr);
}

void fragment() {
	// Use world-space position to make pattern static relative to scene
	vec2 st = v_world_pos.xz * scale;

	float d = dot(st * 0.02, st * 0.02);
	float t = time * animation_speed;

	vec3 c = voronoi(st, pow(d, 0.4), t);

	vec3 color = vec3(0.0);
	color = mix(vec3(1.0), color, smoothstep(0.01, 0.02, c.x));
	float dd = length(c.yz);
	color += vec3(1.0) * (1.0 - smoothstep(0.0, 0.1, dd));

	ALBEDO = color * intensity;
}
