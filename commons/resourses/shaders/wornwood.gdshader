shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Main control parameters
uniform float wear_amount : hint_range(0.0, 1.0) = 0.6;
uniform float scratch_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float dirt_amount : hint_range(0.0, 1.0) = 0.5;
uniform float edge_wear : hint_range(0.0, 1.0) = 0.7;
uniform float wood_grain_strength : hint_range(0.0, 1.0) = 0.5;

// Advanced parameters
uniform float roughness_base : hint_range(0.0, 1.0) = 0.6;
uniform float roughness_variation : hint_range(0.0, 1.0) = 0.3;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float normal_strength : hint_range(0.0, 2.0) = 0.5;

// Wood colors
uniform vec3 wood_color_light : source_color = vec3(0.6, 0.4, 0.25);
uniform vec3 wood_color_dark : source_color = vec3(0.35, 0.22, 0.15);
uniform vec3 dirt_color : source_color = vec3(0.15, 0.12, 0.1);

// Scaling parameters
uniform float grain_scale : hint_range(0.1, 10.0) = 2.0;
uniform float scratch_scale : hint_range(0.1, 10.0) = 3.0;
uniform float dirt_scale : hint_range(0.1, 20.0) = 8.0;

// === NOISE FUNCTIONS ===

// Hash function for randomness
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// 2D noise function
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// Fractional Brownian Motion for complex patterns
float fbm(vec2 p, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for(int i = 0; i < octaves; i++) {
        value += amplitude * noise(p * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    
    return value;
}

// Voronoi noise for cellular patterns
vec2 voronoi(vec2 p) {
    vec2 n = floor(p);
    vec2 f = fract(p);
    
    float min_dist = 1.0;
    vec2 min_point = vec2(0.0);
    
    for(int j = -1; j <= 1; j++) {
        for(int i = -1; i <= 1; i++) {
            vec2 neighbor = vec2(float(i), float(j));
            vec2 point = hash(n + neighbor) * vec2(1.0, 1.0);
            vec2 diff = neighbor + point - f;
            float dist = length(diff);
            
            if(dist < min_dist) {
                min_dist = dist;
                min_point = point;
            }
        }
    }
    
    return vec2(min_dist, hash(min_point));
}

// === MAIN SHADER ===

void fragment() {
    // Get world position and normal
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    vec3 world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
    
    // === WOOD GRAIN PATTERN ===
    vec2 grain_coord = vec2(world_pos.x, world_pos.z * 4.0) * grain_scale;
    float grain_pattern = fbm(grain_coord, 5);
    grain_pattern = smoothstep(0.3, 0.7, grain_pattern);
    
    // Base wood color with grain
    vec3 wood_base = mix(wood_color_dark, wood_color_light, 
                         mix(0.5, grain_pattern, wood_grain_strength));
    
    // Add ring patterns (optional enhancement)
    float rings = sin(world_pos.x * grain_scale * 8.0 + grain_pattern * 2.0) * 0.5 + 0.5;
    rings = pow(rings, 3.0) * 0.15;
    wood_base += rings * (wood_color_light - wood_color_dark);
    
    // === EDGE WEAR DETECTION ===
    // Detect edges using normals (edges point away from vertical)
    float edge_factor = 1.0 - abs(dot(world_normal, vec3(0.0, 1.0, 0.0)));
    edge_factor = pow(edge_factor, 2.0);
    
    // Corner wear based on position
    vec2 corner_dist = abs(fract(world_pos.xz * 0.5) - 0.5);
    float corner_factor = 1.0 - smoothstep(0.3, 0.5, max(corner_dist.x, corner_dist.y));
    
    // Combined edge wear
    float wear_mask = edge_factor * edge_wear + corner_factor * edge_wear * 0.5;
    wear_mask = clamp(wear_mask, 0.0, 1.0);
    
    // === SCRATCHES ===
    float scratches = 0.0;
    vec2 scratch_coord = world_pos.xz * scratch_scale;
    
    // Multiple scratch layers at different angles
    for(float i = 0.0; i < 8.0; i += 1.0) {
        float angle = i * 0.4;
        vec2 rotated = vec2(
            scratch_coord.x * cos(angle) - scratch_coord.y * sin(angle),
            scratch_coord.x * sin(angle) + scratch_coord.y * cos(angle)
        );
        
        float scratch_line = hash(vec2(floor(rotated.y * 10.0), i));
        if(scratch_line > 0.94) {
            float scratch_pos = fract(rotated.y * 10.0);
            float scratch_width = smoothstep(0.0, 0.1, abs(scratch_pos - 0.5));
            scratches += (1.0 - scratch_width) * 0.2;
        }
    }
    scratches *= scratch_intensity;
    
    // === DIRT ACCUMULATION ===
    vec2 dirt_coord = UV * dirt_scale + world_pos.xz * 0.5;
    float dirt_noise = fbm(dirt_coord, 4);
    
    // Voronoi for splotchy dirt patterns
    vec2 voronoi_dirt = voronoi(dirt_coord * 0.5);
    float dirt_splotches = smoothstep(0.15, 0.25, voronoi_dirt.x);
    
    // Combine dirt patterns
    float dirt = smoothstep(0.4, 0.7, dirt_noise) * (1.0 - dirt_splotches * 0.5);
    
    // More dirt in worn edges and crevices
    dirt += wear_mask * 0.4;
    dirt = clamp(dirt * dirt_amount, 0.0, 1.0);
    
    // === COLOR COMPOSITION ===
    // Wear lightens the wood (exposed fresh layers)
    float total_wear = (wear_mask + scratches) * wear_amount;
    vec3 worn_color = mix(wood_base, wood_color_light * 1.3, total_wear);
    
    // Apply dirt (darkens)
    vec3 final_color = mix(worn_color, dirt_color, dirt * 0.7);
    
    // Subtle color variation
    float color_variation = noise(UV * 20.0 + world_pos.xz) * 0.08;
    final_color += color_variation * (1.0 - dirt);
    
    // Ambient occlusion in edges
    float ao = 1.0 - (edge_factor * 0.25);
    final_color *= ao;
    
    // === OUTPUTS ===
    ALBEDO = final_color;
    
    // Roughness - worn areas are smoother, dirt is rougher
    float roughness = roughness_base;
    roughness -= total_wear * roughness_variation; // Worn areas smoother
    roughness += dirt * 0.2; // Dirt adds roughness
    roughness += noise(UV * 50.0) * 0.1; // Micro variation
    ROUGHNESS = clamp(roughness, 0.1, 1.0);
    
    METALLIC = metallic;
    
    // === NORMAL MAPPING ===
    // Create normal map from procedural details
    float height_grain = grain_pattern * 0.3;
    float height_wear = total_wear * 0.2;
    float height_dirt = dirt * -0.15; // Dirt is recessed
    float height_total = height_grain + height_wear + height_dirt;
    
    // Calculate normal from height variations
    float offset = 0.01;
    float h_right = fbm(grain_coord + vec2(offset, 0.0), 3);
    float h_top = fbm(grain_coord + vec2(0.0, offset), 3);
    
    vec3 normal_map = normalize(vec3(
        (height_total - h_right) * normal_strength,
        (height_total - h_top) * normal_strength,
        1.0
    ));
    
    NORMAL_MAP = normal_map;
    
    // Specular - worn areas are slightly more reflective
    SPECULAR = 0.4 + total_wear * 0.2;
}

void vertex() {
    // Optional: Add subtle vertex displacement for extra detail
    // Uncomment to add geometric detail (performance cost)
    /*
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float displacement = fbm(world_pos.xz * 2.0, 3) * 0.01;
    VERTEX += NORMAL * displacement * wear_amount;
    */
}