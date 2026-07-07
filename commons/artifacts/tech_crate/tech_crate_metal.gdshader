shader_type spatial;
render_mode cull_disabled;

// Worn machined-metal body: PBR base + procedural grime + a fresnel rim
// glow tinted by the crate's accent colour. Static (no TIME).

uniform vec4 body_color : source_color = vec4(0.13, 0.14, 0.16, 1.0);
uniform float metallic_amt : hint_range(0.0, 1.0) = 0.6;
uniform float roughness_amt : hint_range(0.0, 1.0) = 0.5;
uniform vec4 rim_color : source_color = vec4(0.4, 0.6, 0.9, 1.0);
uniform float rim_strength : hint_range(0.0, 4.0) = 0.45;
uniform float grime : hint_range(0.0, 1.0) = 0.28;

varying vec3 world_pos;

float hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

float vnoise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash13(i + vec3(0.0, 0.0, 0.0));
	float n100 = hash13(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash13(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash13(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash13(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash13(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash13(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash13(i + vec3(1.0, 1.0, 1.0));
	return mix(mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y),
	           mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y), f.z);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float g = vnoise(world_pos * 9.0);
	float g2 = vnoise(world_pos * 2.3);
	ALBEDO = body_color.rgb * (1.0 - grime * (0.45 * g + 0.2 * g2));
	METALLIC = metallic_amt;
	ROUGHNESS = clamp(roughness_amt + grime * 0.35 * g, 0.0, 1.0);
	float fres = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 3.0);
	EMISSION = rim_color.rgb * fres * rim_strength;
}
