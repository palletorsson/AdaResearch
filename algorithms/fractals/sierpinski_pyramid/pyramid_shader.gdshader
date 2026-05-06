shader_type spatial;

uniform vec3 base_color : source_color = vec3(0.1, 0.05, 0.2);
uniform vec3 glow_color : source_color = vec3(0.0, 1.0, 1.0);
uniform float rim_power : hint_range(0.1, 10.0) = 3.0;
uniform float pulse_speed : hint_range(0.1, 5.0) = 1.0;

void fragment() {
    // World space position for gradient effect
    vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
    
    // Fresnel effect for rim lighting
    float fresnel = pow(1.0 - dot(NORMAL, VIEW), rim_power);
    
    // Time-based pulsing
    float pulse = (sin(TIME * pulse_speed + world_pos.y) + 1.0) * 0.5;
    
    // Mix base color with pulse
    vec3 final_color = mix(base_color, glow_color * 0.5, pulse * 0.2);
    
    // Add rim glow
    final_color += glow_color * fresnel;
    
    ALBEDO = final_color;
    EMISSION = glow_color * fresnel * 2.0 + (glow_color * pulse * 0.5);
    ROUGHNESS = 0.2;
    METALLIC = 0.8;
}
