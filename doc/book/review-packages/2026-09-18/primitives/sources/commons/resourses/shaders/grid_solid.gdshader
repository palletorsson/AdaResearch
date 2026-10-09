shader_type spatial;

// VR-compatible solid wireframe shader
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

// Uniforms
uniform vec4 base_color : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 edge_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float edge_width : hint_range(0.0, 10.0) = 1.5;
uniform float edge_sharpness : hint_range(0.1, 5.0) = 2.0;
uniform float emission_strength : hint_range(0.0, 5.0) = 1.0;

// Barycentric coordinates for edge detection
varying vec3 barycentric;

void vertex() {
    // Assign barycentric coordinates based on vertex index
    if (VERTEX_ID % 3 == 0) {
        barycentric = vec3(1.0, 0.0, 0.0);
    } else if (VERTEX_ID % 3 == 1) {
        barycentric = vec3(0.0, 1.0, 0.0);
    } else {
        barycentric = vec3(0.0, 0.0, 1.0);
    }
}

void fragment() {
    // Calculate derivatives for edge detection
    vec3 d = fwidth(barycentric);

    // Find distance to nearest edge
    vec3 a3 = smoothstep(vec3(0.0), d * edge_width, barycentric);
    float edge_factor = min(min(a3.x, a3.y), a3.z);

    // Sharp edge transition
    edge_factor = 1.0 - pow(1.0 - edge_factor, edge_sharpness);

    // Mix base color with edge color
    vec3 final_color = mix(edge_color.rgb, base_color.rgb, edge_factor);

    // Always fully opaque for VR compatibility
    ALBEDO = final_color;
    ALPHA = 1.0;

    // Add subtle emission to edges
    EMISSION = edge_color.rgb * (1.0 - edge_factor) * emission_strength * 0.3;
}