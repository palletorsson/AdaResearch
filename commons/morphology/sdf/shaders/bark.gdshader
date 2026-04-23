// bark.gdshader
// For tree trunks, fungus stems — rough, crevice-darkened surface.
// The darkening concentrates where the surface curves inward (approximated
// via normal Y direction + noise) giving a bark-bark feel.

shader_type spatial;

uniform vec3 bark_color : source_color = vec3(0.35, 0.23, 0.15);
uniform vec3 crevice_color : source_color = vec3(0.12, 0.08, 0.05);
uniform float crack_scale : hint_range(0.5, 30.0) = 12.0;
uniform float crack_depth : hint_range(0.0, 1.0) = 0.65;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.92;

float bark_noise(vec3 p) {
	// Multi-octave value noise approximation — cheap, looks woody
	float n = sin(p.y * crack_scale) * 0.5 + 0.5;
	n += sin(p.y * crack_scale * 2.13 + p.x * crack_scale * 0.3) * 0.3;
	n += sin(p.y * crack_scale * 0.37 + p.z * crack_scale * 0.4) * 0.2;
	return clamp(n * 0.5 + 0.25, 0.0, 1.0);
}

void fragment() {
	float crack = bark_noise(VERTEX);
	// Darken where noise is low (ridges/crevices)
	float darkness = 1.0 - crack_depth * (1.0 - crack);
	ALBEDO = mix(crevice_color, bark_color, darkness);
	ROUGHNESS = roughness_val;
	METALLIC = 0.0;
}
