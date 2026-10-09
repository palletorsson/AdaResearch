shader_type spatial;
render_mode unshaded, depth_draw_always, cull_disabled;

uniform float time_offset = 0.0;
uniform float flow_speed = 0.0;  // Static by default
uniform vec4 color_start : source_color = vec4(1.0, 0.0, 0.5, 1.0);
uniform vec4 color_end : source_color = vec4(0.0, 0.5, 1.0, 1.0);
uniform float glow_intensity = 1.5;
uniform float thickness_variation = 0.0;  // No thickness animation by default
uniform float pulse_frequency = 0.0;  // No pulse by default

varying float line_progress;

void vertex() {
	line_progress = UV.x;
	// Static thickness - no animation when pulse_frequency is 0
	float thickness = 1.0;
	if (pulse_frequency > 0.0) {
		thickness += sin(line_progress * 10.0 + TIME * pulse_frequency) * thickness_variation;
	}
	VERTEX.xyz *= thickness;
}

void fragment() {
	// Static gradient based on position along line
	float color_wave = line_progress;  // Simple gradient, no time-based animation
	vec3 flowing_color = mix(color_start.rgb, color_end.rgb, color_wave);

	// Optional rainbow effect, but static
	float hue_shift = line_progress;  // No time component for static look
	vec3 rainbow = vec3(
		sin(hue_shift * 6.2831) * 0.5 + 0.5,
		sin(hue_shift * 6.2831 + 2.094) * 0.5 + 0.5,
		sin(hue_shift * 6.2831 + 4.188) * 0.5 + 0.5
	);
	vec3 final_color = mix(flowing_color, rainbow, 0.3);

	// Static intensity - no pulse
	float pulse = 1.0;

	// Center glow effect
	float center_distance = abs(UV.y - 0.5) * 2.0;
	float glow = 1.0 - pow(center_distance, 0.5);

	ALBEDO = final_color;
	EMISSION = final_color * glow_intensity * glow;
	ALPHA = color_start.a;
}