shader_type spatial;
#define PI 3.14159265358979323846

uniform float zoom = 3.0;

vec2 tile(vec2 st, float z) {
    st *= z;
    return fract(st);
}

vec2 rotate2D(vec2 st, float a){
    st -= 0.5;
    st = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * st;
    st += 0.5;
    return st;
}

vec2 rotateTilePattern(vec2 st){
    st *= 2.0;
    float index = 0.0;
    index += step(1., mod(st.x, 2.0));
    index += step(1., mod(st.y, 2.0)) * 2.0;
    st = fract(st);
    if (index == 1.0) st = rotate2D(st, PI*0.5);
    else if (index == 2.0) st = rotate2D(st, PI*-0.5);
    else if (index == 3.0) st = rotate2D(st, PI);
    return st;
}

void fragment(){
    vec2 st = tile(UV, zoom);           // First tile
    st = rotateTilePattern(st);         // Then rotate pattern
    ALBEDO = vec3(st, 0.0);
    ALPHA = 1.0;
}
