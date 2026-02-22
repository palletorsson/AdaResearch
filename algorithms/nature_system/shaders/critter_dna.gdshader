shader_type spatial;
render_mode blend_mix, cull_disabled, diffuse_lambert, specular_schlick_ggx, depth_prepass_alpha;

// ═══════════════════════════════════════════════════════════════
// critter_dna.gdshader — Universal DNA-expression shader
//
// Evolved from queerbreeder's dna_pattern.gdshader. Drives all
// five kingdoms (tree, creature, flower, fungus, hybrid) from
// a single shader with 20 interpolatable pattern types.
//
// Every uniform maps to a CritterDNA gene via CritterTraitMapper.
// ═══════════════════════════════════════════════════════════════

// --- Color (from CritterDNA.primary_color / secondary_color / tertiary_color) ---
uniform vec4 primary_color : source_color = vec4(1.0, 0.5, 0.2, 1.0);
uniform vec4 secondary_color : source_color = vec4(0.2, 0.5, 1.0, 1.0);
uniform vec4 wing_color : source_color = vec4(1.0, 0.8, 0.0, 1.0);  // tertiary

// --- Pattern (from CritterDNA.pattern_type / pattern_density / pattern_scale) ---
uniform float pattern_type : hint_range(0.0, 1.0) = 0.5;
uniform float pattern_density : hint_range(0.0, 1.0) = 0.5;
uniform float pattern_scale : hint_range(0.2, 5.0) = 1.0;
uniform float pattern_rotation : hint_range(0.0, 6.28318) = 0.0;
uniform float pattern_intensity : hint_range(0.0, 1.0) = 0.8;

// --- Effect flags packed as vec4 to save uniform slots ---
// x=edge_detection, y=cellular_influence, z=darkness, w=color_mixing
uniform vec4 effect_flags = vec4(0.5, 0.2, 0.35, 0.5);

// --- Material (from CritterDNA surface genes) ---
uniform float iridescence : hint_range(0.0, 1.0) = 0.0;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.05, 1.0) = 0.7;
uniform float specular_tint : hint_range(0.0, 1.0) = 0.0;
uniform float transparency : hint_range(0.0, 0.9) = 0.0;
uniform float cracking : hint_range(0.0, 1.0) = 0.0;

// --- LOD ---
uniform float detail_level : hint_range(0.1, 1.0) = 1.0;

// --- Animation (from CritterDNA behavior genes via trait mapper) ---
uniform float wave_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float wave_amplitude : hint_range(0.0, 0.5) = 0.5;
uniform float wave_frequency : hint_range(0.1, 20.0) = 10.0;
uniform float wave_speed : hint_range(0.0, 10.0) = 3.0;
uniform vec2 wave_direction = vec2(1.0, 0.0);

// --- Bond / Transmutation overlay (from CritterTraitMapper.apply_bond_overlay) ---
uniform float emission_energy : hint_range(0.0, 2.0) = 0.0;
uniform float rim_light : hint_range(0.0, 1.0) = 0.0;
uniform vec4 rim_color : source_color = vec4(0.8, 0.9, 1.0, 1.0);


// ═══════════════════════════════════════════════════════════════
// MULTIMESH INSTANCE DATA — passed from vertex to fragment
// When not using MultiMesh, COLOR=(1,1,1,1), INSTANCE_CUSTOM=(0,0,0,0)
// ═══════════════════════════════════════════════════════════════

varying vec4 v_instance_color;
varying vec4 v_instance_custom;


// ═══════════════════════════════════════════════════════════════
// VERTEX — Wave animation + instance data passthrough
// ═══════════════════════════════════════════════════════════════

void vertex() {
    // Pass MultiMesh per-instance data to fragment
    v_instance_color = COLOR;           // Per-instance tint (white = no effect)
    v_instance_custom = INSTANCE_CUSTOM; // .r = extra pattern rotation (0-1)

    if (wave_intensity > 0.01) {
        vec2 dir = normalize(wave_direction);
        float phase = dot(VERTEX.xz, dir) * wave_frequency + TIME * wave_speed;
        VERTEX.y += sin(phase) * wave_amplitude * wave_intensity;
    }
}


