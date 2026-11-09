shader_type spatial;
// A mirrorball (2026-11-09) - disco_lights' own surface. Its first shader (commons/resourses/shaders/discoLights,
// still used by the softbodies joy ride) replaced the lighting with one pulsing colour: a flat disc in disco colours.
// A mirrorball is many small flat mirrors on a sphere. Each tile here is flat (its normal is the tile's centre
// direction, so it reflects the room in one piece), set in dark grout, and the ball turns; now and then a tile
// catches the light and flashes a disco colour. Same three uniforms as before, same meaning.

uniform float time_speed : hint_range(0.1, 5.0) = 5.0;      // how fast the colours run and the tiles flash
uniform vec3 base_color = vec3(0.5, 0.5, 0.5);              // tint of the flashes
uniform float intensity_factor : hint_range(0.1, 2.0) = 1.0; // brightness of the flashes
uniform int lon_tiles = 40;                                  // tiles round the equator
uniform int lat_tiles = 20;                                  // tiles pole to pole
uniform float grout = 0.08;                                  // grout width, in tile widths
uniform float spin = 0.35;                                   // radians a second

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec3 disco_color(float time) {
	return vec3(0.5 + 0.5 * sin(time * 3.0), 0.5 + 0.5 * sin(time * 2.0 + 1.0), 0.5 + 0.5 * sin(time * 4.0 + 2.0));
}

mat3 turn(float a) {
	return mat3(vec3(cos(a), 0.0, -sin(a)), vec3(0.0, 1.0, 0.0), vec3(sin(a), 0.0, cos(a)));
}

void vertex() {
	mat3 r = turn(TIME * spin);
	VERTEX = r * VERTEX;
	NORMAL = r * NORMAL;
}

void fragment() {
	vec2 grid = vec2(float(lon_tiles), float(lat_tiles));
	vec2 cell = floor(UV * grid);
	vec2 f = fract(UV * grid);
	float tile = step(grout, f.x) * step(grout, f.y) * step(f.x, 1.0 - grout) * step(f.y, 1.0 - grout);
	float h = hash(cell);

	// The tile's centre direction, as SphereMesh lays its UVs (u round the Y axis from +Z, v from the top pole).
	float th = (cell.y + 0.5) / grid.y * PI;
	float ph = (cell.x + 0.5) / grid.x * TAU;
	vec3 d = turn(TIME * spin) * vec3(sin(ph) * sin(th), cos(th), cos(ph) * sin(th));
	vec3 flat_normal = normalize((VIEW_MATRIX * MODEL_MATRIX * vec4(d, 0.0)).xyz);

	float t = TIME * time_speed;
	float flash = pow(max(0.0, sin(t * 0.9 + h * 97.0)), 90.0);
	vec3 glint = disco_color(t * 0.3 + h * TAU) * base_color * 2.0;

	NORMAL = mix(NORMAL, flat_normal, tile);
	ALBEDO = mix(vec3(0.06), vec3(0.78 + 0.12 * h), tile);
	METALLIC = tile;
	ROUGHNESS = mix(0.9, 0.08 + 0.12 * h, tile);
	EMISSION = tile * glint * (0.015 + 4.0 * intensity_factor * flash);
}
