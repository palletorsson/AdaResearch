shader_type canvas_item;

// Pipilotti Rist-inspired post-processing shader
// Creates dreamy, saturated visuals with color shifting effects

uniform float saturation : hint_range(0.0, 3.0) = 1.5;
uniform float color_shift_speed : hint_range(0.0, 1.0) = 0.2;
uniform float distortion_amount : hint_range(0.0, 0.2) = 0.03;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.4;
uniform float vignette_size : hint_range(0.0, 1.0) = 0.8;
uniform float time;

// Color adjustments
vec3 adjust_saturation(vec3 color, float _saturation) {
    float brightness = dot(color, vec3(0.299, 0.587, 0.114));
    return mix(vec3(brightness), color, _saturation);
}

// Chromatic aberration
vec3 chromatic_aberration(sampler2D tex, vec2 uv, float amount) {
    vec2 direction = normalize(uv - 0.5);
    vec3 result;
    
    // Sample the texture with RGB channel separation
    result.r = texture(tex, uv - direction * amount).r;
    result.g = texture(tex, uv).g;
    result.b = texture(tex, uv + direction * amount).b;
    
    return result;
}

// Dreamy distortion
vec2 distort_uv(vec2 uv, float _time, float amount) {
    vec2 center = vec2(0.5);
    vec2 distorted_uv = uv;
    
    // Subtle pulsing wave distortion
    float wave = sin(_time * 0.5 + uv.x * 5.0) * sin(_time * 0.3 + uv.y * 5.0) * amount;
    distorted_uv += vec2(wave, wave) * 0.5;
    
    return distorted_uv;
}

// Vignette effect
float vignette(vec2 uv, float size, float strength) {
    float dist = distance(uv, vec2(0.5));
    return smoothstep(size, size - 0.05, dist * strength);
}

// Color shifting over time
vec3 shift_colors(vec3 color, float ttime) {
    // Subtly shift the RGB balance over time
    float r_shift = sin(ttime * color_shift_speed * 1.1) * 0.1 + 0.9;
    float g_shift = sin(ttime * color_shift_speed * 0.9 + 2.0) * 0.1 + 0.9;
    float b_shift = sin(ttime * color_shift_speed * 0.7 + 4.0) * 0.1 + 0.9;
    
    return vec3(
        color.r * r_shift,
        color.g * g_shift,
        color.b * b_shift
    );
}

// Main fragment function
void fragment() {
    // Distort the UVs
    vec2 distorted_uv = distort_uv(UV, time, distortion_amount);
    
    // Apply chromatic aberration
    vec3 color = chromatic_aberration(TEXTURE, distorted_uv, distortion_amount * 0.5);
    
    // Apply saturating and color shifting
    color = adjust_saturation(color, saturation);
    color = shift_colors(color, time);
    
    // Apply vignette
    float vig = vignette(UV, vignette_size, vignette_strength);
    color *= mix(0.7, 1.0, vig);
    
    // Apply bloom-like glow to bright areas
    float luminance = dot(color, vec3(0.299, 0.587, 0.114));
    if (luminance > 0.8) {
        color += color * (luminance - 0.8) * 0.5;
    }
    
    // Final color
    COLOR = vec4(color, 1.0);
}