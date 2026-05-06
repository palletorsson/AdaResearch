shader_type spatial;

void fragment() {
    vec2 st = UV;
	ALBEDO = vec3(st, 0.0);
	ALPHA = 1.0;
}
