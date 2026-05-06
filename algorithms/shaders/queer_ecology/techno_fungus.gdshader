shader_type spatial;

// Agent-Ecologist: Techno-Fungus
// Aesthetic: Cybernetic organism, fungal network, data-rot.
// Description: Voronoi patterns meeting digital grid lines.

uniform vec3 spore_color : source_color = vec3(0.1, 0.1, 0.2); // Dark base
uniform vec3 vein_color : source_color = vec3(0.0, 1.0, 0.8); // Cyan veins
uniform float cell_density = 10.0;
uniform float animate_speed = 1.0;

// Voronoi Noise Function
vec2 random2(vec2 p) {
    return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

float voronoi(vec2 uv, float time) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    float m_dist = 1.0;
    
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 neighbor = vec2(float(x), float(y));
            vec2 point = random2(i + neighbor);
            
            // Animate points
            point = 0.5 + 0.5 * sin(time + 6.2831 * point);
            
            vec2 diff = neighbor + point - f;
            float dist = length(diff);
            
            if (dist < m_dist) {
                m_dist = dist;
            }
        }
    }
    return m_dist;
}

void vertex() {
    // Slight displacement along normal based on vertex position
    VERTEX += NORMAL * sin(VERTEX.x * 5.0 + TIME * animate_speed) * 0.02;
}

void fragment() {
    float v = voronoi(UV * cell_density, TIME * animate_speed);
    
    // Invert voronoi for veins
    float veins = 1.0 - smoothstep(0.0, 0.1, v);
    
    // Digital grid overlay
    float grid = step(0.98, fract(UV.x * 20.0)) + step(0.98, fract(UV.y * 20.0));
    
    // Mix organic and digital
    vec3 organic = mix(spore_color, vein_color, veins);
    vec3 digital = vec3(1.0, 1.0, 1.0) * grid;
    
    ALBEDO = organic + digital * 0.2;
    
    // Pulse the veins
    EMISSION = vein_color * veins * (sin(TIME * 2.0) * 0.5 + 1.0) * 2.0 + digital * 0.5;
    
    ROUGHNESS = 0.1; // Slimy
}
