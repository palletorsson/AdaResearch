// Kanga - printers of the Swahili coast. Border (pindo) + central motif
// (mji) + a proverb (jina): text is part of the pattern.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float g_scale : hint_range(0.3, 3.0) = 1.0;
uniform float g_weight : hint_range(0.4, 2.2) = 1.0;
uniform float g_wobble : hint_range(0.0, 2.5) = 1.0;
uniform vec3 g_tint : source_color = vec3(1.0, 1.0, 1.0);

void fragment() {
	vec2 uv = UV;
	vec3 blk = vec3(0.10, 0.08, 0.07);
	vec3 red = vec3(0.75, 0.22, 0.17);
	vec3 crm = vec3(0.96, 0.92, 0.84);
	float b = 0.10;
	vec3 col = red;
	bool border = uv.x < b || uv.x > 1.0 - b || uv.y < b || uv.y > 1.0 - b;
	if (border) {
		col = blk;
		vec2 d = fract(uv * 22.0 * g_scale) - 0.5;
		if (length(d) < 0.18) col = crm;
	} else {
		vec2 c = uv - 0.5;
		float r = length(c);
		float th = atan(c.y, c.x);
		float pet = abs(sin(th * floor(6.0 * g_scale + 0.5))) * 0.06 * g_wobble + 0.16 * g_weight;
		if (r < pet && r > 0.10) col = crm;
		if (r < 0.10) col = blk;
		if (r < 0.055) col = crm;
	}
	ALBEDO = col * g_tint;
}
