shader_type spatial;

// VR-optimized water shader based on Gerstner waves
// Reduced complexity for better VR performance while maintaining visual quality

render_mode depth_draw_always, cull_disabled;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;

// Simplified wave parameters (reduced from 8 to 4 waves for VR performance)
group_uniforms Waves;
uniform vec4 wave_1 = vec4(0.2, 3.0, 0.15, 0.8);   // Slower, gentler waves
uniform vec4 wave_2 = vec4(-0.15, -0.1, 0.008, 0.6);
uniform vec4 wave_3 = vec4(-1.2, 0.8, 0.08, 0.5);
uniform vec4 wave_4 = vec4(0.3, -0.4, 0.12, 1.2);

uniform float time_factor = 1.5;                     // Slower motion for VR comfort
uniform float noise_zoom = 1.5;                      // Reduced complexity
uniform float noise_amp = 0.8;                       // Gentler height variation

group_uniforms Water_colours;
uniform vec3 base_water_color : source_color = vec3(0.1, 0.3, 0.6);
uniform vec3 fresnel_water_color : source_color = vec3(0.2, 0.5, 0.8);
uniform vec4 deep_water_color : source_color = vec4(0.05, 0.2, 0.4, 0.9);
uniform vec4 shallow_water_color : source_color = vec4(0.3, 0.6, 0.8, 0.7);

group_uniforms Depth;
uniform float beers_law = 0.4;                       // Gentler depth effect
uniform float depth_offset = -0.8;
uniform float near = 5.0;
uniform float far = 8000.0;

group_uniforms Edge_Detection;
uniform float edge_texture_scale = 2.5;
uniform float edge_texture_offset = 0.8;
uniform float edge_texture_speed = 0.08;             // Slower foam movement
uniform float edge_foam_intensity = 1.5;
uniform float edge_fade_start = -2.0;
uniform float edge_fade_end = 5.0;
uniform sampler2D edge_foam_texture;

group_uniforms Surface_details;
uniform float metallic = 0.4;                        // Reduced for VR performance
uniform float roughness = 0.06;
uniform float uv_scale_text_a = 0.08;
uniform vec2 uv_speed_text_a = vec2(0.02, 0.015);   // Slower UV animation
uniform float uv_scale_text_b = 0.4;
uniform vec2 uv_speed_text_b = vec2(0.008, 0.006);  // Very slow secondary movement
uniform float normal_strength = 0.8;                 // Reduced for gentler effect
uniform float blend_factor = 0.25;
uniform sampler2D normalmap_a;
uniform sampler2D normalmap_b;

// Simplified fresnel function
float fresnel(float amount, vec3 normal, vec3 view) {
    return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}

// Edge depth calculation
float edge(float depth) {
    depth = 2.0 * depth - 1.0;
    return near * far / (far - depth * (near - far));
}

// Simplified noise function for VR performance
float simple_noise(vec2 x) {
    return fract(sin(dot(x * 17.17, vec2(14.91, 67.31))) * 4791.9511);
}

