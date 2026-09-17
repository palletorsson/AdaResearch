// vitrine_floor.gdshader — the cage's ground: the ring's earth colour, and the presence
// grid (R tree, G creature, B flower, A fungus) as the glow the floor keeps.
// hint_default_black: an unbound sampler is black, never white — a StandardMaterial3D's
// emission_texture photographed the whole floor flat white before its first bind.
shader_type spatial;
render_mode cull_back;

uniform vec4 earth : source_color = vec4(0.27, 0.27, 0.27, 1.0);
uniform sampler2D presence : hint_default_black, filter_linear;
uniform float glow = 0.9;
// 1.0 before the colour sequence: the floor remembers in grey
uniform float mono = 0.0;

void fragment() {
	vec4 p = texture(presence, UV);
	ALBEDO = earth.rgb;
	ROUGHNESS = 0.85;
	// tree green, creature amber, flower blue, fungus (the alpha channel) violet
	vec3 e = vec3(0.25, 0.85, 0.30) * p.r + vec3(0.95, 0.70, 0.20) * p.g
		+ vec3(0.35, 0.55, 1.00) * p.b + vec3(0.70, 0.35, 0.95) * p.a;
	float lum = (p.r + p.g + p.b + p.a) * 0.6;
	EMISSION = mix(e, vec3(0.85) * lum, mono) * glow;
}
