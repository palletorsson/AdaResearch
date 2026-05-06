shader_type spatial;
render_mode blend_add, cull_disabled, unshaded, depth_draw_never;

uniform vec4 laser_color : source_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform float energy = 2.0;
uniform float speed = 1.0;
uniform sampler2D noise_texture;

void fragment() {
    // Scroll noise along UV.y (length of cylinder)
    vec2 uv_scroll = UV;
    uv_scroll.y -= TIME * speed;
    
    // Sample noise
    float noise = texture(noise_texture, uv_scroll).r;
    
    // Make edges softer (horizontal fade)
    float side_fade = 1.0 - abs((UV.x - 0.5) * 2.0);
    side_fade = pow(side_fade, 2.0);
    
    // Fade at end of beam (vertical fade)
    float end_fade = smoothstep(0.0, 0.2, UV.y) * smoothstep(1.0, 0.8, UV.y);
    
    // Composition
    vec3 col = laser_color.rgb * energy;
    float alpha = laser_color.a * noise * side_fade * end_fade;
    
    ALBEDO = col;
    ALPHA = alpha;
}
