// TerrainVisual.gdshader — the marching-cave terrain look, with the distance fade
// made a UNIFORM instead of a literal.
//
// TRANSCRIBED, NOT REWRITTEN. Every line below is the code the VisualShader
// (TerrainVisual.tres) already generated, in the same order, with the same
// constants. Two literals became uniforms and nothing else changed, so at the
// default values this file and the graph produce identical pixels.
//
// WHY IT HAD TO CHANGE. The fade is:
//
//     ALBEDO = (1.0 - clamp(distance(camera, vertex) / 500.0 * 1.2, 0, 1)) * ramp
//
// which reaches pure black at ~417 units. That is a fine look for a player
// standing ON a 300-unit terrain, and it is fatal to a capture bench, which has
// to stand far enough back to frame the whole thing: at chunk_scale 300 the rig
// sits about 1600 units out, four times past the black point. Measured, the six
// terrain artifacts rendered at a subject mean luminance of 0.0-0.1 out of 255
// against 59 and 168 for the two wave-1 artifacts that do not use this material.
// Ten declared axes were scored WEAK or INERT on frames where the axis is
// plainly visible - the num_portals=16 tile shows sixteen countable rings and
// was filed INERT at 2.30%.
//
// The bench could not be the place to fix it: capture_config_sweep's staging is
// marked FROZEN, because tuning it re-bases every archived bite number in the
// project. So the knob belongs to the artifact, and dna.fixture opens it for the
// length of a sweep only.
//
// fade_distance defaults to 500.0 and fade_gain to 1.2, the two literals that
// were in the graph. Every shipped placement keeps the look it had.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, depth_test_default, cull_back, diffuse_lambert, specular_schlick_ggx;

// The ramp the VisualShader carried as its Texture2D node default.
uniform sampler2D terrain_ramp : source_color;
// WAS the literal 500.0. Raise it and the terrain stops fading to black.
uniform float fade_distance = 500.0;
// WAS the literal 1.2, the multiplier on the normalised distance.
uniform float fade_gain = 1.2;

varying vec3 var_PosTest;

void vertex() {
	// Local-space VERTEX, exactly as the graph had it. Note this is compared
	// against CAMERA_POSITION_WORLD below, which is a world-space value - a
	// mismatch that predates this file and is preserved deliberately, because
	// correcting it would change the shipped look rather than the measurability.
	var_PosTest = VERTEX;
}

void fragment() {
	float dist = distance(CAMERA_POSITION_WORLD, var_PosTest);
	float fade = 1.0 - min(max(dist / fade_distance * fade_gain, 0.0), 1.0);

	// Ramp lookup: a band index built from the surface normal's Y (so slope reads
	// as a colour change) plus height, wrapped with mod() into a repeating strip.
	float slope = fma(NORMAL.y, 0.5, 0.5);
	float height = var_PosTest.y / 100.0;
	float band = mod(fma(2.2, slope, height) / 5.0, 1.0);
	vec4 ramp = textureLod(terrain_ramp, vec2(band, 0.5), 0.0);

	ALBEDO = vec3(fade) * ramp.rgb;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
