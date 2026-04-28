shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

// ═══════════════════════════════════════════════════════════════
// critter_dna_billboard.gdshader — DNA-driven foliage billboard
//
// The billboard counterpart of critter_dna.gdshader. Same uniform
// vocabulary so a single CritterDNA Resource produces matching visuals
// across solid and billboard parts: a bee's striped abdomen and its
// veined billboard wings come from one set of genes.
//
// Differences from the solid shader:
//   - VERTEX is bypassed; we compute world position from MODEL_MATRIX
//     translation column + camera-facing basis + per-instance scale.
//   - Wind sway acts only on the top half of the quad (UV.y > 0.5).
//   - Alpha mask atlas defines the SILHOUETTE; pattern fills the inside.
//   - Skipped: tension shimmer, breathing (these need real surfaces).
// ═══════════════════════════════════════════════════════════════

// ── Color (CritterDNA primary/secondary/tertiary) ──
uniform vec4 primary_color : source_color = vec4(0.95, 0.4, 0.65, 1.0);
uniform vec4 secondary_color : source_color = vec4(0.85, 0.25, 0.55, 1.0);
uniform vec4 wing_color : source_color = vec4(1.0, 0.85, 0.3, 1.0);

// ── Pattern (same as critter_dna.gdshader) ──
uniform float pattern_type : hint_range(0.0, 1.0) = 0.5;
uniform float pattern_density : hint_range(0.0, 1.0) = 0.5;
uniform float pattern_scale : hint_range(0.2, 5.0) = 1.0;
uniform float pattern_intensity : hint_range(0.0, 1.0) = 0.6;

// ── Material ──
uniform float roughness : hint_range(0.05, 1.0) = 0.7;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float iridescence : hint_range(0.0, 1.0) = 0.0;

// ── Animation: wind (DNA wave_*) ──
uniform float wave_amplitude : hint_range(0.0, 0.5) = 0.06;
uniform float wave_frequency : hint_range(0.0, 5.0) = 1.5;
uniform float wave_intensity : hint_range(0.0, 1.0) = 1.0;

// ── Billboard control ──
uniform sampler2D albedo_tex : source_color, hint_default_white;
uniform float alpha_threshold : hint_range(0.0, 1.0) = 0.5;
uniform float face_camera : hint_range(0.0, 1.0) = 1.0;

varying vec2 v_uv;
varying vec4 v_instance_color;


// ── Noise / pattern helpers (subset of critter_dna shader) ──
float rand(vec2 n) { return fract(sin(dot(n, vec2(12.9898, 78.233))) * 43758.5453); }

float noise(vec2 p) {
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u * u * (3.0 - 2.0 * u);
    return mix(
        mix(rand(ip), rand(ip + vec2(1.0, 0.0)), u.x),
        mix(rand(ip + vec2(0.0, 1.0)), rand(ip + vec2(1.0, 1.0)), u.x),
        u.y);
}

// Compact 5-pattern dispatch — covers the common foliage cases without
// dragging in all 20. Petals usually want dots/stripes/veins/scales.
float eval_billboard_pattern(int idx, vec2 uv, float freq) {
    if (idx == 0) {
        // dots
        return 1.0 - smoothstep(0.3, 0.5, length(fract(uv * freq * 0.5) - 0.5));
    } else if (idx == 1) {
        // stripes (tiger / bee abdomen)
        return 0.5 + 0.5 * sign(sin(uv.x * freq * 0.6));
    } else if (idx == 2) {
        // grid (scales / butterfly wing tiles)
        return max(0.5 + 0.5 * sign(sin(uv.x * freq * 0.4)),
                   0.5 + 0.5 * sign(sin(uv.y * freq * 0.4)));
    } else if (idx == 3) {
        // veins (sinusoidal — leaf venation)
        return 0.5 + 0.5 * sin(uv.x * freq * 0.7 + uv.y * freq * 0.4
            + noise(uv * 2.0) * 3.14159);
    } else if (idx == 4) {
        // organic noise blobs
        return noise(uv * freq * 0.4);
    }
    return 0.5;
}

