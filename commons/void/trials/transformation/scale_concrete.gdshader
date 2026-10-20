shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.72, 0.70, 0.64, 1.0);
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.94;
varying vec3 object_position;
varying vec3 object_normal;

void vertex() {
	object_position = VERTEX;
	object_normal = NORMAL;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), f.x),
		mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0)), f.x), f.y);
}

void fragment() {
	// Coordinates belong to the original unit cube: seams grow with the body.
	vec3 n = abs(object_normal);
	vec2 uv = object_position.xy;
	if (n.y > 0.5) { uv = object_position.xz; }
	else if (n.x > 0.5) { uv = object_position.zy; }
	uv += vec2(0.5);
	vec2 panel = uv * 4.0;
	vec2 seam_distance = abs(fract(panel + 0.5) - 0.5);
	vec2 aa = max(fwidth(panel), vec2(0.002));
	vec2 seams = 1.0 - smoothstep(vec2(0.012), vec2(0.012) + aa, seam_distance);
	float seam = max(seams.x, seams.y);
	vec2 tie_position = (fract(panel) - 0.5) * vec2(1.0, 1.0);
	float tie = 1.0 - smoothstep(0.018, 0.035 + length(aa), length(tie_position));
	float cast_variation = noise(uv * 23.0) * 0.12 + noise(uv * 91.0) * 0.035;
	vec3 concrete = base_color.rgb * (0.91 + cast_variation);
	concrete *= 1.0 - seam * 0.22 - tie * 0.26;
	ALBEDO = concrete;
	METALLIC = metallic;
	ROUGHNESS = roughness;
}
