shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

// Screen texture for background/refraction
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Flow textures
uniform sampler2D flow_map : source_color;
uniform sampler2D deriv_height_texture : source_color;

// Water surface properties
uniform vec4 water_color : source_color = vec4(0.306, 0.514, 0.663, 0.8);
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.5;

// Flow properties
uniform float flow_strength : hint_range(0.0, 2.0) = 1.0;
uniform float flow_speed : hint_range(0.0, 2.0) = 1.0;
uniform float tiling : hint_range(0.1, 10.0) = 1.0;

// Underwater fog
uniform vec4 water_fog_color : source_color = vec4(0.306, 0.514, 0.663, 1.0);
uniform float water_fog_density : hint_range(0.0, 2.0) = 0.15;

// Refraction
uniform float refraction_strength : hint_range(0.0, 1.0) = 0.25;

// Transparency
uniform float transparency : hint_range(0.0, 1.0) = 0.8;

varying vec2 flow_uv;
varying vec3 vertex_world_pos;
varying float vertex_distance;

// Flow function implementation
vec2 flow_uv_func(vec2 uv, vec2 flow_vector, float time) {
    return uv - flow_vector * time;
}

// Unpack derivative height from texture
vec3 unpack_derivative_height(vec4 textureData) {
    vec3 dh = textureData.rgb * 2.0 - 1.0;
    dh.xy *= textureData.a;
    return dh;
}

// Flow grid implementation with phase offset
vec3 flow_grid(vec2 uv, vec2 flow_vec, float time, bool flowB) {
    float phase = flowB ? 0.5 : 0.0;
    float flowLerp = abs(fract(time + phase) * 2.0 - 1.0);
    flowLerp = smoothstep(0.0, 1.0, flowLerp);
    
    vec2 sample_uv = flow_uv_func(uv, flow_vec, time + phase);
    vec3 dh = unpack_derivative_height(texture(deriv_height_texture, sample_uv));
    
    return dh * flowLerp;
}

// Main flow function combining two flow phases
vec3 flow(vec2 uv, vec2 flow_vec, float time) {
    vec3 dhA = flow_grid(uv, flow_vec, time, false);
    vec3 dhB = flow_grid(uv, flow_vec, time, true);
    return dhA + dhB;
}

void vertex() {
    flow_uv = UV * tiling;
    vertex_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    vertex_distance = length(VERTEX);
}

void fragment() {
    float current_time = TIME * flow_speed;
    
    // Sample flow map to get flow direction
    vec2 flow_vector = (texture(flow_map, UV).rg * 2.0 - 1.0) * flow_strength;
    
    // Get derivative height from flow calculation
    vec3 dh = flow(flow_uv, flow_vector, current_time);
    
    // Calculate surface normal from derivatives
    vec3 surface_normal = normalize(vec3(-dh.xy, 1.0));
    
    // Screen coordinates for background sampling
    vec2 screen_uv = SCREEN_UV;
    
    // Apply refraction offset
    vec2 refraction_offset = surface_normal.xy * refraction_strength * 0.02;
    vec2 refracted_uv = screen_uv + refraction_offset;
    refracted_uv = clamp(refracted_uv, 0.02, 0.98);
    
    // Sample background with refraction
    vec3 background_color = texture(SCREEN_TEXTURE, refracted_uv).rgb;
    
    // Simple depth-based fog using vertex distance
    float fog_depth = vertex_distance * 0.1;
    float fog_factor = exp2(-water_fog_density * fog_depth);
    fog_factor = clamp(fog_factor, 0.0, 1.0);
    vec3 fogged_background = mix(water_fog_color.rgb, background_color, fog_factor);
    
    // Calculate water surface properties
    float height_intensity = dh.z * dh.z;
    vec3 final_water_color = water_color.rgb * height_intensity;
    
    // Set material properties
    ALBEDO = final_water_color;
    NORMAL = surface_normal;
    METALLIC = metallic;
    ROUGHNESS = roughness;
    
    // Mix surface with underwater view
    float alpha = water_color.a * transparency;
    EMISSION = fogged_background * (1.0 - alpha);
    ALPHA = alpha;
}