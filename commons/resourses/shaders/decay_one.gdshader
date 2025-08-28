shader_type spatial;

uniform sampler2D base_texture; // Base texture
uniform sampler2D decay_texture ; // Decay texture
uniform sampler2D noise_texture; // Noise texture for blending

uniform float decay_amount : hint_range(0.0, 1.0) = 0.5; // Overall decay intensity
uniform float decay_scale : hint_range(0.1, 5.0) = 1.0; // Scale of decay patterns
uniform float grime_amount : hint_range(0.0, 1.0) = 0.5; // Intensity of grime
uniform vec3 dirt_color = vec3(0.5, 0.3, 0.1); // Color of the dirt

uniform float roughness_decay : hint_range(0.0, 1.0) = 0.5; // Additional roughness from decay
uniform float metallic_decay : hint_range(0.0, 1.0) = 0.0; // Reduced metallic property

void fragment() {
    // Base UV and scaled UV for decay
    vec2 uv = UV;
    vec2 decay_uv = UV * decay_scale;

    // Sample textures
    vec4 base_color = texture(base_texture, uv);
    vec4 decay_color = texture(decay_texture, decay_uv);
    float noise = texture(noise_texture, decay_uv).r;

    // Decay blending using noise and intensity
    float decay_mask = smoothstep(0.5 - decay_amount * 0.5, 0.5 + decay_amount * 0.5, noise);
    vec3 blended_color = mix(base_color.rgb, mix(decay_color.rgb, dirt_color, grime_amount), decay_mask);

    // Adjust roughness and metallic
    float blended_roughness = mix(ROUGHNESS, roughness_decay, decay_mask);
    float blended_metallic = mix(METALLIC, metallic_decay, decay_mask);

    // Output final color
    ALBEDO = blended_color;
    ROUGHNESS = blended_roughness;
    METALLIC = blended_metallic;
}
