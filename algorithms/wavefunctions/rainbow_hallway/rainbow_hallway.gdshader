// Rainbow Hallway Shader
// Creates a gradient based on Z position with optional animation

shader_type spatial;

// Gradient texture for the rainbow effect
uniform sampler2D rainbow_gradient : source_color;

// Animation parameters
uniform float animation_speed : hint_range(0.0, 2.0) = 1.0;
uniform float gradient_offset : hint_range(0.0, 1.0) = 0.5;

// Glow parameters
uniform float glow_intensity : hint_range(0.0, 2.0) = 0.5;
uniform float emission_strength : hint_range(0.0, 1.0) = 0.3;

// World-space mapping parameters (meters)
uniform float gradient_start_z = 0.0;     // world Z where gradient begins
uniform float gradient_length_m = 10.0;   // length in meters over which the gradient covers 0..1

// Varying variable to pass Z position from vertex to fragment shader
varying float z_position_normalized;

void vertex() {
	// Calculate the vertex's world position
	vec4 world_pos = MODEL_MATRIX * vec4(VERTEX, 1.0);
	
    // Normalize Z over configured range [gradient_start_z, gradient_start_z + gradient_length_m]
    z_position_normalized = (world_pos.z - gradient_start_z) / max(gradient_length_m, 0.0001);
}

void fragment() {
	// Clamp the value to ensure it's always between 0 and 1
	float coord = clamp(z_position_normalized, 0.0, 1.0);
	
	// Add animation offset
	coord = fract(coord + gradient_offset + TIME * animation_speed * 0.1);
	
	// Sample the color from the gradient texture using the normalized Z position
	vec3 color = texture(rainbow_gradient, vec2(coord, 0.0)).rgb;
	
	// Set the base color
	ALBEDO = color;
	
	// Add emission for glow effect
	EMISSION = color * emission_strength;
	
	// Set metallic and roughness for a smooth surface
	METALLIC = 0.1;
	ROUGHNESS = 0.2;
}
