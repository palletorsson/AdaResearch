shader_type spatial;
render_mode cull_disabled;
uniform float opening : hint_range(0.0, 1.0) = 0.0;
uniform float pick_count = 1.0;
uniform bool folded = false;
void vertex() {
	if (!folded) {
		// Inspection narrows the yarns around their unchanged centre paths.
		VERTEX.xz -= UV2 * opening * 0.70;
		float sx = mix(1.0, 1.15, opening);
		float sy = mix(1.0, 4.0, opening);
		float shear = opening * 1.8 / max(pick_count - 1.0, 1.0) / 0.025;
		VERTEX = vec3(VERTEX.x * sx, 0.98 + (VERTEX.y - 0.98) * sy + (VERTEX.z + 1.30) * shear, VERTEX.z);
		NORMAL = normalize(vec3(NORMAL.x / sx, NORMAL.y / sy, NORMAL.z - NORMAL.y * shear / sy));
	}
}
void fragment() {
	// Subtle filaments across each flattened yarn; geometry carries every crossing.
	float fibre = 0.96 + 0.04 * sin(UV.y * 75.398 + UV.x * 130.0);
	ALBEDO = COLOR.rgb * fibre;
	ROUGHNESS = 0.94;
	SPECULAR = 0.18;
}
