shader_type spatial;
render_mode blend_mix, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec2  uv_scale = vec2(24.0, 24.0); // tiles per UV
uniform float angle_deg = 45.0;          // rotation of the grid
uniform float gutter   : hint_range(0.0, 0.5) = 0.08; // thickness of gaps
uniform float edge_soft: hint_range(0.0, 0.2) = 0.02; // feather for gutter

uniform vec4 col_a      : source_color = vec4(0.05,0.02,0.08,1.0);
uniform vec4 col_b      : source_color = vec4(1.0,0.0,0.8,1.0);
uniform vec4 col_gutter : source_color = vec4(0.02,0.98,0.85,1.0);

uniform float glow = 1.2;
uniform float metallic  : hint_range(0.0,1.0) = 0.0;
uniform float roughness : hint_range(0.0,1.0) = 0.45;

mat2 rot(float a){
    return mat2(
        vec2(cos(a), sin(a)),   // first column
        vec2(-sin(a), cos(a))   // second column
    );
}

void fragment(){
	// center, scale, rotate UV
	vec2 uv = (UV - 0.5);
	uv = rot(radians(angle_deg)) * uv;
	uv = uv * uv_scale + 0.5;

	// checker base
	float chk = mod(floor(uv.x) + floor(uv.y), 2.0);
	vec3 base = mix(col_a.rgb, col_b.rgb, chk);

	// gutter: distance to nearest grid line in either axis
	vec2 f = fract(uv);
	vec2 d = min(f, 1.0 - f);                 // distance to nearest edge per axis
	float edge_d = min(d.x, d.y);             // closest edge distance
	float gutter_mask = 1.0 - smoothstep(gutter, gutter + edge_soft, edge_d);

	// compose
	vec3 col = mix(base, col_gutter.rgb, gutter_mask);

	ALBEDO    = col;
	EMISSION  = col_gutter.rgb * gutter_mask * glow;
	METALLIC  = metallic;
	ROUGHNESS = roughness;
}
