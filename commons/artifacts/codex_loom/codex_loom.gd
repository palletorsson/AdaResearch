extends Node3D
class_name CodexLoom

## @identity
# essence: a single DNA-driven CODEX GRID/WEAVING SPECIMEN rendered not as decorative pattern but as
#   a GENUINE ARRAY ALGORITHM run live. Where most "grid" artifacts paint a checker, CodexLoom
#   COMPUTES its grid: a 2D over-under WEAVE decided by a boolean pattern matrix, a PLACE-VALUE
#   counting array of bead-rods encoding a number in a base, a GRID-INDEX traversal walking k//W and
#   k%W in boustrophedon order across a board, or a WALLPAPER-GROUP tessellation replicating a motif
#   by a symmetry group's modular-arithmetic operations. Luigi Serafini's Codex Seraphinianus grid
#   and weaving plates — counting matrices, board tracks, woven panels, tiled terraces — are the
#   muse; four founding array ideas (the 2D boolean array, place-value, linear-index decode, plane
#   symmetry) are the engine. Depending on its `mode` DNA it becomes one of FOUR teaching specimens
#   whose pattern IS its process: weave (a REAL 2D over-under weave — warp threads run +Z, weft +X,
#   and at every crossing one boolean bit lifts the warp over the weft or dips it under; a weave
#   DRAFT {PLAIN/TWILL/SATIN} picked from the seed fills the matrix; two crossing 1-D colour
#   sequences make a tartan; on a wooden loom frame with shuttle + heddle + loose ends), abacus (a
#   REAL place-value counting array — the seed written in base BASE, one digit per horizontal rod,
#   counted beads clustered left of a reckoning divider and uncounted parked right, the most-
#   significant and ones places highlighted, asemic numeral ticks carved per counted bead), board-
#   track (a REAL grid-index traversal — an N x N board of raised checker cells with a ribbon
#   snaking through them in boustrophedon order via row=k//W, col=k%W with the column reversing every
#   other row; direction chevrons, pawns, ladder/portal arcs jumping non-adjacent cells, a glowing
#   finish + a start pad), and wallpaper (a REAL wallpaper-group tessellation — an asymmetric motif
#   replicated across a grid by the explicit symmetry operations {p4/p4m/p6m/pmm/pgg} of a seed-
#   chosen plane group, with modular arithmetic on (row,col) selecting per-cell orientation + accent).
#   It is identity confessed as an ARRAY PROCESS — the grid is the computation, not its decoration.
# desire: it wants the algorithm to stay LEGIBLE and GENUINE — the weave's over/under bits (warp and
#   weft visibly passing over and under one another through an OPEN lattice of gaps), the abacus's
#   honest base decomposition (counted vs uncounted beads = the digit), the board's k//W / k%W
#   indexing (the ribbon IS the for-loop walking the array, the boustrophedon reversal the snake
#   numbering you read off the board), and the wallpaper group's proper orbit (an asymmetric motif so
#   every rotated/mirrored copy is recognisably re-oriented) — all must read as COMPUTED, never hand-
#   placed. It wants the wooden FRAME / board / stele to glow soft with an emission floor so the
#   substrate never collapses to black against the dark capture, threads / beads / cells / tiles to
#   read matte in the colour triad, and HIGHLIGHTS (the rubricated rod, the glowing track + finish,
#   the accent tiles, the shuttle tip) to BURN near-unshaded. Above all it wants every index BOUNDED
#   — the weave matrix N x N, the rod count clamped, the track length finite, the wallpaper grid
#   modest — and every value seeded so each launch is identical.
# critical_parameter: mode + seed + the colour triad (color_a PRIMARY thread/bead/tile/cell-A /
#   color_b SECONDARY thread/rod/tile/cell-B/frame / accent HIGHLIGHT/counter/track/MST-of-the-grid/
#   accent-cell GLOW) + complexity. mode picks the array lineage; seed varies the individual
#   deterministically (a local seeded RNG, no global randf/randi ever — it picks the weave draft, the
#   number the abacus encodes, the board's ladder endpoints + pawn cells, the wallpaper group);
#   complexity scales the WEAVE GRID SIZE, the ABACUS ROD COUNT, the BOARD SIZE, and the WALLPAPER
#   GRID SIZE. Higher complexity = a denser array / a longer count / a bigger board.
# triggers: _ready() reads DNA metadata overrides, seeds the RNG from `seed`, and branches on `mode`
#   to a _build_<mode>() helper; apply_grid_config rewrites config metas, clears children (remove
#   BEFORE free, guarded by `_built`), and rebuilds.
# emerges: a row of these reads as a CABINET OF GRIDS — four ways an array becomes a pattern. Switch
#   one mode and the room's idea of "what a grid is" shifts from woven-cloth to counting-frame to
#   indexed-board to symmetry-tiling; reseed and the array persists while its individual varies.
#   These are teaching specimens for the array_tutorial lab: the grid is the first order — index,
#   modulo, repeat — and the loom is a 2D array you can hold.
# needs: a seeded RNG for deterministic individuals [present]; four build branches each carrying its
#   trial's genuine algorithm self-contained (2D over-under weave matrix, place-value base decompose,
#   boustrophedon k//W/k%W index decode, wallpaper-group symmetry orbit) [present]; primary / second-
#   ary / glow materials driven by the colour triad [present]; threads / beads / cells / tiles batched
#   into ArrayMeshes (with a Variant-coercing merge for non-indexed MorphoPrimitive surfaces) so the
#   AABB capture frames the specimen [present]; the morphology toolkit statics (MorphoPrimitive) for
#   tube / revolution / sphere / box / bezier_sweep surface generation [present].
# relationships: kin to codex_glyph (same genome shape + conventions — identity header, grouped
#   @export, apply_grid_config + _parse_color + _built rebuild guard, self-clearing idempotent
#   _build(), seeded RNG, settle centring, the Variant-coercing mesh-merge; codex_glyph runs writing-
#   system algorithms, CodexLoom runs array algorithms); kin to codex_morph + codex_flora (the shared
#   Codex genome shape); built on the nature_system morphology engine it borrows from (MorphoPrimitive)
#   for surface generation; cousin to any mode-switchboard of one genome.
# truth: the grid is the first order — index, modulo, repeat — and the loom is a 2D array you can
#   hold. Serafini drew counting matrices and woven terraces that mean nothing yet read as system;
#   the 2D boolean array, place-value, linear-index decode, and plane symmetry grow grids that did
#   not exist until the rule ran. CodexLoom holds four such array processes in one genome where the
#   pattern is COMPUTED — a woven over/under cloth, a counted place-value frame, an indexed board
#   track, a symmetry tessellation — and lets a single parameter choose which array the viewer is
#   invited to read. The algorithm must stay genuine, the wood must glow, the highlight must burn,
#   and above all every index must be bounded and deterministic.

## A multi-mode generative Codex grid/weaving specimen run as a GENUINE array ALGORITHM.
##
## Built procedurally from DNA exports, after Luigi Serafini's Codex Seraphinianus grid/weaving
## plates, for the array_tutorial curriculum lab. The `mode` export selects one of FOUR processes,
## each ported faithfully from a verified trial INCLUDING its real algorithm:
## weave (a REAL 2D over-under WEAVE — a boolean pattern matrix `_over[i][j]` from a seed-picked draft
## {PLAIN: (i+j)%2, TWILL: diagonal rib, SATIN: scattered floats} decides whether warp column i passes
## OVER or UNDER weft row j; warp tubes run +Z, weft tubes run +X, the over/under bit lifts/dips the Y;
## two crossing 1-D colour sequences make a tartan; cloth authored FLAT in X-Z then tilted via Basis —
## multi_tube DEGENERATES on world-Y-aligned paths so the loom must be built flat then pitched),
## abacus (a REAL place-value counting array — the seed decomposed into base-BASE digits by integer
## division [NOT powf], one digit per horizontal rod, ones at the bottom; counted beads cluster left
## of a reckoning divider, uncounted park right; the most-significant + ones rods are rubricated; a
## numeral tick is carved per counted bead),
## boardtrack (a REAL grid-index traversal — an N x N board of raised checker cells; a ribbon snakes
## through them in boustrophedon order decoded by row = k // W and col = k % W [reversed on odd rows];
## direction chevrons, pawns on indexed cells, 3 ladder/portal bezier arcs jumping non-adjacent cells,
## a glowing finish post + a start pad),
## wallpaper (a REAL wallpaper-group tessellation — an asymmetric relief motif in a unit cell repeated
## across an N x M grid by the explicit Transform2D symmetry operations of a seed-chosen plane group
## {p4, p4m, p6m, pmm, pgg}; modular arithmetic on (row+col) picks per-cell phase + accent marking).
##
## A seeded RNG makes every individual deterministic from its `seed`. The colour triad (color_a
## PRIMARY thread/bead/tile-A / color_b SECONDARY thread/rod/tile-B/frame / accent HIGHLIGHT) re-
## registers the same array between palettes. Shared material + orient + settle + mesh-merge helpers
## live under the `_cl_` prefix; the genuine algorithm from each trial stays in its own builder under
## `_weave_` / `_aba_` / `_board_` / `_wall_` so the weave draft, the place-value decompose, the
## boustrophedon index decode, and the wallpaper-group orbit are preserved — that is the whole point.
## Surface generation reuses the morphology toolkit statics (MorphoPrimitive).
##
## complexity scales the array budget per mode: weave GRID SIZE (12..20), abacus ROD COUNT floor,
## board SIZE (6..10 per side), wallpaper GRID SIZE. Higher complexity = a denser array / a longer
## count / a bigger board.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Form")
## weave | abacus | boardtrack | wallpaper
@export var mode: String = "weave"
## Deterministic seed — same seed always yields the same specimen.
@export var seed: int = 0
## Detail / array budget. Scales weave grid size, abacus rod count, board size, and wallpaper grid
## size. Higher = a denser array / a longer count / a bigger board.
@export var complexity: int = 6
## Overall height in meters (nominal full height of the specimen).
@export var sculpt_height: float = 1.8
## Footprint / across-span width scale in meters (1.0 = native trial proportions).
@export var sculpt_width: float = 1.0

@export_group("Material")
## PRIMARY thread / bead / tile / cell-A — vivid Codex rose.
@export var color_a: Color = Color(0.82, 0.34, 0.40)
## SECONDARY thread / rod / tile / cell-B / FRAME — contrasting slate-blue.
@export var color_b: Color = Color(0.30, 0.50, 0.66)
## HIGHLIGHT / counter / track / MST-of-the-grid / accent-cell GLOW — gold.
@export var accent: Color = Color(0.95, 0.82, 0.35)
## Thread/bead/tile, not metal — keep this LOW.
@export var metallic_amt: float = 0.0
@export var rough_amt: float = 0.7
## Boost emissive energies (highlight reads hotter when true).
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
	# (after apply_grid_config has already built), a second _build() must not stack a second specimen
	# on top of the first (which would double mesh counts on the first instance per process — the
	# capture path). Remove BEFORE freeing (queue_free is deferred) so the rebuild starts from a
	# genuinely empty subtree this frame.
	for c: Node in get_children():
		remove_child(c)
		c.queue_free()
	_built = true
	_mesh_count = 0
	_rng.seed = seed
	match mode:
		"weave":
			_build_weave()
		"abacus":
			_build_abacus()
		"boardtrack":
			_build_boardtrack()
		"wallpaper":
			_build_wallpaper()
		_:
			# Unknown mode falls back to the woven over/under cloth.
			_build_weave()


