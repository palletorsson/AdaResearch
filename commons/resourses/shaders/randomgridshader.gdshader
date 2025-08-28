shader_type spatial;

// Tile size for the grid
uniform float tile_size = 1.0;
uniform vec3 color1 = vec3(1.0, 1.0, 1.0); // White
uniform vec3 base_grey = vec3(0.5, 0.5, 0.5); // Base Grey
uniform float grey_variation = 0.1;  // Maximum variation for grey tiles

// Simple hash function to generate pseudo-random values
float random(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    // Get the world position in X and Z (for the floor)
    vec2 world_pos = UV / tile_size;

    // Floor to get the tile grid coordinates
    vec2 grid_pos = floor(world_pos);

    // Calculate the parity (alternating pattern)
    float checker_pattern = mod(grid_pos.x + grid_pos.y, 2.0);

    // Add a random variation to the grey color for each grey tile
    vec3 varied_grey = base_grey + (random(grid_pos) - 0.5) * grey_variation;

    // Ensure the grey stays within 0 to 1 range
    varied_grey = clamp(varied_grey, 0.0, 1.0);

    // Choose between the white color and the varied grey color based on the checker pattern
    vec3 tile_color = mix(color1, varied_grey, checker_pattern);

    // Set the fragment color
    ALBEDO = tile_color;
}
