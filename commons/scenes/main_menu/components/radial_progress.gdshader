shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float radius : hint_range(0.0, 0.5) = 0.4;
uniform float thickness : hint_range(0.0, 0.5) = 0.05;

void fragment() {
	vec2 uv = UV - 0.5;
	float dist = length(uv);
	float angle = atan(uv.y, uv.x);
	// Normalize angle to 0-1 range, starting from top (-PI/2)
	float normalized_angle = (angle + 3.14159 * 0.5) / (2.0 * 3.14159);
	if (normalized_angle < 0.0) {
		normalized_angle += 1.0;
	}
	
	float alpha = 0.0;
	
	// Ring shape
	if (dist > radius - thickness && dist < radius) {
		// Progress check
		if (normalized_angle < progress) {
			alpha = 1.0;
		}
	}
	
	ALBEDO = color.rgb;
	ALPHA = color.a * alpha;
}