// ═══════════════════════════════════════════════════════════════
// NOISE FUNCTIONS
// ═══════════════════════════════════════════════════════════════

float rand(vec2 n) {
    return fract(sin(dot(n, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u * u * (3.0 - 2.0 * u);
    return mix(
        mix(rand(ip), rand(ip + vec2(1.0, 0.0)), u.x),
        mix(rand(ip + vec2(0.0, 1.0)), rand(ip + vec2(1.0, 1.0)), u.x),
        u.y);
}


// ═══════════════════════════════════════════════════════════════
// PATTERN HELPER FUNCTIONS
// ═══════════════════════════════════════════════════════════════

float voronoi_cellular(vec2 uv, float scale, float randomness, float edge_width) {
    uv *= scale;
    vec2 cell_id = floor(uv);
    vec2 local_pos = fract(uv);
    float min_dist = 8.0;
    float second_min_dist = 8.0;

    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 neighbor = vec2(float(x), float(y));
            vec2 cell_coord = cell_id + neighbor;
            vec2 point_pos = vec2(rand(cell_coord), rand(cell_coord + vec2(23.14, 97.21)));
            point_pos = 0.5 + 0.5 * randomness * sin(point_pos * 6.2831853);
            float dist = length(neighbor + point_pos - local_pos);
            if (dist < min_dist) {
                second_min_dist = min_dist;
                min_dist = dist;
            } else if (dist < second_min_dist) {
                second_min_dist = dist;
            }
        }
    }
    return smoothstep(0.0, edge_width, second_min_dist - min_dist);
}

float voronoi(vec2 x, float density) {
    vec2 n = floor(x * density);
    vec2 f = fract(x * density);
    float md = 1.0;
    for (int j = -1; j <= 1; j++) {
        for (int i = -1; i <= 1; i++) {
            vec2 neighbor = vec2(float(i), float(j));
            vec2 cell_coord = n + neighbor;
            vec2 random_vec = vec2(rand(cell_coord), rand(cell_coord + vec2(3.7, 8.9)));
            vec2 point = random_vec * 0.5 + 0.25;
            md = min(md, length(neighbor + point - f));
        }
    }
    return md;
}

float vortex_pattern(vec2 uv, float scale, float intensity) {
    vec2 p = uv * scale - vec2(0.5);
    float angle = atan(p.y, p.x);
    float dist = length(p);
    float r = dist + intensity * (angle / 6.28318);
    return 0.5 + 0.5 * sin(r * 20.0);
}

float crystal_pattern(vec2 uv, float scale, float sharpness) {
    vec2 tc = uv * scale;
    float n1 = noise(tc);
    float n2 = noise((tc + vec2(1.3, 8.7)) * 1.5);
    float ridges = pow(1.0 - abs(n1 * 2.0 - 1.0), sharpness);
    return ridges * (0.5 + n2 * 0.5);
}

float sinusoidal_pattern(vec2 uv, float scale, float complexity) {
    vec2 dir1 = vec2(1.0, 0.0);
    vec2 dir2 = vec2(-0.5, 0.866);
    vec2 dir3 = vec2(-0.5, -0.866);
    float w1 = sin(dot(uv * scale, dir1) * 10.0);
    float w2 = sin(dot(uv * scale, dir2) * 10.0 * (1.0 + complexity * 0.5));
    float w3 = sin(dot(uv * scale, dir3) * 10.0 * (1.0 + complexity));
    return 0.5 + 0.5 * (w1 + w2 * 0.7 + w3 * 0.5) / 2.2;
}

float ripple_pattern(vec2 uv, float scale, float complexity) {
    float dist = length((uv - 0.5) * scale);
    float r1 = sin(dist * 10.0);
    float r2 = sin(dist * 20.0 * (1.0 + complexity * 0.3)) * 0.5;
    float r3 = sin(dist * 30.0 * (1.0 + complexity * 0.6)) * 0.25;
    return 0.5 + 0.5 * (r1 + r2 + r3) / 1.75;
}

float spiral_pattern(vec2 uv, float scale, float complexity) {
    vec2 centered = (uv - 0.5) * scale;
    float radius = length(centered);
    float angle = atan(centered.y, centered.x);
    float s = sin(radius * 10.0 + angle * (3.0 + complexity * 3.0));
    if (complexity > 0.3) {
        s = mix(s, sin(radius * 15.0 - angle * 2.0), complexity * 0.5);
    }
    return 0.5 + 0.5 * s;
}

float detect_edges(float pattern_val, float thickness) {
    vec2 gradient = vec2(dFdx(pattern_val), dFdy(pattern_val));
    return smoothstep(0.0, 0.05 * thickness, length(gradient));
}

mat2 rotate2d(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(vec2(c, s), vec2(-s, c));
}


// ═══════════════════════════════════════════════════════════════
// PATTERN EVALUATOR — evaluate a single pattern by index
// Refactored to avoid duplicating the 20-pattern switch twice
// ═══════════════════════════════════════════════════════════════

float eval_pattern(int idx, vec2 uv, float freq_mult, float detail_mult) {
    if (idx == 0) {
        // 0: Dots
        return 1.0 - smoothstep(0.3 / detail_mult, 0.5 / detail_mult,
                    length(fract(uv * freq_mult * 0.5) - 0.5));
    }
    else if (idx == 1) {
        // 1: Stripes
        return 0.5 + 0.5 * sign(sin(uv.x * freq_mult * 0.6));
    }
    else if (idx == 2) {
        // 2: Grid
        return max(
            0.5 + 0.5 * sign(sin(uv.x * freq_mult * 0.4)),
            0.5 + 0.5 * sign(sin(uv.y * freq_mult * 0.4)));
    }
    else if (idx == 3) {
        // 3: Waves
        return 0.5 + 0.5 * sin(uv.x * freq_mult * 0.7 + uv.y * freq_mult * 0.4
                    + noise(uv * 2.0) * 3.14159 * (detail_mult - 0.5));
    }
    else if (idx == 4) {
        // 4: Noise
        return noise(uv * freq_mult * 0.4);
    }
    else if (idx == 5) {
        // 5: Voronoi
        return voronoi(uv, freq_mult * 0.3);
    }
    else if (idx == 6) {
        // 6: Fractal
        float f = 0.0; float a = 1.0; float fr = 1.0;
        for (int i = 0; i < 3; i++) {
            f += a * noise(uv * freq_mult * fr);
            a *= 0.5; fr *= 2.0;
        }
        return fract(f * 3.0);
    }
    else if (idx == 7) {
        // 7: Blobs
        float b = 0.0;
        for (int i = 0; i < 3; i++) {
            vec2 off = vec2(sin(float(i) * 1.57), cos(float(i) * 1.57)) * 0.5;
            b += smoothstep(0.2, 0.7, 1.0 - length((fract(uv * freq_mult * 0.25) - 0.5) - off));
        }
        return clamp(b, 0.0, 1.0);
    }
    else if (idx == 8) {
        // 8: Fragments
        return step(0.5, noise(uv * freq_mult * 0.6)) *
               step(0.5, noise((uv + vec2(1.3, 2.7)) * freq_mult * 0.4));
    }
    else if (idx == 9) {
        // 9: Sine interference
        return 0.5 + 0.5 * (sin(uv.x * freq_mult * 0.5) *
               sin(uv.y * freq_mult * 0.6) *
               sin((uv.x + uv.y) * freq_mult * 0.4));
    }
    else if (idx == 10) {
        // 10: Edges
        return detect_edges(noise(uv * freq_mult * 0.3), 1.0);
    }
    else if (idx == 11) {
        // 11: Triangles
        vec2 t = fract(uv * freq_mult * 0.25) - 0.5;
        return step(t.x + t.y, 0.0);
    }
    else if (idx == 12) {
        // 12: Hexagons
        return smoothstep(0.4, 0.5, length(fract(uv * freq_mult * 0.2) - 0.5));
    }
    else if (idx == 13) {
        // 13: Stitching
        vec2 s = fract(uv * freq_mult * 0.3) - 0.5;
        float sx = abs(s.x); float sy = abs(s.y);
        return (1.0 - smoothstep(0.3, 0.35, max(sx, sy))) *
               (1.0 - smoothstep(0.15, 0.2, min(sx, sy)));
    }
    else if (idx == 14) {
        // 14: Tartan
        float h = step(0.5, fract(uv.x * freq_mult * 0.2));
        float v = step(0.5, fract(uv.y * freq_mult * 0.2));
        float th = step(0.9, fract(uv.x * freq_mult * 0.5));
        float tv = step(0.9, fract(uv.y * freq_mult * 0.5));
        return max(max(h, v), max(th, tv));
    }
    else if (idx == 15) {
        // 15: Spiral
        return spiral_pattern(uv, freq_mult * 0.2, detail_mult);
    }
    else if (idx == 16) {
        // 16: Vortex
        return vortex_pattern(uv, freq_mult * 0.2, detail_mult);
    }
    else if (idx == 17) {
        // 17: Crystal
        return crystal_pattern(uv, freq_mult * 0.3, 2.0 + detail_mult * 3.0);
    }
    else if (idx == 18) {
        // 18: Sinusoidal
        return sinusoidal_pattern(uv, freq_mult * 0.3, detail_mult);
    }
    else if (idx == 19) {
        // 19: Ripple
        return ripple_pattern(uv, freq_mult * 0.25, detail_mult);
    }

    return 0.5;  // Fallback
}


// ═══════════════════════════════════════════════════════════════
// MAIN PATTERN GENERATOR — interpolates between two nearest types
// ═══════════════════════════════════════════════════════════════

float generate_base_pattern(vec2 uv, float type, float complexity, float intensity_mod) {
    complexity *= detail_level;
    float freq_mult = (5.0 + complexity * 15.0) * detail_level;
    float detail_mult = 0.5 + complexity;

    float pattern_idx = type * 19.0;  // 20 patterns, indices 0-19
    int lower_idx = int(floor(pattern_idx)) % 20;
    int upper_idx = int(ceil(pattern_idx)) % 20;
    float blend = fract(pattern_idx);

    float lower_val = eval_pattern(lower_idx, uv, freq_mult, detail_mult);
    float upper_val = eval_pattern(upper_idx, uv, freq_mult, detail_mult);

    float pattern = mix(lower_val, upper_val, blend);
    return mix(0.5, pattern, intensity_mod);
}


// ═══════════════════════════════════════════════════════════════
// CRACK GENERATOR
// ═══════════════════════════════════════════════════════════════

float generate_cracks(vec2 uv, float intensity) {
    float n1 = noise(uv * 30.0);
    float n2 = noise(uv * 15.0 + vec2(5.0));
    return smoothstep(0.6, 0.65, pow(n1 * n2, 2.0)) * intensity;
}


// ═══════════════════════════════════════════════════════════════
// FRAGMENT — Final color assembly
// ═══════════════════════════════════════════════════════════════

void fragment() {
    // Unpack effect flags
    float edge_detection = effect_flags.x;
    float cellular_influence = effect_flags.y;
    float darkness = effect_flags.z;
    float color_mixing = effect_flags.w;

    // UV processing with rotation and scale
    // Instance custom data: .r adds extra pattern rotation (0-1 → 0-TAU)
    float total_rotation = pattern_rotation;
    if (v_instance_custom.r > 0.001) {
        total_rotation += v_instance_custom.r * 6.28318;
    }
    vec2 base_uv = UV * pattern_scale;
    vec2 rotated_uv = rotate2d(total_rotation) * base_uv;

    // Subtle time-based distortion (skip at low LOD)
    vec2 final_uv = rotated_uv;
    if (detail_level > 0.5) {
        float adj_density = pattern_density * detail_level;
        vec2 distort = vec2(
            sin(rotated_uv.y * 5.0 * adj_density + TIME * 0.3) * 0.03,
            cos(rotated_uv.x * 5.0 * adj_density + TIME * 0.3) * 0.03
        );
        final_uv += distort * smoothstep(0.0, 0.5, pattern_type);
    }

    // ── Pattern ──
    float adj_density = pattern_density * detail_level;
    float base_pattern = generate_base_pattern(final_uv, pattern_type, adj_density, pattern_intensity);

    // Cellular overlay
    if (cellular_influence > 0.01) {
        float cell_size = 10.0 * (0.5 + adj_density);
        float cell = voronoi_cellular(final_uv, cell_size, 0.5 + adj_density * 0.3, 0.05 * (0.5 + pattern_intensity * 0.5));
        base_pattern = mix(base_pattern, cell, cellular_influence);
    }

    // Edge detection overlay
    float edge_value = 0.0;
    if (edge_detection > 0.01) {
        edge_value = detect_edges(base_pattern, 2.0 * pattern_intensity);
    }

    // ── Color mixing ──
    vec3 dark_primary = primary_color.rgb * (1.0 - darkness);
    vec3 dark_secondary = secondary_color.rgb * (1.0 - darkness);
    vec3 dark_wing = wing_color.rgb * (1.0 - darkness);

    vec3 base_color = mix(dark_primary, dark_secondary, base_pattern);

    // Edge color
    if (edge_detection > 0.01) {
        vec3 edge_color = mix(dark_primary * 0.4, dark_wing * 0.7, 0.5);
        base_color = mix(base_color, edge_color, edge_value * edge_detection);
    }

    // Three-color blend
    if (color_mixing > 0.01) {
        vec3 mixed = mix(mix(dark_primary, dark_secondary, 0.5), dark_wing, color_mixing * 0.5);
        base_color = mix(base_color, mixed, color_mixing * base_pattern);
    }

    // ── Iridescence (view-dependent color shift) ──
    if (iridescence > 0.001) {
        float view_dot = max(0.001, dot(NORMAL, VIEW));
        float fresnel = pow(1.0 - view_dot, 3.0);
        float hue = final_uv.x * 0.5 + final_uv.y * 0.2 + TIME * 0.1;
        vec3 iri = vec3(
            0.5 + 0.5 * sin(hue * 6.28318),
            0.5 + 0.5 * sin(hue * 6.28318 + 2.09439),
            0.5 + 0.5 * sin(hue * 6.28318 + 4.18879)
        );
        base_color = mix(base_color, iri, iridescence * fresnel * 0.8);
    }

    // ── Cracking (metamorphosis / aging) ──
    if (cracking > 0.001) {
        float crack = generate_cracks(UV, cracking);
        base_color = mix(base_color, base_color * 0.2, crack);
    }

    // ── Bond / Transmutation rim light ──
    if (rim_light > 0.001) {
        float view_dot = max(0.0, dot(NORMAL, VIEW));
        float rim = pow(1.0 - view_dot, 3.0) * rim_light;
        base_color = mix(base_color, rim_color.rgb, rim * 0.6);
    }

    // ── MultiMesh per-instance color tint ──
    // When used in MultiMesh, v_instance_color carries per-instance tint.
    // When used as individual MeshInstance3D, v_instance_color is (1,1,1,1) — no effect.
    base_color *= v_instance_color.rgb;

    // ── Final PBR output ──
    ALBEDO = base_color;

    if (transparency > 0.05) {
        ALPHA_SCISSOR_THRESHOLD = 0.1;
    }
    ALPHA = 1.0 - transparency;

    METALLIC = metallic;
    ROUGHNESS = roughness;
    SPECULAR = specular_tint;

    // Emission from bond overlay
    if (emission_energy > 0.001) {
        EMISSION = base_color * emission_energy;
    }
}
