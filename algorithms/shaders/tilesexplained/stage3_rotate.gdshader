shader_type spatial;
uniform float zoom = 3.0;
uniform float angle = 1.57;

vec2 tile(vec2 st, float z) {
    st *= z;
    return fract(st);
}

vec2 rotate2D(vec2 st, float a) {
    st -= 0.5;
    st = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * st;
    st += 0.5;
    return st;
}

void fragment() {
    vec2 st = tile(UV, zoom);      // First tile
    st = rotate2D(st, angle);      // Then rotate
    ALBEDO = vec3(st, 0.0);
    ALPHA = 1.0;
}
