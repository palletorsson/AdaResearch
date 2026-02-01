shader_type spatial;
render_mode blend_mix, cull_back;

// Circus Triangle Pattern - integrates with carousel_cake system

uniform float base_triangle_count : hint_range(4.0, 32.0) = 12.0;
uniform float triangle_density_multiplier : hint_range(1.0, 2.0) = 1.3;
uniform float layer_count : hint_range(1.0, 20.0) = 8.0;

uniform vec4 color_primary : source_color = vec4(0.957, 0.827, 0.369, 1.0); // Yellow
uniform vec4 color_secondary : source_color = vec4(0.102, 0.102, 0.102, 1.0); // Black

uniform float time_scale : hint_range(0.0, 2.0) = 0.0;

varying vec3 local_pos;
varying vec3 local_normal;
varying float layer_index;

void vertex() {
	local_pos = VERTEX;
	local_normal = NORMAL;
	layer_index = INSTANCE_CUSTOM.x;
}

// Signed distance to equilateral triangle
float sdTriangle(vec2 p) {
	const float k = sqrt(3.0);
	p.x = abs(p.x) - 0.5;
	p.y = p.y + 0.5 / k;
	if (p.x + k * p.y > 0.0) {
		p = vec2(p.x - k * p.y, -k * p.x - p.y) / 2.0;
	}
	p.x -= clamp(p.x, -1.0, 0.0);
	return -length(p) * sign(p.y);
}

void fragment() {
	float is_cap = abs(local_normal.y);
	
	float cap_angle = atan(local_pos.x, local_pos.z);
	float cap_normalized = (cap_angle + PI) / TAU;
	float side_normalized = UV.x;
	float angle = mix(side_normalized, cap_normalized, is_cap);
	
	float v = is_cap > 0.5 ? length(local_pos.xz) : UV.y;
	
	float layer_factor = layer_index / max(layer_count - 1.0, 1.0);
	float time_offset = TIME * time_scale * (1.0 + layer_factor * 2.0);
	angle = fract(angle + time_offset);
	
	float tri_count = base_triangle_count * pow(triangle_density_multiplier, layer_index);
	
	// Create triangle pattern
	float cell_u = fract(angle * tri_count);
	float cell_v = fract(v * tri_count * 0.866); // sqrt(3)/2 for equilateral
	
	// Center and scale for triangle
	vec2 p = (vec2(cell_u, cell_v) - vec2(0.5, 0.6)) * 2.2;
	
	float d = sdTriangle(p);
	float triangle = 1.0 - smoothstep(-0.02, 0.02, d);
	
	vec3 final_color = mix(color_primary.rgb, color_secondary.rgb, triangle);
	
	ALBEDO = final_color;
	METALLIC = 0.3;
	ROUGHNESS = 0.4;
}
