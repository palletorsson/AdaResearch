shader_type spatial;

// ═══════════════════════════════════════════════════════════════
// living_ground.gdshader — DNA-driven terrain expression
//
// Reads a presence texture from PresenceGrid and transforms the
// ground surface. Each RGBA channel represents a kingdom's mark:
//   R = tree (moss/green), G = creature (trails), B = flower (pollen), A = fungus (mycelium)
//
// The ground becomes a living record of what organisms have been here.
// ═══════════════════════════════════════════════════════════════

// Base ground — warm earth with organic texture (not dead gray)
uniform vec3 base_color_warm : source_color = vec3(0.28, 0.22, 0.15);  // Warm brown earth
uniform vec3 base_color_cool : source_color = vec3(0.18, 0.2, 0.16);   // Cool green-gray
uniform float base_roughness : hint_range(0.0, 1.0) = 0.82;
uniform float base_texture_scale : hint_range(1.0, 20.0) = 6.0;

// Presence texture from PresenceGrid
uniform sampler2D presence_map : filter_linear, repeat_disable;

// World mapping (must match PresenceGrid world_size)
uniform vec2 world_size = vec2(50.0, 50.0);
uniform vec2 world_offset = vec2(0.0, 0.0);

// Kingdom colors — what presence paints onto the earth
uniform vec3 tree_color : source_color = vec3(0.12, 0.32, 0.08);     // Deep moss green
uniform vec3 creature_color : source_color = vec3(0.3, 0.22, 0.12);  // Worn dusty path
uniform vec3 flower_color : source_color = vec3(0.45, 0.35, 0.12);   // Warm pollen gold
uniform vec3 fungus_color : source_color = vec3(0.3, 0.1, 0.4);      // Rich mycelium purple

// Vertex displacement strength
uniform float displacement_strength : hint_range(0.0, 0.5) = 0.15;

// Animation
uniform float time_scale : hint_range(0.0, 2.0) = 1.0;

// Internal
varying vec2 v_world_xz;
varying vec4 v_presence;


// ── Noise ──
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


void vertex() {
    // World position for presence lookup
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    v_world_xz = world_pos.xz;

    // Sample presence at this vertex
    vec2 presence_uv = (v_world_xz - world_offset + world_size * 0.5) / world_size;
    v_presence = texture(presence_map, presence_uv);

    // ── Vertex displacement from presence ──
    float tree_p = v_presence.r;
    float creature_p = v_presence.g;
    float flower_p = v_presence.b;
    float fungus_p = v_presence.a;

    float height = 0.0;

    // Tree presence: raise ground (root humps)
    if (tree_p > 0.05) {
        float root_noise = noise(v_world_xz * 3.0) * 0.5 + 0.5;
        height += tree_p * displacement_strength * root_noise;
    }

    // Creature presence: lower ground (footpaths)
    if (creature_p > 0.05) {
        height -= creature_p * displacement_strength * 0.5;
    }

    // Fungus presence: slow undulation (breathing ground)
    if (fungus_p > 0.05) {
        float breath = sin(TIME * time_scale * 0.8 + v_world_xz.x * 2.0 + v_world_xz.y * 1.5) * 0.5 + 0.5;
        height += fungus_p * displacement_strength * 0.3 * breath;
    }

    VERTEX.y += height;
}


