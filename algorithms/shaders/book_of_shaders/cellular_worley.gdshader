shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.12: Worley noise
// Distance to nearest feature point — organic cellular look

uniform float scale : hint_range(2.0, 15.0) = 6.0;
uniform float speed : hint_range(0.0, 2.0) = 0.3;
uniform float invert : hint_range(0.0, 1.0) = 0.0;
uniform vec3 color_near : source_color = vec3(0.05, 0.05, 0.1);
uniform vec3 color_far : source_color = vec3(0.0, 0.78, 0.85);

vec2 random2(vec2 p) {
	return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV * scale;
	vec2 i_st = floor(uv);
	vec2 f_st = fract(uv);

	float min_dist = 1e10;

	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 neighbor = vec2(float(x), float(y));
			vec2 point = random2(i_st + neighbor);
			point = 0.5 + 0.5 * sin(TIME * speed + 6.2831 * point);
			float dist = length(neighbor + point - f_st);
			min_dist = min(min_dist, dist);
		}
	}

	float d = min_dist;
	if (invert > 0.5) {
		d = 1.0 - d;
	}

	vec3 color = mix(color_near, color_far, d);

	ALBEDO = color;
}
