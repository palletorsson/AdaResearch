shader_type spatial;
// Painted timber: the kit's wood texture under two kinds of coat, mixed in linear light.
// A cover coat (emulsion) lays colour over what is there by its share `cover_a`, so a first thin coat
// still shows the grain; a glaze (stain) filters everything beneath it, multiplying, so cyan over
// yellow is green. Shown = (wood * (1 - cover_a) + cover * cover_a) * glaze.
uniform sampler2D wood : source_color, filter_linear_mipmap_anisotropic;
uniform vec4 wood_tint : source_color = vec4(0.949, 0.898, 0.808, 1.0);
uniform vec3 cover : source_color = vec3(1.0);
uniform float cover_a : hint_range(0.0, 1.0) = 0.0;
uniform vec3 glaze : source_color = vec3(1.0);
uniform float wet : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec3 w = texture(wood, UV).rgb * wood_tint.rgb;
	ALBEDO = (w * (1.0 - cover_a) + cover * cover_a) * glaze;
	// bare timber .67; dry paint a little smoother; wet paint glossy until it dries
	ROUGHNESS = mix(mix(0.67, 0.5, cover_a), 0.18, wet);
	SPECULAR = mix(0.5, 0.65, wet);
}
