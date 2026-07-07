shader_type spatial;
render_mode blend_mix, cull_disabled, diffuse_lambert, specular_schlick_ggx, depth_prepass_alpha;

// ═══════════════════════════════════════════════════════════════
// critter_dna.gdshader — Universal DNA-expression shader
//
// Drives all five kingdoms (tree, creature, flower, fungus, hybrid)
// from a single shader. 20 interpolatable patterns, 5 surface types,
// vertex breathing/wind/tension, and per-part material interpretation.
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

// --- Surface type (kingdom-derived, per-part) ---
// 0=bark, 1=scales, 2=petal, 3=membrane, 4=fur/velvet
uniform float surface_type : hint_range(0.0, 4.0) = 0.0;

// --- LOD ---
uniform float detail_level : hint_range(0.1, 1.0) = 1.0;

// --- Animation: Wave/Wind ---
uniform float wave_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float wave_amplitude : hint_range(0.0, 0.5) = 0.5;
uniform float wave_frequency : hint_range(0.1, 20.0) = 10.0;
uniform float wave_speed : hint_range(0.0, 10.0) = 3.0;
uniform vec2 wave_direction = vec2(1.0, 0.0);

// --- Animation: Breathing (all kingdoms) ---
uniform float breath_speed : hint_range(0.1, 5.0) = 1.5;
uniform float breath_amplitude : hint_range(0.0, 0.1) = 0.015;

// --- Animation: Tension shimmer (creatures under stress) ---
uniform float tension : hint_range(0.0, 1.0) = 0.0;

// --- Bond / Transmutation overlay ---
uniform float emission_energy : hint_range(0.0, 2.0) = 0.0;
uniform float rim_light : hint_range(0.0, 1.0) = 0.0;
uniform vec4 rim_color : source_color = vec4(0.8, 0.9, 1.0, 1.0);


// ═══════════════════════════════════════════════════════════════
// MULTIMESH INSTANCE DATA
// ═══════════════════════════════════════════════════════════════

varying vec4 v_instance_color;
varying vec4 v_instance_custom;
varying float v_height_factor;  // 0 at base, 1 at top — for wind weighting


// ═══════════════════════════════════════════════════════════════
// VERTEX — Breathing + height-weighted wind + tension shimmer
// ═══════════════════════════════════════════════════════════════

