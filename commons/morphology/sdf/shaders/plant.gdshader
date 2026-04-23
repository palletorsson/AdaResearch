// plant.gdshader
// For stems, leaves, petals — translucent feel via fresnel-driven edge
// brightening. Uniform base color + fresnel rim. Subtle vein-like variation
// from low-frequency noise on normal-space position.

shader_type spatial;
render_mode cull_disabled;

uniform vec3 base_color : source_color = vec3(0.35, 0.62, 0.22);
uniform vec3 edge_color : source_color = vec3(0.9, 0.95, 0.5);
uniform float rim_strength : hint_range(0.0, 2.0) = 1.1;
uniform float rim_power : hint_range(0.5, 6.0) = 2.2;
uniform float vein_strength : hint_range(0.0, 0.8) = 0.15;
uniform float vein_scale : hint_range(0.5, 8.0) = 2.5;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.6;

void fragment() {
	// Fresnel — brightens where the surface normal is perpendicular to view.
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	vec3 mixed = mix(base_color, edge_color, fresnel * rim_strength);

	// Cheap vein variation from object-space position.
	vec3 v = vec3(sin(VERTEX.x * vein_scale), cos(VERTEX.y * vein_scale * 1.3),
	              sin(VERTEX.z * vein_scale * 0.7));
	float vein = (v.x * v.y * v.z) * 0.5 + 0.5;
	mixed *= mix(1.0 - vein_strength, 1.0 + vein_strength * 0.5, vein);

	ALBEDO = mixed;
	ROUGHNESS = roughness_val;
	METALLIC = 0.0;
	// Slight emission at the rim to simulate subsurface light leak
	EMISSION = edge_color * fresnel * 0.15;
}
