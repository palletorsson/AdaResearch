shader_type spatial;
render_mode cull_disabled;

uniform vec4 skin_color : source_color = vec4(0.73, 0.38, 0.48, 1.0);
uniform vec4 edge_color : source_color = vec4(1.0, 0.82, 0.63, 1.0);
uniform float pattern_scale = 0.68;
varying vec3 local_point;

vec3 feature(vec3 p) {
	return fract(sin(vec3(dot(p, vec3(127.1,311.7,74.7)),
		dot(p, vec3(269.5,183.3,246.1)), dot(p, vec3(113.5,271.9,124.6)))) * 43758.5453);
}

void vertex() {
	local_point = VERTEX;
}

void fragment() {
	vec3 p = local_point * pattern_scale;
	vec3 cell = floor(p);
	vec3 within = fract(p);
	float f1 = 20.0;
	float f2 = 20.0;
	// Chapter 12's neighbouring-cell search, extended through the third axis.
	for (int z = -1; z <= 1; z++) {
		for (int y = -1; y <= 1; y++) {
			for (int x = -1; x <= 1; x++) {
				vec3 neighbour = vec3(float(x), float(y), float(z));
				vec3 delta = neighbour + feature(cell + neighbour) - within;
				float d = dot(delta, delta);
				f2 = max(f1, min(f2, d));
				f1 = min(f1, d);
			}
		}
	}
	float edge = 1.0 - smoothstep(0.012, 0.055, sqrt(f2) - sqrt(f1));
	float mottling = smoothstep(0.05, 0.9, sqrt(f1));
	ALBEDO = mix(skin_color.rgb * (0.72 + 0.28 * mottling), edge_color.rgb, edge * 0.24);
	ROUGHNESS = 0.56 + mottling * 0.18;
	EMISSION = edge_color.rgb * edge * 0.045;
	NORMAL = FRONT_FACING ? NORMAL : -NORMAL;
}
