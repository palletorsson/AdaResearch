shader_type spatial;
render_mode depth_draw_always, cull_back;
// Disco Grid Shader - Emissive tiles with Complementary Base Color

// Uniforms
uniform vec4 modelColor : source_color = vec4(0.0, 0.0, 0.0, 1.0);       // Background color (Black)
uniform float emission_strength : hint_range(0.0, 20.0) = 5.0;           // Emission intensity

// Barycentric coordinates (kept for wireframe if needed, but we focus on flat tile glow)
varying vec4 instanceColor;  // Pass instance color from MultiMesh

void vertex() {
    // Pass instance color (from MultiMesh) to fragment shader
    instanceColor = COLOR;
}

void fragment() {
    // 1. Determine "Active" Color (The Emission)
    vec3 emission_color = instanceColor.rgb;
    
    // 2. Determine "Base" Color (The Albedo)
    // User wants "Opposite" color.
    // We calculate complementary color: 1.0 - RGB.
    // Pink (1,0,1) -> Green (0,1,0).
    vec3 complementary_color = vec3(1.0) - emission_color;
    
    // 3. Handle "Off" state
    // If the instance color is very dark (Black/Off), we want the tile to be Black (modelColor), NOT White (complementary of black).
    // We use brightness to blend.
    float brightness = max(max(emission_color.r, emission_color.g), emission_color.b);
    
    // Smooth blending: If brightness < 0.2, fade to Black. If > 0.2, fade to Complementary.
    // Using a steep curve to make it "snap" or smooth-step? Let's use smoothstep for organic transition.
    float on_factor = smoothstep(0.1, 0.3, brightness);
    
    // Mix Black -> Complementary
    vec3 base_albedo = mix(modelColor.rgb, complementary_color, on_factor);
    
    // 4. Output
    ALBEDO = base_albedo;
    
    // Emission is driven by the instance color directly
    EMISSION = emission_color * emission_strength;
}
