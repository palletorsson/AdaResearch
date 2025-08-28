shader_type spatial;

// Uniforms for resolution and time
uniform vec2 u_resolution;
uniform float u_time;

// Function to generate a random value based on position
vec2 random2(vec2 p) {
    return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

// Function to calculate the Voronoi pattern
vec3 voronoi(vec2 x) {
    vec2 n = floor(x);
    vec2 f = fract(x);

    vec2 mg, mr;
    float md = 8.0;

    for (int j = -1; j <= 1; j++) {
        for (int i = -1; i <= 1; i++) {
            vec2 g = vec2(float(i), float(j));
            vec2 o = random2(n + g);
            // Animate the seed offset over time
            o = 0.5 + 0.5 * sin(TIME + 6.2831 * o);

            vec2 r = g + o - f;
            float d = dot(r, r);

            if (d < md) {
                md = d;
                mr = r;
                mg = g;
            }
        }
    }

    md = 8.0;
    for (int j = -2; j <= 2; j++) {
        for (int i = -2; i <= 2; i++) {
            vec2 g = mg + vec2(float(i), float(j));
            vec2 o = random2(n + g);
            // Animate the seed offset over time
            o = 0.5 + 0.5 * sin(TIME + 6.2831 * o);

            vec2 r = g + o - f;
            if (dot(mr - r, mr - r) > 0.00001) {
                md = min(md, dot(0.5 * (mr + r), normalize(r - mr)));
            }
        }
    }

    return vec3(md, mr);
}

void fragment() {
    vec2 st = UV;

    // Animate the position over time by adding time to the UVs
    st += vec2(TIME * 0.1);

    // Scale the coordinates
    st *= 4.0;
    vec3 c = voronoi(st);

    vec3 color = vec3(0.0);
    // Isolines
    color = c.x * (0.5 + 0.5 * sin(64.0 * c.x)) * vec3(1.0);
    // Borders
    color = mix(vec3(1.0), color, smoothstep(0.01, 0.02, c.x));
    // Feature points
    float dd = length(c.yz);
    color += vec3(1.0) * (1.0 - smoothstep(0.0, 0.04, dd));

    ALBEDO = color;
}
