shader_type spatial;
render_mode blend_mix, cull_back;

// Base stripe parameters
uniform float base_stripe_count : hint_range(4.0, 64.0) = 12.0;
uniform float stripe_width : hint_range(0.1, 0.9) = 0.5;
uniform float stripe_sharpness : hint_range(0.01, 0.5) = 0.05;

// Layer-based variation (denser stripes = faster perceived rotation)
uniform float stripe_density_multiplier : hint_range(1.0, 2.0) = 1.3;
uniform float layer_count : hint_range(1.0, 20.0) = 8.0;

// Colors
uniform vec4 color_a : source_color = vec4(0.992, 0.323, 0.882, 1.0);
uniform vec4 color_b : source_color = vec4(0.228, 0.867, 1.0, 1.0);

// Animation (if you want shader-driven rotation preview)
uniform float time_scale : hint_range(0.0, 2.0) = 0.0;

varying vec3 local_pos;
varying vec3 local_normal;
varying float layer_index;

void vertex() {
	// Keep local position for stripe calculation (moves with mesh)
	local_pos = VERTEX;
	local_normal = NORMAL;
	// Get layer index from instance custom data (set per-instance in GDScript)
	layer_index = INSTANCE_CUSTOM.x;
}

void fragment() {
	// Detect if we're on a cap (normal pointing up/down) or side (normal pointing outward)
	float is_cap = abs(local_normal.y);  // 1.0 for caps, 0.0 for sides

	// For caps: use atan of local position (radial pattern)
	float cap_angle = atan(local_pos.x, local_pos.z);
	float cap_normalized = (cap_angle + PI) / TAU;

	// For sides: use UV.x which maps around the cylinder circumference
	float side_normalized = UV.x;

	// Blend between the two based on surface type
	float normalized_angle = mix(side_normalized, cap_normalized, is_cap);

	// Normalize layer index to 0-1 range
	float layer_factor = layer_index / max(layer_count - 1.0, 1.0);

	// Optional time-based animation offset (for editor preview)
	float time_offset = TIME * time_scale * (1.0 + layer_factor * 2.0);
	normalized_angle = fract(normalized_angle + time_offset);

	// Calculate stripe count for this layer (constant per layer now)
	// Higher layers (faster rotation) get more stripes
	float layer_stripe_multiplier = pow(stripe_density_multiplier, layer_index);
	float effective_stripe_count = base_stripe_count * layer_stripe_multiplier;

	// Create stripe pattern
	float stripe_phase = fract(normalized_angle * effective_stripe_count);

	// Smooth stripe edges
	float stripe = smoothstep(stripe_width - stripe_sharpness, stripe_width, stripe_phase);
	stripe -= smoothstep(1.0 - stripe_sharpness, 1.0, stripe_phase);
	stripe = clamp(stripe, 0.0, 1.0);

	// Mix colors
	vec3 final_color = mix(color_a.rgb, color_b.rgb, stripe);

	ALBEDO = final_color;

	// Slight metallic/roughness variation for depth
	METALLIC = 0.1 + stripe * 0.1;
	ROUGHNESS = 0.6 - stripe * 0.2;
}
