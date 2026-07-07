## One-off sweep capture for the QFEP-balance DNA gallery.
##
## The pedagogical claim — read out of doc/ENTRY.md, the project's seven
## timeline phases, and the per-sequence qfep_term / qfep_connection fields
## in commons/maps/sequences/*.json — is that the project is organized
## around a single formula:
##
##   QFE = F − λ·E(S) + φ·ΔE(S,t)
##
## Where:
##   F      = Free energy. Order. Prediction. The grid before noise.
##   E(S)   = Entropy of the state. Disorder. Possibility space.
##   λ      = Entropy drive (0 → 1). The knob between crystallization and
##            dissolution. Life sits at λ ≈ 0.3–0.5.
##   φ·ΔE   = Rate sensitivity. The queer signature. How the system
##            responds to its own rate-of-change of entropy over time.
##   Q      = Queer + Self (post 2026-05-11). The recursive maker-modifier
##            wrapping the whole formula — every F/λ/φ choice is itself
##            a maker-choice in a prior cognitive landscape.
##
## The project's curriculum is not "F vs E vs λ vs φ" as four cells.
## It is SEVEN PHASES along a spine that walks the formula:
##
##   F_order       — Order before entropy. Primitives, transformation,
##                   color, change, arrays, isosurfaces, booleans.
##                   QFE ≈ F (entropy term suppressed).
##   oscillation   — Order and entropy alternate. Sine, forces.
##                   QFE has both F and E active; rate term emerging.
##   E_entropy     — Entropy as creative force. Randomness, noise.
##                   QFE ≈ F − λ·E(S) with λ → 1.
##   lambda_edge   — The edge of chaos. CA, fractals, L-systems, procgen,
##                   swarm. QFE balanced at λ ≈ 0.4. Where life happens.
##   integration   — φ·ΔE active. Softbodies (settling), ML (descent).
##                   The whole formula visible.
##   relation      — The substrate underneath. Graphs. The project's
##                   retroactive recognition: every prior phase was
##                   already graph-shaped.
##   synthesis     — Full QFE. Foundations crisis, QFEP lab, post-crisis.
##                   The formula as ground, not as goal.
##
## We render ONE cell per phase. Each cell is a "balance plate" — a square
## frame containing:
##   - A four-axis radar (F / E / λ / φ) showing this phase's signature
##     QFE knob configuration
##   - The phase's canonical timeline color as accent (matches the colors
##     used in ada_encyclopedia/src/app/timeline/page.tsx PHASE_COLORS)
##   - A small QFEP formula readout at the bottom of the frame
##
## Why phases (7) rather than QFEP letters (4): the brief's "what is true to
## the project" test. The four letters are real but they are PARAMETERS, not
## phases. The seven phases are what the spine actually walks through — they
## are the project's own vocabulary, used in the timeline ribbon UI, the
## sequence JSON `layer:` field, and curriculum_spine.json's `phase:` field.
## A QFEP gallery built on phases inherits the project's actual frame.
##
## Run:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/capture_qfep_balance_gallery.gd \
##     -- --out=user://qfep_balance_gallery
##
## Output: <out>/{qfep_F_order, qfep_oscillation, ..., qfep_synthesis}.png
##         + qfep_<phase>.json sidecar + manifest.json
extends SceneTree

const CAPTURE_SIZE: Vector2i = Vector2i(1024, 1024)
const BG_COLOR: Color = Color(0.06, 0.07, 0.10)

