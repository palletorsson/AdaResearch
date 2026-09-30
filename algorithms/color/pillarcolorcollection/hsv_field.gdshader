shader_type spatial;
render_mode unshaded, cull_disabled;
// The same encoded RGB calculation draws the column, ceiling and held sample.
uniform int field_mode = 0; // 0: fixed sample, 1: column, 2: full-value ceiling
uniform vec3 sample_hsv = vec3(0.0, 1.0, 1.0);
uniform float bottom_y = -1.8;
uniform float top_y = 1.8;
uniform vec2 plane_offset = vec2(6.4, 9.6);
varying vec3 position_in_mesh;
void vertex() { position_in_mesh = VERTEX; }
vec3 hsv_rgb(vec3 hsv) {
	vec3 p = abs(fract(vec3(hsv.x) + vec3(0.0, 2.0/3.0, 1.0/3.0)) * 6.0 - 3.0);
	return hsv.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), hsv.y);
}
vec3 decode_srgb(vec3 c) {
	return mix(pow((c + vec3(0.055)) / 1.055, vec3(2.4)), c / 12.92, step(c, vec3(0.04045)));
}
void fragment() {
	vec3 hsv = sample_hsv;
	if (field_mode == 1) { hsv.z = clamp((position_in_mesh.y-bottom_y)/(top_y-bottom_y), 0.0, 1.0); }
	if (field_mode == 2) {
		vec2 address = clamp((position_in_mesh.xz + plane_offset) / vec2(12.8, 19.2), vec2(0.0), vec2(1.0));
		hsv = vec3(address.x * 0.85, mix(0.25, 1.0, address.y), 1.0);
	}
	vec3 rgb = hsv_rgb(hsv);
	ALBEDO = OUTPUT_IS_SRGB ? rgb : decode_srgb(rgb);
}
