shader_type spatial;
render_mode blend_mix, cull_disabled;

uniform vec2 uv_scale = vec2(12.0,12.0);
uniform float stripe_width = 0.35; // 0..0.5
uniform vec4 col_a : source_color = vec4(0.02,0.02,0.08,1.0);
uniform vec4 col_b : source_color = vec4(1.0,0.0,0.8,1.0);

void fragment(){
	vec2 uv = (UV - 0.5) * uv_scale;
	float d = fract((uv.x+uv.y)*0.5) - 0.5;
	float s = 1.0 - smoothstep(stripe_width, stripe_width*0.8, abs(d));
	ALBEDO = mix(col_a.rgb, col_b.rgb, s);
}