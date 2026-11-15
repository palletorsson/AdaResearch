shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;   // the tower's haze would tint a print
// Drawn like a print: no light, a tone for each way a face looks, and engraved lines across it.
// The tones and lines are the same after a half turn about the tower's axis and after any drop of 0.6 m, so that
// the place a climber is set down in looks exactly like the one it left.
uniform vec3 origin = vec3(0.0);
uniform vec3 paper : source_color = vec3(0.93, 0.9, 0.84);
uniform vec3 ink : source_color = vec3(0.1, 0.11, 0.15);
uniform float depth = 1.0;          // how dark this thing is drawn: 1 stone, 2 a robe
uniform bool tower = false;         // courses and arched windows
varying vec3 at;
varying vec3 facing;

void vertex() {
	at = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz - origin;
	facing = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(facing);
	if (!FRONT_FACING) n = -n;
	float tone;
	float lines;
	if (abs(n.y) > 0.6) {
		tone = n.y > 0.0 ? 0.04 : 0.72;
		lines = fract((at.x + at.z) / 0.3);
	} else {
		vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), n));
		float u = dot(at, right);
		bool broad = abs(n.z) >= abs(n.x);
		tone = broad ? 0.26 : 0.52;
		lines = fract((u + at.y * (broad ? 1.0 : -1.0)) / (broad ? 0.1 : 0.06));
		if (tower) {
			float course = fract(at.y / 0.3);
			if (course < 0.06) tone = 0.8;
			float v = fract(at.y / 1.2) * 1.2;
			float w = abs(fract(u / 1.6 + 0.5) * 1.6 - 0.8);
			float arch = 0.72 - (w * w) * 2.2;
			if (w < 0.26 && v > 0.22 && v < arch) tone = 0.9;
		}
	}
	float cut = smoothstep(0.0, 0.12, lines) * (1.0 - smoothstep(0.42, 0.55, lines));
	tone = clamp(tone * depth + cut * 0.16 * (0.4 + tone), 0.0, 0.95);
	ALBEDO = mix(paper, ink, tone);
}
