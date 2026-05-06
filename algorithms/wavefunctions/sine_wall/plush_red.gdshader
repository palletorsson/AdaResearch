shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled;

uniform vec4 albedo : source_color = vec4(0.5, 0.0, 0.1, 0.85); // Deep red, slightly transparent
uniform float roughness : hint_range(0.0, 1.0) = 0.85;
uniform float rim_power : hint_range(0.0, 10.0) = 2.5;
uniform float rim_intensity : hint_range(0.0, 1.0) = 0.6;
uniform vec4 rim_color : source_color = vec4(1.0, 0.2, 0.3, 1.0); // Pinkish rim

void fragment() {
    // Base color mixed with vertex color for some variation if needed, 
    // but keeping it mostly the uniform red for the "heavy plush" look.
    // We can multiply by COLOR to let the wave height affect brightness slightly.
    vec3 base_col = albedo.rgb * (0.5 + 0.5 * COLOR.rgb); 
    
    ALBEDO = base_col;
    ALPHA = albedo.a;
    
    ROUGHNESS = roughness;
    
    // Fresnel / Rim effect for plush look (velvet)
    // The dot product of Normal and View gives us the angle. 
    // 1.0 - dot gives us the edge.
    float fresnel = pow(clamp(1.0 - dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
    vec3 rim = rim_color.rgb * fresnel * rim_intensity;
    
    // Add rim to emission to make it pop like velvet
    EMISSION = rim;
}
