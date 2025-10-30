shader_type spatial;
render_mode depth_draw_always, cull_back, diffuse_burley, specular_schlick_ggx;

// === Base Appearance ===
uniform vec4 modelColor      : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 wireframeColor  : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 emissionColor   : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float width          : hint_range(0.1, 15.0) = 2.0;
uniform float blur           : hint_range(0.1, 5.0)  = 1.0;
uniform float emission_strength : hint_range(0.0, 10.0) = 2.0;
uniform bool show_interior   = true;

// === Dirt / Decay Controls ===
uniform float dirt_scale     : hint_range(0.1, 10.0) = 1.5;
uniform float dirt_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float decay_scale    : hint_range(0.1, 10.0) = 2.0;
uniform float decay_intensity: hint_range(0.0, 1.0) = 0.5;
uniform bool animate_dirt    = false;
uniform float time           : hint_range(0.0, 1000.0) = 0.0;

// === Y-Level Grid ===
uniform float grid_height_spacing : hint_range(0.1, 5.0) = 0.5;   // spacing between grid lines
uniform float grid_line_thickness : hint_range(0.001, 0.2) = 0.02;
uniform vec4  grid_color : source_color = vec4(0.2, 0.2, 0.2, 1.0);
uniform float grid_intensity : hint_range(0.0, 2.0) = 1.0;

// === Internal ===
varying vec3 baryCoord;
varying vec3 v_world_pos;

// --- Simple 3D hash noise ---
float hash(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.1, 0.3, 0.7));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

// --- Value noise ---
float noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(
			mix(hash(i + vec3(0,0,0)), hash(i + vec3(1,0,0)), f.x),
			mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
		mix(
			mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x),
			mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y),
		f.z);
}

void vertex() {
	int vertexIndex = VERTEX_ID % 3;
	if (vertexIndex == 0) baryCoord = vec3(1.0, 0.0, 0.0);
	else if (vertexIndex == 1) baryCoord = vec3(0.0, 1.0, 0.0);
	else baryCoord = vec3(0.0, 0.0, 1.0);
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// --- Wireframe base ---
	vec3 dBaryCoordX = dFdx(baryCoord);
	vec3 dBaryCoordY = dFdy(baryCoord);
	vec3 dBaryCoord = sqrt(dBaryCoordX * dBaryCoordX + dBaryCoordY * dBaryCoordY);
	dBaryCoord = max(dBaryCoord, vec3(0.0001));
	vec3 edge_distance = baryCoord / (dBaryCoord * width);
	vec3 remap = smoothstep(vec3(0.0), vec3(blur), edge_distance);
	float closestEdge = min(min(remap.x, remap.y), remap.z);

	// --- Dirt & decay ---
	float t = animate_dirt ? time * 0.1 : 0.0;
	float dirt = noise(v_world_pos * dirt_scale + t);
	float decay = noise(v_world_pos * decay_scale + vec3(5.0, 10.0, 2.0));
	float dirt_mask  = pow(dirt, 3.0) * dirt_intensity;
	float decay_mask = smoothstep(0.4, 0.8, decay) * decay_intensity;

	// --- Y-level grid ---
	float y_level = abs(fract(v_world_pos.y / grid_height_spacing) - 0.5);
	float grid_line = smoothstep(grid_line_thickness, 0.0, y_level);
	vec3 grid_effect = mix(vec3(1.0), grid_color.rgb, grid_line * grid_intensity);

	// --- Combine ---
	vec3 base_col = mix(wireframeColor.rgb, modelColor.rgb, closestEdge);
	base_col *= (1.0 - dirt_mask);
	base_col = mix(base_col, vec3(0.2, 0.15, 0.1), decay_mask);
	base_col *= grid_effect; // apply the Y-based grid tint

	ALBEDO = base_col;
	EMISSION = emissionColor.rgb * (1.0 - closestEdge) * emission_strength;
}
