shader_type spatial;

// VR-optimized version with performance improvements and comfort features

uniform vec3 albedo : source_color = vec3(0.1, 0.4, 0.7);
uniform vec3 albedo2 : source_color = vec3(0.2, 0.6, 0.9);
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.05;

// Simplified textures for better VR performance
uniform sampler2D wave : hint_default_black;
uniform sampler2D texture_normal : hint_normal;

// Reduced and slower wave parameters for VR comfort
uniform vec2 wave_direction = vec2(1.0, 0.2); // Gentler, less directional movement
uniform float time_scale : hint_range(0.0, 0.1, 0.001) = 0.015; // Slower for VR comfort
uniform float noise_scale = 15.0; // Larger scale for smoother waves
uniform float height_scale = 0.08; // Reduced height to prevent motion sickness

// Depth colors with better contrast for VR
uniform vec4 color_deep : source_color = vec4(0.05, 0.2, 0.4, 1.0);
uniform vec4 color_shallow : source_color = vec4(0.3, 0.6, 0.8, 0.8);
uniform float beers_law = 1.5; // Reduced for gentler depth transition
uniform float depth_offset = -0.5;

// Simplified edge detection
uniform float edge_scale = 0.2;
uniform float near = 1.0;
uniform float far = 100.0;
uniform vec3 edge_color : source_color = vec3(0.9, 0.9, 1.0);

// VR comfort feature: reduce normal map strength
uniform float normal_strength : hint_range(0.0, 2.0) = 0.6;

uniform sampler2D DEPTH_TEXTURE;
uniform sampler2D SCREEN_TEXTURE;
varying float height;
varying vec3 world_pos;

// Simplified fresnel for better performance
float fresnel(float amount, vec3 normal, vec3 view) {
    return pow(1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0), amount);
}

// Simplified edge function
float edge(float depth) {
    depth = 2.0 * depth - 1.0;
    return near * far / (far + depth * (near - far));
}

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    
    // Simplified wave calculation - single texture sample for better performance
    vec2 wave_uv = world_pos.xz / noise_scale + TIME * wave_direction * time_scale;
    height = texture(wave, wave_uv).r;
    
    // Gentler vertex displacement
    VERTEX.y += height * height_scale;
}

void fragment() {
    // Simplified depth calculation
    float depth_texture = texture(DEPTH_TEXTURE, SCREEN_UV).r;
    float depth = PROJECTION_MATRIX[3][2] / (depth_texture * 2.0 - 1.0 + PROJECTION_MATRIX[2][2]);
    float depth_blend = exp((depth + VERTEX.z + depth_offset) * -beers_law);
    depth_blend = clamp(1.0 - depth_blend, 0.0, 1.0);
    
    // Simplified screen color sampling (no LOD for better VR performance)
    vec3 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
    vec3 depth_color = mix(color_shallow.rgb, color_deep.rgb, depth_blend);
    vec3 color = mix(screen_color * depth_color, depth_color * 0.3, depth_blend * 0.4);
    
    // Simplified edge detection
    float z_depth = edge(texture(DEPTH_TEXTURE, SCREEN_UV).x);
    float z_pos = edge(FRAGCOORD.z);
    float z_dif = z_depth - z_pos;
    
    // Single normal map for better VR performance
    vec2 normal_uv = world_pos.xz + TIME * wave_direction * time_scale;
    vec3 normal_map = texture(texture_normal, normal_uv).rgb;
    
    // Reduced normal strength for VR comfort
    normal_map = mix(vec3(0.5, 0.5, 1.0), normal_map, normal_strength);
    
    // Simplified fresnel calculation
    float fresnel_effect = fresnel(3.0, NORMAL, VIEW); // Reduced intensity
    vec3 surface_color = mix(albedo, albedo2, fresnel_effect);
    
    // Edge foam with smooth transition
    vec3 depth_color_adj = mix(edge_color, color, smoothstep(0.0, edge_scale, z_dif));
    
    // Final color composition
    ALBEDO = clamp(surface_color + depth_color_adj, vec3(0.0), vec3(1.0));
    METALLIC = metallic;
    ROUGHNESS = roughness;
    NORMAL_MAP = normal_map;
}