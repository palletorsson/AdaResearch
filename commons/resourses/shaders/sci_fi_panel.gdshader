shader_type spatial;

uniform vec4 base_color : source_color = vec4(0.08, 0.09, 0.11, 1.0);
uniform vec4 line_color : source_color = vec4(0.55, 0.8, 1.0, 1.0);
uniform vec4 accent_color : source_color = vec4(0.15, 0.6, 1.0, 1.0);
uniform float line_width : hint_range(0.001, 0.05) = 0.02;
uniform float panel_scale : hint_range(0.1, 4.0) = 1.0;
uniform float accent_density : hint_range(0.0, 1.0) = 0.35;
uniform float scratch_intensity : hint_range(0.0, 1.0) = 0.2;
uniform float seed = 0.0;

// Pass world position from vertex to fragment (no built-in WORLD_POSITION in fragment)
varying vec3 v_world_pos;

void vertex() {
    v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// simple hash for noise-like variation
float hash(vec2 p){
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return fract(sin(p.x + p.y) * 43758.5453);
}

float grid_line(vec2 uv, float w){
    vec2 g = abs(fract(uv) - 0.5);
    float d = min(g.x, g.y);
    return smoothstep(w, 0.0, d);
}

void fragment(){
    // use interpolated world position for stable panel mapping
    vec3 p = v_world_pos;
    vec2 uv = p.xy * panel_scale + vec2(seed);

    // base color with subtle scratches
    float scratches = hash(uv * 8.0) * scratch_intensity;
    vec3 baseCol = base_color.rgb * (1.0 - 0.1 * scratches);

    // panel grid lines
    float lineMask = grid_line(uv, line_width);

    // random accents
    float accentMask = step(1.0 - accent_density, hash(floor(uv)));

    vec3 color = baseCol;
    color = mix(color, line_color.rgb, lineMask);
    color = mix(color, accent_color.rgb, accentMask * 0.25);

    ALBEDO = color;
    METALLIC = 0.2;
    ROUGHNESS = 0.6;
    // Boost emission so panel lines are clearly visible
    EMISSION = line_color.rgb * (lineMask * 0.6);
    ALPHA = 1.0;
}
