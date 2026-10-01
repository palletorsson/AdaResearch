shader_type spatial;

uniform vec3 body_colour : source_color;
uniform vec3 band_colour : source_color;

void fragment() {
	float band = step(0.5, UV.y);
	ALBEDO = mix(band_colour, body_colour, band);
}
