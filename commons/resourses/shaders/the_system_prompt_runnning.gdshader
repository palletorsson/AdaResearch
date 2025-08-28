shader_type spatial;

uniform vec2 u_resolution = vec2(0.5, 0.5);

// Random function for float
float random(float x) {
    return fract(sin(x) * 43758.5453);
}

// Random function for vec2
float myrandom(vec2 st) {
    return fract(sin(dot(st, vec2(12.9898, 78.233))) * 43758.5453);
}

// Generates a random character-like pattern
float randomChar(vec2 outer, vec2 inner) {
    float grid = 5.0;
    vec2 margin = vec2(0.2, 0.05);
    vec2 borders = step(margin, inner) * step(margin, 1.0 - inner);
    vec2 ipos = floor(inner * grid);
    vec2 fpos = fract(inner * grid);
    return step(0.5, myrandom(outer * 64.0 + ipos)) * borders.x * borders.y * step(0.01, fpos.x) * step(0.01, fpos.y);
}

void fragment() {
    // Normalize and adjust aspect ratio
    vec2 st = UV.xy / u_resolution;

    // Initialize the color
    vec3 color = vec3(0.0);

    // Define the number of rows
    float rows = 12.0;  // Default to 12 rows for demonstration
    vec2 ipos = floor(st * rows);
    vec2 fpos = fract(st * rows);

    // Animate the position to scroll characters
    ipos += vec2(0.0, floor(TIME * 1.0 * random(ipos.x + 1.0)));

    // Compute the character display
    float pct = 1.0;
    pct *= randomChar(ipos, fpos);

    // Set the green channel to the computed value for green text
    color = vec3(0.0, pct, 0.0);

    // Set the fragment color
    ALBEDO = color;
}
