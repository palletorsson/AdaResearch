shader_type spatial;

uniform vec3 body_colour : source_color;
uniform vec3 band_colour : source_color;
uniform float bands : hint_range(1.0, 16.0) = 6.0;
uniform float softness : hint_range(0.01, 0.5) = 0.1;
uniform float drift : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float wave = 0.5 + 0.5 * sin((UV.y * bands + TIME * drift) * TAU);
	float band = smoothstep(0.5 - softness, 0.5 + softness, wave);
	ALBEDO = mix(band_colour, body_colour, band);
}
