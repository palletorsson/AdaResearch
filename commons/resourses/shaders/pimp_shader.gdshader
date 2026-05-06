shader_type spatial;
render_mode   depth_draw_opaque, cull_disabled, specular_schlick_ggx;

uniform float amplitude = 0.3;
uniform float frequency = 6.0;
uniform float speed = 1.0;
uniform vec4 base_color : source_color = vec4(0.5, 0.2, 1.0, 1.0);

void vertex() {
	float d = sin(TIME * speed + VERTEX.x * frequency + VERTEX.y * frequency + VERTEX.z * frequency);
	VERTEX += NORMAL * d * amplitude;
}

void fragment() {
	ALBEDO = base_color.rgb;
}
