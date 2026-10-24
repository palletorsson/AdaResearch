shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;
// The ink stroke of the modular line (Palle, 23 Oct: "make a shader for the line").
// A drawn line, not a plastic tube: the ends taper like a pen lifting, the silhouette
// darkens as wet ink does at its edge, and a faint grain along the length breaks the
// flat shade. The mesh is a CylinderMesh whose axis is Y; `length` is its height.

uniform vec4 ink : source_color = vec4(0.169, 0.114, 0.078, 1.0);
uniform float length_m = 1.0;
uniform float taper = 0.55;      // width at the very ends relative to the middle
uniform float edge = 0.35;       // how much the silhouette darkens
uniform float grain = 0.06;      // shade variation along the stroke

varying float t_along;

float hash1(float n) {
	return fract(sin(n) * 43758.5453123);
}

void vertex() {
	t_along = clamp(VERTEX.y / max(length_m, 0.0001) + 0.5, 0.0, 1.0);
	// pen pressure: full in the middle, lifted at both ends
	float w = mix(taper, 1.0, pow(sin(t_along * PI), 0.35));
	VERTEX.xz *= w;
}

void fragment() {
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	float g = (hash1(floor(t_along * 48.0)) - 0.5) * 2.0 * grain;
	vec3 col = ink.rgb * (1.0 + g);
	col = mix(col, col * 0.45, fres * edge);
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
