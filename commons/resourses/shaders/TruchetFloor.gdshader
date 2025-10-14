// res://materials/TruchetFloor.shader
shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque, specular_schlick_ggx;


/* ---- Params ---- */
uniform float tile_size : hint_range(0.05, 5.0) = 0.70;
uniform float rotation_deg : hint_range(-180.0, 180.0) = 0.0;
uniform float grout : hint_range(0.0, 0.25) = 0.05;
uniform float edge_softness : hint_range(0.0, 0.2) = 0.02;
uniform vec4 grout_color : source_color = vec4(0.0, 0.0, 0.0, 1.0); // Defaulted to black
uniform int truchet_mode = 0;
uniform int preset = 0;

uniform float metallic : hint_range(0.0, 1.0) = 0.03;
uniform float roughness : hint_range(0.0, 1.0) = 0.45;
uniform float emission_strength : hint_range(0.0, 2.0) = 0.0;

/* This uniform is no longer used but left here to avoid breaking the material file */
uniform vec4 light_tile : source_color = vec4(0.94, 0.91, 0.82, 1.0);


/* ---- Varyings ---- */
varying vec3 v_world_pos;

/* ---- Helpers ---- */
float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

vec2 rot2d(vec2 p, float a) {
	float c = cos(a), s = sin(a);
	return mat2(vec2(c, -s), vec2(s, c)) * p;
}

vec3 hsv2rgb(vec3 c) {
	vec3 p = abs(fract(c.xxx + vec3(0.0, 1.0/3.0, 2.0/3.0)) * 6.0 - 3.0);
	return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

vec3 palette(int i) {
	if (preset == 0) {
		const vec3 pal[6] = vec3[](
			vec3(0.90,0.30,0.30), vec3(0.18,0.70,0.40), vec3(0.27,0.55,0.85),
			vec3(0.95,0.75,0.25), vec3(0.55,0.40,0.75), vec3(0.15,0.70,0.70)
		);
		return pal[i % 6];
	} else {
		float h = fract(float(i) * 0.61803398875);
		return hsv2rgb(vec3(h, 0.85, 0.95));
	}
}

/* ---- Stages ---- */
void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = v_world_pos.xz / max(tile_size, 1e-5);
	p = rot2d(p, radians(rotation_deg));

	vec2 cell = floor(p);
	vec2 uv = fract(p);

	// Randomly rotate the UVs for each tile to create the Truchet pattern
	int r = int(floor(hash21(cell) * 4.0)) % 4;
	if (r == 1) uv = rot2d(uv - 0.5, 0.5 * PI) + 0.5;
	else if (r == 2) uv = rot2d(uv - 0.5, PI) + 0.5;
	else if (r == 3) uv = rot2d(uv - 0.5, -0.5 * PI) + 0.5;

	// FIX: Corrected grout mask. It's now 0.0 for grout and 1.0 for the tile.
	float e = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
	float gmask = smoothstep(grout, grout + edge_softness, e);

	// Determine the pattern shape based on the mode
	float shape;
	if (truchet_mode == 0) { // Arcs
		float radius = 0.5;
		float thickness = clamp(0.25 - grout * 0.5, 0.05, 0.35);
		float softness = max(edge_softness * 3.0, 0.001);
		float diff_a = abs(length(uv - vec2(0.0, 0.0)) - radius);
		float diff_b = abs(length(uv - vec2(1.0, 1.0)) - radius);
		float arc_a = 1.0 - smoothstep(thickness, thickness + softness, diff_a);
		float arc_b = 1.0 - smoothstep(thickness, thickness + softness, diff_b);
		shape = clamp(max(arc_a, arc_b), 0.0, 1.0);
	} else if (truchet_mode == 1) { // Triangles
		shape = step(uv.x, uv.y);
	} else { // Quarter circles
		float r0 = 0.7071; // sqrt(0.5)
		float a = step(length(uv - vec2(0.0, 0.0)), r0);
		float b = step(length(uv - vec2(1.0, 1.0)), r0);
		shape = abs(a - b);
	}

	// FIX: Use two different colors from the palette for the pattern
	int idx = int(mod(cell.x + cell.y * 7.0, 10000.0));
	vec3 cA = palette(idx + int(floor(hash21(cell) * 8.0)));
	vec3 cB = palette(idx + int(floor(hash21(cell + 1.23) * 8.0)));
	
	// Create the colored pattern by mixing the two palette colors
	vec3 base = mix(cA, cB, shape);
	
	// Apply the grout color over the base pattern
	vec3 final_col = mix(grout_color.rgb, base, gmask);

	ALBEDO = final_col;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	EMISSION = final_col * emission_strength;
}