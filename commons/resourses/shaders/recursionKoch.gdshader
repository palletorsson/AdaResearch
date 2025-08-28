shader_type spatial;

uniform int recursion_level : hint_range(1, 8) = 3;  // Recursion level (1 to 8 recommended)
uniform float line_width : hint_range(0.001, 0.1) = 0.02;  // Thickness of the lines
uniform vec4 line_color = vec4(1.0, 0.0, 0.0, 1.0);  // Line color

// Koch fractal function
float koch(vec2 uv, int level) {
    float x = uv.x * pow(3.0, float(level));  // Scale x-coordinates
    float y = uv.y;  // Keep y-coordinates

    for (int i = 0; i < level; i++) {
        x = abs(x - floor(x) - 0.5) * 3.0;  // Koch step
    }

    return abs(y - 0.5 * x);
}

void fragment() {
    // UV mapping normalized to [-1, 1]
    vec2 uv = (UV * 2.0 - 1.0);

    // Fractal pattern calculation
    float d = koch(uv, recursion_level);

    // Smooth thickness
    float alpha = 1.0 - smoothstep(line_width, line_width * 1.5, d);

    // Apply line color
    ALBEDO = line_color.rgb * alpha;

    // Transparency for the unused areas
    ALPHA = alpha * line_color.a;
}
