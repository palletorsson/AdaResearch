extends Node3D
class_name CodexGlyph

## @identity
# essence: a single DNA-driven CODEX WRITING-SYSTEM SPECIMEN rendered not as decorative letters
#   but as a GENUINE writing ALGORITHM run live. Where most "text" artifacts place glyph decals,
#   CodexGlyph COMPUTES its script: a combinatorial stroke-GRAMMAR, a bracketed L-SYSTEM, a
#   weighted GRAPH with a minimum spanning tree, or a noise-driven generative PEN-WALK decides
#   the marks, and the relief mesh is only their read-out. Luigi Serafini's Codex Seraphinianus
#   asemic writing — script that means nothing yet reads as language — is the muse; four founding
#   computational ideas (grammar, L-systems, graph theory, generative curves) are the engine.
#   Depending on its `mode` DNA it becomes one of FOUR teaching specimens whose page IS its
#   process: glyphgrid (a combinatorial stroke-GRAMMAR — 7 terminal stroke primitives + 4
#   attachment production rules generate a ruled GRID of distinct asemic glyphs in raised relief
#   on a parchment tablet, a deterministic subset rubricated in glowing gold), branchscript (a
#   REAL bracketed L-system — axiom + production rules expanded ~16 generations, a 3D turtle with
#   push/pop brackets and branch decay growing a single ornate branching letterform: dominant
#   stem + curling logarithmic-spiral flourishes + illuminated nib tips, rising from an inkwell),
#   glyphgraph (REAL graph theory — a glyph-node network laid out on a dome, k-NN weighted edges,
#   then PRIM'S minimum-spanning-tree computed and highlighted as glowing arcs over the dim web;
#   nodes are glyph-etched stone discs), and codexcolumn (generative cursive — a pen-walk driven
#   by a slow sine baseline + layered value-NOISE tremor + cursive LOOPS + ascender/descender
#   bumps + word-gap pen-lifts generates lines of flowing asemic script swept as raised ink
#   ribbons on a parchment stele, opened by an illuminated initial). It is identity confessed as
#   a WRITING PROCESS — the page is the computation, not its letters.
# desire: it wants the algorithm to stay LEGIBLE and GENUINE — the grammar's combinatorics (the
#   same stroke set reading differently under a different rule), the L-system's coiling spiral
#   flourishes off a commanding stem, the MST visibly threading the lightest path through every
#   glyph-node, and the cursive's organic tremor + cursive loops — must read as COMPUTED, never
#   hand-placed. It wants PARCHMENT / stone to glow soft with an emission floor so the substrate
#   never collapses to black against the dark capture, INK strokes/glyphs/edges to read matte
#   sepia, and ILLUMINATION (gold rubrication / the cyan MST highlight / the gilded initial) to
#   BURN near-unshaded. Above all it wants every generator BOUNDED — the L-system string and the
#   pen-walk both hard-capped so they always terminate, every value seeded so each launch is
#   identical.
# critical_parameter: mode + seed + the colour triad (color_a PARCHMENT/substrate/tablet/disc/
#   stele / color_b INK/stroke/glyph/edge / accent ILLUMINATION/rubrication/MST-highlight/margin
#   GLOW) + complexity. mode picks the writing-system lineage; seed varies the individual
#   deterministically (a local seeded RNG, no global randf/randi ever — it drives the per-cell
#   grammar choices, the L-system variant pick, the graph scatter + layout, every pen-walk
#   sample); complexity scales the glyph GRID SIZE, the L-system GENERATIONS, the graph NODE
#   COUNT, and the script LINE COUNT. Higher complexity = a denser page / a deeper expansion.
# triggers: _ready() reads DNA metadata overrides, seeds the RNG from `seed`, and branches on
#   `mode` to a _build_<mode>() helper; apply_grid_config rewrites config metas, clears children
#   (remove BEFORE free, guarded by `_built`), and rebuilds.
# emerges: a row of these reads as a CABINET OF WRITING SYSTEMS — four ways a mark can become a
#   rule. Switch one mode and the room's idea of "what makes writing" shifts from grid-of-glyphs
#   to grown-letter to network-of-glyphs to flowing-line; reseed and the script persists while
#   its individual varies. These are teaching specimens for the lsystems / graphtheory labs:
#   glyphgrid + branchscript for the grammar / L-systems room, glyphgraph for graphtheory,
#   codexcolumn for generative curves / noise.
# needs: a seeded RNG for deterministic individuals [present]; four build branches each carrying
#   its trial's genuine algorithm self-contained (combinatorial stroke-grammar, bracketed
#   L-system + 3D turtle, k-NN graph + Prim's MST, noise-driven pen-walk) [present]; parchment /
#   ink / glow materials driven by the colour triad [present]; strokes / glyphs / edges batched
#   into ArrayMeshes (with a Variant-coercing merge for non-indexed MorphoPrimitive surfaces) so
#   the AABB capture frames the specimen [present]; the morphology toolkit statics (MorphoPrimitive
#   / MorphoSweep) for surface generation, and the LSystem util for the grammar expansion [present].
# relationships: kin to codex_morph (same genome shape + conventions — identity header, grouped
#   @export, apply_grid_config + _parse_color + _built rebuild guard, self-clearing idempotent
#   _build(), seeded RNG, settle centring; codex_morph runs morphogenesis sims, CodexGlyph runs
#   writing-system algorithms); kin to codex_flora (the shared Codex genome shape; codex_flora
#   grows L-system PLANTS, branchscript grows an L-system LETTER); built on the nature_system
#   morphology engine it borrows from (MorphoPrimitive / MorphoSweep) and the LSystem grammar
#   util; cousin to any mode-switchboard of one genome.
# truth: the mark is a rule and the page is a graph — writing was always computation. Serafini
#   drew a script that cannot be read; grammar, L-systems, graph theory, and generative curves
#   grow scripts that did not exist until the rule ran. CodexGlyph holds four such processes in
#   one genome where the page is COMPUTED — a combinatorial alphabet, a grown letterform, a
#   spanning-tree of glyphs, a flowing generative line — and lets a single parameter choose which
#   writing system the viewer is invited to read. The algorithm must stay genuine, the parchment
#   must glow, the illumination must burn, and above all the generator must be bounded and
#   deterministic.

## A multi-mode generative Codex writing-system specimen run as a GENUINE algorithm.
##
## Built procedurally from DNA exports, after Luigi Serafini's Codex Seraphinianus, for the
## lsystems / graphtheory curriculum labs. The `mode` export selects one of FOUR processes, each
## ported faithfully from a verified trial INCLUDING its real algorithm:
## glyphgrid (a combinatorial stroke-GRAMMAR — 7 stroke terminals {BAR, CROSSBAR, DIAGONAL, ARC,
## HOOK, LOOP, DOT} placed by 4 attachment production rules {STACKED, SIDE_BY_SIDE, CROSSING,
## RADIAL} per cell, tiling a ruled grid of distinct asemic glyphs in raised relief on a tilted
## parchment tablet, a seeded subset rubricated gold),
## branchscript (a REAL bracketed L-system — one of 3 seed-picked grammars {majuscule, italic,
## monogram}, each a dominant stem `I→I` plus a self-recursing flourish `A→F!<+A` that coils into
## a logarithmic spiral, expanded N generations and walked by a 3D turtle with push/pop brackets
## + branch decay into tapered ink ribbons, illuminated nib tips, on an inkwell base),
## glyphgraph (REAL graph theory — N glyph-disc nodes on a dome, k-NN weighted edges + union-find
## bridging to one component, then PRIM'S minimum spanning tree highlighted as glowing arcs over
## the dim web),
## codexcolumn (generative cursive — a per-line pen-walk: sine baseline bob + layered value-noise
## tremor + cursive loops + cosine ascender/descender bumps + word-gap pen-lifts, swept as raised
## calligraphic ink ribbons on a parchment stele, opened by an illuminated initial).
##
## A seeded RNG makes every individual deterministic from its `seed`. The colour triad (color_a
## PARCHMENT / color_b INK / accent ILLUMINATION) re-registers the same writing between palettes;
## note glyphgraph's accent is the cyan MST highlight while the others' accent is gold illumination.
## Shared material + orient + settle + mesh-merge helpers live under the `_cg_` prefix; the genuine
## algorithm from each trial stays in its own builder under `_grid_` / `_brk_` / `_graph_` / `_col_`
## so the stroke-grammar, the L-system turtle, Prim's MST, and the pen-walk are preserved — that is
## the whole point. Surface generation reuses the morphology toolkit statics (MorphoPrimitive,
## MorphoSweep) and the LSystem grammar util.
##
## complexity scales the writing budget per mode: glyphgrid GRID SIZE (rows/cols), branchscript
## L-system GENERATIONS, glyphgraph NODE COUNT (9..16), codexcolumn LINE COUNT. Higher complexity
## = a denser page / a deeper expansion.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Form")
## glyphgrid | branchscript | glyphgraph | codexcolumn
@export var mode: String = "glyphgrid"
## Deterministic seed — same seed always yields the same specimen.
@export var seed: int = 0
## Detail / generator budget. Scales glyphgrid grid size, branchscript L-system generations,
## glyphgraph node count, and codexcolumn line count. Higher = a denser page / a deeper expansion.
@export var complexity: int = 6
## Overall height in meters (nominal full height of the specimen).
@export var sculpt_height: float = 1.6
## Footprint / across-span width scale in meters (1.0 = native trial proportions).
@export var sculpt_width: float = 1.0

@export_group("Material")
## PARCHMENT / substrate / tablet / disc / stele — pale cream stone.
@export var color_a: Color = Color(0.86, 0.80, 0.66)
## INK / stroke / glyph / edge — dark sepia.
@export var color_b: Color = Color(0.22, 0.16, 0.12)
## ILLUMINATION / rubrication / MST-highlight / margin GLOW — gold-ochre (cyan in glyphgraph).
@export var accent: Color = Color(0.85, 0.45, 0.25)
## Ink-on-parchment, not metal — keep this LOW.
@export var metallic_amt: float = 0.0
@export var rough_amt: float = 0.7
## Boost emissive energies (illumination reads hotter when true).
@export var emissive: bool = true

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false
var _rng := RandomNumberGenerator.new()
var _mesh_count: int = 0           # diagnostic: MeshInstance3D nodes emitted this build


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k: Variant in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c: Node in get_children():
			remove_child(c)
			c.queue_free()
		_built = false
	_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_mode"):
		mode = str(get_meta("config_mode")).to_lower().strip_edges()
	if has_meta("config_seed"):
		seed = int(str(get_meta("config_seed")))
	if has_meta("config_complexity"):
		complexity = int(str(get_meta("config_complexity")))
	if has_meta("config_sculpt_height"):
		sculpt_height = float(str(get_meta("config_sculpt_height")))
	if has_meta("config_sculpt_width"):
		sculpt_width = float(str(get_meta("config_sculpt_width")))
	if has_meta("config_color_a"):
		color_a = _parse_color(str(get_meta("config_color_a")), color_a)
	if has_meta("config_color_b"):
		color_b = _parse_color(str(get_meta("config_color_b")), color_b)
	if has_meta("config_accent"):
		accent = _parse_color(str(get_meta("config_accent")), accent)
	if has_meta("config_metallic_amt"):
		metallic_amt = float(str(get_meta("config_metallic_amt")))
	if has_meta("config_rough_amt"):
		rough_amt = float(str(get_meta("config_rough_amt")))
	if has_meta("config_emissive"):
		emissive = str(get_meta("config_emissive")).to_lower() in ["true", "1", "yes", "on"]


## Accepts an "r,g,b" / "r,g,b,a" string OR a colour name ("red", "cyan", …).
func _parse_color(raw: String, fallback: Color) -> Color:
	var s := raw.strip_edges()
	var parts := s.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	var named := Color(s.to_lower())
	if named != Color(0, 0, 0, 1) or s.to_lower() in ["black", "#000000", "000000"]:
		return named
	return fallback


# ── Build dispatch ─────────────────────────────────────────────────────

func _build() -> void:
	# Self-clear so the build is idempotent no matter who calls it: if `_ready()` fires DEFERRED
	# (after apply_grid_config has already built), a second _build() must not stack a second
	# specimen on top of the first (which previously doubled mesh counts on the first instance per
	# process — the capture path). Remove BEFORE freeing (queue_free is deferred) so the rebuild
	# starts from a genuinely empty subtree this frame.
	for c: Node in get_children():
		remove_child(c)
		c.queue_free()
	_built = true
	_mesh_count = 0
	_rng.seed = seed
	match mode:
		"glyphgrid":
			_build_glyphgrid()
		"branchscript":
			_build_branchscript()
		"glyphgraph":
			_build_glyphgraph()
		"codexcolumn":
			_build_codexcolumn()
		_:
			# Unknown mode falls back to the combinatorial glyph grid.
			_build_glyphgrid()


