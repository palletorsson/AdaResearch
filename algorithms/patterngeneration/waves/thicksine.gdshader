shader_type spatial;
render_mode blend_mix, cull_disabled;

uniform vec2 uv_scale = vec2(4.0, 1.0);
uniform int count : hint_range(1,120) = 60;
uniform float amplitude = 0.25;
uniform float freq = 8.0;
uniform float thickness = 0.12;    // visual thickness of each curve
uniform float phase_step = 0.15;   // per-band phase offset
uniform float speed = 1.0;
uniform vec4 col_bg  : source_color = vec4(0.03,0.0,0.06,1.0);
uniform vec4 col_fx  : source_color = vec4(0.9,0.4,1.0,1.0);
uniform float glow = 1.4;

void fragment(){
	vec2 uv = UV * uv_scale;

	// which band (0..count-1) am I on?
	float idf = floor(clamp(float(count)*uv.y, 0.0, float(count)-1.0));
	float y_center = (idf + 0.5) / float(count);

	// centerline for this band
	float phase = idf * phase_step + TIME*speed;
	float y_curve = y_center + amplitude/float(count) * sin(uv.x*freq + phase);

	// thickness mask
	float dist = abs(uv.y - y_curve) * float(count);
	float mask = 1.0 - smoothstep(thickness, thickness*0.6, dist);

	vec3 col = mix(col_bg.rgb, col_fx.rgb, mask);
	ALBEDO = col;
	EMISSION = col_fx.rgb * pow(mask, 1.2) * glow;
}
