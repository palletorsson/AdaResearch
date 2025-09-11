shader_type spatial;

render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

// Essential uniforms only
uniform vec4 water_color : source_color = vec4(0.1, 0.4, 0.7, 0.8);
uniform vec4 deep_color : source_color = vec4(0.05, 0.2, 0.4, 0.9);
uniform float wave_speed : hint_range(0.1, 2.0) = 0.5;
uniform float wave_height : hint_range(0.0, 1.0) = 0.2;
uniform float wave_frequency : hint_range(0.1, 5.0) = 1.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.1;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

varying vec3 world_position;
varying float vertex_height;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    
    // Simple sine wave displacement
    float time = TIME * wave_speed;
    float wave1 = sin(world_position.x * wave_frequency + time) * wave_height;
    float wave2 = sin(world_position.z * wave_frequency * 0.7 + time * 1.3) * wave_height * 0.6;
    
    VERTEX.y += wave1 + wave2;
    vertex_height = wave1 + wave2;
    
    // Simple normal calculation
    float dx = cos(world_position.x * wave_frequency + time) * wave_frequency * wave_height;
    float dz = cos(world_position.z * wave_frequency * 0.7 + time * 1.3) * wave_frequency * 0.7 * wave_height * 0.6;
    
    NORMAL = normalize(vec3(-dx, 1.0, -dz));
}

void fragment() {
    // Get depth for transparency effect
    float depth = texture(DEPTH_TEXTURE, SCREEN_UV).r;
    depth = PROJECTION_MATRIX[3][2] / (depth + PROJECTION_MATRIX[2][2]);
    float water_depth = depth + VERTEX.z;
    
    // Simple depth-based color mixing
    float depth_factor = clamp(water_depth * 0.5, 0.0, 1.0);
    vec3 final_color = mix(water_color.rgb, deep_color.rgb, depth_factor);
    
    // Add screen color for refraction effect
    vec3 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
    final_color = mix(screen_color, final_color, water_color.a);
    
    // Simple fresnel effect
    float fresnel = 1.0 - dot(normalize(NORMAL), normalize(VIEW));
    fresnel = pow(fresnel, 2.0);
    
    ALBEDO = mix(final_color, final_color * 1.2, fresnel * 0.3);
    ROUGHNESS = roughness;
    METALLIC = metallic;
    ALPHA = mix(0.7, 1.0, depth_factor);
}