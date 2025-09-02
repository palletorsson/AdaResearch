// reaction_diffusion.gdshader
shader_type canvas_item;

// Uniforms to control the simulation's parameters
uniform sampler2D last_frame ; // Texture from previous frame
uniform vec2 mouse_pos = vec2(-1.0, -1.0); // Mouse position to add chemicals
uniform float feed_rate : hint_range(0.0, 0.1) = 0.0545;
uniform float kill_rate : hint_range(0.0, 0.1) = 0.062;

// The diffusion rates for chemicals U and V
const float diff_u = 1.0;
const float diff_v = 0.5;
// Delta time for the integration step
const float delta_time = 1.0;

void fragment() {
    // Get the size of one pixel in UV coordinates
    // CORRECTED LINE: Cast the ivec2 from textureSize to a vec2
    vec2 pixel_size = 1.0 / vec2(textureSize(last_frame, 0));
    vec2 uv = UV;

    // --- 1. SAMPLE NEIGHBORS ---
    // Read the concentrations of U (in red channel) and V (in green channel)
    // from the current pixel and its 8 immediate neighbors.
    vec2 c = texture(last_frame, uv).rg;
    vec2 n = texture(last_frame, uv + vec2(0.0, -pixel_size.y)).rg;
    vec2 e = texture(last_frame, uv + vec2(pixel_size.x, 0.0)).rg;
    vec2 s = texture(last_frame, uv + vec2(0.0, pixel_size.y)).rg;
    vec2 w = texture(last_frame, uv + vec2(-pixel_size.x, 0.0)).rg;
    vec2 ne = texture(last_frame, uv + vec2(pixel_size.x, -pixel_size.y)).rg;
    vec2 nw = texture(last_frame, uv + vec2(-pixel_size.x, -pixel_size.y)).rg;
    vec2 se = texture(last_frame, uv + vec2(pixel_size.x, pixel_size.y)).rg;
    vec2 sw = texture(last_frame, uv + vec2(-pixel_size.x, pixel_size.y)).rg;

    // --- 2. CALCULATE LAPLACIAN ---
    // This approximates the diffusion (spreading) of the chemicals.
    // It's a weighted average of the neighbors' values minus the center's value.
    vec2 laplacian = (n + e + s + w) * 0.2 + (ne + nw + se + sw) * 0.05 - c * 1.0;

    // --- 3. GRAY-SCOTT REACTION ---
    // These are the core reaction equations.
    float u = c.r;
    float v = c.g;
    float uvv = u * v * v;
    float du = (diff_u * laplacian.r) - uvv + feed_rate * (1.0 - u);
    float dv = (diff_v * laplacian.g) + uvv - (kill_rate + feed_rate) * v;

    // --- 4. INTEGRATE ---
    // Apply the change over a small time step to get the new values.
    float new_u = u + delta_time * du;
    float new_v = v + delta_time * dv;

    // --- 5. MOUSE INTERACTION ---
    // If the mouse is over this pixel, add a splash of chemical V.
    if (distance(uv, mouse_pos) < 0.02) {
        new_v = 1.0;
    }

    // --- 6. OUTPUT ---
    // Write the new U and V concentrations to the Red and Green channels.
    // Clamp the values to keep them between 0 and 1.
    COLOR = vec4(clamp(new_u, 0.0, 1.0), clamp(new_v, 0.0, 1.0), 0.0, 1.0);
}