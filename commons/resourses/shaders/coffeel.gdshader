shader_type canvas_item;

uniform float time : hint_range(0.0, 10.0); // Controls the mixing progression
uniform vec4 coffee_color  = vec4(0.2, 0.1, 0.05, 1.0); // Dark coffee color
uniform vec4 milk_color  = vec4(1.0, 0.9, 0.8, 1.0);    // Light milk color
uniform sampler2D noise_texture; // Noise texture for swirls
uniform vec2 resolution = vec2(512.0, 512.0);  // Canvas resolution

void fragment() {
    vec2 uv = FRAGCOORD.xy / resolution.xy;

    // Generate time-dependent noise texture
    vec2 noise_uv = uv * 2.0 + vec2(sin(time * 0.5), cos(time * 0.3));
    float noise = texture(noise_texture, noise_uv).r;

    // Decay over time to simulate mixing
    float mix_factor = smoothstep(0.0, 1.0, noise * 0.5 + sin(time) * 0.5);

    // Blend coffee and milk colors based on the noise
    vec4 color = mix(coffee_color, milk_color, mix_factor);

    COLOR = color;
}