# ── The seven phases, in spine order ─────────────────────────────────
# Each entry: phase_id, display_name, color (hex from timeline page.tsx),
# F / E / λ / φ knob values (0..1), formula readout, example artifact,
# example sequence, notes.
#
# Knob values are derived from the per-sequence qfep_term fields:
#   F_order      — F dominant; E ≈ 0.05; λ ≈ 0.05; φ ≈ 0.0
#   oscillation  — F and E both ~0.6; λ ≈ 0.4; φ awakening at 0.3
#   E_entropy    — E dominant; F retains ~0.35; λ near 1; φ low
#   lambda_edge  — Edge of chaos: F ≈ E ≈ 0.55; λ ≈ 0.4; φ ≈ 0.3
#   integration  — φ·ΔE comes alive: F ≈ 0.55, E ≈ 0.6, λ ≈ 0.5, φ ≈ 0.85
#   relation     — Graph substrate: F ≈ 0.6, E ≈ 0.4, λ ≈ 0.4, φ ≈ 0.55
#                  with a relational hinge (different rendering: link arcs)
#   synthesis    — All four high: F ≈ 0.7, E ≈ 0.65, λ ≈ 0.5, φ ≈ 0.7
const PHASES: Array = [
	{
		"id": "F_order",
		"display": "F — Order",
		"color": Color(0.227, 0.482, 1.0),  # #3A7BFF
		"F": 0.95, "E": 0.05, "lambda": 0.05, "phi": 0.0,
		"dominant_letter": "F",
		"formula": "QFE ≈ F",
		"caption": "Pure F. Entropy term suppressed. The grid before the noise.",
		"example_artifact": "qfep_formula_3d (intro placement)",
		"example_sequence": "primitives, transformation, color, change, arrays, isosurfaces, booleans",
	},
	{
		"id": "oscillation",
		"display": "F ↔ E — Oscillation",
		"color": Color(0.490, 1.0, 0.659),  # #7DFFA8
		"F": 0.65, "E": 0.55, "lambda": 0.4, "phi": 0.3,
		"dominant_letter": "ω",
		"formula": "QFE = F − 0.4·E(S) + 0.3·ΔE",
		"caption": "Order and entropy alternate. Sine is the rule's most ordered output.",
		"example_artifact": "force_vector_field, sine_wave_lab",
		"example_sequence": "wavefunctions, forces",
	},
	{
		"id": "E_entropy",
		"display": "λE(S) — Entropy",
		"color": Color(0.957, 0.635, 0.380),  # #F4A261
		"F": 0.35, "E": 0.92, "lambda": 0.95, "phi": 0.15,
		"dominant_letter": "E",
		"formula": "QFE = F − 0.95·E(S)",
		"caption": "Entropy as creative force. The F-model meets irreducible uncertainty.",
		"example_artifact": "particle_chaos, random_cubes",
		"example_sequence": "randomness, noise",
	},
	{
		"id": "lambda_edge",
		"display": "λ ≈ 0.4 — Edge of Chaos",
		"color": Color(0.902, 0.224, 0.275),  # #E63946
		"F": 0.55, "E": 0.58, "lambda": 0.4, "phi": 0.35,
		"dominant_letter": "λ",
		"formula": "QFE = F − 0.4·E(S) + 0.35·ΔE",
		"caption": "Life lives here. Five colors of the same edge: CA, fractals, L-systems, procgen, swarm.",
		"example_artifact": "lambda_slider (default 0.4), bifurcation_walkway",
		"example_sequence": "cellularautomata, fractals, lsystems, procgen, swarmintelligence",
	},
	{
		"id": "integration",
		"display": "φΔE(S,t) — Integration",
		"color": Color(0.608, 0.365, 0.898),  # #9B5DE5
		"F": 0.55, "E": 0.62, "lambda": 0.55, "phi": 0.85,
		"dominant_letter": "φ",
		"formula": "QFE = F − 0.55·E(S) + 0.85·ΔE",
		"caption": "Rate sensitivity comes alive. Soft bodies and ML descend energy landscapes.",
		"example_artifact": "phi_slider, jelly_cube, gradient_descent_demo",
		"example_sequence": "softbodies, machinelearning",
	},
	{
		"id": "relation",
		"display": "(•—•) — Relation",
		"color": Color(0.984, 0.890, 0.541),  # #FBE38A
		"F": 0.6, "E": 0.4, "lambda": 0.4, "phi": 0.55,
		"dominant_letter": "G",
		"formula": "QFE on a graph G = (V, E)",
		"caption": "The substrate underneath. Every cell, force, agent, neuron was always a node.",
		"example_artifact": "graph_spanning_tree, citation_graph_node",
		"example_sequence": "graphtheory",
	},
	{
		"id": "synthesis",
		"display": "QFE — Synthesis",
		"color": Color(1.0, 1.0, 1.0),  # #FFFFFF
		"F": 0.7, "E": 0.65, "lambda": 0.5, "phi": 0.7,
		"dominant_letter": "Q",
		"formula": "QFE = F − λE(S) + φΔE(S,t)",
		"caption": "The whole formula, with Q wrapping the maker. The edge is the ground.",
		"example_artifact": "qfep_formula_3d, qfep_term_compass, edge_as_ground_capstone",
		"example_sequence": "foundationscrisis, qfeplaboratory, postfoundationscrisis",
	},
]

