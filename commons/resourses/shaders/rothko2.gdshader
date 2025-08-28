shader_type spatial;
render_mode cull_disabled, diffuse_toon, specular_schlick_ggx;

uniform vec4 color_top = vec4(1.0, 0.3, 0.1, 1.0);          // Deep red/orange for the top
uniform vec4 color_mid = vec4(1.0, 0.6, 0.4, 1.0);          // Light pink/orange for the mid
uniform vec4 color_bottom = vec4(1.0, 0.3, 0.1, 1.0);       // Similar deep red/orange for the bottom
uniform vec4 color_background = vec4(1.0, 0.7, 0.2, 1.0);   // Yellow-orange background

uniform float speed = 1.0;       // Speed of color modulation
uniform float osc_amp : hint_range(0.0, 0.1) = 0.05; // Amplitude of color oscillation

void fragment() {
    vec2 uv = UV.xy;

    // Define height segments (these remain fixed).
    float top_segment = 0.25;    // Top section threshold.
    float mid_segment = 0.65;    // Middle section threshold.
    float bottom_segment = 1.0;  // Bottom section threshold.

    // Compute modulated colors.
    // Each color is perturbed slightly over time.
    vec3 mod_top = color_top.rgb + osc_amp * vec3(sin(TIME * speed),
                                                  cos(TIME * speed),
                                                  sin(TIME * speed * 0.5));

    vec3 mod_mid = color_mid.rgb + osc_amp * vec3(cos(TIME * speed * 0.8),
                                                  sin(TIME * speed * 0.8),
                                                  cos(TIME * speed * 0.4));

    vec3 mod_bottom = color_bottom.rgb + osc_amp * vec3(sin(TIME * speed * 0.6),
                                                        cos(TIME * speed * 0.6),
                                                        sin(TIME * speed * 0.3));

    vec3 mod_bg = color_background.rgb + osc_amp * vec3(cos(TIME * speed * 0.7),
                                                        sin(TIME * speed * 0.7),
                                                        cos(TIME * speed * 0.35));

    // Determine the final color based on the original uv.y value.
    vec3 final_color = mod_bg;
    if (uv.y < top_segment) {
        final_color = mix(mod_bg, mod_top, uv.y / top_segment);
    }
    else if (uv.y >= top_segment && uv.y < mid_segment) {
        final_color = mix(mod_top, mod_mid, (uv.y - top_segment) / (mid_segment - top_segment));
    }
    else { // uv.y >= mid_segment
        final_color = mix(mod_mid, mod_bottom, (uv.y - mid_segment) / (bottom_segment - mid_segment));
    }

    // Optional: if you still want to overlay a fixed black stripe (not oscillating) at a fixed position.
    if (abs(uv.y - 0.5) < 0.02) {
        final_color = vec3(0.0);
    }

    ALBEDO = final_color;
}
