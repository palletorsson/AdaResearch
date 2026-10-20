shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float radius = 0.30;
uniform float softness = 0.0;
uniform vec2 centre = vec2(0.5, 0.5);
uniform vec4 ground : source_color = vec4(0.032, 0.039, 0.046, 1.0);
uniform vec4 ink : source_color = vec4(0.93, 0.89, 0.82, 1.0);

void fragment() {
    float d = distance(UV, centre);
    float mask = 1.0 - step(radius, d);
    if (softness > 0.0) {
        mask = 1.0 - smoothstep(radius - softness, radius + softness, d);
    }
    ALBEDO = mix(ground.rgb, ink.rgb, mask);
}
