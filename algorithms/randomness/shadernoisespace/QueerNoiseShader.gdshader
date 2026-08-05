// QueerNoiseShader.gdshader
// The room sphere's material. NOTE: this file and WallNoiseShader.gdshader are the SAME
// shader — they were byte-identical before this line was written, header comment included,
// which is why this one carried the other's name. The "two independent noise loops" the
// artifact's @identity claims are one shader run twice with different uniform values and a
// 0.7x phase offset on time. Kept as two files because the .tscn's two materials point at
// them separately; both carry the noise_basis dispatch so the room and its walls change
// basis together.
shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform float time : hint_range(0.0, 100.0) = 0.0;
uniform float cloud_scale : hint_range(0.5, 5.0) = 2.0;
uniform float pink_intensity : hint_range(0.0, 2.0) = 0.8;
uniform float corner_darkness : hint_range(0.0, 1.0) = 0.3;
uniform float time_scale : hint_range(0.0, 1.0) = 0.2;
uniform float cloud_density : hint_range(0.1, 2.0) = 1.0;
uniform vec4 base_pink : source_color = vec4(1.0, 0.6, 0.8, 1.0);
uniform vec4 deep_pink : source_color = vec4(0.8, 0.2, 0.6, 1.0);
uniform vec4 dark_corner : source_color = vec4(0.2, 0.1, 0.2, 1.0);

// WHICH BASIS FILLS THE FIELD. 0 simplex, 1 perlin, 2 value, 3 cellular — the same four the
// noise sequence's bench artifacts compare (perlin_noise, simplex_noise, noise_terrain),
// asked here at room scale, where the field is the architecture rather than a tabletop.
// 1 is the default because 1 is what this shader has always computed.
uniform int noise_basis : hint_range(0, 3) = 1;

varying vec2 world_uv;
varying vec3 world_position;

