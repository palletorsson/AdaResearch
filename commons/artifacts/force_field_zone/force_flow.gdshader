shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_opaque;

// Chevron-flow force field. World-space, so ONE material drives all six faces: each
// fragment projects the force direction onto its own face and draws rows of chevrons
// streaming the way the force points. Faces the force passes through pulse faintly.

uniform vec3 force_dir = vec3(0.0, -1.0, 0.0);          // world-space force direction
uniform float force_mag = 9.8;                          // |F| — drives brightness
uniform vec4 flow_color : source_color = vec4(0.35, 0.85, 1.0, 1.0);
uniform float freq = 1.6;                               // chevrons per metre along the flow
uniform float flow_speed = 1.8;
uniform float density = 4.0;                            // chevron rows across the face
uniform float chevron = 0.55;                           // how pointed the arrows are

varying vec3 v_wpos;
varying vec3 v_wnrm;

void vertex() {
	v_wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(v_wnrm);
	vec3 fd = normalize(force_dir);
	vec3 proj = fd - n * dot(fd, n);                    // force projected onto this face
	float plen = length(proj);
	vec3 col = flow_color.rgb;
	ALBEDO = vec3(0.0);
	if (plen > 0.01) {
		vec3 along = proj / plen;                       // flow direction on the face
		vec3 across = normalize(cross(n, along));
		float a = dot(v_wpos, along);
		float b = dot(v_wpos, across);
		float t = TIME * flow_speed;
		float within = abs(fract(b * density) - 0.5) * 2.0;   // 0 mid-row, 1 at the edge
		float phase = a * freq - t + within * chevron;        // chevron points along the flow (∨)
		float s = fract(phase);
		float arrow = smoothstep(0.0, 0.10, s) * (1.0 - smoothstep(0.30, 0.62, s));
		float intensity = arrow * clamp(plen, 0.0, 1.0) * clamp(force_mag / 9.8, 0.25, 1.7);
		EMISSION = col * intensity * 2.2;
		ALPHA = clamp(0.05 + intensity * 0.85, 0.0, 0.8);
	} else {
		float pulse = 0.5 + 0.5 * sin(TIME * 2.2);      // force is normal to this face
		EMISSION = col * (0.08 + 0.08 * pulse);
		ALPHA = 0.12;
	}
}
