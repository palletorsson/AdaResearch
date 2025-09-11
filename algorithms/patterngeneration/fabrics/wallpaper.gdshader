shader_type spatial;

// Author @kyndinfo - 2016 (Converted to Godot 4 Spatial)
// http://www.kynd.info
// Title: Textile - Spatial Version

uniform float time_scale : hint_range(0.0, 2.0) = 1.0;
uniform float pattern_scale : hint_range(1.0, 20.0) = 5.0;
uniform float turbulence_strength : hint_range(0.0, 1.0) = 0.5;
uniform float turbulence_offset : hint_range(0.0, 1.0) = 0.2;
uniform vec3 base_color : source_color = vec3(0.445, 0.920, 0.457);
uniform vec3 mid_color : source_color = vec3(0.915, 0.537, 0.413);
uniform vec3 dark_color : source_color = vec3(0.490, 0.038, 0.060);
uniform float roughness : hint_range(0.0, 1.0) = 0.8;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float emission_strength : hint_range(0.0, 2.0) = 0.1;
uniform bool animate  = true;

vec3 mod289(vec3 x) { 
    return x - floor(x * (1.0 / 289.0)) * 289.0; 
}

vec2 mod289(vec2 x) { 
    return x - floor(x * (1.0 / 289.0)) * 289.0; 
}

vec3 permute(vec3 x) { 
    return mod289(((x * 34.0) + 1.0) * x); 
}

float snoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187,
                        0.366025403784439,
                        -0.577350269189626,
                        0.024390243902439);
    vec2 i  = floor(v + dot(v, C.yy));
    vec2 x0 = v - i + dot(i, C.xx);
    vec2 i1;
    i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod289(i);
    vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0))
        + i.x + vec3(0.0, i1.x, 1.0));
    vec3 m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.0);
    m = m * m;
    m = m * m;
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);
    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

const int OCTAVES = 6;

float turbulence(in vec2 st) {
    float value = 0.0;
    float amplitude = 1.0;
    for (int i = 0; i < OCTAVES; i++) {
        value += amplitude * abs(snoise(st));
        st *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

void fragment() {
    vec2 st = UV;
    st = fract(st * pattern_scale);
    
    // Create textile-like pattern with mirroring
    st.x = (st.x > 0.5) ? st.x : 1.0 - st.x;
    st.y = (st.y > 0.5) ? st.y : 1.0 - st.y;
    
    // Add turbulence for organic textile feel
    float time_offset = animate ? TIME * time_scale : 0.0;
    st.x += turbulence(st + time_offset) * turbulence_strength;
    st.y += turbulence(st + vec2(1.0) + time_offset) * turbulence_offset;
    
    // Create layered color mixing for textile appearance
    vec3 color = base_color;
    color = mix(color, mid_color, turbulence(st * 6.0));
    color = mix(color, dark_color, turbulence(st * 1.0));
    
    ALBEDO = color;
    ROUGHNESS = roughness;
    METALLIC = metallic;
    EMISSION = color * emission_strength;
}