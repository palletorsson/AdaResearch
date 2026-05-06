shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.11: Domain warping
// Feed noise into itself to create organic distortion

uniform float scale : hint_range(1.0, 10.0) = 4.0;
uniform float warp_strength : hint_range(0.0, 3.0) = 1.5;
uniform float speed : hint_range(0.0, 1.0) = 0.2;
uniform float color_shift : hint_range(0.0, 1.0) = 0.5;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			   mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 5; i++) {
		value += amplitude * noise(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec2 uv = UV * scale;
	float t = TIME * speed;

	// First warp layer
	vec2 q = vec2(fbm(uv + t), fbm(uv + vec2(5.2, 1.3) + t));

	// Second warp layer
	vec2 r = vec2(
		fbm(uv + warp_strength * q + vec2(1.7, 9.2) + 0.15 * t),
		fbm(uv + warp_strength * q + vec2(8.3, 2.8) + 0.126 * t)
	);

	float f = fbm(uv + warp_strength * r);

	// Color mapping
	vec3 color = mix(vec3(0.1, 0.2, 0.3), vec3(0.0, 0.78, 0.85), clamp(f * f * 2.0, 0.0, 1.0));
	color = mix(color, vec3(0.95, 0.45, 0.15), clamp(length(q) * color_shift, 0.0, 1.0));
	color = mix(color, vec3(0.9, 0.9, 0.95), clamp(length(r.x) * color_shift * 0.5, 0.0, 1.0));

	ALBEDO = color;
}
