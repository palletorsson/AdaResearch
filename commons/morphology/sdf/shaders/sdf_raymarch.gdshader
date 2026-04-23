// sdf_raymarch.gdshader
// Fragment shader that sphere-traces a baked SDF stored in a 3D texture.
// Replaces thousands of voxel cubes with one box mesh and per-pixel
// raymarching on the GPU. Smooth surfaces, correct depth, real lighting.
//
// The host script (sdf_raymarch_preview.gd) bakes the SDF once, places
// a BoxMesh at the AABB, assigns this material. The fragment shader
// walks a ray from the camera through the volume and shades on hit.

shader_type spatial;
render_mode depth_draw_opaque, specular_schlick_ggx;

uniform sampler3D sdf_tex : filter_linear, repeat_disable;
uniform vec3 aabb_min;
uniform vec3 aabb_size;

uniform vec3 base_color : source_color = vec3(0.9, 0.85, 0.75);
uniform vec3 edge_color : source_color = vec3(1.0, 0.95, 0.8);
uniform float rim_strength : hint_range(0.0, 2.0) = 0.7;
uniform float rim_power : hint_range(0.5, 6.0) = 2.5;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.55;
uniform int max_steps : hint_range(16, 256) = 96;
uniform float hit_threshold : hint_range(0.0001, 0.05) = 0.003;
uniform float surface_offset : hint_range(-0.2, 0.2) = 0.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float sample_sdf(vec3 p) {
	// Clamp uvw to [0,1] so we always sample a valid voxel, then add the
	// distance from p to the AABB (zero when inside, positive when outside).
	// This avoids the off-by-float-precision trap where p exactly on the
	// AABB boundary returned 0 and caused every ray to hit at entry.
	vec3 uvw = (p - aabb_min) / aabb_size;
	vec3 uvw_c = clamp(uvw, vec3(0.001), vec3(0.999));
	float d_inside = texture(sdf_tex, uvw_c).r;
	vec3 out_q = max(aabb_min - p, p - (aabb_min + aabb_size));
	float d_outside = length(max(out_q, vec3(0.0)));
	return d_inside + d_outside + surface_offset;
}

vec3 sdf_gradient(vec3 p) {
	float e = 0.003;
	return normalize(vec3(
		sample_sdf(p + vec3(e, 0.0, 0.0)) - sample_sdf(p - vec3(e, 0.0, 0.0)),
		sample_sdf(p + vec3(0.0, e, 0.0)) - sample_sdf(p - vec3(0.0, e, 0.0)),
		sample_sdf(p + vec3(0.0, 0.0, e)) - sample_sdf(p - vec3(0.0, 0.0, e))
	));
}

void fragment() {
	vec3 ro = CAMERA_POSITION_WORLD;
	vec3 rd = normalize(world_pos - ro);

	// Start the march at the front-face of the AABB (this fragment).
	// If the camera is inside the box, t starts at 0.
	float t = max(distance(ro, world_pos) - 0.01, 0.0);
	float hit_t = -1.0;

	for (int i = 0; i < max_steps; i++) {
		vec3 p = ro + rd * t;
		float d = sample_sdf(p);
		if (d < hit_threshold) { hit_t = t; break; }
		t += max(d, 0.001);
		if (t > 80.0) break;
	}

	if (hit_t < 0.0) {
		discard;
	}

	vec3 hit_p = ro + rd * hit_t;
	vec3 normal = sdf_gradient(hit_p);
	// Fragment normal in view space for Godot lighting integration
	NORMAL = (VIEW_MATRIX * vec4(normal, 0.0)).xyz;

	// Fresnel rim
	float fresnel = pow(1.0 - clamp(dot(normal, -rd), 0.0, 1.0), rim_power);
	vec3 albedo = mix(base_color, edge_color, fresnel * rim_strength);

	ALBEDO = albedo;
	ROUGHNESS = roughness_val;
	METALLIC = 0.0;

	// Write correct depth so the raymarched surface occludes properly
	// against other geometry (pedestals, floor, labels).
	vec4 clip = PROJECTION_MATRIX * VIEW_MATRIX * vec4(hit_p, 1.0);
	DEPTH = clip.z / clip.w;
}
