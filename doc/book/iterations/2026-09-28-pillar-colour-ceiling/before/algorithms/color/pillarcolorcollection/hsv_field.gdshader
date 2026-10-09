shader_type spatial;
render_mode unshaded, cull_disabled;
// The same encoded RGB calculation draws the column, floor and held sample.
uniform int field_mode = 0; // 0: fixed sample, 1: column, 2: bright floor
uniform vec3 sample_hsv = vec3(0.0, 1.0, 1.0);
uniform float bottom_y = -1.8;
uniform float top_y = 1.8;
varying float height_in_mesh;
void vertex() { height_in_mesh = VERTEX.y; }
vec3 hsv_rgb(vec3 hsv) {
	vec3 p = abs(fract(vec3(hsv.x) + vec3(0.0, 2.0/3.0, 1.0/3.0)) * 6.0 - 3.0);
	return hsv.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), hsv.y);
}
vec3 decode_srgb(vec3 c) {
	return mix(pow((c + vec3(0.055)) / 1.055, vec3(2.4)), c / 12.92, step(c, vec3(0.04045)));
}
void fragment() {
	vec3 hsv = sample_hsv;
	if (field_mode == 1) { hsv.z = clamp((height_in_mesh-bottom_y)/(top_y-bottom_y), 0.0, 1.0); }
	if (field_mode == 2) { hsv = vec3(UV.x*0.85, mix(0.25, 1.0, UV.y), 0.95); }
	vec3 rgb = hsv_rgb(hsv);
	ALBEDO = OUTPUT_IS_SRGB ? rgb : decode_srgb(rgb);
}