// Reduced complexity fBM (3 octaves instead of 6)
float fbm(vec2 x) {
    float height = 0.0;
    float amplitude = 0.5;
    float frequency = 2.0;
    for (int i = 0; i < 3; i++) {
        height += simple_noise(x * frequency) * amplitude;
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    return height;
}

// Simplified wave result structure
struct WaveResult {
    vec3 displacement;
    vec3 normal;
};

// Optimized Gerstner wave function
WaveResult gerstner_wave(vec4 params, vec2 pos, float time) {
    float steepness = params.z;
    float wavelength = params.w;
    float k = 2.0 * PI / wavelength;
    float c = sqrt(9.81 / k);
    vec2 d = normalize(params.xy);
    float f = k * (dot(d, pos.xy) - c * time);
    float a = steepness / k;

    vec3 displacement = vec3(d.x * (a * cos(f)), a * sin(f), d.y * (a * cos(f)));

    // Simplified normal calculation
    float sin_f = sin(f);
    float cos_f = cos(f);
    vec3 normal = normalize(vec3(-d.x * steepness * sin_f, 1.0, -d.y * steepness * sin_f));

    return WaveResult(displacement, normal);
}

// Combine waves (reduced from 8 to 4 for VR performance)
WaveResult wave(vec2 pos, float time) {
    WaveResult result;
    result.displacement = vec3(0.0);
    result.normal = vec3(0.0, 1.0, 0.0);

    WaveResult wr;
    wr = gerstner_wave(wave_1, pos, time);
    result.displacement += wr.displacement;
    result.normal += wr.normal;

    wr = gerstner_wave(wave_2, pos, time);
    result.displacement += wr.displacement;
    result.normal += wr.normal;

    wr = gerstner_wave(wave_3, pos, time);
    result.displacement += wr.displacement;
    result.normal += wr.normal;

    wr = gerstner_wave(wave_4, pos, time);
    result.displacement += wr.displacement;
    result.normal += wr.normal;

    // Add subtle noise
    result.displacement.y += fbm(pos.xy * noise_zoom * 0.02) * noise_amp * 0.5;

    return result;
}

varying float height;
varying vec3 world_position;

void vertex() {
    float time = TIME / time_factor;
    WaveResult waveResult = wave(VERTEX.xz, time);
    VERTEX += waveResult.displacement;
    height = waveResult.displacement.y;
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    NORMAL = (MODEL_MATRIX * vec4(waveResult.normal, 0.0)).xyz;
}

void fragment() {
    vec2 uv = world_position.xz;

    // Simplified normal mapping (reduced complexity)
    vec2 uv_a = uv * uv_scale_text_a + uv_speed_text_a * TIME;
    vec2 uv_b = uv * uv_scale_text_b + uv_speed_text_b * TIME;

    vec3 normal_a = texture(normalmap_a, uv_a).rgb * 2.0 - 1.0;
    vec3 normal_b = texture(normalmap_b, uv_b).rgb * 2.0 - 1.0;
    vec3 combined_normal = normalize(mix(normal_a, normal_b, blend_factor));

    // Apply normal strength
    NORMAL = normalize(NORMAL + combined_normal * normal_strength);

    // Depth calculations
    float depth_raw = texture(DEPTH_TEXTURE, SCREEN_UV).r;
    float depth = PROJECTION_MATRIX[3][2] / (depth_raw + PROJECTION_MATRIX[2][2]);

    // Simplified depth blending
    float depth_blend = exp((depth + VERTEX.z + depth_offset) * -beers_law);
    depth_blend = clamp(1.0 - depth_blend, 0.0, 1.0);
    float depth_blend_power = clamp(pow(depth_blend, 2.0), 0.0, 1.0);

    // Color mixing
    vec3 screen_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, depth_blend_power * 2.0).rgb;
    vec3 depth_color = mix(shallow_water_color.rgb, deep_water_color.rgb, depth_blend_power);
    vec3 color = mix(screen_color * depth_color, depth_color * 0.3, depth_blend_power * 0.4);

    // Edge detection for foam
    float z_depth = edge(texture(DEPTH_TEXTURE, SCREEN_UV).x);
    float z_pos = edge(FRAGCOORD.z);
    float z_dif = z_depth - z_pos;

    // Fresnel effect
    float fresnel_effect = fresnel(4.0, NORMAL, VIEW);
    vec3 surface_color = mix(base_water_color, fresnel_water_color, fresnel_effect);

    // Edge foam (simplified)
    vec2 edge_uv = world_position.xz * edge_texture_scale + TIME * edge_texture_speed;
    float edge_fade = smoothstep(edge_fade_start, edge_fade_end, z_dif);
    vec3 final_color = mix(texture(edge_foam_texture, edge_uv).rgb * edge_foam_intensity, color, edge_fade);

    // Combine all effects
    ALBEDO = clamp(surface_color + final_color, vec3(0.0), vec3(1.0));
    METALLIC = metallic;
    ROUGHNESS = roughness;
}