shader_type spatial;
render_mode unshaded, blend_add, cull_disabled;

uniform vec4 ring_color : source_color = vec4(0.92, 0.92, 0.92, 0.2);
uniform vec4 dot_idle_color : source_color = vec4(0.6, 0.6, 0.6, 1.0);
uniform vec4 dot_active_color : source_color = vec4(0.85, 0.1, 0.38, 1.0);

uniform float ring_radii[8];
uniform float phases[8];
uniform float active_timers[8]; // 0 to 1 range
uniform int loop_count = 7;

float sdCircle(vec2 p, float r) {
    return length(p) - r;
}

void fragment() {
    // Center UV at 0,0 and scale to -3..3 range to accommodate radii
    vec2 uv = (UV * 2.0 - 1.0) * 3.0;
    
    vec3 final_color = vec3(0.0);
    float final_alpha = 0.0;

    // Background faint center glow
    float dist = length(uv);
    final_color += vec3(0.05, 0.05, 0.1) * exp(-dist * 2.0);

    for (int i = 0; i < loop_count; i++) {
        float r = ring_radii[i];
        
        // --- 1. Draw Ring ---
        float ring_sdf = abs(length(uv) - r) - 0.01;
        float ring_mask = smoothstep(0.02, 0.0, ring_sdf);
        final_color += ring_color.rgb * ring_mask * ring_color.a;

        // --- 2. Draw Dot ---
        // Calculate dot position based on phase
        // Phase 0 starts at Right (Playhead)
        float angle = -phases[i] * 6.283185 + 3.14159; 
        vec2 dot_pos = vec2(cos(angle), sin(angle)) * r;
        
        float dot_size = 0.06 + active_timers[i] * 0.04;
        float dot_sdf = length(uv - dot_pos) - dot_size;
        float dot_mask = smoothstep(0.02, 0.0, dot_sdf);
        
        vec3 d_col = mix(dot_idle_color.rgb, dot_active_color.rgb, active_timers[i]);
        float d_glow = exp(-length(uv - dot_pos) * 10.0) * active_timers[i] * 2.0;
        
        final_color += (d_col * dot_mask) + (dot_active_color.rgb * d_glow);
    }

    ALBEDO = final_color;
    ALPHA = clamp(length(final_color) * 2.0, 0.0, 1.0);
}
