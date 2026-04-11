shader_type spatial;

// VR-safe biome ground shader — no SCREEN_TEXTURE, pure vertex/fragment math
// Colors the ground based on distance from grid center:
//   Near grid: warm brown earth
//   Mid ring: green grass
//   Outer ring: fades to dark (world edge)

uniform vec2 grid_size = vec2(10.0, 10.0);
uniform vec2 grid_center = vec2(5.0, 5.0);
uniform float ring_width = 8.0;
uniform float fade_width = 4.0;
uniform float density = 0.5;

// Color palette
uniform vec4 earth_color : source_color = vec4(0.25, 0.18, 0.12, 1.0);
uniform vec4 grass_color : source_color = vec4(0.15, 0.32, 0.08, 1.0);
uniform vec4 edge_color : source_color = vec4(0.05, 0.05, 0.05, 1.0);

varying float v_edge_dist;
varying float v_ring_t;

void vertex() {
	// Calculate distance from grid edge in world XZ
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float dx = max(abs(world_pos.x - grid_center.x) - grid_size.x * 0.5, 0.0);
	float dz = max(abs(world_pos.z - grid_center.y) - grid_size.y * 0.5, 0.0);
	v_edge_dist = max(dx, dz);
	v_ring_t = clamp(v_edge_dist / (ring_width + fade_width), 0.0, 1.0);

	// Slight height variation from noise
	float noise = sin(world_pos.x * 1.3) * cos(world_pos.z * 1.7) * 0.05 * density;
	VERTEX.y += noise;
}

void fragment() {
	// Three-zone color blend:
	// 0.0-0.3: earth (near grid)
	// 0.3-0.7: grass (mid ring)
	// 0.7-1.0: fade to edge
	float t = v_ring_t;

	vec3 color;
	if (t < 0.3) {
		float lt = t / 0.3;
		color = mix(earth_color.rgb, grass_color.rgb, lt * density);
	} else if (t < 0.7) {
		float lt = (t - 0.3) / 0.4;
		color = mix(grass_color.rgb, grass_color.rgb * 0.7, lt) * density + earth_color.rgb * (1.0 - density);
	} else {
		float lt = (t - 0.7) / 0.3;
		vec3 mid = mix(grass_color.rgb, earth_color.rgb, 0.5) * density + earth_color.rgb * (1.0 - density);
		color = mix(mid, edge_color.rgb, lt * lt);
	}

	// Subtle noise pattern
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float pattern = fract(sin(dot(world_pos.xz, vec2(12.9898, 78.233))) * 43758.5453);
	color += (pattern - 0.5) * 0.03;

	ALBEDO = color;
	ROUGHNESS = 0.9;
	ALPHA = t > 0.85 ? 1.0 - (t - 0.85) / 0.15 : 1.0;
}
