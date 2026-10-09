shader_type spatial;
render_mode unshaded;
uniform vec4 ink : source_color = vec4(1.0);
uniform float brightness : hint_range(1.0, 12.0) = 5.0;
void fragment() {
    // HDR output supplies the screen-glow threshold without scene illumination.
    ALBEDO = ink.rgb * brightness;
}
