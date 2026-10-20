shader_type spatial;
render_mode cull_disabled;

uniform float density : hint_range(0.5, 2.0) = 1.0;
uniform float phase : hint_range(0.0, 1.0) = 0.0;
uniform float radius = 0.30;
uniform bool use_uv = false;
uniform bool attached = false;
uniform vec3 field_origin = vec3(0.0);
uniform mat4 receiver_inverse;
uniform vec4 ground : source_color = vec4(0.87, 0.80, 0.72, 1.0);
uniform vec4 ink : source_color = vec4(0.42, 0.075, 0.18, 1.0);
varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

float circle_at(vec2 p) {
	// The previous hall's circle, now read at each fractional tile address.
	vec2 tile_uv = fract(p * density + vec2(phase, 0.0));
	return 1.0 - step(radius, distance(tile_uv, vec2(0.5)));
}

void fragment() {
	vec3 p = world_position - field_origin;
	vec3 n = normalize(world_normal);
	if (attached) {
		p = (receiver_inverse * vec4(world_position, 1.0)).xyz;
		n = normalize(mat3(receiver_inverse) * n);
	}
	// Supplied projection adapter for architecture and the multi-part chair.
	vec3 weights = pow(abs(n), vec3(12.0));
	weights /= max(weights.x + weights.y + weights.z, 0.001);
	float mask = circle_at(p.zy) * weights.x + circle_at(p.xz) * weights.y + circle_at(p.xy) * weights.z;
	if (use_uv) {
		// This square represents three metres across, with complete 0..1 UVs.
		mask = circle_at(UV * 3.0);
	}
	ALBEDO = mix(ground.rgb, ink.rgb, mask);
	ROUGHNESS = 0.78;
	EMISSION = ALBEDO * 0.12;
}
