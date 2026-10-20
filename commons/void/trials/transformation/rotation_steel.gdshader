shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.31, 0.38, 0.42, 1.0);
uniform float metallic : hint_range(0.0, 1.0) = 0.7;
uniform float roughness : hint_range(0.0, 1.0) = 0.48;
uniform float half_width = 0.5;
varying vec3 object_position;
varying vec3 object_normal;

void vertex() {
	object_position = VERTEX;
	object_normal = NORMAL;
}

float stripe(float coordinate, float width) {
	float distance = abs(fract(coordinate + 0.5) - 0.5);
	float aa = max(fwidth(coordinate), 0.001);
	return 1.0 - smoothstep(width, width + aa, distance);
}

void fragment() {
	vec3 p = object_position;
	float top = step(0.8, object_normal.y);
	// Metre-long deck plates; the small tread follows the steel, not the world.
	float joint = stripe(p.x, 0.012);
	float tread = stripe(p.x * 11.0 + abs(p.z) * 13.0, 0.07);
	float grain = sin(p.x * 83.0 + p.z * 23.0) * 0.018;
	vec3 steel = base_color.rgb * (1.0 + grain + top * tread * 0.13);
	steel = mix(steel, base_color.rgb * 0.43, joint * 0.7);
	float edge = top * smoothstep(half_width - 0.045, half_width - 0.025, abs(p.z));
	vec3 paint = vec3(0.86, 0.61, 0.16);
	ALBEDO = mix(steel, paint, edge);
	METALLIC = mix(metallic, 0.08, edge);
	ROUGHNESS = mix(roughness + tread * 0.08, 0.76, edge);
}
