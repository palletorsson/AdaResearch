shader_type spatial;

uniform vec3 metaball_pos_1;
uniform vec3 metaball_pos_2;
uniform vec3 metaball_pos_3;
uniform float metaball_radius_1 = 0.5;
uniform float metaball_radius_2 = 0.4;
uniform float metaball_radius_3 = 0.3;
uniform float smoothness = 0.1;
uniform vec3 color : source_color = vec3(0.2, 0.6, 1.0);

float sdf_sphere(vec3 p, vec3 center, float radius) {
	return length(p - center) - radius;
}

float sdf_metaballs(vec3 p) {
	float d1 = sdf_sphere(p, metaball_pos_1, metaball_radius_1);
	float d2 = sdf_sphere(p, metaball_pos_2, metaball_radius_2);
	float d3 = sdf_sphere(p, metaball_pos_3, metaball_radius_3);
	
	// Smooth minimum blend
	float k = smoothness;
	float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
	float blend = mix(d2, d1, h) - k * h * (1.0 - h);
	
	h = clamp(0.5 + 0.5 * (d3 - blend) / k, 0.0, 1.0);
	return mix(d3, blend, h) - k * h * (1.0 - h);
}

void fragment() {
	// Simple lighting
	vec3 normal = NORMAL;
	float ndotl = max(dot(normal, normalize(vec3(0.5, 0.6, 0.2))), 0.0);
	ALBEDO = color * (ndotl + 0.3);
	METALLIC = 0.8;
	ROUGHNESS = 0.1;
	SPECULAR = 0.5;
}

void vertex() {
	// Perturb vertices slightly based on SDF
	float field = sdf_metaballs(VERTEX);
	if (field < 0.0) {
		// Push vertices slightly outward along normal
		VERTEX += NORMAL * field * 0.2;
	}
}