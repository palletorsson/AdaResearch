shader_type spatial;
render_mode unshaded;

uniform float zoom : hint_range(1.0, 20.0) = 5.0;
uniform float radius : hint_range(0.0, 1.0) = 0.2;
uniform vec4 color_a : source_color = vec4(0.0,0.0,0.0,1.0);
uniform vec4 color_b : source_color = vec4(1.0,1.0,1.0,1.0);

vec2 tile(vec2 st, float z){
    st *= z;
    return fract(st);
}

float circle(vec2 st, float r){
    vec2 pos = vec2(0.5) - st;
    r *= 0.75;
    return 1.0 - smoothstep(
        r - (r * 0.05),
        r + (r * 0.05),
        dot(pos, pos) * 3.14159
    );
}

void fragment(){
    vec2 st = UV;

    // Aspect correction using viewport size
    st.x *= VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;

    // Tile pattern
    st = tile(st, zoom);

    float c = circle(st, radius);
    vec3 col = mix(color_a.rgb, color_b.rgb, c);

    ALBEDO = col;
    ALPHA  = 1.0;
}
