shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

uniform sampler2D film : source_color, filter_linear;
uniform int treatment = 0;
uniform vec2 texel = vec2(0.00260417, 0.00347222);
uniform vec3 ink : source_color = vec3(0.65, 0.75, 0.93);

float light_at(vec2 uv) {
	return dot(texture(film, uv).rgb, vec3(0.2126, 0.7152, 0.0722));
}

void fragment() {
	float value = light_at(UV);
	vec3 paper = vec3(0.91, 0.89, 0.82);
	vec3 dark = vec3(0.012, 0.018, 0.025);
	vec3 image = mix(dark, vec3(0.94), clamp(value * 1.6, 0.0, 1.0));
	if (treatment == 1) {
		// A luminance threshold, not a depth map or a change to the rods.
		image = mix(paper, dark, smoothstep(0.14, 0.23, value));
	} else if (treatment == 2) {
		float dx = light_at(UV + vec2(texel.x, 0.0)) - light_at(UV - vec2(texel.x, 0.0));
		float dy = light_at(UV + vec2(0.0, texel.y)) - light_at(UV - vec2(0.0, texel.y));
		float edge = smoothstep(0.04, 0.3, length(vec2(dx, dy)));
		image = mix(dark, ink, edge);
	} else if (treatment == 3) {
		float scan = 0.78 + 0.22 * sin(UV.y / texel.y * 3.14159265);
		image = dark + ink * clamp(value * 2.0, 0.0, 1.0) * scan;
	}
	ALBEDO = image;
}
