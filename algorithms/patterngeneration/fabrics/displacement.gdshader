shader_type spatial;

// Author @kyndinfo - 2016 (Converted to Godot 4 Spatial)
// http://www.kynd.info
// Title: Displacement - Spatial Version

uniform float time_scale : hint_range(0.0, 3.0) = 0.5;
uniform float cell_scale : hint_range(0.5, 20.0) = 5.0;
uniform float displacement_strength : hint_range(0.0, 2.0) = 0.5;
uniform float animation_speed : hint_range(0.0, 5.0) = 1.0;
uniform float vertex_displacement : hint_range(0.0, 1.0) = 0.1;

// Material properties
uniform vec3 base_color : source_color = vec3(0.8, 0.8, 0.8);
uniform float roughness : hint_range(0.0, 1.0) = 0.3;
uniform float metallic : hint_range(0.0, 1.0) = 0.2;
uniform float emission_strength : hint_range(0.0, 2.0) = 0.3;
uniform float base_alpha = 0.5;
// Color channels for displacement effect
uniform vec3 color_r : source_color = vec3(1.0, 0.2, 0.2);
uniform vec3 color_g : source_color = vec3(0.2, 1.0, 0.2);
uniform vec3 color_b : source_color = vec3(0.2, 0.2, 1.0);

uniform bool animate  = true;
uniform bool use_vertex_displacement   = true;
uniform bool use_full_color  = false;
uniform bool use_pattern_alpha  = false;
const float pattern_alpha_influence = 0.5;
const float edge_fade = 0.5;

float random(in vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

vec2 random2(vec2 p) {
    return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

float cellular(vec2 p) {
    vec2 i_st = floor(p);
    vec2 f_st = fract(p);
    float m_dist = 10.0;

    for (int j = -1; j <= 1; j++) {
        for (int i = -1; i <= 1; i++) {
            vec2 neighbor = vec2(float(i), float(j));
            vec2 point = random2(i_st + neighbor);

            // Animate the cellular pattern
            if (animate) {
                point = 0.5 + 0.5 * sin(6.2831 * point + TIME * animation_speed);
            } else {
                point = 0.5 + 0.5 * sin(6.2831 * point);
            }

            vec2 diff = neighbor + point - f_st;
            float dist = length(diff);

            if (dist < m_dist) {
                m_dist = dist;
            }
        }
    }
    return m_dist;
}

void vertex() {
    if (use_vertex_displacement) {
        vec2 st = UV * cell_scale;
        float time_offset = animate ? TIME * time_scale : 0.0;

        // Use cellular noise for vertex displacement
        float displacement = cellular(st + time_offset);
        VERTEX += NORMAL * displacement * vertex_displacement;
    }
}

void fragment() {
    vec2 st = UV * cell_scale;

    // Calculate time offset for displacement
    float time_offset = animate ? TIME * time_scale : 0.0;

    // Calculate cellular noise values
    float r = cellular(st);
    float g = cellular(st + vec2(displacement_strength, 0.0)); // Horizontal displacement
    float b = cellular(st - vec2(0.0, sin(time_offset) * displacement_strength)); // Vertical displacement

    vec3 final_color;

    if (use_full_color) {
        // Use custom color channels
        final_color = base_color * (r * color_r + g * color_g + b * color_b);
    } else {
        // Original red-blue displacement effect
        final_color = base_color * vec3(r, 0.5, b);
    }

    ALBEDO = final_color;
    ROUGHNESS = roughness;
    METALLIC = metallic;
    EMISSION = final_color * emission_strength;

    // Calculate transparency based on cellular patterns
    float alpha = base_alpha;

    if (use_pattern_alpha) {
        // Use cellular pattern to influence transparency
        float pattern_intensity = (r + g + b) / 3.0;
        alpha = mix(base_alpha * (1.0 - pattern_alpha_influence), base_alpha, pattern_intensity);
    }

    // Add edge fade effect based on UV coordinates
    if (edge_fade > 0.0) {
        vec2 edge_dist = min(UV, 1.0 - UV);
        float edge_factor = min(edge_dist.x, edge_dist.y);
        float fade_factor = smoothstep(0.0, edge_fade, edge_factor);
        alpha *= fade_factor;
    }

    ALPHA = alpha;

    // Add subtle normal mapping based on cellular pattern
    vec3 normal_variation = vec3(r - 0.5, g - 0.5, 0.5) * 0.5 + 0.5;
    NORMAL_MAP = normal_variation;
}