shader_type spatial;

// Agent-QueerFabricator: Sad Metal
// Aesthetic: Soft-reflective alloy with emotional curvature.
// Poetics: The metal that sighs.
// Technique: Anisotropic roughness + "Tear" streaks.

uniform vec3 metal_color : source_color = vec3(0.7, 0.7, 0.8); // Blue-ish chrome
uniform float base_roughness : hint_range(0.0, 1.0) = 0.2;
uniform float metallic : hint_range(0.0, 1.0) = 0.9;

uniform sampler2D tear_noise : hint_default_white;
uniform float tear_scale = 2.0;
uniform float tear_speed = 0.05;

void fragment() {
    ALBEDO = metal_color;
    METALLIC = metallic;
    
    // Tears: Vertical streaks running down (assuming UV y is down or using world coords)
    // We stretch UVs vertically to make streaks
    vec2 uv_tears = UV * vec2(1.0, 0.2) * tear_scale;
    
    // Scroll them downwards
    float flow = texture(tear_noise, uv_tears + vec2(0.0, -TIME * tear_speed)).r;
    
    // Use the flow to modulate roughness
    // "Wet" areas (tears) are smoother (lower roughness)
    // "Dry" areas are rougher
    float tear_mask = smoothstep(0.4, 0.6, flow);
    
    // Sadness is blurry (high roughness) but tears are clear (low roughness)
    float dynamic_roughness = mix(base_roughness + 0.3, 0.05, tear_mask);
    
    ROUGHNESS = dynamic_roughness;
    
    // Anisotropy: Brush direction follows the tears (vertical)
    ANISOTROPY = 0.5;
    ANISOTROPY_FLOW = vec2(0.0, 1.0); // Vertical flow
    
    // Slight color shift in the tears (melancholy blue)
    vec3 tear_tint = vec3(0.0, 0.1, 0.3);
    EMISSION = tear_tint * tear_mask * 0.2;
}
