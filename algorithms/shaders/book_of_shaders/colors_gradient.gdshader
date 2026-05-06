shader_type spatial;
render_mode unshaded;

// Book of Shaders Ch.6: Linear gradient with adjustable hue rotation
// Demonstrates how color changes across UV space

uniform float hue_offset : hint_range(0.0, 1.0) = 0.0;
uniform float saturation : hint_range(0.0, 1.0) = 0.8;
uniform float brightness : hint_range(0.0, 1.0) = 0.9;
uniform float angle : hint_range(0.0, 6.28318) = 0.0;

vec3 hsb2rgb(vec3 c) {
	vec3 rgb = clamp(abs(mod(c.x * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
	rgb = rgb * rgb * (3.0 - 2.0 * rgb); // cubic smoothing
	return c.z * mix(vec3(1.0), rgb, c.y);
}

void fragment() {
	vec2 uv = UV;

	// Rotate gradient direction
	float cs = cos(angle);
	float sn = sin(angle);
	float t = (uv.x - 0.5) * cs + (uv.y - 0.5) * sn + 0.5;
	t = clamp(t, 0.0, 1.0);

	// Map t to hue with offset
	float hue = fract(t + hue_offset);

	ALBEDO = hsb2rgb(vec3(hue, saturation, brightness));
}
