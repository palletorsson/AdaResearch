shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// 3D material shader for trippy objects like in the second image
// Creates morphing patterns on 3D surfaces

uniform float animation_speed : hint_range(0.1, 5.0) = 1.0;
uniform float pattern_frequency : hint_range(1.0, 20.0) = 8.0;
uniform float wave_amplitude : hint_range(0.0, 1.0) = 0.5;
uniform float color_shift_speed : hint_range(0.1, 3.0) = 1.5;
uniform float metallic_factor : hint_range(0.0, 1.0) = 0.3;
uniform float roughness_factor : hint_range(0.0, 1.0) = 0.4;
uniform vec3 base_color : source_color = vec3(1.0, 0.5, 0.2);

varying vec3 world_pos;
varying vec3 local_pos;

// Noise functions
float hash(vec3 p) {
    p = fract(p * vec3(0.1031, 0.1030, 0.0973));
    p += dot(p, p.yxz + 33.33);
    return fract((p.x + p.y) * p.z);
}

float noise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    
    vec3 u = f * f * (3.0 - 2.0 * f);
    
    return mix(
        mix(
            mix(hash(i + vec3(0, 0, 0)), hash(i + vec3(1, 0, 0)), u.x),
            mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), u.x), u.y),
        mix(
            mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), u.x),
            mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), u.x), u.y), u.z);
}

float fbm(vec3 p) {
    float value = 0.0;
    float amplitude = 0.5;
    
    for(int i = 0; i < 6; i++) {
        value += amplitude * noise(p);
        p *= 2.0;
        amplitude *= 0.5;
    }
    
    return value;
}

// Morphing pattern generator
float morphing_pattern(vec3 pos, float time_offset) {
    float t = TIME * animation_speed + time_offset;
    
    // Multiple wave layers
    float wave1 = sin(pos.x * pattern_frequency + t * 2.0) * 
                  cos(pos.y * pattern_frequency * 0.7 + t * 1.5) *
                  sin(pos.z * pattern_frequency * 0.9 + t * 1.8);
    
    float wave2 = cos(pos.x * pattern_frequency * 1.3 + t * 2.5) * 
                  sin(pos.y * pattern_frequency * 1.1 + t * 2.2) *
                  cos(pos.z * pattern_frequency * 0.8 + t * 1.9);
    
    // Add noise for complexity
    float noise_layer = fbm(pos * 2.0 + vec3(t * 0.3, t * 0.4, t * 0.2));
    
    return (wave1 + wave2) * 0.3 + noise_layer * 0.4;
}

// Generate vibrant colors
vec3 vibrant_colors(float pattern_value, vec3 pos) {
    float t = TIME * color_shift_speed;
    
    // Create color cycles
    vec3 color1 = vec3(
        0.5 + 0.5 * sin(t + pattern_value * 3.14159),
        0.5 + 0.5 * sin(t + pattern_value * 3.14159 + 2.094),
        0.5 + 0.5 * sin(t + pattern_value * 3.14159 + 4.188)
    );
    
    vec3 color2 = vec3(
        0.5 + 0.5 * cos(t * 0.7 + pos.x + pos.y),
        0.5 + 0.5 * cos(t * 0.8 + pos.y + pos.z),
        0.5 + 0.5 * cos(t * 0.9 + pos.z + pos.x)
    );
    
    // Mix based on pattern
    float mix_factor = 0.5 + 0.5 * sin(pattern_value * 6.28);
    return mix(color1, color2, mix_factor) * base_color;
}

void vertex() {
    world_pos = VERTEX;
    local_pos = VERTEX;
    
    // Add vertex displacement for morphing geometry
    float displacement = morphing_pattern(VERTEX, 0.0) * wave_amplitude * 0.1;
    VERTEX += NORMAL * displacement;
}

void fragment() {
    // Calculate pattern value
    float pattern = morphing_pattern(local_pos, 0.0);
    
    // Generate base color
    vec3 color = vibrant_colors(pattern, local_pos);
    
    // Add intensity variations
    float intensity = 0.7 + 0.3 * pattern;
    color *= intensity;
    
    // Apply gamma correction for vibrant colors
    color = pow(color, vec3(0.8));
    
    // Create animated stripes/bands
    float stripe_pattern = sin(local_pos.y * pattern_frequency * 2.0 + TIME * animation_speed * 3.0);
    color *= 0.8 + 0.4 * stripe_pattern;
    
    // Set material properties
    ALBEDO = color;
    METALLIC = metallic_factor + pattern * 0.2;
    ROUGHNESS = roughness_factor - pattern * 0.1;
    
    // Add emission for glowing effect
    EMISSION = color * 0.1 * (0.5 + 0.5 * sin(TIME * animation_speed + pattern * 6.28));
}