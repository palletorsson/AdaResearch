shader_type spatial;

// Helper function to create a bar in the pattern
float bar(float min, float max, float x) {
    return step(min, x) * step(x, max);
}

// Function to wrap UV coordinates for tiling
vec2 tile(vec2 uv, float div) {
    return fract(uv * div);
}

// Function to combine colors based on a threshold (t)
vec3 combine(vec2 uv, float div, vec3 color1, vec3 color2, float t) {
    uv = tile(uv, div);
    vec3 resultColor = color1;

    if (t >= 1.0) {
        resultColor = color2;
    } else if (t >= 0.5) {
        bool checker = mod(floor(uv.x * 2.0) + floor(uv.y * 2.0), 2.0) == 0.0;
        resultColor = checker ? color2 : color1;
    }
    return resultColor;
}

// Main pattern function
vec3 pattern(vec2 uv) {
    float mask1 = 0.5 *
        (bar(0.1, 0.2, uv.x) + bar(0.3, 0.4, uv.x) +
         bar(0.6, 0.7, uv.y) + bar(0.8, 0.9, uv.y));
    float mask2 = 0.5 *
        (bar(0.0, 0.1, uv.x) + bar(0.2, 0.3, uv.x) + bar(0.4, 0.5, uv.x) +
         bar(0.9, 1.0, uv.y) + bar(0.7, 0.8, uv.y) + bar(0.5, 0.6, uv.y));
    float mask3 = 0.5 *
        (bar(0.7, 0.75, uv.x) + bar(0.8, 0.85, uv.x) +
         bar(0.15, 0.2, uv.y) + bar(0.25, 0.3, uv.y));

    vec3 baseColor = vec3(0.8588, 0.7725, 0.6039); // Beige color
    vec3 color = combine(uv, 50.0, baseColor, vec3(1.0), mask1); // White
    color = combine(uv, 50.0, color, vec3(0.0), mask2); // Black
    color = combine(uv, 50.0, color, vec3(0.7, 0.0, 0.3), mask3); // Reddish color

    return color;
}

void fragment() {
    vec2 uv = UV;

    // Generate the tartan pattern
    vec3 color = pattern(tile(uv, 2.0));

    // Fade to black as uv.x approaches 1
    float fade_to_black = smoothstep(0.8, 1.0, uv.x);
    color = mix(color, vec3(0.0), fade_to_black);

    ALBEDO = color; // Set the fragment color
}
