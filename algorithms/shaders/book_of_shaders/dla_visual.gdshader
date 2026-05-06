shader_type spatial;
render_mode unshaded;

// DLA (Diffusion Limited Aggregation) visualization shader
// Simulates the visual appearance of DLA growth using noise

uniform float scale : hint_range(1.0, 8.0) = 3.0;
uniform float growth : hint_range(0.0, 2.0) = 1.0;
uniform float branch_density : hint_range(0.3, 0.9) = 0.55;
uniform float speed : hint_range(0.0, 0.5) = 0.1;
uniform vec3 crystal_color : source_color = vec3(0.0, 0.78, 0.85);
uniform vec3 bg_color : source_color = vec3(0.02, 0.02, 0.05);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			   mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 6; i++) {
		v += a * noise(p);
		p *= 2.0;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;

	// Radial distance from center (seed point)
	float dist = length(uv);

	// Create branch-like structures using angular noise
	float angle = atan(uv.y, uv.x);
	float angular_noise = fbm(vec2(angle * 3.0, dist * scale));
	float radial_noise = fbm(uv * scale + TIME * speed);

	// DLA-like threshold: branches extend from center
	float growth_radius = growth * (0.5 + 0.5 * angular_noise);
	float branch = smoothstep(growth_radius + 0.1, growth_radius - 0.05, dist + radial_noise * 0.3);

	// Fine detail: crystalline edges
	float detail = fbm(uv * scale * 4.0);
	float crystal = smoothstep(branch_density - 0.1, branch_density + 0.1, detail) * branch;

	// Glow around the structure
	float glow = smoothstep(growth_radius + 0.3, growth_radius, dist) * 0.2;

	vec3 color = bg_color;
	color += crystal_color * glow;
	color = mix(color, crystal_color, crystal);
	// Bright tips
	color += vec3(0.5) * smoothstep(0.8, 1.0, crystal) * branch;

	ALBEDO = color;
}
