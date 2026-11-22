shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;
// CONTACT (commons/artifacts/contact_study): one meeting of two bodies in four finishes.
// The vertex colour is DATA written by tools/contact_forms.py, never a colour:
//   r  how much of body A this point is (1 on A alone, 0 on B alone; between, the smooth union's mixing weight)
//   g  1 on a face a boolean cut made; for INSIDE, how deep under the skin a point of the cut lies; for WITHIN,
//      0 on the skin and 1 on the room's wall
//   b  the join's band: 1 at the middle of a neck between the two, 0 away from it
//   a  ambient occlusion read from the distance field
// finish 0 CLAY   two raw meshes: every triangle flat, as a viewport shows them before anything is decided
// finish 1 CUT    a black body; what the other body took away is left as a bright face
// finish 2 CUBES  a cell is the colour of what it is mostly made of
// finish 3 SKIN   the two bodies' colours run into each other through the join; a thin film turns with the
//                 angle of view; the lines are the levels of the mixing weight, so they crowd where the two meet
// finish 4 INSIDE the skin as in 3; on a face another form cut (g = depth under the skin there, 0 on the skin)
//                 the field in rings
// finish 5 WITHIN the skin as in 3 outside; the wall of the room inside it (g = 1 there) lit by itself
uniform int finish = 3;
uniform vec3 colour_a : source_color = vec3(1.0, 0.31, 0.55);
uniform vec3 colour_b : source_color = vec3(0.23, 0.36, 1.0);
uniform vec3 join_colour : source_color = vec3(0.93, 0.82, 1.0);
uniform vec3 cut_colour : source_color = vec3(1.0, 0.24, 0.55);
uniform vec3 clay_colour : source_color = vec3(0.60, 0.59, 0.57);
uniform vec3 line_colour : source_color = vec3(1.0, 0.97, 0.92);
uniform float ao_strength = 0.75;
uniform float join_amount = 0.55;
uniform float film_amount = 0.75;
uniform float film_turns = 0.85;
uniform float film_shift = 0.08;
uniform float line_count = 9.0;
uniform float line_amount = 0.55;
uniform float glow = 0.35;
uniform float ring_count = 8.0;
uniform float within_glow = 0.55;
uniform float within_top = 0.5;     // how tall the room is, in the form's own metres: its light deepens towards the top

varying float height;       // the point's height in the form's own metres

void vertex() {
	height = VERTEX.y;
}

void fragment() {
	float weight = clamp(COLOR.r, 0.0, 1.0);
	float cut = clamp(COLOR.g, 0.0, 1.0);
	float band = clamp(COLOR.b, 0.0, 1.0);
	float ao = mix(1.0, clamp(COLOR.a, 0.0, 1.0), ao_strength);
	vec3 n = normalize(NORMAL);
	vec3 v = normalize(VIEW);
	if (finish == 0) {
		// the triangle's own plane, not the smoothed normal: the mesh as it is
		vec3 flat_n = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
		if (dot(flat_n, v) < 0.0) flat_n = -flat_n;
		NORMAL = flat_n;
		ALBEDO = mix(clay_colour * 0.92, clay_colour, weight) * ao;
		ROUGHNESS = 0.92;
		SPECULAR = 0.2;
	} else if (finish == 1) {
		ALBEDO = mix(vec3(0.045, 0.045, 0.052), cut_colour, cut) * ao;
		ROUGHNESS = mix(0.30, 0.16, cut);
		SPECULAR = 0.55;
		EMISSION = cut_colour * cut * 0.22;
	} else if (finish == 2) {
		vec3 base = mix(colour_b, colour_a, weight);
		ALBEDO = mix(base, join_colour, band * join_amount);
		ROUGHNESS = 0.72;
		SPECULAR = 0.35;
	} else if (finish == 4 && cut > 0.02) {
		// INSIDE, on a face the containing form cut: the field itself. g is how deep under the skin the point
		// lies, and every ring is one level of that depth - two sets of rings deep in, one set near the skin.
		vec3 flesh = mix(colour_b, colour_a, smoothstep(0.0, 1.0, weight));
		flesh = mix(flesh, join_colour, band * join_amount);
		float level = cut * ring_count;
		float width = max(fwidth(level), 0.0001);
		float ring = 1.0 - smoothstep(0.8, 1.8, abs(fract(level - 0.5) - 0.5) / width);
		ALBEDO = mix(mix(flesh, vec3(0.03, 0.03, 0.04), 0.35 + 0.4 * cut), line_colour, ring * 0.85);
		ROUGHNESS = 0.55;
		SPECULAR = 0.3;
		EMISSION = flesh * 0.10 + line_colour * ring * 0.12;
	} else if (finish == 5 && cut > 0.5) {
		// WITHIN, the wall seen from the room: the form a little under its own skin. It lights itself, since
		// no lamp reaches into a body; the lines are the levels of the mixing weight, as on the skin outside,
		// so they crowd in the doorway where the two bodies are one.
		vec3 flesh = mix(colour_b, colour_a, smoothstep(0.0, 1.0, weight));
		flesh = mix(flesh, join_colour, band * join_amount);
		float level = weight * line_count;
		float width = max(fwidth(level), 0.0001);
		float line = 1.0 - smoothstep(0.7, 1.5, abs(fract(level - 0.5) - 0.5) / width);
		line *= step(0.015, weight) * step(weight, 0.985);
		// its own light falls off where the wall turns away from the eye and towards the top of the room, so a
		// dome reads as a dome from inside it
		float facing = clamp(dot(n, v), 0.0, 1.0);
		float shade = mix(0.5, 1.0, facing) * mix(1.0, 0.62, smoothstep(0.24 * within_top, within_top, height));
		ALBEDO = mix(flesh * ao, line_colour, line * 0.75);
		ROUGHNESS = 0.55;
		SPECULAR = 0.35;
		EMISSION = flesh * within_glow * ao * shade + line_colour * line * 0.15;
	} else {
		float mixed = smoothstep(0.0, 1.0, weight);
		vec3 base = mix(colour_b, colour_a, mixed);
		base = mix(base, join_colour, band * join_amount);
		float edge = pow(1.0 - clamp(dot(n, v), 0.0, 1.0), 2.2);
		vec3 film = 0.5 + 0.5 * cos(6.28318 * (vec3(0.0, 0.33, 0.67) + film_shift + edge * film_turns + band * 0.35));
		vec3 colour = mix(base, film, edge * film_amount) * ao;
		// the levels of the mixing weight, one screen pixel wide wherever the weight changes
		float level = weight * line_count;
		float width = max(fwidth(level), 0.0001);
		float line = 1.0 - smoothstep(0.7, 1.5, abs(fract(level - 0.5) - 0.5) / width);
		line *= step(0.015, weight) * step(weight, 0.985);
		ALBEDO = mix(colour, line_colour, line * line_amount);
		ROUGHNESS = mix(0.20, 0.34, band);
		METALLIC = 0.12;
		SPECULAR = 0.65;
		RIM = 0.55;
		RIM_TINT = 0.35;
		EMISSION = join_colour * band * glow * 0.6 + film * edge * 0.12;
	}
}
