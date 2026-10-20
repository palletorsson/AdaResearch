shader_type spatial;
render_mode cull_disabled;

uniform vec4 ground : source_color = vec4(0.06, 0.012, 0.07, 1.0);
uniform vec4 ink : source_color = vec4(1.0, 0.05, 0.42, 1.0);
uniform vec4 edge_colour : source_color = vec4(0.18, 0.84, 0.80, 1.0);
uniform float density = 1.6;
uniform float dots : hint_range(0, 1) = 1.0;
uniform float rim_amount : hint_range(0, 1.5) = 1.0;
uniform float glow : hint_range(0, 0.8) = 0.35;
uniform float roughness = 0.18;
uniform mat4 room_inverse;
varying vec3 room_position;
varying vec3 room_normal;

void vertex() {
	// Supplied metre-scale projection adapter from the Patterns passage.
	// The sofa source has no UVs. This adapter also works on sphere and cube.
	room_position = (room_inverse * MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	room_normal = normalize(mat3(room_inverse) * MODEL_NORMAL_MATRIX * NORMAL);
}
float circle_at(vec2 p) {
	vec2 cell = fract(p * density);
	return 1.0 - step(0.30, distance(cell, vec2(0.5)));
}
void fragment() {
	vec3 n = normalize(room_normal);
	vec3 weights = pow(abs(n), vec3(12.0));
	weights /= max(weights.x + weights.y + weights.z, 0.001);
	float mask = circle_at(room_position.zy) * weights.x
		+ circle_at(room_position.xz) * weights.y
		+ circle_at(room_position.xy) * weights.z;
	vec3 colour = mix(ground.rgb, ink.rgb, mask * dots);
	float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float edge = pow(1.0 - facing, 3.0);
	ALBEDO = colour;
	ROUGHNESS = roughness;
	SPECULAR = 0.6;
	EMISSION = colour * glow + edge_colour.rgb * edge * rim_amount;
}