const KNOB_LABELS: Array = ["F", "E", "λ", "φ"]
const KNOB_KEYS: Array = ["F", "E", "lambda", "phi"]

var _output_dir: String = "user://qfep_balance_gallery"
var _entries: Array = []
var _viewport: SubViewport
var _scene_holder: Node3D
var _camera: Camera3D


func _initialize() -> void:
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--out="):
			_output_dir = arg.split("=")[1]
	_run.call_deferred()


func _run() -> void:
	# ── SubViewport — explicit 1024×1024 square with MSAA 8x ────────
	_viewport = SubViewport.new()
	_viewport.size = CAPTURE_SIZE
	_viewport.transparent_bg = false
	_viewport.own_world_3d = true
	var iso_world := World3D.new()

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.86, 0.92)
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.tonemap_white = 1.2
	iso_world.environment = env

	_viewport.world_3d = iso_world
	_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = Viewport.MSAA_8X
	_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	_viewport.use_taa = false
	_viewport.use_debanding = true
	get_root().add_child(_viewport)

	# Soft directional light (mostly cosmetic — content is unshaded)
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-45, 0, 0)
	key_light.light_energy = 0.8
	key_light.shadow_enabled = false
	_viewport.add_child(key_light)

	# Orthographic camera looking down +Z at the XY plane
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = 3.6
	_camera.near = 0.01
	_camera.far = 50.0
	_camera.current = true
	_camera.position = Vector3(0, 0, 5)
	_viewport.add_child(_camera)
	_camera.look_at(Vector3.ZERO, Vector3.UP)

	_scene_holder = Node3D.new()
	_viewport.add_child(_scene_holder)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))

	# ── Sweep — one cell per phase ──────────────────────────────────
	for phase in PHASES:
		_build_balance_scene(phase)
		await create_timer(0.05).timeout
		var id := "qfep_%s" % phase.id
		var meta := {
			"id": id,
			"phase": phase.id,
			"display": phase.display,
			"qfep_term": phase.dominant_letter,
			"dominant_phase": phase.id,
			"formula": phase.formula,
			"caption": phase.caption,
			"example_artifact": phase.example_artifact,
			"example_sequence": phase.example_sequence,
			"knobs": {
				"F": phase.F,
				"E": phase.E,
				"lambda": phase.lambda,
				"phi": phase.phi,
			},
			"color_hex": _color_to_hex(phase.color),
			"notes": phase.caption,
		}
		await _capture_and_record(id, meta)
		_clear_holder()
		await create_timer(0.02).timeout

	# ── Manifest ────────────────────────────────────────────────────
	var manifest := {
		"version": 1,
		"description": "QFEP balance plates — one cell per timeline phase in the project's spine. The QFEP formula QFE = F − λ·E(S) + φ·ΔE(S,t) made into a navigable substrate. Each cell shows a 4-axis radar of the QFEP knobs (F, E, λ, φ) configured for that phase, tinted with the phase's canonical timeline color (matching ada_encyclopedia/src/app/timeline/page.tsx PHASE_COLORS), with a formula readout. The seven phases — F_order, oscillation, E_entropy, lambda_edge, integration, relation, synthesis — are the project's own vocabulary, used in the timeline ribbon, sequence JSON layer fields, and curriculum_spine.json. The frame that organizes the spine becomes a navigable cell-grid in its own right.",
		"capture_size": [CAPTURE_SIZE.x, CAPTURE_SIZE.y],
		"camera": {"projection": "orthogonal", "size": 3.6},
		"formula": "QFE = F − λ·E(S) + φ·ΔE(S,t)",
		"knob_axes": KNOB_LABELS,
		"entries": _entries,
	}
	var f := FileAccess.open("%s/manifest.json" % _output_dir, FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "\t"))
	f.close()
	print("DONE — %d entries saved to %s" % [_entries.size(), _output_dir])
	quit(0)


