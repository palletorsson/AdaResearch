shader_type spatial;
render_mode unshaded;

uniform float zoom : hint_range(1.0, 20.0) = 5.0;
uniform vec4 color_a : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 color_b : source_color = vec4(1.0, 1.0, 1.0, 1.0);

vec2 mirrorTile(vec2 st, float z){
    st *= z;
    if (fract(st.y * 0.5) > 0.5){
        st.x = st.x + 0.5;
        st.y = 1.0 - st.y;
    }
    return fract(st);
}

float fillY(vec2 st, float pct, float antia){
    return smoothstep(pct - antia, pct, st.y);
}

void fragment(){
    vec2 st = UV;

    // Match original scaling (y doubled before tiling)
    st = mirrorTile(st * vec2(1.0, 2.0), zoom);

    float x = st.x * 2.0;
    float a = floor(1.0 + sin(x * 3.14159));
    float b = floor(1.0 + sin((x + 1.0) * 3.14159));
    float f = fract(x);

    float m = fillY(st, mix(a, b, f), 0.01);

    vec3 col = mix(color_a.rgb, color_b.rgb, m);
    ALBEDO = col;
    ALPHA = 1.0;
}
