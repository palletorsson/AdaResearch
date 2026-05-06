shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.12: Crackle pattern (F2 - F1)
// Difference between first and second nearest distances

uniform float scale : hint_range(2.0, 15.0) = 6.0;
uniform float speed : hint_range(0.0, 2.0) = 0.3;
uniform float sharpness : hint_range(0.5, 5.0) = 2.0;
uniform vec3 crack_color : source_color = vec3(0.0, 0.78, 0.85);
uniform vec3 bg_color : source_color = vec3(0.02, 0.02, 0.05);

vec2 random2(vec2 p) {
	return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV * scale;
	vec2 i_st = floor(uv);
	vec2 f_st = fract(uv);

	float f1 = 1e10; // nearest
	float f2 = 1e10; // second nearest

	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 neighbor = vec2(float(x), float(y));
			vec2 point = random2(i_st + neighbor);
			point = 0.5 + 0.5 * sin(TIME * speed + 6.2831 * point);
			float dist = length(neighbor + point - f_st);
			if (dist < f1) {
				f2 = f1;
				f1 = dist;
			} else if (dist < f2) {
				f2 = dist;
			}
		}
	}

	float crackle = f2 - f1;
	crackle = pow(crackle, sharpness);

	vec3 color = mix(bg_color, crack_color, crackle);

	ALBEDO = color;
}
