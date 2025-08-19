shader_type spatial;

// Performance-optimized shader with only essential uniforms
uniform float time_scale : hint_range(0.0, 1.0) = 0.2;
uniform float segment_width : hint_range(5.0, 50.0) = 20.0;
uniform vec3 background_color : source_color = vec3(0.8, 0.8, 0.8);
uniform vec3 block_color : source_color = vec3(1.0, 0.3, 0.0);
// Custom time value that can be set from script to freeze at a specific pattern
uniform float custom_time = -1.0; // -1 means use the built-in TIME
// Virtual resolution for consistent sizing regardless of mesh dimensions
uniform vec2 virtual_resolution = vec2(1024.0, 256.0);

// A simple pseudo-random function
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = UV;

    // Use custom_time if set, otherwise use built-in TIME
    float current_time = custom_time > 0.0 ? custom_time : TIME;

    // Create a tiled effect where each tile can have a different pattern
    float seed_time = floor(current_time * time_scale);

    // Map UV to virtual resolution coordinates
    vec2 virtual_pos = uv * virtual_resolution;

    // Calculate position within the segment width
    float x_pos = virtual_pos.x;
    float segment_pos = mod(x_pos, segment_width);
    float segment_idx = floor(x_pos / segment_width);

    // Generate random values for this segment
    vec2 segment_seed = vec2(segment_idx, seed_time);
    float offset = 5.0 + random(segment_seed) * 10.0;
    float block_height = 20.0 + random(segment_seed + vec2(1.0, 0.0)) * (virtual_resolution.y - 20.0);
    float block_y_pos = random(segment_seed + vec2(0.0, 1.0)) * (virtual_resolution.y - block_height);

    // Calculate the next segment position and determine if we're in a gap
    float x_in_pattern = mod(x_pos, segment_width + offset);
    bool in_gap = x_in_pattern > segment_width;

    // Check if we're in a colored block
    float y_pos = virtual_pos.y;
    bool in_block = !in_gap && (y_pos >= block_y_pos && y_pos <= block_y_pos + block_height);

    // Set color based on whether we're in a block or not
    vec3 color = in_block ? block_color : background_color;

    ALBEDO = color;
}