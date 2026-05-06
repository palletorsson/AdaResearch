shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float flow_speed : hint_range(0.0, 5.0) = 0.001;
uniform float dissipation : hint_range(0.9, 1.0) = 0.995;

void fragment() {
    // Current UV coordinate
    vec2 uv = SCREEN_UV;
    vec2 pixel_size = SCREEN_PIXEL_SIZE;
    
    // Simulate flow by sampling from slightly above
    vec2 flow_uv = uv - vec2(0.0, flow_speed);
    
    // Diffusion: Sample 5 points (Center + Neighbors) to blur
    vec4 total_color = vec4(0.0);
    vec2 offsets[5] = vec2[](
        vec2(0.0, 0.0),
        vec2(1.0, 0.0),
        vec2(-1.0, 0.0),
        vec2(0.0, 1.0),
        vec2(0.0, -1.0)
    );
    // Weights for gaussian-ish blur
    // Increased neighbor weights for MORE SPREAD (Faster diffusion)
    // Center: 0.2, Neighbors: 0.2 each (Total 1.0)
    float weights[5] = float[](0.2, 0.2, 0.2, 0.2, 0.2);
    
    for (int i = 0; i < 5; i++) {
        vec2 sample_uv = flow_uv + offsets[i] * pixel_size * 1.0; // 1.0 = blur radius
        
        vec4 sample_color;
        // Check bounds for each sample
        if (sample_uv.y < 0.0 || sample_uv.x < 0.0 || sample_uv.x > 1.0) {
            sample_color = vec4(1.0); // White paper
        } else {
            sample_color = texture(screen_texture, sample_uv);
        }
        total_color += sample_color * weights[i];
    }
    
    vec4 prev_color = total_color;
    
    // Apply dissipation: Fade towards WHITE
    vec4 color = mix(vec4(1.0), prev_color, dissipation);
    
    COLOR = color;
}
