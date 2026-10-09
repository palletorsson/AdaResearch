shader_type spatial;

uniform vec3 base_color : source_color = vec3(0.8, 0.1, 0.1);
uniform vec3 dot_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float dot_size : hint_range(0.0, 1.0) = 0.3;
uniform float dot_spacing : hint_range(1.0, 20.0) = 10.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.5;
uniform float specular : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    vec2 uv = UV * dot_spacing;
    vec2 fpos = fract(uv);
    
    // Offset every other row for a hexagonal/staggered pattern
    if (int(floor(uv.y)) % 2 != 0) {
        fpos.x = fract(uv.x + 0.5);
    }
    
    float dist = distance(fpos, vec2(0.5));
    float spot = step(dist, dot_size);
    
    ALBEDO = mix(base_color, dot_color, spot);
    ROUGHNESS = roughness;
    SPECULAR = specular;
    
    // Add a little normal perturbation for the dots
    if (spot > 0.5) {
        // Simple fake normal map for the dot bump
        vec2 center = vec2(0.5);
        vec2 dir = normalize(fpos - center);
        float slope = cos(dist * 3.14159 / dot_size);
        NORMAL = normalize(NORMAL + vec3(dir.x * slope * 0.5, dir.y * slope * 0.5, 1.0));
    }
}
