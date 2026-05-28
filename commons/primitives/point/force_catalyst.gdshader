// Force-catalyst morph shader.
//
// At morph_t = 0 the geometry stays flush against its base sphere
// (the original interactive point). As morph_t climbs to 1 a low-
// frequency sine wave displaces the vertices along their normals,
// pulsing the surface outward into a "force field" shell. The
// fragment colour blends from the neutral base white to a warm
// force-orange, with emission tracking morph_t so the shape glows
// brighter as it engages.
shader_type spatial;
render_mode unshaded, depth_draw_opaque, cull_back;

uniform float morph_t : hint_range(0.0, 1.0) = 0.0;
uniform float pulse_amp = 0.06;            // max displacement at morph_t=1
uniform float pulse_freq = 6.0;            // spatial wave frequency
uniform float pulse_speed = 2.5;           // temporal wave speed
uniform vec4 base_color : source_color = vec4(0.95, 0.95, 0.92, 1.0);
uniform vec4 force_color : source_color = vec4(1.0, 0.55, 0.10, 1.0);
uniform float emission_base = 0.4;
uniform float emission_force = 2.5;

void vertex() {
	// Pulse along the local normal. Use VERTEX.xyz to vary the wave
	// across the mesh so the displacement reads as a rippling shell,
	// not a uniform inflate.
	float w = sin(TIME * pulse_speed
		+ VERTEX.x * pulse_freq
		+ VERTEX.y * pulse_freq * 0.8
		+ VERTEX.z * pulse_freq * 1.2);
	w = w * 0.5 + 0.5;                  // [0, 1]
	float disp = morph_t * pulse_amp * (0.4 + 0.6 * w);
	VERTEX += NORMAL * disp;
}

void fragment() {
	vec3 col = mix(base_color.rgb, force_color.rgb, morph_t);
	ALBEDO = col;
	EMISSION = col * mix(emission_base, emission_force, morph_t);
}
