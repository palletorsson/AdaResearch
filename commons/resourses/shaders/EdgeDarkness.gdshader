shader_type spatial;
render_mode cull_disabled;

uniform vec4 modelColor : source_color;
uniform vec4 wireframeColor : source_color;

uniform float width : hint_range(0.0, 15.0) = 1.0;
uniform float modelOpacity : hint_range(0.0, 1.0) = 1.0;

uniform bool filtered = false;

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
	vec3 dBaryCoordX = dFdx(baryCoord);
	vec3 dBaryCoordY = dFdy(baryCoord);
	vec3 dBaryCoord = sqrt(dBaryCoordX * dBaryCoordX + dBaryCoordY * dBaryCoordY);

	vec3 remap = smoothstep(
		vec3(0.0),
		dBaryCoord * width,
		baryCoord
	);

	remap = filtered ? remap : step(0.5, remap);

	float closestEdge = min(min(remap.x, remap.y), remap.z);

	// Use FRONT_FACING to apply different effects for front and back faces if needed
	vec3 color = mix(wireframeColor.xyz, modelColor.xyz, closestEdge);

	ALBEDO = color;
	ALPHA = mix(1.0, modelOpacity, closestEdge);
}
