shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 base_color : source_color = vec4(0.0, 0.5, 1.0, 1.0);
uniform vec4 wave_color : source_color = vec4(0.5, 1.0, 1.0, 1.0);
uniform float time_speed = 1.0;
uniform float wave_frequency = 0.5;
uniform float wave_amplitude = 2.0;

varying float height_factor;

void vertex() {
	// Lines remain static in geometry
	// Height factor calculated here for passing to fragment if needed,
	// but mostly we want the 'traveling pulse' effect in fragment.
	
	vec3 instance_pos = MODEL_MATRIX[3].xyz;
	
	// Pass world position x/z to fragment for pattern generation
	height_factor = instance_pos.x * 0.5 + instance_pos.z * 0.5; 
}

void fragment() {
	// Create a moving wave of light/color
	// 'height_factor' acts as a spatial offset
	
	float wave_phase = height_factor * wave_frequency + TIME * time_speed;
	float wave = sin(wave_phase);
	
	// Sharpen the wave for a "pulse" or laser scan effect
	// Map -1..1 to 0..1
	float brightness = smoothstep(0.4, 0.6, wave * 0.5 + 0.5);
	
	// Mix colors
	vec3 col = mix(base_color.rgb, wave_color.rgb, brightness);
	
	ALBEDO = col;
	
	// Optional: Make dark parts transparent or dimmer?
	// EMISSION for glowing lines
	EMISSION = col * (brightness * wave_amplitude); // Use amplitude for brightness intensity
	ALPHA = base_color.a + brightness * (wave_color.a - base_color.a);
}
