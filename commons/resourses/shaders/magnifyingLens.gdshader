shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx, unshaded;

uniform vec4 albedo : source_color = vec4(1.0, 1.0, 1.0, 0.0);  // Glass base color
uniform float specular = 0.5;  // Specular intensity
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Outline settings
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0); // Dark outline for the frame
uniform float outline_thickness = 1.5;  // Thickness of the lens frame

// Magnification settings
uniform float magnification_strength = 0.7; // Higher value = stronger magnification effect

void fragment() {
    vec3 norm = normalize(NORMAL); // Normal direction
    vec3 view_dir = normalize(VIEW); // Camera view direction

    // Fresnel-based edge detection for the lens frame
    float fresnel = pow(1.0 - dot(norm, view_dir), outline_thickness);

    // Screen magnification effect
    vec2 magnified_uv = SCREEN_UV - 0.5; // Centering UV
    magnified_uv *= magnification_strength; // Apply magnification
    magnified_uv += 0.5; // Reset position

    // Fetch the magnified screen texture
    vec4 magnified_texture = texture(SCREEN_TEXTURE, magnified_uv);

    // Blend outline with magnified texture
    vec3 final_color = mix(magnified_texture.rgb, outline_color.rgb, fresnel);

    // Output final shader properties
    ALBEDO = final_color;
    SPECULAR = specular;
}
