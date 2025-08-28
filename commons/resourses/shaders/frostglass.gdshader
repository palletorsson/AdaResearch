shader_type spatial;

uniform sampler2D noise_texture;  // Noise texture to create the ripple effect
uniform float distortion_strength : hint_range(0.0, 1.0) = 0.05; // Strength of the distortion
uniform float speed : hint_range(0.0, 10.0) = 1.0;  // Speed of the ripple animation
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    // Time-based movement to animate the ripples
    vec2 uv = FRAGCOORD.xy / UV.xy;
    float time = TIME * speed;

    // Sample noise texture for distortion
    vec2 noise_uv = uv + texture(noise_texture, uv + time * 0.1).rg * distortion_strength;

    // Apply noise-based distortion
    vec4 color = texture(SCREEN_TEXTURE, noise_uv);

    // Output the distorted color
    ALBEDO = color.rgb;
    ALPHA = color.a;
}
