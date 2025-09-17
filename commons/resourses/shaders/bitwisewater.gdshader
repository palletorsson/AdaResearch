shader_type spatial;
render_mode depth_prepass_alpha, cull_disabled, diffuse_burley, specular_schlick_ggx;

// Pride flag selector
uniform int pride_flag : hint_range(0, 7) = 0; // 0=Trans, 1=Rainbow, 2=Lesbian, 3=Bi, 4=Pan, 5=Ace, 6=Non-binary, 7=Progress

// Animation controls
uniform float flow_speed : hint_range(0.1, 5.0) = 1.5;
uniform float wave_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float shimmer_speed : hint_range(0.1, 10.0) = 3.0;
uniform float color_blend : hint_range(0.0, 2.0) = 1.2;

// Effect controls
uniform float transparency : hint_range(0.0, 1.0) = 0.85;
uniform float glow_strength : hint_range(0.0, 3.0) = 1.8;
uniform float sparkle_density : hint_range(0.0, 10.0) = 5.0;
uniform bool flowing_stripes = true;
uniform bool add_sparkles  = true;
uniform bool holographic_effect  = true;

varying vec3 world_pos;
varying vec2 flow_uv;
varying vec3 view_dir;

// Hash function for sparkles
float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Get pride flag colors
vec3 get_pride_color(int flag_type, float t) {
    t = clamp(t, 0.0, 1.0);
    
    if (flag_type == 0) { // Trans flag
        if (t < 0.2) return vec3(0.36, 0.81, 0.98); // Light blue
        else if (t < 0.4) return vec3(0.96, 0.67, 0.79); // Pink
        else if (t < 0.6) return vec3(1.0, 1.0, 1.0); // White
        else if (t < 0.8) return vec3(0.96, 0.67, 0.79); // Pink
        else return vec3(0.36, 0.81, 0.98); // Light blue
        
    } else if (flag_type == 1) { // Rainbow flag
        if (t < 0.167) return vec3(0.9, 0.0, 0.0); // Red
        else if (t < 0.333) return vec3(1.0, 0.5, 0.0); // Orange
        else if (t < 0.5) return vec3(1.0, 1.0, 0.0); // Yellow
        else if (t < 0.667) return vec3(0.0, 0.8, 0.0); // Green
        else if (t < 0.833) return vec3(0.0, 0.4, 1.0); // Blue
        else return vec3(0.5, 0.0, 0.8); // Purple
        
    } else if (flag_type == 2) { // Lesbian flag
        if (t < 0.2) return vec3(0.84, 0.27, 0.0); // Dark orange
        else if (t < 0.4) return vec3(1.0, 0.6, 0.4); // Orange
        else if (t < 0.6) return vec3(1.0, 1.0, 1.0); // White
        else if (t < 0.8) return vec3(0.82, 0.47, 0.65); // Pink
        else return vec3(0.64, 0.0, 0.32); // Dark pink
        
    } else if (flag_type == 3) { // Bisexual flag
        if (t < 0.4) return vec3(0.84, 0.0, 0.63); // Pink
        else if (t < 0.6) return vec3(0.62, 0.32, 0.82); // Purple blend
        else return vec3(0.0, 0.32, 0.82); // Blue
        
    } else if (flag_type == 4) { // Pansexual flag
        if (t < 0.33) return vec3(1.0, 0.13, 0.54); // Pink
        else if (t < 0.67) return vec3(1.0, 0.85, 0.0); // Yellow
        else return vec3(0.13, 0.69, 1.0); // Blue
        
    } else if (flag_type == 5) { // Asexual flag
        if (t < 0.25) return vec3(0.0, 0.0, 0.0); // Black
        else if (t < 0.5) return vec3(0.64, 0.64, 0.64); // Gray
        else if (t < 0.75) return vec3(1.0, 1.0, 1.0); // White
        else return vec3(0.5, 0.0, 0.5); // Purple
        
    } else if (flag_type == 6) { // Non-binary flag
        if (t < 0.25) return vec3(1.0, 0.96, 0.0); // Yellow
        else if (t < 0.5) return vec3(1.0, 1.0, 1.0); // White
        else if (t < 0.75) return vec3(0.6, 0.27, 0.8); // Purple
        else return vec3(0.0, 0.0, 0.0); // Black
        
    } else { // Progress flag (simplified)
        if (t < 0.15) return vec3(0.36, 0.81, 0.98); // Trans blue
        else if (t < 0.3) return vec3(0.96, 0.67, 0.79); // Trans pink
        else if (t < 0.4) return vec3(0.6, 0.3, 0.0); // Brown
        else if (t < 0.5) return vec3(0.0, 0.0, 0.0); // Black
        else if (t < 0.6) return vec3(0.9, 0.0, 0.0); // Red
        else if (t < 0.7) return vec3(1.0, 0.5, 0.0); // Orange
        else if (t < 0.8) return vec3(1.0, 1.0, 0.0); // Yellow
        else if (t < 0.9) return vec3(0.0, 0.8, 0.0); // Green
        else return vec3(0.0, 0.4, 1.0); // Blue
    }
}

