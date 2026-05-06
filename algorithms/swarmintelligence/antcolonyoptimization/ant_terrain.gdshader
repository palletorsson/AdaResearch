shader_type spatial;

uniform sampler2D pheromone_texture;
uniform float valley_depth = 0.5;
uniform float mountain_height = 5.0; // From previous logic
uniform vec3 ground_color = vec3(0.5, 0.4, 0.2);
uniform float roughness = 0.9;

void vertex() {
	// Sample pheromone map
	vec4 pheromone = texture(pheromone_texture, UV);
	float intensity = max(pheromone.r, pheromone.b);
	
	// Displace DOWNWARDS
	VERTEX.y -= intensity * valley_depth;
}

void fragment() {
	vec4 pheromone = texture(pheromone_texture, UV);
	
	vec3 color = ground_color;
	
	// Add Food trail (Red)
	color = mix(color, vec3(1.0, 0.2, 0.2), pheromone.r);
	
	// Add Home trail (Blue)
	color = mix(color, vec3(0.2, 0.2, 1.0), pheromone.b);
	
	ALBEDO = color;
	ROUGHNESS = roughness;
	METALLIC = 0.1;
}