void fragment() {
    // Re-sample presence at fragment level for smoother color
    vec2 presence_uv = (v_world_xz - world_offset + world_size * 0.5) / world_size;
    vec4 presence = texture(presence_map, presence_uv);

    float tree_p = presence.r;
    float creature_p = presence.g;
    float flower_p = presence.b;
    float fungus_p = presence.a;
    float total = tree_p + creature_p + flower_p + fungus_p;

    // ── Base ground — warm earthy texture, not flat gray ──
    // Multi-octave noise for organic soil variation
    float soil_n1 = noise(v_world_xz * base_texture_scale);
    float soil_n2 = noise(v_world_xz * base_texture_scale * 2.3 + vec2(5.7, 3.1));
    float soil_n3 = noise(v_world_xz * base_texture_scale * 0.4 + vec2(11.0, 7.0));
    float soil_blend = soil_n1 * 0.5 + soil_n2 * 0.3 + soil_n3 * 0.2;

    // Blend warm and cool earth tones with noise
    vec3 color = mix(base_color_warm, base_color_cool, soil_blend);

    // Add subtle dark patches (pebbles / organic debris)
    float debris = smoothstep(0.55, 0.65, noise(v_world_xz * 18.0));
    color *= mix(1.0, 0.75, debris * 0.4);

    // Subtle warm highlights (dry patches catching light)
    float highlight = smoothstep(0.6, 0.8, noise(v_world_xz * 4.0 + vec2(20.0, 15.0)));
    color = mix(color, base_color_warm * 1.3, highlight * 0.15);

    // ── Tree presence: moss/grass green ──
    if (tree_p > 0.02) {
        // Noise-modulated moss patches
        float moss_noise = noise(v_world_xz * 8.0) * 0.5 + 0.5;
        float moss = smoothstep(0.0, 0.5, tree_p) * moss_noise;
        color = mix(color, tree_color, moss * 0.8);
    }

    // ── Creature presence: worn trails ──
    if (creature_p > 0.02) {
        // Flattened, lighter earth
        float trail = smoothstep(0.0, 0.4, creature_p);
        color = mix(color, creature_color, trail * 0.6);
    }

    // ── Flower presence: pollen shimmer ──
    if (flower_p > 0.02) {
        float pollen = smoothstep(0.0, 0.3, flower_p);
        // Warm shift with subtle sparkle
        float sparkle = noise(v_world_xz * 30.0 + vec2(TIME * time_scale * 0.5, 0.0));
        sparkle = smoothstep(0.7, 0.9, sparkle) * flower_p;
        color = mix(color, flower_color, pollen * 0.7);
        color += vec3(sparkle * 0.15, sparkle * 0.1, 0.0);  // Golden sparkle
    }

    // ── Fungus presence: mycelium veins ──
    if (fungus_p > 0.02) {
        // Vein pattern using noise gradient
        float vein_noise = noise(v_world_xz * 12.0);
        float vein = smoothstep(0.45, 0.55, vein_noise) * fungus_p;
        // Purple tint for mycelium mat
        float mat_strength = smoothstep(0.0, 0.5, fungus_p);
        color = mix(color, fungus_color, mat_strength * 0.6);
        // Vein highlights
        color += vec3(0.1, 0.0, 0.15) * vein * 0.5;
    }

    // ── Normal perturbation from presence gradients ──
    vec3 normal_offset = vec3(0.0, 0.0, 1.0);
    if (total > 0.05) {
        // Compute presence gradient for normal perturbation
        float dx = texture(presence_map, presence_uv + vec2(1.0 / float(textureSize(presence_map, 0).x), 0.0)).r
                  - texture(presence_map, presence_uv - vec2(1.0 / float(textureSize(presence_map, 0).x), 0.0)).r;
        float dy = texture(presence_map, presence_uv + vec2(0.0, 1.0 / float(textureSize(presence_map, 0).y))).r
                  - texture(presence_map, presence_uv - vec2(0.0, 1.0 / float(textureSize(presence_map, 0).y))).r;
        normal_offset = normalize(vec3(dx * 2.0, dy * 2.0, 1.0));
    }

    // ── Output ──
    ALBEDO = color;
    ROUGHNESS = mix(base_roughness, 0.5, total * 0.5);  // Smoother where presence is high
    METALLIC = 0.0;

    // Normal map from presence
    NORMAL_MAP = normal_offset;

    // Emission from high fungus presence (bioluminescence)
    if (fungus_p > 0.4) {
        float glow = (fungus_p - 0.4) * 1.5;
        EMISSION = fungus_color * glow * 0.3;
    }

    // Emission from high flower presence (pollen glow)
    if (flower_p > 0.5) {
        float glow = (flower_p - 0.5) * 2.0;
        EMISSION += flower_color * glow * 0.15;
    }
}