// Smooth color blending between flag stripes
vec3 get_blended_pride_color(int flag_type, float t) {
    // Sample multiple points for smooth blending
    vec3 color1 = get_pride_color(flag_type, t);
    vec3 color2 = get_pride_color(flag_type, t + 0.1);
    vec3 color3 = get_pride_color(flag_type, t - 0.1);
    
    // Blend for smoother transitions
    return mix(mix(color1, color2, 0.3), color3, 0.2);
}

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    view_dir = normalize(CAMERA_POSITION_WORLD - world_pos);
    
    // Create flowing UV coordinates
    flow_uv = UV;
    
    if (flowing_stripes) {
        // Diagonal flow for dynamic flag effect
        flow_uv += vec2(
            sin(TIME * flow_speed + VERTEX.y * 3.0) * 0.1,
            cos(TIME * flow_speed * 0.7 + VERTEX.x * 2.0) * 0.05
        );
    }
}

void fragment() {
    vec2 uv = flow_uv;
    float time = TIME;
    
    // Create flowing wave effect across the surface
    float wave_offset = 0.0;
    if (flowing_stripes) {
        wave_offset = sin(uv.x * 8.0 + time * shimmer_speed) * 0.1 * wave_intensity;
        wave_offset += cos(uv.y * 6.0 + time * shimmer_speed * 0.8) * 0.05 * wave_intensity;
    }
    
    // Calculate stripe position with wave effect
    float stripe_pos = uv.y + wave_offset;
    
    // Add diagonal flow for more dynamic movement
    stripe_pos += uv.x * 0.2 + time * flow_speed * 0.1;
    
    // Normalize to 0-1 range
    stripe_pos = fract(stripe_pos);
    
    // Get base pride colors
    vec3 pride_color = get_blended_pride_color(pride_flag, stripe_pos);
    
    // Add holographic shimmer effect
    if (holographic_effect) {
        float hologram = sin(uv.x * 20.0 + time * shimmer_speed) * 
                        cos(uv.y * 15.0 + time * shimmer_speed * 1.2);
        hologram = hologram * 0.5 + 0.5;
        
        // Shift colors slightly for holographic effect
        vec3 hologram_shift = get_blended_pride_color(pride_flag, stripe_pos + hologram * 0.1);
        pride_color = mix(pride_color, hologram_shift, hologram * 0.3);
    }
    
    // Add sparkles
    float sparkles = 0.0;
    if (add_sparkles) {
        vec2 sparkle_uv = uv * sparkle_density;
        vec2 sparkle_grid = floor(sparkle_uv);
        vec2 sparkle_fract = fract(sparkle_uv);
        
        float sparkle_hash = hash21(sparkle_grid);
        float sparkle_timing = fract(sparkle_hash * 10.0 + time * 2.0);
        
        // Create twinkling sparkles
        if (sparkle_hash > 0.95) {
            float sparkle_dist = length(sparkle_fract - 0.5);
            float sparkle_intensity = (sin(sparkle_timing * 6.28) + 1.0) * 0.5;
            sparkles = (1.0 - smoothstep(0.0, 0.3, sparkle_dist)) * sparkle_intensity;
        }
    }
    
    // Rim lighting effect for extra glow
    vec3 normal = normalize(NORMAL);
    float rim = 1.0 - max(dot(normal, view_dir), 0.0);
    rim = pow(rim, 2.0);
    
    // Final color composition
    vec3 final_color = pride_color;
    
    // Add sparkle highlights
    final_color = mix(final_color, vec3(1.0), sparkles * 0.8);
    
    // Add rim glow
    final_color += rim * pride_color * 0.5;
    
    // Color intensity boost
    final_color *= color_blend;
    
    ALBEDO = final_color;
    ALPHA = transparency * (0.8 + sparkles * 0.2 + rim * 0.3);
    EMISSION = final_color * glow_strength * (0.5 + sparkles * 0.5);
    
    // Slight roughness variation for interesting light interaction
    ROUGHNESS = 0.1 + sparkles * 0.2;
    METALLIC = 0.1;
}