# ── Shared `_cl_` material helpers (the trial materials, DNA-driven) ─────

## Energy multiplier for emissive elements, lifted when `emissive` is on (gated like codex_glyph's
## `_cg_glow_energy`).
func _cl_glow_energy(base: float) -> float:
	return base * (1.0 if emissive else 0.6)


## PRIMARY thread / bead / tile-A (color_a family): vivid albedo, roughness ~0.7, with an emission
## FLOOR in its own tone (albedo*0.4 at energy ~0.10) so the element never collapses to black against
## the dark capture.
func _cl_primary_mat(c: Color = color_a) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = clampf(rough_amt, 0.02, 1.0)
	m.metallic = clampf(metallic_amt, 0.0, 1.0)
	m.emission_enabled = true
	m.emission = c * 0.4
	m.emission_energy_multiplier = _cl_glow_energy(0.10)
	return m


## SECONDARY thread / rod / tile-B / FRAME (color_b family): roughness ~0.75, emission floor ~0.10 so
## the element never collapses to black.
func _cl_secondary_mat(c: Color = color_b) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = clampf(maxf(rough_amt, 0.75), 0.02, 1.0)
	m.metallic = clampf(metallic_amt, 0.0, 1.0)
	m.emission_enabled = true
	m.emission = c * 0.4
	m.emission_energy_multiplier = _cl_glow_energy(0.10)
	return m


## Warm-WOOD derive (for loom beams / abacus rails + feet / board frame): a warm brown blended from
## color_b toward an ochre, rough and matte with a faint floor.
func _cl_wood_mat() -> StandardMaterial3D:
	var wood: Color = color_b.lerp(Color(0.52, 0.38, 0.24), 0.78)
	var m := StandardMaterial3D.new()
	m.albedo_color = wood
	m.roughness = clampf(maxf(rough_amt, 0.82), 0.02, 1.0)
	m.metallic = clampf(metallic_amt, 0.0, 1.0)
	m.emission_enabled = true
	m.emission = wood * 0.4
	m.emission_energy_multiplier = _cl_glow_energy(0.07)
	return m


## HIGHLIGHT / counter / track / accent-cell GLOW (accent family): saturated, near-UNSHADED, burning
## at `energy` ~2.2-2.8. The track glow, the rubricated rod/beads, the accent tiles, the shuttle tip
## all come through here — the triad re-registers per mode via the accent colour.
func _cl_glow_mat(c: Color = accent, energy: float = 2.5) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = _cl_glow_energy(energy)
	return m


# ── Shared `_cl_` geometry helpers ──────────────────────────────────────

