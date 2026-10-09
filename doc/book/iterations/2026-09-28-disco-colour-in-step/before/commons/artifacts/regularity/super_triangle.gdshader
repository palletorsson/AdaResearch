shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec2 tile_count = vec2(12.0);
uniform float tile_size = 0.8;
uniform float gap_fraction = 0.0125;
uniform float motion = 0.0;
uniform vec4 ink : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 paper : source_color = vec4(1.0);
uniform sampler2D column_pulses : filter_nearest, repeat_disable;
varying vec2 grid_position;
const float QUARTER_TURN = 1.57079632679;
const float FULL_TURN = 6.28318530718;

float grouping(int family) {
	if (family == 4) { return 2.0; }
	if (family == 5) { return 3.0; }
	return 1.0;
}

float angle_for(int pose, vec2 grid) {
	int family = (pose / 4) % 6;
	vec2 cell = floor(grid / grouping(family));
	vec2 parity = mod(cell, 2.0);
	float quarter = 0.0;
	if (family == 1) {
		quarter = parity.x;
	} else if (family == 2 || family >= 4) {
		// Four half-square motifs face the common centre of a 2 by 2 block.
		quarter = mix(mix(0.0, 1.0, parity.x), mix(3.0, 2.0, parity.x), parity.y);
	} else if (family == 3) {
		quarter = mod(cell.x + cell.y, 4.0);
	}
	return (quarter + float(pose % 4) + 0.5) * QUARTER_TURN;
}

void vertex() {
	grid_position = VERTEX.xz / tile_size + tile_count * 0.5;
}

void fragment() {
	// The receiving square tiles and their joints stay in the same places.
	vec2 within_tile = fract(grid_position);
	if (min(min(within_tile.x, within_tile.y), min(1.0-within_tile.x, 1.0-within_tile.y)) < gap_fraction) {
		discard;
	}
	float clock = mod(motion, 24.0);
	int from_pose = int(floor(clock));
	int to_pose = (from_pose + 1) % 24;
	float blend = smoothstep(0.15, 0.9, fract(clock));
	float group_size = mix(grouping(from_pose / 4), grouping(to_pose / 4), blend);
	vec2 local = fract(grid_position / group_size) - 0.5;
	float a = angle_for(from_pose, grid_position);
	float b = angle_for(to_pose, grid_position);
	float turn = mod(b-a+FULL_TURN*0.5, FULL_TURN)-FULL_TURN*0.5;
	float angle = a + turn * blend;
	float divider = dot(local, vec2(cos(angle), sin(angle)));
	float edge = max(fwidth(divider) * 0.75, 0.0001);
	float white = smoothstep(-edge, edge, divider);
	vec3 colour = mix(ink.rgb, paper.rgb, white);
	float pulse = texture(column_pulses, vec2((floor(grid_position.x)+0.5)/tile_count.x, 0.5)).r;
	ALBEDO = mix(colour, vec3(1.0), pulse * 0.4);
}
