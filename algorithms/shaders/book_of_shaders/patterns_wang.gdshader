shader_type spatial;
render_mode unshaded;

// Wang tiles — aperiodic tiling with edge-matched colored tiles
// Each tile edge gets a color from hash; matching edges create seamless patterns

uniform float grid_size : hint_range(2.0, 24.0) = 10.0;
uniform float edge_width : hint_range(0.02, 0.25) = 0.12;
uniform float seed : hint_range(0.0, 100.0) = 7.0;
uniform float aperiodic_mix : hint_range(0.0, 1.0) = 1.0;

// Edge colors — 4 possible edge types
const vec3 EDGE_COLORS[4] = {
	vec3(0.85, 0.25, 0.2),   // red
	vec3(0.2, 0.75, 0.9),    // cyan
	vec3(0.9, 0.75, 0.15),   // gold
	vec3(0.3, 0.85, 0.35)    // green
};

float hash(vec2 p) {
	return fract(sin(dot(p + vec2(seed), vec2(127.1, 311.7))) * 43758.5453);
}

int edge_type(vec2 tile_id, int edge) {
	// Deterministic edge assignment per tile-edge pair
	// edge: 0=north, 1=east, 2=south, 3=west
	float h = hash(tile_id * 3.17 + float(edge) * 7.31 + vec2(seed * 0.37));
	return int(h * 4.0) % 4;
}

vec3 wang_color(vec2 tile_id, vec2 tile_uv) {
	// Determine which edge zone we're in
	float north = 1.0 - tile_uv.y;  // distance from north edge
	float south = tile_uv.y;
	float east = 1.0 - tile_uv.x;
	float west = tile_uv.x;

	float min_dist = min(min(north, south), min(east, west));

	if (min_dist > edge_width) {
		// Interior — blend of all edge colors
		vec3 interior = vec3(0.0);
		for (int i = 0; i < 4; i++) {
			interior += EDGE_COLORS[edge_type(tile_id, i)] * 0.25;
		}
		return interior * 0.4;
	}

	// Which edge are we closest to?
	int closest_edge;
	if (min_dist == north) closest_edge = 0;
	else if (min_dist == east) closest_edge = 1;
	else if (min_dist == south) closest_edge = 2;
	else closest_edge = 3;

	int etype = edge_type(tile_id, closest_edge);

	// Ensure matching: neighbor's opposite edge should match
	// This creates the Wang tile constraint visually
	vec2 neighbor;
	int opposite;
	if (closest_edge == 0) { neighbor = tile_id + vec2(0, 1); opposite = 2; }
	else if (closest_edge == 1) { neighbor = tile_id + vec2(1, 0); opposite = 3; }
	else if (closest_edge == 2) { neighbor = tile_id + vec2(0, -1); opposite = 0; }
	else { neighbor = tile_id + vec2(-1, 0); opposite = 1; }

	// Blend between independent and matched edges
	int matched_type = edge_type(neighbor, opposite);
	vec3 own_col = EDGE_COLORS[etype];
	vec3 matched_col = EDGE_COLORS[matched_type];
	vec3 edge_col = mix(own_col, matched_col, aperiodic_mix * 0.5);

	// Fade toward interior
	float fade = smoothstep(0.0, edge_width, min_dist);
	return edge_col * (1.0 - fade * 0.6);
}

void fragment() {
	vec2 uv = UV * grid_size;
	vec2 tile_id = floor(uv);
	vec2 tile_uv = fract(uv);

	// Tile border
	vec2 edge = abs(tile_uv - 0.5);
	float border = smoothstep(0.48, 0.5, max(edge.x, edge.y));

	vec3 color = wang_color(tile_id, tile_uv);

	// Diamond marker in center for tile identity
	float diamond = abs(tile_uv.x - 0.5) + abs(tile_uv.y - 0.5);
	float center_dot = 1.0 - smoothstep(0.03, 0.05, diamond);
	color += vec3(0.3) * center_dot;

	color = mix(color, vec3(0.15), border * 0.5);

	ALBEDO = color;
}
