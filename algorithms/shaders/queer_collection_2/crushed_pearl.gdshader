shader_type spatial;

// Agent-QueerFabricator: Crushed Pearl Hologram
// Aesthetic: Powder drag refractance.
// Poetics: Glamour as a mathematical singularity.
// Technique: Diffraction grating simulation via spectral noise.

uniform vec3 base_pearl_color : source_color = vec3(0.9, 0.9, 0.95);
uniform float roughness : hint_range(0.0, 1.0) = 0.2;
uniform float metallic : hint_range(0.0, 1.0) = 0.1;

uniform float diffraction_scale = 50.0;
uniform float diffraction_brightness = 2.0;

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
    // Base Pearl look
    ALBEDO = base_pearl_color;
    ROUGHNESS = roughness;
    METALLIC = metallic;
    
    // View dependent vector
    vec3 view_dir = normalize(VIEW);
    vec3 normal_dir = normalize(NORMAL);
    
    // Diffraction Grating Effect
    // We use the viewing angle relative to the surface + high freq noise position
    // to determine the "phase" of the light, creating localized rainbows.
    
    float angle = dot(view_dir, normal_dir);
    
    // High frequency variation based on position (the "dust" particles)
    float dust_noise = sin(UV.x * diffraction_scale) * cos(UV.y * diffraction_scale);
    
    // Combine angle and dust to shift hue
    float hue = fract(angle * 2.0 + dust_noise + TIME * 0.1);
    
    // Create the hologram sparkles
    // Only appear at certain angles or "glints"
    float glint = smoothstep(0.9, 1.0, sin(dust_noise * 10.0 + angle * 20.0));
    
    vec3 holo_color = hsv2rgb(vec3(hue, 0.8, 1.0));
    
    // Add to Emission
    EMISSION = holo_color * glint * diffraction_brightness;
    
    // Add a general pearlescent rim
    float rim = 1.0 - clamp(angle, 0.0, 1.0);
    ALBEDO += vec3(rim * 0.2, rim * 0.1, rim * 0.3);
}
