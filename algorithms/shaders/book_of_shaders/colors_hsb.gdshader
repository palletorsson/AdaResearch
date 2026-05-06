shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.6: HSB color wheel / spectrum
// Full HSB space visualization: x = hue, y = brightness, saturation uniform

uniform float saturation : hint_range(0.0, 1.0) = 1.0;
uniform float mode : hint_range(0.0, 1.0) = 0.0; // 0 = spectrum, 1 = wheel

vec3 hsb2rgb(vec3 c) {
	vec3 rgb = clamp(abs(mod(c.x * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
	rgb = rgb * rgb * (3.0 - 2.0 * rgb);
	return c.z * mix(vec3(1.0), rgb, c.y);
}

void fragment() {
	vec2 uv = UV;

	// Spectrum mode: x = hue, y = value
	vec3 spectrum = hsb2rgb(vec3(uv.x, saturation, 1.0 - uv.y));

	// Wheel mode: angle = hue, radius = saturation
	vec2 center = uv * 2.0 - 1.0;
	float angle_val = atan(center.y, center.x) / 6.28318 + 0.5;
	float radius = length(center);
	vec3 wheel = hsb2rgb(vec3(angle_val, radius, 1.0));
	float mask = 1.0 - smoothstep(0.95, 1.0, radius);
	wheel *= mask;

	ALBEDO = mix(spectrum, wheel, mode);
}
