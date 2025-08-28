shader_type spatial;
render_mode cull_disabled, unshaded;
uniform vec2 grid_size  = vec2(10.0, 10.0); // Controls the grid density
uniform float split_height   = 0.5; // Split between grid and transparency
uniform vec4 grid_color = vec4(0.0, 0.0, 0.0, 0.8); // Color of the grid lines
uniform vec4 background_color = vec4(1.0, 1.0, 1.0, 0.0); // Background transparency

void fragment() {
    // UV coordinates
    vec2 uv = UV;

    // Determine if the fragment is in the grid (bottom part) or transparent (top part)
    if (uv.y < split_height) {
        // Bottom part: Grid pattern
        vec2 grid = fract(uv * grid_size);

        // Define the grid line thickness
        float line_width = 0.05;

        // Calculate if the fragment is on a grid line
        bool is_grid_line = grid.x < line_width || grid.y < line_width;

        if (is_grid_line) {
            ALBEDO = grid_color.rgb;
            ALPHA = grid_color.a;
        } else {
            ALBEDO = background_color.rgb;
            ALPHA = background_color.a;
        }
    } else {
        // Top part: Fully transparent
        ALPHA = 0.0;
    }
}
