shader_type spatial;

// Pulsing status light — LEDs and latch tabs breathe over time.

uniform vec4 led_color : source_color = vec4(0.30, 0.90, 0.40, 1.0);
uniform float pulse_speed : hint_range(0.0, 8.0) = 2.2;
uniform float base_glow : hint_range(0.0, 4.0) = 1.0;
uniform float pulse_amp : hint_range(0.0, 4.0) = 1.7;

void fragment() {
	float p = 0.5 + 0.5 * sin(TIME * pulse_speed);
	ALBEDO = led_color.rgb;
	METALLIC = 0.0;
	ROUGHNESS = 0.3;
	EMISSION = led_color.rgb * (base_glow + pulse_amp * p);
}
