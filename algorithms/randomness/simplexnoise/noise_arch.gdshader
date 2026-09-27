shader_type spatial;
render_mode cull_disabled;
// UV = signed sample, boundary weight. UV2 locates the point on our arch.
uniform float relief_depth = 0.55;
void vertex() {
    float angle = UV2.x * 3.14159265359;
    vec3 direction = vec3(cos(angle), sin(angle), 0.0);
    VERTEX += direction * UV.x * UV.y * relief_depth;
}
void fragment() {
    vec3 face = cross(dFdx(VERTEX), dFdy(VERTEX));
    if (length(face) > 0.000001) {
        face = normalize(face);
        NORMAL = dot(face, VIEW) < 0.0 ? -face : face;
    }
    ALBEDO = COLOR.rgb;
    EMISSION = COLOR.rgb * 0.08;
    METALLIC = 0.12;
    ROUGHNESS = 0.65;
}