void vertex() {
    v_instance_color = COLOR;
    v_instance_custom = INSTANCE_CUSTOM;

    // ── Tier 2.5: per-instance TAPER for batched limbs / body ──
    // CreatureBatcher writes:
    //   INSTANCE_CUSTOM.x = top_radius / bottom_radius (taper factor)
    //   INSTANCE_CUSTOM.w = 1.0 to enable this transform; 0.0 (default
    //                       for non-multimesh instances) means leave
    //                       VERTEX alone.
    // Canonical mesh is a unit cylinder centred on origin (-0.5..+0.5
    // in y); we lerp xz scale from 1.0 at y=-0.5 (bottom) to taper
    // at y=+0.5 (top).
    if (INSTANCE_CUSTOM.w > 0.5) {
        float taper_factor = INSTANCE_CUSTOM.x;
        float t = clamp(VERTEX.y + 0.5, 0.0, 1.0);  // 0 bottom, 1 top
        float xz_scale = mix(1.0, taper_factor, t);
        VERTEX.xz *= xz_scale;
        // Adjust normal so lighting still reads correctly on tapered
        // surfaces. For a cone-frustum, the surface normal tilts
        // outward by atan((1 - taper_factor)/2). Approximate by
        // scaling NORMAL.y inversely to xz scale and renormalising.
        NORMAL = normalize(vec3(NORMAL.x, NORMAL.y / max(xz_scale, 0.001), NORMAL.z));
    }

    // Height factor for wind weighting (more sway at top)
    v_height_factor = clamp(VERTEX.y * 0.5, 0.0, 1.0);

    // 1. BREATHING — subtle normal-direction pulsing (all kingdoms)
    if (breath_amplitude > 0.001) {
        float breath = sin(TIME * breath_speed) * breath_amplitude;
        VERTEX += NORMAL * breath;
    }

    // 2. WIND SWAY — direction-aware, height-weighted (trees, flowers)
    if (wave_intensity > 0.01) {
        vec2 dir = normalize(wave_direction);
        float phase = dot(VERTEX.xz, dir) * wave_frequency + TIME * wave_speed;
        float hf = v_height_factor;  // sway more at top
        VERTEX.x += sin(phase) * wave_amplitude * wave_intensity * hf;
        VERTEX.z += cos(phase * 0.7) * wave_amplitude * wave_intensity * 0.5 * hf;
        VERTEX.y += sin(phase * 1.3) * wave_amplitude * wave_intensity * 0.3;
    }

    // 3. TENSION SHIMMER — jitter when stressed (creatures)
    if (tension > 0.01) {
        float jitter_phase = TIME * 12.0 + float(VERTEX_ID) * 3.7;
        vec3 jitter = NORMAL * tension * 0.02 * sin(jitter_phase);
        VERTEX += jitter;
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
// PATTERN HELPERS
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
// PATTERN EVALUATOR
// ═══════════════════════════════════════════════════════════════

float eval_pattern(int idx, vec2 uv, float freq_mult, float detail_mult) {
    if (idx == 0) { return 1.0 - smoothstep(0.3 / detail_mult, 0.5 / detail_mult, length(fract(uv * freq_mult * 0.5) - 0.5)); }
    else if (idx == 1) { return 0.5 + 0.5 * sign(sin(uv.x * freq_mult * 0.6)); }
    else if (idx == 2) { return max(0.5 + 0.5 * sign(sin(uv.x * freq_mult * 0.4)), 0.5 + 0.5 * sign(sin(uv.y * freq_mult * 0.4))); }
    else if (idx == 3) { return 0.5 + 0.5 * sin(uv.x * freq_mult * 0.7 + uv.y * freq_mult * 0.4 + noise(uv * 2.0) * 3.14159 * (detail_mult - 0.5)); }
    else if (idx == 4) { return noise(uv * freq_mult * 0.4); }
    else if (idx == 5) { return voronoi(uv, freq_mult * 0.3); }
    else if (idx == 6) { float f = 0.0; float a = 1.0; float fr = 1.0; for (int i = 0; i < 3; i++) { f += a * noise(uv * freq_mult * fr); a *= 0.5; fr *= 2.0; } return fract(f * 3.0); }
    else if (idx == 7) { float b = 0.0; for (int i = 0; i < 3; i++) { vec2 off = vec2(sin(float(i) * 1.57), cos(float(i) * 1.57)) * 0.5; b += smoothstep(0.2, 0.7, 1.0 - length((fract(uv * freq_mult * 0.25) - 0.5) - off)); } return clamp(b, 0.0, 1.0); }
    else if (idx == 8) { return step(0.5, noise(uv * freq_mult * 0.6)) * step(0.5, noise((uv + vec2(1.3, 2.7)) * freq_mult * 0.4)); }
    else if (idx == 9) { return 0.5 + 0.5 * (sin(uv.x * freq_mult * 0.5) * sin(uv.y * freq_mult * 0.6) * sin((uv.x + uv.y) * freq_mult * 0.4)); }
    else if (idx == 10) { return detect_edges(noise(uv * freq_mult * 0.3), 1.0); }
    else if (idx == 11) { vec2 t = fract(uv * freq_mult * 0.25) - 0.5; return step(t.x + t.y, 0.0); }
    else if (idx == 12) { return smoothstep(0.4, 0.5, length(fract(uv * freq_mult * 0.2) - 0.5)); }
    else if (idx == 13) { vec2 s = fract(uv * freq_mult * 0.3) - 0.5; float sx = abs(s.x); float sy = abs(s.y); return (1.0 - smoothstep(0.3, 0.35, max(sx, sy))) * (1.0 - smoothstep(0.15, 0.2, min(sx, sy))); }
    else if (idx == 14) { float h = step(0.5, fract(uv.x * freq_mult * 0.2)); float v = step(0.5, fract(uv.y * freq_mult * 0.2)); float th = step(0.9, fract(uv.x * freq_mult * 0.5)); float tv = step(0.9, fract(uv.y * freq_mult * 0.5)); return max(max(h, v), max(th, tv)); }
    else if (idx == 15) { return spiral_pattern(uv, freq_mult * 0.2, detail_mult); }
    else if (idx == 16) { return vortex_pattern(uv, freq_mult * 0.2, detail_mult); }
    else if (idx == 17) { return crystal_pattern(uv, freq_mult * 0.3, 2.0 + detail_mult * 3.0); }
    else if (idx == 18) { return sinusoidal_pattern(uv, freq_mult * 0.3, detail_mult); }
    else if (idx == 19) { return ripple_pattern(uv, freq_mult * 0.25, detail_mult); }
    return 0.5;
}


// ═══════════════════════════════════════════════════════════════
// MAIN PATTERN GENERATOR
// ═══════════════════════════════════════════════════════════════

float generate_base_pattern(vec2 uv, float type, float complexity, float intensity_mod) {
    complexity *= detail_level;
    float freq_mult = (5.0 + complexity * 15.0) * detail_level;
    float detail_mult = 0.5 + complexity;
    float pattern_idx = type * 19.0;
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
// SURFACE TYPE EFFECTS — per-kingdom material character
// Applied AFTER base pattern, BEFORE final PBR output
// ═══════════════════════════════════════════════════════════════

void apply_surface_effect(inout vec3 color, inout float r, inout float m,
                          inout vec3 normal_perturbation, vec2 uv, float NdotV) {
    int st = int(round(surface_type));

    if (st == 0) {
        // BARK — warm noise on normals, high roughness, crevice darkening
        float bark_noise = noise(uv * 40.0);
        float bark_crevice = smoothstep(0.3, 0.5, bark_noise);
        color *= mix(0.7, 1.0, bark_crevice);  // darken crevices
        color = mix(color, color * vec3(1.05, 0.98, 0.9), 0.3);  // warm shift
        normal_perturbation = vec3(
            (noise(uv * 60.0) - 0.5) * 0.15,
            (noise(uv * 60.0 + vec2(7.0, 3.0)) - 0.5) * 0.15,
            1.0
        );
        r = max(r, 0.7);  // bark is always rough
    }
    else if (st == 1) {
        // SCALES — hexagonal overlay, slight metallic sheen
        float hex = smoothstep(0.35, 0.45, length(fract(uv * 15.0) - 0.5));
        color = mix(color, color * 0.7, hex * 0.4);  // scale edges darker
        m = max(m, 0.15);  // slight metallic
        r = mix(r, 0.4, 0.3);  // smoother than bark
        normal_perturbation = vec3(
            (hex - 0.5) * 0.1,
            (hex - 0.5) * 0.1,
            1.0
        );
    }
    else if (st == 2) {
        // PETAL — subsurface scattering approximation, soft and translucent
        float sss = pow(max(0.0, 1.0 - NdotV), 2.0) * 0.3;
        color += color * sss;  // light bleeds through at edges
        color = mix(color, color * vec3(1.0, 0.95, 1.05), 0.2);  // cool-pink shift
        r = min(r, 0.35);  // petals are smooth
        m = 0.0;
    }
    else if (st == 3) {
        // MEMBRANE — thin-film iridescence, translucent glow
        float thin_film = pow(1.0 - NdotV, 4.0);
        float film_hue = uv.x * 3.0 + uv.y * 2.0 + TIME * 0.2;
        vec3 film_color = vec3(
            0.5 + 0.5 * sin(film_hue * 6.28),
            0.5 + 0.5 * sin(film_hue * 6.28 + 2.09),
            0.5 + 0.5 * sin(film_hue * 6.28 + 4.19)
        );
        color = mix(color, film_color, thin_film * 0.5);
        r = min(r, 0.25);
    }
    else if (st == 4) {
        // FUR/VELVET — rim sheen, normal perturbation for softness
        float rim = pow(1.0 - clamp(NdotV, 0.0, 1.0), 2.0);
        float fur_noise = rand(uv * 100.0);
        float noisy_rim = smoothstep(0.0, 1.0, rim) * (0.8 + 0.4 * fur_noise);
        vec3 sheen = mix(color * 1.5, vec3(1.0), 0.3) * noisy_rim * 0.6;
        color += sheen;
        normal_perturbation = vec3(
            (fur_noise - 0.5) * 0.08,
            (rand(uv * 100.0 + vec2(5.0, 3.0)) - 0.5) * 0.08,
            1.0
        );
        r = max(r, 0.75);  // fur is rough
    }
}


// ═══════════════════════════════════════════════════════════════
// FRAGMENT — Final color assembly with surface types
// ═══════════════════════════════════════════════════════════════

void fragment() {
    // Unpack effect flags
    float edge_detection = effect_flags.x;
    float cellular_influence = effect_flags.y;
    float darkness = effect_flags.z;
    float color_mixing = effect_flags.w;

    // UV processing
    float total_rotation = pattern_rotation;
    if (v_instance_custom.r > 0.001) {
        total_rotation += v_instance_custom.r * 6.28318;
    }
    vec2 base_uv = UV * pattern_scale;
    vec2 rotated_uv = rotate2d(total_rotation) * base_uv;

    // Subtle time-based distortion
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

    if (edge_detection > 0.01) {
        vec3 edge_color = mix(dark_primary * 0.4, dark_wing * 0.7, 0.5);
        base_color = mix(base_color, edge_color, edge_value * edge_detection);
    }

    if (color_mixing > 0.01) {
        vec3 mixed = mix(mix(dark_primary, dark_secondary, 0.5), dark_wing, color_mixing * 0.5);
        base_color = mix(base_color, mixed, color_mixing * base_pattern);
    }

    // ── Surface type effects ──
    float NdotV = max(0.001, dot(NORMAL, VIEW));
    float final_roughness = roughness;
    float final_metallic = metallic;
    vec3 normal_perturbation = vec3(0.0, 0.0, 1.0);

    apply_surface_effect(base_color, final_roughness, final_metallic,
                         normal_perturbation, final_uv, NdotV);

    // ── Iridescence (view-dependent color shift) ──
    if (iridescence > 0.001) {
        float fresnel = pow(1.0 - NdotV, 3.0);
        float hue = final_uv.x * 0.5 + final_uv.y * 0.2 + TIME * 0.1;
        vec3 iri = vec3(
            0.5 + 0.5 * sin(hue * 6.28318),
            0.5 + 0.5 * sin(hue * 6.28318 + 2.09439),
            0.5 + 0.5 * sin(hue * 6.28318 + 4.18879)
        );
        base_color = mix(base_color, iri, iridescence * fresnel * 0.8);
    }

    // ── Cracking ──
    if (cracking > 0.001) {
        float crack = generate_cracks(UV, cracking);
        base_color = mix(base_color, base_color * 0.2, crack);
    }

    // ── Bond / Transmutation rim light ──
    if (rim_light > 0.001) {
        float rim = pow(1.0 - NdotV, 3.0) * rim_light;
        base_color = mix(base_color, rim_color.rgb, rim * 0.6);
    }

    // ── MultiMesh per-instance tint ──
    base_color *= v_instance_color.rgb;

    // ── Final PBR output ──
    ALBEDO = base_color;

    if (transparency > 0.05) {
        ALPHA_SCISSOR_THRESHOLD = 0.1;
    }
    ALPHA = 1.0 - transparency;

    METALLIC = final_metallic;
    ROUGHNESS = final_roughness;
    SPECULAR = specular_tint;

    // Normal perturbation from surface type
    if (length(normal_perturbation.xy) > 0.001) {
        NORMAL_MAP = normalize(normal_perturbation);
    }

    // Emission
    if (emission_energy > 0.001) {
        EMISSION = base_color * emission_energy;
    }
}
