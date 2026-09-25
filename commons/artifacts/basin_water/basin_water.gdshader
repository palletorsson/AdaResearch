shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, specular_schlick_ggx;

// A lid of water over a museum basin. Three directional sines (the wave
// functions of sequence nine), one value noise (sequence eleven), and a
// colour that depends on the angle the surface is seen from. Everything here
// is computed for every vertex and every pixel on every frame; nothing is
// stored between frames. That is the point the hall makes.
//
// THE CLOCK WRAPS. project.godot sets rendering/limits/time/time_rollover_secs
// to 30, so TIME runs 0..30 and drops back to 0. A phase written as TIME * w
// leaps at the wrap unless w * 30 is a whole number of cycles — the sine panel
// in the sequence's first hall leaps for exactly that reason, twice a minute.
// Here every wave's rate is rounded to whole cycles per rollover and the noise
// drifts round a circle once per rollover, so the wrap is invisible on the
// water. The rollover is handed in by basin_water.gd from the project setting.

uniform vec4 deep_color : source_color = vec4(0.06, 0.20, 0.30, 0.86);
uniform vec4 shallow_color : source_color = vec4(0.38, 0.64, 0.72, 0.55);
uniform float amplitude = 0.05;        // metres the surface may rise and fall
uniform float wavelength = 1.6;        // metres, of the longest sine
uniform float speed = 0.8;             // metres per second along the longest sine, before rounding
uniform float noise_amount = 0.35;     // share of the amplitude given to the noise term
uniform float rollover = 30.0;         // seconds; TIME wraps here
uniform float roughness_value = 0.08;

// TAU is a built-in constant of Godot's shader language; redefining it is a compile error.

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

// An angular rate rounded to whole cycles per rollover: continuous across the wrap.
float wrap_rate(float w) {
	float per = max(rollover, 1.0);
	return floor(w * per / TAU + 0.5) * TAU / per;
}

float height_at(vec2 p, float t) {
	float k = TAU / max(wavelength, 0.05);
	float w = speed * k;
	float w1 = wrap_rate(w * 0.9);
	float w2 = wrap_rate(w * 1.4);
	float w3 = wrap_rate(w * 2.1);
	float h = sin(k * dot(p, vec2(0.90, 0.44)) - t * w1)
	        + 0.55 * sin(k * 1.7 * dot(p, vec2(-0.30, 0.95)) - t * w2)
	        + 0.30 * sin(k * 2.9 * dot(p, vec2(0.62, -0.78)) + t * w3);
	float a = TAU * t / max(rollover, 1.0);
	h += (vnoise(p * 2.3 + 0.9 * vec2(cos(a), sin(a))) - 0.5) * 2.0 * noise_amount;
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
