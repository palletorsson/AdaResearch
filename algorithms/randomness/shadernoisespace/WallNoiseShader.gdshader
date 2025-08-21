// WallNoiseShader.gdshader
// Shader for wall textures creating pink clouds with darker corners
shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled, diffuse_burley, specular_schlick_ggx;


uniform float time : hint_range(0.0, 100.0) = 0.0;
uniform float cloud_scale : hint_range(0.5, 5.0) = 2.0;
uniform float pink_intensity : hint_range(0.0, 2.0) = 0.8;
uniform float corner_darkness : hint_range(0.0, 1.0) = 0.3;
uniform float time_scale : hint_range(0.0, 1.0) = 0.2;
uniform float cloud_density : hint_range(0.1, 2.0) = 1.0;
uniform vec4 base_pink : source_color = vec4(1.0, 0.6, 0.8, 1.0);
uniform vec4 deep_pink : source_color = vec4(0.8, 0.2, 0.6, 1.0);
uniform vec4 dark_corner : source_color = vec4(0.2, 0.1, 0.2, 1.0);

varying vec2 world_uv;
varying vec3 world_position;

// High quality 2D noise
vec2 hash2(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)),
             dot(p, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise2d(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(mix(dot(hash2(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)),
                   dot(hash2(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
               mix(dot(hash2(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
                   dot(hash2(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x), u.y);
}

// Cloud-like fractal noise
float cloud_noise(vec2 pos, float t) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    // Multiple octaves for cloud-like appearance
    for (int i = 0; i < 6; i++) {
        vec2 animated_pos = pos * frequency;
        animated_pos.x += sin(t * 0.3 + pos.y * 0.5) * 0.3;
        animated_pos.y += cos(t * 0.2 + pos.x * 0.3) * 0.2;
        
        value += amplitude * abs(noise2d(animated_pos));
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    return value;
}

// Turbulence for more organic cloud patterns
float turbulence(vec2 pos, float t) {
    float turb = 0.0;
    float amplitude = 1.0;
    float frequency = 0.5;
    
    for (int i = 0; i < 4; i++) {
        vec2 moving_pos = pos * frequency;
        moving_pos += vec2(cos(t * 0.1), sin(t * 0.15)) * 2.0;
        
        turb += amplitude * abs(noise2d(moving_pos));
        amplitude *= 0.6;
        frequency *= 2.5;
    }
    return turb;
}

void vertex() {
    world_uv = UV;
    world_position = VERTEX;
}

void fragment() {
    vec2 uv = world_uv;
    
    // Create flowing cloud patterns
    float cloud_base = cloud_noise(uv * cloud_scale, time * time_scale);
    float cloud_detail = turbulence(uv * cloud_scale * 2.0, time * time_scale * 0.7);
    
    // Combine noise patterns for realistic clouds
    float cloud_pattern = (cloud_base + cloud_detail * 0.4) * cloud_density;
    cloud_pattern = smoothstep(0.2, 0.8, cloud_pattern);
    
    // Create corner darkening effect
    vec2 corner_dist = abs(uv - 0.5) * 2.0; // Distance from center
    float corner_factor = max(corner_dist.x, corner_dist.y);
    corner_factor = pow(corner_factor, 1.5); // Sharper falloff
    float darkness = mix(1.0, corner_darkness, corner_factor);
    
    // Generate pink cloud colors with variation
    vec3 cloud_color = mix(base_pink.rgb, deep_pink.rgb, cloud_pattern);
    
    // Add subtle color shifting over time
    float color_shift = sin(time * 0.3 + uv.x * 2.0 + uv.y * 3.0) * 0.1;
    cloud_color.r += color_shift;
    cloud_color.b -= color_shift * 0.5;
    
    // Apply pink intensity
    cloud_color *= pink_intensity;
    
    // Apply corner darkening
    cloud_color = mix(dark_corner.rgb, cloud_color, darkness);
    
    // Add subtle edge highlighting
    float edge_highlight = 1.0 - smoothstep(0.4, 0.6, cloud_pattern);
    cloud_color += edge_highlight * 0.2 * vec3(1.0, 0.8, 0.9);
    
    // Final cloud density modulation
    float final_pattern = smoothstep(0.1, 0.9, cloud_pattern);
    vec3 final_color = mix(cloud_color * 0.3, cloud_color, final_pattern);
    
    // Add atmospheric depth
    float atmospheric = 1.0 - cloud_pattern * 0.2;
    final_color *= atmospheric;
    
    ALBEDO = final_color;
    EMISSION = final_color * 0.1 * pink_intensity;
    METALLIC = 0.0;
    ROUGHNESS = 0.7 + cloud_pattern * 0.3;
    
    // Add subtle normal mapping effect for depth
    vec2 normal_offset = vec2(
        cloud_noise(uv * cloud_scale + vec2(0.01, 0.0), time * time_scale) - 
        cloud_noise(uv * cloud_scale - vec2(0.01, 0.0), time * time_scale),
        cloud_noise(uv * cloud_scale + vec2(0.0, 0.01), time * time_scale) - 
        cloud_noise(uv * cloud_scale - vec2(0.0, 0.01), time * time_scale)
    ) * 0.1;
    
    NORMAL_MAP = vec3(normal_offset, 1.0);
}