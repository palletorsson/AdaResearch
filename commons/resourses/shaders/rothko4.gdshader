shader_type spatial;
render_mode cull_disabled, diffuse_toon, specular_schlick_ggx;

// Base colors for different segments
uniform vec4 color_top = vec4(0.1, 0.1, 0.1, 1.0);       // Dark top color
uniform vec4 color_bottom = vec4(1.0, 0.4, 0.0, 1.0);      // Orange bottom color
uniform vec4 color_border = vec4(0.9, 0.7, 0.6, 1.0);      // Light border color

// Parameters for the base gradient
uniform float top_segment = 0.45;     // Top section threshold
uniform float border_size = 0.03;     // Border thickness

// Parameters for blur over time
uniform float blur_speed : hint_range(0.0, 1.0) = 0.05;   // How quickly blur increases
// The effective blur amount increases linearly with time.
 
void fragment() {
    vec2 uv = UV.xy;
    
    // Calculate blur amount based on time (only affecting color blending)
    float blur_amount = TIME * blur_speed;
    
    // We'll average color samples from a 3x3 kernel.
    vec3 color_sum = vec3(0.0);
    int samples = 0;
    
    // Loop over a 3x3 grid. The offsets are scaled by the blur_amount.
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            vec2 offset = vec2(float(i), float(j)) * blur_amount;
            vec2 sample_uv = uv + offset;
            
            // Compute base color for this sample (using same gradient logic)
            vec3 sample_color;
            if (sample_uv.y < top_segment) {
                sample_color = color_top.rgb;
            } else {
                sample_color = color_bottom.rgb;
            }
            
            // Apply a border blend if near the edge (using sample_uv, not modified)
            if (sample_uv.y < border_size || sample_uv.y > (1.0 - border_size) ||
                sample_uv.x < border_size || sample_uv.x > (1.0 - border_size)) {
                sample_color = mix(sample_color, color_border.rgb, 0.7);
            }
            
            color_sum += sample_color;
            samples += 1;
        }
    }
    
    // Average the colors
    ALBEDO = color_sum / float(samples);
}
