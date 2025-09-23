shader_type spatial;
render_mode unshaded, depth_draw_opaque, cull_back;

uniform vec4 bg_color : source_color = vec4(0.70, 0.73, 0.76, 1.0);
uniform vec4 line_color : source_color = vec4(0.80, 0.00, 0.00, 1.0);
uniform float line_width = 0.012; // fraction of cell size
uniform int grid_cols = 34;
uniform int grid_rows = 20;
uniform float time_scale = 0.5;
uniform int field_type = 1; // 0=radial, 1=vortex, 2=uniform, 3=sinusoidal
uniform float field_strength = 1.4;
uniform float arrow_len = 0.035; // in UV units (scaled per cell)

float aastep(float threshold, float value) {
    float afwidth = fwidth(value) * 0.7071;
    return smoothstep(threshold - afwidth, threshold + afwidth, value);
}

vec2 field(vec2 p, float t) {
    if (field_type == 0) {
        // Radial from center (0.5,0.5)
        vec2 d = normalize(p - vec2(0.5));
        return d * field_strength;
    } else if (field_type == 1) {
        // Vortex around moving centers
        vec2 c1 = vec2(0.3 + 0.07 * sin(t*0.7), 0.35 + 0.06 * cos(t*0.9));
        vec2 c2 = vec2(0.72 + 0.05 * cos(t*0.6), 0.62 + 0.05 * sin(t*0.8));
        vec2 r1 = p - c1; vec2 r2 = p - c2;
        vec2 v = vec2(-r1.y, r1.x) / max(dot(r1,r1), 0.002);
        v += vec2(-r2.y, r2.x) / max(dot(r2,r2), 0.002);
        return v * field_strength * 0.12;
    } else if (field_type == 2) {
        return normalize(vec2(1.0, 0.25)) * field_strength;
    } else {
        float sx = sin((p.x*8.0 + t*0.8));
        float cz = cos((p.y*8.0 - t*0.6));
        return normalize(vec2(sx, cz)) * field_strength;
    }
}

// Signed distance to a capped line segment from uv
float sdSegment(vec2 uv, vec2 a, vec2 b) {
    vec2 pa = uv - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba*h);
}

void fragment() {
    // Use mesh UV as a stable 0..1 domain regardless of world size
    vec2 uv = UV;
    float t = TIME * time_scale;

    // Background
    ALBEDO = bg_color.rgb;
    EMISSION = vec3(0.0);
    ALPHA = bg_color.a;

    // Grid cell center in UV
    vec2 g = vec2(float(grid_cols), float(grid_rows));
    vec2 cell = floor(uv * g) / g;
    vec2 center = cell + 0.5/g;

    // Field and arrow endpoints in UV space
    vec2 v = field(center, t);
    float mag = clamp(length(v), 0.0, 2.5);
    vec2 dir = normalize(v + 1e-6);
    float half_len = arrow_len;
    vec2 a = center - dir * half_len;
    vec2 b = center + dir * half_len * (0.9 + 0.4*mag);

    // Shaft
    float d = sdSegment(uv, a, b);
    float lw = line_width / max(g.x, g.y);
    float shaft = 1.0 - aastep(lw, d);

    // Head (small dot at the end)
    float head = 1.0 - aastep(lw*1.7, length(uv - b));

    float mask = clamp(shaft + head, 0.0, 1.0);

    vec3 lc = line_color.rgb;
    ALBEDO = mix(ALBEDO, lc, mask);
    EMISSION = lc * (0.35 * mask);
}