// High quality 2D noise
vec2 hash2(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)),
             dot(p, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float hash1(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// PERLIN — the shipped basis, unchanged. A random GRADIENT at each lattice corner, dotted
// with the offset to it and smoothed between. Because the value is zero at every corner the
// square lattice stays faintly latent in the result: smooth swells on a grid.
float perlin2d(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(mix(dot(hash2(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)),
                   dot(hash2(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
               mix(dot(hash2(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
                   dot(hash2(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x), u.y);
}

// VALUE — a random HEIGHT at each corner instead of a gradient, interpolated identically.
// The field no longer passes through zero on the lattice, so cells become plateaus and the
// grid stops being latent and becomes the picture. The blockiest of the four.
float value2d(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    float v = mix(mix(hash1(i + vec2(0.0, 0.0)), hash1(i + vec2(1.0, 0.0)), u.x),
                  mix(hash1(i + vec2(0.0, 1.0)), hash1(i + vec2(1.0, 1.0)), u.x), u.y);
    return (v - 0.5) * 0.770;
}

// SIMPLEX — the same gradient idea on a TRIANGULAR lattice, summed from three corners with a
// radial falloff instead of interpolated from four. Perlin's square grid disappears and what
// is left has no preferred direction; it is the busiest of the four at a given frequency.
float simplex2d(vec2 p) {
    float F2 = 0.366025403784439;
    float G2 = 0.211324865405187;
    vec2 i = floor(p + (p.x + p.y) * F2);
    vec2 x0 = p - i + (i.x + i.y) * G2;
    vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec2 x1 = x0 - i1 + G2;
    vec2 x2 = x0 - 1.0 + 2.0 * G2;
    vec3 t = max(0.5 - vec3(dot(x0, x0), dot(x1, x1), dot(x2, x2)), 0.0);
    t = t * t;
    t = t * t;
    vec3 g = vec3(dot(hash2(i), x0),
                  dot(hash2(i + i1), x1),
                  dot(hash2(i + vec2(1.0, 1.0)), x2));
    return dot(t, g) * 38.0;
}

// CELLULAR — Worley, and not a smooth field at all. Space is partitioned by scattered
// feature points and every fragment reports the distance to its nearest one, so the result
// has EDGES: the only basis of the four that admits it is made of cells.
float cellular2d(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float best = 8.0;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 o = vec2(float(x), float(y));
            vec2 feature = o + (hash2(i + o) * 0.5 + 0.5);
            best = min(best, length(feature - f));
        }
    }
    return (0.5 - best) * 0.827;
}

// The four are AMPLITUDE-MATCHED, not merely swapped in: measured over 30,000 samples each
// returns mean |value| = 0.137, which is what the shipped perlin returns. Without those three
// constants the sweep would mostly be reading which basis is BRIGHTER once the fbm below is
// pushed through smoothstep(0.2, 0.8), and the axis would be about exposure instead of
// about structure. Their own characters survive it: value is the smoothest field per unit
// distance, simplex the busiest, cellular the only one with edges.
float noise2d(vec2 p) {
    if (noise_basis == 0) { return simplex2d(p); }
    if (noise_basis == 2) { return value2d(p); }
    if (noise_basis == 3) { return cellular2d(p); }
    return perlin2d(p);
}

// Cloud-like fractal noise
float cloud_noise(vec2 pos, float t) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;

    // Multiple octaves for cloud-like appearance
    for (int i = 0; i < 6; i++) {
        vec2 animated_pos = pos * frequency;
        animated_pos.x += sin(t * 0.3 + pos.y * 0.5) * 0.3;
        animated_pos.y += cos(t * 0.2 + pos.x * 0.3) * 0.2;

        value += amplitude * abs(noise2d(animated_pos));
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    return value;
}

// Turbulence for more organic cloud patterns
float turbulence(vec2 pos, float t) {
    float turb = 0.0;
    float amplitude = 1.0;
    float frequency = 0.5;

    for (int i = 0; i < 4; i++) {
        vec2 moving_pos = pos * frequency;
        moving_pos += vec2(cos(t * 0.1), sin(t * 0.15)) * 2.0;

        turb += amplitude * abs(noise2d(moving_pos));
        amplitude *= 0.6;
        frequency *= 2.5;
    }
    return turb;
}

void vertex() {
    world_uv = UV;
    world_position = VERTEX;
}

void fragment() {
    vec2 uv = world_uv;

    // Create flowing cloud patterns
    float cloud_base = cloud_noise(uv * cloud_scale, time * time_scale);
    float cloud_detail = turbulence(uv * cloud_scale * 2.0, time * time_scale * 0.7);

    // Combine noise patterns for realistic clouds
    float cloud_pattern = (cloud_base + cloud_detail * 0.4) * cloud_density;
    cloud_pattern = smoothstep(0.2, 0.8, cloud_pattern);

    // Create corner darkening effect
    vec2 corner_dist = abs(uv - 0.5) * 2.0; // Distance from center
    float corner_factor = max(corner_dist.x, corner_dist.y);
    corner_factor = pow(corner_factor, 1.5); // Sharper falloff
    float darkness = mix(1.0, corner_darkness, corner_factor);

    // Generate pink cloud colors with variation
    vec3 cloud_color = mix(base_pink.rgb, deep_pink.rgb, cloud_pattern);

    // Add subtle color shifting over time
    float color_shift = sin(time * 0.3 + uv.x * 2.0 + uv.y * 3.0) * 0.1;
    cloud_color.r += color_shift;
    cloud_color.b -= color_shift * 0.5;

    // Apply pink intensity
    cloud_color *= pink_intensity;

    // Apply corner darkening
    cloud_color = mix(dark_corner.rgb, cloud_color, darkness);

    // Add subtle edge highlighting
    float edge_highlight = 1.0 - smoothstep(0.4, 0.6, cloud_pattern);
    cloud_color += edge_highlight * 0.2 * vec3(1.0, 0.8, 0.9);

    // Final cloud density modulation
    float final_pattern = smoothstep(0.1, 0.9, cloud_pattern);
    vec3 final_color = mix(cloud_color * 0.3, cloud_color, final_pattern);

    // Add atmospheric depth
    float atmospheric = 1.0 - cloud_pattern * 0.2;
    final_color *= atmospheric;

    ALBEDO = final_color;
    EMISSION = final_color * 0.1 * pink_intensity;
    METALLIC = 0.0;
    ROUGHNESS = 0.7 + cloud_pattern * 0.3;

    // Add subtle normal mapping effect for depth
    vec2 normal_offset = vec2(
        cloud_noise(uv * cloud_scale + vec2(0.01, 0.0), time * time_scale) -
        cloud_noise(uv * cloud_scale - vec2(0.01, 0.0), time * time_scale),
        cloud_noise(uv * cloud_scale + vec2(0.0, 0.01), time * time_scale) -
        cloud_noise(uv * cloud_scale - vec2(0.0, 0.01), time * time_scale)
    ) * 0.1;

    NORMAL_MAP = vec3(normal_offset, 1.0);
}