// portal_shader.gdshader
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 portal_color : source_color = vec4(0.0, 0.4, 1.0, 0.5);
uniform float ripple_speed = 1.0;
uniform float ripple_intensity = 0.1;

void vertex() {
    // Add some simple vertex animation for a ripple effect
    VERTEX.x += sin(TIME * ripple_speed + VERTEX.y) * ripple_intensity;
    VERTEX.y += cos(TIME * ripple_speed + VERTEX.x) * ripple_intensity;
}

void fragment() {
    // Basic portal effect with some edge glow
    float edge = 1.0 - abs(dot(NORMAL, VIEW));
    ALBEDO = portal_color.rgb;
    ALPHA = portal_color.a + edge * 0.5;
    EMISSION = portal_color.rgb * 1.5 * (1.0 + 0.5 * sin(TIME));
}