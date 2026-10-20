shader_type spatial;

uniform vec4 ground : source_color = vec4(0.08, 0.02, 0.045, 1.0);
uniform vec4 ink : source_color = vec4(1.0, 0.05, 0.42, 1.0);
uniform vec4 edge_colour : source_color = vec4(0.18, 0.84, 0.80, 1.0);
uniform vec2 repeats = vec2(3.0);
uniform vec3 amounts = vec3(1.0, 0.6, 0.3);

void fragment() {
    vec2 cell = fract(UV * repeats);
    float mask = 1.0 - step(0.30, distance(cell, vec2(0.5)));
    vec3 colour = mix(ground.rgb, ink.rgb, mask * amounts.x);
    float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
    float edge = pow(1.0 - facing, 3.0);
    ALBEDO = colour;
    ROUGHNESS = 0.25;
    EMISSION = colour * (0.8 * amounts.z)
        + edge_colour.rgb * edge * 0.0;
}
