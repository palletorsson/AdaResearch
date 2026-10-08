shader_type spatial;
render_mode cull_disabled;

// Planar mapping follows the inherited two-triangle face, including its back.
// No historical insignia: five original studies in repetition and direction.
uniform vec2 face_size = vec2(0.66, 1.8);
uniform vec4 ground_color : source_color = vec4(0.07, 0.13, 0.25, 1.0);
uniform vec4 line_color : source_color = vec4(0.93, 0.88, 0.71, 1.0);
uniform vec4 accent_color : source_color = vec4(0.8, 0.3, 0.15, 1.0);
uniform int motif = 0;
uniform float reveal : hint_range(0.0, 1.0) = 0.0;
uniform float colour_amount : hint_range(0.0, 1.0) = 1.0;
uniform float pattern_amount : hint_range(0.0, 1.0) = 1.0;
varying vec2 panel_uv;

void vertex() {
	panel_uv = VERTEX.xy / face_size + vec2(0.5);
}

float stroke(float distance_to_line, float width) {
	float aa = max(fwidth(distance_to_line), 0.001);
	return 1.0 - smoothstep(width-aa, width+aa, distance_to_line);
}

void fragment() {
	vec2 uv = panel_uv;
	vec2 p = uv * vec2(4.0, 10.0);
	float marks = 0.0;
	float accent = 0.0;
	if (motif == 0) {
		// Overlapping wave arcs, built from repeated distances to a point.
		for (int row = 0; row < 2; row++) {
			vec2 q = p + vec2(float(row)*0.5, float(row));
			vec2 cell = vec2(fract(q.x)-0.5, mod(q.y, 2.0));
			float r = length(cell);
			marks = max(marks, max(stroke(abs(r-0.55),0.025), stroke(abs(r-0.8),0.025)));
		}
		accent = stroke(abs(fract(p.y/2.0)-0.92),0.025);
	} else if (motif == 1) {
		// A triangle unfolds into repeated nested diamonds.
		vec2 q = abs(fract(p*0.65)-0.5);
		float d = q.x+q.y;
		marks = max(stroke(abs(d-0.48),0.032),stroke(abs(d-0.27),0.026));
		accent = 1.0-smoothstep(0.075,0.095,d);
	} else if (motif == 2) {
		// A grid interrupted by circles; each cell keeps its address.
		vec2 q = fract(p*0.75)-0.5;
		marks = max(stroke(abs(q.x),0.027),stroke(abs(q.y),0.027));
		marks = max(marks,stroke(abs(length(q)-0.32),0.025));
		accent = stroke(abs(length(q)-0.13),0.042);
	} else if (motif == 3) {
		// Sloping lines turn into alternating chevrons.
		float zig = abs(fract(p.x*0.5)-0.5)*2.0;
		float band = fract((p.y-zig)*0.65);
		marks = 1.0-smoothstep(0.26-fwidth(band),0.26+fwidth(band),band);
		accent = stroke(abs(band-0.52),0.045);
	} else {
		// Branch-like diagonals meet a repeated central line.
		vec2 q = fract(p*vec2(0.5,0.45))-0.5;
		marks = max(stroke(abs(q.x),0.025),stroke(abs(abs(q.x)+q.y-0.24),0.035));
		accent = stroke(abs(abs(q.x)+q.y+0.15),0.022);
	}
	vec3 cloth = mix(ground_color.rgb,line_color.rgb,clamp(marks,0.0,1.0));
	cloth = mix(cloth,accent_color.rgb,clamp(accent,0.0,1.0));
	float edge = min(min(uv.x,1.0-uv.x),min(uv.y*2.727,(1.0-uv.y)*2.727));
	float border = max(stroke(abs(edge-0.025),0.009),stroke(abs(edge-0.065),0.006));
	cloth = mix(cloth,line_color.rgb,border);
	// Anti-aliased woven variation, restrained enough to remain a fabric surface.
	float thread = sin(uv.x*520.0)*sin(uv.y*1400.0);
	float detail = 1.0-smoothstep(0.1,0.5,max(fwidth(uv.x*83.0),fwidth(uv.y*223.0)));
	cloth *= 1.0+0.035*thread*detail;
	cloth = mix(ground_color.rgb,cloth,pattern_amount);
	cloth = mix(vec3(dot(cloth,vec3(0.2126,0.7152,0.0722))),cloth,colour_amount);
	ALBEDO = mix(vec3(0.60,0.235,0.13),cloth,reveal);
	ROUGHNESS = 0.92;
}
