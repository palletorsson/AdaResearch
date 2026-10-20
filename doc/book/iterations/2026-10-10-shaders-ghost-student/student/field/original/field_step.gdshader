shader_type canvas_item;
render_mode unshaded, blend_disabled;
// Data, not colour: two 12-bit concentrations packed in RGB8. No source_color hint.
// The spare low nibbles share blue; alpha stays opaque on every renderer.
uniform sampler2D previous_state : filter_nearest, repeat_enable;
uniform float feed = 0.055;
uniform float kill = 0.062;
uniform bool integrate = true;
uniform vec2 brush = vec2(-10.0);
uniform float brush_radius = 0.04;
vec2 read_state(vec2 uv) {
    vec3 bytes = floor(texture(previous_state, uv).rgb * 255.0 + 0.5);
    return (bytes.rg * 16.0 + vec2(floor(bytes.b / 16.0), mod(bytes.b, 16.0))) / 4095.0;
}
vec4 pack_state(vec2 value) {
    vec2 bits = floor(clamp(value, vec2(0.0), vec2(1.0)) * 4095.0 + 0.5);
    return vec4(floor(bits / 16.0), mod(bits.x, 16.0) * 16.0 + mod(bits.y, 16.0), 255.0) / 255.0;
}
void fragment() {
    vec2 c = read_state(UV);
    if (integrate) {
        vec2 p = 1.0 / vec2(textureSize(previous_state, 0));
        vec2 lap = -c;
        lap += 0.2 * (read_state(UV + vec2(p.x, 0.0)) + read_state(UV - vec2(p.x, 0.0))
            + read_state(UV + vec2(0.0, p.y)) + read_state(UV - vec2(0.0, p.y)));
        lap += 0.05 * (read_state(UV + p) + read_state(UV - p)
            + read_state(UV + vec2(p.x, -p.y)) + read_state(UV + vec2(-p.x, p.y)));
        float reaction = c.x * c.y * c.y;
        // Gray–Scott: dt=1, Du=1, Dv=.5 with this weighted nine-cell stencil.
        c += vec2(lap.x - reaction + feed * (1.0 - c.x),
            0.5 * lap.y + reaction - (feed + kill) * c.y);
    }
    if (distance(UV, brush) < brush_radius) c = vec2(0.5, 1.0);
    COLOR = pack_state(c);
}
