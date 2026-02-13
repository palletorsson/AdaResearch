shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.13: FBM domain warping
// FBM feeding into itself — creates stunning organic patterns

uniform float scale : hint_range(1.0, 8.0) = 3.0;
uniform float warp_amount : hint_range(0.0, 4.0) = 2.0;
uniform float warp_layers : hint_range(1.0, 3.0) = 2.0;
uniform float speed : hint_range(0.0, 0.5) = 0.1;

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
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p *= 2.0;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV * scale;
	float t = TIME * speed;

	// Layer 1: base warp
	vec2 q = vec2(
		fbm(uv + vec2(0.0, 0.0) + t),
		fbm(uv + vec2(5.2, 1.3) + t)
	);

	vec2 r = q;

	// Layer 2: warp the warp
	if (warp_layers > 1.5) {
		r = vec2(
			fbm(uv + warp_amount * q + vec2(1.7, 9.2) + 0.15 * t),
			fbm(uv + warp_amount * q + vec2(8.3, 2.8) + 0.126 * t)
		);
	}

	// Layer 3: triple warp
	vec2 s = r;
	if (warp_layers > 2.5) {
		s = vec2(
			fbm(uv + warp_amount * r + vec2(3.1, 7.4) + 0.21 * t),
			fbm(uv + warp_amount * r + vec2(6.8, 1.2) + 0.18 * t)
		);
	}

	float f = fbm(uv + warp_amount * s);

	// Iq-style coloring: beautiful organic palette
	vec3 color = mix(vec3(0.101961, 0.619608, 0.666667), vec3(0.666667, 0.666667, 0.498039), clamp(f * f * 4.0, 0.0, 1.0));
	color = mix(color, vec3(0.0, 0.0, 0.164706), clamp(length(q), 0.0, 1.0));
	color = mix(color, vec3(0.666667, 1.0, 1.0), clamp(length(r.x), 0.0, 1.0));

	ALBEDO = color;
}
