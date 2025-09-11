shader_type spatial;

// Author @kyndinfo - 2016 (Converted to Godot 4 Spatial)
// http://www.kynd.info
// Title: Terrain - Spatial Version

uniform float time_scale : hint_range(0.0, 3.0) = 1.0;
uniform float noise_scale : hint_range(0.1, 10.0) = 1.0;
uniform float water_level : hint_range(0.0, 1.0) = 0.4;
uniform float terrain_height : hint_range(0.1, 5.0) = 1.0;
uniform int octaves : hint_range(1, 8) = 7;
uniform float vertex_displacement : hint_range(0.0, 2.0) = 0.3;

// Terrain colors and materials
uniform vec3 land_color : source_color = vec3(0.2, 0.6, 0.2);
uniform vec3 water_color : source_color = vec3(0.0, 0.2, 0.8);
uniform vec3 mountain_color : source_color = vec3(0.5, 0.4, 0.3);
uniform vec3 beach_color : source_color = vec3(0.8, 0.7, 0.4);

// Material properties
uniform float roughness_land : hint_range(0.0, 1.0) = 0.8;
uniform float roughness_water : hint_range(0.0, 1.0) = 0.1;
uniform float roughness_mountain : hint_range(0.0, 1.0) = 0.9;
uniform float metallic_water : hint_range(0.0, 1.0) = 0.1;

// Thresholds
uniform float mountain_threshold : hint_range(0.0, 1.0) = 0.7;
uniform float beach_threshold : hint_range(0.0, 0.5) = 0.05;

// Animation and effects
uniform bool animate_terrain  = false;
uniform bool use_vertex_displacement   = true;
uniform float foam_intensity : hint_range(0.0, 1.0) = 0.3;

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
    float time_offset = animate_terrain ? TIME * time_scale * 0.1 : 0.0;
    
    for (int i = 1; i < octaves + 1; i++) {
        float m = pow(2.0, float(i));
        n += snoise((st + time_offset) * m * noise_scale) * (1.0 / m);
    }
    return (n * 0.5 + 0.5) * terrain_height;
}

vec3 calculate_normal(vec2 st) {
    float d = 0.001;
    float l0 = level(st);
    float l1 = level(st + vec2(d, 0.0));
    float l2 = level(st + vec2(0.0, d));
    
    return normalize(vec3(-(l1 - l0), -(l2 - l0), d));
}

void vertex() {
    if (use_vertex_displacement) {
        vec2 st = UV;
        float elevation = level(st);
        
        // Displace vertices based on terrain height
        VERTEX += NORMAL * elevation * vertex_displacement;
    }
}

void fragment() {
    vec2 st = UV;
    float elevation = level(st);
    
    vec3 albedo_color;
    float surface_roughness;
    float surface_metallic = 0.0;
    
    // Determine terrain type based on elevation
    if (elevation < water_level) {
        // Water areas
        float water_depth = (water_level - elevation) / water_level;
        albedo_color = mix(water_color * 1.2, water_color * 0.3, water_depth);
        surface_roughness = roughness_water;
        surface_metallic = metallic_water;
        
        // Add foam effect near shoreline
        if (water_depth < beach_threshold) {
            float foam = snoise(st * 50.0 + TIME * 2.0) * foam_intensity;
            albedo_color = mix(albedo_color, vec3(1.0), foam * (1.0 - water_depth / beach_threshold));
        }
        
    } else if (elevation < water_level + beach_threshold) {
        // Beach/shoreline areas
        float beach_blend = (elevation - water_level) / beach_threshold;
        albedo_color = mix(beach_color, land_color, beach_blend);
        surface_roughness = mix(roughness_water, roughness_land, beach_blend);
        
    } else if (elevation > mountain_threshold) {
        // Mountain areas
        float mountain_blend = smoothstep(mountain_threshold, mountain_threshold + 0.2, elevation);
        albedo_color = mix(land_color, mountain_color, mountain_blend);
        surface_roughness = mix(roughness_land, roughness_mountain, mountain_blend);
        
    } else {
        // Regular land areas
        albedo_color = land_color;
        surface_roughness = roughness_land;
    }
    
    // Add height-based lighting variation
    float height_variation = smoothstep(0.0, 1.0, elevation);
    albedo_color *= (0.7 + 0.3 * height_variation);
    
    // Generate normal map from terrain
    vec3 terrain_normal = calculate_normal(st);
    vec3 normal_map = terrain_normal * 0.5 + 0.5;
    
    ALBEDO = albedo_color;
    ROUGHNESS = surface_roughness;
    METALLIC = surface_metallic;
    NORMAL_MAP = normal_map;
    
    // Add subtle emission for water reflections
    if (elevation < water_level) {
        EMISSION = albedo_color * 0.1;
    }
}