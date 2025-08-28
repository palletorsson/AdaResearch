shader_type spatial;

uniform vec3 color_yellow = vec3(1.0, 0.8, 0.0);
uniform vec3 color_red  = vec3(1.0, 0.0, 0.0);
uniform vec3 color_black = vec3(0.0, 0.0, 0.0);

uniform float grid_scale = 4.0; // Scale of the tartan grid
uniform float line_width = 0.1; // Thickness of the lines
uniform float stripe_width = 0.05; // Thickness of diagonal stripes

void fragment() {
    vec2 uv = UV * grid_scale; // Scale the UV coordinates for the grid
    vec2 grid = fract(uv); // Get the repeating grid pattern
    vec3 color = color_yellow; // Default color is yellow

    // Horizontal and vertical black lines
    if (grid.x < line_width || grid.y < line_width) {
        color = color_black;
    }

    // Red cross lines
    if (abs(grid.x - 0.5) < line_width || abs(grid.y - 0.5) < line_width) {
        color = color_red;
    }

    // Diagonal stripes (black)
    float diagonal = abs(grid.x - grid.y);
    if (diagonal < stripe_width || abs(grid.x + grid.y - 1.0) < stripe_width) {
        color = color_black;
    }

    ALBEDO = color;
}