float generate_pattern(vec2 uv, float t, float density, float intensity) {
    float freq = 5.0 + density * 15.0;
    float pattern_idx = t * 4.0;
    int lower = int(floor(pattern_idx)) % 5;
    int upper = int(ceil(pattern_idx)) % 5;
    float blend = fract(pattern_idx);
    float lower_val = eval_billboard_pattern(lower, uv, freq);
    float upper_val = eval_billboard_pattern(upper, uv, freq);
    return mix(0.5, mix(lower_val, upper_val, blend), intensity);
}


// ═══════════════════════════════════════════════════════════════
// VERTEX — Camera-facing basis + DNA-driven wind on top half
// ═══════════════════════════════════════════════════════════════

void vertex() {
    v_instance_color = COLOR;

    vec3 anchor_world = MODEL_MATRIX[3].xyz;
    float sx = length(MODEL_MATRIX[0].xyz);
    float sy = length(MODEL_MATRIX[1].xyz);

    // Y-locked camera-facing basis: keep world up vertical, rotate
    // around Y so the quad's normal points at the camera in the XZ
    // plane. This is the canonical foliage billboard.
    vec3 cam_world = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
    vec3 to_cam_flat = vec3(cam_world.x - anchor_world.x, 0.0,
                            cam_world.z - anchor_world.z);
    if (length(to_cam_flat) < 1e-4) {
        to_cam_flat = vec3(0.0, 0.0, 1.0);
    }
    vec3 facing_normal = normalize(to_cam_flat);
    vec3 facing_right = normalize(cross(vec3(0.0, 1.0, 0.0), facing_normal));
    vec3 facing_up = vec3(0.0, 1.0, 0.0);

    // Static basis from collector (when face_camera < 1).
    vec3 static_right = MODEL_MATRIX[0].xyz / max(sx, 1e-6);
    vec3 static_up    = MODEL_MATRIX[1].xyz / max(sy, 1e-6);

    vec3 right = mix(static_right, facing_right, face_camera);
    vec3 up    = mix(static_up,    facing_up,    face_camera);

    // Wind sway: top of the quad bends in world-X based on TIME and a
    // per-instance phase. Bottom stays anchored.
    float phase = float(INSTANCE_ID) * 0.7137;
    float wind = sin(TIME * wave_frequency + phase) * wave_amplitude * wave_intensity;
    float wind_mask = smoothstep(0.4, 1.0, UV.y);

    // QuadMesh local: VERTEX in -0.5..0.5 on X and Y, UV in 0..1.
    vec3 world_pos = anchor_world
        + right * (VERTEX.x * sx + wind * wind_mask)
        + up    * (VERTEX.y * sy);
    POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(world_pos, 1.0));
    NORMAL = normalize(cross(right, up));
    v_uv = UV;
}


// ═══════════════════════════════════════════════════════════════
// FRAGMENT — Alpha-mask silhouette + DNA pattern fill
// ═══════════════════════════════════════════════════════════════

void fragment() {
    // Silhouette comes from the alpha mask (atlas texture).
    vec4 mask = texture(albedo_tex, v_uv);
    if (mask.a < alpha_threshold) discard;

    // Fill the silhouette with a DNA-driven two-tone pattern.
    vec2 puv = v_uv * pattern_scale;
    float p = generate_pattern(puv, pattern_type, pattern_density, pattern_intensity);
    vec3 color = mix(primary_color.rgb, secondary_color.rgb, p);

    // Tint by per-instance vertex colour (lets the same shader carry
    // per-instance variations without changing uniforms).
    color *= v_instance_color.rgb;

    // Iridescence — view-dependent hue shift, same as critter shader.
    if (iridescence > 0.001) {
        float NdotV = max(0.001, dot(NORMAL, VIEW));
        float fresnel = pow(1.0 - NdotV, 3.0);
        float hue = v_uv.x * 0.5 + v_uv.y * 0.2 + TIME * 0.1;
        vec3 iri = vec3(
            0.5 + 0.5 * sin(hue * 6.28318),
            0.5 + 0.5 * sin(hue * 6.28318 + 2.09439),
            0.5 + 0.5 * sin(hue * 6.28318 + 4.18879)
        );
        color = mix(color, iri, iridescence * fresnel * 0.8);
    }

    ALBEDO = color;
    ALPHA = mask.a;
    ROUGHNESS = roughness;
    METALLIC = metallic;
}
