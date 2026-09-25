shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, specular_schlick_ggx;

// A lid of water over a museum basin. Three directional sines (the wave
// functions of sequence nine), one value noise (sequence eleven), and a
// colour that depends on the angle the surface is seen from. Everything here
// is computed for every vertex and every pixel on every frame; nothing is
// stored between frames. That is the point the hall makes.

uniform vec4 deep_color : source_color = vec4(0.06, 0.20, 0.30, 0.86);
uniform vec4 shallow_color : source_color = vec4(0.38, 0.64, 0.72, 0.55);
uniform float amplitude = 0.05;        // metres the surface may rise and fall
uniform float wavelength = 1.6;        // metres, of the longest sine
uniform float speed = 0.8;             // metres per second along the longest sine
uniform float noise_amount = 0.35;     // share of the amplitude given to the noise term
uniform float roughness_value = 0.08;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), u.x),
	           mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), u.x), u.y);
}

float height_at(vec2 p, float t) {
	float k = 6.2831853 / max(wavelength, 0.05);
	float w = speed * k;
	float h = sin(k * dot(p, vec2(0.90, 0.44)) - t * w * 0.9)
	        + 0.55 * sin(k * 1.7 * dot(p, vec2(-0.30, 0.95)) - t * w * 1.4)
	        + 0.30 * sin(k * 2.9 * dot(p, vec2(0.62, -0.78)) + t * w * 2.1);
	h += (vnoise(p * 2.3 + vec2(t * 0.15, -t * 0.11)) - 0.5) * 2.0 * noise_amount;
	return h * amplitude;
}

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = TIME;
	float e = 0.05;
	float h = height_at(world.xz, t);
	float hx = height_at(world.xz + vec2(e, 0.0), t);
	float hz = height_at(world.xz + vec2(0.0, e), t);
	VERTEX.y += h;
	// The plane is placed unrotated, so its model axes are the world's.
	NORMAL = normalize(vec3(h - hx, e, h - hz));
}

void fragment() {
	float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float fres = pow(1.0 - facing, 3.0);
	vec4 col = mix(deep_color, shallow_color, fres);
	ALBEDO = col.rgb;
	ALPHA = col.a;
	ROUGHNESS = roughness_value;
	METALLIC = 0.0;
	SPECULAR = 0.6;
}
