/*
	Wood Grain Shader by Yui Kinomoto @arlez80
	Modified for per-cube variation
	MIT License
*/
shader_type spatial;
// render_mode;

uniform vec4 light_color = vec4(0.9529411764705882, 0.8588235294117647, 0.7490196078431373, 1.0);
uniform vec4 dark_color = vec4(0.7490196078431373, 0.6196078431372549, 0.49019607843137253, 1.0);

uniform float ring_scale = 4.4;
uniform float wave_scale = 8.454;
uniform float random_scale = 4.6;
uniform float noise_scale = 0.03;

// New uniform for cube position to vary the pattern
uniform vec3 cube_position;  // X, Y, Z position of the cube in the grid

vec2 random(vec2 pos) {
	return fract(
		sin(
			vec2(
				dot(pos, vec2(12.9898, 78.233)),
				dot(pos, vec2(-148.998, -65.233))
			)
		) * 43758.5453
	);
}

float value_noise(vec2 pos) {
	vec2 p = floor(pos);
	vec2 f = fract(pos);

	float v00 = random(p + vec2(0.0, 0.0)).x;
	float v10 = random(p + vec2(1.0, 0.0)).x;
	float v01 = random(p + vec2(0.0, 1.0)).x;
	float v11 = random(p + vec2(1.0, 1.0)).x;

	vec2 u = f * f * (3.0 - 2.0 * f);

	// Use cube_position to vary the noise
	float position_influence = dot(cube_position.xz, vec2(1.0, 2.0));  // Use X and Z for variation
	return mix(mix(v00, v10, u.x), mix(v01, v11, u.x), u.y) * (1.0 + sin(position_influence * 0.1));
}

void fragment() {
	vec2 shift_uv = UV;
	// Offset UV based on cube position for variation
	shift_uv += vec2(cube_position.x * 0.1, cube_position.z * 0.1);  // Small offset per cube
	shift_uv.x += value_noise(shift_uv * random_scale);

	// Vary ring_scale and wave_scale slightly per cube
	float varied_ring_scale = ring_scale + (cube_position.x + cube_position.z) * 0.1;
	float varied_wave_scale = wave_scale + (cube_position.y) * 0.05;

	float x = shift_uv.x + sin(shift_uv.y * varied_wave_scale);
	float f = mod(x * varied_ring_scale + random(shift_uv).x * noise_scale, 1.0);

	ALBEDO = mix(light_color, dark_color, f).rgb;
	ALPHA = mix(light_color, dark_color, f).a;
}