# ── Scene builder ───────────────────────────────────────────────────
#
# Builds a "balance plate" composed of:
#   1. A plate background (square with the phase's tinted edge)
#   2. A four-axis radar (F top, E right, λ bottom, φ left)
#   3. Radial guides at 0.25 / 0.5 / 0.75 / 1.0
#   4. Knob dots at each axis tick = phase's knob value, connected by a
#      filled polygon in the phase's color
#   5. Axis labels (F / E / λ / φ) at the axis tips
#   6. A center hub circle with the phase's dominant letter colored
#   7. Phase title at the top, formula at the bottom
func _build_balance_scene(phase: Dictionary) -> void:
	# Layer Z values (camera looks down +Z, so larger Z is closer)
	var Z_BG: float = -0.5
	var Z_PLATE: float = -0.2
	var Z_GRID: float = -0.05
	var Z_RADAR: float = 0.05
	var Z_LABEL: float = 0.20

	# ── Plate / frame ───────────────────────────────────────────────
	# A tinted square plate with a thin outer border in the phase color.
	# The phase color is muted to ~30% saturation for the plate so the
	# foreground radar reads on top.
	var plate_color: Color = phase.color
	plate_color.a = 0.10  # very translucent tint over BG
	var plate := _make_filled_rect(
		Vector2(-1.6, -1.6), Vector2(1.6, 1.6), plate_color, Z_PLATE
	)
	_scene_holder.add_child(plate)

	# Outer border — thin frame in the phase color
	var border_color: Color = phase.color
	var border := _make_lined_rect(
		Vector2(-1.6, -1.6), Vector2(1.6, 1.6), border_color, Z_PLATE + 0.01, 0.012
	)
	_scene_holder.add_child(border)

	# ── Radar grid — concentric squares (rotated 45° → diamonds) ────
	# A radar with 4 axes is most legibly drawn as a series of nested
	# DIAMONDS (square rotated 45°), with each diamond at a fixed radius.
	# We draw rings at 0.25, 0.5, 0.75, 1.0 of the radar's max extent.
	var radar_max: float = 1.05  # max half-extent of the radar axes
	for r_frac in [0.25, 0.5, 0.75, 1.0]:
		var r: float = radar_max * float(r_frac)
		var dim_color := Color(0.32, 0.34, 0.42, 0.55)
		if r_frac == 1.0:
			dim_color = Color(0.46, 0.50, 0.60, 0.75)
		var ring := _make_diamond_outline(r, dim_color, Z_GRID, 0.006)
		_scene_holder.add_child(ring)

	# ── Radar axes — four spokes ────────────────────────────────────
	# F top (+Y), E right (+X), λ bottom (−Y), φ left (−X)
	var axis_color := Color(0.42, 0.46, 0.56, 0.70)
	_scene_holder.add_child(_make_line(
		Vector2(0, 0), Vector2(0, radar_max), axis_color, Z_GRID + 0.005, 0.006
	))
	_scene_holder.add_child(_make_line(
		Vector2(0, 0), Vector2(radar_max, 0), axis_color, Z_GRID + 0.005, 0.006
	))
	_scene_holder.add_child(_make_line(
		Vector2(0, 0), Vector2(0, -radar_max), axis_color, Z_GRID + 0.005, 0.006
	))
	_scene_holder.add_child(_make_line(
		Vector2(0, 0), Vector2(-radar_max, 0), axis_color, Z_GRID + 0.005, 0.006
	))

	# ── Radar polygon — knob values connected as a filled shape ─────
	var knob_F: float = float(phase.F)
	var knob_E: float = float(phase.E)
	var knob_L: float = float(phase.lambda)
	var knob_P: float = float(phase.phi)
	# Vertices in (axis_label, signed_xy) order
	var top := Vector2(0.0, radar_max * knob_F)         # F
	var right := Vector2(radar_max * knob_E, 0.0)        # E
	var bottom := Vector2(0.0, -radar_max * knob_L)      # λ
	var left := Vector2(-radar_max * knob_P, 0.0)        # φ

	# Filled polygon with phase color at ~50% opacity
	var phase_color: Color = phase.color
	var poly_fill: Color = phase_color
	poly_fill.a = 0.45
	# Boost dim phases so they read against the plate tint
	if phase.id in ["F_order", "oscillation"]:
		poly_fill.a = 0.55
	_scene_holder.add_child(_make_filled_quad(
		top, right, bottom, left, poly_fill, Z_RADAR
	))

	# Polygon outline — brighter, fully opaque phase color
	var poly_outline: Color = phase_color
	poly_outline.a = 1.0
	# For pure white (synthesis), drop slightly so the polyline reads
	if phase.id == "synthesis":
		poly_outline = Color(0.95, 0.95, 0.95, 1.0)
	_scene_holder.add_child(_make_quad_outline(
		top, right, bottom, left, poly_outline, Z_RADAR + 0.01, 0.014
	))

	# Knob dots at each vertex
	for v in [top, right, bottom, left]:
		_scene_holder.add_child(_make_filled_circle(
			v, 0.045, poly_outline, Z_RADAR + 0.02, 12
		))

	# ── Center hub — small circle with the dominant letter ──────────
	# A solid hub at the radar's center, then text on top of it.
	var hub_color := Color(0.10, 0.12, 0.16, 1.0)
	_scene_holder.add_child(_make_filled_circle(
		Vector2.ZERO, 0.12, hub_color, Z_RADAR + 0.03, 24
	))
	_scene_holder.add_child(_make_filled_circle(
		Vector2.ZERO, 0.12, poly_outline * Color(1.0, 1.0, 1.0, 0.0) + Color(0,0,0,0),
		Z_RADAR + 0.031, 24
	))  # subtle (no-op visual to keep z-stack tidy)
	# Hub ring
	_scene_holder.add_child(_make_circle_outline(
		Vector2.ZERO, 0.12, poly_outline, Z_RADAR + 0.04, 24, 0.008
	))

	# Dominant letter at center
	_scene_holder.add_child(_make_text_label(
		Vector2(0, 0), str(phase.dominant_letter), poly_outline, Z_LABEL, 60
	))

	# ── Axis labels — F top, E right, λ bottom, φ left ──────────────
	var label_color := Color(0.78, 0.80, 0.88, 1.0)
	_scene_holder.add_child(_make_text_label(
		Vector2(0, radar_max + 0.18), "F", label_color, Z_LABEL, 32
	))
	_scene_holder.add_child(_make_text_label(
		Vector2(radar_max + 0.18, 0), "E", label_color, Z_LABEL, 32
	))
	_scene_holder.add_child(_make_text_label(
		Vector2(0, -radar_max - 0.18), "λ", label_color, Z_LABEL, 32
	))
	_scene_holder.add_child(_make_text_label(
		Vector2(-radar_max - 0.18, 0), "φ", label_color, Z_LABEL, 32
	))

	# Knob values next to each axis tip — small numeric readouts
	var val_color := Color(0.60, 0.64, 0.72, 1.0)
	_scene_holder.add_child(_make_text_label(
		top + Vector2(0.16, 0.10), "%.2f" % knob_F, val_color, Z_LABEL, 18
	))
	_scene_holder.add_child(_make_text_label(
		right + Vector2(0.16, 0.10), "%.2f" % knob_E, val_color, Z_LABEL, 18
	))
	_scene_holder.add_child(_make_text_label(
		bottom + Vector2(0.16, -0.10), "%.2f" % knob_L, val_color, Z_LABEL, 18
	))
	_scene_holder.add_child(_make_text_label(
		left + Vector2(-0.16, 0.10), "%.2f" % knob_P, val_color, Z_LABEL, 18
	))

	# ── Title at top of plate ───────────────────────────────────────
	var title_color: Color = phase.color
	_scene_holder.add_child(_make_text_label(
		Vector2(0, 1.45), str(phase.display), title_color, Z_LABEL, 26
	))

	# ── Formula at bottom of plate ──────────────────────────────────
	_scene_holder.add_child(_make_text_label(
		Vector2(0, -1.45), str(phase.formula), Color(0.85, 0.87, 0.92, 1.0), Z_LABEL, 18
	))


