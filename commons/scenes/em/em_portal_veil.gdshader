shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec3 accent : source_color = vec3(1.0, 0.025, 0.34);
varying vec2 local_position;

void vertex() {
	local_position = vec2(VERTEX.x / 0.86, (VERTEX.y - 1.14) / 1.2);
}

void fragment() {
	vec2 p = local_position;
	float fold = sin(p.y * 5.0 + TIME * 0.45) * 0.08;
	float seam = exp(-abs(p.x + fold) * 28.0);
	float edge = pow(clamp(abs(p.x), 0.0, 1.0), 9.0);
	float silk = pow(0.5 + 0.5 * sin(p.x * 11.0 + p.y * 1.5 + TIME * 0.3), 6.0);
	vec3 dark = vec3(0.008, 0.003, 0.015);
	ALBEDO = dark + accent * (0.045 + silk * 0.12 + seam * 0.65 + edge * 0.85);
}
