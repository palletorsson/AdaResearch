shader_type spatial;
render_mode blend_mix, cull_back;

// Circus Tent Scallop Pattern - integrates with carousel_cake system

uniform float base_scallop_count : hint_range(4.0, 32.0) = 8.0;
uniform float scallop_density_multiplier : hint_range(1.0, 2.0) = 1.3;
uniform float layer_count : hint_range(1.0, 20.0) = 8.0;

uniform vec4 color_primary : source_color = vec4(0.757, 0.071, 0.122, 1.0); // Red
uniform vec4 color_secondary : source_color = vec4(0.973, 0.976, 0.980, 1.0); // White

uniform float time_scale : hint_range(0.0, 2.0) = 0.0;

varying vec3 local_pos;
varying vec3 local_normal;
varying float layer_index;

void vertex() {
	local_pos = VERTEX;
	local_normal = NORMAL;
	layer_index = INSTANCE_CUSTOM.x;
}

void fragment() {
	float is_cap = abs(local_normal.y);
	
	// Angle around cylinder
	float cap_angle = atan(local_pos.x, local_pos.z);
	float cap_normalized = (cap_angle + PI) / TAU;
	float side_normalized = UV.x;
	float angle = mix(side_normalized, cap_normalized, is_cap);
	
	// Vertical position (0-1 on sides)
	float v = is_cap > 0.5 ? length(local_pos.xz) : UV.y;
	
	// Layer-based density
	float layer_factor = layer_index / max(layer_count - 1.0, 1.0);
	float time_offset = TIME * time_scale * (1.0 + layer_factor * 2.0);
	angle = fract(angle + time_offset);
	
	float scallop_count = base_scallop_count * pow(scallop_density_multiplier, layer_index);
	
	// Create scallop pattern using overlapping circles
	float cell_angle = fract(angle * scallop_count);
	float cell_v = fract(v * scallop_count * 0.5);
	
	// Two rows of offset circles
	vec2 p1 = vec2(cell_angle, cell_v);
	vec2 c1 = vec2(0.5, 0.0);
	vec2 c2 = vec2(0.0, 0.5);
	vec2 c3 = vec2(1.0, 0.5);
	
	float d1 = length(p1 - c1);
	float d2 = length(p1 - c2);
	float d3 = length(p1 - c3);
	
	float radius = 0.5;
	float scallop = min(min(d1, d2), d3);
	float in_circle = 1.0 - smoothstep(radius - 0.05, radius + 0.05, scallop);
	
	vec3 final_color = mix(color_primary.rgb, color_secondary.rgb, in_circle);
	
	ALBEDO = final_color;
	METALLIC = 0.3;
	ROUGHNESS = 0.4;
}
