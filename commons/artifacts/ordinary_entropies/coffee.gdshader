shader_type spatial;
render_mode cull_back;
uniform float mixing : hint_range(0.0, 1.0) = 0.0;
uniform float milk_fraction : hint_range(0.0, 1.0) = 0.25;
uniform float clock = 0.0;
uniform vec4 coffee_color : source_color = vec4(0.12, 0.045, 0.017, 1.0);
uniform vec4 milk_color : source_color = vec4(0.96, 0.89, 0.72, 1.0);
float ribbon(float p, float width) {
    return smoothstep(-width, width, p) - smoothstep(milk_fraction-width, milk_fraction+width, p);
}
void fragment() {
    vec2 p = UV * 2.0 - 1.0;
    float r2 = dot(p, p);
    if (r2 > 1.0) { discard; }
    // Angular shear preserves each annulus's milk fraction. Blending preserves
    // its mean too. This is a controlled illustration, not a fluid solver.
    float angle = atan(p.y, p.x) / 6.2831853 + 0.5;
    float turns = 0.12 + 8.0 * mixing + clock * 0.035 * (1.0 - mixing);
    float phase = fract(angle + turns * (1.0 - r2));
    float edge = 0.008 + 0.025 * mixing;
    float stripe = ribbon(phase-1.0, edge) + ribbon(phase, edge) + ribbon(phase+1.0, edge);
    float homogenised = smoothstep(0.25, 1.0, mixing);
    float cream = mix(stripe, milk_fraction, homogenised);
    ALBEDO = mix(coffee_color.rgb, milk_color.rgb, cream);
    ROUGHNESS = 0.23;
    SPECULAR = 0.5;
}
