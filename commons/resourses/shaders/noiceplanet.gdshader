shader_type spatial;

uniform float noise_scale = 0.5;  // Scale of the noise to make the glitter appear finer
uniform float height_multiplier = 0.2;  // Height scaling factor for the noise
uniform float noise_speed = 0.1;  // Speed at which the noise evolves over time
uniform float time_factor = 0.1;  // Factor to control how time affects the noise
uniform float loop_time = 720.0;  // Duration of one full loop (in seconds)

// Pass local object position to the fragment shader
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

void vertex() {
    vec3 object_pos = VERTEX;

    // Apply the noise in the XZ plane to avoid line streaks and make the noise "spotty"
    vec2 noise_input = vec2(object_pos.x * noise_scale, object_pos.z * noise_scale);

    // Generate a looping time component using sin and cos to ensure smooth periodicity
    float loop_phase = TIME * 2.0 * 3.14159265359 / loop_time;
    vec2 time_offset = vec2(sin(loop_phase), cos(loop_phase)) * time_factor * noise_speed;

    // Generate noise based on the vertex position and looping time
    float noise_value = noise(noise_input + time_offset);

    // Apply noise displacement along the vertex normal
    vec3 displacement = NORMAL * noise_value * height_multiplier;

    // Modify the vertex position based on the noise value
    VERTEX += displacement;

    // Pass the object space position to the fragment shader
    v_object_position = object_pos;  // Store the local object position instead of world position
}

void fragment() {
    // Use the object position passed from the vertex shader
    vec3 object_pos = v_object_position;

    // Generate a looping time component using sin and cos to ensure smooth periodicity
    float loop_phase = TIME * 2.0 * 3.14159265359 / loop_time;
    vec2 time_offset = vec2(sin(loop_phase), cos(loop_phase)) * time_factor * noise_speed;

    // Apply the noise in the XZ plane for more "spotty" effect rather than line streaks
    float noise_value = noise(vec2(object_pos.x * noise_scale, object_pos.z * noise_scale) + time_offset);

    // Set the base color with some modification based on noise
    ALBEDO = vec3(0.1, 0.1, 0.2) * noise_value;  // Use noise value to modulate color
}
