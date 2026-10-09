shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float flow_speed : hint_range(0.0, 5.0) = 0.001;
uniform float dissipation : hint_range(0.9, 1.0) = 0.995;
uniform bool spray_mode = false;
uniform bool clear_surface = false;
uniform float frame_delta = 0.0166667;
uniform float frame_seed = 0.0;
uniform vec4 ground_color : source_color = vec4(1.0);

void fragment() {
    // Current UV coordinate
    vec2 uv = SCREEN_UV;
    vec2 pixel_size = SCREEN_PIXEL_SIZE;
    
    // Simulate flow by sampling from slightly above
    float step_scale = spray_mode ? clamp(frame_delta, 0.0, 0.05) * 60.0 : 1.0;
    vec2 flow_uv = uv - vec2(0.0, flow_speed * step_scale);
    
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
        if (sample_uv.y < 0.0 || sample_uv.x < 0.0 || sample_uv.x > 1.0 || sample_uv.y > 1.0) {
            sample_color = spray_mode ? ground_color : vec4(1.0);
        } else {
            sample_color = texture(screen_texture, sample_uv);
        }
        total_color += sample_color * weights[i];
    }
    
    vec4 prev_color = total_color;
    if (spray_mode) {
        vec4 centre = ground_color;
        if (all(greaterThanEqual(flow_uv, vec2(0.0))) && all(lessThanEqual(flow_uv, vec2(1.0)))) {
            centre = texture(screen_texture, flow_uv);
        }
        // A little settling preserves the visible grain of aerosol deposits.
        prev_color = mix(centre, total_color, clamp(0.12 * step_scale, 0.0, 1.0));
    }
    
    // Apply dissipation: Fade towards WHITE
    vec4 color = mix(vec4(1.0), prev_color, dissipation);
    if (spray_mode) {
        color = mix(ground_color, prev_color, pow(dissipation, step_scale));
        // Stochastic rounding keeps slow changes from stalling in an 8-bit buffer.
        float rounding = fract(sin(dot(FRAGCOORD.xy, vec2(12.9898,78.233)) + frame_seed * 0.73) * 43758.5453);
        color.rgb = floor(clamp(color.rgb, vec3(0.0), vec3(1.0)) * 255.0 + rounding) / 255.0;
    }
    
    COLOR = clear_surface ? ground_color : color;
}
