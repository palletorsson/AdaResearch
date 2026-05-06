shader_type spatial;
render_mode blend_mix, cull_back;

// Complete Circus Tin - All patterns per layer, like stacked Alessi tins
// Layer 0-1: Scallop tent (top cap)
// Layer 2-3: Triangles
// Layer 4: Stripes
// Layer 5-7: Harlequin

uniform float base_pattern_count : hint_range(4.0, 24.0) = 10.0;
uniform float pattern_density_multiplier : hint_range(1.0, 2.0) = 1.3;
uniform float layer_count : hint_range(1.0, 20.0) = 8.0;
uniform float dot_size : hint_range(0.02, 0.2) = 0.08;

uniform vec4 color_black : source_color = vec4(0.102, 0.102, 0.102, 1.0);
uniform vec4 color_yellow : source_color = vec4(0.957, 0.827, 0.369, 1.0);
uniform vec4 color_red : source_color = vec4(0.757, 0.071, 0.122, 1.0);
uniform vec4 color_white : source_color = vec4(0.973, 0.976, 0.980, 1.0);
uniform vec4 color_silver : source_color = vec4(0.6, 0.62, 0.65, 1.0);
uniform vec4 color_gold : source_color = vec4(1.0, 0.84, 0.0, 1.0);

uniform float time_scale : hint_range(0.0, 2.0) = 0.0;

varying vec3 local_pos;
varying vec3 local_normal;
varying float layer_index;

void vertex() {
	local_pos = VERTEX;
	local_normal = NORMAL;
	layer_index = INSTANCE_CUSTOM.x;
}

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

float sdRhombus(vec2 p, vec2 b) {
	vec2 q = abs(p);
	float h = clamp((-2.0 * dot(q, b) + dot(b, b)) / dot(b, b), -1.0, 1.0);
	float d = length(q - 0.5 * b * vec2(1.0 - h, 1.0 + h));
	return d * sign(q.x * b.y + q.y * b.x - b.x * b.y);
}

vec3 scallop_pattern(vec2 uv, float count) {
	float cell_u = fract(uv.x * count);
	float cell_v = fract(uv.y * count * 0.5);
	
	vec2 p1 = vec2(cell_u, cell_v);
	float d1 = length(p1 - vec2(0.5, 0.0));
	float d2 = length(p1 - vec2(0.0, 0.5));
	float d3 = length(p1 - vec2(1.0, 0.5));
	
	float scallop = min(min(d1, d2), d3);
	float in_circle = 1.0 - smoothstep(0.45, 0.55, scallop);
	
	return mix(color_red.rgb, color_white.rgb, in_circle);
}

vec3 triangle_pattern(vec2 uv, float count) {
	float cell_u = fract(uv.x * count);
	float cell_v = fract(uv.y * count * 0.866);
	
	vec2 p = (vec2(cell_u, cell_v) - vec2(0.5, 0.6)) * 2.2;
	float d = sdTriangle(p);
	float triangle = 1.0 - smoothstep(-0.02, 0.02, d);
	
	return mix(color_yellow.rgb, color_black.rgb, triangle);
}

vec3 stripe_pattern(vec2 uv, float count) {
	float stripe = step(0.5, fract(uv.x * count * 2.0));
	return mix(color_red.rgb, color_yellow.rgb, stripe);
}

vec3 harlequin_pattern(vec2 uv, float count) {
	vec2 scaled = uv * count;
	vec2 cell = floor(scaled);
	vec2 local = fract(scaled);
	vec2 p = local - 0.5;
	
	float diamond = sdRhombus(p, vec2(0.4, 0.4));
	float in_diamond = 1.0 - smoothstep(-0.02, 0.02, diamond);
	
	vec3 col = color_black.rgb;
	col = mix(col, color_yellow.rgb, in_diamond);
	
	float checker = mod(cell.x + cell.y, 2.0);
	float corner_tl = step(local.x + local.y, 0.5) * (1.0 - in_diamond);
	float corner_br = step(1.5, local.x + local.y) * (1.0 - in_diamond);
	
	vec3 corner_a = mix(color_red.rgb, color_white.rgb, checker);
	col = mix(col, corner_a, corner_tl + corner_br);
	
	// Dots
	float dots = 0.0;
	dots = max(dots, step(length(local - vec2(0.5, 0.0)), dot_size));
	dots = max(dots, step(length(local - vec2(0.5, 1.0)), dot_size));
	dots = max(dots, step(length(local - vec2(0.0, 0.5)), dot_size));
	dots = max(dots, step(length(local - vec2(1.0, 0.5)), dot_size));
	col = mix(col, color_yellow.rgb, dots);
	
	return col;
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
	
	float pattern_count = base_pattern_count * pow(pattern_density_multiplier, layer_index);
	
	vec2 uv = vec2(u, v);
	vec3 col;
	float metal = 0.3;
	float rough = 0.4;
	
	// Assign pattern based on layer
	int layer = int(layer_index);
	
	if (layer <= 1) {
		// Top layers: Scallop tent pattern
		col = scallop_pattern(uv, pattern_count);
	} else if (layer <= 3) {
		// Middle layers: Triangle pattern  
		col = triangle_pattern(uv, pattern_count);
	} else if (layer == 4) {
		// Accent layer: Stripes
		col = stripe_pattern(uv, pattern_count);
	} else {
		// Bottom layers: Harlequin diamonds
		col = harlequin_pattern(uv, pattern_count * 0.5);
	}
	
	// Add silver band effect at layer boundaries (thin horizontal lines)
	float band = smoothstep(0.02, 0.0, v) + smoothstep(0.98, 1.0, v);
	col = mix(col, color_silver.rgb, band * 0.5);
	metal = mix(metal, 0.7, band);
	
	ALBEDO = col;
	METALLIC = metal;
	ROUGHNESS = rough;
}
