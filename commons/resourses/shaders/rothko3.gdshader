shader_type spatial;
render_mode cull_disabled, diffuse_toon, specular_schlick_ggx;
uniform vec4 color_top = vec4(1.0, 0.4, 0.0, 1.0); // Orange top color
uniform vec4 color_mid = vec4(1.0, 0.2, 0.5, 1.0); // Pink mid color
uniform vec4 color_bottom = vec4(0.0, 0.2, 1.0, 1.0); // Blue bottom color
uniform vec4 color_border = vec4(0.9, 0.7, 0.6, 1.0); // Light border around the sections
uniform vec4 color_drip = vec4(1.0, 0.3, 0.3, 1.0); // Red drips near the bottom

void fragment() {
    vec2 uv = UV.xy;

    // Define the height segments for different color regions
    float top_segment = 0.35;   // Orange section size
    float mid_segment = 0.65;   // Pink section size

    // Border effect to mimic roughness on edges
    float border_size = 0.02;

    // Orange top section
    if (uv.y < top_segment) {
        ALBEDO = mix(color_top.rgb, color_mid.rgb, uv.y / top_segment);
    }
    // Blue bottom section
    else if (uv.y > mid_segment) {
        ALBEDO = mix(color_mid.rgb, color_bottom.rgb, (uv.y - mid_segment) / (1.0 - mid_segment));
    }
    // Pink middle section
    else {
        ALBEDO = color_mid.rgb;
    }

    // Add a rough border effect for each section
    if (uv.y < border_size || uv.y > (1.0 - border_size)) {
        ALBEDO = mix(ALBEDO, color_border.rgb, 0.5);
    }

    // Add drip effect near the bottom
    if (uv.y > 0.95 && uv.x < 0.1) {
        ALBEDO = color_drip.rgb;
    }
}
