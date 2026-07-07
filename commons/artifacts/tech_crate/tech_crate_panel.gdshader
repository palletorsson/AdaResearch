shader_type spatial;

// Active tech-panel floor: a faint emissive grid + a bright accent SCANLINE
// that sweeps up the panel over time (animated). Sits behind the dark vent
// grille, so the X / fan / louver read as dark silhouettes over a live glow.

uniform vec4 floor_color : source_color = vec4(0.26, 0.27, 0.30, 1.0);
uniform vec4 accent_color : source_color = vec4(0.95, 0.50, 0.10, 1.0);
uniform float scan_speed : hint_range(0.0, 3.0) = 0.5;
uniform float grid_scale : hint_range(1.0, 24.0) = 7.0;
uniform float glow : hint_range(0.0, 3.0) = 1.0;

void fragment() {
	vec2 uv = UV;
	// faint tech grid
	vec2 gg = abs(fract(uv * grid_scale) - 0.5);
	float grid = smoothstep(0.44, 0.5, max(gg.x, gg.y));
	// scrolling scanline sweeping up the panel
	float sweep = fract(uv.y - TIME * scan_speed);
	float scan = smoothstep(0.0, 0.05, sweep) * (1.0 - smoothstep(0.05, 0.16, sweep));
	ALBEDO = floor_color.rgb;
	METALLIC = 0.5;
	ROUGHNESS = 0.45;
	EMISSION = accent_color.rgb * glow * (grid * 0.22 + scan * 0.9);
}