## Orthonormal Basis whose Y axis is `up_axis`. The single orient primitive the builders use so
## orientation is always via Basis, never out-of-tree look_at.
func _cl_basis_from_up(up_axis: Vector3) -> Basis:
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
func _cl_add_mesh(parent: Node3D, mesh: Mesh, mat: Material,
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


## Append a Mesh's surface-0 triangles into a SurfaceTool, transformed by `xform`. This is the mesh-
## batch / merge helper that lets a whole weave / bead-field / board of cells / tessellation live in a
## handful of ArrayMeshes the capture AABB can frame — no MultiMesh.
##
## CRITICAL (carried from the trials): MorphoPrimitive output is often NON-INDEXED and may be missing
## the normal array, so the mesh arrays must be read as Variants and coerced ONLY when the expected
## packed type is actually present — never blind-cast `arrays[ARRAY_INDEX]` to PackedInt32Array (it can
## be null → a hard runtime error). Both the indexed and non-indexed paths are handled.
func _cl_merge_into(st: SurfaceTool, mesh: Mesh, xform: Transform3D = Transform3D.IDENTITY) -> void:
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
## normals (off when the batch already set per-vertex normals via _cl_merge_into or the hand-emitted
## boxes, which would otherwise be flattened/wrong). Returns the instance (or null if empty).
func _cl_commit_batch(parent: Node3D, st: SurfaceTool, mat: Material, nm: String,
		gen_normals: bool = false) -> MeshInstance3D:
	if gen_normals:
		st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return null
	return _cl_add_mesh(parent, mesh, mat, Transform3D.IDENTITY, nm)


## Emit one box (12 triangles, outward normals) into a SurfaceTool. Centred at `c`, half-extents
## (hx,hy,hz) along orthonormal axes (ax,ay,az). Shared by every frame beam / rod / cell / tile / bar
## across all four modes. Sets per-vertex normals (so commit with gen_normals=false). Never call
## generate_tangents on these — they have normals but no UVs (a fatal "UVs required").
func _cl_emit_box(st: SurfaceTool, c: Vector3, ax: Vector3, ay: Vector3, az: Vector3,
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
	_cl_quad(st, p000, p010, p110, p100, -az)   # -Z
	_cl_quad(st, p001, p101, p111, p011, az)    # +Z
	_cl_quad(st, p000, p100, p101, p001, -ay)   # -Y
	_cl_quad(st, p010, p011, p111, p110, ay)    # +Y
	_cl_quad(st, p000, p001, p011, p010, -ax)   # -X
	_cl_quad(st, p100, p110, p111, p101, ax)    # +X


func _cl_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3) -> void:
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(b)
	st.set_normal(n); st.add_vertex(c)
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(c)
	st.set_normal(n); st.add_vertex(d)


## Append an axis-aligned box (centre, full size) into a SurfaceTool via MorphoPrimitive.box welded
## through _cl_merge_into. Used where the trials authored frames as transformed BoxMesh surfaces.
func _cl_append_box_mesh(st: SurfaceTool, center: Vector3, size: Vector3) -> void:
	_cl_merge_into(st, MorphoPrimitive.box(size), Transform3D(Basis.IDENTITY, center))


## Local AABB over all MeshInstance3D descendants of `node`, accumulated through the chain of LOCAL
## transforms down from `node` (never touches global_transform — independent of tree state). Used to
## centre + scale each specimen.
func _cl_subtree_aabb(node: Node3D) -> AABB:
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


## Centre `body` and scale it to fill ~`target_span` on its largest axis, then either rest its base on
## y=0 (`floor_to_zero`) or centre it around its own centroid. `width_scale` stretches the horizontal
## axes for extra span. The codex_glyph `_cg_settle` analogue, but span-fitted (the looms read widest
## across, like the trials' TARGET_SPAN/BOARD_SPAN/PANEL_WIDTH fits).
func _cl_settle(body: Node3D, target_span: float, width_scale: float = 1.0,
		floor_to_zero: bool = true) -> void:
	if target_span > 0.0:
		var raw: AABB = _cl_subtree_aabb(body)
		var span: float = maxf(maxf(raw.size.x, maxf(raw.size.y, raw.size.z)), 0.001)
		var k: float = target_span / span
		body.scale = Vector3(k * width_scale, k, k * width_scale)
	var aabb: AABB = _cl_subtree_aabb(body)
	if aabb.size == Vector3.ZERO:
		return
	var centre: Vector3 = aabb.get_center()
	if floor_to_zero:
		body.position += Vector3(-centre.x, -aabb.position.y, -centre.z)
	else:
		body.position += -centre


# =============================================================================
# MODE: weave — a REAL 2D over-under WEAVE on a loom (trial v1)
#
# The genuine algorithm (a 2D boolean array realised as interlace, the load-bearing core):
#   A weave IS a 2D boolean array. At every crossing of warp column i and weft row j a single bit
#   over[i][j] decides whether the WARP passes OVER the weft (warp lifts to +Y, weft dips to -Y) or
#   UNDER it (the complement). The bit comes from a weave DRAFT picked DETERMINISTICALLY from the
#   seed:  PLAIN (i+j)%2==0 — over-one/under-one basket;  TWILL (i + j*step) % block < lift — the
#   diagonal rib of denim/tweed;  SATIN (i*sat_step)%n == j — long floats, few interlacings. Colour is
#   two 1-D sequences crossing: a warp band-sequence and a DIFFERENT weft band-sequence, so where they
#   meet a CHECK / TARTAN emerges purely from 1-D × 1-D → 2-D — the combinatorial heart of the lab.
#   Every thread is a MorphoPrimitive.multi_tube following its row/column with the over/under
#   undulation; threads BATCH by colour into a few ArrayMeshes. A wooden loom frame, heddle bar,
#   shuttle, and loose warp ends dress it.
#   COORDINATE GOTCHA (carried from the trial): multi_tube derives its tube frame from forward ×
#   Vector3.UP, which DEGENERATES for world-Y-aligned paths. So the cloth is authored FLAT in X-Z
#   (warp +Z, weft +X, relief +Y) — every thread's forward axis stays horizontal — then the whole flat
#   loom is tilted toward the camera via Basis/Euler (no out-of-tree look_at). An OPEN weave (thin
#   cords + gaps) lets BOTH warp and weft read through one another. complexity scales the grid size.
# =============================================================================

enum WeaveDraft { PLAIN, TWILL, SATIN }

const _WEAVE_WEB_HALF: float = 1.0          # web spans [-half,+half] in X and Z
const _WEAVE_THREAD_SIDES: int = 8          # cross-section sides of a thread tube
const _WEAVE_SAMPLES_PER_SPAN: int = 7      # path samples per grid cell (smooth undulation)
const _WEAVE_TARGET_SPAN: float = 2.3       # final across-span of the loom (m, before settle)

var _weave_n: int = 14                       # grid is _weave_n × _weave_n crossings
var _weave_draft: int = WeaveDraft.PLAIN
var _weave_over: Array[Array] = []           # typed Array[Array[bool]]: over[i][j] = warp i OVER weft j
var _weave_spacing: float = 0.15
var _weave_warp_radius: float = 0.05
var _weave_weft_radius: float = 0.05
var _weave_cross_lift: float = 0.07          # ±Y amplitude of the over/under relief


func _build_weave() -> void:
	var loom := Node3D.new()
	loom.name = "Loom"
	add_child(loom)

	# complexity scales the grid (clamped, kept even so plain/twill tile cleanly).
	_weave_n = clampi(7 + complexity, 12, 20)
	if _weave_n % 2 == 1:
		_weave_n += 1

	# Derive thread thickness + over/under lift from the grid spacing so the panel reads the same at
	# any grid size. OPEN-WEAVE regime: thin threads with a clear GAP between parallel neighbours so
	# neither set occludes the other; a bold lift makes the over/under unmistakable.
	_weave_spacing = (2.0 * _WEAVE_WEB_HALF) / float(_weave_n - 1)
	var base_radius: float = _weave_spacing * 0.31      # diameter ≈ 0.62 × spacing → open lattice
	# The high camera sees horizontal weft a touch fuller than end-on vertical warp; fatten warp to
	# even their visual weight.
	_weave_warp_radius = base_radius * 1.22
	_weave_weft_radius = base_radius * 0.92
	_weave_cross_lift = base_radius * 1.4

	# Pick the weave draft deterministically from the seed, then fill the boolean matrix.
	_weave_draft = _weave_pick_draft()
	_weave_build_matrix()

	# Materials.
	var mat_warp_a := _cl_primary_mat(color_a)
	var mat_warp_b := _cl_primary_mat(color_a.lerp(Color(0.88, 0.55, 0.30), 0.5))   # warm ochre tint
	var mat_weft_a := _cl_secondary_mat(color_b)
	var mat_weft_b := _cl_secondary_mat(color_b.lerp(Color(0.40, 0.66, 0.52), 0.5)) # sage-teal tint
	var mat_wood := _cl_wood_mat()
	var mat_glow := _cl_glow_mat(accent, 2.2)

	# Layers (each batched by colour inside).
	_weave_build_warp(loom, mat_warp_a, mat_warp_b)
	_weave_build_weft(loom, mat_weft_a, mat_weft_b)
	_weave_build_frame(loom, mat_wood)
	_weave_build_heddle_bar(loom, mat_wood, mat_glow)
	_weave_build_shuttle(loom, mat_wood, mat_glow)
	_weave_build_loose_ends(loom, mat_warp_a, mat_warp_b)

	# The cloth is authored flat in X-Z (face normal +Y). Pitch it up about +X and yaw about +Y so the
	# woven face aims at the high +X/+Y/+Z capture camera — the face fills the frame and the over/under
	# relief reads. Basis/Euler only (no out-of-tree look_at). Then settle.
	loom.rotation = Vector3(deg_to_rad(62.0), deg_to_rad(30.0), 0.0)
	_cl_settle(loom, maxf(_WEAVE_TARGET_SPAN * (sculpt_height / 1.8), 0.4), maxf(sculpt_width, 0.2), true)


## Choose a weave kind from the seed (deterministic). Another seed routes through this to twill/satin.
func _weave_pick_draft() -> int:
	var draw: int = _rng.randi_range(0, 2)
	match draw:
		0: return WeaveDraft.PLAIN
		1: return WeaveDraft.TWILL
		_: return WeaveDraft.SATIN


## Fill _weave_over[i][j] from the chosen draft. True = warp column i passes OVER weft row j (warp
## lifts +Y, weft dips -Y); False = warp passes UNDER. This boolean matrix is the whole pattern.
func _weave_build_matrix() -> void:
	_weave_over.clear()
	var twill_step: int = 1
	var twill_lift: int = 2
	var twill_block: int = 4
	var sat_step: int = 3
	for i: int in range(_weave_n):
		var col: Array[bool] = []
		for j: int in range(_weave_n):
			var bit: bool
			match _weave_draft:
				WeaveDraft.PLAIN:
					bit = ((i + j) % 2) == 0
				WeaveDraft.TWILL:
					var phase: int = (i + j * twill_step) % twill_block
					bit = phase < twill_lift
				WeaveDraft.SATIN:
					bit = ((i * sat_step) % _weave_n) == j
				_:
					bit = ((i + j) % 2) == 0
			col.append(bit)
		_weave_over.append(col)


## Warp colour for column i, from a repeating band sequence (period 8). A tiny 1-D pattern read modulo
## its length stripes the warp.
func _weave_warp_color(i: int, mat_a: Material, mat_b: Material) -> Material:
	var seq: Array[int] = [0, 0, 0, 1, 0, 0, 1, 1]
	return mat_a if seq[i % seq.size()] == 0 else mat_b


## Weft colour for row j, from a DIFFERENT repeating sequence (period 8, offset) so the check is
## asymmetric → a proper tartan, not a plain grid.
func _weave_weft_color(j: int, mat_a: Material, mat_b: Material) -> Material:
	var seq: Array[int] = [0, 0, 1, 1, 0, 1, 0, 0]
	return mat_a if seq[j % seq.size()] == 0 else mat_b


## World X of warp column i (columns evenly fill [-half,+half]).
func _weave_col_x(i: int) -> float:
	if _weave_n == 1:
		return 0.0
	return lerpf(-_WEAVE_WEB_HALF, _WEAVE_WEB_HALF, float(i) / float(_weave_n - 1))


## World Z of weft row j.
func _weave_row_z(j: int) -> float:
	if _weave_n == 1:
		return 0.0
	return lerpf(-_WEAVE_WEB_HALF, _WEAVE_WEB_HALF, float(j) / float(_weave_n - 1))


## Height (Y) of WARP column i as it passes row j: +lift where OVER, -lift where UNDER.
func _weave_warp_y_at(i: int, j: int) -> float:
	return _weave_cross_lift if ((_weave_over[i] as Array[bool])[j]) else -_weave_cross_lift


## Height (Y) of WEFT row j as it passes column i — the complement.
func _weave_weft_y_at(i: int, j: int) -> float:
	return -_weave_cross_lift if ((_weave_over[i] as Array[bool])[j]) else _weave_cross_lift


## Build all warp threads (run +Z at fixed X), grouped by warp colour, each colour-group batched into
## one ArrayMesh. The path samples Z with several points per cell; Y smoothly interpolates the per-
## crossing over/under heights so each thread visibly dives and rises.
func _weave_build_warp(parent: Node3D, mat_a: Material, mat_b: Material) -> void:
	var st_a := SurfaceTool.new(); st_a.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_b := SurfaceTool.new(); st_b.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in range(_weave_n):
		var st: SurfaceTool = st_a if _weave_warp_color(i, mat_a, mat_b) == mat_a else st_b
		_weave_emit_warp_thread(st, i)
	_cl_commit_batch(parent, st_a, mat_a, "WarpA", false)
	_cl_commit_batch(parent, st_b, mat_b, "WarpB", false)


func _weave_emit_warp_thread(st: SurfaceTool, i: int) -> void:
	var x: float = _weave_col_x(i)
	var positions: Array[Vector3] = []
	var radii: Array[float] = []
	var z_start: float = _weave_row_z(0) - 0.06
	var z_end: float = _weave_row_z(_weave_n - 1) + 0.06
	var total_steps: int = (_weave_n - 1) * _WEAVE_SAMPLES_PER_SPAN
	for s: int in range(total_steps + 1):
		var f: float = float(s) / float(total_steps)
		var grid_pos: float = f * float(_weave_n - 1)
		var z: float = lerpf(z_start, z_end, f)
		var y: float = _weave_warp_height_smooth(i, grid_pos)
		positions.append(Vector3(x, y, z))
		radii.append(_weave_warp_radius)
	_cl_merge_into(st, MorphoPrimitive.multi_tube(positions, radii, _WEAVE_THREAD_SIDES))


## Smooth warp Y at a fractional row position (smoothstep between integer crossings → clean dip).
func _weave_warp_height_smooth(i: int, grid_pos: float) -> float:
	var j0: int = clampi(int(floor(grid_pos)), 0, _weave_n - 1)
	var j1: int = clampi(j0 + 1, 0, _weave_n - 1)
	var t: float = clampf(grid_pos - float(j0), 0.0, 1.0)
	return lerpf(_weave_warp_y_at(i, j0), _weave_warp_y_at(i, j1), smoothstep(0.0, 1.0, t))


## Build all weft threads (run +X at fixed Z), grouped + batched by weft colour like the warp.
func _weave_build_weft(parent: Node3D, mat_a: Material, mat_b: Material) -> void:
	var st_a := SurfaceTool.new(); st_a.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_b := SurfaceTool.new(); st_b.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j: int in range(_weave_n):
		var st: SurfaceTool = st_a if _weave_weft_color(j, mat_a, mat_b) == mat_a else st_b
		_weave_emit_weft_thread(st, j)
	_cl_commit_batch(parent, st_a, mat_a, "WeftA", false)
	_cl_commit_batch(parent, st_b, mat_b, "WeftB", false)


func _weave_emit_weft_thread(st: SurfaceTool, j: int) -> void:
	var z: float = _weave_row_z(j)
	var positions: Array[Vector3] = []
	var radii: Array[float] = []
	var x_start: float = _weave_col_x(0) - 0.06
	var x_end: float = _weave_col_x(_weave_n - 1) + 0.06
	var total_steps: int = (_weave_n - 1) * _WEAVE_SAMPLES_PER_SPAN
	for s: int in range(total_steps + 1):
		var f: float = float(s) / float(total_steps)
		var grid_pos: float = f * float(_weave_n - 1)
		var x: float = lerpf(x_start, x_end, f)
		var y: float = _weave_weft_height_smooth(j, grid_pos)
		positions.append(Vector3(x, y, z))
		radii.append(_weave_weft_radius)
	_cl_merge_into(st, MorphoPrimitive.multi_tube(positions, radii, _WEAVE_THREAD_SIDES))


## Smooth weft Y at a fractional column position (complement of the warp curve).
func _weave_weft_height_smooth(j: int, grid_pos: float) -> float:
	var i0: int = clampi(int(floor(grid_pos)), 0, _weave_n - 1)
	var i1: int = clampi(i0 + 1, 0, _weave_n - 1)
	var t: float = clampf(grid_pos - float(i0), 0.0, 1.0)
	return lerpf(_weave_weft_y_at(i0, j), _weave_weft_y_at(i1, j), smoothstep(0.0, 1.0, t))


## Four wooden beams around the cloth (X-Z plane): front+back beams (run X) and two side rails (run
## Z), set just outside the web, sitting a little below the cloth plane. Batched into one wood mesh.
func _weave_build_frame(parent: Node3D, mat: Material) -> void:
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var outer: float = _WEAVE_WEB_HALF + 0.14
	var beam_thick: float = 0.12
	var beam_y: float = -_weave_cross_lift - 0.02
	var span: float = (_WEAVE_WEB_HALF + 0.20) * 2.0
	_cl_append_box_mesh(st, Vector3(0.0, beam_y, outer), Vector3(span, beam_thick, beam_thick))
	_cl_append_box_mesh(st, Vector3(0.0, beam_y, -outer), Vector3(span, beam_thick, beam_thick))
	_cl_append_box_mesh(st, Vector3(-outer, beam_y, 0.0), Vector3(beam_thick, beam_thick, span))
	_cl_append_box_mesh(st, Vector3(outer, beam_y, 0.0), Vector3(beam_thick, beam_thick, span))
	_cl_commit_batch(parent, st, mat, "Frame", false)


## A thin heddle bar across the warp toward the back, riding above the cloth, with accent glints.
func _weave_build_heddle_bar(parent: Node3D, mat_wood: Material, mat_glow: Material) -> void:
	var bar_z: float = _weave_row_z(_weave_n - 1) * 0.5
	var bar_y: float = _weave_cross_lift + _weave_warp_radius + 0.05
	var wood := SurfaceTool.new(); wood.begin(Mesh.PRIMITIVE_TRIANGLES)
	_cl_append_box_mesh(wood, Vector3(0.0, bar_y, bar_z),
		Vector3((_WEAVE_WEB_HALF + 0.06) * 2.0, 0.05, 0.05))
	_cl_commit_batch(parent, wood, mat_wood, "HeddleBar", false)

	var glints := SurfaceTool.new(); glints.begin(Mesh.PRIMITIVE_TRIANGLES)
	var glint_count: int = 5
	for k: int in range(glint_count):
		var fx: float = lerpf(-_WEAVE_WEB_HALF * 0.7, _WEAVE_WEB_HALF * 0.7, float(k) / float(glint_count - 1))
		_cl_merge_into(glints, MorphoPrimitive.sphere(0.024, 10, 6),
			Transform3D(Basis.IDENTITY, Vector3(fx, bar_y + 0.03, bar_z)))
	_cl_commit_batch(parent, glints, mat_glow, "HeddleGlints", false)


## A weaver's shuttle laid across the front: a tapered revolution spindle (pointed both ends) lying
## along X, with a bright accent tip, set above the cloth.
func _weave_build_shuttle(parent: Node3D, mat_wood: Material, mat_glow: Material) -> void:
	var sz: float = _weave_row_z(0) + 0.30
	var sy: float = _weave_cross_lift + _weave_warp_radius + 0.06
	var profile: Array[Vector2] = []
	var segs: int = 14
	var half_len: float = 0.46
	for s: int in range(segs + 1):
		var f: float = float(s) / float(segs)
		var along: float = lerpf(-half_len, half_len, f)
		var r: float = 0.075 * sin(f * PI)
		profile.append(Vector2(maxf(r, 0.001), along))
	var body_basis := Basis(Vector3(0, 0, 1), deg_to_rad(90.0)) * Basis(Vector3(0, 1, 0), deg_to_rad(10.0))
	_cl_add_mesh(parent, MorphoPrimitive.revolution(profile, 16), mat_wood,
		Transform3D(body_basis, Vector3(0.05, sy, sz)), "ShuttleBody")
	var tip_basis := Basis.IDENTITY.scaled(Vector3(1.6, 0.7, 0.7))
	_cl_add_mesh(parent, MorphoPrimitive.sphere(0.05, 12, 8), mat_glow,
		Transform3D(tip_basis, Vector3(0.05 + half_len * 0.92, sy, sz + 0.02)), "ShuttleTip")


## A handful of slack warp ends trailing past the front beam, drooping forward + down. Batched by
## colour. Each end is seeded by column so the splay is deterministic.
func _weave_build_loose_ends(parent: Node3D, mat_a: Material, mat_b: Material) -> void:
	var st_a := SurfaceTool.new(); st_a.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_b := SurfaceTool.new(); st_b.begin(Mesh.PRIMITIVE_TRIANGLES)
	var beam_front: float = _WEAVE_WEB_HALF + 0.14
	var picks: Array[int] = [2, 5, 8, 11]
	for idx: int in range(picks.size()):
		var i: int = clampi(picks[idx], 0, _weave_n - 1)
		var st: SurfaceTool = st_a if _weave_warp_color(i, mat_a, mat_b) == mat_a else st_b
		_weave_emit_loose_end(st, i, beam_front, idx)
	_cl_commit_batch(parent, st_a, mat_a, "LooseEndsA", false)
	_cl_commit_batch(parent, st_b, mat_b, "LooseEndsB", false)


## One slack warp end from the front beam drooping further forward (+Z) while dipping down (-Y), with
## a small seeded sideways drift. Pure parametric curve — no look_at. RNG seeded per column + index.
func _weave_emit_loose_end(st: SurfaceTool, i: int, beam_front: float, idx: int) -> void:
	var x: float = _weave_col_x(i)
	var lrng := RandomNumberGenerator.new()
	lrng.seed = seed + i * 53 + idx * 7
	var drift: float = (lrng.randf() - 0.5) * 0.28
	var reach: float = lerpf(0.34, 0.58, lrng.randf())
	var positions: Array[Vector3] = []
	var radii: Array[float] = []
	var segs: int = 10
	for s: int in range(segs + 1):
		var f: float = float(s) / float(segs)
		var z: float = beam_front + f * reach
		var y: float = -f * f * 0.30
		var sway: float = drift * f * f
		positions.append(Vector3(x + sway, y, z))
		radii.append(_weave_warp_radius * lerpf(1.0, 0.55, f))
	_cl_merge_into(st, MorphoPrimitive.multi_tube(positions, radii, _WEAVE_THREAD_SIDES))


# =============================================================================
# MODE: abacus — a REAL place-value COUNTING ARRAY (trial v2)
#
# The genuine algorithm (place-value decomposition, the load-bearing core):
#   R horizontal RODS stacked in Y; each rod is a PLACE (a digit position), ones at the BOTTOM, the
#   most-significant climbing upward. The seed is written in base BASE by INTEGER DIVISION + MODULO
#   (NOT powf): repeatedly digit = n % BASE, n = n / BASE — one digit per rod. That digit is the count
#   of COUNTED beads, which cluster LEFT against a central reckoning DIVIDER; the remaining (capacity −
#   digit) UNCOUNTED beads park RIGHT. Two rods are HIGHLIGHTED (accent glow): the most-significant
#   non-zero place and the ones place, so the eye finds where the number begins and ends. A small
#   asemic numeral TICK is carved per counted bead. Beads BATCH into ArrayMeshes (one per colour
#   class) so the dense scatter is a handful of draw calls. complexity nudges the rod-count floor.
# =============================================================================

const _ABA_FRAME_W: float = 1.95
const _ABA_FRAME_H: float = 1.85
const _ABA_FRAME_DEPTH: float = 0.14
const _ABA_RAIL_T: float = 0.13
const _ABA_ROD_RADIUS: float = 0.018
const _ABA_ROD_INSET_X: float = 0.085
const _ABA_BEAD_RADIUS: float = 0.058
const _ABA_BEAD_GAP: float = 1.06
const _ABA_DIVIDER_T: float = 0.045
const _ABA_ROW_MARGIN_Y: float = 0.12
const _ABA_TICK_W: float = 0.018
const _ABA_TICK_H: float = 0.05
const _ABA_BASE: int = 5                 # numeral base; each rod's digit < BASE
const _ABA_BEADS_PER_ROD: int = 9        # capacity per place (>= BASE)
const _ABA_TARGET_SPAN: float = 1.95     # final across-span (m, before settle)


func _build_abacus() -> void:
	var frame := Node3D.new()
	frame.name = "Abacus"
	add_child(frame)

	var rods: int = _aba_rod_count()
	var digits: Array[int] = _aba_encode_digits(rods)
	var msd: int = _aba_msd_index(digits)
	var highlight: Dictionary = {0: true, msd: true}   # ones + most-significant

	var mat_counted := _cl_primary_mat(color_a.lerp(Color(0.85, 0.45, 0.35), 0.5))
	var mat_uncounted := _cl_secondary_mat(color_b.lerp(Color(0.45, 0.50, 0.58), 0.5))
	var mat_rod := _cl_secondary_mat(color_b.lerp(Color(0.45, 0.50, 0.58), 0.5))
	var mat_wood := _cl_wood_mat()
	var mat_glow := _cl_glow_mat(accent, 2.5)

	_aba_build_frame(frame, mat_wood)
	_aba_build_rods(frame, rods, highlight, mat_rod, mat_glow)
	_aba_build_beads(frame, rods, digits, highlight, mat_counted, mat_uncounted, mat_glow)
	_aba_build_dividers(frame, rods, mat_wood)
	_aba_build_ticks(frame, rods, digits, mat_glow)
	_aba_build_feet(frame, mat_wood)

	# The abacus is authored upright in X-Y; settle (standing frame, base to y=0).
	frame.position = Vector3(0.0, _ABA_FRAME_H * 0.5, 0.0)
	_cl_settle(frame, maxf(_ABA_TARGET_SPAN * (sculpt_height / 1.8), 0.4), maxf(sculpt_width, 0.2), true)


## Count of significant base-BASE digits in the seed (integer division loop, NOT powf/log).
func _aba_significant_digits() -> int:
	var n: int = absi(seed)
	var c: int = 0
	while n > 0:
		c += 1
		n = n / _ABA_BASE
	return maxi(c, 1)


## Number of rods, in [6, 9]: exactly the significant base-BASE places of the seed, clamped (so every
## rod carries a real digit). complexity nudges the floor upward.
func _aba_rod_count() -> int:
	var lo: int = clampi(6 + (complexity - 6), 6, 9)
	return clampi(_aba_significant_digits(), lo, 9)


## Decompose the seed into base-BASE digits, low place first, padded/truncated to `rods`. Each entry
## is the COUNTED-bead count (the digit) for that rod. Pure integer arithmetic.
func _aba_encode_digits(rods: int) -> Array[int]:
	var digits: Array[int] = []
	var n: int = absi(seed)
	while n > 0:
		digits.append(n % _ABA_BASE)
		n = n / _ABA_BASE
	while digits.size() < rods:
		digits.append(0)              # honest leading zeros
	if digits.size() > rods:
		digits.resize(rods)
	return digits


## Index of the most-significant non-zero rod (for the highlight).
func _aba_msd_index(digits: Array[int]) -> int:
	var idx: int = 0
	for i: int in range(digits.size()):
		if digits[i] > 0:
			idx = i
	return idx


func _aba_inner_left() -> float:
	return -_ABA_FRAME_W * 0.5 + _ABA_RAIL_T + _ABA_ROD_INSET_X

func _aba_inner_right() -> float:
	return _ABA_FRAME_W * 0.5 - _ABA_RAIL_T - _ABA_ROD_INSET_X

func _aba_row_y(r: int, rods: int) -> float:
	# Rod 0 (ones) at the bottom, climbing upward.
	var top: float = _ABA_FRAME_H - _ABA_RAIL_T - _ABA_ROW_MARGIN_Y
	var bot: float = _ABA_RAIL_T + _ABA_ROW_MARGIN_Y
	if rods <= 1:
		return (top + bot) * 0.5
	return lerpf(bot, top, float(r) / float(rods - 1))


## Four wooden rails as one batched mesh (top/bottom/left/right).
func _aba_build_frame(parent: Node3D, mat: Material) -> void:
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw: float = _ABA_FRAME_W * 0.5
	var hh: float = _ABA_FRAME_H * 0.5
	_cl_append_box_mesh(st, Vector3(0.0, _ABA_FRAME_H - _ABA_RAIL_T * 0.5, 0.0),
		Vector3(_ABA_FRAME_W, _ABA_RAIL_T, _ABA_FRAME_DEPTH))
	_cl_append_box_mesh(st, Vector3(0.0, _ABA_RAIL_T * 0.5, 0.0),
		Vector3(_ABA_FRAME_W, _ABA_RAIL_T, _ABA_FRAME_DEPTH))
	_cl_append_box_mesh(st, Vector3(-hw + _ABA_RAIL_T * 0.5, hh, 0.0),
		Vector3(_ABA_RAIL_T, _ABA_FRAME_H, _ABA_FRAME_DEPTH))
	_cl_append_box_mesh(st, Vector3(hw - _ABA_RAIL_T * 0.5, hh, 0.0),
		Vector3(_ABA_RAIL_T, _ABA_FRAME_H, _ABA_FRAME_DEPTH))
	_cl_commit_batch(parent, st, mat, "Frame", false)


## Muted rod tubes; highlighted rods (ones + MSD) glow.
func _aba_build_rods(parent: Node3D, rods: int, highlight: Dictionary,
		mat_rod: Material, mat_glow: Material) -> void:
	var st_plain := SurfaceTool.new(); st_plain.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_glow := SurfaceTool.new(); st_glow.begin(Mesh.PRIMITIVE_TRIANGLES)
	var xl: float = _aba_inner_left()
	var xr: float = _aba_inner_right()
	for r: int in range(rods):
		var y: float = _aba_row_y(r, rods)
		var seg: Mesh = MorphoPrimitive.tube(Vector3(xl, y, 0.0), Vector3(xr, y, 0.0),
			_ABA_ROD_RADIUS, _ABA_ROD_RADIUS, 8)
		if seg == null:
			continue
		if highlight.has(r):
			_cl_merge_into(st_glow, seg)
		else:
			_cl_merge_into(st_plain, seg)
	_cl_commit_batch(parent, st_plain, mat_rod, "Rods", false)
	_cl_commit_batch(parent, st_glow, mat_glow, "RodsHighlight", false)


## Beads threaded on rods, batched per colour class. COUNTED beads cluster left of the divider (the
## digit); UNCOUNTED park right. Highlighted rods' counted beads go to the accent batch.
func _aba_build_beads(parent: Node3D, rods: int, digits: Array[int], highlight: Dictionary,
		mat_counted: Material, mat_uncounted: Material, mat_glow: Material) -> void:
	var st_counted := SurfaceTool.new(); st_counted.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_uncounted := SurfaceTool.new(); st_uncounted.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_accent := SurfaceTool.new(); st_accent.begin(Mesh.PRIMITIVE_TRIANGLES)

	var bead_mesh: Mesh = MorphoPrimitive.sphere(_ABA_BEAD_RADIUS, 16, 10)
	var step: float = _ABA_BEAD_RADIUS * 2.0 * _ABA_BEAD_GAP
	var xl: float = _aba_inner_left()
	var xr: float = _aba_inner_right()
	var divider_x: float = (xl + xr) * 0.5

	for r: int in range(rods):
		var y: float = _aba_row_y(r, rods)
		var counted: int = clampi(digits[r], 0, _ABA_BEADS_PER_ROD)
		var uncounted: int = _ABA_BEADS_PER_ROD - counted
		var is_hi: bool = highlight.has(r)
		# COUNTED beads against the LEFT face of the divider (nearest divider first, walking left).
		for j: int in range(counted):
			var x: float = divider_x - _ABA_DIVIDER_T - _ABA_BEAD_RADIUS - step * float(j)
			x = maxf(x, xl + _ABA_BEAD_RADIUS)
			var xf := Transform3D(Basis(), Vector3(x, y, 0.0))
			if is_hi:
				_cl_merge_into(st_accent, bead_mesh, xf)
			else:
				_cl_merge_into(st_counted, bead_mesh, xf)
		# UNCOUNTED beads against the RIGHT inner rail.
		for k: int in range(uncounted):
			var x2: float = xr - _ABA_BEAD_RADIUS - step * float(k)
			x2 = maxf(x2, divider_x + _ABA_DIVIDER_T + _ABA_BEAD_RADIUS)
			_cl_merge_into(st_uncounted, bead_mesh, Transform3D(Basis(), Vector3(x2, y, 0.0)))

	_cl_commit_batch(parent, st_counted, mat_counted, "BeadsCounted", false)
	_cl_commit_batch(parent, st_uncounted, mat_uncounted, "BeadsUncounted", false)
	_cl_commit_batch(parent, st_accent, mat_glow, "BeadsHighlight", false)


## A vertical reckoning bar (with top/bottom caps) cleaving counted from uncounted, brought forward.
func _aba_build_dividers(parent: Node3D, rods: int, mat: Material) -> void:
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var xl: float = _aba_inner_left()
	var xr: float = _aba_inner_right()
	var divider_x: float = (xl + xr) * 0.5
	var y_top: float = _aba_row_y(rods - 1, rods) + _ABA_BEAD_RADIUS + 0.06
	var y_bot: float = _aba_row_y(0, rods) - _ABA_BEAD_RADIUS - 0.06
	var cy: float = (y_top + y_bot) * 0.5
	var h: float = y_top - y_bot
	var bar_z: float = _ABA_BEAD_RADIUS * 0.85
	_cl_append_box_mesh(st, Vector3(divider_x, cy, bar_z), Vector3(_ABA_DIVIDER_T * 2.2, h, 0.05))
	_cl_append_box_mesh(st, Vector3(divider_x, y_top, bar_z), Vector3(_ABA_DIVIDER_T * 4.0, 0.05, 0.07))
	_cl_append_box_mesh(st, Vector3(divider_x, y_bot, bar_z), Vector3(_ABA_DIVIDER_T * 4.0, 0.05, 0.07))
	_cl_commit_batch(parent, st, mat, "Divider", false)


## One carved asemic numeral tick per counted bead, climbing the left margin rail (accent glow).
func _aba_build_ticks(parent: Node3D, rods: int, digits: Array[int], mat: Material) -> void:
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var margin_x: float = -_ABA_FRAME_W * 0.5 + _ABA_RAIL_T * 0.5
	for r: int in range(rods):
		var y: float = _aba_row_y(r, rods)
		var count: int = clampi(digits[r], 0, _ABA_BEADS_PER_ROD)
		for j: int in range(count):
			var ty: float = y - _ABA_TICK_H * float(count - 1) * 0.5 + _ABA_TICK_H * float(j)
			_cl_append_box_mesh(st, Vector3(margin_x, ty, _ABA_FRAME_DEPTH * 0.5 + 0.012),
				Vector3(_ABA_TICK_W, _ABA_TICK_H * 0.55, 0.012))
	_cl_commit_batch(parent, st, mat, "NumeralTicks", false)


## Two turned wooden feet (revolution profiles) under the frame.
func _aba_build_feet(parent: Node3D, mat: Material) -> void:
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var profile: Array[Vector2] = [
		Vector2(0.0, -0.10), Vector2(0.085, -0.09), Vector2(0.075, -0.045),
		Vector2(0.045, -0.02), Vector2(0.05, 0.0),
	]
	var foot: Mesh = MorphoPrimitive.revolution(profile, 14)
	if foot == null:
		return
	var fx: float = _ABA_FRAME_W * 0.5 - _ABA_RAIL_T * 0.6
	for sx: int in [-1, 1]:
		_cl_merge_into(st, foot, Transform3D(Basis(), Vector3(float(sx) * fx, 0.0, 0.0)))
	_cl_commit_batch(parent, st, mat, "Feet", false)


# =============================================================================
# MODE: boardtrack — a REAL GRID-INDEX traversal board (trial v3)
#
# The genuine algorithm (linear-index decode of a 2D array, the load-bearing core):
#   A 2D array read as a linear-index TRACK. The board is an N×N grid of raised tile CELLS
#   (alternating warm/cool tints, a checkerboard). A numbered TRACK snakes through the cells in
#   BOUSTROPHEDON order: linear index k maps to (row = k // W, col = k % W) with the column direction
#   REVERSING every other row (col = raw on even rows, W-1-raw on odd). A thin raised RIBBON follows
#   that path from k=0 to k=track_len-1 — the ribbon IS the for-loop walking the array, and the
#   reversal is the snakes-and-ladders numbering. Direction chevrons mark increasing index; pawns sit
#   on indexed cells; 2-3 LADDER/PORTAL bezier arcs jump between non-adjacent cells (a real shortcut,
#   endpoints from the seeded RNG); the last cell GLOWS as the finish, k=0 gets a start pad. Cell tops
#   batch into one ArrayMesh per tint. complexity scales the board size (6..10 per side).
# =============================================================================

const _BOARD_SPAN: float = 2.55           # target planar span (m) of cells
const _BOARD_CELL_GAP_FRAC: float = 0.16  # gap between cells as frac of pitch
const _BOARD_CELL_RISE: float = 0.105     # tile thickness
const _BOARD_BASE_RISE: float = 0.100     # under-board slab thickness
const _BOARD_FRAME_RISE: float = 0.180    # border frame height
const _BOARD_RIBBON_RISE: float = 0.028   # ribbon sits above cell tops
const _BOARD_TILT_DEG: float = 14.0       # tilt toward +X/+Z camera

var _board_cols: int = 8
var _board_rows: int = 8
var _board_pitch: float = 0.30
var _board_cell_size: float = 0.27
var _board_track_len: int = 64


func _build_boardtrack() -> void:
	# Resolve board size from complexity: 6×6 at low, up to 10×10.
	var n: int = clampi(4 + complexity, 6, 10)
	_board_cols = n
	_board_rows = n
	_board_pitch = _BOARD_SPAN / float(_board_cols)
	_board_cell_size = _board_pitch * (1.0 - _BOARD_CELL_GAP_FRAC)
	_board_track_len = _board_rows * _board_cols

	var mat_a := _cl_primary_mat(color_a.lerp(Color(0.88, 0.65, 0.43), 0.4))    # warm cell tint A
	var mat_b := _cl_secondary_mat(color_b.lerp(Color(0.40, 0.52, 0.62), 0.4))  # cool cell tint B
	var mat_dark := _cl_secondary_mat(color_b.lerp(Color(0.20, 0.26, 0.33), 0.6))  # frame + base slab
	var mat_accent := _cl_glow_mat(accent, 2.6)                                  # track / finish / ladders
	var mat_pawn := _cl_primary_mat(color_a.lerp(Color(0.90, 0.88, 0.82), 0.55)) # lit pawn bodies

	# Tilt the whole board toward the camera (Basis only).
	var tilt := Basis().rotated(Vector3(1.0, 0.0, -1.0).normalized(), deg_to_rad(_BOARD_TILT_DEG))
	var board := Node3D.new()
	board.name = "Board"
	board.basis = tilt
	add_child(board)

	_board_build_base_slab(board, mat_dark)
	_board_build_frame(board, mat_dark)
	_board_build_cells(board, mat_a, mat_b)
	_board_build_track_ribbon(board, mat_accent)
	_board_build_arrows(board, mat_accent)
	_board_build_finish_and_start(board, mat_accent)
	_board_build_ladders(board, mat_accent)
	_board_build_counters(board, mat_pawn, mat_accent)

	_cl_settle(board, maxf(_BOARD_SPAN * (sculpt_height / 1.8), 0.4), maxf(sculpt_width, 0.2), true)


## Planar (x, z) centre of grid cell (row, col), board centred on the origin. Row 0 at -Z.
func _board_cell_center(row: int, col: int) -> Vector3:
	var x: float = (float(col) - float(_board_cols - 1) * 0.5) * _board_pitch
	var z: float = (float(row) - float(_board_rows - 1) * 0.5) * _board_pitch
	return Vector3(x, 0.0, z)


## Boustrophedon decode of linear index k → (row, col):
##   row = k // W (integer division), raw = k % W (modulo),
##   col = raw on even rows, (W-1-raw) on odd rows (the snake reversal).
## This is the snakes-and-ladders numbering. The ONLY place index → (row,col) happens.
func _board_index_to_cell(k: int) -> Vector2i:
	var w: int = _board_cols
	var row: int = k / w
	var raw: int = k % w
	var col: int = raw if (row % 2 == 0) else (w - 1 - raw)
	return Vector2i(row, col)


## Standard checkerboard parity on (row + col).
func _board_is_tint_a(row: int, col: int) -> bool:
	return ((row + col) % 2) == 0


## Under-board slab — one box spanning the whole grid.
func _board_build_base_slab(parent: Node3D, mat: Material) -> void:
	var span: float = _board_pitch * float(_board_cols)
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_cl_emit_box(st, Vector3(0.0, -_BOARD_BASE_RISE * 0.5, 0.0),
		Vector3.RIGHT, Vector3.UP, Vector3.BACK, span * 0.5, _BOARD_BASE_RISE * 0.5, span * 0.5)
	_cl_commit_batch(parent, st, mat, "BaseSlab", false)


## Border frame — four bars around the playfield, batched into one mesh.
func _board_build_frame(parent: Node3D, mat: Material) -> void:
	var half: float = _board_pitch * float(_board_cols) * 0.5
	var bar_w: float = _board_pitch * 0.42
	var outer: float = half + bar_w * 0.5
	var y: float = _BOARD_FRAME_RISE * 0.5
	var hy: float = _BOARD_FRAME_RISE * 0.5
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var run: float = outer
	_cl_emit_box(st, Vector3(0.0, y, -half - bar_w * 0.5), Vector3.RIGHT, Vector3.UP, Vector3.BACK,
		run, hy, bar_w * 0.5)
	_cl_emit_box(st, Vector3(0.0, y, half + bar_w * 0.5), Vector3.RIGHT, Vector3.UP, Vector3.BACK,
		run, hy, bar_w * 0.5)
	_cl_emit_box(st, Vector3(-half - bar_w * 0.5, y, 0.0), Vector3.RIGHT, Vector3.UP, Vector3.BACK,
		bar_w * 0.5, hy, run)
	_cl_emit_box(st, Vector3(half + bar_w * 0.5, y, 0.0), Vector3.RIGHT, Vector3.UP, Vector3.BACK,
		bar_w * 0.5, hy, run)
	_cl_commit_batch(parent, st, mat, "Frame", false)


## Raised tile cells — every (row, col) a thin box, batched into TWO meshes by checkerboard tint.
func _board_build_cells(parent: Node3D, mat_a: Material, mat_b: Material) -> void:
	var st_a := SurfaceTool.new(); st_a.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_b := SurfaceTool.new(); st_b.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hs: float = _board_cell_size * 0.5
	var hy: float = _BOARD_CELL_RISE * 0.5
	for row: int in range(_board_rows):
		for col: int in range(_board_cols):
			var p: Vector3 = _board_cell_center(row, col)
			p.y = _BOARD_CELL_RISE * 0.5
			var target: SurfaceTool = st_a if _board_is_tint_a(row, col) else st_b
			_cl_emit_box(target, p, Vector3.RIGHT, Vector3.UP, Vector3.BACK, hs, hy, hs)
	_cl_commit_batch(parent, st_a, mat_a, "CellsA", false)
	_cl_commit_batch(parent, st_b, mat_b, "CellsB", false)


## Track ribbon — a thin raised accent strip following boustrophedon order k=0..track_len-1, segment
## by segment, each oriented along the path direction via Basis. The for-loop walking the array, made
## physical. Sparse accent nodes punctuate the line. Batched into one mesh.
func _board_build_track_ribbon(parent: Node3D, mat: Material) -> void:
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ribbon_w: float = _board_cell_size * 0.085
	var top_y: float = _BOARD_CELL_RISE + _BOARD_RIBBON_RISE
	var hw: float = ribbon_w * 0.5
	var hh: float = _BOARD_RIBBON_RISE * 0.5
	for k: int in range(_board_track_len - 1):
		var a_rc: Vector2i = _board_index_to_cell(k)
		var b_rc: Vector2i = _board_index_to_cell(k + 1)
		var a: Vector3 = _board_cell_center(a_rc.x, a_rc.y)
		var b: Vector3 = _board_cell_center(b_rc.x, b_rc.y)
		a.y = top_y
		b.y = top_y
		var seg: Vector3 = b - a
		var seg_len: float = seg.length()
		if seg_len < 0.0001:
			continue
		var fwd: Vector3 = seg / seg_len
		var side: Vector3 = Vector3.UP.cross(fwd).normalized()
		var mid: Vector3 = (a + b) * 0.5
		_cl_emit_box(st, mid, fwd, Vector3.UP, side, seg_len * 0.5 + hw, hh, hw)
	var node_r: float = _board_cell_size * 0.085
	var node_step: int = maxi(3, _board_cols - 2)
	for k2: int in range(0, _board_track_len, node_step):
		var rc: Vector2i = _board_index_to_cell(k2)
		var p: Vector3 = _board_cell_center(rc.x, rc.y)
		p.y = top_y
		_cl_emit_box(st, p, Vector3.RIGHT, Vector3.UP, Vector3.BACK, node_r, hh, node_r)
	_cl_commit_batch(parent, st, mat, "TrackRibbon", false)


## Direction chevrons on every few cells, pointing in the direction of increasing index. Batched.
func _board_build_arrows(parent: Node3D, mat: Material) -> void:
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top_y: float = _BOARD_CELL_RISE + _BOARD_RIBBON_RISE * 2.0
	var arm: float = _board_cell_size * 0.22
	var bar_w: float = _board_cell_size * 0.07
	var hh: float = _BOARD_RIBBON_RISE * 0.5
	var step: int = maxi(2, _board_cols / 4)
	var k: int = 1
	while k < _board_track_len - 1:
		var rc: Vector2i = _board_index_to_cell(k)
		var nxt: Vector2i = _board_index_to_cell(k + 1)
		var here: Vector3 = _board_cell_center(rc.x, rc.y)
		var there: Vector3 = _board_cell_center(nxt.x, nxt.y)
		here.y = top_y
		var fwd: Vector3 = (there - here)
		fwd.y = 0.0
		if fwd.length() < 0.0001:
			k += step
			continue
		fwd = fwd.normalized()
		var side: Vector3 = Vector3.UP.cross(fwd).normalized()
		var tip: Vector3 = here + fwd * (arm * 0.55)
		_board_emit_chevron_arm(st, tip, fwd, side, arm, bar_w, hh, 1.0)
		_board_emit_chevron_arm(st, tip, fwd, side, arm, bar_w, hh, -1.0)
		k += step
	_cl_commit_batch(parent, st, mat, "Arrows", false)


## One arm of a chevron: a thin box from `tip` sweeping back-and-out (35° off the back vector).
func _board_emit_chevron_arm(st: SurfaceTool, tip: Vector3, fwd: Vector3, side: Vector3,
		arm: float, bar_w: float, hh: float, sign: float) -> void:
	var back: Vector3 = -fwd
	var ang: float = deg_to_rad(35.0)
	var dir: Vector3 = (back * cos(ang) + side * sign * sin(ang)).normalized()
	var mid: Vector3 = tip + dir * (arm * 0.5)
	var perp: Vector3 = Vector3.UP.cross(dir).normalized()
	_cl_emit_box(st, mid, dir, Vector3.UP, perp, arm * 0.5, hh, bar_w * 0.5)


## Glowing finish (cap + tapered post + orb) on the last cell, and a start pad (open accent ring) on
## k=0, so the entry and destination of the traversal both read.
func _board_build_finish_and_start(parent: Node3D, mat: Material) -> void:
	var last: Vector2i = _board_index_to_cell(_board_track_len - 1)
	var p: Vector3 = _board_cell_center(last.x, last.y)

	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hs: float = _board_cell_size * 0.40
	_cl_emit_box(st, Vector3(p.x, _BOARD_CELL_RISE + _BOARD_RIBBON_RISE * 0.5, p.z),
		Vector3.RIGHT, Vector3.UP, Vector3.BACK, hs, _BOARD_RIBBON_RISE * 0.6, hs)
	_cl_commit_batch(parent, st, mat, "FinishCap", false)

	var post_profile: Array[Vector2] = [
		Vector2(_board_cell_size * 0.16, 0.0),
		Vector2(_board_cell_size * 0.13, _board_cell_size * 0.20),
		Vector2(_board_cell_size * 0.08, _board_cell_size * 0.55),
		Vector2(_board_cell_size * 0.04, _board_cell_size * 0.95),
		Vector2(0.0, _board_cell_size * 1.10),
	]
	_cl_add_mesh(parent, MorphoPrimitive.revolution(post_profile, 14), mat,
		Transform3D(Basis.IDENTITY, Vector3(p.x, _BOARD_CELL_RISE, p.z)), "FinishPost")
	_cl_add_mesh(parent, MorphoPrimitive.sphere(_board_cell_size * 0.12, 12, 8), mat,
		Transform3D(Basis.IDENTITY, Vector3(p.x, _BOARD_CELL_RISE + _board_cell_size * 1.14, p.z)), "FinishOrb")

	var start_rc: Vector2i = _board_index_to_cell(0)
	var sp: Vector3 = _board_cell_center(start_rc.x, start_rc.y)
	var sst := SurfaceTool.new(); sst.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring_half: float = _board_cell_size * 0.40
	var ring_t: float = _board_cell_size * 0.07
	var ry: float = _BOARD_CELL_RISE + _BOARD_RIBBON_RISE * 0.6
	var rhy: float = _BOARD_RIBBON_RISE * 0.6
	_cl_emit_box(sst, Vector3(sp.x, ry, sp.z - ring_half), Vector3.RIGHT, Vector3.UP, Vector3.BACK,
		ring_half + ring_t * 0.5, rhy, ring_t * 0.5)
	_cl_emit_box(sst, Vector3(sp.x, ry, sp.z + ring_half), Vector3.RIGHT, Vector3.UP, Vector3.BACK,
		ring_half + ring_t * 0.5, rhy, ring_t * 0.5)
	_cl_emit_box(sst, Vector3(sp.x - ring_half, ry, sp.z), Vector3.RIGHT, Vector3.UP, Vector3.BACK,
		ring_t * 0.5, rhy, ring_half + ring_t * 0.5)
	_cl_emit_box(sst, Vector3(sp.x + ring_half, ry, sp.z), Vector3.RIGHT, Vector3.UP, Vector3.BACK,
		ring_t * 0.5, rhy, ring_half + ring_t * 0.5)
	_cl_commit_batch(parent, sst, mat, "StartPad", false)


## Ladders / portals — accent bezier arcs jumping between two non-adjacent cells. Deterministic:
## endpoints from the seeded RNG, constrained so the two cells differ in linear index by a decent jump
## (a real shortcut). Each arc is a MorphoPrimitive.bezier_sweep tube with glowing feet at both ends.
func _board_build_ladders(parent: Node3D, mat: Material) -> void:
	var jumps: int = 3
	var placed: int = 0
	var used: Array[int] = []
	var attempts: int = 0
	while placed < jumps and attempts < 60:
		attempts += 1
		var k_a: int = _rng.randi_range(2, _board_track_len - 4)
		var span_min: int = maxi(_board_cols, 5)
		var k_b: int = k_a + _rng.randi_range(span_min, span_min + _board_cols)
		if k_b >= _board_track_len - 1:
			continue
		if used.has(k_a) or used.has(k_b):
			continue
		used.append(k_a)
		used.append(k_b)
		var rc_a: Vector2i = _board_index_to_cell(k_a)
		var rc_b: Vector2i = _board_index_to_cell(k_b)
		var a: Vector3 = _board_cell_center(rc_a.x, rc_a.y); a.y = _BOARD_CELL_RISE
		var b: Vector3 = _board_cell_center(rc_b.x, rc_b.y); b.y = _BOARD_CELL_RISE
		var dist: float = a.distance_to(b)
		var lift: float = clampf(dist * 0.42, _board_pitch * 1.0, _board_pitch * 2.2)
		var c1: Vector3 = a.lerp(b, 0.30) + Vector3.UP * lift
		var c2: Vector3 = a.lerp(b, 0.70) + Vector3.UP * lift
		var control: Array[Vector3] = [a, c1, c2, b]
		var tube_r: float = _board_cell_size * 0.07
		var cross: Array[Vector2] = _board_ring_cross_section(tube_r, 7)
		var arc_mesh: Mesh = MorphoPrimitive.bezier_sweep(control, cross, 22, 0.0)
		_cl_add_mesh(parent, arc_mesh, mat, Transform3D.IDENTITY, "Ladder_%d_%d" % [k_a, k_b])
		_board_add_foot(parent, a, mat)
		_board_add_foot(parent, b, mat)
		placed += 1


## Counters / pawns — game pieces on cells, spread along the track in quartiles (jittered, seeded).
## Each pawn is a tapered revolution body topped by a glowing accent head.
func _board_build_counters(parent: Node3D, mat_pawn: Material, mat_glow: Material) -> void:
	var pawns: int = 4
	var placed: int = 0
	var seen: Array[int] = []
	var attempts: int = 0
	var body_profile: Array[Vector2] = [
		Vector2(_board_cell_size * 0.20, 0.0),
		Vector2(_board_cell_size * 0.17, _board_cell_size * 0.06),
		Vector2(_board_cell_size * 0.09, _board_cell_size * 0.14),
		Vector2(_board_cell_size * 0.07, _board_cell_size * 0.26),
		Vector2(_board_cell_size * 0.10, _board_cell_size * 0.36),
		Vector2(_board_cell_size * 0.07, _board_cell_size * 0.44),
		Vector2(0.0, _board_cell_size * 0.50),
	]
	while placed < pawns and attempts < 80:
		attempts += 1
		var quart: int = placed
		var lo: float = float(quart) / float(pawns)
		var hi: float = float(quart + 1) / float(pawns)
		var frac: float = _rng.randf_range(lo + 0.08, hi - 0.08)
		var k: int = clampi(int(round(frac * float(_board_track_len - 1))), 1, _board_track_len - 2)
		if seen.has(k):
			continue
		seen.append(k)
		var rc: Vector2i = _board_index_to_cell(k)
		var p: Vector3 = _board_cell_center(rc.x, rc.y); p.y = _BOARD_CELL_RISE
		_cl_add_mesh(parent, MorphoPrimitive.revolution(body_profile, 12), mat_pawn,
			Transform3D(Basis.IDENTITY, p), "Pawn_%d_body" % k)
		_cl_add_mesh(parent, MorphoPrimitive.sphere(_board_cell_size * 0.13, 12, 8), mat_glow,
			Transform3D(Basis.IDENTITY, p + Vector3(0.0, _board_cell_size * 0.56, 0.0)), "Pawn_%d_head" % k)
		placed += 1


## A small glowing accent sphere at a board position (ladder foot).
func _board_add_foot(parent: Node3D, at: Vector3, mat: Material) -> void:
	_cl_add_mesh(parent, MorphoPrimitive.sphere(_board_cell_size * 0.09, 10, 6), mat,
		Transform3D(Basis.IDENTITY, Vector3(at.x, _BOARD_CELL_RISE + _BOARD_RIBBON_RISE, at.z)), "LadderFoot")


## Closed circular cross-section (typed Array[Vector2]) for bezier_sweep tubes.
func _board_ring_cross_section(radius: float, sides: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for i: int in range(sides):
		var a: float = TAU * float(i) / float(sides)
		out.append(Vector2(cos(a) * radius, sin(a) * radius))
	return out


# =============================================================================
# MODE: wallpaper — a REAL WALLPAPER-GROUP tessellation (trial v4)
#
# The genuine algorithm (plane-symmetry group orbit, the load-bearing core):
#   A MOTIF (a small asymmetric relief in the unit square [0,1]^2) is replicated across an N×M grid by
#   the symmetry operations of a chosen WALLPAPER GROUP. Translation tiles the cells; per-cell
#   rotations / reflections / glides come from the group, each given as an explicit Transform2D acting
#   on the unit square — the list of transforms IS the orbit of the fundamental domain under the point
#   group, so the relief reads as a PROPER wallpaper pattern, not a random grid. Modular arithmetic on
#   (row, col) selects orientation phase ((row+col)%4) and accent marking ((row*2+col)%7==0). Five
#   groups implemented honestly: p4 (4 rotations), p4m (D4 = 8), p6m (D6 = 12), pmm (4 mirrors),
#   pgg (two glide reflections via parity). The motif is asymmetric ON PURPOSE so every copy is
#   recognisably re-oriented. Relief extrudes +z off a tilted slab; everything batches into 3 meshes
#   (motif-A / motif-B / accent) plus slab + frame. complexity scales the grid size.
# =============================================================================

const _WALL_PANEL_WIDTH: float = 2.2
const _WALL_PANEL_THICKNESS: float = 0.10
const _WALL_PANEL_TILT_DEG: float = 22.0
const _WALL_RELIEF_RISE: float = 0.05
const _WALL_GROUPS: PackedStringArray = ["p4", "p4m", "p6m", "pmm", "pgg"]


func _build_wallpaper() -> void:
	var panel := Node3D.new()
	panel.name = "Panel"
	add_child(panel)

	# Seed-chosen group.
	var group: String = _WALL_GROUPS[_rng.randi() % _WALL_GROUPS.size()]

	# Grid size scales with complexity (hex groups slightly wider). Kept modest so motifs stay legible.
	var base_cols: int = clampi(4 + complexity / 2, 5, 9)
	var cols: int = base_cols + (1 if group == "p6m" else 0)
	var rows: int = clampi(base_cols - 1, 4, 8)

	var margin: float = 0.16
	var usable_w: float = _WALL_PANEL_WIDTH - margin * 2.0
	var cell: float = usable_w / float(cols)
	var panel_height: float = cell * float(rows) + margin * 2.0

	var mat_a := _cl_primary_mat(color_a.lerp(Color(0.84, 0.40, 0.46), 0.5))    # motif (rose)
	var mat_b := _cl_secondary_mat(color_b.lerp(Color(0.34, 0.52, 0.56), 0.5))  # ground / secondary
	var mat_accent := _cl_glow_mat(accent, 2.2)

	# Slab (ground tone) + raised border frame (motif tone).
	_cl_add_mesh(panel, MorphoPrimitive.box(Vector3(_WALL_PANEL_WIDTH, panel_height, _WALL_PANEL_THICKNESS)),
		mat_b, Transform3D.IDENTITY, "PanelSlab")
	_wall_build_frame(panel, panel_height, mat_a)

	# Accumulate three surface tools (motif A, secondary B, accent gold).
	var st_a := SurfaceTool.new(); st_a.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_b := SurfaceTool.new(); st_b.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_accent := SurfaceTool.new(); st_accent.begin(Mesh.PRIMITIVE_TRIANGLES)

	var origin_x: float = -_WALL_PANEL_WIDTH * 0.5 + margin
	var origin_y: float = -panel_height * 0.5 + margin
	var face_z: float = _WALL_PANEL_THICKNESS * 0.5

	var motif: Array[Dictionary] = _wall_motif_pieces()

	for row: int in range(rows):
		for col: int in range(cols):
			# Modular arithmetic decides per-cell behaviour.
			var phase: int = (row + col) % 4
			var is_accent: bool = ((row * 2 + col) % 7) == 0
			var ops: Array[Transform2D] = _wall_group_ops(group, row, col, phase)
			var cx: float = origin_x + (float(col) + 0.5) * cell
			var cy: float = origin_y + (float(row) + 0.5) * cell
			for op: Transform2D in ops:
				for piece: Dictionary in motif:
					var tone: String = str(piece.get("tone", "a"))
					var st_target: SurfaceTool = st_b
					if tone == "a":
						st_target = st_accent if is_accent else st_a
					_wall_emit_piece(st_target, piece, op, cx, cy, cell, face_z)

	_cl_commit_batch(panel, st_a, mat_a, "MotifA", false)
	_cl_commit_batch(panel, st_b, mat_b, "MotifB", false)
	_cl_commit_batch(panel, st_accent, mat_accent, "MotifAccent", false)

	# Tilt the panel back so its face angles toward the +X/+Z camera (Basis only), then settle.
	panel.basis = Basis().rotated(Vector3.RIGHT, deg_to_rad(_WALL_PANEL_TILT_DEG))
	_cl_settle(panel, maxf(_WALL_PANEL_WIDTH * (sculpt_height / 1.8), 0.4), maxf(sculpt_width, 0.2), true)


## A small asymmetric relief motif in the unit square [0,1]^2 (a chiral L + diagonal blade + dome).
## Asymmetric ON PURPOSE so the group's rotations/mirrors are VISIBLE. Living in the lower-left
## quadrant keeps the fundamental domain in one quadrant so copies don't pile on the centre.
func _wall_motif_pieces() -> Array[Dictionary]:
	var pieces: Array[Dictionary] = []
	pieces.append({
		"kind": "box", "tone": "a",
		"center": Vector2(0.17, 0.30), "size": Vector2(0.11, 0.40), "rise": 1.0,
	})
	pieces.append({
		"kind": "box", "tone": "a",
		"center": Vector2(0.30, 0.135), "size": Vector2(0.38, 0.11), "rise": 1.0,
	})
	pieces.append({
		"kind": "bar", "tone": "b",
		"a": Vector2(0.24, 0.24), "b": Vector2(0.45, 0.45), "width": 0.085, "rise": 0.85,
	})
	pieces.append({
		"kind": "dome", "tone": "a",
		"center": Vector2(0.45, 0.45), "radius": 0.085, "rise": 1.4,
	})
	return pieces


## Symmetry operations for the chosen group, as Transform2D acting on the unit square. The list IS the
## orbit of the fundamental domain under the point group; tiling by translation realises the plane
## group. `phase` rotates the whole orbit by a lattice-consistent amount (still the same group).
func _wall_group_ops(group: String, row: int, col: int, phase: int) -> Array[Transform2D]:
	match group:
		"p4":
			return _wall_ops_p4(phase)
		"p4m":
			return _wall_ops_p4m()
		"p6m":
			return _wall_ops_p6m()
		"pmm":
			return _wall_ops_pmm()
		"pgg":
			return _wall_ops_pgg(row, col)
		_:
			return _wall_ops_p4(0)


## p4: four copies, each rotated 90° about the cell centre. No mirrors.
func _wall_ops_p4(phase: int) -> Array[Transform2D]:
	var ops: Array[Transform2D] = []
	var base: float = float(phase) * (PI * 0.5)
	for k: int in range(4):
		ops.append(_wall_rot_about_center(base + float(k) * (PI * 0.5)))
	return ops


## p4m: the full square symmetry D4 — 4 rotations × a mirror = 8 copies.
func _wall_ops_p4m() -> Array[Transform2D]:
	var ops: Array[Transform2D] = []
	for k: int in range(4):
		var ang: float = float(k) * (PI * 0.5)
		ops.append(_wall_rot_about_center(ang))
		ops.append(_wall_rot_about_center(ang) * _wall_mirror_x_center())
	return ops


## p6m: hexagonal D6 — 6 rotations (60° each) × a mirror = 12 copies around the cell centre.
func _wall_ops_p6m() -> Array[Transform2D]:
	var ops: Array[Transform2D] = []
	for k: int in range(6):
		var ang: float = float(k) * (PI / 3.0)
		ops.append(_wall_rot_about_center(ang))
		ops.append(_wall_rot_about_center(ang) * _wall_mirror_x_center())
	return ops


## pmm: mirror in x AND mirror in y → 4 copies (identity, mx, my, mx·my).
func _wall_ops_pmm() -> Array[Transform2D]:
	var ops: Array[Transform2D] = []
	ops.append(Transform2D.IDENTITY)
	ops.append(_wall_mirror_x_center())
	ops.append(_wall_mirror_y_center())
	ops.append(_wall_mirror_x_center() * _wall_mirror_y_center())
	return ops


## pgg: two perpendicular glide reflections, no mirror lines. Realised as a 2×2 super-cell where
## alternating cells carry a glide (half-cell shift + reflection). Parity from (row,col) selects the
## glide variant — the modular-arithmetic heart of pgg.
func _wall_ops_pgg(row: int, col: int) -> Array[Transform2D]:
	var ops: Array[Transform2D] = []
	var rx: int = row % 2
	var cy: int = col % 2
	if (rx + cy) % 2 == 0:
		ops.append(Transform2D.IDENTITY)
	else:
		ops.append(_wall_rot_about_center(PI))
	var glide: Transform2D = _wall_mirror_x_center()
	var shift: float = 0.5 if cy == 0 else -0.5
	glide = Transform2D(0.0, Vector2(0.0, shift)) * glide
	ops.append(glide)
	return ops


# ── Transform2D helpers (act on the unit square, centred at 0.5,0.5) ──

func _wall_rot_about_center(angle: float) -> Transform2D:
	var c := Vector2(0.5, 0.5)
	var to_origin := Transform2D(0.0, -c)
	var rot := Transform2D(angle, Vector2.ZERO)
	var back := Transform2D(0.0, c)
	return back * rot * to_origin


func _wall_mirror_x_center() -> Transform2D:
	var c := Vector2(0.5, 0.5)
	var to_origin := Transform2D(0.0, -c)
	var flip := Transform2D(Vector2(-1.0, 0.0), Vector2(0.0, 1.0), Vector2.ZERO)
	var back := Transform2D(0.0, c)
	return back * flip * to_origin


func _wall_mirror_y_center() -> Transform2D:
	var c := Vector2(0.5, 0.5)
	var to_origin := Transform2D(0.0, -c)
	var flip := Transform2D(Vector2(1.0, 0.0), Vector2(0.0, -1.0), Vector2.ZERO)
	var back := Transform2D(0.0, c)
	return back * flip * to_origin


## Turn one motif piece (under one symmetry op, in one cell) into triangles on the target
## SurfaceTool. All relief extrudes +z off the slab face; a piece's 2D footprint maps through `op`
## (cell-local) then to panel coordinates.
func _wall_emit_piece(st: SurfaceTool, piece: Dictionary, op: Transform2D,
		cx: float, cy: float, cell: float, face_z: float) -> void:
	var kind: String = str(piece.get("kind", "box"))
	var rise: float = float(piece.get("rise", 1.0)) * _WALL_RELIEF_RISE
	match kind:
		"box":
			var center: Vector2 = piece["center"] as Vector2
			var size: Vector2 = piece["size"] as Vector2
			var hx: float = size.x * 0.5
			var hy: float = size.y * 0.5
			var corners: Array[Vector2] = [
				center + Vector2(-hx, -hy), center + Vector2(hx, -hy),
				center + Vector2(hx, hy), center + Vector2(-hx, hy),
			]
			_wall_emit_quad_prism(st, corners, op, cx, cy, cell, face_z, rise)
		"bar":
			var pa: Vector2 = piece["a"] as Vector2
			var pb: Vector2 = piece["b"] as Vector2
			var width: float = float(piece["width"])
			var dir: Vector2 = (pb - pa)
			if dir.length() < 0.0001:
				return
			dir = dir.normalized()
			var perp: Vector2 = Vector2(-dir.y, dir.x) * (width * 0.5)
			var corners_b: Array[Vector2] = [pa - perp, pb - perp, pb + perp, pa + perp]
			_wall_emit_quad_prism(st, corners_b, op, cx, cy, cell, face_z, rise)
		"dome":
			var dc: Vector2 = piece["center"] as Vector2
			var radius: float = float(piece["radius"])
			_wall_emit_dome(st, dc, radius, op, cx, cy, cell, face_z, rise)
		_:
			pass


## Map a cell-local 2D point through the symmetry op and into panel-plane world coords (x horizontal,
## y vertical), at relief depth z.
func _wall_to_world(p_local: Vector2, op: Transform2D, cx: float, cy: float,
		cell: float, z: float) -> Vector3:
	var t: Vector2 = op * p_local
	var off: Vector2 = (t - Vector2(0.5, 0.5)) * cell
	return Vector3(cx + off.x, cy + off.y, z)


## Extrude a 4-corner footprint from the slab face (face_z) out to face_z+rise (top + 4 side walls).
func _wall_emit_quad_prism(st: SurfaceTool, corners: Array[Vector2], op: Transform2D,
		cx: float, cy: float, cell: float, face_z: float, rise: float) -> void:
	var top_z: float = face_z + rise
	var base: Array[Vector3] = []
	var top: Array[Vector3] = []
	for cnr: Vector2 in corners:
		base.append(_wall_to_world(cnr, op, cx, cy, cell, face_z))
		top.append(_wall_to_world(cnr, op, cx, cy, cell, top_z))
	var n_top := Vector3(0.0, 0.0, 1.0)
	_wall_tri(st, top[0], top[1], top[2], n_top)
	_wall_tri(st, top[0], top[2], top[3], n_top)
	for i: int in range(4):
		var j: int = (i + 1) % 4
		var b0: Vector3 = base[i]
		var b1: Vector3 = base[j]
		var t1: Vector3 = top[j]
		var t0: Vector3 = top[i]
		var wn: Vector3 = (b1 - b0).cross(t0 - b0)
		if wn.length() > 0.00001:
			wn = wn.normalized()
		else:
			wn = Vector3(0.0, 0.0, 1.0)
		_wall_tri(st, b0, b1, t1, wn)
		_wall_tri(st, b0, t1, t0, wn)


## A small revolution-style dome (apex + rim fan) honouring the symmetry op for its centre position.
func _wall_emit_dome(st: SurfaceTool, center: Vector2, radius: float, op: Transform2D,
		cx: float, cy: float, cell: float, face_z: float, rise: float) -> void:
	var segments: int = 10
	var apex: Vector3 = _wall_to_world(center, op, cx, cy, cell, face_z + rise)
	var rim: Array[Vector3] = []
	for s: int in range(segments):
		var ang: float = TAU * float(s) / float(segments)
		var rim_local: Vector2 = center + Vector2(cos(ang), sin(ang)) * radius
		rim.append(_wall_to_world(rim_local, op, cx, cy, cell, face_z))
	for s: int in range(segments):
		var s_next: int = (s + 1) % segments
		var r0: Vector3 = rim[s]
		var r1: Vector3 = rim[s_next]
		var n: Vector3 = (r1 - r0).cross(apex - r0)
		if n.length() > 0.00001:
			n = n.normalized()
		else:
			n = Vector3(0.0, 0.0, 1.0)
		_wall_tri(st, r0, r1, apex, n)


func _wall_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(b)
	st.set_normal(n); st.add_vertex(c)


## A thin raised border frame around the panel face (motif tone), as four quad prisms.
func _wall_build_frame(parent: Node3D, panel_height: float, mat: Material) -> void:
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var fw: float = 0.06
	var z0: float = _WALL_PANEL_THICKNESS * 0.5
	var z1: float = z0 + _WALL_RELIEF_RISE * 0.8
	var hw: float = _WALL_PANEL_WIDTH * 0.5
	var hh: float = panel_height * 0.5
	var bars: Array = [
		[Vector2(-hw, hh - fw), Vector2(hw, hh - fw), Vector2(hw, hh), Vector2(-hw, hh)],
		[Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, -hh + fw), Vector2(-hw, -hh + fw)],
		[Vector2(-hw, -hh + fw), Vector2(-hw + fw, -hh + fw), Vector2(-hw + fw, hh - fw), Vector2(-hw, hh - fw)],
		[Vector2(hw - fw, -hh + fw), Vector2(hw, -hh + fw), Vector2(hw, hh - fw), Vector2(hw - fw, hh - fw)],
	]
	for bar_v: Variant in bars:
		var bar: Array = bar_v as Array
		var base: Array[Vector3] = []
		var top: Array[Vector3] = []
		for p_v: Variant in bar:
			var p: Vector2 = p_v as Vector2
			base.append(Vector3(p.x, p.y, z0))
			top.append(Vector3(p.x, p.y, z1))
		var n_top := Vector3(0.0, 0.0, 1.0)
		_wall_tri(st, top[0], top[1], top[2], n_top)
		_wall_tri(st, top[0], top[2], top[3], n_top)
		for i: int in range(4):
			var j: int = (i + 1) % 4
			var wn: Vector3 = (base[j] - base[i]).cross(top[i] - base[i])
			if wn.length() > 0.00001:
				wn = wn.normalized()
			else:
				wn = Vector3(0.0, 0.0, 1.0)
			_wall_tri(st, base[i], base[j], top[j], wn)
			_wall_tri(st, base[i], top[j], top[i], wn)
	_cl_commit_batch(parent, st, mat, "PanelFrame", false)
