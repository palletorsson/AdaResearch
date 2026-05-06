shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec3 base_color : source_color = vec3(0.1, 0.85, 0.95);
uniform vec3 glow_color : source_color = vec3(0.05, 0.35, 0.6);
uniform float line_thickness : hint_range(0.001, 0.1, 0.001) = 0.02;
uniform float frequency : hint_range(0.5, 12.0, 0.1) = 5.0;
uniform float amplitude : hint_range(0.0, 1.0, 0.01) = 0.45;
uniform float speed : hint_range(0.0, 5.0, 0.01) = 1.4;
uniform float secondary_frequency : hint_range(0.5, 16.0, 0.1) = 9.0;
uniform float secondary_amplitude : hint_range(0.0, 1.0, 0.01) = 0.18;
uniform float scanline_strength : hint_range(0.0, 1.0, 0.01) = 0.3;
uniform float grid_strength : hint_range(0.0, 1.0, 0.01) = 0.12;
uniform float vignette_strength : hint_range(0.0, 2.0, 0.01) = 0.8;

float hash(float x) {
    return fract(sin(x * 12.9898 + 78.233) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;
    vec2 centered = uv * 2.0 - 1.0;
    centered.y *= 0.9;

    float wave_primary = sin(centered.x * frequency + TIME * speed);
    float wave_secondary = sin(centered.x * secondary_frequency + TIME * speed * 1.7);
    float wave = wave_primary * amplitude + wave_secondary * secondary_amplitude;

    float dist = abs(centered.y - wave);
    float line = smoothstep(line_thickness, 0.0, dist);

    float scanline = sin(uv.y * 900.0) * 0.5 + 0.5;
    float grid = (sin(uv.x * 160.0) * sin(uv.y * 160.0)) * 0.25 + 0.25;
    float noise = hash(centered.x + TIME * 0.5) * 0.05;

    float vignette = 1.0 - dot(centered, centered) * vignette_strength;
    vignette = clamp(vignette, 0.0, 1.0);

    float intensity = line + scanline * scanline_strength + noise;
    intensity = clamp(intensity, 0.0, 1.0);

    vec3 base = mix(vec3(0.01, 0.02, 0.04), base_color, intensity);
    vec3 emission = glow_color * (intensity + grid * grid_strength) * vignette;

    ALBEDO = base;
    EMISSION = emission;
}