# ── Primitive builders ──────────────────────────────────────────────

# Hex string from a Color (RGB only, ignores alpha)
func _color_to_hex(c_in) -> String:
	var c: Color = c_in
	return "#%02X%02X%02X" % [
		int(c.r * 255.0),
		int(c.g * 255.0),
		int(c.b * 255.0),
	]


# Unshaded material in a single color (alpha-aware)
func _make_unshaded_material(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = false
	return m


# Filled rect in the XY plane (Z constant)
func _make_filled_rect(a: Vector2, b: Vector2, color: Color, z: float) -> MeshInstance3D:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _make_unshaded_material(color))
	im.surface_add_vertex(Vector3(a.x, a.y, z))
	im.surface_add_vertex(Vector3(b.x, a.y, z))
	im.surface_add_vertex(Vector3(b.x, b.y, z))
	im.surface_add_vertex(Vector3(a.x, a.y, z))
	im.surface_add_vertex(Vector3(b.x, b.y, z))
	im.surface_add_vertex(Vector3(a.x, b.y, z))
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	return mi


# Outline rect (4 thick line segments built from triangles)
func _make_lined_rect(a: Vector2, b: Vector2, color: Color, z: float, thickness: float) -> Node3D:
	var holder := Node3D.new()
	holder.add_child(_make_line(Vector2(a.x, a.y), Vector2(b.x, a.y), color, z, thickness))
	holder.add_child(_make_line(Vector2(b.x, a.y), Vector2(b.x, b.y), color, z, thickness))
	holder.add_child(_make_line(Vector2(b.x, b.y), Vector2(a.x, b.y), color, z, thickness))
	holder.add_child(_make_line(Vector2(a.x, b.y), Vector2(a.x, a.y), color, z, thickness))
	return holder


