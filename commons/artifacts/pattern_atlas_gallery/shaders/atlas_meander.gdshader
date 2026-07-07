// Greek key meander - Roman mosaic workshops, Pompeii. Field, straight,
// corner: three tiles and one turning rule, run in stone for millennia.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float g_scale : hint_range(0.3, 3.0) = 1.0;
uniform float g_weight : hint_range(0.4, 2.2) = 1.0;
uniform float g_wobble : hint_range(0.0, 2.5) = 1.0;
uniform vec3 g_tint : source_color = vec3(1.0, 1.0, 1.0);

void fragment() {
	vec2 uv = UV;
	vec3 pale = vec3(0.91, 0.88, 0.79);
	vec3 blue = vec3(0.13, 0.21, 0.36);
	vec3 col = pale;
	float band = -1.0;
	if (uv.y > 0.72) band = (uv.y - 0.72) / 0.28;
	else if (uv.y < 0.28) band = uv.y / 0.28;
	if (band >= 0.0) {
		vec2 k = vec2(fract(uv.x * 6.0 * g_scale), band);
		float t = 0.14 * g_weight;
		bool on = false;
		if (k.y < t || k.y > 1.0 - t) on = true;
		if (k.x < t && k.y < 0.75) on = true;
		if (k.y > 0.60 - t && k.y < 0.60 + t && k.x < 0.66) on = true;
		if (k.x > 0.66 - t && k.x < 0.66 + t && k.y > 0.28 && k.y < 0.62) on = true;
		if (k.y > 0.28 - t && k.y < 0.28 + t && k.x > 0.30 && k.x < 0.68) on = true;
		col = on ? blue : pale;
	} else {
		vec2 tes = fract(uv * 26.0) - 0.5;
		col = pale * (0.96 + 0.04 * step(0.42, max(abs(tes.x), abs(tes.y))));
	}
	ALBEDO = col * g_tint;
}
