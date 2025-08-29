shader_type spatial;

// VR-optimized Grid shader - forces complete opacity
render_mode unshaded, cull_disabled, depth_draw_always ;

// Uniforms
uniform vec4 modelColor : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 wireframeColor : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 emissionColor : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float width : hint_range(0.0, 15.0) = 2.0;
uniform float blur : hint_range(0.0, 5.0) = 0.5;
uniform float emission_strength : hint_range(0.0, 10.0) = 1.5;

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
		-blur,
		blur,
		edge_distance
	);

	// Find the closest edge
	float closestEdge = min(min(remap.x, remap.y), remap.z);

	// Mix colors - NO ALPHA BLENDING, always opaque
	ALBEDO = mix(wireframeColor.rgb, modelColor.rgb, closestEdge);
	ALPHA = 1.0;  // Force complete opacity for VR

	// Add emission to the wireframe edges
	EMISSION = emissionColor.rgb * (1.0 - closestEdge) * emission_strength;
}