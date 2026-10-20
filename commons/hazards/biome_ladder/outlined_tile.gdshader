shader_type spatial;

// A white face with a thin black border that travels with the actual tile.
void fragment() {
	vec2 edge = min(UV, vec2(1.0) - UV);
	vec2 pixel = max(fwidth(UV), vec2(0.0001));
	vec2 ink = vec2(1.0) - smoothstep(vec2(0.005) - pixel * 0.5,
		vec2(0.005) + pixel * 0.5, edge);
	ALBEDO = vec3(1.0 - max(ink.x, ink.y));
	ROUGHNESS = 0.9;
}
