shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

// Simple uniforms for educational use
uniform vec4 fill_color : source_color = vec4(0.2, 0.3, 0.8, 0.7);        // Inside face color
uniform vec4 wireframe_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);   // Edge color (cyan)
uniform float wireframe_width : hint_range(0.0, 10.0) = 3.0;               // Edge thickness
uniform float wireframe_brightness : hint_range(0.0, 5.0) = 2.0;           // Edge glow

// Barycentric coordinates for edge detection
varying vec3 barycentric;

// Simple vertex shader
void vertex() {
	// Set barycentric coordinates based on vertex ID
	barycentric = vec3(0.0);
	if (VERTEX_ID % 3 == 0) barycentric.x = 1.0;
	else if (VERTEX_ID % 3 == 1) barycentric.y = 1.0;
	else barycentric.z = 1.0;
}

// Simple fragment shader
void fragment() {
	// Calculate distance to edges using barycentric coordinates
	vec3 d = fwidth(barycentric);
	vec3 edge_distance = barycentric / d;
	
	// Find closest edge
	float closest_edge = min(min(edge_distance.x, edge_distance.y), edge_distance.z);
	
	// Create wireframe effect
	float wireframe_factor = 1.0 - smoothstep(0.0, wireframe_width, closest_edge);
	
	// Mix fill and wireframe colors
	ALBEDO = mix(fill_color.rgb, wireframe_color.rgb, wireframe_factor);
	ALPHA = mix(fill_color.a, wireframe_color.a, wireframe_factor);
	
	// Add emission for glowing edges
	EMISSION = wireframe_color.rgb * wireframe_factor * wireframe_brightness;
} 