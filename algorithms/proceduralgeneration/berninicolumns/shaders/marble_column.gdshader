shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;

uniform vec3 base_color : source_color = vec3(0.70, 0.62, 0.78);
uniform vec3 vein_color : source_color = vec3(0.95, 0.35, 0.82);
uniform float vein_contrast : hint_range(0.5, 4.0) = 2.2;
uniform float vein_strength : hint_range(0.0, 1.0) = 0.55;
uniform float noise_scale : hint_range(0.05, 2.0) = 0.4;
uniform float turbulence : hint_range(0.0, 8.0) = 3.6;
uniform float swirl_strength : hint_range(0.0, 4.0) = 1.1;
uniform float u_time = 0.0;
uniform float time_speed : hint_range(0.0, 3.0) = 0.2;
uniform float metallic_amount : hint_range(0.0, 1.0) = 0.6;
uniform float roughness_amount : hint_range(0.0, 1.0) = 0.28;
uniform float emission_strength : hint_range(0.0, 2.0) = 0.2;
uniform float normal_perturb : hint_range(0.0, 1.0) = 0.25;

float hash(vec3 p) {
    return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float value_noise(vec3 p) {
    vec3 cell = floor(p);
    vec3 local = fract(p);
    vec3 smooth = local * local * (3.0 - 2.0 * local);

    float n000 = hash(cell + vec3(0.0, 0.0, 0.0));
    float n100 = hash(cell + vec3(1.0, 0.0, 0.0));
    float n010 = hash(cell + vec3(0.0, 1.0, 0.0));
    float n110 = hash(cell + vec3(1.0, 1.0, 0.0));
    float n001 = hash(cell + vec3(0.0, 0.0, 1.0));
    float n101 = hash(cell + vec3(1.0, 0.0, 1.0));
    float n011 = hash(cell + vec3(0.0, 1.0, 1.0));
    float n111 = hash(cell + vec3(1.0, 1.0, 1.0));

    float nx00 = mix(n000, n100, smooth.x);
    float nx10 = mix(n010, n110, smooth.x);
    float nx01 = mix(n001, n101, smooth.x);
    float nx11 = mix(n011, n111, smooth.x);

    float nxy0 = mix(nx00, nx10, smooth.y);
    float nxy1 = mix(nx01, nx11, smooth.y);

    return mix(nxy0, nxy1, smooth.z);
}

float fbm(vec3 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    for (int i = 0; i < 5; i++) {
        value += amplitude * value_noise(p * frequency);
        frequency *= 2.02;
        amplitude *= 0.55;
    }
    return value;
}

void fragment() {
    vec3 local_pos = VERTEX;
    float anim_time = u_time * time_speed;

    vec3 sample_pos = local_pos;
    sample_pos.xz += vec2(sin(local_pos.y * 0.35), cos(local_pos.y * 0.35)) * swirl_strength;
    sample_pos.y += anim_time;

    float base_noise = fbm(sample_pos * noise_scale);
    float marble_wave = sin(local_pos.y * turbulence + base_noise * 6.28318);
    marble_wave = 0.5 + 0.5 * marble_wave;
    marble_wave = pow(clamp(marble_wave, 0.0, 1.0), vein_contrast);

    float blend = clamp(marble_wave + base_noise * vein_strength, 0.0, 1.0);
    vec3 albedo_color = mix(base_color, vein_color, blend);

    ALBEDO = albedo_color;
    METALLIC = metallic_amount;
    ROUGHNESS = roughness_amount;
    EMISSION = albedo_color * emission_strength * blend;

    float eps = 0.02;
    float nx = fbm((sample_pos + vec3(eps, 0.0, 0.0)) * noise_scale);
    float ny = fbm((sample_pos + vec3(0.0, eps, 0.0)) * noise_scale);
    float nz = fbm((sample_pos + vec3(0.0, 0.0, eps)) * noise_scale);
    vec3 grad = vec3(nx - base_noise, ny - base_noise, nz - base_noise);
    grad = normalize(vec3(grad.x, grad.y * 0.5, grad.z));
    NORMAL = normalize(NORMAL + grad * normal_perturb);
}
