shader_type spatial;

// Agent-QueerFabricator: Melted Candy Hardlight
// Aesthetic: Sugar glass with refraction tears.
// Poetics: Sweetness pushed past structural integrity.
// Technique: Chromatic aberration, refraction, "melting" vertex displacement.

uniform vec3 candy_color : source_color = vec3(1.0, 0.2, 0.5); // Hot pink/red
uniform float roughness : hint_range(0.0, 1.0) = 0.05; // Glassy
uniform float refraction_strength : hint_range(0.0, 1.0) = 0.05;

uniform float melt_amount = 0.1;
uniform float melt_speed = 0.5;

void vertex() {
    // Melting effect: Displace vertices downwards based on time and position
    // In a real game, we'd use world coordinates, here local is fine for demo
    float melt_wave = sin(VERTEX.x * 5.0 + TIME * melt_speed) * 0.5 + 0.5;
    
    // Push vertices down (negative Y) slightly
    VERTEX.y -= melt_wave * melt_amount;
    
    // Bulge outwards slightly as it melts
    VERTEX.x += (melt_wave * melt_amount * 0.2) * sign(VERTEX.x);
    VERTEX.z += (melt_wave * melt_amount * 0.2) * sign(VERTEX.z);
}

void fragment() {
    ALBEDO = candy_color;
    ROUGHNESS = roughness;
    METALLIC = 0.0;
    
    // Fake internal "glow" or hardlight scattering
    EMISSION = candy_color * 0.2;
    
    // Transmission / Refraction
    // Godot 4 handles refraction nicely via properties, but for raw transmission we use BACKLIGHT
    BACKLIGHT = candy_color;
    
    // Chromatic Aberration / Spectral approximation in albedo/emission?
    // Hard to do real chromatic aberration in standard shader without screen reading.
    // We can fake it by tinting based on normal angle
    float NdotV = dot(normalize(NORMAL), normalize(VIEW));
    vec3 aberration = vec3(0.0);
    aberration.r = smoothstep(0.0, 0.2, NdotV); // Red at edges
    aberration.b = smoothstep(0.8, 1.0, NdotV); // Blue at center
    
    ALBEDO += aberration * 0.2;
    
    // Make it look sticky/specular
    SPECULAR = 1.0;
}
