shader_type spatial;
render_mode cull_disabled, diffuse_toon, specular_schlick_ggx;

uniform vec4 color_top = vec4(1.0, 0.5, 0.0, 1.0);      // Orange top color
uniform vec4 color_mid = vec4(1.0, 1.0, 1.0, 1.0);        // White mid color
uniform vec4 color_bottom = vec4(1.0, 0.0, 1.0, 1.0);     // Pink bottom color
uniform vec4 color_black_line = vec4(0.0, 0.0, 0.0, 1.0); // Black stripe

// Uniforms for vertical shifting.
uniform float base_shift_y : hint_range(-0.5, 0.5) = 0.0;      // Base vertical offset.
uniform float oscillation_amplitude : hint_range(0.0, 0.5) = 0.1; // Amplitude of oscillation.
uniform float oscillation_speed : hint_range(0.0, 10.0) = 1.0;    // Speed of oscillation.

void fragment() {
    // Get the UV coordinates.
    vec2 uv = UV.xy;

    // Compute oscillation based on time.
    float oscillation = sin(TIME * oscillation_speed) * oscillation_amplitude;
    uv.y += base_shift_y + oscillation;

    // Define the height segments for different colors.
    float top_segment = 0.3;    // Orange section size.
    float mid_segment = 0.55;   // Mid section size.
    float black_line_pos = 0.5; // Position of the black stripe.

    // Determine the color based on the (shifted) uv.y.
    if (uv.y < top_segment) {
        ALBEDO = mix(color_top.rgb, color_mid.rgb, uv.y / top_segment);
    } else if (uv.y > mid_segment) {
        ALBEDO = mix(color_mid.rgb, color_bottom.rgb, (uv.y - mid_segment) / (1.0 - mid_segment));
    } else {
        ALBEDO = color_mid.rgb;
    }

    // Overlay the black stripe.
    if (abs(uv.y - black_line_pos) < 0.02) {
        ALBEDO = color_black_line.rgb;
    }
}
