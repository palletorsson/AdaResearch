shader_type spatial;

uniform sampler2D slime_texture;
uniform float vein_height : hint_range(0.0, 5.0) = 1.0;
uniform vec3 ground_color : source_color = vec3(0.1, 0.1, 0.1); # Dark soil
uniform vec3 vein_color : source_color = vec3(0.8, 1.0, 0.1); # Yellow-Green slime

void vertex() {
	// Sample slime intensity
	float slime = texture(slime_texture, UV).g; // Green channel holds main data
	
	// Raise vertices (Growing veins)
	VERTEX.y += slime * vein_height;
}

void fragment() {
	float slime = texture(slime_texture, UV).g;
	
	// Mix ground with vein color
	vec3 final_color = mix(ground_color, vein_color, slime);
	
	ALBEDO = final_color;
	
	// Add glow (bioluminescence)
	if (slime > 0.1) {
		EMISSION = vein_color * slime * 2.0;
	}
	
	// PBR
	ROUGHNESS = 0.8 - (slime * 0.6); // Slime is wet/shiny
	SPECULAR = 0.5;
}
