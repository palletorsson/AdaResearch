shader_type spatial;

uniform vec4 shield_color = vec4(0.2, 0.5, 1.0, 0.8); // Base shield color
uniform float time_speed = 1.0;  // Speed of the shield animation
uniform float noise_scale = 5.0; // Scale of the noise effect
uniform sampler2D noise_texture; // Noise texture for dynamic energy patterns

void fragment() {
    // UV coordinates and time
    vec2 uv = UV;
    float time = TIME * time_speed;

    // Distortion effect using noise
    vec2 distorted_uv = uv * noise_scale + vec2(sin(time), cos(time));
    float noise_value = texture(noise_texture, distorted_uv).r;

    // Glow effect near edges
    float glow = smoothstep(0.8, 1.0, noise_value);

    // Combine glow and shield color
    vec3 final_color = shield_color.rgb * (0.5 + glow);
    ALBEDO = final_color;

    // Transparency (fades out toward the edges)
    ALPHA = shield_color.a * (0.3 + glow);
}
