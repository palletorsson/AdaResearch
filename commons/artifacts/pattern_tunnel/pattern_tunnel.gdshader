shader_type spatial;
render_mode cull_disabled, diffuse_burley;

// The subway-tiled corridor surface: small tiles (grout grid) coloured by a wallpaper
// pattern, revealed from white as a front travels down the tunnel (world -Z).

uniform sampler2D pattern_tex : filter_nearest, repeat_enable;
uniform vec2 pattern_reps = vec2(3.0, 6.0);   // wallpaper swatch repeats across the surface
uniform vec2 tile_reps = vec2(12.0, 24.0);    // subway tile grid (small tiles -> high)
uniform float tunnel_len = 14.0;              // metres, for the reveal coordinate
uniform float reveal : hint_range(0.0, 1.2) = 1.0;
uniform float surf_offset = 0.0;              // floor 0 -> walls -> ceiling, for step-by-step fill
uniform vec3 white_col : source_color = vec3(0.95, 0.95, 0.96);
uniform vec3 grout_col : source_color = vec3(0.07, 0.07, 0.085);
uniform float grout = 0.06;
uniform float emission_amt = 0.10;

varying vec2 v_uv;
varying vec3 v_world;

void vertex() {
	v_uv = UV;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// wallpaper pattern colour for this tile
	vec3 pat = texture(pattern_tex, v_uv * pattern_reps).rgb;
	// subway tile grout grid
	vec2 cell = fract(v_uv * tile_reps);
	vec2 dd = abs(cell - vec2(0.5));
	float line = smoothstep(0.5 - grout, 0.5, max(dd.x, dd.y));
	// reveal front travels down the tunnel (mouth at z=0 -> far at z=-tunnel_len)
	float along = clamp(-v_world.z / max(tunnel_len, 0.001), 0.0, 1.0);
	float filled = step(along, reveal - surf_offset);
	vec3 col = mix(white_col, pat, filled);
	col = mix(col, grout_col, line);
	ALBEDO = col;
	ROUGHNESS = 0.72;
	METALLIC = 0.0;
	EMISSION = pat * emission_amt * filled;
}
