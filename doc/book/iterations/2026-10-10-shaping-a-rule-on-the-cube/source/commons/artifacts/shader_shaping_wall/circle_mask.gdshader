shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float radius : hint_range(0.08, 0.46) = 0.30;
uniform float softness : hint_range(0.0, 0.08) = 0.0;
uniform vec4 ground : source_color = vec4(0.032, 0.039, 0.046, 1.0);
uniform vec4 ink : source_color = vec4(0.93, 0.89, 0.82, 1.0);

void fragment() {
	float d = distance(UV, vec2(0.5));
	float mask = 1.0 - step(radius, d);
	if (softness > 0.0) {
		mask = 1.0 - smoothstep(radius - softness, radius + softness, d);
	}
	ALBEDO = mix(ground.rgb, ink.rgb, mask);
}
