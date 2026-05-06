shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled;

// UV-based grid shader for walls — draws clean grid lines without diagonals
// Uses UV coordinates and fract() instead of barycentric coordinates

// Uniforms matching SimpleGrid interface for compatibility
uniform vec4 modelColor : source_color = vec4(0.15, 0.15, 0.15, 1.0);
uniform vec4 wireframeColor : source_color = vec4(0.6, 0.6, 0.6, 1.0);
uniform vec4 emissionColor : source_color = vec4(0.4, 0.4, 0.5, 1.0);
uniform float width : hint_range(0.1, 15.0) = 1.0;
uniform float blur : hint_range(0.1, 5.0) = 1.0;
uniform float emission_strength : hint_range(0.0, 10.0) = 2.0;
uniform float modelOpacity : hint_range(0.0, 1.0) = 1.0;
uniform float wireframeOpacity : hint_range(0.0, 1.0) = 1.0;
uniform float globalOpacity : hint_range(0.0, 1.0) = 1.0;
uniform bool show_interior = true;

// Grid density — how many cells per UV unit
uniform float grid_cells_x : hint_range(1.0, 100.0) = 6.0;
uniform float grid_cells_y : hint_range(1.0, 100.0) = 4.0;

void fragment() {
    // Scale UV to grid cell count
    vec2 grid_uv = UV * vec2(grid_cells_x, grid_cells_y);

    // Distance to nearest grid line (0 = on line, 0.5 = center of cell)
    vec2 grid_fract = fract(grid_uv);
    vec2 dist_to_edge = min(grid_fract, 1.0 - grid_fract);

    // Screen-space derivative for consistent line width at any distance
    vec2 duvx = dFdx(grid_uv);
    vec2 duvy = dFdy(grid_uv);
    vec2 pixel_width = sqrt(duvx * duvx + duvy * duvy);
    pixel_width = max(pixel_width, vec2(0.0001));

    // Normalize edge distance by pixel width and line thickness
    vec2 edge_normalized = dist_to_edge / (pixel_width * width);

    // Smoothstep for anti-aliased lines
    vec2 line_mask = smoothstep(vec2(0.0), vec2(blur), edge_normalized);

    // Closest edge — 0 = on a line, 1 = in cell interior
    float closestEdge = min(line_mask.x, line_mask.y);

    // Calculate final color and alpha
    vec3 finalColor;
    float finalAlpha;

    if (show_interior) {
        finalColor = mix(wireframeColor.rgb, modelColor.rgb, closestEdge);
        finalAlpha = mix(wireframeOpacity, modelOpacity, closestEdge);

        if (closestEdge > 0.5) {
            finalAlpha = max(finalAlpha, 0.1);
        }
    } else {
        finalColor = wireframeColor.rgb;
        finalAlpha = wireframeOpacity * (1.0 - closestEdge);

        if (closestEdge > 0.5) {
            finalAlpha = 0.0;
        }
    }

    finalAlpha *= globalOpacity;

    if (show_interior && modelOpacity > 0.0) {
        finalAlpha = max(finalAlpha, 0.05);
    }

    ALBEDO = finalColor;
    ALPHA = finalAlpha;
    ROUGHNESS = 1.0;
    SPECULAR = 0.0;

    // Emission on grid lines
    EMISSION = emissionColor.rgb * (1.0 - closestEdge) * emission_strength;
}
