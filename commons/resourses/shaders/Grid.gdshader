shader_type spatial;
// Enable transparency for opacity control - Correct Godot 4 syntax
 

// Uniforms
uniform vec4 modelColor : source_color = vec4(0.5, 0.5, 0.5, 1.0);       // Main cube color
uniform vec4 wireframeColor : source_color = vec4(1.0, 0.0, 0.0, 1.0);   // Wireframe color
uniform vec4 emissionColor : source_color = vec4(1.0, 0.0, 0.0, 1.0);    // Emission color
uniform float width : hint_range(0.1, 15.0) = 2.0;                       // Edge thickness
uniform float blur : hint_range(0.1, 5.0) = 1.0;                         // Blur amount
uniform float emission_strength : hint_range(0.0, 10.0) = 2.0;           // Emission intensity
uniform float modelOpacity : hint_range(0.0, 1.0) = 0.8;                 // Base opacity - NOW WORKS!
uniform float wireframeOpacity : hint_range(0.0, 1.0) = 1.0;             // Wireframe opacity
uniform float globalOpacity : hint_range(0.0, 1.0) = 1.0;                // Overall opacity multiplier
uniform bool show_interior = true;                                       // Show cube interior

// Barycentric coordinates
varying vec3 baryCoord;

void vertex() {
    // Calculate barycentric coordinates more reliably
    int vertexIndex = VERTEX_ID % 3;
    if (vertexIndex == 0) {
        baryCoord = vec3(1.0, 0.0, 0.0);
    } else if (vertexIndex == 1) {
        baryCoord = vec3(0.0, 1.0, 0.0);
    } else {
        baryCoord = vec3(0.0, 0.0, 1.0);
    }
}

void fragment() {
    // Calculate edge distances using barycentric coordinates
    vec3 dBaryCoordX = dFdx(baryCoord);
    vec3 dBaryCoordY = dFdy(baryCoord);
    vec3 dBaryCoord = sqrt(dBaryCoordX * dBaryCoordX + dBaryCoordY * dBaryCoordY);

    // Prevent division by zero
    dBaryCoord = max(dBaryCoord, vec3(0.0001));

    // Calculate distance to edges
    vec3 edge_distance = baryCoord / (dBaryCoord * width);

    // Apply smoothstep for edge detection
    vec3 remap = smoothstep(vec3(0.0), vec3(blur), edge_distance);

    // Find the closest edge (minimum distance means closest to an edge)
    float closestEdge = min(min(remap.x, remap.y), remap.z);

    // Calculate final colors and alpha
    vec3 finalColor;
    float finalAlpha;

    if (show_interior) {
        // Mix wireframe and model colors
        finalColor = mix(wireframeColor.rgb, modelColor.rgb, closestEdge);
        finalAlpha = mix(wireframeOpacity, modelOpacity, closestEdge);

        // Ensure minimum visibility for the model interior
        if (closestEdge > 0.5) {
            finalAlpha = max(finalAlpha, 0.1); // Minimum 10% opacity for interior
        }
    } else {
        // Only show wireframe
        finalColor = wireframeColor.rgb;
        finalAlpha = wireframeOpacity * (1.0 - closestEdge);

        // If not showing interior, make interior completely transparent
        if (closestEdge > 0.5) {
            finalAlpha = 0.0;
        }
    }

    // Apply global opacity multiplier
    finalAlpha *= globalOpacity;

    // Clamp alpha to prevent complete transparency when not intended
    if (show_interior && modelOpacity > 0.0) {
        finalAlpha = max(finalAlpha, 0.05);
    }

    // Apply colors
    ALBEDO = finalColor;
    ALPHA = finalAlpha;

    // Add emission to wireframe edges
    EMISSION = emissionColor.rgb * (1.0 - closestEdge) * emission_strength;
}