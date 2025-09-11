shader_type spatial;
render_mode blend_mix, cull_disabled, depth_prepass_alpha;

// ---------- Look ----------
uniform vec4  glass_tint : source_color = vec4(0.92, 0.98, 1.00, 0.96);
uniform float brightness : hint_range(0.0, 3.0) = 1.0;
uniform float roughness  : hint_range(0.0, 1.0) = 0.55;
uniform float metallic   : hint_range(0.0, 1.0) = 0.0;
uniform float specular   : hint_range(0.0, 1.0) = 0.5;

// ---------- Distortion ----------
uniform bool  use_noise = true;
uniform float noise_scale = 40.0;
uniform float noise_speed = 0.15;
uniform float noise_strength : hint_range(0.0, 2.0) = 0.8;

// ---------- Blur ----------
uniform bool  blur_enable = true;
uniform float blur_radius_px : hint_range(0.0, 8.0) = 2.5;
uniform float blur_strength   : hint_range(0.0, 2.0) = 1.0;

// Depth awareness
uniform float depth_fade : hint_range(0.0, 2.0) = 0.8;

// Screen + depth
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D DEPTH_TEXTURE  : hint_depth_texture;
 

// ---------------- Noise helpers ----------------
float hash21(vec2 p){
    p = fract(p * vec2(123.34, 345.45));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

float vnoise(vec2 p){
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));
    vec2  u = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

vec2 noise_grad(vec2 p){
    float e = 0.5 / max(noise_scale, 1.0);
    float nx = vnoise(p + vec2(e, 0.0)) - vnoise(p - vec2(e, 0.0));
    float ny = vnoise(p + vec2(0.0, e)) - vnoise(p - vec2(0.0, e));
    return vec2(nx, ny);
}

// ---------------- Fragment ----------------
void fragment(){
    vec2 distort = vec2(0.0);

    if (use_noise){
        vec2 nUV = UV * noise_scale + vec2(TIME, -TIME) * noise_speed;
        distort += noise_grad(nUV) * noise_strength;
    }

    // Depth fade
    float scene_depth = texture(DEPTH_TEXTURE, SCREEN_UV).r;
    float depth_factor = mix(1.0, 0.3, clamp(pow(scene_depth, 1.5) * depth_fade, 0.0, 1.0));
    distort *= depth_factor;

    // Pixel size (replacement for SCREEN_PIXEL_SIZE)
    vec2 pixel_size = 1.0 / VIEWPORT_SIZE;

    // Blur
    vec3 screen_col;
    if (blur_enable){
        float rN = blur_radius_px;
        vec2 dir[4] = vec2[4](
            vec2( 1.0, 0.0), vec2(-1.0, 0.0),
            vec2( 0.0, 1.0), vec2( 0.0,-1.0)
        );

        vec3 acc = texture(SCREEN_TEXTURE, SCREEN_UV + distort * pixel_size * rN).rgb;
        float wsum = 1.0;

        for (int i = 0; i < 4; i++){
            vec2 off = distort * 0.5 + dir[i] * rN * pixel_size;
            float w = 0.25 * blur_strength;
            acc += texture(SCREEN_TEXTURE, SCREEN_UV + off).rgb * w;
            wsum += w;
        }
        screen_col = acc / max(wsum, 1e-3);
    } else {
        screen_col = texture(SCREEN_TEXTURE, SCREEN_UV + distort * pixel_size * blur_radius_px).rgb;
    }

    vec3 col = screen_col * glass_tint.rgb * brightness;

    ALBEDO    = col;
    METALLIC  = metallic;
    ROUGHNESS = roughness;
    SPECULAR  = specular;
    ALPHA     = glass_tint.a;
}
