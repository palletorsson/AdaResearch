shader_type spatial;

// Uniform for touch state
uniform bool is_touched = false;

// Uniforms for noise and time
uniform float u_time;

// 2D Random function
float rand(vec2 n) {
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

// Helper function to rotate UVs around the central point
vec2 rotate2D(vec2 uv, float angle) {
    float c = cos(angle);
    float s = sin(angle);

    mat2 rotMat = mat2(vec2(c, -s), vec2(s, c));
    return rotMat * uv;
}

// 2D Noise function
float noise(vec2 p) {
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u * u * (3.0 - 2.0 * u);

    float res = mix(
        mix(rand(ip), rand(ip + vec2(1.0, 0.0)), u.x),
        mix(rand(ip + vec2(0.0, 1.0)), rand(ip + vec2(1.0, 1.0)), u.x),
        u.y
    );
    return res * res;
}

// Function to combine multiple octaves of noise for more complexity
float fbm(vec2 p) {
    float f = 0.0;
    f += 0.5000 * noise(p); p = p * 2.02;
    f += 0.2500 * noise(p); p = p * 2.03;
    f += 0.1250 * noise(p); p = p * 2.01;
    f += 0.0625 * noise(p);
    return f / 0.9375;
}

// HSV to RGB conversion for vibrant color generation
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
    vec3 color;

    if (is_touched) {
        // Vibrant colors when touched
        vec2 p = UV * 4.0;  // Scale up UVs for detail
        vec2 rotated_p = rotate2D(p, TIME * 0.2);  // Rotate the pattern over time

        // Generate fluid, dynamic patterns
        float q = fbm(rotated_p - TIME * 0.5);
        float n = fbm(rotated_p + q + TIME);

        // Vibrant color based on noise
        vec3 hsv = vec3(fract(n + TIME * 0.1), 1.0, n);  // Hue shifts over time
        color = hsv2rgb(hsv);
    } else {
        // Fluid gray when not touched
        vec2 p = UV * 4.0;  // Scale for noise detail
        vec2 flow = rotate2D(p, TIME * 0.1);  // Slow, flowing effect
        float gray_noise = fbm(flow);  // Smooth gray noise
        color = vec3(0.3 + gray_noise * 0.2);  // Base gray with dynamic variation
    }

    // Output the color
    ALBEDO = color;

    // Add subtle emission when touched
    EMISSION = is_touched ? color * 0.5 : vec3(0.0);
}