# Thick line segment as two triangles (so we get visible width — line
# primitive doesn't honour thickness in modern Godot rendering paths)
func _make_line(a: Vector2, b: Vector2, color: Color, z: float, thickness: float) -> MeshInstance3D:
	var d := (b - a).normalized()
	# Perpendicular in 2D
	var p := Vector2(-d.y, d.x) * (thickness * 0.5)
	var v1 := a + p
	var v2 := a - p
	var v3 := b - p
	var v4 := b + p
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _make_unshaded_material(color))
	im.surface_add_vertex(Vector3(v1.x, v1.y, z))
	im.surface_add_vertex(Vector3(v2.x, v2.y, z))
	im.surface_add_vertex(Vector3(v3.x, v3.y, z))
	im.surface_add_vertex(Vector3(v1.x, v1.y, z))
	im.surface_add_vertex(Vector3(v3.x, v3.y, z))
	im.surface_add_vertex(Vector3(v4.x, v4.y, z))
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	return mi


# Diamond outline (4 lines forming a 45°-rotated square at half-extent r)
func _make_diamond_outline(r: float, color: Color, z: float, thickness: float) -> Node3D:
	var holder := Node3D.new()
	var top := Vector2(0, r)
	var right := Vector2(r, 0)
	var bottom := Vector2(0, -r)
	var left := Vector2(-r, 0)
	holder.add_child(_make_line(top, right, color, z, thickness))
	holder.add_child(_make_line(right, bottom, color, z, thickness))
	holder.add_child(_make_line(bottom, left, color, z, thickness))
	holder.add_child(_make_line(left, top, color, z, thickness))
	return holder


# Filled quad from 4 vertices (top → right → bottom → left → top)
func _make_filled_quad(top: Vector2, right: Vector2, bottom: Vector2, left: Vector2, color: Color, z: float) -> MeshInstance3D:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _make_unshaded_material(color))
	# Two triangles from the center
	im.surface_add_vertex(Vector3(top.x, top.y, z))
	im.surface_add_vertex(Vector3(right.x, right.y, z))
	im.surface_add_vertex(Vector3(bottom.x, bottom.y, z))
	im.surface_add_vertex(Vector3(top.x, top.y, z))
	im.surface_add_vertex(Vector3(bottom.x, bottom.y, z))
	im.surface_add_vertex(Vector3(left.x, left.y, z))
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	return mi


