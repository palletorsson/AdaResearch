shader_type spatial;


// Uniforms
uniform vec4 modelColor : source_color = vec4(0.5, 0.5, 0.5, 1.0);       // Main cube color
uniform vec4 wireframeColor : source_color = vec4(1.0, 0.0, 0.0, 1.0);   // Wireframe color
uniform vec4 emissionColor : source_color = vec4(1.0, 0.0, 0.0, 1.0);    // Emission color (matches wireframe by default)
uniform float width : hint_range(0.0, 15.0) = 1.0;                       // Edge thickness
uniform float blur : hint_range(0.0, 5.0) = 1.0;                         // Blur amount
uniform float emission_strength : hint_range(0.0, 10.0) = 2.0;           // Emission intensity
uniform float modelOpacity : hint_range(0.0, 1.0) = 1.0;                 // Opacity of the cube

// Barycentric coordinate vectors for triangle edges
const vec3 vectors[3] = {
	vec3(1.0, 0.0, 0.0),
	vec3(0.0, 1.0, 0.0),
	vec3(0.0, 0.0, 1.0)
};

varying vec3 baryCoord;

void vertex() {
	baryCoord = vectors[VERTEX_ID % 3];
}

void fragment() {
	// Calculate barycentric coordinate derivatives for edge detection
	vec3 dBaryCoordX = dFdx(baryCoord);
	vec3 dBaryCoordY = dFdy(baryCoord);
	vec3 dBaryCoord = sqrt(dBaryCoordX * dBaryCoordX + dBaryCoordY * dBaryCoordY);

	// Smoothstep with blur control
	vec3 edge_distance = baryCoord / (dBaryCoord * width);
	vec3 remap = smoothstep(
		-blur,           // Start of the fade (negative for blur beyond edge)
		blur,            // End of the fade (positive for blur inward)
		edge_distance    // Distance from edge
	);

	// Find the closest edge
	float closestEdge = min(min(remap.x, remap.y), remap.z);

	// Mix colors and opacity
	ALBEDO = mix(wireframeColor, modelColor, closestEdge).xyz;
	ALPHA = mix(1.0, modelOpacity, closestEdge);

	// Add emission to the wireframe edges
	// 1.0 - closestEdge makes emission strongest at the edges (where closestEdge is 0)
	EMISSION = emissionColor.rgb * (1.0 - closestEdge) * emission_strength;
}