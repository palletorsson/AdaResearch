shader_type spatial;
render_mode blend_mix, unshaded;

uniform vec4 slime_color : source_color = vec4(0.3, 0.9, 0.4, 0.7);
uniform float noise_scale = 2.0;
uniform float wobble_speed = 2.0;  // Increased speed
uniform float wobble_intensity = 0.2;  // Increased intensity
uniform sampler2D noise_texture : source_color;

void vertex() {
    vec3 pos = VERTEX;
    float time = TIME * wobble_speed;

    // Get multiple noise values for more complex wobble
    float noise1 = texture(noise_texture, UV * noise_scale + vec2(time, 0.0)).r;
    float noise2 = texture(noise_texture, UV * noise_scale * 1.5 + vec2(0.0, time * 0.5)).r;

    // Combine noise layers for more organic movement
    float wobble = (noise1 + noise2) * 0.5;

    // Increase wobble by scaling displacement
    pos += NORMAL * wobble * wobble_intensity;

    VERTEX = pos;
}

void fragment() {
    vec2 uv = UV * noise_scale;
    float noise = texture(noise_texture, uv + vec2(TIME * 0.05
	)).r;

    // Enhance color variation with more dynamic blending
    vec3 final_color = slime_color.rgb * mix(0.7, 1.3, noise);

    ALBEDO = final_color;
    ALPHA = slime_color.a;
    EMISSION = final_color * 0.5;  // Stronger glow effect
    METALLIC = 0.1;
    ROUGHNESS = 0.2;
}
