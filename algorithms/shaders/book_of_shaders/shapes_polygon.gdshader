shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.7: Regular polygon via SDF
// Adjustable number of sides from triangle to circle

uniform float sides : hint_range(3.0, 12.0) = 6.0;
uniform float size : hint_range(0.1, 0.8) = 0.4;
uniform float rotation_speed : hint_range(0.0, 2.0) = 0.3;
uniform vec3 shape_color : source_color = vec3(0.0, 0.78, 0.85);
uniform vec3 bg_color : source_color = vec3(0.05, 0.05, 0.1);

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;

	// Rotate
	float a = TIME * rotation_speed;
	float cs = cos(a);
	float sn = sin(a);
	uv = vec2(uv.x * cs - uv.y * sn, uv.x * sn + uv.y * cs);

	// Polygon SDF using angular repetition
	float n = floor(sides);
	float angle = atan(uv.y, uv.x);
	float slice = 6.28318 / n;

	// Distance to edge of polygon
	float sector_angle = mod(angle + slice * 0.5, slice) - slice * 0.5;
	float r = length(uv);
	float dist = r * cos(sector_angle) - size;

	float shape = 1.0 - smoothstep(-0.005, 0.005, dist);

	// Distance rings
	float rings = 0.5 + 0.5 * cos(dist * 30.0);
	vec3 ring_color = vec3(0.1, 0.15, 0.2) * rings * 0.4;

	vec3 color = mix(bg_color + ring_color, shape_color, shape);

	ALBEDO = color;
}
