shader_type spatial;
render_mode cull_disabled;
uniform sampler2D state_texture : filter_nearest, repeat_enable;
uniform vec4 paper : source_color = vec4(0.88,0.85,0.76,1.0);
uniform vec4 ink : source_color = vec4(0.025,0.08,0.085,1.0);
void fragment() {
	vec3 bytes = floor(texture(state_texture, UV).rgb * 255.0 + 0.5);
	float b = (bytes.g * 16.0 + mod(bytes.b,16.0)) / 4095.0;
	// Display mapping only; never fed into the solver.
	vec3 colour = mix(paper.rgb, ink.rgb, smoothstep(0.05,0.30,b));
	ALBEDO = colour;
	ROUGHNESS = 0.55;
	EMISSION = colour * 0.14;
}
