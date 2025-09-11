shader_type spatial;

// Author @kyndinfo - 2016 (Converted to Godot 4 Spatial)
// http://www.kynd.info
// Title: Normal map - Spatial Version

uniform float time_scale : hint_range(0.0, 2.0) = 0.0;
uniform float noise_scale : hint_range(0.1, 10.0) = 1.0;
uniform float height_scale : hint_range(0.1, 5.0) = 1.0;
uniform float detail_offset : hint_range(0.0001, 0.01) = 0.001;
uniform int octaves : hint_range(1, 8) = 7;
uniform float displacement_strength : hint_range(0.0, 1.0) = 0.1;
uniform vec3 base_color : source_color = vec3(0.8, 0.8, 0.8);
uniform float roughness : hint_range(0.0, 1.0) = 0.5;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform bool animate  = false;
uniform bool use_vertex_displacement   = true;

vec3 mod289(vec3 x) { 
    return x - floor(x * (1.0 / 289.0)) * 289.0; 
}

vec2 mod289(vec2 x) { 
    return x - floor(x * (1.0 / 289.0)) * 289.0; 
}

vec3 permute(vec3 x) { 
    return mod289(((x * 34.0) + 1.0) * x); 
}

float random(in vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
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

float level(vec2 st) {
    float n = 0.0;
    float time_offset = animate ? TIME * time_scale : 0.0;
    
    for (int i = 1; i < octaves + 1; i++) {
        float m = pow(2.0, float(i));
        n += snoise((st + time_offset) * m * noise_scale) * (1.0 / m);
    }
    return n * 0.5 + 0.5;
}

vec3 normal_from_height(vec2 st) {
    float d = detail_offset;
    float l0 = level(st);
    float l1 = level(st + vec2(d, 0.0));
    float l2 = level(st + vec2(0.0, d));
    
    // Calculate the normal vector using height differences
    vec3 surface_normal = normalize(vec3(-(l1 - l0) * height_scale, -(l2 - l0) * height_scale, d));
    
    // Convert from world space normal to normal map format (0.0-1.0 range)
    return surface_normal * 0.5 + 0.5;
}

void vertex() {
    if (use_vertex_displacement) {
        vec2 st = UV;
        float height = level(st * noise_scale);
        
        // Displace vertices along their normal
        VERTEX += NORMAL * height * displacement_strength;
    }
}

void fragment() {
    vec2 st = UV;
    
    // Generate normal map
    vec3 normal_color = normal_from_height(st);
    
    // Use the normal map for surface details
    NORMAL_MAP = normal_color;
    
    // Base material properties
    ALBEDO = base_color;
    ROUGHNESS = roughness;
    METALLIC = metallic;
    
    // Optional: Add height-based color variation
    float height = level(st * noise_scale);
    ALBEDO = mix(base_color * 0.7, base_color * 1.3, height);
}