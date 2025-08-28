shader_type spatial;

uniform vec3 metaball_positions[8]; // Maximum 8 metaballs
uniform float threshold = 0.5;
uniform float influence_radius = 2.0;

void vertex() {
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float influence_sum = 0.0;

    for (int i = 0; i < 8; i++) {
        float distance = length(world_pos - metaball_positions[i]);
        influence_sum += 1.0 - smoothstep(0.0, influence_radius, distance);
    }

    float alpha = smoothstep(threshold - 0.1, threshold + 0.1, influence_sum);
    
    // Apply the metaball effect
    VERTEX += NORMAL * (alpha * 0.2);
    COLOR = vec4(1.0, 0.0, 0.0, alpha);
}

void fragment() {
    ALBEDO = COLOR.rgb;
    ALPHA = COLOR.a;
}
