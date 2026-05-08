shader_type spatial;

// ParametricGrid — UV-space grid with controllable line counts.
//
// Unlike SimpleGrid (which highlights actual mesh triangle edges and
// loses information at high tessellation density) and basic_grid
// (which uses a fixed 100x UV multiplier), this shader draws exactly
// `lines_u` × `lines_v` lines in UV space. The result is independent
// of mesh tessellation: a sphere with 64 rings and one with 8 rings
// both show whatever line_count you ask for.
//
// Used by the primitive-DNA gallery so the gallery's visual encoding
// stays legible across the entire parameter sweep — the lines you
// see are the parameters the variant is teaching, not the mesh's
// happenstance triangulation.

render_mode blend_mix, depth_draw_opaque, cull_back, unshaded;

uniform vec3 fill_color   : source_color = vec3(0.62, 0.65, 0.74);
uniform vec3 line_color   : source_color = vec3(0.95, 0.40, 0.45);
uniform int  lines_u      : hint_range(1, 64) = 8;   // longitude / radial / "rings"
uniform int  lines_v      : hint_range(1, 64) = 8;   // latitude  / axial  / "ring_segments"
uniform float line_width  : hint_range(0.001, 0.2) = 0.02;
uniform float emission    : hint_range(0.0, 4.0)   = 1.2;
// When true, draw a fainter "every-line" grid at the mesh's actual
// triangulation density alongside the parametric grid. Off by default
// to keep the gallery clean.
uniform bool  show_mesh_edges = false;
uniform float mesh_edge_alpha : hint_range(0.0, 1.0) = 0.15;

void fragment() {
	// Parametric grid: project UV into [0, lines_u) × [0, lines_v) and
	// draw lines at every integer crossing. This is how a sphere with
	// 8 longitudes and 8 latitudes can be drawn on top of a mesh that
	// has 24 actual rings — the geometry is over-tessellated but the
	// grid you see is the one you specified.
	vec2 scaled  = UV * vec2(float(lines_u), float(lines_v));
	vec2 cell    = abs(fract(scaled) - 0.5);     // 0 at line, 0.5 at center
	vec2 dist    = vec2(0.5) - cell;             // 0.5 at line, 0 at center

	// Anti-aliasing scale: derivative of UV per fragment, scaled to lines.
	vec2 fwidth_uv = fwidth(scaled);
	float aa_u = max(fwidth_uv.x, 0.0001);
	float aa_v = max(fwidth_uv.y, 0.0001);

	float u_line = 1.0 - smoothstep(line_width - aa_u, line_width + aa_u, dist.x);
	float v_line = 1.0 - smoothstep(line_width - aa_v, line_width + aa_v, dist.y);
	float param_grid = max(u_line, v_line);

	// Optional secondary layer: actual mesh edges via UV derivative jumps.
	// At low tessellation this overlaps the parametric grid (visible);
	// at high tessellation it appears as a faint sheen.
	float mesh_edge_intensity = 0.0;
	if (show_mesh_edges) {
		vec2 mesh_dx = dFdx(UV);
		vec2 mesh_dy = dFdy(UV);
		float mesh_density = length(mesh_dx) + length(mesh_dy);
		mesh_edge_intensity = clamp(mesh_density * 80.0, 0.0, 1.0) * mesh_edge_alpha;
	}

	float line_intensity = max(param_grid, mesh_edge_intensity);

	vec3 color = mix(fill_color, line_color, line_intensity);

	ALBEDO   = color;
	EMISSION = line_color * line_intensity * emission;
	ALPHA    = 1.0;
}
