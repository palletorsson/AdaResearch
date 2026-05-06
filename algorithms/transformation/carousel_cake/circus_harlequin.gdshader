shader_type spatial;
render_mode blend_mix, cull_back;

// Circus Harlequin Diamond Pattern - integrates with carousel_cake system

uniform float base_diamond_count : hint_range(2.0, 16.0) = 6.0;
uniform float diamond_density_multiplier : hint_range(1.0, 2.0) = 1.3;
uniform float layer_count : hint_range(1.0, 20.0) = 8.0;
uniform float dot_size : hint_range(0.02, 0.2) = 0.1;

uniform vec4 color_black : source_color = vec4(0.102, 0.102, 0.102, 1.0);
uniform vec4 color_yellow : source_color = vec4(0.957, 0.827, 0.369, 1.0);
uniform vec4 color_red : source_color = vec4(0.757, 0.071, 0.122, 1.0);
uniform vec4 color_white : source_color = vec4(0.973, 0.976, 0.980, 1.0);

uniform float time_scale : hint_range(0.0, 2.0) = 0.0;

varying vec3 local_pos;
varying vec3 local_normal;
varying float layer_index;

void vertex() {
	local_pos = VERTEX;
	local_normal = NORMAL;
	layer_index = INSTANCE_CUSTOM.x;
}

float sdRhombus(vec2 p, vec2 b) {
	vec2 q = abs(p);
	float h = clamp((-2.0 * dot(q, b) + dot(b, b)) / dot(b, b), -1.0, 1.0);
	float d = length(q - 0.5 * b * vec2(1.0 - h, 1.0 + h));
	return d * sign(q.x * b.y + q.y * b.x - b.x * b.y);
}

void fragment() {
	float is_cap = abs(local_normal.y);
	
	float cap_angle = atan(local_pos.x, local_pos.z);
	float cap_normalized = (cap_angle + PI) / TAU;
	float side_normalized = UV.x;
	float u = mix(side_normalized, cap_normalized, is_cap);
	
	float v = is_cap > 0.5 ? length(local_pos.xz) : UV.y;
	
	float layer_factor = layer_index / max(layer_count - 1.0, 1.0);
	float time_offset = TIME * time_scale * (1.0 + layer_factor * 2.0);
	u = fract(u + time_offset);
	
	float diamond_count = base_diamond_count * pow(diamond_density_multiplier, layer_index);
	
	// Grid coordinates
	vec2 scaled = vec2(u, v) * diamond_count;
	vec2 cell = floor(scaled);
	vec2 local = fract(scaled);
	vec2 p = local - 0.5;
	
	// Diamond shape
	float diamond = sdRhombus(p, vec2(0.4, 0.4));
	float in_diamond = 1.0 - smoothstep(-0.02, 0.02, diamond);
	
	// Start with black
	vec3 col = color_black.rgb;
	
	// Yellow center diamond
	col = mix(col, color_yellow.rgb, in_diamond);
	
	// Corner triangles - alternating based on cell position
	float checker = mod(cell.x + cell.y, 2.0);
	
	float corner_tl = step(local.x + local.y, 0.5) * (1.0 - in_diamond);
	float corner_br = step(1.5, local.x + local.y) * (1.0 - in_diamond);
	float corner_tr = step(0.5, local.x) * step(local.y, 0.5) * step(local.x - local.y, 0.5) * (1.0 - in_diamond);
	float corner_bl = step(local.x, 0.5) * step(0.5, local.y) * step(local.y - local.x, 0.5) * (1.0 - in_diamond);
	
	vec3 corner_a = mix(color_red.rgb, color_white.rgb, checker);
	vec3 corner_b = mix(color_white.rgb, color_red.rgb, checker);
	
	col = mix(col, corner_a, corner_tl + corner_br);
	col = mix(col, corner_b, corner_tr + corner_bl);
	
	// Connector dots at edges
	float dots = 0.0;
	dots = max(dots, step(length(local - vec2(0.5, 0.0)), dot_size));
	dots = max(dots, step(length(local - vec2(0.5, 1.0)), dot_size));
	dots = max(dots, step(length(local - vec2(0.0, 0.5)), dot_size));
	dots = max(dots, step(length(local - vec2(1.0, 0.5)), dot_size));
	
	col = mix(col, color_yellow.rgb, dots);
	
	ALBEDO = col;
	METALLIC = 0.3;
	ROUGHNESS = 0.4;
}
