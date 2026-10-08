shader_type spatial;
render_mode cull_disabled;
uniform vec4 colour_a : source_color = vec4(1.0,0.1,0.35,1.0);
uniform vec4 colour_b : source_color = vec4(0.05,0.01,0.12,1.0);
uniform float density = 4.0;
uniform float phase = 0.0;
uniform float clock = 0.0;
uniform int pattern = 0;
varying vec3 world_position;
varying vec3 world_normal;
void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
    world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
float tile(vec2 p) {
    if (pattern == 1) return step(0.28, length(fract(p)-0.5));
    if (pattern == 2) return step(0.5, fract(p.x+p.y));
    return mod(floor(p.x)+floor(p.y),2.0);
}
void fragment() {
    vec3 weights = pow(abs(world_normal),vec3(10.0));
    weights /= max(weights.x+weights.y+weights.z,0.001);
    vec3 p = world_position*density+vec3(phase+clock*0.13);
    float pattern_value = tile(p.zy)*weights.x+tile(p.xz)*weights.y+tile(p.xy)*weights.z;
    ALBEDO = mix(colour_a.rgb,colour_b.rgb,pattern_value);
    EMISSION = ALBEDO * 0.08;
    ROUGHNESS = 0.62;
}
