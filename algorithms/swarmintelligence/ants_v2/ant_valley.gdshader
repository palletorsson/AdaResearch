shader_type spatial;

uniform sampler2D pheromone_texture : filter_linear;
uniform float valley_depth = 1.0;
uniform vec3 ground_color : source_color = vec3(0.8, 0.7, 0.5); // Sand color

void vertex() {
	// Sample texture for displacement
	// Use vertex UVs
	vec4 data = texture(pheromone_texture, UV);
	
	// Max intensity of either Home(Blue) or Food(Red)
	float intensity = max(data.r, data.b);
	
	// Displace DOWN (create valley)
	// Smoothstep for nicer falloff?
	VERTEX.y -= intensity * valley_depth;
}

void fragment() {
	vec4 data = texture(pheromone_texture, UV);
	
	vec3 color = ground_color;
	
	// Blend trails
	// Food Trail (Red Channel) -> Red Tint
	color = mix(color, vec3(1.0, 0.1, 0.1), data.r * 0.8);
	
	// Home Trail (Blue Channel) -> Blue Tint
	color = mix(color, vec3(0.1, 0.1, 1.0), data.b * 0.8);
	
	ALBEDO = color;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
