// Tibetan tiger rug - carpet-knotters of Tibet. The pelt abstracted to
// symmetric stripe fields about a spine.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float g_scale : hint_range(0.3, 3.0) = 1.0;
uniform float g_weight : hint_range(0.4, 2.2) = 1.0;
uniform float g_wobble : hint_range(0.0, 2.5) = 1.0;
uniform vec3 g_tint : source_color = vec3(1.0, 1.0, 1.0);
float hash1(float p) { return fract(sin(p * 127.1) * 43758.5453); }

void fragment() {
	vec2 uv = UV;
	vec3 ochre = vec3(0.75, 0.48, 0.20);
	vec3 dark = vec3(0.14, 0.10, 0.06);
	vec3 rim = vec3(0.35, 0.23, 0.12);
	vec3 col = ochre;
	float ax = abs(uv.x - 0.5);
	float row = floor(uv.y * 11.0 * g_scale);
	float wav = sin(ax * 18.0 + hash1(row) * 6.28) * 0.02 * g_wobble;
	float band = fract(uv.y * 11.0 * g_scale + wav);
	float len = 0.28 * g_weight + hash1(row + 40.0) * 0.17;
	if (band > 0.30 && band < 0.62 && ax < len) {
		float taper = smoothstep(len, len - 0.10, ax);
		if (taper > 0.4) col = dark;
	}
	if (ax < 0.012) col = dark;
	if (uv.x < 0.04 || uv.x > 0.96 || uv.y < 0.05 || uv.y > 0.95) col = rim;
	ALBEDO = col * g_tint;
}
