shader_type spatial;
render_mode cull_disabled;

uniform float noise_scale = 0.5;        // Scale of the noise for finer appearance
uniform float height_multiplier = 0.2;  // Height scaling factor for the noise
uniform float noise_speed = 0.05;       // Speed of the noise animation
uniform float elongation_factor = 2.0;  // Factor to elongate the sphere vertically
uniform float hue_shift_speed = 0.05;   // Speed of hue shift for a subtle rainbow effect

// 2026-09-12 (Noise_One, N2 of the noise arc): two readings of ONE field, so a room can put
// them side by side. Both default to 1.0, which is the shipped picture exactly — the ring
// displaces by the field and colours by the same field.
uniform float show_relief = 1.0;        // 1 = the field displaces the surface, 0 = it does not
uniform float show_colour = 1.0;        // 1 = the field colours it, 0 = one flat tone instead
uniform vec3 plain_albedo = vec3(0.60, 0.59, 0.56);   // the tone used when show_colour is 0
                                                      // (mid grey: a ridge has to cast a shade)

varying vec3 v_object_position;

// Simple 2D noise function
float hash(vec2 p) {
    p = 50.0 * fract(p * 0.3183099 + vec2(0.71, 0.113));
    return -1.0 + 2.0 * fract(p.x * p.y * (p.x + p.y));
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(
        mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
        u.y
    );
}

// Function to convert HSV to RGB
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void vertex() {
    vec3 object_pos = VERTEX;

    // Apply vertical elongation
    object_pos.y *= elongation_factor;

    // Noise input with animated offset
    vec2 noise_input = vec2(object_pos.x * noise_scale, object_pos.z * noise_scale);

    // --- FIX APPLIED HERE ---
    // Wrap TIME with mod() to prevent floating point precision loss over time.
    // The animation will now loop every hour, which is practically seamless.
    float wrapped_time = mod(TIME, 3600.0);
    float time_offset = wrapped_time * noise_speed;
    noise_input += vec2(time_offset, time_offset);

    // Generate noise and apply displacement
    float noise_value = noise(noise_input);
    vec3 displacement = NORMAL * noise_value * height_multiplier * show_relief;
    VERTEX = object_pos + displacement;

    // Pass object space position to fragment shader
    v_object_position = object_pos;
}

void fragment() {
    vec3 object_pos = v_object_position;

    // --- FIX APPLIED HERE ---
    // Use the same wrapped time value to keep the fragment color synchronized with the vertex displacement.
    float wrapped_time = mod(TIME, 3600.0);
    float time_offset = wrapped_time * noise_speed;
    vec2 noise_input = vec2(object_pos.x * noise_scale, object_pos.z * noise_scale) + vec2(time_offset, time_offset);

    // Generate noise and apply for color modulation
    float noise_value = noise(noise_input);

    // Rainbow color with hue shift (This part was already correct, as mod() was already in use)
    float hue_shift = mod(TIME * hue_shift_speed, 1.0);
    vec3 hsv_color = vec3(hue_shift, 1.0, 1.0); // Full saturation and brightness
    vec3 rainbow_color = hsv2rgb(hsv_color);

    // Set base color with noise-modulated brightness. NOTE what this does with the half of
    // the field that is negative: noise() returns -1..1, so a negative sample multiplies the
    // hue into negative albedo and the pipeline clamps it to black. The colour reading keeps
    // the positive half of the field and throws the rest away; the displacement above keeps
    // both halves and pushes inward for one of them. Same value, two readings, one of them
    // lossy — which is the whole subject of the room this shader stands in.
    ALBEDO = mix(plain_albedo, rainbow_color * noise_value, show_colour);

    // Emission with subtle sparkle effect
    EMISSION = rainbow_color * noise_value * 0.5 * show_colour;
}