# ── Shared `_cg_` material helpers (the trial materials, DNA-driven) ─────

## Energy multiplier for emissive elements, lifted when `emissive` is on (gated like
## codex_morph's `_cm_glow_energy` / codex_flora's `_cfl_glow_energy`).
func _cg_glow_energy(base: float) -> float:
	return base * (1.0 if emissive else 0.6)


## PARCHMENT / stone / disc / tablet / stele (color_a family): pale, rough, with an emission FLOOR
## in its own tone (albedo*0.4 at energy ~0.10) so the substrate never collapses to black against
## the dark capture.
func _cg_substrate_mat(c: Color = color_a) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = clampf(maxf(rough_amt, 0.85), 0.02, 1.0)
	m.metallic = clampf(metallic_amt, 0.0, 1.0)
	m.emission_enabled = true
	m.emission = c * 0.4
	m.emission_energy_multiplier = _cg_glow_energy(0.10)
	return m


## INK strokes / glyphs / edges (color_b family): dark sepia, matte, with a faint emission floor
## (~0.06 energy) so the ink never collapses to pure black.
func _cg_ink_mat(c: Color = color_b) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = clampf(minf(rough_amt, 0.65), 0.02, 1.0)
	m.metallic = clampf(metallic_amt, 0.0, 1.0)
	m.emission_enabled = true
	m.emission = c * 0.4
	m.emission_energy_multiplier = _cg_glow_energy(0.06)
	return m


