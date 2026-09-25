shader_type spatial;
render_mode cull_disabled;

// The same CPU field supplies the pair, plates and room. UV carries its signed
// sample and the floor/door pinning weight; this vertex stage turns that sample
// into radial form. Collision uses the same expression at the same vertices.
uniform vec3 sphere_centre = vec3(0.0, 1.5, 0.2);
uniform float relief_depth = 0.8;

void vertex() {
    vec3 direction = normalize(VERTEX - sphere_centre);
    VERTEX += direction * UV.x * UV.y * relief_depth;
}

void fragment() {
    // Read the orientation of the displaced triangles, including their inside.
    vec3 face = cross(dFdx(VERTEX), dFdy(VERTEX));
    if (length(face) > 0.000001) {
        face = normalize(face);
        NORMAL = dot(face, VIEW) < 0.0 ? -face : face;
    }
    ALBEDO = COLOR.rgb;
    EMISSION = COLOR.rgb * 0.12;
    ROUGHNESS = 0.85;
}
