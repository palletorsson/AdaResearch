shader_type canvas_item;

// Cell structure properties
uniform float cell_density = 10.0;
uniform float outer_membrane_thickness = 0.05;
uniform float inner_membrane_thickness = 0.03;
uniform vec4 background_color : source_color = vec4(0.98, 0.95, 0.82, 1.0); // Cream background
uniform vec4 outer_membrane_color : source_color = vec4(0.85, 0.8, 0.55, 1.0); // Yellowish membrane
uniform vec4 inner_membrane_color : source_color = vec4(0.3, 0.3, 0.4, 1.0); // Dark gray inner membrane
uniform vec4 nucleus_color : source_color = vec4(0.2, 0.2, 0.35, 1.0); // Dark blue nucleus
uniform vec4 highlight_color : source_color = vec4(0.3, 0.35, 0.6, 1.0); // Blue highlight for some cells
uniform float random_seed = 43758.5453123;
uniform float nucleus_size_variance = 0.4;
uniform float deformation_amount = 0.2;
uniform bool circular_mask = true;
uniform float circular_mask_softness = 0.1;

// Animation properties
uniform float time_scale = 0.2; // Controls animation speed
uniform float flow_intensity = 0.15; // Controls how much cells flow
uniform float pulse_intensity = 0.1; // Controls nucleus pulsing
uniform float membrane_fluctuation = 0.02; // Controls membrane thickness variation

// Voronoi/cellular noise implementation
vec2 random2(vec2 p) {
    return fract(sin(vec2(
        dot(p, vec2(127.1, 311.7)),
        dot(p, vec2(269.5, 183.3))
    )) * random_seed);
}

// Distance function with animation and deformation
float cellular_distance(vec2 a, vec2 b, float seed, float time) {
    float dist = distance(a, b);
    
    // Add time-based deformation
    float deform_time = sin(time * time_scale + seed) * 0.5 + 0.5;
    float deform = sin(a.x * 10.0 + seed + time) * sin(a.y * 10.0 + seed - time) 
                  * deformation_amount * (0.8 + 0.4 * deform_time);
    
    return dist + deform;
}

// Create a flowing effect for cell positions
vec2 flow_offset(vec2 uv, float time, float seed) {
    // Create a gentle flowing motion
    float flow_x = sin(uv.y * 2.0 + time * 0.5) * flow_intensity;
    float flow_y = cos(uv.x * 2.0 + time * 0.4) * flow_intensity;
    
    // Add some variation based on position and seed
    flow_x += sin(uv.x * 3.0 + seed + time * 0.3) * flow_intensity * 0.3;
    flow_y += cos(uv.y * 3.0 + seed - time * 0.2) * flow_intensity * 0.3;
    
    return vec2(flow_x, flow_y);
}

void fragment() {
    // Get animation time from shader globals
    float time = TIME;
    
    // Scale UV based on cell density
    vec2 scaled_uv = UV * cell_density;
    
    // Keep track of closest and second closest distances
    float min_dist = 1.0;
    float second_min_dist = 1.0;
    vec2 closest_point = vec2(0.0);
    float point_id = 0.0;
    
    // Check neighboring cells in a 3x3 grid
    for(int y = -1; y <= 1; y++) {
        for(int x = -1; x <= 1; x++) {
            vec2 neighbor = vec2(float(x), float(y));
            vec2 cell_point = floor(scaled_uv) + neighbor;
            
            // Add seed-based identifier for this cell
            float cell_seed = dot(cell_point, vec2(13.0, 7.0));
            
            // Generate random point in the cell with flowing motion
            vec2 random_point = cell_point + random2(cell_point);
            
            // Add flowing animation to the point position
            random_point += flow_offset(random_point, time, cell_seed);
            
            // Compute distance to the point with animated deformation
            float dist = cellular_distance(scaled_uv, random_point, cell_seed, time);
            
            // Update minimum distances
            if(dist < min_dist) {
                second_min_dist = min_dist;
                min_dist = dist;
                closest_point = random_point;
                point_id = dot(cell_point, vec2(1.0, 57.0));
            } else if(dist < second_min_dist) {
                second_min_dist = dist;
            }
        }
    }
    
    // Calculate cell borders by comparing distances
    float border = second_min_dist - min_dist;
    
    // Animate membrane thickness
    float membrane_time = sin(time * 0.7 + point_id * 0.1) * 0.5 + 0.5;
    float animated_outer_thickness = outer_membrane_thickness * (1.0 + membrane_fluctuation * membrane_time);
    
    // Outer cell membrane
    float outer_membrane = 1.0 - smoothstep(0.0, animated_outer_thickness, border);
    
    // Animate nucleus size with a gentle pulse
    float pulse_time = sin(time * 0.5 + point_id * 0.2) * 0.5 + 0.5;
    float nucleus_base_size = 0.3 + 0.4 * fract(sin(point_id * 123.456) * 43758.5453) * nucleus_size_variance;
    float nucleus_size = nucleus_base_size * (1.0 + pulse_intensity * pulse_time);
    
    // Inner cell areas - nucleus
    float nucleus = 1.0 - smoothstep(0.0, nucleus_size, min_dist);
    
    // Animate inner membrane thickness
    float inner_time = cos(time * 0.6 + point_id * 0.3) * 0.5 + 0.5;
    float animated_inner_thickness = inner_membrane_thickness * (1.0 + membrane_fluctuation * 1.5 * inner_time);
    
    // Inner membrane around the nucleus
    float inner_membrane = 1.0 - smoothstep(0.0, animated_inner_thickness, min_dist - nucleus_size);
    inner_membrane *= step(nucleus_size + animated_inner_thickness, min_dist);
    
    // Determine cell colors based on point ID with subtle color shifting over time
    float color_shift = sin(time * 0.2 + point_id * 0.5) * 0.1 + 0.9;
    float use_highlight = step(0.8, fract(sin(point_id * 45.678) * 43758.5453));
    
    // Animate highlight color slightly
    vec4 animated_highlight = highlight_color;
    animated_highlight.b = highlight_color.b * (0.9 + 0.2 * sin(time * 0.8 + point_id));
    
    vec4 current_nucleus_color = mix(nucleus_color, animated_highlight, use_highlight * color_shift);
    
    // Apply colors
    vec4 color = background_color;
    color = mix(color, outer_membrane_color, outer_membrane);
    color = mix(color, inner_membrane_color, inner_membrane);
    color = mix(color, current_nucleus_color, nucleus);
    
    // Apply circular mask if enabled
    if (circular_mask) {
        // Animate the mask slightly
        float mask_pulse = sin(time * 0.3) * 0.02;
        vec2 center_uv = UV - 0.5;
        float dist_from_center = length(center_uv);
        float circle_mask = 1.0 - smoothstep(0.45 + mask_pulse, 0.45 + circular_mask_softness + mask_pulse, dist_from_center);
        color = mix(background_color, color, circle_mask);
    }
    
    COLOR = color;
}