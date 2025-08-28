shader_type spatial;

uniform float time;
uniform vec2 resolution;
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform vec2 grid_size = vec2(4.0, 4.0); // Grid size controls the number of repeats

void fragment() {
    // Scale UV coordinates based on grid size
    vec2 scaled_uv = UV * grid_size;

    // Wrap the UVs to create a repeating pattern
    vec2 repeat_uv = fract(scaled_uv);

    // Offset UVs dynamically over time for a dynamic effect (optional)
    vec2 offset = vec2(0.05 * sin(time), 0.05 * cos(time));
    repeat_uv += offset;

    // Sample the screen texture using the modified UVs
    vec4 screen_color = texture(screen_texture, repeat_uv);

    // Assign the resulting color to the fragment
    ALBEDO = screen_color.rgb;
}
