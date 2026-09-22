shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D motif : filter_nearest, repeat_enable;
uniform float repeats = 4.0;
uniform bool shaded = false;
uniform bool show_grid = false;
uniform vec3 light_direction = vec3(-0.7, 0.5, 1.0);
varying vec3 specimen_normal;
void vertex() { specimen_normal = NORMAL; }
void fragment() {
    vec2 address = UV * vec2(repeats, 2.0);
    vec3 ink = texture(motif, address).rgb;
    float gain = shaded ? 0.18 + 0.82 * max(dot(normalize(specimen_normal), normalize(light_direction)), 0.0) : 1.0;
    vec2 edge = min(fract(address), 1.0 - fract(address));
    if (show_grid && min(edge.x, edge.y) < 0.025) ink = vec3(0.04);
    ALBEDO = ink * gain;
}
