shader_type spatial;

uniform sampler2D noise_texture;
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float distortion_strength : hint_range(0.0, 1.0) = 0.1;
uniform vec4 glass_color = vec4(1.0, 1.0, 1.0, 0.8);

void fragment() {
    vec2 uv = UV;
    vec2 noise = texture(noise_texture, uv).rg - 0.5;
    vec2 distorted_uv = uv + noise * distortion_strength;

    vec3 scene_color = texture(screen_texture, distorted_uv).rgb;
    vec3 final_color = mix(scene_color, glass_color.rgb, glass_color.a);

    ALBEDO = final_color;
    ALPHA = glass_color.a;
}
