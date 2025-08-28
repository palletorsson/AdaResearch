// simulation_shader.gdshader
shader_type spatial;
render_mode unshaded;
uniform sampler2D prev_texture;
uniform vec2 texture_size = vec2(256.0, 256.0);


uniform sampler2D simulation_texture;

uniform float diffusion_a = 0.16;
uniform float diffusion_b = 0.08;
uniform float feed = 0.055;
uniform float kill = 0.062;
uniform float dt = 1.0;



float laplacian(sampler2D tex, vec2 uv, int channel) {
    vec2 pixel_size = 1.0 / texture_size;
    float sum = 0.0;

    // Center
    sum -= texture(tex, uv)[channel] * 1.0;

    // Adjacent
    sum += texture(tex, uv + vec2(1,0)*pixel_size)[channel] * 0.2;
    sum += texture(tex, uv + vec2(-1,0)*pixel_size)[channel] * 0.2;
    sum += texture(tex, uv + vec2(0,1)*pixel_size)[channel] * 0.2;
    sum += texture(tex, uv + vec2(0,-1)*pixel_size)[channel] * 0.2;

    // Diagonal
    sum += texture(tex, uv + vec2(1,1)*pixel_size)[channel] * 0.05;
    sum += texture(tex, uv + vec2(-1,-1)*pixel_size)[channel] * 0.05;
    sum += texture(tex, uv + vec2(1,-1)*pixel_size)[channel] * 0.05;
    sum += texture(tex, uv + vec2(-1,1)*pixel_size)[channel] * 0.05;

    return sum;
}

void fragment() {
    vec2 uv = UV;
    vec4 prev = texture(prev_texture, uv);
    float A = prev.r;
    float B = prev.g;

    // Calculate laplacians
    float lap_A = laplacian(prev_texture, uv, 0);
    float lap_B = laplacian(prev_texture, uv, 1);

    // Reaction calculations
    float reaction = A * B * B;

    // Update values
    A += (diffusion_a * lap_A - reaction + feed * (1.0 - A)) * dt;
    B += (diffusion_b * lap_B + reaction - (kill + feed) * B) * dt;

    // Clamp values
    A = clamp(A, 0.0, 1.0);
    B = clamp(B, 0.0, 1.0);

    ALBEDO = vec3(A, B, 0.0);
	//texture(simulation_texture, UV).rg = vec2(A, B);
}