shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled, depth_draw_opaque, blend_mix;

// Time and animation parameters
uniform float time_scale : hint_range(0.1, 5.0) = 1.0;
uniform float blob_speed : hint_range(0.5, 3.0) = 1.5;
uniform float blob_intensity : hint_range(0.1, 2.0) = 1.0;

// Noise parameters
uniform float noise_scale : hint_range(0.1, 10.0) = 2.0;
uniform float noise_strength : hint_range(0.1, 2.0) = 0.5;
uniform int noise_octaves : hint_range(1, 8) = 4;

// Color parameters
uniform vec4 blob_color : source_color = vec4(0.2, 0.8, 1.0, 0.7);
uniform vec4 blob_core_color : source_color = vec4(1.0, 0.5, 0.8, 0.9);
uniform float color_shift_speed : hint_range(0.1, 3.0) = 1.0;

// Size and morphing
uniform float base_size : hint_range(0.1, 3.0) = 1.0;
uniform float size_variation : hint_range(0.0, 1.0) = 0.3;
uniform float morph_speed : hint_range(0.1, 5.0) = 2.0;

varying vec3 world_position;
varying vec3 local_position;
varying float noise_factor;

// 3D Noise function
vec3 mod289(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 mod289_4(vec4 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x) {
    return mod289_4(((x * 34.0) + 1.0) * x);
}

vec4 taylorInvSqrt(vec4 r) {
    return 1.79284291400159 - 0.85373472095314 * r;
}

float snoise(vec3 v) {
    const vec2 C = vec2(1.0/6.0, 1.0/3.0);
    const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);
    
    vec3 i = floor(v + dot(v, C.yyy));
    vec3 x0 = v - i + dot(i, C.xxx);
    
    vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;
    vec3 i1 = min(g.xyz, l.zxy);
    vec3 i2 = max(g.xyz, l.zxy);
    
    vec3 x1 = x0 - i1 + C.xxx;
    vec3 x2 = x0 - i2 + C.yyy;
    vec3 x3 = x0 - D.yyy;
    
    i = mod289(i);
    vec4 p = permute(permute(permute(
        i.z + vec4(0.0, i1.z, i2.z, 1.0))
        + i.y + vec4(0.0, i1.y, i2.y, 1.0))
        + i.x + vec4(0.0, i1.x, i2.x, 1.0));
        
    float n_ = 0.142857142857;
    vec3 ns = n_ * D.wyz - D.xzx;
    
    vec4 j = p - 49.0 * floor(p * ns.z * ns.z);
    
    vec4 x_ = floor(j * ns.z);
    vec4 y_ = floor(j - 7.0 * x_);
    
    vec4 x = x_ * ns.x + ns.yyyy;
    vec4 y = y_ * ns.x + ns.yyyy;
    vec4 h = 1.0 - abs(x) - abs(y);
    
    vec4 b0 = vec4(x.xy, y.xy);
    vec4 b1 = vec4(x.zw, y.zw);
    
    vec4 s0 = floor(b0) * 2.0 + 1.0;
    vec4 s1 = floor(b1) * 2.0 + 1.0;
    vec4 sh = -step(h, vec4(0.0));
    
    vec4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
    vec4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
    
    vec3 p0 = vec3(a0.xy, h.x);
    vec3 p1 = vec3(a0.zw, h.y);
    vec3 p2 = vec3(a1.xy, h.z);
    vec3 p3 = vec3(a1.zw, h.w);
    
    vec4 norm = taylorInvSqrt(vec4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;
    
    vec4 m = max(0.6 - vec4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
    m = m * m;
    return 42.0 * dot(m * m, vec4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)));
}

// Fractal noise with multiple octaves
float fractal_noise(vec3 pos) {
    float value = 0.0;
    float amplitude = 1.0;
    float frequency = 1.0;
    
    for (int i = 0; i < noise_octaves; i++) {
        value += snoise(pos * frequency) * amplitude;
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    
    return value;
}

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    local_position = VERTEX;
    
    // Calculate noise factor for vertex displacement
    vec3 noise_pos = world_position * noise_scale + vec3(TIME * blob_speed * time_scale);
    noise_factor = fractal_noise(noise_pos) * noise_strength;
    
    // Apply morphing and size variation
    float size_morph = base_size + sin(TIME * morph_speed + world_position.x * 0.5) * size_variation;
    
    // Apply noise displacement to create blob-like morphing
    vec3 displacement = vec3(
        snoise(noise_pos + vec3(100.0)),
        snoise(noise_pos + vec3(200.0)),
        snoise(noise_pos + vec3(300.0))
    ) * noise_factor;
    
    VERTEX = VERTEX * size_morph + displacement;
}

void fragment() {
    // Calculate distance from center for blob falloff
    float distance_from_center = length(local_position);
    
    // Create blob mask with soft edges
    float blob_mask = 1.0 - smoothstep(0.3, 1.0, distance_from_center);
    
    // Add noise-based internal structure
    vec3 noise_pos = world_position * noise_scale * 2.0 + vec3(TIME * blob_speed * time_scale * 0.5);
    float internal_noise = fractal_noise(noise_pos) * 0.5 + 0.5;
    
    // Create pulsing effect
    float pulse = sin(TIME * 3.0 + world_position.x * 0.2 + world_position.z * 0.3) * 0.5 + 0.5;
    
    // Color shifting over time
    float hue_shift = sin(TIME * color_shift_speed + world_position.y * 0.1) * 0.5 + 0.5;
    vec4 shifted_color = mix(blob_color, blob_core_color, hue_shift);
    
    // Combine all effects
    float intensity = blob_mask * internal_noise * pulse * blob_intensity;
    vec4 final_color = shifted_color * intensity;
    
    // Add glow effect at edges
    float edge_glow = smoothstep(0.8, 1.0, distance_from_center) * blob_mask * 0.5;
    final_color.rgb += vec3(edge_glow);
    
    // Apply noise factor for additional variation
    final_color.a *= blob_mask * (0.7 + noise_factor * 0.3);
    
    ALBEDO = final_color.rgb;
    ALPHA = final_color.a;
}

