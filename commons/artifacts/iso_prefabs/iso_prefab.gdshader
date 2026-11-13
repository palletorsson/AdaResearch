shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// The isosurface prefabs' one material (the boolean floor, 2026-11-13). Vertex COLOR is DATA written by
// tools/iso_prefabs.py from each form's distance-field expression: r = a difference cut this face, g = an intersection
// trimmed it, b = the band where a smooth union melted two bodies, a = ambient occlusion read from the field along the
// normal (the floor counted as solid). The finish decides what that data looks like.
//   0 paint: the hall's own colours - a cut is CUT_COLOR orange, a trim sea-green, a band the union demo's seam yellow
//   1 satin: the Random Boolean Carving's demo (randomboolean/all_patterns_demo.tscn). Its body is advanced_carver.gd's
//            material - albedo 0.7 0.7 0.8, metallic 0.3, roughness 0.7 - and its cutters carry no material, so every
//            cave wall is Godot's default material (0.6 linear, roughness 0.8, metallic 0.2): here the faces a difference
//            made take that default, which is the demo's own way of showing a face neither operand brought. The demo is
//            lit by a white sun at 1.5, sixty degrees up, with SSAO; the tower's floors sit in the shade of the floor
//            above under a low evening sun and flat colour ambient, which turned the satin into dark violet plastic
//            (measured in review, 2026-11-13: pieces at 0.53 - 0.82 of the floor's luminance). So the satin carries the
//            demo's sun as a soft wrapped key and a broad sheen, through EMISSION, and the baked occlusion is applied
//            once - a light cavity tint in the albedo, the rest through AO, which (like SSAO) shuts out ambient light only.
//   2 cast: one pale material, occlusion only
uniform int finish = 1;
uniform vec3 body_colour : source_color = vec3(0.86, 0.84, 0.80);
uniform vec3 cut_colour : source_color = vec3(1.0, 0.55, 0.35);
uniform vec3 trim_colour : source_color = vec3(0.50, 0.80, 0.74);
uniform vec3 band_colour : source_color = vec3(1.0, 0.95, 0.65);
uniform vec3 pale_colour : source_color = vec3(0.80, 0.78, 0.74);
uniform float ao_strength = 0.7;
uniform vec3 satin_colour : source_color = vec3(0.7, 0.7, 0.8);
uniform float satin_metallic = 0.3;
uniform float satin_roughness = 0.7;
uniform vec3 cave_colour = vec3(0.6);                    // Godot's default material, linear (no source_color)
uniform float cave_roughness = 0.8;
uniform float cave_metallic = 0.2;
uniform vec3 trim_tint = vec3(0.93, 1.0, 1.06);
uniform vec3 band_tint = vec3(1.08, 1.07, 1.02);
uniform float key_energy = 0.45;
uniform vec3 key_dir = vec3(-0.30, 0.85, 0.43);          // from above, on the side of the tower's low sun
uniform vec3 key_colour : source_color = vec3(1.0, 0.97, 0.93);
uniform float sheen = 0.06;
uniform float ao_gain = 1.25;

varying float key;
varying vec3 key_view;

void vertex() {
	vec3 n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float w = 0.5 + 0.5 * dot(n, normalize(key_dir));
	key = w * w;
	key_view = normalize((VIEW_MATRIX * vec4(normalize(key_dir), 0.0)).xyz);
}

void fragment() {
	float cut = COLOR.r;
	float trim = COLOR.g;
	float band = COLOR.b;
	float ao = COLOR.a;
	if (finish == 1) {
		ao = clamp(ao * ao_gain, 0.0, 1.0);
		ao = mix(ao, 1.0, 0.25 * cut);                    // the demo's SSAO reached a short way; a cave is not shut in
		vec3 tint = mix(vec3(1.0), trim_tint, trim);
		tint = mix(tint, band_tint, band);
		vec3 base = mix(satin_colour, cave_colour, cut) * tint;
		float metal = mix(satin_metallic, cave_metallic, cut);
		float ao_out = mix(0.15, 1.0, ao);
		ALBEDO = base * mix(0.75, 1.0, ao);
		AO = ao_out;
		AO_LIGHT_AFFECT = 0.0;
		ROUGHNESS = mix(satin_roughness - 0.15 * band, cave_roughness, cut);
		METALLIC = metal;
		EMISSION = ALBEDO * (1.0 - metal) * key_colour * key_energy * key * ao_out
			+ key_colour * sheen * pow(max(dot(NORMAL, normalize(key_view + VIEW)), 0.0), 12.0) * ao_out * (1.0 - cut);
	} else {
		vec3 base;
		float rough = 0.78;
		if (finish == 0) {
			base = mix(body_colour, cut_colour, cut);
			base = mix(base, trim_colour, trim);
			base = mix(base, band_colour, band);
		} else {
			base = pale_colour;
			rough = 0.86;
		}
		ALBEDO = base * mix(1.0 - ao_strength, 1.0, ao);
		AO = ao;
		AO_LIGHT_AFFECT = 0.3;
		ROUGHNESS = rough;
		METALLIC = 0.0;
	}
}
