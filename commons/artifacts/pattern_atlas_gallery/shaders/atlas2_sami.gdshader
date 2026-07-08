// SAMI BAND WEAVING (duodji) — the band weavers of Sapmi. Pick-up weave on
// narrow warps: diamond chains and zigzags between bordered stripes. The
// atlas's northern homecoming — the craft lineage nearest Vamlingbo's looms.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float g_scale : hint_range(0.3, 3.0) = 1.0;
uniform float g_weight : hint_range(0.4, 2.2) = 1.0;
uniform float g_wobble : hint_range(0.0, 2.5) = 1.0;
uniform vec3 g_tint : source_color = vec3(1.0, 1.0, 1.0);

float hash2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash2(i), b = hash2(i + vec2(1, 0)), c = hash2(i + vec2(0, 1)), d = hash2(i + vec2(1, 1));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 uv = UV;
	vec3 wool = vec3(0.92, 0.89, 0.80);
	vec3 red = vec3(0.72, 0.16, 0.15);
	vec3 blue = vec3(0.15, 0.24, 0.46);
	vec3 yellow = vec3(0.90, 0.72, 0.16);
	vec3 green = vec3(0.20, 0.42, 0.24);
	// the band runs horizontally; y is the band cross-section, repeated
	float band = fract(uv.y * 2.0 * g_scale);
	vec3 col = wool;
	// border stripes
	if (band < 0.06 || band > 0.94) col = red;
	else if (band < 0.12 || band > 0.88) col = blue;
	else if (band < 0.16 || band > 0.84) col = yellow;
	else {
		// central pick-up field: diamond chain
		float cx = uv.x * 10.0 * g_scale;
		vec2 c = vec2(fract(cx) - 0.5, (band - 0.5) / 0.34);
		float d = abs(c.x) * 1.6 + abs(c.y);
		if (abs(d - 0.62) < 0.14 * g_weight) col = red;
		if (abs(d - 0.62) < 0.05 * g_weight) col = blue;
		if (d < 0.22) col = mod(floor(cx), 2.0) < 1.0 ? green : yellow;
		// warp texture
		col *= 0.95 + 0.05 * step(0.5, fract(cx * 8.0));
	}
	ALBEDO = col * g_tint;
}