## ILLUMINATION / rubrication / MST-highlight / illuminated initial (accent family): saturated,
## near-UNSHADED, burning at `energy` ~2.5-3.5. The MST glow (glyphgraph) and the gold illumination
## (the other three) both come through here — the triad re-registers per mode via the accent colour.
func _cg_glow_mat(c: Color = accent, energy: float = 3.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = _cg_glow_energy(energy)
	return m


# ── Shared `_cg_` geometry helpers ──────────────────────────────────────

## Orthonormal Basis whose Y axis is `up_axis`. The single orient primitive the builders use so
## orientation is always via Basis, never out-of-tree look_at.
func _cg_basis_from_up(up_axis: Vector3) -> Basis:
	var y: Vector3 = up_axis.normalized()
	if y.length_squared() < 0.0001:
		y = Vector3.UP
	var ref: Vector3 = Vector3.RIGHT
	if absf(y.dot(ref)) > 0.95:
		ref = Vector3.FORWARD
	var x: Vector3 = ref.cross(y).normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Basis(x, y, z)


## Wrap a Mesh in a MeshInstance3D with material + local transform, parented to `parent`.
func _cg_add_mesh(parent: Node3D, mesh: Mesh, mat: Material,
		xform: Transform3D = Transform3D.IDENTITY, node_name: String = "Part") -> MeshInstance3D:
	if mesh == null:
		return null
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = xform
	parent.add_child(mi)
	_mesh_count += 1
	return mi


## Append a Mesh's surface-0 triangles into a SurfaceTool, transformed by `xform`. This is the
## mesh-batch / merge helper that lets a whole alphabet / edge-web / line of script live in a
## handful of ArrayMeshes the capture AABB can frame — no MultiMesh.
##
## CRITICAL (carried from the trials): MorphoPrimitive output is often NON-INDEXED and may be
## missing the normal array, so the mesh arrays must be read as Variants and coerced ONLY when the
## expected packed type is actually present — never blind-cast `arrays[ARRAY_NORMAL]` to
## PackedVector3Array (it can be null → a hard runtime error). Both the indexed and non-indexed
## paths are handled.
func _cg_merge_into(st: SurfaceTool, mesh: Mesh, xform: Transform3D = Transform3D.IDENTITY) -> void:
	if mesh == null:
		return
	if mesh.get_surface_count() == 0:
		return
	var arrays: Array = mesh.surface_get_arrays(0)
	var v_raw: Variant = arrays[Mesh.ARRAY_VERTEX]
	if not (v_raw is PackedVector3Array):
		return
	var verts: PackedVector3Array = v_raw
	var n_raw: Variant = arrays[Mesh.ARRAY_NORMAL]
	var norms := PackedVector3Array()
	if n_raw is PackedVector3Array:
		norms = n_raw
	var i_raw: Variant = arrays[Mesh.ARRAY_INDEX]
	var indices := PackedInt32Array()
	if i_raw is PackedInt32Array:
		indices = i_raw
	var nbasis: Basis = xform.basis
	if indices.size() > 0:
		for i: int in range(indices.size()):
			var idx: int = indices[i]
			var n: Vector3 = (nbasis * norms[idx]).normalized() if idx < norms.size() else Vector3.UP
			st.set_normal(n)
			st.add_vertex(xform * verts[idx])
	else:
		for i: int in range(verts.size()):
			var n2: Vector3 = (nbasis * norms[i]).normalized() if i < norms.size() else Vector3.UP
			st.set_normal(n2)
			st.add_vertex(xform * verts[i])


## Commit a batched SurfaceTool into one MeshInstance3D under `parent`. `gen_normals` regenerates
## normals (off when the batch already set per-vertex normals via _cg_merge_into, which would
## otherwise be flattened). Returns the instance (or null if the batch was empty).
func _cg_commit_batch(parent: Node3D, st: SurfaceTool, mat: Material, nm: String,
		gen_normals: bool = false) -> MeshInstance3D:
	if gen_normals:
		st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return null
	return _cg_add_mesh(parent, mesh, mat, Transform3D.IDENTITY, nm)


## Local AABB over all MeshInstance3D descendants of `node`, accumulated through the chain of LOCAL
## transforms down from `node` (never touches global_transform — independent of tree state). Used
## to centre + scale each specimen.
func _cg_subtree_aabb(node: Node3D) -> AABB:
	var total := AABB()
	var first: bool = true
	var stack: Array = [[node, Transform3D.IDENTITY]]
	while not stack.is_empty():
		var entry: Array = stack.pop_back()
		var current: Node = entry[0]
		var accum: Transform3D = entry[1]
		if current is MeshInstance3D and (current as MeshInstance3D).mesh != null:
			var mi := current as MeshInstance3D
			var a: AABB = accum * mi.get_aabb()
			if first:
				total = a
				first = false
			else:
				total = total.merge(a)
		for child: Node in current.get_children():
			if child is Node3D:
				stack.append([child, accum * (child as Node3D).transform])
			else:
				stack.append([child, accum])
	return total


## Centre `body` and scale it to ~`target_h` tall, then present it to the +X/+Z capture camera (the
## codex_morph `_cm_settle` analogue). `width_scale` stretches the horizontal axes for span.
## `floor_to_zero` drops the base to y=0 (standing tablets/steles); when false the specimen is
## fully centred (the free-floating glyph / network that frames cleanest around its own centroid).
func _cg_settle(body: Node3D, target_h: float, width_scale: float = 1.0,
		floor_to_zero: bool = true) -> void:
	if target_h > 0.0:
		var raw: AABB = _cg_subtree_aabb(body)
		var span_y: float = maxf(raw.size.y, 0.001)
		var k: float = target_h / span_y
		body.scale = Vector3(k * width_scale, k, k * width_scale)
	var aabb: AABB = _cg_subtree_aabb(body)
	if aabb.size == Vector3.ZERO:
		return
	var centre: Vector3 = aabb.get_center()
	if floor_to_zero:
		body.position += Vector3(-centre.x, -aabb.position.y, -centre.z)
	else:
		body.position += -centre


# =============================================================================
# MODE: glyphgrid — the combinatorial stroke-GRAMMAR (trial v1)
#
# The genuine algorithm (a combinatorial stroke-grammar, the load-bearing core):
#   A small library of 7 STROKE primitives is the terminal vocabulary
#   {BAR, CROSSBAR, DIAGONAL, ARC, HOOK, LOOP, DOT}. A glyph is a deterministic combination of
#   2..5 strokes chosen from a per-cell sub-seed; one of 4 ATTACHMENT production rules
#   {STACKED, SIDE_BY_SIDE, CROSSING, RADIAL} decides where each successive stroke sits, so the
#   SAME stroke set reads differently under a different rule. This is the production system:
#       cell_seed -> (rule, stroke list, slots) -> glyph.
#   GLYPH_ROWS x GLYPH_COLS cells (scaled by complexity) tile a ruled grid on a parchment tablet
#   like a manuscript key-table; faint raised rules separate the cells; a seeded subset of glyphs
#   is RUBRICATED (ink swapped for glowing gold). Every stroke is a real raised relief solid;
#   curved strokes use MorphoPrimitive.bezier_sweep / multi_tube / sphere, bars use batched boxes.
#   All ink strokes weld into ONE ArrayMesh and all gold into another so the tablet frames as one
#   object. complexity scales the grid density. Deterministic from seed.
# =============================================================================

# glyphgrid stroke-grammar terminal symbols.
enum GridStroke { BAR, CROSSBAR, DIAGONAL, ARC, HOOK, LOOP, DOT }
# glyphgrid attachment grammar (production rules — how strokes are placed in a cell).
enum GridRule { STACKED, SIDE_BY_SIDE, CROSSING, RADIAL }

const _GRID_ROWS: int = 5                 # base rows  (×complexity)
const _GRID_COLS: int = 4                 # base cols  (×complexity)
const _GRID_TABLET_W: float = 2.20        # slab width  (m, X on the face plane)
const _GRID_TABLET_H: float = 2.05        # slab height (m, Y on the face plane)
const _GRID_TABLET_THICK: float = 0.115   # slab depth (m)
const _GRID_TILT_DEG: float = 14.0        # backward lean of the face (lectern)
const _GRID_RELIEF: float = 0.038         # how far ink stands proud of the face
const _GRID_STROKE_W: float = 0.030       # ink ribbon/bar half-thickness scale
const _GRID_RUBRIC_FRACTION: float = 0.18 # share of glyphs rendered in gold

# Face-plane frame (slab LOCAL space; the slab node's tilt basis is applied once by the parent).
var _grid_face_x: Vector3 = Vector3.RIGHT
var _grid_face_y: Vector3 = Vector3.UP
var _grid_face_normal: Vector3 = Vector3.BACK      # BACK == +Z in Godot
var _grid_face_origin: Vector3 = Vector3.ZERO


func _build_glyphgrid() -> void:
	var mat_parchment := _cg_substrate_mat(color_a)
	var mat_ink := _cg_ink_mat(color_b)
	# Incised guide rules: a darker, recessed parchment tone (substrate dimmed toward ink).
	var mat_groove := _cg_substrate_mat(color_a.lerp(color_b, 0.42))
	var mat_gold := _cg_glow_mat(accent, 2.5)

	# Orient the slab so its FRONT FACE (+Z local) turns toward the +X/+Z capture camera: a yaw
	# about Y aims the face, a small backward lean tips the reading plane up to meet the descending
	# camera (lectern stance). The face frame is expressed in the slab's LOCAL space below, so every
	# stroke is transformed by this basis EXACTLY once (working in local space avoids double xforms).
	var yaw := Basis(Vector3.UP, deg_to_rad(30.0))
	var lean := Basis(Vector3.RIGHT, deg_to_rad(-_GRID_TILT_DEG))
	var tilt: Basis = yaw * lean

	var slab := Node3D.new()
	slab.name = "Tablet"
	slab.basis = tilt
	add_child(slab)

	# Slab box + local face frame.
	_cg_add_mesh(slab, MorphoPrimitive.box(
			Vector3(_GRID_TABLET_W, _GRID_TABLET_H, _GRID_TABLET_THICK)),
		mat_parchment, Transform3D.IDENTITY, "Slab")
	_grid_face_x = Vector3.RIGHT
	_grid_face_y = Vector3.UP
	_grid_face_normal = Vector3.BACK
	_grid_face_origin = Vector3(0.0, 0.0, _GRID_TABLET_THICK * 0.5)

	# Grid dimensions scale with complexity (clamped so the tablet stays a key-table, not a haze).
	var cfac: float = clampf(float(complexity) / 6.0, 0.5, 2.0)
	var rows: int = maxi(2, int(round(float(_GRID_ROWS) * cfac)))
	var cols: int = maxi(2, int(round(float(_GRID_COLS) * cfac)))

	# Writing region: tight inset so the grid of glyphs fills the face.
	var margin_x: float = _GRID_TABLET_W * 0.055
	var margin_y: float = _GRID_TABLET_H * 0.050
	var region_w: float = _GRID_TABLET_W - margin_x * 2.0
	var region_h: float = _GRID_TABLET_H - margin_y * 2.0
	var cell_w: float = region_w / float(cols)
	var cell_h: float = region_h / float(rows)
	var glyph_w: float = cell_w * 0.74
	var glyph_h: float = cell_h * 0.78

	# Incised guide grid (faint raised rules, batched as one mesh).
	_grid_build_rules(slab, mat_groove, rows, cols, region_w, region_h)

	# Ink and gold are each accumulated into ONE SurfaceTool then committed once, so the whole
	# alphabet frames as two objects.
	var ink_st := SurfaceTool.new()
	ink_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var gold_st := SurfaceTool.new()
	gold_st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for r: int in range(rows):
		for c: int in range(cols):
			# Cell centre on the writing surface (v grows downward in reading order, row 0 = top).
			var cu: float = -region_w * 0.5 + cell_w * (float(c) + 0.5)
			var cv: float = region_h * 0.5 - cell_h * (float(r) + 0.5)

			# Deterministic per-cell sub-seed mixing the master seed and (r,c).
			var cell_seed: int = seed + (r * 73856093) ^ (c * 19349663)
			var grng := RandomNumberGenerator.new()
			grng.seed = cell_seed

			# Rubricate a deterministic subset (gold illuminated initials).
			var is_gold: bool = grng.randf() < _GRID_RUBRIC_FRACTION
			var target_st: SurfaceTool = gold_st if is_gold else ink_st
			_grid_build_glyph(target_st, grng, cu, cv, glyph_w, glyph_h)

	# Commit the ink alphabet + the rubricated gold alphabet (normals regenerated per batch).
	_cg_commit_batch(slab, ink_st, mat_ink, "GlyphInk", true)
	_cg_commit_batch(slab, gold_st, mat_gold, "GlyphGold", true)

	# Lift the slab so its base sits near y=0, then settle (standing tablet leans toward camera).
	slab.position = Vector3(0.0, _GRID_TABLET_H * 0.5, 0.0)
	_cg_settle(slab, maxf(sculpt_height, 0.4), maxf(sculpt_width, 0.2), true)


## Map a 2D point on the writing surface (u,v centred at face origin) + proud height h to a LOCAL
## slab-space position.
func _grid_surface_point(u: float, v: float, h: float) -> Vector3:
	return _grid_face_origin + _grid_face_x * u + _grid_face_y * v + _grid_face_normal * h


## Orthonormal Basis aligned to the face frame with an in-plane roll (radians about the normal).
func _grid_face_basis(roll: float) -> Basis:
	var x: Vector3 = (_grid_face_x * cos(roll) + _grid_face_y * sin(roll)).normalized()
	var y: Vector3 = (-_grid_face_x * sin(roll) + _grid_face_y * cos(roll)).normalized()
	return Basis(x, y, _grid_face_normal)


## Incised guide grid: thin raised ribbons between cells (and a border), batched into one mesh,
## sitting just proud of the face so the lattice reads between the glyphs.
func _grid_build_rules(slab: Node3D, mat: Material, rows: int, cols: int,
		region_w: float, region_h: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var line_w: float = 0.006
	var rule_h: float = _GRID_RELIEF * 0.18
	var rule_d: float = _GRID_RELIEF * 0.18
	var inner_left: float = -region_w * 0.5
	var inner_top: float = region_h * 0.5

	for r: int in range(rows + 1):
		var v: float = inner_top - region_h * (float(r) / float(rows))
		var c0: Vector3 = _grid_surface_point(-region_w * 0.5, v, rule_h)
		var c1: Vector3 = _grid_surface_point(region_w * 0.5, v, rule_h)
		_grid_emit_face_ribbon(st, c0, c1, line_w, rule_d)
	for c: int in range(cols + 1):
		var u: float = inner_left + region_w * (float(c) / float(cols))
		var c0v: Vector3 = _grid_surface_point(u, region_h * 0.5, rule_h)
		var c1v: Vector3 = _grid_surface_point(u, -region_h * 0.5, rule_h)
		_grid_emit_face_ribbon(st, c0v, c1v, line_w, rule_d)

	_cg_commit_batch(slab, st, mat, "GuideGrid", true)


# ── THE GLYPH GRAMMAR — cell_seed -> (rule, strokes, slots) -> relief ──

## Build ONE glyph inside the window centred at (cu,cv) of size (gw,gh) on the writing surface,
## emitting its strokes into `st`. The grammar: 1) pick an attachment RULE; 2) pick a stroke COUNT
## in 2..5; 3) pick that many STROKE terminals (rule biases the palette); 4) place each in a SLOT
## determined by the rule + index.
func _grid_build_glyph(st: SurfaceTool, rng: RandomNumberGenerator,
		cu: float, cv: float, gw: float, gh: float) -> void:
	var rule: int = rng.randi() % 4
	var count: int = 2 + (rng.randi() % 4)            # 2..5 strokes
	var hw: float = gw * 0.5
	var hh: float = gh * 0.5
	match rule:
		GridRule.STACKED:
			_grid_glyph_stacked(st, rng, cu, cv, hw, hh, count)
		GridRule.SIDE_BY_SIDE:
			_grid_glyph_side_by_side(st, rng, cu, cv, hw, hh, count)
		GridRule.CROSSING:
			_grid_glyph_crossing(st, rng, cu, cv, hw, hh, count)
		GridRule.RADIAL:
			_grid_glyph_radial(st, rng, cu, cv, hw, hh, count)


## STACKED: a central mast with strokes stacked at successive heights (script-like).
func _grid_glyph_stacked(st: SurfaceTool, rng: RandomNumberGenerator,
		cu: float, cv: float, hw: float, hh: float, count: int) -> void:
	_grid_stroke_bar(st, cu, cv, hh * 1.7, rng.randf_range(-0.10, 0.10))
	for i: int in range(count - 1):
		var t: float = float(i + 1) / float(count)
		var v: float = cv + lerpf(hh * 0.8, -hh * 0.8, t)
		var pick: int = _grid_weighted_stroke(rng, [GridStroke.CROSSBAR, GridStroke.HOOK, GridStroke.DOT, GridStroke.ARC])
		_grid_emit_stroke(st, rng, pick, cu, v, hw, hh * 0.5)


## SIDE_BY_SIDE: strokes placed in horizontal slots across the cell (adjacent radicals).
func _grid_glyph_side_by_side(st: SurfaceTool, rng: RandomNumberGenerator,
		cu: float, cv: float, hw: float, hh: float, count: int) -> void:
	for i: int in range(count):
		var t: float = (float(i) + 0.5) / float(count)
		var u: float = cu + lerpf(-hw * 0.9, hw * 0.9, t)
		var pick: int = _grid_weighted_stroke(rng, [GridStroke.BAR, GridStroke.ARC, GridStroke.DIAGONAL, GridStroke.HOOK, GridStroke.LOOP])
		_grid_emit_stroke(st, rng, pick, u, cv + rng.randf_range(-hh * 0.15, hh * 0.15), hw / float(count) * 1.2, hh)


## CROSSING: two or more strokes intersecting through the centre — an X / + ideogram.
func _grid_glyph_crossing(st: SurfaceTool, rng: RandomNumberGenerator,
		cu: float, cv: float, hw: float, hh: float, count: int) -> void:
	if rng.randf() < 0.5:
		_grid_stroke_diagonal(st, cu, cv, hw * 1.4, hh * 1.4, deg_to_rad(38.0) + rng.randf_range(-0.12, 0.12))
		_grid_stroke_diagonal(st, cu, cv, hw * 1.4, hh * 1.4, deg_to_rad(-38.0) + rng.randf_range(-0.12, 0.12))
	else:
		_grid_stroke_bar(st, cu, cv, hh * 1.6, rng.randf_range(-0.08, 0.08))
		_grid_stroke_crossbar(st, cu, cv, hw * 1.6, rng.randf_range(-0.08, 0.08))
	for i: int in range(count - 2):
		var ang: float = TAU * (float(i) / float(maxi(count - 2, 1))) + rng.randf_range(0.0, TAU)
		var u: float = cu + cos(ang) * hw * 0.7
		var v: float = cv + sin(ang) * hh * 0.7
		var pick: int = _grid_weighted_stroke(rng, [GridStroke.DOT, GridStroke.ARC, GridStroke.HOOK])
		_grid_emit_stroke(st, rng, pick, u, v, hw * 0.4, hh * 0.4)


## RADIAL: strokes radiate from a central node — a sun / asterisk character.
func _grid_glyph_radial(st: SurfaceTool, rng: RandomNumberGenerator,
		cu: float, cv: float, hw: float, hh: float, count: int) -> void:
	if rng.randf() < 0.5:
		_grid_stroke_loop(st, cu, cv, minf(hw, hh) * 0.42)
	else:
		_grid_stroke_dot(st, cu, cv, minf(hw, hh) * 0.22)
	var spokes: int = count - 1
	for i: int in range(spokes):
		var ang: float = TAU * float(i) / float(maxi(spokes, 1)) + rng.randf_range(-0.12, 0.12)
		var reach: float = minf(hw, hh) * 0.95
		var u: float = cu + cos(ang) * reach * 0.5
		var v: float = cv + sin(ang) * reach * 0.5
		var roll: float = ang - PI * 0.5
		if rng.randf() < 0.35:
			_grid_stroke_hook(st, u, v, reach * 0.5, roll)
		else:
			_grid_stroke_bar(st, u, v, reach * 0.95, roll)


## Dispatch a single stroke terminal at (u,v) sized to (sw,sh) with rng jitter.
func _grid_emit_stroke(st: SurfaceTool, rng: RandomNumberGenerator, kind: int,
		u: float, v: float, sw: float, sh: float) -> void:
	match kind:
		GridStroke.BAR:
			_grid_stroke_bar(st, u, v, sh * 1.4, rng.randf_range(-0.18, 0.18))
		GridStroke.CROSSBAR:
			_grid_stroke_crossbar(st, u, v, sw * 1.5, rng.randf_range(-0.12, 0.12))
		GridStroke.DIAGONAL:
			_grid_stroke_diagonal(st, u, v, sw * 1.2, sh * 1.2,
				deg_to_rad(40.0) * (1.0 if rng.randf() < 0.5 else -1.0) + rng.randf_range(-0.15, 0.15))
		GridStroke.ARC:
			_grid_stroke_arc(st, u, v, sw * 1.2, sh * 1.3, rng.randf_range(0.0, TAU))
		GridStroke.HOOK:
			_grid_stroke_hook(st, u, v, sh * 1.1, rng.randf_range(0.0, TAU))
		GridStroke.LOOP:
			_grid_stroke_loop(st, u, v, minf(sw, sh) * 0.7)
		GridStroke.DOT:
			_grid_stroke_dot(st, u, v, minf(sw, sh) * 0.5)


## Pick a stroke terminal uniformly from a candidate palette (the grammar biases which strokes
## appear under each attachment rule).
func _grid_weighted_stroke(rng: RandomNumberGenerator, palette: Array) -> int:
	return int(palette[rng.randi() % palette.size()])


# ── glyphgrid STROKE PRIMITIVES — each a raised relief solid on the face plane ──

## BAR: a vertical mast — a thin box standing on the face. `length` = its height; `roll` rolls it.
func _grid_stroke_bar(st: SurfaceTool, u: float, v: float, length: float, roll: float) -> void:
	var basis: Basis = _grid_face_basis(roll)
	var centre: Vector3 = _grid_surface_point(u, v, _GRID_RELIEF * 0.5)
	_grid_emit_box(st, centre, basis.x, basis.y, basis.z, _GRID_STROKE_W, length * 0.5, _GRID_RELIEF * 0.5)


## CROSSBAR: a horizontal beam — a thin box laid across the surface (long axis = face-x).
func _grid_stroke_crossbar(st: SurfaceTool, u: float, v: float, length: float, roll: float) -> void:
	var basis: Basis = _grid_face_basis(roll)
	var centre: Vector3 = _grid_surface_point(u, v, _GRID_RELIEF * 0.5)
	_grid_emit_box(st, centre, basis.x, basis.y, basis.z, length * 0.5, _GRID_STROKE_W, _GRID_RELIEF * 0.5)


## DIAGONAL: an oblique stroke — a thin box rolled to angle `roll` (radians) in the face plane.
func _grid_stroke_diagonal(st: SurfaceTool, u: float, v: float, hw: float, hh: float, roll: float) -> void:
	var basis: Basis = _grid_face_basis(roll)
	var centre: Vector3 = _grid_surface_point(u, v, _GRID_RELIEF * 0.5)
	var length: float = sqrt(hw * hw + hh * hh) * 1.1
	_grid_emit_box(st, centre, basis.x, basis.y, basis.z, _GRID_STROKE_W, length * 0.5, _GRID_RELIEF * 0.5)


## ARC: a curved ribbon — a cubic Bézier swept with a thin rectangular section, in the face plane.
## `phase` rotates the arc's bow direction so arcs read varied.
func _grid_stroke_arc(st: SurfaceTool, u: float, v: float, hw: float, hh: float, phase: float) -> void:
	var radius: float = minf(hw, hh)
	var a0: float = phase
	var a1: float = phase + PI * 0.85
	var p0: Vector3 = _grid_surface_point(u + cos(a0) * radius, v + sin(a0) * radius, _GRID_RELIEF * 0.7)
	var p3: Vector3 = _grid_surface_point(u + cos(a1) * radius, v + sin(a1) * radius, _GRID_RELIEF * 0.7)
	var mid_ang: float = (a0 + a1) * 0.5
	var bow: float = radius * 1.5
	var pm: Vector3 = _grid_surface_point(u + cos(mid_ang) * bow, v + sin(mid_ang) * bow, _GRID_RELIEF * 0.7)
	var p1: Vector3 = p0.lerp(pm, 0.6)
	var p2: Vector3 = p3.lerp(pm, 0.6)
	var ctrl: Array[Vector3] = [p0, p1, p2, p3]
	var cross: Array[Vector2] = _grid_ribbon_cross()
	var arc_mesh: Mesh = MorphoPrimitive.bezier_sweep(ctrl, cross, 10, 0.0)
	_cg_merge_into(st, arc_mesh)


## HOOK: a tight curled tail — a short strongly-bowed Bézier ribbon (a comma / crozier). `roll`
## orients the hook's overall direction.
func _grid_stroke_hook(st: SurfaceTool, u: float, v: float, size: float, roll: float) -> void:
	var dir: Vector2 = Vector2(cos(roll), sin(roll))
	var perp: Vector2 = Vector2(-dir.y, dir.x)
	var s: float = size
	var q0: Vector2 = Vector2(0.0, 0.0)
	var q1: Vector2 = dir * s * 0.7
	var q2: Vector2 = dir * s * 0.95 + perp * s * 0.55
	var q3: Vector2 = dir * s * 0.55 + perp * s * 1.0
	var p0: Vector3 = _grid_surface_point(u + q0.x, v + q0.y, _GRID_RELIEF * 0.7)
	var p1: Vector3 = _grid_surface_point(u + q1.x, v + q1.y, _GRID_RELIEF * 0.7)
	var p2: Vector3 = _grid_surface_point(u + q2.x, v + q2.y, _GRID_RELIEF * 0.7)
	var p3: Vector3 = _grid_surface_point(u + q3.x, v + q3.y, _GRID_RELIEF * 0.7)
	var ctrl: Array[Vector3] = [p0, p1, p2, p3]
	var cross: Array[Vector2] = _grid_ribbon_cross()
	var hook_mesh: Mesh = MorphoPrimitive.bezier_sweep(ctrl, cross, 9, 0.0)
	_cg_merge_into(st, hook_mesh)


## LOOP: a closed ring — a tube swept around a circle on the face plane (an 'o' / bulla), via
## MorphoPrimitive.multi_tube over a ring of positions (first==last for closure).
func _grid_stroke_loop(st: SurfaceTool, u: float, v: float, radius: float) -> void:
	var seg: int = 14
	var positions: Array[Vector3] = []
	var radii: Array[float] = []
	for i: int in range(seg + 1):
		var a: float = TAU * float(i) / float(seg)
		positions.append(_grid_surface_point(u + cos(a) * radius, v + sin(a) * radius, _GRID_RELIEF * 0.7))
		radii.append(_GRID_STROKE_W * 0.85)
	var loop_mesh: Mesh = MorphoPrimitive.multi_tube(positions, radii, 6)
	_cg_merge_into(st, loop_mesh)


## DOT: a punctuation node — a small squashed sphere proud of the face.
func _grid_stroke_dot(st: SurfaceTool, u: float, v: float, radius: float) -> void:
	var centre: Vector3 = _grid_surface_point(u, v, radius * 0.6 + _GRID_RELIEF * 0.3)
	var dot_mesh: Mesh = MorphoPrimitive.sphere(radius, 10, 6)
	# Squash along the face normal so it reads as a raised bead, not a full ball.
	var basis: Basis = Basis(_grid_face_x, _grid_face_y, _grid_face_normal).scaled(Vector3(1.0, 1.0, 0.6))
	_cg_merge_into(st, dot_mesh, Transform3D(basis, centre))


## A thin rectangular ribbon cross-section (x = half-width across, y = half relief), used by the
## bezier_sweep strokes (arc, hook).
func _grid_ribbon_cross() -> Array[Vector2]:
	var w: float = _GRID_STROKE_W * 0.9
	var d: float = _GRID_RELIEF * 0.55
	return [
		Vector2(-w, -d), Vector2(w, -d), Vector2(w, d), Vector2(-w, d),
	]


## A thin ribbon laid flat on the face between two LOCAL points `a` and `b` (used for guide rules).
## `half_w` half-width across the line in the face plane; `half_d` half-depth along the normal.
func _grid_emit_face_ribbon(st: SurfaceTool, a: Vector3, b: Vector3, half_w: float, half_d: float) -> void:
	var along: Vector3 = b - a
	var length: float = along.length()
	if length < 0.0001:
		return
	along = along / length
	var centre: Vector3 = (a + b) * 0.5
	var across: Vector3 = _grid_face_normal.cross(along).normalized()
	_grid_emit_box(st, centre, along, across, _grid_face_normal, length * 0.5, half_w, half_d)


## Emit one box (12 triangles, outward normals) into a SurfaceTool. Centred at `c`, half-extents
## (hx,hy,hz) along orthonormal axes (ax,ay,az). Shared by every bar/crossbar/diagonal + guide rule.
func _grid_emit_box(st: SurfaceTool, c: Vector3, ax: Vector3, ay: Vector3, az: Vector3,
		hx: float, hy: float, hz: float) -> void:
	var ex: Vector3 = ax * hx
	var ey: Vector3 = ay * hy
	var ez: Vector3 = az * hz
	var p000: Vector3 = c - ex - ey - ez
	var p100: Vector3 = c + ex - ey - ez
	var p110: Vector3 = c + ex + ey - ez
	var p010: Vector3 = c - ex + ey - ez
	var p001: Vector3 = c - ex - ey + ez
	var p101: Vector3 = c + ex - ey + ez
	var p111: Vector3 = c + ex + ey + ez
	var p011: Vector3 = c - ex + ey + ez
	_grid_quad(st, p000, p010, p110, p100, -az)   # -Z
	_grid_quad(st, p001, p101, p111, p011, az)    # +Z
	_grid_quad(st, p000, p100, p101, p001, -ay)   # -Y
	_grid_quad(st, p010, p011, p111, p110, ay)    # +Y
	_grid_quad(st, p000, p001, p011, p010, -ax)   # -X
	_grid_quad(st, p100, p110, p111, p101, ax)    # +X


func _grid_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3) -> void:
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(b)
	st.set_normal(n); st.add_vertex(c)
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(c)
	st.set_normal(n); st.add_vertex(d)


# =============================================================================
# MODE: branchscript — a single ornate LETTER grown by a REAL L-system (trial v2)
#
# The genuine algorithm (a bracketed Lindenmayer system, the load-bearing core):
#   The SAME machinery TreeMorphology uses to grow a tree — axiom + production rules expanded N
#   generations, a 3D turtle with push/pop brackets + branch decay — tuned instead to grow ONE
#   ornate calligraphic CHARACTER. The seed picks one of 3 grammars {majuscule, italic, monogram};
#   each keeps (1) a DOMINANT STABLE STEM (`I -> I`, a constant-length unit so the spine towers
#   over the flourishes with no global rescale-to-thread), and (2) a CONTINUOUS TIGHTENING SPIRAL
#   flourish (`A -> F ! < + A`: forward, thin, shrink step, turn, recurse) which over GENERATIONS
#   traces a logarithmic spiral coiling inward to a nib — a pen-flourish that flushes as ONE swept
#   ribbon. The expanded string is hard-capped (MAX_STRING_LEN) so it always terminates; the
#   turtle is segment-capped too. Every stroke is a tapered ink RIBBON via MorphoPrimitive.multi_tube
#   (flattened cross-section -> calligraphic nib); flourish-tip GLOW beads + dot-serifs are spheres;
#   the inkwell base is a revolution. Orientation is purely the turtle's Basis frame — no look_at.
#   complexity scales the L-system GENERATIONS (deeper = longer coils). Deterministic from seed.
# =============================================================================

const _BRK_BASE_GENERATIONS: int = 16   # L-system rewrite depth at complexity 6 (stem rules are
                                        # identity/one-shot, so generations chiefly lengthen the
                                        # recursive spiral curls A->F!<+A — each generation a whorl).
const _BRK_MAX_STRING_LEN: int = 60000  # hard cap so expansion always terminates
const _BRK_TARGET_HEIGHT: float = 2.45  # final upright height (m), before settle
const _BRK_STEP_LEN: float = 0.118      # turtle forward step (pre-decay)
const _BRK_STEP_DECAY: float = 0.80     # length shrink per bracket depth
const _BRK_STEP_SHRINK: float = 0.86    # length shrink per `<` (curl tightening)
const _BRK_YAW_DEG: float = 22.0        # base yaw turn
const _BRK_PITCH_DEG: float = 18.0      # base pitch turn
const _BRK_ROLL_DEG: float = 24.0       # base roll turn
const _BRK_STROKE_RADIUS: float = 0.060 # ink ribbon half-width at the root
const _BRK_RADIUS_DECAY: float = 0.72   # ribbon thinning per bracket depth
const _BRK_RIBBON_FLATTEN: float = 0.62 # cross-section z/x ratio (ribbon, not tube)
const _BRK_TUBE_SIDES: int = 7          # ribbon cross-section resolution
const _BRK_MAX_SEGMENTS: int = 1400     # safety cap on drawn segments

# branchscript turtle state pushed/popped on brackets (typed throughout).
class BrkTurtle:
	var pos: Vector3
	var heading: Vector3
	var left: Vector3
	var up: Vector3
	var depth: int
	var length: float
	var radius: float

var _brk_segment_count: int = 0


func _build_branchscript() -> void:
	_brk_segment_count = 0
	var mat_ink := _cg_ink_mat(color_b)
	var mat_base := _cg_substrate_mat(color_a)
	var mat_glow := _cg_glow_mat(accent, 3.0)

	var glyph := Node3D.new()
	glyph.name = "Glyph"
	add_child(glyph)

	# Inkwell base sits at the origin; the glyph rises out of it.
	_brk_build_inkwell(glyph, mat_base)

	# Grow the L-system for this seed, then interpret it into geometry.
	var sentence: String = _brk_build_sentence()
	_brk_interpret(sentence, glyph, mat_ink, mat_glow, mat_base)

	# Frame the glyph: scale to height, present its asymmetric profile to the +X/+Z camera.
	_brk_frame_glyph(glyph)


## Build the L-system for this seed and return its expanded sentence. Three seed-picked grammars,
## each a dominant `I` stem + self-recursing asymmetric flourishes so the result reads as one
## curling character. The string is a String; generations scale with complexity.
func _brk_build_sentence() -> String:
	var variant: int = _rng.randi() % 3
	var lsys: LSystem
	var axiom: String = ""

	if variant == 0:
		# MAJUSCULE — an upright illuminated initial: a commanding vertical stem shedding ascending
		# flourishes at varied azimuths (all coiling the same hand), a grounding foot-curl, a crown.
		axiom = (
			"o [ R ] + I I"
			+ " [ & & F F ^ A ] I I"
			+ " [ / / / / & & F F ^ A ] I I"
			+ " [ \\ \\ & & F F ^ A ] I I"
			+ " I I I H"
		)
		lsys = LSystem.new(axiom)
		lsys.add_rule("I", "I")                 # stem unit — constant length
		lsys.add_rule("A", "F ! < + A")         # the tightening logarithmic-spiral curl
		lsys.add_rule("H", "/ & F F F ^ ^ A")   # crown: a single grand swash
		lsys.add_rule("R", "& & F - F - F ! < - A")  # root foot: one low backward curl
	elif variant == 1:
		# ITALIC — a leaning cursive character: flourishes spring from alternating azimuths with
		# opposite-handed curls (-), a grand ascender loop on top.
		axiom = (
			"o + + + I I"
			+ " [ \\ & & F F ^ A ] I I"
			+ " [ / / / & & F F ^ A ] I I"
			+ " [ / & & F F ^ A ] I I"
			+ " I I I T"
		)
		lsys = LSystem.new(axiom)
		lsys.add_rule("I", "I")
		lsys.add_rule("A", "F ! < - A")         # left-handed spiral -> cursive
		lsys.add_rule("T", "\\ & F F F ^ ^ A")  # tall ascender looping over the top
	else:
		# MONOGRAM — a doubled character: a primary stem + a secondary stem branching early, leaning
		# away, climbing in parallel, each crowned with its own curl (an entwined initial).
		axiom = (
			"o I I [ M ] I"
			+ " [ & & & F F F ^ A ] I I"
			+ " [ / / / & & F F F ^ A ] I I"
			+ " [ \\ \\ \\ & & & F F F ^ A ] I I"
			+ " [ / & & F F ^ A ] I I I H"
		)
		lsys = LSystem.new(axiom)
		lsys.add_rule("I", "I")
		lsys.add_rule("M", "/ / & & & J J J J [ & & F F ^ A ] J J J ^ F F F ^ A")  # secondary spine
		lsys.add_rule("J", "J")
		lsys.add_rule("A", "F ! < + A")
		lsys.add_rule("H", "/ & F F F ^ ^ A")

	# Generations scale with complexity (clamped so deep coils stay bounded).
	var gens: int = clampi(_BRK_BASE_GENERATIONS + (complexity - 6) * 2, 8, 22)
	lsys.generate_n(gens)
	var raw: String = lsys.get_sentence().replace(" ", "")
	# Hard cap so the turtle always terminates even if a grammar runs hot.
	if raw.length() > _BRK_MAX_STRING_LEN:
		raw = raw.substr(0, _BRK_MAX_STRING_LEN)
	return raw


## Walk the sentence (a String). `I`/`J`/`F` accumulate into a polyline flushed into a tapered ink
## ribbon on every push/pop. Glow beads mark flourish tips (leftover `A`/`B` nibs + `}`); dot-serifs
## mark `o`. The turtle frame rotates by Basis-based rotations only — no out-of-tree look_at.
func _brk_interpret(sentence: String, glyph: Node3D, mat_ink: Material,
		mat_glow: Material, mat_base: Material) -> void:
	var yaw_rad: float = deg_to_rad(_BRK_YAW_DEG)
	var pitch_rad: float = deg_to_rad(_BRK_PITCH_DEG)
	var roll_rad: float = deg_to_rad(_BRK_ROLL_DEG)

	var st := BrkTurtle.new()
	st.pos = Vector3.ZERO
	st.heading = Vector3.UP            # the glyph grows upward
	st.left = Vector3.LEFT
	st.up = Vector3.BACK
	st.depth = 0
	st.length = _BRK_STEP_LEN
	st.radius = _BRK_STROKE_RADIUS

	var stack: Array[BrkTurtle] = []

	# Current stroke being accumulated: parallel typed arrays of points + radii.
	var stroke_pts: Array[Vector3] = [st.pos]
	var stroke_radii: Array[float] = [st.radius]

	for ci: int in range(sentence.length()):
		if _brk_segment_count >= _BRK_MAX_SEGMENTS:
			break
		var ch: String = sentence[ci]
		match ch:
			"I", "J", "F":
				# Draw forward. Stem strokes (I/J) keep almost full radius (bold spine); flourish
				# strokes (F) taper hard so curls thin to a calligraphic nib.
				var is_stem: bool = (ch == "I" or ch == "J")
				var taper: float = 0.992 if is_stem else 0.88
				var np: Vector3 = st.pos + st.heading * st.length
				st.pos = np
				st.radius = maxf(st.radius * taper, 0.004)
				stroke_pts.append(np)
				stroke_radii.append(st.radius)
				_brk_segment_count += 1
			"+":
				_brk_yaw(st, yaw_rad)
			"-":
				_brk_yaw(st, -yaw_rad)
			"&":
				_brk_pitch(st, pitch_rad)
			"^":
				_brk_pitch(st, -pitch_rad)
			"\\":
				_brk_roll(st, roll_rad)
			"|":
				_brk_roll(st, -roll_rad)
			"<":
				# Shrink step length — makes a continuous curl tighten into a logarithmic spiral
				# WITHOUT a bracket, so the whole flourish flushes as ONE swept ribbon.
				st.length = maxf(st.length * _BRK_STEP_SHRINK, _BRK_STEP_LEN * 0.06)
			">":
				st.length = minf(st.length / _BRK_STEP_SHRINK, _BRK_STEP_LEN * 1.5)
			"!":
				# Thin the stroke (calligraphic taper inside a continuous curl).
				st.radius = maxf(st.radius * 0.82, 0.004)
				if stroke_radii.size() > 0:
					stroke_radii[stroke_radii.size() - 1] = st.radius
			"[":
				# Flush the current stroke up to the branch point, then push.
				_brk_flush_stroke(glyph, stroke_pts, stroke_radii, mat_ink)
				stack.append(_brk_copy_state(st))
				st.depth += 1
				st.length *= _BRK_STEP_DECAY
				st.radius *= _BRK_RADIUS_DECAY
				stroke_pts = [st.pos]
				stroke_radii = [st.radius]
			"]":
				_brk_flush_stroke(glyph, stroke_pts, stroke_radii, mat_ink)
				if stack.size() > 0:
					st = stack.pop_back()
				stroke_pts = [st.pos]
				stroke_radii = [st.radius]
			"}", "A", "B":
				# Flourish terminus: `}` an explicit tip; a leftover `A`/`B` is the UNEXPANDED tail
				# of a tightening spiral (the nib where recursion bottomed out). End the stroke and
				# place an illuminated glow node (rubrication) at the curl's end.
				_brk_flush_stroke(glyph, stroke_pts, stroke_radii, mat_ink)
				_brk_add_glow(glyph, st.pos, st.radius, mat_glow)
				stroke_pts = [st.pos]
				stroke_radii = [st.radius]
			"o":
				_brk_add_serif(glyph, st.pos, st.radius, mat_base)
			_:
				pass

	# Flush whatever stroke remains open.
	_brk_flush_stroke(glyph, stroke_pts, stroke_radii, mat_ink)


func _brk_copy_state(s: BrkTurtle) -> BrkTurtle:
	var c := BrkTurtle.new()
	c.pos = s.pos
	c.heading = s.heading
	c.left = s.left
	c.up = s.up
	c.depth = s.depth
	c.length = s.length
	c.radius = s.radius
	return c


# ── Turtle rotations: rotate the frame about an axis (Basis-based, no look_at) ──

func _brk_yaw(s: BrkTurtle, ang: float) -> void:
	var ax: Vector3 = s.up
	s.heading = s.heading.rotated(ax, ang).normalized()
	s.left = s.left.rotated(ax, ang).normalized()

func _brk_pitch(s: BrkTurtle, ang: float) -> void:
	var ax: Vector3 = s.left
	s.heading = s.heading.rotated(ax, ang).normalized()
	s.up = s.up.rotated(ax, ang).normalized()

func _brk_roll(s: BrkTurtle, ang: float) -> void:
	var ax: Vector3 = s.heading
	s.left = s.left.rotated(ax, ang).normalized()
	s.up = s.up.rotated(ax, ang).normalized()


## Flush an accumulated polyline into one tapered ink ribbon via MorphoPrimitive.multi_tube. The
## cross-section is flattened (z<x via the instance scale) so it reads as a calligraphic nib. A
## 1-point stroke is a no-op.
func _brk_flush_stroke(glyph: Node3D, pts: Array[Vector3], radii: Array[float], mat: Material) -> void:
	if pts.size() < 2:
		return
	var mesh: Mesh = MorphoPrimitive.multi_tube(pts, radii, _BRK_TUBE_SIDES)
	if mesh == null:
		return
	# Flatten along world Z via the instance basis (keeps the mesh untouched + deterministic).
	var xf := Transform3D(Basis().scaled(Vector3(1.0, 1.0, _BRK_RIBBON_FLATTEN)), Vector3.ZERO)
	_cg_add_mesh(glyph, mesh, mat, xf, "Stroke")


## Illuminated flourish tip (rubrication): a small gold glow bead sized to the stroke that produced
## it, so it reads as a glowing nib-end.
func _brk_add_glow(glyph: Node3D, pos: Vector3, radius: float, mat: Material) -> void:
	var r: float = clampf(radius * 1.25 + 0.006, 0.012, 0.032)
	_cg_add_mesh(glyph, MorphoPrimitive.sphere(r, 10, 6), mat,
		Transform3D(Basis.IDENTITY, pos), "GlowTip")


## Dot-serif: a small warm-stone bead punctuating the stroke (the `o` marker).
func _brk_add_serif(glyph: Node3D, pos: Vector3, radius: float, mat: Material) -> void:
	var r: float = clampf(radius * 1.1 + 0.008, 0.012, 0.032)
	_cg_add_mesh(glyph, MorphoPrimitive.sphere(r, 8, 5), mat,
		Transform3D(Basis.IDENTITY, pos), "Serif")


## A short squat inkwell (wide foot, pinched neck, flared lip) the glyph rises out of, via
## MorphoPrimitive.revolution. Profile points are (radius, height).
func _brk_build_inkwell(glyph: Node3D, mat: Material) -> void:
	var profile: Array[Vector2] = [
		Vector2(0.0, 0.0),
		Vector2(0.21, 0.0),
		Vector2(0.235, 0.035),
		Vector2(0.205, 0.10),
		Vector2(0.165, 0.155),
		Vector2(0.185, 0.195),     # flared lip
		Vector2(0.15, 0.205),
		Vector2(0.0, 0.205),       # cap the rim back to the axis (closed top)
	]
	_cg_add_mesh(glyph, MorphoPrimitive.revolution(profile, 28), mat,
		Transform3D.IDENTITY, "Inkwell")


## Centre + scale the grown glyph so it stands at the target height with a yaw that turns its
## widest asymmetric profile toward the +X/+Z capture camera. Uses the shared settle (floor to y=0)
## then adds the presentation yaw.
func _brk_frame_glyph(glyph: Node3D) -> void:
	_cg_settle(glyph, maxf(_BRK_TARGET_HEIGHT * (sculpt_height / 1.6), 0.4),
		maxf(sculpt_width, 0.2), true)
	glyph.rotate_y(deg_to_rad(-32.0))


# =============================================================================
# MODE: glyphgraph — a GLYPH NETWORK with a minimum spanning tree (trial v3)
#
# The genuine algorithm (graph theory + Prim's MST, the load-bearing core):
#   N glyph-NODES (small stone discs each bearing a raised asemic mark) are laid out on a gentle
#   dome, connected by weighted EDGES. The layout seeds a structured interior (hub + concentric
#   jittered rings) then runs a RADIUS-ANCHORED repulsion relaxation (even angular spacing without
#   the rim-collapse a pure repulsion gives). Edges are each node's k-NEAREST neighbours
#   (undirected, de-duplicated), and UNION-FIND bridging adds the cheapest cross-component edge
#   until the graph is ONE component (so the MST spans every node). Over the connected weighted
#   graph we RUN PRIM'S algorithm — grow the tree from node 0, each step adding the cheapest edge
#   joining a tree node to a non-tree node — and HIGHLIGHT the minimum spanning tree: its edges
#   thicken and glow (arced up over multi-point splines), every other edge stays a dim ink thread,
#   and the MST nodes get glowing halos. Edges are MorphoPrimitive.multi_tube (own frame, no
#   look_at), batched into TWO meshes (dim + glow). complexity scales the NODE COUNT (9..16).
#   The whole graph, its layout, and the MST are deterministic from the seeded RNG.
# =============================================================================

const _GRAPH_SPAN: float = 1.15            # planar radius of the network disc
const _GRAPH_DOME_RISE: float = 0.55       # how much the dome lifts central nodes
const _GRAPH_BASE_Y: float = 0.30          # lift whole network off the plinth
const _GRAPH_K_NEAREST: int = 4            # candidate edges per node (k-NN)
const _GRAPH_LAYOUT_ITERS: int = 140       # force-directed relaxation passes
const _GRAPH_NODE_DISC_R: float = 0.135    # planar radius of a glyph disc
const _GRAPH_EDGE_R_DIM: float = 0.009     # non-tree edge tube radius (quiet)
const _GRAPH_EDGE_R_MST: float = 0.026     # MST edge tube radius (thick, dominant)

# Graph state (all typed).
var _graph_nodes: Array[Vector3] = []          # node local positions
var _graph_edges: Array[Vector2i] = []         # undirected edges (i<j)
var _graph_edge_weights: Array[float] = []     # weight per edge (= length)
var _graph_edge_in_mst: Array[bool] = []       # highlight flag per edge
var _graph_node_in_mst: Array[bool] = []       # node touched by the tree


func _build_glyphgraph() -> void:
	# Reset graph state for this build (idempotent).
	_graph_nodes.clear()
	_graph_edges.clear()
	_graph_edge_weights.clear()
	_graph_edge_in_mst.clear()
	_graph_node_in_mst.clear()

	var mat_disc := _cg_substrate_mat(color_a)
	var mat_ink := _cg_ink_mat(color_b)
	# Dim non-tree edges: ink, cooled slightly so the glowing MST reads against it.
	var mat_edge_dim := _cg_ink_mat(color_b.lerp(Color(0.30, 0.30, 0.36), 0.35))
	# MST highlight + node halos: the accent glow (cyan if the DNA sets accent to cyan; gold by
	# default — either way this is the spanning-tree's burn).
	var mat_glow := _cg_glow_mat(accent, 3.5)
	# Faint base plinth: substrate, dimmer + rougher.
	var mat_plinth := _cg_substrate_mat(color_a.lerp(color_b, 0.18))

	# Node count scales with complexity (9..16).
	var cnorm: float = clampf(float(complexity) / 12.0, 0.0, 1.0)
	var n: int = int(round(lerpf(9.0, 16.0, cnorm)))

	# 1) Lay out nodes (seeded scatter + radius-anchored relaxation, on a dome).
	_graph_layout_nodes(n)
	# 2) Build a connected weighted graph (k-NN + union-find component bridging).
	_graph_build_edges()
	# 3) Run Prim's MST and flag the highlighted edges + nodes.
	_graph_compute_mst()

	# Whole network tips a little toward the +X/+Z capture camera so the dome's luminous tree reads.
	var net := Node3D.new()
	net.name = "GlyphNetwork"
	net.basis = Basis().rotated(Vector3(1.0, 0.0, -1.0).normalized(), deg_to_rad(10.0))
	add_child(net)

	_graph_build_plinth(net, mat_plinth)
	_graph_build_edges_mesh(net, mat_edge_dim, mat_glow)
	for i: int in range(n):
		_graph_build_node(net, i, mat_disc, mat_ink, mat_glow)

	# Centre the floating specimen around its own centroid (it sits on its own stem).
	_cg_settle(net, maxf(sculpt_height, 0.4), maxf(sculpt_width, 0.2), false)


## Height of the layout dome at planar radius r in [0, SPAN]: lifts the centre, eases to the rim.
func _graph_dome_height(r: float) -> float:
	var rr: float = clampf(r / _GRAPH_SPAN, 0.0, 1.0)
	return _GRAPH_BASE_Y + _GRAPH_DOME_RISE * 0.5 * (cos(rr * PI) + 1.0)


## Lay out N nodes so they genuinely FILL the disc interior (not a rim ring): a hub node, then the
## rest over concentric jittered rings whose radii step outward (guaranteed inner AND outer nodes).
## A radius-anchored repulsion relaxation evens the spacing without collapsing the interior; each is
## then lifted onto the dome. Fills _graph_nodes.
func _graph_layout_nodes(n: int) -> void:
	var planar: Array[Vector2] = []
	# Hub at (near) centre.
	planar.append(Vector2(
		_rng.randf_range(-_GRAPH_SPAN * 0.06, _GRAPH_SPAN * 0.06),
		_rng.randf_range(-_GRAPH_SPAN * 0.06, _GRAPH_SPAN * 0.06)))
	var remaining: int = n - 1
	var ring_count: int = maxi(2, int(round(sqrt(float(remaining)))))
	var band_r: Array[float] = [0.0]           # hub's band radius (index 0)
	var placed: int = 0
	for ri: int in range(ring_count):
		var rings_left: int = ring_count - ri
		var nodes_left: int = remaining - placed
		var ideal: int = int(round(float(nodes_left) / float(rings_left)))
		var on_ring: int = maxi(1, ideal)
		if ri == ring_count - 1:
			on_ring = nodes_left
		var base_r: float = _GRAPH_SPAN * lerpf(0.40, 0.90, float(ri) / float(maxi(ring_count - 1, 1)))
		var phase: float = _rng.randf_range(0.0, TAU)
		for k2: int in range(on_ring):
			if placed >= remaining:
				break
			var ang: float = phase + TAU * float(k2) / float(on_ring)
			ang += _rng.randf_range(-0.18, 0.18)
			var rad: float = base_r + _rng.randf_range(-_GRAPH_SPAN * 0.05, _GRAPH_SPAN * 0.05)
			rad = clampf(rad, _GRAPH_SPAN * 0.22, _GRAPH_SPAN * 0.94)
			planar.append(Vector2(cos(ang), sin(ang)) * rad)
			band_r.append(rad)
			placed += 1

	# Radius-anchored relaxation: repel for even ANGULAR spacing, then restore each node's seeded
	# band radius (the hub damps toward centre). This preserves the interior bands.
	var k_ideal: float = _GRAPH_SPAN * 0.40
	var step: float = _GRAPH_SPAN * 0.045
	for _iter: int in range(_GRAPH_LAYOUT_ITERS):
		var disp: Array[Vector2] = []
		for _i: int in range(n):
			disp.append(Vector2.ZERO)
		for i: int in range(n):
			for j: int in range(i + 1, n):
				var delta: Vector2 = (planar[i] as Vector2) - (planar[j] as Vector2)
				var dist: float = maxf(delta.length(), 0.001)
				var force: float = minf((k_ideal * k_ideal) / (dist * dist), 5.0) * k_ideal * 0.5
				var dir: Vector2 = delta / dist
				disp[i] = (disp[i] as Vector2) + dir * force
				disp[j] = (disp[j] as Vector2) - dir * force
		for i3: int in range(n):
			var d: Vector2 = disp[i3] as Vector2
			var dl: float = maxf(d.length(), 0.001)
			var move: Vector2 = (d / dl) * minf(dl, step)
			var np: Vector2 = (planar[i3] as Vector2) + move
			var target_r: float = band_r[i3] as float
			if target_r < 0.001:
				np = np * 0.5
			else:
				var ang2: float = atan2(np.y, np.x)
				np = Vector2(cos(ang2), sin(ang2)) * target_r
			planar[i3] = np
		step = maxf(step * 0.985, _GRAPH_SPAN * 0.006)

	# Lift onto the dome.
	_graph_nodes.clear()
	for p2: Vector2 in planar:
		var y: float = _graph_dome_height(p2.length())
		_graph_nodes.append(Vector3(p2.x, y, p2.y))


## Build a connected weighted graph: each node links to its K_NEAREST neighbours (undirected,
## de-duplicated, i<j; weight = Euclidean length); then union-find bridging guarantees one component.
func _graph_build_edges() -> void:
	var n: int = _graph_nodes.size()
	var seen: Dictionary = {}
	_graph_edges.clear()
	_graph_edge_weights.clear()

	for i: int in range(n):
		var order: Array[int] = _graph_neighbours_by_distance(i)
		var added: int = 0
		for j: int in order:
			if added >= _GRAPH_K_NEAREST:
				break
			var a: int = mini(i, j)
			var b: int = maxi(i, j)
			var key: String = "%d_%d" % [a, b]
			if seen.has(key):
				continue
			seen[key] = true
			_graph_edges.append(Vector2i(a, b))
			_graph_edge_weights.append((_graph_nodes[a] as Vector3).distance_to(_graph_nodes[b] as Vector3))
			added += 1

	_graph_ensure_connected(seen)


## Indices of all other nodes sorted by ascending distance from node `i`.
func _graph_neighbours_by_distance(i: int) -> Array[int]:
	var pi: Vector3 = _graph_nodes[i] as Vector3
	var idxs: Array[int] = []
	for j: int in range(_graph_nodes.size()):
		if j != i:
			idxs.append(j)
	idxs.sort_custom(func(a: int, b: int) -> bool:
		var da: float = pi.distance_to(_graph_nodes[a] as Vector3)
		var db: float = pi.distance_to(_graph_nodes[b] as Vector3)
		return da < db)
	return idxs


## Union-find connect: while more than one component exists, add the cheapest edge joining two
## different components. Guarantees a spanning MST.
func _graph_ensure_connected(seen: Dictionary) -> void:
	var n: int = _graph_nodes.size()
	var parent: Array[int] = []
	for i: int in range(n):
		parent.append(i)
	for e: Vector2i in _graph_edges:
		_graph_union(parent, e.x, e.y)
	var guard: int = 0
	while _graph_component_count(parent) > 1 and guard < n * n:
		guard += 1
		var best_w: float = INF
		var best_a: int = -1
		var best_b: int = -1
		for i: int in range(n):
			for j: int in range(i + 1, n):
				if _graph_find(parent, i) == _graph_find(parent, j):
					continue
				var w: float = (_graph_nodes[i] as Vector3).distance_to(_graph_nodes[j] as Vector3)
				if w < best_w:
					best_w = w
					best_a = i
					best_b = j
		if best_a < 0:
			break
		var key: String = "%d_%d" % [best_a, best_b]
		if not seen.has(key):
			seen[key] = true
			_graph_edges.append(Vector2i(best_a, best_b))
			_graph_edge_weights.append(best_w)
		_graph_union(parent, best_a, best_b)


func _graph_find(parent: Array[int], x: int) -> int:
	var root: int = x
	while parent[root] != root:
		root = parent[root]
	var cur: int = x
	while parent[cur] != root:
		var nxt: int = parent[cur]
		parent[cur] = root
		cur = nxt
	return root


func _graph_union(parent: Array[int], a: int, b: int) -> void:
	var ra: int = _graph_find(parent, a)
	var rb: int = _graph_find(parent, b)
	if ra != rb:
		parent[rb] = ra


func _graph_component_count(parent: Array[int]) -> int:
	var roots: Dictionary = {}
	for i: int in range(parent.size()):
		roots[_graph_find(parent, i)] = true
	return roots.size()


## Run Prim's algorithm: grow the tree from node 0, each step adding the cheapest edge connecting a
## tree node to a non-tree node. Marks _graph_edge_in_mst + _graph_node_in_mst. Because the graph is
## connected, the result is a true MST spanning all nodes.
func _graph_compute_mst() -> void:
	var n: int = _graph_nodes.size()
	_graph_edge_in_mst.clear()
	_graph_node_in_mst.clear()
	for _e: int in range(_graph_edges.size()):
		_graph_edge_in_mst.append(false)
	for _v: int in range(n):
		_graph_node_in_mst.append(false)
	if n == 0:
		return

	# Adjacency: per node, list of (other_node, edge_index).
	var adj: Array = []
	for _i: int in range(n):
		adj.append([] as Array)
	for ei: int in range(_graph_edges.size()):
		var e: Vector2i = _graph_edges[ei]
		(adj[e.x] as Array).append(Vector2i(e.y, ei))
		(adj[e.y] as Array).append(Vector2i(e.x, ei))

	var in_tree: Array[bool] = []
	for _t: int in range(n):
		in_tree.append(false)

	in_tree[0] = true
	_graph_node_in_mst[0] = true
	var tree_size: int = 1

	# Simple O(V*E) Prim — fine for N<=16. Each round scans every frontier edge.
	while tree_size < n:
		var best_w: float = INF
		var best_edge: int = -1
		var best_new: int = -1
		for v: int in range(n):
			if not in_tree[v]:
				continue
			for pair_v: Variant in adj[v]:
				var pair: Vector2i = pair_v as Vector2i
				var other: int = pair.x
				var edge_idx: int = pair.y
				if in_tree[other]:
					continue
				var w: float = _graph_edge_weights[edge_idx]
				if w < best_w:
					best_w = w
					best_edge = edge_idx
					best_new = other
		if best_edge < 0:
			break        # disconnected guard (shouldn't happen)
		_graph_edge_in_mst[best_edge] = true
		in_tree[best_new] = true
		_graph_node_in_mst[best_new] = true
		tree_size += 1


## Build one node: a stone disc (revolution) with a dark ink rim, topped by a raised asemic glyph
## (a few batched multi_tube strokes). MST nodes get a glowing halo torus.
func _graph_build_node(parent: Node3D, idx: int, mat_disc: Material, mat_ink: Material,
		mat_glow: Material) -> void:
	var pos: Vector3 = _graph_nodes[idx] as Vector3
	var basis: Basis = _cg_basis_from_up(Vector3.UP)

	# Disc plaque: revolution of a shallow puck profile (face on top).
	var disc_h: float = _GRAPH_NODE_DISC_R * 0.34
	var disc_profile: Array[Vector2] = [
		Vector2(0.0, 0.0),
		Vector2(_GRAPH_NODE_DISC_R * 0.96, 0.0),
		Vector2(_GRAPH_NODE_DISC_R * 1.00, disc_h * 0.35),
		Vector2(_GRAPH_NODE_DISC_R * 0.94, disc_h),
		Vector2(_GRAPH_NODE_DISC_R * 0.62, disc_h),
		Vector2(0.0, disc_h),
	]
	_cg_add_mesh(parent, MorphoPrimitive.revolution(disc_profile, 22), mat_disc,
		Transform3D(basis, pos), "NodeDisc")

	# Ink rim: a thin torus hugging the disc crest.
	_cg_add_mesh(parent, MorphoPrimitive.torus(_GRAPH_NODE_DISC_R * 0.92, _GRAPH_NODE_DISC_R * 1.02, 8, 20),
		mat_ink, Transform3D(basis, pos + basis.y * disc_h), "NodeRim")

	# Raised asemic glyph: a few ink strokes batched into one mesh on the disc top face.
	var glyph_mesh: ArrayMesh = _graph_build_glyph_mesh(idx, disc_h)
	if glyph_mesh != null:
		_cg_add_mesh(parent, glyph_mesh, mat_ink, Transform3D(basis, pos), "NodeGlyph")

	# MST node illumination: a glowing halo torus.
	if _graph_node_in_mst[idx]:
		_cg_add_mesh(parent, MorphoPrimitive.torus(_GRAPH_NODE_DISC_R * 1.06, _GRAPH_NODE_DISC_R * 1.20, 8, 22),
			mat_glow, Transform3D(basis, pos + basis.y * (disc_h * 0.5)), "NodeHalo")


## Build a small asemic glyph for node `idx` as a batch of raised ink strokes on the disc top face.
## Each stroke is a short multi_tube along a seeded poly-line (per-node sub-RNG so each glyph differs
## yet the piece stays deterministic). Strokes are merged into one ArrayMesh via _cg_merge_into.
func _graph_build_glyph_mesh(idx: int, top_y: float) -> ArrayMesh:
	var grng := RandomNumberGenerator.new()
	grng.seed = seed * 1000 + idx * 17 + 3

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var stroke_r: float = _GRAPH_NODE_DISC_R * 0.062
	var lift: float = top_y + stroke_r * 0.6
	var n_strokes: int = 2 + (grng.randi() % 3)     # 2..4 marks per glyph
	var reach: float = _GRAPH_NODE_DISC_R * 0.48
	var emitted: bool = false

	for _s: int in range(n_strokes):
		var pts: int = 3 + (grng.randi() % 2)       # 3..4 control points
		var positions: Array[Vector3] = []
		var radii: Array[float] = []
		var cur := Vector2(grng.randf_range(-reach, reach), grng.randf_range(-reach, reach))
		var heading: float = grng.randf_range(0.0, TAU)
		for pidx: int in range(pts):
			if cur.length() > reach:
				cur = cur.normalized() * reach
			positions.append(Vector3(cur.x, lift, cur.y))
			var t: float = float(pidx) / float(maxi(pts - 1, 1))
			radii.append(stroke_r * lerpf(1.0, 0.55, t))
			heading += grng.randf_range(-1.1, 1.1)
			var step_len: float = _GRAPH_NODE_DISC_R * grng.randf_range(0.22, 0.40)
			cur += Vector2(cos(heading), sin(heading)) * step_len
		var stroke_mesh: Mesh = MorphoPrimitive.multi_tube(positions, radii, 5)
		if stroke_mesh != null:
			_cg_merge_into(st, stroke_mesh)
			emitted = true

	if not emitted:
		return null
	return st.commit()


## Build the two edge meshes (dim non-tree threads + glowing MST arcs). multi_tube builds its own
## frame from the endpoints (no look_at); edges are merged into one of two SurfaceTools and committed
## once each. MST edges inset to the disc rim and arc UP over a 4-point spline so the skeleton floats
## above the flat dim web; dim edges are thin straight threads tucked just under disc level.
func _graph_build_edges_mesh(parent: Node3D, mat_dim: Material, mat_glow: Material) -> void:
	var dim_st := SurfaceTool.new()
	dim_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mst_st := SurfaceTool.new()
	mst_st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for ei: int in range(_graph_edges.size()):
		var e: Vector2i = _graph_edges[ei]
		var a: Vector3 = _graph_nodes[e.x] as Vector3
		var b: Vector3 = _graph_nodes[e.y] as Vector3
		var dir: Vector3 = (b - a).normalized()
		var span_len: float = a.distance_to(b)

		if _graph_edge_in_mst[ei]:
			var inset_m: float = _GRAPH_NODE_DISC_R * 0.80
			var pa: Vector3 = a + dir * inset_m + Vector3(0.0, _GRAPH_NODE_DISC_R * 0.10, 0.0)
			var pb: Vector3 = b - dir * inset_m + Vector3(0.0, _GRAPH_NODE_DISC_R * 0.10, 0.0)
			if pa.distance_to(pb) < 0.01:
				continue
			var arc_h: float = clampf(span_len * 0.24, _GRAPH_NODE_DISC_R * 0.30, _GRAPH_SPAN * 0.34)
			var q1: Vector3 = pa.lerp(pb, 0.30) + Vector3(0.0, arc_h * 0.82, 0.0)
			var q2: Vector3 = pa.lerp(pb, 0.70) + Vector3(0.0, arc_h * 0.82, 0.0)
			var positions: Array[Vector3] = [pa, q1, q2, pb]
			var radii: Array[float] = [_GRAPH_EDGE_R_MST * 0.80, _GRAPH_EDGE_R_MST, _GRAPH_EDGE_R_MST, _GRAPH_EDGE_R_MST * 0.80]
			var m: Mesh = MorphoPrimitive.multi_tube(positions, radii, 9)
			if m != null:
				_cg_merge_into(mst_st, m)
		else:
			var inset_d: float = _GRAPH_NODE_DISC_R * 0.70
			var pa2: Vector3 = a + dir * inset_d - Vector3(0.0, _GRAPH_NODE_DISC_R * 0.04, 0.0)
			var pb2: Vector3 = b - dir * inset_d - Vector3(0.0, _GRAPH_NODE_DISC_R * 0.04, 0.0)
			if pa2.distance_to(pb2) < 0.01:
				continue
			var positions2: Array[Vector3] = [pa2, pb2]
			var radii2: Array[float] = [_GRAPH_EDGE_R_DIM, _GRAPH_EDGE_R_DIM]
			var m2: Mesh = MorphoPrimitive.multi_tube(positions2, radii2, 6)
			if m2 != null:
				_cg_merge_into(dim_st, m2)

	_cg_commit_batch(parent, dim_st, mat_dim, "EdgesDim", false)
	_cg_commit_batch(parent, mst_st, mat_glow, "EdgesMST", false)


## A slim central stem + foot so the network reads as a floating specimen on a stand (no wide disc
## to occlude the edges). Foot = a low revolution disc; stem = a slender multi_tube column.
func _graph_build_plinth(parent: Node3D, mat: Material) -> void:
	var foot_r: float = _GRAPH_SPAN * 0.34
	var foot_h: float = 0.05
	var foot_profile: Array[Vector2] = [
		Vector2(0.0, 0.0),
		Vector2(foot_r * 0.95, 0.0),
		Vector2(foot_r, foot_h * 0.5),
		Vector2(foot_r * 0.82, foot_h),
		Vector2(0.0, foot_h),
	]
	_cg_add_mesh(parent, MorphoPrimitive.revolution(foot_profile, 36), mat,
		Transform3D.IDENTITY, "PedestalFoot")

	var stem_top: float = _graph_dome_height(0.0) - _GRAPH_NODE_DISC_R * 0.3
	var positions: Array[Vector3] = [
		Vector3(0.0, foot_h, 0.0),
		Vector3(0.0, stem_top * 0.55, 0.0),
		Vector3(0.0, stem_top, 0.0),
	]
	var radii: Array[float] = [_GRAPH_SPAN * 0.060, _GRAPH_SPAN * 0.040, _GRAPH_SPAN * 0.030]
	_cg_add_mesh(parent, MorphoPrimitive.multi_tube(positions, radii, 10), mat,
		Transform3D.IDENTITY, "PedestalStem")


# =============================================================================
# MODE: codexcolumn — a STELE of generative cursive asemic script (trial v4)
#
# The genuine algorithm (a noise-driven generative pen-walk, the load-bearing core):
#   A pen starts at the left margin of a line and walks rightward. At each step it advances in x
#   and sets y from: a slow cursive SINE undulation (the handwriting baseline bob) + layered value-
#   NOISE wiggle (organic tremor) + a smooth cosine ASCENDER/DESCENDER bump (tall letters l/h, deep
#   tails g/y). Periodically the pen draws a LOOP (a small circle excursion — the cursive bowl of an
#   o/e). At WORD-GAPS the pen LIFTS (the current stroke ends; a new one begins after a blank gap),
#   so each line is a sequence of connected word-strokes. Every value comes from a per-line sub-
#   seeded RNG (deterministic) + a deterministic value-noise table (no global noise). The walk is
#   bounded by the line width, so it always terminates. Each word-stroke polyline is swept into a
#   calligraphic INK ribbon via MorphoSweep.sweep (ellipse profile -> flat pen nib; Catmull-Rom path
#   Callable over BAKED points; pulse + tapered-ends radius Callable -> thick/thin). All strokes of a
#   line BATCH into one ArrayMesh. A large ILLUMINATED INITIAL (gold) + a margin glow dot open the
#   page. complexity scales the LINE COUNT. Deterministic from seed.
# =============================================================================

const _COL_STELE_W: float = 1.60          # slab width (x)
const _COL_STELE_H: float = 2.30          # slab height (y)
const _COL_STELE_T: float = 0.16          # slab thickness (z)
const _COL_STELE_TILT_DEG: float = 8.0    # lean back from vertical, toward camera
const _COL_BASE_LINE_COUNT: int = 6       # lines of handwriting at complexity 6
const _COL_MARGIN_X: float = 0.20         # left/right margin inset
const _COL_TOP_INSET: float = 0.42        # space above first line (for the initial)
const _COL_BOT_INSET: float = 0.26        # space below last line
const _COL_RELIEF: float = 0.045          # how proud the ink stands off the face
const _COL_INK_RADIUS: float = 0.0125     # base ink ribbon radius (calligraphic)
const _COL_STEP_X: float = 0.018          # pen advance per step along x
const _COL_SINE_AMP: float = 0.018        # baseline undulation amplitude
const _COL_SINE_FREQ: float = 9.0         # undulations across a line
const _COL_NOISE_AMP: float = 0.013       # tremor amplitude
const _COL_WORD_MIN: int = 8              # min steps per word-stroke
const _COL_WORD_MAX: int = 26             # max steps per word-stroke
const _COL_GAP_STEPS: int = 2             # blank steps between words (pen lift)
const _COL_LOOP_CHANCE: float = 0.62      # per-word chance to draw a cursive loop
const _COL_ASC_CHANCE: float = 0.34       # per-word chance of an ascender/descender bump

# Deterministic 1D value-noise table (seeded once per page).
var _col_noise_table: PackedFloat32Array
var _col_stroke_count: int = 0


func _build_codexcolumn() -> void:
	_col_stroke_count = 0
	var mat_parchment := _cg_substrate_mat(color_a)
	var mat_ink := _cg_ink_mat(color_b)
	var mat_gold := _cg_glow_mat(accent, 2.8)

	# The whole stele leans back slightly so its written face tips toward the +X/+Z camera. Basis only.
	var tilt := Basis().rotated(Vector3.RIGHT, deg_to_rad(-_COL_STELE_TILT_DEG))
	var stele := Node3D.new()
	stele.name = "Stele"
	stele.basis = tilt
	add_child(stele)

	# Slab.
	_cg_add_mesh(stele, MorphoPrimitive.box(Vector3(_COL_STELE_W, _COL_STELE_H, _COL_STELE_T)),
		mat_parchment, Transform3D.IDENTITY, "Slab")

	# Face plane: front of the slab + relief so ink stands proud.
	var face_z: float = _COL_STELE_T * 0.5 + _COL_RELIEF

	# Seed the value-noise table once for the whole page.
	_col_seed_noise_table(96)

	# Lines of cursive script; count scales with complexity (clamped so the stele stays legible).
	var line_count: int = clampi(_COL_BASE_LINE_COUNT + (complexity - 6), 4, 9)
	var top_y: float = _COL_STELE_H * 0.5 - _COL_TOP_INSET
	var bot_y: float = -_COL_STELE_H * 0.5 + _COL_BOT_INSET
	for li: int in range(line_count):
		var frac: float = float(li) / float(maxi(line_count - 1, 1))
		var baseline_y: float = lerpf(top_y, bot_y, frac)
		var line_seed: int = seed + 1000 + li * 97
		_col_build_line(stele, baseline_y, face_z, line_seed, li, mat_ink)

	# Illuminated initial + marginal glow (manuscript flourish).
	_col_build_illumination(stele, top_y, face_z, mat_gold)

	# Lift so the base sits near y=0, then settle (standing stele leans toward camera).
	stele.position = Vector3(0.0, _COL_STELE_H * 0.5, 0.0)
	_cg_settle(stele, maxf(sculpt_height, 0.4), maxf(sculpt_width, 0.2), true)


# ── value-noise: deterministic 1D smooth noise from the seeded RNG ──

func _col_seed_noise_table(n: int) -> void:
	_col_noise_table = PackedFloat32Array()
	for i: int in range(n):
		_col_noise_table.append(_rng.randf_range(-1.0, 1.0))


## Smoothly-interpolated noise at a continuous position t (in table units).
func _col_value_noise(t: float) -> float:
	var n: int = _col_noise_table.size()
	if n < 2:
		return 0.0
	var ft: float = fposmod(t, float(n))
	var i0: int = int(floor(ft))
	var i1: int = (i0 + 1) % n
	var frac: float = ft - float(i0)
	var smooth: float = (1.0 - cos(frac * PI)) * 0.5
	return lerpf(_col_noise_table[i0], _col_noise_table[i1], smooth)


## Walk a pen left->right across one line, returning an Array of word-strokes (each a typed
## Array[Vector3] polyline in stele-local space on the face plane). The pen LIFTS at word-gaps, so
## words are separate strokes. baseline_y is the line's vertical centre; line_seed seeds this line's
## own RNG. The loop is bounded by x_end so it always terminates.
func _col_walk_line(baseline_y: float, face_z: float, line_seed: int) -> Array:
	var line_rng := RandomNumberGenerator.new()
	line_rng.seed = line_seed

	var noise_phase: float = line_rng.randf_range(0.0, 100.0)
	var sine_phase: float = line_rng.randf_range(0.0, TAU)

	var words: Array = []
	var x: float = -_COL_STELE_W * 0.5 + _COL_MARGIN_X
	var x_end: float = _COL_STELE_W * 0.5 - _COL_MARGIN_X
	var step_idx: int = 0

	while x < x_end:
		var word_len: int = line_rng.randi_range(_COL_WORD_MIN, _COL_WORD_MAX)
		var stroke: Array[Vector3] = []

		# Decide up front (baked locals) where loops sit, so values are fixed before any sweep
		# Callable closes over them. A word may carry several cursive loops.
		var loop_steps_set: Dictionary = {}
		var n_loops: int = 0
		if line_rng.randf() < _COL_LOOP_CHANCE:
			n_loops = 1 + (line_rng.randi() % 2)            # 1..2 loops
		for _li: int in range(n_loops):
			var at: int = line_rng.randi_range(1, maxi(1, word_len - 2))
			loop_steps_set[at] = {
				"dir": 1.0 if line_rng.randf() < 0.6 else -1.0,
				"radius": lerpf(0.014, 0.026, line_rng.randf()),
			}

		# An ascender/descender is a SMOOTH cosine bump over a window of steps. Decide its centre,
		# half-width and signed height once per word (baked locals).
		var has_asc: bool = line_rng.randf() < _COL_ASC_CHANCE
		var asc_center: int = line_rng.randi_range(1, maxi(1, word_len - 2))
		var asc_half: int = line_rng.randi_range(1, 3)
		var asc_sign: float = 1.0 if line_rng.randf() < 0.55 else -1.0
		var asc_height: float = asc_sign * lerpf(0.040, 0.075, line_rng.randf())

		for s: int in range(word_len):
			if x >= x_end:
				break
			var sine_y: float = sin(x * _COL_SINE_FREQ + sine_phase) * _COL_SINE_AMP
			var noise_y: float = _col_value_noise(float(step_idx) * 0.55 + noise_phase) * _COL_NOISE_AMP
			noise_y += _col_value_noise(float(step_idx) * 1.5 + noise_phase + 13.0) * _COL_NOISE_AMP * 0.45

			var bump: float = 0.0
			if has_asc:
				var d: int = absi(s - asc_center)
				if d <= asc_half:
					var w_frac: float = float(d) / float(asc_half + 1)
					bump = asc_height * (0.5 + 0.5 * cos(w_frac * PI))   # 1 at centre -> 0 at edge

			var y: float = baseline_y + sine_y + noise_y + bump
			stroke.append(Vector3(x, y, face_z))

			# Draw any cursive loop scheduled at this step (small circle excursion).
			if loop_steps_set.has(s):
				var lp: Dictionary = loop_steps_set[s]
				_col_append_loop(stroke, x, y, face_z, lp["radius"] as float, lp["dir"] as float)

			x += _COL_STEP_X
			step_idx += 1

		if stroke.size() >= 2:
			words.append(stroke)

		# Word-gap: lift the pen, advance a blank gap before the next word.
		x += _COL_STEP_X * float(_COL_GAP_STEPS)
		step_idx += _COL_GAP_STEPS

	return words


## Append a small circular LOOP to the current stroke (the cursive bowl of an o/e or the loop of an
## l), starting and ending near the pen's current position so the following stroke continues smoothly.
func _col_append_loop(stroke: Array[Vector3], x: float, y: float, face_z: float,
		radius: float, direction: float) -> void:
	var cx: float = x + radius * 0.5
	var cy: float = y + radius * direction
	var loop_steps: int = 12
	for li: int in range(1, loop_steps + 1):
		var a: float = lerpf(-PI * 0.5, PI * 1.4, float(li) / float(loop_steps))
		var lx: float = cx + cos(a) * radius
		var ly: float = cy + sin(a) * radius * direction
		stroke.append(Vector3(lx, ly, face_z))


## Build one line of script: walk the pen, sweep each word-stroke, batch them all into a single
## ArrayMesh, add it as one MeshInstance3D.
func _col_build_line(parent: Node3D, baseline_y: float, face_z: float,
		line_seed: int, line_index: int, mat: Material) -> void:
	var words: Array = _col_walk_line(baseline_y, face_z, line_seed)
	if words.is_empty():
		return

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Per-line RNG for stroke thickness jitter — separate from the walk RNG so geometry stays
	# deterministic regardless of call order.
	var jit := RandomNumberGenerator.new()
	jit.seed = line_seed + 555

	for w: Variant in words:
		var stroke: Array[Vector3] = w as Array[Vector3]
		var thick: float = _COL_INK_RADIUS * jit.randf_range(0.82, 1.18)
		var pulse_phase: float = jit.randf_range(0.0, TAU)
		var stroke_mesh: Mesh = _col_sweep_stroke(stroke, thick, pulse_phase)
		if stroke_mesh != null:
			_cg_merge_into(st, stroke_mesh)
			_col_stroke_count += 1

	_cg_commit_batch(parent, st, mat, "Line_%d" % line_index, true)


## Sweep an ink ribbon along a polyline word-stroke via MorphoSweep.sweep. The path Callable
## interpolates the BAKED points with Catmull-Rom so cursive curves stay smooth; the radius Callable
## gives calligraphic thick/thin (pulse + tapered ends). Returns the swept Mesh (or null if short).
## Seeded geometry is BAKED into a local copy before the Callables close over it (no late RNG reads).
func _col_sweep_stroke(points: Array[Vector3], thickness: float, pulse_phase: float) -> Mesh:
	if points.size() < 2:
		return null

	var baked: Array[Vector3] = points.duplicate()
	var n: int = baked.size()

	var path_func := func(t: float) -> Vector3:
		var ft: float = clampf(t, 0.0, 1.0) * float(n - 1)
		var i1: int = clampi(int(floor(ft)), 0, n - 1)
		var i2: int = mini(i1 + 1, n - 1)
		var i0: int = maxi(i1 - 1, 0)
		var i3: int = mini(i2 + 1, n - 1)
		var frac: float = ft - float(i1)
		var p0: Vector3 = baked[i0]
		var p1: Vector3 = baked[i1]
		var p2: Vector3 = baked[i2]
		var p3: Vector3 = baked[i3]
		var f2: float = frac * frac
		var f3: float = f2 * frac
		return 0.5 * (
			(2.0 * p1)
			+ (-p0 + p2) * frac
			+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * f2
			+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * f3)

	var base_r: float = thickness
	var rad_func := func(t: float) -> float:
		var taper: float = sin(clampf(t, 0.0, 1.0) * PI)            # 0->1->0 ends
		var ends: float = lerpf(0.45, 1.0, clampf(taper * 3.0, 0.0, 1.0))
		var pulse: float = 1.0 + 0.35 * sin(t * TAU * 3.0 + pulse_phase)
		return base_r * ends * pulse

	var segs: int = clampi(n * 4, 24, 320)
	var profile: Array[Vector2] = MorphoSweep.profile_ellipse(8, 0.55)
	return MorphoSweep.sweep(profile, path_func, rad_func, 0.0, segs, false)


## A large ILLUMINATED INITIAL opening the page + a small marginal glow dot — both gold, near-
## unshaded, like gilded manuscript decoration.
func _col_build_illumination(parent: Node3D, top_y: float, face_z: float, mat: Material) -> void:
	var ix: float = -_COL_STELE_W * 0.5 + _COL_MARGIN_X * 0.6
	var iy: float = top_y + 0.16
	var initial_mesh: ArrayMesh = _col_build_initial_glyph(ix, iy, face_z + 0.02)
	if initial_mesh != null:
		_cg_add_mesh(parent, initial_mesh, mat, Transform3D.IDENTITY, "IlluminatedInitial")

	_cg_add_mesh(parent, MorphoPrimitive.sphere(0.028, 10, 6), mat,
		Transform3D(Basis.IDENTITY, Vector3(-_COL_STELE_W * 0.5 + _COL_MARGIN_X * 0.5,
			-_COL_STELE_H * 0.5 + _COL_BOT_INSET * 0.5, face_z + 0.02)), "MarginGlow")


## Build a chunky illuminated initial as a few thick gold ribbon strokes welded together — a bold
## asemic capital (a descending vertical spine + a bowl), swept thick. Deterministic (fixed glyph).
func _col_build_initial_glyph(ox: float, oy: float, face_z: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var h: float = 0.20         # initial height
	var w: float = 0.12         # initial width
	var thick: float = 0.026    # bold strokes

	var spine: Array[Vector3] = [
		Vector3(ox, oy + h * 0.5, face_z),
		Vector3(ox + w * 0.10, oy + h * 0.1, face_z),
		Vector3(ox, oy - h * 0.4, face_z),
		Vector3(ox + w * 0.12, oy - h * 0.5, face_z),
	]
	var spine_mesh: Mesh = _col_sweep_stroke(spine, thick, 0.0)
	if spine_mesh != null:
		_cg_merge_into(st, spine_mesh)

	var bowl: Array[Vector3] = []
	var bowl_steps: int = 12
	for bi: int in range(bowl_steps + 1):
		var a: float = lerpf(-PI * 0.55, PI * 0.55, float(bi) / float(bowl_steps))
		var bx: float = ox + w * 0.10 + cos(a) * w * 0.6
		var by: float = oy + h * 0.18 + sin(a) * h * 0.30
		bowl.append(Vector3(bx, by, face_z))
	var bowl_mesh: Mesh = _col_sweep_stroke(bowl, thick * 0.9, 1.0)
	if bowl_mesh != null:
		_cg_merge_into(st, bowl_mesh)

	var m: ArrayMesh = st.commit()
	if m == null or m.get_surface_count() == 0:
		return null
	return m
