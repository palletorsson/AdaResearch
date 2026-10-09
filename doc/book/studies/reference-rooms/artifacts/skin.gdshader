shader_type spatial;
render_mode cull_disabled;
uniform float clock = 0.0;
uniform vec4 base_colour : source_color = vec4(0.56,0.28,0.45,1.0);
void fragment() {
    float facing = clamp(dot(normalize(NORMAL),normalize(VIEW)),0.0,1.0);
    float fringe = pow(1.0-facing,2.6);
    ALBEDO = mix(base_colour.rgb,vec3(0.66,0.81,0.93),fringe);
    METALLIC = 0.77;
    ROUGHNESS = 0.22;
    EMISSION = vec3(0.52,0.025,0.23)*fringe*0.22;
}
