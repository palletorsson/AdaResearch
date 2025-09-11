shader_type spatial;

// Based on Stay at Home Dev's Godot 4 water shader tutorials
// Includes: dual normal maps, vertex displacement, fresnel, depth color, edge foam, and refraction

// Core material properties
uniform vec4 albedo : source_color = vec4(0.0, 0.5, 0.6, 1.0);
uniform vec4 albedo2 : source_color = vec4(0.0, 0.7, 0.9, 1.0);
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.1;

// Normal map textures and animation
uniform sampler2D texture_normal : hint_normal;
uniform sampler2D texture_normal2 : hint_normal;
uniform vec2 wave_direction = vec2(2.0, 0.0);
uniform vec2 wave_direction2 = vec2(0.0, 1.0);
uniform float time_scale : hint_range(0.0, 0.3) = 0.025;

// Vertex displacement (wave height)
uniform sampler2D wave : hint_default_black;
uniform float noise_scale = 10.0;
uniform float height_scale = 0.5;

// Depth colors and transparency
uniform vec4 color_deep : source_color = vec4(0.0, 0.0, 0.1, 1.0);
uniform vec4 color_shallow : source_color = vec4(0.0, 0.4, 0.8, 1.0);
uniform float beers_law = 2.0;
uniform float depth_offset = -0.75;
uniform float water_transparency : hint_range(0.0, 1.0) = 0.0;

// Edge detection and foam
uniform float edge_scale = 0.25;
uniform float near = 1.0;
uniform float far = 100.0;
uniform vec4 edge_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// Refraction
uniform float refraction_strength : hint_range(0.0, 1.0) = 0.5;

// Screen textures for refraction and depth
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Varying variables to pass data from vertex to fragment
varying float height;
varying vec3 world_position;

// Fresnel function
float fresnel(float amount, vec3 normal, vec3 view) {
    return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}

// Edge detection function
float edge(float depth) {
    depth = 2.0 * depth - 1.0;
    return near * far / (far - depth * (near - far));
}

void vertex() {
    // Calculate world position for scaling
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

    // Sample wave texture for vertex displacement
    vec2 time_offset = TIME * wave_direction * time_scale;
    float noise = texture(wave, world_position.xz / noise_scale + time_offset).r;
    height = noise;

    // Apply vertex displacement
    VERTEX.y += noise * height_scale;
}

void fragment() {
    // Calculate animated UVs for normal maps
    vec2 time_offset1 = TIME * wave_direction * time_scale;
    vec2 time_offset2 = TIME * wave_direction2 * time_scale;

    // Sample both normal maps
    vec3 normal_blend = mix(
        texture(texture_normal, world_position.xz + time_offset1).rgb,
        texture(texture_normal2, world_position.xz + time_offset2).rgb,
        0.5
    );

    // Convert normal map from [0,1] to [-1,1] range
    normal_blend = normalize(normal_blend * 2.0 - 1.0);

    // Create refraction normal for UV distortion
    vec3 refraction_normal = normal_blend * 2.0 - 1.0;
    refraction_normal = mix(NORMAL, refraction_normal, 0.5);

    // Calculate distorted UV for refraction
    vec2 distorted_uv = SCREEN_UV - refraction_normal.xy * refraction_strength;

    // Sample depth textures (clean and distorted)
    float depth_clean = texture(DEPTH_TEXTURE, SCREEN_UV).r;
    float depth_distorted = texture(DEPTH_TEXTURE, distorted_uv).r;

    // Calculate linear depth values
    float ndc_clean = depth_clean * 2.0 - 1.0;
    vec4 view_clean = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, ndc_clean, 1.0);
    view_clean.xyz /= view_clean.w;
    float linear_depth_clean = -view_clean.z;

    // Check if pixel is in front of water surface
    bool use_distorted = linear_depth_clean > 0.1;

    // Choose appropriate depth and screen texture
    float depth_texture_value = use_distorted ? depth_distorted : depth_clean;
    vec3 screen_color = use_distorted ?
        texture(SCREEN_TEXTURE, distorted_uv).rgb :
        texture(SCREEN_TEXTURE, SCREEN_UV).rgb;

    // Calculate depth for Beer's law
    float depth = PROJECTION_MATRIX[3][2] / (depth_texture_value + PROJECTION_MATRIX[2][2]);
    float depth_blend = exp((depth + VERTEX.z + depth_offset) * -beers_law);
    depth_blend = clamp(1.0 - depth_blend, 0.0, 1.0);

    // Mix shallow and deep colors based on depth
    vec3 depth_color = mix(color_shallow.rgb, color_deep.rgb, depth_blend);

    // Create refraction texture mix
    vec3 refraction_texture = mix(depth_color, screen_color, water_transparency * depth_blend);

    // Calculate fresnel effect
    float fresnel_effect = fresnel(5.0, NORMAL, VIEW);
    vec3 surface_color = mix(albedo.rgb, albedo2.rgb, fresnel_effect);

    // Edge detection for foam
    float z_depth = edge(texture(DEPTH_TEXTURE, SCREEN_UV).x);
    float z_pos = edge(FRAGCOORD.z);
    float z_dif = z_depth - z_pos;

    // Apply edge foam
    float edge_blend = step(edge_scale, z_dif);
    vec3 surface_color_final = mix(edge_color.rgb, surface_color, edge_blend);

    // Final color combining surface and refraction
    ALBEDO = mix(refraction_texture, surface_color_final, fresnel_effect);
    NORMAL = normal_blend;
    METALLIC = metallic;
    ROUGHNESS = roughness;
}