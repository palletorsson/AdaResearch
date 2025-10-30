shader_type spatial;
uniform float zoom = 10.0;

vec2 tile(vec2 st, float z) {
    st *= z;
    return fract(st);
}

void fragment() {
    vec2 st = tile(UV, zoom);
	ALBEDO = vec3(st, 0.0);
	ALPHA = 1.0;
}