# Quad outline (4 lines)
func _make_quad_outline(top: Vector2, right: Vector2, bottom: Vector2, left: Vector2, color: Color, z: float, thickness: float) -> Node3D:
	var holder := Node3D.new()
	holder.add_child(_make_line(top, right, color, z, thickness))
	holder.add_child(_make_line(right, bottom, color, z, thickness))
	holder.add_child(_make_line(bottom, left, color, z, thickness))
	holder.add_child(_make_line(left, top, color, z, thickness))
	return holder


# Filled circle as N-sided polygon
func _make_filled_circle(center: Vector2, r: float, color: Color, z: float, sides: int) -> MeshInstance3D:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _make_unshaded_material(color))
	for i in range(sides):
		var a0: float = float(i) * TAU / float(sides)
		var a1: float = float(i + 1) * TAU / float(sides)
		var p0 := center + Vector2(cos(a0), sin(a0)) * r
		var p1 := center + Vector2(cos(a1), sin(a1)) * r
		im.surface_add_vertex(Vector3(center.x, center.y, z))
		im.surface_add_vertex(Vector3(p0.x, p0.y, z))
		im.surface_add_vertex(Vector3(p1.x, p1.y, z))
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	return mi


# Circle outline as N short line segments
func _make_circle_outline(center: Vector2, r: float, color: Color, z: float, sides: int, thickness: float) -> Node3D:
	var holder := Node3D.new()
	for i in range(sides):
		var a0: float = float(i) * TAU / float(sides)
		var a1: float = float(i + 1) * TAU / float(sides)
		var p0 := center + Vector2(cos(a0), sin(a0)) * r
		var p1 := center + Vector2(cos(a1), sin(a1)) * r
		holder.add_child(_make_line(p0, p1, color, z, thickness))
	return holder


# Text label via Label3D (Godot's billboarded 3D text). Camera is orthographic
# looking down +Z, so we render the labels facing -Z (out of the screen).
func _make_text_label(center: Vector2, text: String, color: Color, z: float, pixel_size: int) -> Label3D:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.modulate = color
	lbl.outline_modulate = Color(0, 0, 0, 0.85)
	lbl.outline_size = 6
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.no_depth_test = true
	lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	# Label3D's "pixel_size" is meters per pixel in the font. For an
	# orthographic camera with size 3.6 and viewport 1024×1024, 1 world unit
	# ≈ 1024/3.6 ≈ 284 pixels. So pixel_size = (desired_pt_in_world_meters)/
	# (font_em_height). Empirically: pixel_size ≈ 0.0035 gives ~36pt text.
	lbl.pixel_size = 0.0035 * (float(pixel_size) / 36.0)
	lbl.position = Vector3(center.x, center.y, z)
	# Face the camera (camera looks down +Z, so face is normal -Z)
	lbl.rotation_degrees = Vector3(0, 0, 0)
	return lbl


# ── Capture/record ──────────────────────────────────────────────────

func _clear_holder() -> void:
	for c in _scene_holder.get_children():
		c.queue_free()


func _capture_and_record(id: String, meta: Dictionary) -> void:
	# Yield a few frames so the viewport definitely renders the new content
	# before we sample the texture.
	await process_frame
	await process_frame
	await process_frame
	var image := _viewport.get_texture().get_image()
	var img_rel := "%s.png" % id
	var img_abs := "%s/%s" % [_output_dir, img_rel]
	image.save_png(ProjectSettings.globalize_path(img_abs))

	var config := meta.duplicate(true)
	var cfg_rel := "%s.json" % id
	var cf := FileAccess.open("%s/%s" % [_output_dir, cfg_rel], FileAccess.WRITE)
	cf.store_string(JSON.stringify(config, "\t"))
	cf.close()

	_entries.append({
		"id": id,
		"notes": meta.get("caption", ""),
		"phase": meta.get("phase", ""),
		"qfep_term": meta.get("qfep_term", ""),
		"dominant_phase": meta.get("dominant_phase", ""),
		"formula": meta.get("formula", ""),
		"example_artifact": meta.get("example_artifact", ""),
		"example_sequence": meta.get("example_sequence", ""),
		"knobs": meta.get("knobs", {}),
		"color_hex": meta.get("color_hex", ""),
		"image": "/qfep-balance-gallery/%s" % img_rel,
		"config": "/qfep-balance-gallery/%s" % cfg_rel,
	})
	print("  saved: %s" % id)
