shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D motif : source_color, filter_nearest, repeat_enable;
uniform float repeats = 4.0;
uniform float phase = 0.0;

void fragment() {
    vec2 address = UV * vec2(repeats, 2.0) + vec2(0.0, 0.0);
    ALBEDO = texture(motif, address).rgb;
}
