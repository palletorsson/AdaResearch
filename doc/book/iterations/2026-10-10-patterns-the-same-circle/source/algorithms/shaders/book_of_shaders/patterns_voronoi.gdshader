shader_type spatial;
render_mode unshaded;

// Voronoi-based texture generation
// Shows cell boundaries, distance fields, and procedural textures

uniform float grid_size : hint_range(2.0, 16.0) = 6.0;
uniform float jitter : hint_range(0.0, 1.0) = 0.85;
uniform float display_mode : hint_range(0.0, 3.0) = 0.0;
uniform float seed : hint_range(0.0, 100.0) = 13.0;

vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1 + seed, 311.7)),
	          dot(p, vec2(269.5, 183.3 + seed)));
	return fract(sin(p) * 43758.5453);
}

// Returns (min_dist, second_dist, cell_id_hash)
vec3 voronoi(vec2 uv) {
	vec2 cell = floor(uv);
	vec2 frac_uv = fract(uv);

	float min_d = 8.0;
	float second_d = 8.0;
	vec2 closest_cell = vec2(0.0);

	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 neighbor = vec2(float(x), float(y));
			vec2 point = hash2(cell + neighbor) * jitter;
			// Animate slightly
			point = 0.5 + 0.5 * sin(TIME * 0.3 + 6.2831 * point);
			point = mix(hash2(cell + neighbor) * jitter, point, 0.3);

			vec2 diff = neighbor + point - frac_uv;
			float d = length(diff);

			if (d < min_d) {
				second_d = min_d;
				min_d = d;
				closest_cell = cell + neighbor;
			} else if (d < second_d) {
				second_d = d;
			}
		}
	}

	float cell_hash = fract(sin(dot(closest_cell, vec2(12.9898, 78.233))) * 43758.5453);
	return vec3(min_d, second_d, cell_hash);
}

void fragment() {
	vec2 uv = UV * grid_size;
	vec3 vor = voronoi(uv);

	float min_d = vor.x;
	float second_d = vor.y;
	float cell_id = vor.z;

	int mode = int(round(display_mode));
	vec3 color;

	if (mode == 0) {
		// Cell coloring — each cell gets a unique hue
		float hue = cell_id;
		float sat = 0.6 + 0.3 * sin(cell_id * 6.28);
		// HSV to RGB
		vec3 k = vec3(1.0, 2.0/3.0, 1.0/3.0);
		vec3 p = abs(fract(vec3(hue) + k) * 6.0 - 3.0);
		color = mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), sat) * 0.8;
		// Edge darkening
		float edge = smoothstep(0.0, 0.08, second_d - min_d);
		color *= 0.3 + 0.7 * edge;
	} else if (mode == 1) {
		// Distance field — grayscale radial gradient
		color = vec3(min_d * 1.5);
		// Add cell edge highlight
		float edge = 1.0 - smoothstep(0.0, 0.05, second_d - min_d);
		color = mix(color, vec3(0.0, 0.8, 1.0), edge);
	} else if (mode == 2) {
		// Crackle / edge pattern
		float edge_d = second_d - min_d;
		float crack = 1.0 - smoothstep(0.0, 0.06, edge_d);
		float glow = exp(-edge_d * 15.0);
		color = vec3(0.05) + vec3(0.9, 0.6, 0.2) * crack + vec3(0.3, 0.6, 1.0) * glow * 0.5;
	} else {
		// Bubble / organic — radial gradient per cell with rim lighting
		float center_fade = smoothstep(0.0, 0.5, min_d);
		float rim = smoothstep(0.02, 0.0, second_d - min_d);
		vec3 cell_col = 0.5 + 0.5 * cos(6.28 * cell_id + vec3(0.0, 2.0, 4.0));
		color = cell_col * (1.0 - center_fade * 0.6);
		color += vec3(0.8) * rim * 0.4;
		color *= 0.8;
	}

	ALBEDO = color;
}
