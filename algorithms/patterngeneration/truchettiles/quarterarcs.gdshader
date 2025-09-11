shader_type spatial;
render_mode unshaded ;

uniform float zoom : hint_range(1.0, 20.0) = 3.0;           // like tile(st, 3.0)
uniform bool  animate = false;                               // enable TIME rotation like the original comments
uniform float spin_speed = 0.25;                             // PI * TIME * spin_speed
uniform vec4  color_a : source_color = vec4(0.0,0.0,0.0,1.0);
uniform vec4  color_b : source_color = vec4(1.0,1.0,1.0,1.0);
 

mat2 rot(float a){
    // column-major constructor in Godot
    return mat2(
        vec2(cos(a), sin(a)),
        vec2(-sin(a), cos(a))
    );
}

vec2 rotate2D(vec2 st, float angle){
    st -= 0.5;
    st = rot(angle) * st;
    st += 0.5;
    return st;
}

vec2 tile(vec2 st, float z){
    st *= z;
    return fract(st);
}

vec2 rotateTilePattern(vec2 st){
    // scale to 2x2
    st *= 2.0;

    // index per cell (0..3)
    float index = 0.0;
    index += step(1.0, mod(st.x, 2.0));
    index += step(1.0, mod(st.y, 2.0)) * 2.0;

    // localize to 0..1
    st = fract(st);

    // rotate per index
    if (index == 1.0){
        st = rotate2D(st, PI * 0.5);
    } else if (index == 2.0){
        st = rotate2D(st, PI * -0.5);
    } else if (index == 3.0){
        st = rotate2D(st, PI);
    }

    return st;
}

void fragment(){
    vec2 st = UV;

    // optional global rotation like the Book of Shaders comment
    if (animate){
        st = rotate2D(st, -PI * TIME * spin_speed);
    }

    st = tile(st, zoom);
    st = rotateTilePattern(st);

    // same output idea: vec3(step(st.x, st.y))
    float m = step(st.x, st.y);

    ALBEDO = mix(color_a.rgb, color_b.rgb, m);
    ALPHA  = mix(color_a.a,  color_b.a,  m);
}
