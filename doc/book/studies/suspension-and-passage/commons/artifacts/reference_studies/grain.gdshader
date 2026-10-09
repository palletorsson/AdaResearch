shader_type spatial;
uniform vec4 stone : source_color = vec4(0.48, 0.45, 0.40, 1.0);
varying vec3 local_position;
void vertex() { local_position = VERTEX; }
float hash(vec3 p) { return fract(sin(dot(p,vec3(12.98,78.23,37.71)))*43758.54); }
void fragment() {
    float grain = hash(floor(local_position * 160.0));
    float aggregate = hash(floor(local_position * 22.0));
    ALBEDO = stone.rgb * (0.72 + 0.30 * grain + 0.20 * aggregate);
    ROUGHNESS = 0.97;
}
