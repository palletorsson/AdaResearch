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

// Varying variable to pass Z position from vertex to fragment shader
varying float z_position_normalized;

void vertex() {
	// Calculate the vertex's world position
	vec4 world_pos = MODEL_MATRIX * vec4(VERTEX, 1.0);
	
	// Normalize the Z position from -10 to 10 into a 0.0 to 1.0 range
	// Adjust these values to match your hallway length
	float start_z = -10.0;
	float length = 20.0;
	z_position_normalized = (world_pos.z - start_z) / length;
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
