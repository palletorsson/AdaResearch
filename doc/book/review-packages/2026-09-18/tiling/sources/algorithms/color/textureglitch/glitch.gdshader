shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix;

uniform int layer_index;
uniform int glitch_type; // 0=datamosh, 1=chromatic, 2=decay, 3=cascade, 4=pixel_sort, 5=bit_crush, 6=memory_leak, 7=quantum
uniform float time;
uniform vec4 layer_color : source_color;

// Hash function
float hash(vec2 p) {
	vec3 p3  = fract(vec3(p.xyx) * .1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
	vec2 uv = UV;
	vec4 col = vec4(1.0);
	float t = time;
	
	if (glitch_type == 0) { // Datamosh
		vec2 motion = vec2(
			sin(t * 3.0 + uv.x * 10.0) * 0.1,
			cos(t * 2.0 + uv.y * 8.0) * 0.1
		);
		vec2 shifted_uv = uv + motion * float(layer_index + 1) * 0.25;
		float pattern = sin(shifted_uv.x * 25.13) * cos(shifted_uv.y * 18.84); // PI*8, PI*6
		
		if (layer_index == 0) col = vec4(pattern * 0.5 + 0.5, 0.2, 0.2, 0.8);
		else if (layer_index == 1) col = vec4(0.2, pattern * 0.5 + 0.5, 0.2, 0.6);
		else if (layer_index == 2) col = vec4(0.2, 0.2, pattern * 0.5 + 0.5, 0.7);
		else col = vec4(pattern * 0.3 + 0.3, pattern * 0.3 + 0.3, 0.2, 0.5);
		
	} else if (glitch_type == 1) { // Chromatic
		float shift = 0.02 * (float(layer_index) - 1.5);
		// Logic simplified for single pass, real chromatic needs 3 samples
		float r_pat = sin((uv.x + shift) * 37.7 + t * 2.0);
		float g_pat = sin(uv.x * 37.7 + t * 2.0);
		float b_pat = sin((uv.x - shift) * 37.7 + t * 2.0);
		
		if (layer_index == 0) col = vec4(r_pat * 0.5 + 0.5, 0.0, 0.0, 0.8);
		else if (layer_index == 1) col = vec4(0.0, g_pat * 0.5 + 0.5, 0.0, 0.8);
		else if (layer_index == 2) col = vec4(0.0, 0.0, b_pat * 0.5 + 0.5, 0.8);
		else col = vec4(0.3, 0.3, 0.3, 0.4);
		
	} else if (glitch_type == 2) { // Decay
		float decay_seed = hash(uv * 100.0 + vec2(t * 10.0));
		float decay_amt = sin(t * 0.5) * 0.5 + 0.5;
		float intensity = decay_seed * decay_amt;
		float l_decay = 1.0 - mod(t * 0.1 * float(layer_index + 1), 1.0);
		
		col = vec4(
			intensity * l_decay,
			intensity * 0.5 * l_decay,
			intensity * 0.3 * l_decay,
			0.6 + intensity * 0.4
		);
		
	} else if (glitch_type == 3) { // Cascade
		float wave = t * 2.0 - float(layer_index) * 0.5;
		float pos = mod(wave, 1.0);
		float dist = abs(uv.y - pos);
		float intensity = exp(-dist * 10.0);
		float corruption = intensity * sin(uv.x * 50.2 + t * 4.0);
		
		col = vec4(
			intensity,
			0.2 + corruption * 0.4,
			0.2 + corruption * 0.4,
			intensity * 0.8
		);
		
	} else if (glitch_type == 4) { // Pixel Sort (Simulated)
		float sort_col = floor(uv.x * 16.0);
		float trigger = step(0.5, sin(t * 3.0 + sort_col));
		float brightness = uv.y;
		if (trigger > 0.5) brightness = smoothstep(0.0, 1.0, uv.y);
		
		float offset = float(layer_index) * 0.25;
		brightness = mod(brightness + offset, 1.0);
		col = vec4(brightness, brightness * 0.7, brightness * 0.4, 0.7);
		
	} else if (glitch_type == 5) { // Bit Crush
		float depth = 4.0 - float(layer_index);
		float levels = pow(2.0, depth);
		float pat = sin(uv.x * 25.1 + t*2.0) * cos(uv.y * 18.8); // 8PI, 6PI
		float crushed = floor(pat * levels) / levels;
		float c = crushed;
		col = vec4(c * 0.5 + 0.5, c * 0.3 + 0.3, c * 0.7 + 0.3, 0.6);
		
	} else if (glitch_type == 6) { // Memory Leak
		// Simplified leak points
		vec2 points[4];
		points[0] = vec2(0.2, 0.3); points[1] = vec2(0.7, 0.2);
		points[2] = vec2(0.4, 0.8); points[3] = vec2(0.8, 0.6);
		
		float total = 0.0;
		for(int i=0; i<4; i++) {
			float d = distance(uv, points[i]);
			float size = 0.1 + sin(t * 1.5 + float(i)) * 0.05;
			if (d < size) total += (size - d) / size;
		}
		total *= (1.0 + t * 0.1);
		col = vec4(total * 0.8, total * 0.4, total * 0.2, min(total, 1.0) * 0.7);
		
	} else { // Quantum
		float q_no = hash(uv * 64.0 + vec2(t * 10.0, float(layer_index) * 5.0));
		float uncertainty = sin(q_no * 12.56) * 0.5 + 0.5;
		float sa = sin(uv.x * 62.8 + t * 3.0) * 0.5 + 0.5;
		float sb = cos(uv.y * 50.2 + t * 2.5) * 0.5 + 0.5;
		float sup = (sa + sb) * 0.5;
		float collapse = step(0.8, uncertainty);
		float final = mix(sup, q_no * 0.5 + 0.5, collapse);
		col = vec4(final, final * 0.6, final * 0.8, 0.5 + uncertainty * 0.5);
	}
	
	// Apply blend color/alpha logic from layer settings
	// For "add" layers we might want to pre-multiply or just boost?
	// The shader uses mix. 
	// We'll trust the alpha out.
	
	ALBEDO = col.rgb * layer_color.rgb; // Tint
	ALPHA = col.a * layer_color.a;
	EMISSION = col.rgb * 0.5;
}
