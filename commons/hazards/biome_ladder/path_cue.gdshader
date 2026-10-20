shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
// A bright core and dark silhouette remain distinct over the pale floor and grey sky.
uniform vec4 cue_colour : source_color = vec4(1.0);
void fragment() {
	// The announced target can be the eye itself. Never fill the visitor's near view.
	if (length(VERTEX) < 0.7) { discard; }
	float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
	ALBEDO = mix(vec3(0.025), cue_colour.rgb, smoothstep(0.25, 0.70, facing));
	ALPHA = smoothstep(0.7, 1.5, length(VERTEX));
}
