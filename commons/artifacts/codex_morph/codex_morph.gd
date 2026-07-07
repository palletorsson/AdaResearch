extends Node3D
class_name CodexMorph

## @identity
# essence: a single DNA-driven CODEX MORPHOGENESIS SPECIMEN grown not as a primitive-stack
#   but as a GENUINE morphogenesis ALGORITHM run live. Where most artifacts assemble a
#   creature from boxes and spheres, CodexMorph COMPUTES its form: a developmental clock, a
#   cellular automaton, a reaction-diffusion field, or an evolving genome decides the shape,
#   and the mesh is only its read-out. Luigi Serafini's Codex Seraphinianus fauna-and-
#   metamorphosis plates are the muse; the three founding morphogenesis theories are the
#   engine. Depending on its `mode` DNA it becomes one of FOUR teaching specimens whose form
#   IS its process: lifecycle (a developmental STAGE-SEQUENCE — egg -> segmented larva ->
#   ribbed pupa -> winged-horned adult — growing along a gentle arc, threaded by a glowing
#   progression line so the row reads as ONE creature developing through time), division (a
#   REAL Conway's Game of Life run B3/S23 on a seeded grid for fixed iterations, then its
#   final state embodied as a translucent cell colony on a petri-mound — brightly glowing
#   NEWBORNS, dumbbell MITOSIS cells, faded DYING husks, classed by comparing three CA
#   snapshots), turing (a REAL Gray-Scott reaction-diffusion sim integrated in the SPOTS
#   regime on a toroidal lattice for thousands of steps, the V field mapped onto a smooth
#   ellipsoid beast as raised teal-rimmed rose OCELLI — the spots are not painted, they
#   EMERGE; the hero of the set), and taxon (an evolved-variant taxonomy GRID — one typed-
#   Dictionary base genome MUTATED per cell by a seeded RNG, with a directional SELECTION
#   axis across columns and neutral DRIFT down rows, growing a grid of spiny hue-shifted
#   Codex egg-pods on a tray). It is identity confessed as a PROCESS — the body is the
#   computation, not its parts.
# desire: it wants the algorithm to stay LEGIBLE and GENUINE — the developmental arc, the
#   Life dynamics (newborn/dying/dividing read AT A GLANCE), the Turing spots (real ocelli
#   catching the key light, not a texture), and the selection cline (left plain -> right
#   elaborate) must read as COMPUTED, never hand-placed. It wants FLESH to glow soft with an
#   emission floor so bodies never collapse to black against the dark capture, SHELL /
#   structure to read matte and cool, and GLOW (nucleus / eye / core / RD-spot) to BURN
#   bioluminescent. Above all it wants every sim BOUNDED — the Life and RD runs seeded with
#   fixed iteration counts so each launch is identical.
# critical_parameter: mode + seed + the colour triad (color_a FLESH/body/membrane/skin /
#   color_b SHELL/structure/segment/tray / accent GLOW/nucleus/eye/core/RD-spot) +
#   complexity. mode picks the morphogenesis lineage; seed varies the individual
#   deterministically (a local seeded RNG, no global randf/randi ever — it drives the Life
#   seeding, the RD V-blob scatter, every genome mutation, every jitter); complexity scales
#   lifecycle STAGE COUNT, Life GRID SIZE + iterations, RD GRID + iterations, and taxon GRID
#   SIZE. Higher complexity = a bigger sim / a longer development.
# triggers: _ready() reads DNA metadata overrides, seeds the RNG from `seed`, and branches
#   on `mode` to a _build_<mode>() helper; apply_grid_config rewrites config metas, clears
#   children (remove BEFORE free, guarded by `_built`), and rebuilds.
# emerges: a row of these reads as a CABINET OF MORPHOGENESES — four ways a form can compute
#   itself. Switch one mode and the room's idea of "what makes a creature" shifts from
#   assembly to GENERATION; reseed and the species persists while its individual varies.
#   These are teaching specimens for the morphogenesis cluster: lifecycle + division for the
#   cellularautomata room, turing for softbodies / reaction-diffusion, taxon for
#   machinelearning / evolution.
# needs: a seeded RNG for deterministic individuals [present]; four build branches each
#   carrying its trial's genuine algorithm self-contained (developmental clock, hand-rolled
#   Conway Life, hand-rolled Gray-Scott RD, typed-Dictionary genome mutation) [present];
#   flesh / shell / glow materials driven by the colour triad [present]; cells / spikes /
#   stage sub-parts batched into one ArrayMesh per kind so the AABB capture frames the
#   specimen [present]; the morphology toolkit statics (MorphoPrimitive / MorphoModifier) for
#   surface generation [present].
# relationships: kin to codex_flora (same genome shape + conventions — identity header,
#   grouped @export, apply_grid_config + _parse_color + _built rebuild guard, self-clearing
#   idempotent _build(), seeded RNG, settle centring; codex_flora grows L-system grammars,
#   CodexMorph runs morphogenesis sims); kin to haeckel (the shared Codex-bio genome shape);
#   built on the nature_system morphology engine it borrows from (MorphoPrimitive /
#   MorphoModifier); cousin to any mode-switchboard of one genome.
# truth: form is a PROCESS — the pattern computes itself. Serafini drew fauna that could not
#   exist; morphogenesis grows fauna that did not exist until the rule ran. CodexMorph holds
#   four such processes in one genome where the body is COMPUTED — a developmental arc, a
#   living cellular automaton, an emergent Turing coat, an evolving population — and lets a
#   single parameter choose which process the viewer is invited to read. The algorithm must
#   stay genuine, the flesh must glow, the spot must burn, and above all the sim must be
#   bounded and deterministic.

## A multi-mode generative Codex-morphogenesis specimen run as a GENUINE algorithm.
##
## Built procedurally from DNA exports, after Luigi Serafini's Codex Seraphinianus, for the
## morphogenesis curriculum cluster (cellularautomata / softbodies-reaction-diffusion /
## machinelearning-evolution). The `mode` export selects one of FOUR processes, each ported
## faithfully from a verified trial INCLUDING its real algorithm:
## lifecycle (a developmental stage-sequence egg -> larva -> pupa -> winged adult growing
## along an arc, threaded by a glowing progression line),
## division (a REAL Conway's Game of Life run B3/S23 on a seeded grid for fixed iterations,
## its final state embodied as a translucent cell colony — newborn glow, dumbbell mitosis,
## dying husks — classed by comparing prev/final/next CA snapshots),
## turing (a REAL Gray-Scott reaction-diffusion sim in the SPOTS regime mapped onto a smooth
## creature as raised teal-rimmed rose ocelli + a 1x128 ramp texture; glowing eyes — the
## hero),
## taxon (an evolved-variant taxonomy grid — one typed-Dictionary genome mutated per cell by
## a seeded RNG, a directional selection axis across columns + neutral drift down rows,
## growing a grid of spiny hue-shifted Codex egg-pods on a tray).
##
## A seeded RNG makes every individual deterministic from its `seed`. The colour triad
## (color_a FLESH / color_b SHELL / accent GLOW) re-registers the same anatomy between
## palettes. Shared material + orient + settle + batch helpers live under the `_cm_` prefix;
## the genuine algorithm from each trial stays in its own builder under `_lc_` / `_life_` /
## `_rd_` / `_tax_` so the Life sim, the Gray-Scott RD sim, and the genome mutation are
## preserved — that is the whole point. Surface generation reuses the morphology toolkit
## statics (MorphoPrimitive, MorphoModifier).
##
## complexity scales the morphogenesis budget per mode: lifecycle STAGE COUNT (5..7), Life
## GRID SIZE (12..18) + iterations, RD GRID (96..150) + iterations, taxon GRID columns
## (3..4). Higher complexity = a bigger sim / a longer development.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Form")
## lifecycle | division | turing | taxon
@export var mode: String = "lifecycle"
## Deterministic seed — same seed always yields the same specimen.
@export var seed: int = 0
## Detail / sim budget. Scales lifecycle stage count, Life grid size + iterations, RD grid +
## iterations, and taxon grid columns. Higher = a bigger sim / a longer development.
@export var complexity: int = 6
## Overall height in meters (nominal full height of the specimen).
@export var sculpt_height: float = 1.6
## Footprint / across-span width scale in meters (1.0 = native trial proportions).
@export var sculpt_width: float = 1.0

@export_group("Material")
## FLESH / body / cell membrane / creature skin — warm Codex coral.
@export var color_a: Color = Color(0.86, 0.42, 0.40)
## SHELL / structure / segment / pattern / tray — cool slate backbone.
@export var color_b: Color = Color(0.30, 0.34, 0.40)
## GLOW / nucleus / eye / core / RD-spot — bioluminescent accent.
@export var accent: Color = Color(0.45, 0.95, 0.85)
## Living matter, not metal — keep this LOW.
@export var metallic_amt: float = 0.0
@export var rough_amt: float = 0.65
## Boost emissive energies (glow reads hotter when true).
@export var emissive: bool = true

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false
var _rng := RandomNumberGenerator.new()


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
	# Self-clear so the build is idempotent no matter who calls it: if `_ready()` fires
	# DEFERRED (after apply_grid_config has already built), a second _build() must not stack
	# a second specimen on top of the first (which previously doubled mesh counts on the
	# first instance per process — the capture path). Remove BEFORE freeing (queue_free is
	# deferred) so the rebuild starts from a genuinely empty subtree this frame.
	for c: Node in get_children():
		remove_child(c)
		c.queue_free()
	_built = true
	_rng.seed = seed
	match mode:
		"lifecycle":
			_build_lifecycle()
		"division":
			_build_division()
		"turing":
			_build_turing()
		"taxon":
			_build_taxon()
		_:
			# Unknown mode falls back to the developmental lifecycle sequence.
			_build_lifecycle()


# ── Shared `_cm_` material helpers (the trial materials, DNA-driven) ─────

## Energy multiplier for emissive elements, lifted when `emissive` is on (gated like
## codex_flora's `_cfl_glow_energy`).
func _cm_glow_energy(base: float) -> float:
	return base * (1.0 if emissive else 0.6)


## FLESH / body / cell membrane / creature skin (color_a family): warm with a little
## subsurface and an emission FLOOR in its own tone so bodies read against the dark capture.
## `alpha` < 1.0 turns on alpha blending (the division colony's translucent membrane, so the
## glowing nucleus reads THROUGH the cell — keep the trial's translucency where it used one).
func _cm_flesh_mat(c: Color = color_a, alpha: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	m.roughness = clampf(rough_amt, 0.02, 1.0)
	m.metallic = clampf(metallic_amt, 0.0, 1.0)
	m.subsurf_scatter_enabled = true
	m.subsurf_scatter_strength = 0.25
	if alpha < 0.999:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.emission_enabled = true
	m.emission = c * 0.4
	m.emission_energy_multiplier = _cm_glow_energy(0.10)
	return m


## SHELL / structure / segment / tray / pattern (color_b family): cool matte backbone with a
## faint emission floor so the structure never collapses to black. `alpha` < 1.0 enables
## blending (the colony's draining dying-cell husk).
func _cm_struct_mat(c: Color = color_b, alpha: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	m.roughness = clampf(rough_amt * 1.08, 0.02, 1.0)
	m.metallic = clampf(metallic_amt, 0.0, 1.0)
	if alpha < 0.999:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.emission_enabled = true
	m.emission = c * 0.4
	m.emission_energy_multiplier = _cm_glow_energy(0.10)
	return m


## GLOW / nucleus / eye / core / RD-spot (accent family): saturated near-unshaded
## bioluminescence. `energy` ~2.5-4; `unshaded` toggles full unshaded (nuclei/cores) vs
## shaded glow (the RD eye uses per-pixel so the sphere still rounds under the key light).
func _cm_glow_mat(c: Color = accent, energy: float = 3.0, unshaded: bool = true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	else:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		m.roughness = clampf(rough_amt * 0.4, 0.02, 1.0)
		m.metallic = clampf(metallic_amt, 0.0, 1.0)
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = _cm_glow_energy(energy)
	return m


# ── Shared `_cm_` geometry helpers ──────────────────────────────────────

## Orthonormal Basis whose Y axis is `up_axis`. The single orient primitive the builders use
## so orientation is always via Basis, never out-of-tree look_at.
func _cm_basis_from_up(up_axis: Vector3) -> Basis:
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
func _cm_add_mesh(parent: Node3D, mesh: Mesh, mat: Material,
		xform: Transform3D = Transform3D.IDENTITY, node_name: String = "Part") -> MeshInstance3D:
	if mesh == null:
		return null
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = xform
	parent.add_child(mi)
	return mi


## Append every triangle of `mesh` (surface 0) into `st`, transformed by `xform`. This is the
## mesh-batch helper that lets a whole colony / spike-crown / stage's sub-parts live in a
## handful of ArrayMeshes the capture AABB can frame — no MultiMesh. Reads positions/normals
## via MeshDataTool and re-emits them (handles primitive meshes by converting first).
func _cm_batch_into(st: SurfaceTool, mesh: Mesh, xform: Transform3D = Transform3D.IDENTITY) -> void:
	if mesh == null:
		return
	var arr_mesh: ArrayMesh
	if mesh is ArrayMesh:
		arr_mesh = mesh as ArrayMesh
	else:
		var conv := SurfaceTool.new()
		conv.create_from(mesh, 0)
		arr_mesh = conv.commit()
	if arr_mesh == null or arr_mesh.get_surface_count() == 0:
		return
	var mdt := MeshDataTool.new()
	if mdt.create_from_surface(arr_mesh, 0) != OK:
		return
	var nbasis: Basis = xform.basis.inverse().transposed()
	for fi: int in range(mdt.get_face_count()):
		for fvi: int in range(3):
			var vi: int = mdt.get_face_vertex(fi, fvi)
			var v: Vector3 = xform * mdt.get_vertex(vi)
			var nrm: Vector3 = (nbasis * mdt.get_vertex_normal(vi)).normalized()
			st.set_normal(nrm)
			st.add_vertex(v)


## Commit a batched SurfaceTool into one MeshInstance3D under `parent`. `gen_normals`
## regenerates normals (off when the batch already set per-vertex normals via _cm_batch_into,
## which would otherwise be flattened). `shadows` off for the colony's cells/nuclei so the
## mound floor does not fill with hard dark blobs.
func _cm_commit_batch(parent: Node3D, st: SurfaceTool, mat: Material, nm: String,
		gen_normals: bool = true, shadows: bool = true) -> void:
	if gen_normals:
		st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var mi := _cm_add_mesh(parent, mesh, mat, Transform3D.IDENTITY, nm)
	if mi != null and not shadows:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Local AABB over all MeshInstance3D descendants of `node`, accumulated through the chain of
## LOCAL transforms down from `node` (never touches global_transform — independent of tree
## state). Used to centre + scale each specimen.
func _cm_subtree_aabb(node: Node3D) -> AABB:
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


## Centre `body` and scale it to ~`target_h` tall, base dropped to y=0, then horizontally
## centred at the origin so the +X/+Z capture frames it (the codex_flora `_cfl_settle`
## analogue). `width_scale` stretches the horizontal axes for span. `floor_to_zero` drops the
## base to y=0 (standing specimens); when false the specimen is vertically centred too (the
## free-floating creature / colony that already sits on its own mound).
func _cm_settle(body: Node3D, target_h: float, width_scale: float = 1.0,
		floor_to_zero: bool = true) -> void:
	if target_h > 0.0:
		var raw: AABB = _cm_subtree_aabb(body)
		var span_y: float = maxf(raw.size.y, 0.001)
		var k: float = target_h / span_y
		body.scale = Vector3(k * width_scale, k, k * width_scale)
	var aabb: AABB = _cm_subtree_aabb(body)
	if aabb.size == Vector3.ZERO:
		return
	var centre: Vector3 = aabb.get_center()
	if floor_to_zero:
		body.position += Vector3(-centre.x, -aabb.position.y, -centre.z)
	else:
		body.position += -centre


# =============================================================================
# MODE: lifecycle — the developmental STAGE-SEQUENCE (trial v1)
#
# The genuine morphogenesis (a developmental clock, the load-bearing core):
#   ONE organism rendered as a left->right STAGE-SEQUENCE — egg -> segmented larva ->
#   ribbed pupa/cocoon -> winged-horned adult — growing in size AND complexity along a
#   gentle arc. A developmental-stage MAP assigns each slot a KIND (first=egg, last=adult,
#   middle slots fill larva->pupa, extra larva/pupa slots inserted as the count grows so the
#   size ramp reads as smooth growth). A glowing PROGRESSION LINE of beads threads the stages
#   so the row reads as a single creature developing through time.
#   complexity scales the stage COUNT (5..7) and per-stage detail. Deterministic from seed.
# Each stage's many sub-parts (speckles, segment rings, legs, antennae, ribs, eyes, beads)
# are batched into shared ArrayMeshes so the capture AABB frames the whole row.
# =============================================================================

const _LC_ARC_SPAN: float = 2.95            # total left->right width of the sequence (m)
const _LC_ARC_DEPTH: float = 0.34           # forward bow of the arc (toward -Z)
const _LC_BEAD_SEGMENTS: int = 7            # bead sphere segments
const _LC_PRESENT_YAW: float = -14.0        # yaw so the arc reads L->R to the +X/+Z cam

var _lc_noise: FastNoiseLite
var _lc_stage_anchors: Array[Vector3] = []  # line height points for the progression line


func _build_lifecycle() -> void:
	# Local seeded noise for the organic skin wobble (deterministic from seed).
	_lc_noise = FastNoiseLite.new()
	_lc_noise.seed = seed
	_lc_noise.frequency = 2.4
	_lc_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_lc_stage_anchors.clear()

	# Materials: flesh body, slate shell/segments, glow nucleus/eyes/beads.
	var mat_flesh := _cm_flesh_mat(color_a)
	var mat_shell := _cm_struct_mat(color_b)
	var mat_glow := _cm_glow_mat(accent, 3.0, true)

	# Present the row to the +X/+Z capture camera so it reads left->right.
	var root := Node3D.new()
	root.name = "Lifecycle"
	root.basis = Basis().rotated(Vector3.UP, deg_to_rad(_LC_PRESENT_YAW))
	add_child(root)

	# Stage count scales with complexity: 5..7. (complexity native 6 -> 6 stages.)
	var n: int = clampi(3 + complexity / 2, 5, 7)

	for i: int in range(n):
		var t: float = float(i) / float(n - 1)
		var x: float = lerpf(-_LC_ARC_SPAN * 0.5, _LC_ARC_SPAN * 0.5, t)
		# Parabolic bow: deepest (most -Z) in the middle of the row.
		var z: float = -_LC_ARC_DEPTH * (1.0 - pow(2.0 * t - 1.0, 2.0))
		var base_pos := Vector3(x, 0.0, z)
		# Growth ramp: each stage clearly larger than the last; top held back so the adult's
		# wings/horns don't swamp the row.
		var s: float = lerpf(0.52, 0.96, pow(t, 0.80))

		var stage := Node3D.new()
		stage.name = "Stage%d" % i
		stage.position = base_pos
		# Per-stage tiny yaw jitter so the row feels drawn, not stamped.
		var yaw_jit: float = _rng.randf_range(-6.0, 6.0)
		stage.basis = Basis().rotated(Vector3.UP, deg_to_rad(yaw_jit))
		root.add_child(stage)

		match _lc_stage_kind(i, n):
			0:
				_lc_build_egg(stage, s, mat_flesh, mat_shell, mat_glow)
			1:
				_lc_build_larva(stage, s, mat_flesh, mat_shell, mat_glow)
			2:
				_lc_build_pupa(stage, s, mat_flesh, mat_shell, mat_glow)
			_:
				_lc_build_adult(stage, s, mat_flesh, mat_shell, mat_glow)

		# Record an anchor for the progression line — a low, gently-rising timeline (anchoring
		# at the wildly-varying crowns would yank the line up at the winged adult).
		var line_y: float = lerpf(0.12, 0.30, t)
		_lc_stage_anchors.append(base_pos + Vector3(0.0, line_y, 0.0))

	# Thread the glowing progression line through the stage anchors.
	_lc_build_progression_line(root, mat_glow)

	# Centre + scale; the arc floats (vertically centred) so the bowed row frames cleanly.
	_cm_settle(root, maxf(sculpt_height, 0.4), maxf(sculpt_width, 0.2), false)


## Map a stage slot to a developmental KIND given n total stages.
##   0 = egg, 1 = larva, 2 = pupa/transitional, 3 = adult.
## First slot is always egg, last always adult; middle slots fill larva->pupa with extra
## larva/pupa slots inserted as n grows (5->7) so the size ramp reads as smooth growth.
func _lc_stage_kind(i: int, n: int) -> int:
	if i == 0:
		return 0
	if i == n - 1:
		return 3
	var mids: int = n - 2
	var k: int = i - 1
	var larva_slots: int = int(ceil(float(mids) * 0.5))
	if k < larva_slots:
		return 1
	return 2


# ── STAGE 0 — EGG: speckled ovoid on a tiny base ──

## Build a small speckled egg of overall scale `s`.
func _lc_build_egg(parent: Node3D, s: float, mat_flesh: StandardMaterial3D,
		mat_shell: StandardMaterial3D, mat_glow: StandardMaterial3D) -> void:
	var base_r: float = 0.10 * s
	var base_h: float = 0.05 * s
	# Tiny revolution base — a low collar the egg nests in.
	var base_profile: Array[Vector2] = [
		Vector2(0.0, 0.0),
		Vector2(base_r * 0.9, 0.0),
		Vector2(base_r, base_h * 0.5),
		Vector2(base_r * 0.78, base_h),
		Vector2(base_r * 0.5, base_h * 1.05),
	]
	_cm_add_mesh(parent, MorphoPrimitive.revolution(base_profile, 16), mat_shell,
		Transform3D.IDENTITY, "EggBase")

	# Ovoid egg shell: revolution of a half-ellipse profile, slightly pointed at the top.
	var egg_w: float = 0.13 * s
	var egg_h: float = 0.21 * s
	var egg_rings: int = 9
	var egg_profile: Array[Vector2] = []
	for ri: int in range(egg_rings + 1):
		var v: float = float(ri) / float(egg_rings)
		var ang: float = v * PI
		var r: float = sin(ang) * egg_w
		r *= lerpf(1.06, 0.86, v)
		var y: float = v * egg_h
		egg_profile.append(Vector2(maxf(r, 0.0008), y))
	var egg_mesh: Mesh = MorphoPrimitive.revolution(egg_profile, 18)
	var egg_disp: ArrayMesh = MorphoModifier.noise_displace(egg_mesh, _lc_noise, 0.006 * s)
	_cm_add_mesh(parent, egg_disp if egg_disp != null else egg_mesh, mat_flesh,
		Transform3D(Basis.IDENTITY, Vector3(0.0, base_h * 0.5, 0.0)), "EggShell")

	# Speckles: small glow nodules scattered on the shell, batched into one mesh.
	var speckle_n: int = 10 + complexity
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var spec_r: float = 0.011 * s
	for _si: int in range(speckle_n):
		var u: float = _rng.randf()
		var phi: float = _rng.randf_range(0.18, 0.92) * PI
		var theta: float = u * TAU
		var rr: float = sin(phi) * egg_w * lerpf(1.06, 0.86, phi / PI)
		var yy: float = base_h * 0.5 + (phi / PI) * egg_h
		_lc_emit_sphere(st, Vector3(cos(theta) * rr, yy, sin(theta) * rr), spec_r, 5)
	_cm_commit_batch(parent, st, mat_glow, "EggSpeckles")


# ── STAGE 1 — LARVA: segmented body + stub legs + antennae ──

## Build a short segmented larva of scale `s` lying along +X, reared up at the head.
func _lc_build_larva(parent: Node3D, s: float, mat_flesh: StandardMaterial3D,
		mat_shell: StandardMaterial3D, mat_glow: StandardMaterial3D) -> void:
	var seg_n: int = 6 + complexity / 3
	var body_len: float = 0.42 * s
	var body_r: float = 0.066 * s
	var rear_x: float = -body_len * 0.5

	# Spine as a gentle arch: rear low, head reared up.
	var positions: Array[Vector3] = []
	var radii: Array[float] = []
	for i: int in range(seg_n):
		var t: float = float(i) / float(seg_n - 1)
		var px: float = rear_x + t * body_len
		var py: float = body_r * 1.05 + sin(t * PI) * body_r * 1.5 + t * body_r * 1.2
		positions.append(Vector3(px, py, 0.0))
		var rad: float = body_r * (0.5 + 0.85 * sin(clampf(t, 0.02, 0.98) * PI))
		rad = maxf(rad, body_r * 0.34)
		radii.append(rad)

	var body_mesh: Mesh = MorphoPrimitive.multi_tube(positions, radii, 9)
	var body_disp: ArrayMesh = MorphoModifier.noise_displace(body_mesh, _lc_noise, 0.008 * s)
	_cm_add_mesh(parent, body_disp if body_disp != null else body_mesh, mat_flesh,
		Transform3D.IDENTITY, "LarvaBody")

	# Segment rings: slim slate collars cinching the body (the "segmented" read), batched.
	var ring_st := SurfaceTool.new()
	ring_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: int = seg_n - 1
	for i: int in range(1, rings):
		var t: float = float(i) / float(seg_n - 1)
		var idx_f: float = t * float(seg_n - 1)
		var lo: int = clampi(int(floor(idx_f)), 0, seg_n - 1)
		var hi: int = clampi(lo + 1, 0, seg_n - 1)
		var frac: float = idx_f - float(lo)
		var c: Vector3 = (positions[lo] as Vector3).lerp(positions[hi] as Vector3, frac)
		var rad: float = lerpf(radii[lo] as float, radii[hi] as float, frac) * 1.05
		_lc_emit_ring(ring_st, c, Vector3.RIGHT, rad, rad * 0.16, 10)
	_cm_commit_batch(parent, ring_st, mat_shell, "LarvaRings")

	# Stub legs: tiny tapered nubs in pairs along the underside, batched.
	var leg_st := SurfaceTool.new()
	leg_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var leg_pairs: int = 3 + complexity / 3
	var leg_len: float = body_r * 1.5
	for p: int in range(leg_pairs):
		var t: float = lerpf(0.18, 0.82, float(p) / float(maxi(leg_pairs - 1, 1)))
		var idx_f: float = t * float(seg_n - 1)
		var lo: int = clampi(int(floor(idx_f)), 0, seg_n - 1)
		var hi: int = clampi(lo + 1, 0, seg_n - 1)
		var frac: float = idx_f - float(lo)
		var c: Vector3 = (positions[lo] as Vector3).lerp(positions[hi] as Vector3, frac)
		var rad: float = lerpf(radii[lo] as float, radii[hi] as float, frac)
		for side: int in [-1, 1]:
			var root_pt: Vector3 = c + Vector3(0.0, -rad * 0.55, float(side) * rad * 0.8)
			var tip: Vector3 = root_pt + Vector3(0.0, -leg_len * 0.7, float(side) * leg_len * 0.6)
			_lc_emit_tapered_segment(leg_st, root_pt, tip, body_r * 0.34, body_r * 0.12, 5)
	_cm_commit_batch(parent, leg_st, mat_shell, "LarvaLegs")

	# Two short antennae at the head, batched.
	var head: Vector3 = positions[seg_n - 1] as Vector3
	var head_r: float = radii[seg_n - 1] as float
	var ant_st := SurfaceTool.new()
	ant_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side: int in [-1, 1]:
		var a_root: Vector3 = head + Vector3(head_r * 0.6, head_r * 0.5, float(side) * head_r * 0.5)
		var a_tip: Vector3 = a_root + Vector3(head_r * 1.2, head_r * 1.6, float(side) * head_r * 0.7)
		_lc_emit_tapered_segment(ant_st, a_root, a_tip, body_r * 0.18, body_r * 0.05, 4)
	_cm_commit_batch(parent, ant_st, mat_shell, "LarvaAntennae")

	# Glow eye-spots, batched.
	var eye_st := SurfaceTool.new()
	eye_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side: int in [-1, 1]:
		var eye: Vector3 = head + Vector3(head_r * 0.7, head_r * 0.15, float(side) * head_r * 0.55)
		_lc_emit_sphere(eye_st, eye, head_r * 0.26, 5)
	_cm_commit_batch(parent, eye_st, mat_glow, "LarvaEyes")


# ── STAGE 2 — PUPA / COCOON: ribbed capsule, proto-limb seams ──

## Build a ribbed cocoon of scale `s` standing upright on a small base.
func _lc_build_pupa(parent: Node3D, s: float, mat_flesh: StandardMaterial3D,
		mat_shell: StandardMaterial3D, mat_glow: StandardMaterial3D) -> void:
	var base_r: float = 0.12 * s
	var base_h: float = 0.045 * s
	var base_profile: Array[Vector2] = [
		Vector2(0.0, 0.0),
		Vector2(base_r, 0.0),
		Vector2(base_r * 0.86, base_h),
		Vector2(base_r * 0.52, base_h * 1.1),
	]
	_cm_add_mesh(parent, MorphoPrimitive.revolution(base_profile, 16), mat_shell,
		Transform3D.IDENTITY, "PupaBase")

	# Cocoon body: a teardrop capsule — wide low belly tapering to a pointed top, ribbed.
	var coc_w: float = 0.155 * s
	var coc_h: float = 0.50 * s
	var rib_freq: float = 7.0
	var rib_amp: float = coc_w * 0.06
	var rings: int = 22
	var coc_profile: Array[Vector2] = []
	for ri: int in range(rings + 1):
		var v: float = float(ri) / float(rings)
		var ang: float = v * PI
		var env: float = sin(ang)
		var r: float = env * coc_w * lerpf(1.12, 0.7, v)
		r += sin(v * PI * rib_freq) * rib_amp * env
		var y: float = base_h * 0.5 + v * coc_h
		coc_profile.append(Vector2(maxf(r, 0.001), y))
	var coc_mesh: Mesh = MorphoPrimitive.revolution(coc_profile, 22)
	var coc_disp: ArrayMesh = MorphoModifier.noise_displace(coc_mesh, _lc_noise, 0.007 * s)
	_cm_add_mesh(parent, coc_disp if coc_disp != null else coc_mesh, mat_flesh,
		Transform3D.IDENTITY, "PupaBody")

	# Rib rings: slate bands wrapping the cocoon (chrysalis segmentation), batched.
	var ring_st := SurfaceTool.new()
	ring_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var band_n: int = 5 + complexity / 3
	for b: int in range(band_n):
		var v: float = lerpf(0.12, 0.86, float(b) / float(maxi(band_n - 1, 1)))
		var ang: float = v * PI
		var env: float = sin(ang)
		var r: float = env * coc_w * lerpf(1.12, 0.7, v) * 1.04
		var y: float = base_h * 0.5 + v * coc_h
		_lc_emit_ring(ring_st, Vector3(0.0, y, 0.0), Vector3.UP, r, r * 0.10, 14)
	_cm_commit_batch(parent, ring_st, mat_shell, "PupaRibs")

	# Proto-limb seams: a few vertical ridges down the front, hinting limbs forming, batched.
	var seam_st := SurfaceTool.new()
	seam_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seam_n: int = 3
	for sidx: int in range(seam_n):
		var around: float = lerpf(-0.5, 0.5, float(sidx) / float(maxi(seam_n - 1, 1)))
		var theta: float = around * 1.1
		var dir: Vector3 = Vector3(cos(theta), 0.0, sin(theta))
		var top_v: float = 0.74
		var bot_v: float = 0.20
		var v_mid: float = (top_v + bot_v) * 0.5
		var ang_mid: float = v_mid * PI
		var r_mid: float = sin(ang_mid) * coc_w * lerpf(1.12, 0.7, v_mid) * 1.02
		var c: Vector3 = dir * r_mid + Vector3(0.0, base_h * 0.5 + v_mid * coc_h, 0.0)
		var seam_h: float = (top_v - bot_v) * coc_h * 0.5
		_lc_emit_box(seam_st, c, Vector3.UP, dir, dir.cross(Vector3.UP).normalized(),
			seam_h, coc_w * 0.10, coc_w * 0.035)
	_cm_commit_batch(parent, seam_st, mat_shell, "PupaSeams")

	# A single glow node at the crown (the soon-to-emerge eye).
	var crown_pt := Vector3(0.0, base_h * 0.5 + coc_h, 0.0)
	_cm_add_mesh(parent, MorphoPrimitive.sphere(coc_w * 0.20, 8, 5), mat_glow,
		Transform3D(Basis.IDENTITY, crown_pt - Vector3(0.0, coc_w * 0.06, 0.0)), "PupaGlow")


# ── STAGE 3 — ADULT: segmented body + bezier wings/horns + sensor head ──

## Build the full adult of scale `s`: reared segmented thorax/abdomen, revolution sensor head
## with glowing eyes, twin bezier_sweep wings and a pair of bezier_sweep horns.
func _lc_build_adult(parent: Node3D, s: float, mat_flesh: StandardMaterial3D,
		mat_shell: StandardMaterial3D, mat_glow: StandardMaterial3D) -> void:
	var seg_n: int = 8
	var body_len: float = 0.46 * s
	var body_r: float = 0.085 * s
	var rear_x: float = -body_len * 0.62

	# Spine: low abdomen at the rear arching up to a reared thorax at the front.
	var positions: Array[Vector3] = []
	var radii: Array[float] = []
	for i: int in range(seg_n):
		var t: float = float(i) / float(seg_n - 1)
		var px: float = rear_x + t * body_len
		var py: float = body_r * 1.1 + pow(t, 1.4) * body_r * 4.8
		positions.append(Vector3(px, py, 0.0))
		var rad: float = body_r * (1.15 - 0.55 * t + 0.45 * pow(t, 2.2))
		rad = maxf(rad, body_r * 0.4)
		radii.append(rad)

	var body_mesh: Mesh = MorphoPrimitive.multi_tube(positions, radii, 11)
	var body_disp: ArrayMesh = MorphoModifier.noise_displace(body_mesh, _lc_noise, 0.009 * s)
	_cm_add_mesh(parent, body_disp if body_disp != null else body_mesh, mat_flesh,
		Transform3D.IDENTITY, "AdultBody")

	# Segment bands cinching the abdomen, batched.
	var ring_st := SurfaceTool.new()
	ring_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in range(1, seg_n - 1):
		var t: float = float(i) / float(seg_n - 1)
		if t > 0.62:
			continue
		var c: Vector3 = positions[i] as Vector3
		var rad: float = (radii[i] as float) * 1.05
		var fwd: Vector3 = ((positions[i + 1] as Vector3) - (positions[i - 1] as Vector3)).normalized()
		_lc_emit_ring(ring_st, c, fwd, rad, rad * 0.13, 12)
	_cm_commit_batch(parent, ring_st, mat_shell, "AdultBands")

	# Sensor head: a revolution bulb at the front crown of the thorax.
	var head_base: Vector3 = positions[seg_n - 1] as Vector3
	var head_r: float = (radii[seg_n - 1] as float) * 1.15
	var head_dir: Vector3 = (head_base - (positions[seg_n - 2] as Vector3)).normalized()
	var head_centre: Vector3 = head_base + head_dir * head_r * 1.1
	var head_profile: Array[Vector2] = []
	var hrings: int = 8
	for ri: int in range(hrings + 1):
		var v: float = float(ri) / float(hrings)
		var ang: float = v * PI
		var r: float = sin(ang) * head_r * lerpf(0.95, 1.05, v)
		head_profile.append(Vector2(maxf(r, 0.001), (v - 0.5) * head_r * 2.0))
	_cm_add_mesh(parent, MorphoPrimitive.revolution(head_profile, 16), mat_flesh,
		Transform3D(Basis.IDENTITY, head_centre), "AdultHead")

	# Glowing compound eyes — two glow spheres on the head front/sides, batched.
	var eye_st := SurfaceTool.new()
	eye_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side: int in [-1, 1]:
		var eye: Vector3 = head_centre + Vector3(head_r * 0.55, head_r * 0.1, float(side) * head_r * 0.6)
		_lc_emit_sphere(eye_st, eye, head_r * 0.38, 7)
	_cm_commit_batch(parent, eye_st, mat_glow, "AdultEyes")

	# Horns: two bezier_sweep curved spikes off the head. Bake derived values into locals
	# BEFORE building control points.
	var horn_cs: Array[Vector2] = _lc_ring_cross_section(body_r * 0.16, 5)
	for side: int in [-1, 1]:
		var fside: float = float(side)
		var h0: Vector3 = head_centre + Vector3(head_r * 0.2, head_r * 0.7, fside * head_r * 0.45)
		var h1: Vector3 = h0 + Vector3(head_r * 0.5, head_r * 1.0, fside * head_r * 0.4)
		var h2: Vector3 = h1 + Vector3(head_r * 0.9, head_r * 0.7, fside * head_r * 0.5)
		var h3: Vector3 = h2 + Vector3(head_r * 1.3, head_r * 0.2, fside * head_r * 0.3)
		var horn_ctrl: Array[Vector3] = [h0, h1, h2, h3]
		var horn_mesh: Mesh = MorphoPrimitive.bezier_sweep(horn_ctrl, horn_cs, 12, 20.0)
		var horn_taper: ArrayMesh = MorphoModifier.taper(horn_mesh, (h3 - h0).normalized(),
			func(tt: float) -> float: return lerpf(1.0, 0.12, tt))
		_cm_add_mesh(parent, horn_taper if horn_taper != null else horn_mesh, mat_shell,
			Transform3D.IDENTITY, "AdultHorn")

	# Wings: two large bezier_sweep membranes off the thorax.
	var thorax: Vector3 = positions[seg_n - 2] as Vector3
	var wing_cs: Array[Vector2] = _lc_wing_cross_section(body_r * 0.9)
	for side: int in [-1, 1]:
		var fside: float = float(side)
		var w0: Vector3 = thorax + Vector3(0.0, body_r * 1.2, fside * body_r * 0.6)
		var w1: Vector3 = w0 + Vector3(-body_len * 0.18, body_len * 0.55, fside * body_len * 0.55)
		var w2: Vector3 = w0 + Vector3(-body_len * 0.42, body_len * 0.85, fside * body_len * 0.95)
		var w3: Vector3 = w0 + Vector3(-body_len * 0.62, body_len * 0.78, fside * body_len * 1.25)
		var wing_ctrl: Array[Vector3] = [w0, w1, w2, w3]
		var wing_mesh: Mesh = MorphoPrimitive.bezier_sweep(wing_ctrl, wing_cs, 16, 0.0)
		var wing_taper: ArrayMesh = MorphoModifier.taper(wing_mesh, (w3 - w0).normalized(),
			func(tt: float) -> float: return lerpf(0.6, 1.25, sin(tt * PI)))
		_cm_add_mesh(parent, wing_taper if wing_taper != null else wing_mesh, mat_flesh,
			Transform3D.IDENTITY, "AdultWing")


# ── PROGRESSION LINE — glowing beads threading the stage anchors ──

## Thread a thin dotted line of glowing beads through the recorded stage anchors so the row
## reads as ONE timeline. Beads ride a smooth Catmull-Rom path; all batched into one mesh.
func _lc_build_progression_line(parent: Node3D, mat_glow: StandardMaterial3D) -> void:
	if _lc_stage_anchors.size() < 2:
		return
	var pts: Array[Vector3] = []
	for a: Vector3 in _lc_stage_anchors:
		pts.append(a)

	var bead_st := SurfaceTool.new()
	bead_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var per_span: int = 5
	for i: int in range(pts.size() - 1):
		var p0: Vector3 = pts[maxi(i - 1, 0)]
		var p1: Vector3 = pts[i]
		var p2: Vector3 = pts[i + 1]
		var p3: Vector3 = pts[mini(i + 2, pts.size() - 1)]
		for j: int in range(per_span):
			var t: float = float(j) / float(per_span)
			var pos: Vector3 = _lc_catmull(p0, p1, p2, p3, t)
			_lc_emit_sphere(bead_st, pos, 0.018, _LC_BEAD_SEGMENTS)
	_lc_emit_sphere(bead_st, pts[pts.size() - 1], 0.018, _LC_BEAD_SEGMENTS)
	_cm_commit_batch(parent, bead_st, mat_glow, "ProgressionLine")


# ── lifecycle batched-geometry sub-helpers (_lc_) ──

## Catmull-Rom interpolation for a smooth bead path.
func _lc_catmull(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var t2: float = t * t
	var t3: float = t2 * t
	return 0.5 * (
		(2.0 * p1) +
		(-p0 + p2) * t +
		(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
		(-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)


## A round (ring) cross-section of `sides` points, radius `r`, for bezier_sweep.
func _lc_ring_cross_section(r: float, sides: int) -> Array[Vector2]:
	var cs: Array[Vector2] = []
	for i: int in range(sides):
		var a: float = TAU * float(i) / float(sides)
		cs.append(Vector2(cos(a) * r, sin(a) * r))
	return cs


## A flattened leaf/wing cross-section (wide, thin) for bezier_sweep wings.
func _lc_wing_cross_section(half_w: float) -> Array[Vector2]:
	var thick: float = half_w * 0.10
	return [
		Vector2(-half_w, 0.0),
		Vector2(-half_w * 0.5, thick),
		Vector2(0.0, thick * 1.2),
		Vector2(half_w * 0.5, thick),
		Vector2(half_w, 0.0),
		Vector2(half_w * 0.5, -thick),
		Vector2(0.0, -thick * 1.2),
		Vector2(-half_w * 0.5, -thick),
	]


## Emit a low-poly UV sphere into a SurfaceTool at centre `c`, radius `r`. Cheap batched glow
## nodule / bead.
func _lc_emit_sphere(st: SurfaceTool, c: Vector3, r: float, seg: int) -> void:
	var rings: int = maxi(seg - 1, 3)
	var prev_ring: Array[Vector3] = []
	for ri: int in range(rings + 1):
		var v: float = float(ri) / float(rings)
		var phi: float = v * PI
		var y: float = cos(phi) * r
		var rr: float = sin(phi) * r
		var cur_ring: Array[Vector3] = []
		for si: int in range(seg + 1):
			var u: float = float(si) / float(seg)
			var theta: float = u * TAU
			cur_ring.append(c + Vector3(cos(theta) * rr, y, sin(theta) * rr))
		if ri > 0:
			for si: int in range(seg):
				_lc_tri(st, prev_ring[si], cur_ring[si], prev_ring[si + 1])
				_lc_tri(st, prev_ring[si + 1], cur_ring[si], cur_ring[si + 1])
		prev_ring = cur_ring


## Emit a thin torus-like RING (band) into a SurfaceTool. `axis` is the ring normal, `major`
## the radius, `minor` the tube radius, `sides` segments around the major circle. No look_at.
func _lc_emit_ring(st: SurfaceTool, c: Vector3, axis: Vector3, major: float,
		minor: float, sides: int) -> void:
	var n: Vector3 = axis.normalized()
	var ref: Vector3 = Vector3.RIGHT
	if absf(n.dot(ref)) > 0.95:
		ref = Vector3.FORWARD
	var u_dir: Vector3 = ref.cross(n).normalized()
	var v_dir: Vector3 = n.cross(u_dir).normalized()
	var tube_seg: int = 6
	var prev_ring: Array[Vector3] = []
	for mi: int in range(sides + 1):
		var ma: float = TAU * float(mi) / float(sides)
		var centre: Vector3 = c + (u_dir * cos(ma) + v_dir * sin(ma)) * major
		var radial: Vector3 = (u_dir * cos(ma) + v_dir * sin(ma)).normalized()
		var cur_ring: Array[Vector3] = []
		for ti: int in range(tube_seg + 1):
			var ta: float = TAU * float(ti) / float(tube_seg)
			var off: Vector3 = radial * cos(ta) * minor + n * sin(ta) * minor
			cur_ring.append(centre + off)
		if mi > 0:
			for ti: int in range(tube_seg):
				_lc_tri(st, prev_ring[ti], cur_ring[ti], prev_ring[ti + 1])
				_lc_tri(st, prev_ring[ti + 1], cur_ring[ti], cur_ring[ti + 1])
		prev_ring = cur_ring


## Emit a tapered round segment (a short tube) between two points. For legs and antennae.
func _lc_emit_tapered_segment(st: SurfaceTool, a: Vector3, b: Vector3,
		r0: float, r1: float, sides: int) -> void:
	var fwd: Vector3 = b - a
	var length: float = fwd.length()
	if length < 0.0001:
		return
	fwd = fwd / length
	var ref: Vector3 = Vector3.UP
	if absf(fwd.dot(ref)) > 0.95:
		ref = Vector3.RIGHT
	var right: Vector3 = fwd.cross(ref).normalized()
	var up: Vector3 = right.cross(fwd).normalized()
	var ring_a: Array[Vector3] = []
	var ring_b: Array[Vector3] = []
	for si: int in range(sides + 1):
		var ang: float = TAU * float(si) / float(sides)
		var dir: Vector3 = right * cos(ang) + up * sin(ang)
		ring_a.append(a + dir * r0)
		ring_b.append(b + dir * r1)
	for si: int in range(sides):
		_lc_tri(st, ring_a[si], ring_b[si], ring_a[si + 1])
		_lc_tri(st, ring_a[si + 1], ring_b[si], ring_b[si + 1])


## Emit one oriented box (12 tris) into a SurfaceTool, centred at `c` with orthonormal axes
## (ax,ay,az) and half-extents (hx,hy,hz).
func _lc_emit_box(st: SurfaceTool, c: Vector3, ax: Vector3, ay: Vector3, az: Vector3,
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
	_lc_quad(st, p000, p010, p110, p100, -az)
	_lc_quad(st, p001, p101, p111, p011, az)
	_lc_quad(st, p000, p100, p101, p001, -ay)
	_lc_quad(st, p010, p011, p111, p110, ay)
	_lc_quad(st, p000, p001, p011, p010, -ax)
	_lc_quad(st, p100, p110, p111, p101, ax)


func _lc_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3) -> void:
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(b)
	st.set_normal(n); st.add_vertex(c)
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(c)
	st.set_normal(n); st.add_vertex(d)


func _lc_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


# =============================================================================
# MODE: division — a CELL-DIVISION COLONY driven by Conway's Game of Life (trial v2)
#
# The genuine morphogenesis (a REAL cellular automaton, the load-bearing core):
#   1. Conway's Life on a small grid (size scaled by complexity), seeded from `seed` at
#      ~36% live (centre-biased so the colony reads as a clustered mound), run a FIXED number
#      of steps. Hand-rolled: a typed grid Array[PackedInt32Array] + 8-neighbour count +
#      the B3/S23 rule. prev (step before final) and next (step after final) are kept so each
#      live final-state cell can be CLASSED by the CA itself:
#        NEWBORN (off->on entering the final step): smaller + brightly glowing.
#        DYING   (on->off leaving the final step, by Life rules): faded, shrunk husk.
#        STABLE  survivor: full healthy protoplasm; some caught mid-DIVISION (mitosis) as a
#                pinched dumbbell built with MorphoPrimitive.multi_tube.
#   2. The FINAL state becomes a 3D colony — one soft organic CELL blob per live cell on a
#      petri-mound. Every living cell carries a glowing NUCLEUS. Bodies/nuclei are batched
#      into shared ArrayMeshes (one per material) so the capture AABB frames the whole colony.
#   complexity scales the Life GRID side (12..18); ITERATIONS fixed at 4. Deterministic.
# =============================================================================

const _DIV_GRID_MIN: int = 12               # grid side at complexity ~3
const _DIV_GRID_MAX: int = 18               # grid side at complexity ~12
const _DIV_LIVE_FRACTION: float = 0.36      # ~36% seeded live
const _DIV_ITERATIONS: int = 4              # Game of Life steps to run (fixed)
const _DIV_COLONY_SPAN: float = 2.05        # planar extent of the colony (metres)
const _DIV_MOUND_HEIGHT: float = 0.58       # central rise of the supporting mound
const _DIV_TILT_DEGREES: float = 16.0       # tip the mound toward the +X/+Z camera
const _DIV_DIVISION_FRACTION: float = 0.38  # share of stable cells shown mid-mitosis

# Cell state classes (derived from the CA, not authored).
enum DivCellState { STABLE, NEWBORN, DYING }

var _div_noise: FastNoiseLite
# Batched surfaces — cells grouped by material, nuclei separate.
var _div_st_cell: SurfaceTool
var _div_st_dying: SurfaceTool
var _div_st_nucleus: SurfaceTool
var _div_mat_cell: StandardMaterial3D
var _div_mat_dying: StandardMaterial3D
var _div_mat_nucleus: StandardMaterial3D


func _build_division() -> void:
	# Local seeded noise for the organic membrane wobble (deterministic from seed).
	_div_noise = FastNoiseLite.new()
	_div_noise.seed = seed
	_div_noise.frequency = 2.6
	_div_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	# Materials. The CELL membrane is TRANSLUCENT (the trial's alpha jelly) so the glowing
	# nucleus reads THROUGH it; the DYING husk is faintly translucent (draining out). The
	# mound uses a darker struct tone.
	_div_mat_cell = _cm_flesh_mat(color_a, 0.66)
	_div_mat_cell.roughness = clampf(rough_amt * 0.92, 0.02, 1.0)
	_div_mat_dying = _cm_struct_mat(color_b, 0.78)
	_div_mat_dying.roughness = clampf(rough_amt * 1.30, 0.02, 1.0)
	_div_mat_dying.emission_energy_multiplier = _cm_glow_energy(0.06)
	_div_mat_nucleus = _cm_glow_mat(accent, 4.0, true)
	var mat_mound := _cm_struct_mat(color_b.darkened(0.10))
	mat_mound.roughness = clampf(rough_amt * 1.30, 0.02, 1.0)
	mat_mound.emission_energy_multiplier = _cm_glow_energy(0.06)

	# Grid resolution scales with complexity (native 6 -> ~13).
	var n: int = clampi(int(round(lerpf(float(_DIV_GRID_MIN), float(_DIV_GRID_MAX),
		clampf(float(complexity - 3) / 9.0, 0.0, 1.0)))), _DIV_GRID_MIN, _DIV_GRID_MAX)

	# Run the Game of Life. Keep prev + compute next so each final cell classes itself.
	var grid: Array[PackedInt32Array] = _life_seed_grid(n)
	var prev: Array[PackedInt32Array] = grid
	for _i: int in range(_DIV_ITERATIONS):
		prev = grid
		grid = _life_step(grid, n)
	var final_grid: Array[PackedInt32Array] = grid
	var next_grid: Array[PackedInt32Array] = _life_step(final_grid, n)

	# A tilt tips the mound so the cell pattern reads from the +X/+Z capture lens.
	var colony := Node3D.new()
	colony.name = "Division"
	colony.basis = Basis().rotated(Vector3(1.0, 0.0, -1.0).normalized(), deg_to_rad(_DIV_TILT_DEGREES))
	add_child(colony)

	# Supporting mound under the live cells.
	_div_build_mound(colony, mat_mound)

	# Cell-to-world: map grid (x, y) to a centred planar (X, Z) patch.
	var cell_pitch: float = _DIV_COLONY_SPAN / float(n)
	var origin: float = -_DIV_COLONY_SPAN * 0.5 + cell_pitch * 0.5

	# Batch surfaces.
	_div_st_cell = SurfaceTool.new()
	_div_st_cell.begin(Mesh.PRIMITIVE_TRIANGLES)
	_div_st_dying = SurfaceTool.new()
	_div_st_dying.begin(Mesh.PRIMITIVE_TRIANGLES)
	_div_st_nucleus = SurfaceTool.new()
	_div_st_nucleus.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Place one cell per live final-state cell.
	for y: int in range(n):
		for x: int in range(n):
			if (final_grid[y] as PackedInt32Array)[x] == 0:
				continue
			# Classify from the CA: NEWBORN if off in prev, DYING if off in next, else STABLE.
			var was_alive: bool = (prev[y] as PackedInt32Array)[x] == 1
			var will_live: bool = (next_grid[y] as PackedInt32Array)[x] == 1
			var state: DivCellState = DivCellState.STABLE
			if not was_alive:
				state = DivCellState.NEWBORN
			elif not will_live:
				state = DivCellState.DYING

			var jx: float = _rng.randf_range(-cell_pitch * 0.16, cell_pitch * 0.16)
			var jz: float = _rng.randf_range(-cell_pitch * 0.16, cell_pitch * 0.16)
			var px: float = origin + float(x) * cell_pitch + jx
			var pz: float = origin + float(y) * cell_pitch + jz
			var surf_y: float = _div_mound_height(Vector2(px, pz).length())

			# Stable cells occasionally caught mid-division (mitosis).
			var dividing: bool = state == DivCellState.STABLE and _rng.randf() < _DIV_DIVISION_FRACTION
			_div_emit_cell(Vector3(px, surf_y, pz), cell_pitch, state, dividing)

	# Commit batches: cells/nuclei keep their per-vertex normals (no regen) and cast no
	# shadow so the mound floor doesn't fill with hard dark blobs.
	_cm_commit_batch(colony, _div_st_cell, _div_mat_cell, "Cells", false, false)
	_cm_commit_batch(colony, _div_st_dying, _div_mat_dying, "DyingCells", false, false)
	_cm_commit_batch(colony, _div_st_nucleus, _div_mat_nucleus, "Nuclei", false, false)

	# The colony already sits on its own mound; centre it (float) for the capture.
	_cm_settle(colony, maxf(sculpt_height, 0.4), maxf(sculpt_width, 0.2), false)


# ── CONWAY'S GAME OF LIFE — hand-rolled, deterministic from seed (_life_) ──
# Grid is Array[PackedInt32Array]; cell is 0 (dead) or 1 (alive).

## Build a fresh grid seeded with ~_DIV_LIVE_FRACTION live cells, biased toward the centre so
## the resulting colony reads as a clustered mound, not a square.
func _life_seed_grid(n: int) -> Array[PackedInt32Array]:
	var grid: Array[PackedInt32Array] = []
	var centre: float = float(n - 1) * 0.5
	var max_r: float = centre * 1.18
	for y: int in range(n):
		var row := PackedInt32Array()
		row.resize(n)
		for x: int in range(n):
			var dx: float = float(x) - centre
			var dy: float = float(y) - centre
			var r: float = sqrt(dx * dx + dy * dy)
			var rim: float = clampf(1.0 - (r / max_r), 0.0, 1.0)
			var p: float = _DIV_LIVE_FRACTION * (0.45 + 0.85 * rim)
			row[x] = 1 if _rng.randf() < p else 0
		grid.append(row)
	return grid


## Count the 8 live neighbours of cell (x, y). Bounded grid (edges are dead).
func _life_neighbours(grid: Array[PackedInt32Array], x: int, y: int, n: int) -> int:
	var count: int = 0
	for dy: int in range(-1, 2):
		for dx: int in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx: int = x + dx
			var ny: int = y + dy
			if nx < 0 or nx >= n or ny < 0 or ny >= n:
				continue
			count += (grid[ny] as PackedInt32Array)[nx]
	return count


## One Conway step: B3/S23. A dead cell with exactly 3 live neighbours is born; a live cell
## with 2 or 3 survives; everything else dies. Returns a new grid.
func _life_step(grid: Array[PackedInt32Array], n: int) -> Array[PackedInt32Array]:
	var next_grid: Array[PackedInt32Array] = []
	for y: int in range(n):
		var row := PackedInt32Array()
		row.resize(n)
		for x: int in range(n):
			var alive: int = (grid[y] as PackedInt32Array)[x]
			var nb: int = _life_neighbours(grid, x, y, n)
			var out: int = 0
			if alive == 1:
				out = 1 if (nb == 2 or nb == 3) else 0
			else:
				out = 1 if nb == 3 else 0
			row[x] = out
		next_grid.append(row)
	return next_grid


# ── COLONY GEOMETRY (_div_) ──

## Mound height for planar radius r — a smooth cosine cushion the colony rests on.
func _div_mound_height(r: float) -> float:
	var half_span: float = _DIV_COLONY_SPAN * 0.5
	var rr: float = clampf(r / half_span, 0.0, 1.0)
	return _DIV_MOUND_HEIGHT * 0.5 * (cos(rr * PI) + 1.0)


## Build the supporting mound (a revolved cushion) under the colony.
func _div_build_mound(parent: Node3D, mat: StandardMaterial3D) -> void:
	var half_span: float = _DIV_COLONY_SPAN * 0.5
	var profile: Array[Vector2] = []
	var base_y: float = -_DIV_MOUND_HEIGHT * 0.30
	profile.append(Vector2(0.0, base_y))
	profile.append(Vector2(half_span * 0.72, base_y))
	profile.append(Vector2(half_span * 1.02, base_y * 0.45))
	profile.append(Vector2(half_span * 1.04, 0.0))
	var samples: int = 36
	for i: int in range(1, samples + 1):
		var r: float = half_span * 1.02 * float(samples - i) / float(samples)
		profile.append(Vector2(r, _div_mound_height(r)))
	_cm_add_mesh(parent, MorphoPrimitive.revolution(profile, 48), mat,
		Transform3D.IDENTITY, "ColonyMound")


## Emit one cell into the batched surfaces. The CA-derived `state` sets size and which
## membrane material it joins; `dividing` swaps the single blob for a pinched two-lobe
## dumbbell (mitosis). The nucleus is emitted to the glow surface; newborns get a brighter,
## larger nucleus; dying cells are drained (no bright nucleus).
func _div_emit_cell(pos: Vector3, pitch: float, state: DivCellState, dividing: bool) -> void:
	var base_r: float = pitch * 0.46
	var size_mul: float = 1.0
	match state:
		DivCellState.NEWBORN:
			size_mul = _rng.randf_range(0.52, 0.66)
		DivCellState.DYING:
			size_mul = _rng.randf_range(0.60, 0.74)
		_:
			size_mul = _rng.randf_range(0.90, 1.06)
	var cell_r: float = base_r * size_mul

	# Lift the cell so its squashed body rests PROUD on the mound, not half-buried.
	var seat: Vector3 = pos + Vector3(0.0, cell_r * 0.55, 0.0)
	var into_dying: bool = state == DivCellState.DYING

	if dividing:
		_div_emit_dividing_cell(seat, cell_r, into_dying)
	else:
		_div_emit_blob_cell(seat, cell_r, into_dying)

	# Nucleus — bright glowing core for LIVING cells (newborn nuclei larger -> brightest).
	# Dividing cells emit their own two daughter nuclei, so skip the single one here.
	if state != DivCellState.DYING and not dividing:
		var nuc_r: float = cell_r * (0.46 if state == DivCellState.NEWBORN else 0.34)
		var nuc_mesh: Mesh = MorphoPrimitive.sphere(nuc_r, 8, 5)
		_cm_batch_into(_div_st_nucleus, nuc_mesh,
			Transform3D(Basis(), seat + Vector3(0.0, cell_r * 0.04, 0.0)))


## A single soft blob: a slightly squashed ellipsoid wobbled by noise so it reads as organic
## protoplasm rather than a hard ball. Joins the dying surface when `into_dying`.
func _div_emit_blob_cell(pos: Vector3, cell_r: float, into_dying: bool) -> void:
	var base: Mesh = MorphoPrimitive.sphere(cell_r, 12, 8)
	var wobbled: ArrayMesh = MorphoModifier.noise_displace(base, _div_noise, cell_r * 0.16,
		_rng.randf_range(0.0, 100.0))
	if wobbled == null:
		wobbled = base as ArrayMesh
	# Squash slightly on Y so the colony reads as a clustered sheet of cushions.
	var squash := Basis().scaled(Vector3(
		_rng.randf_range(0.96, 1.12),
		_rng.randf_range(0.74, 0.88),
		_rng.randf_range(0.96, 1.12)))
	var spin := Basis().rotated(Vector3.UP, _rng.randf_range(0.0, TAU))
	var target: SurfaceTool = _div_st_dying if into_dying else _div_st_cell
	_cm_batch_into(target, wobbled, Transform3D(spin * squash, pos))


## A cell caught mid-mitosis: two lobes joined by a pinched neck — a dumbbell built with
## MorphoPrimitive.multi_tube (radii bulge at the lobes, narrow at the waist). Oriented along
## a horizontal axis via a Basis so the pinch reads from the camera. Two daughter nuclei.
func _div_emit_dividing_cell(pos: Vector3, cell_r: float, into_dying: bool) -> void:
	var heading: float = _rng.randf_range(0.0, TAU)
	var axis := Vector3(cos(heading), 0.0, sin(heading))
	var sep: float = cell_r * 1.05
	var lobe_r: float = cell_r * 0.86

	# Five-ring profile: lobe cap -> lobe belly -> pinched waist -> lobe belly -> lobe cap.
	var positions: Array = [
		pos - axis * (sep + lobe_r * 0.62) + Vector3(0.0, cell_r * 0.04, 0.0),
		pos - axis * sep,
		pos,
		pos + axis * sep,
		pos + axis * (sep + lobe_r * 0.62) + Vector3(0.0, cell_r * 0.04, 0.0),
	]
	var radii: Array = [
		lobe_r * 0.18,
		lobe_r * 1.00,
		lobe_r * 0.30,
		lobe_r * 1.00,
		lobe_r * 0.18,
	]
	var neck: Mesh = MorphoPrimitive.multi_tube(positions, radii, 12)
	if neck == null:
		_div_emit_blob_cell(pos, cell_r, into_dying)
		return
	var wobbled: ArrayMesh = MorphoModifier.noise_displace(neck, _div_noise, cell_r * 0.10,
		_rng.randf_range(0.0, 100.0))
	if wobbled == null:
		wobbled = neck as ArrayMesh
	var target: SurfaceTool = _div_st_dying if into_dying else _div_st_cell
	_cm_batch_into(target, wobbled, Transform3D.IDENTITY)

	# Two daughter nuclei, one in each lobe.
	var nuc_r: float = cell_r * 0.30
	for s: int in [-1, 1]:
		var nc: Vector3 = pos + axis * sep * float(s)
		_cm_batch_into(_div_st_nucleus, MorphoPrimitive.sphere(nuc_r, 8, 5),
			Transform3D(Basis(), nc))


# =============================================================================
# MODE: turing — a REACTION-DIFFUSION PATTERNED CREATURE (trial v3) — THE HERO
#
# The genuine morphogenesis (a REAL Gray-Scott RD sim, the load-bearing core):
#   1. Gray-Scott RD is integrated on a toroidal RD_GRID^2 lattice for RD_ITERS steps in the
#      SPOTS regime (F~0.030, K~0.0615 -> isolated ocelli, leopard coat). Two morphogens U
#      (substrate) and V (autocatalyst) diffuse at different rates (Du>Dv) and react
#      u + 2v -> 3v; the diffusion-driven instability spontaneously breaks the uniform state
#      into spots:
#        U' = Du*lap(U) - U*V^2 + F*(1 - U)
#        V' = Dv*lap(V) + U*V^2 - (F + K)*V
#      Fully typed (PackedFloat32Array buffers), deterministic from `seed`, one-time static
#      build (slow is fine). The RD seed + fixed iteration count make every launch identical.
#   2. The V field is mapped onto a smooth ELLIPSOID creature by spherical UV (longitude
#      wraps, poles welded). Rendered TWO WAYS so the Turing structure is unmistakable:
#      (a) every spot is a RAISED RIDGE (the body displaced outward along its normal by V),
#      (b) TWO-TONE skin — vertex colour + a 1x128 ramp TEXTURE built at runtime carry the
#      field, teal coat (color_a) valleys, dark-rim/rose-centre ocelli (color_b/accent).
#   3. A sensor head with two near-unshaded eyes + four stubby limbs finish the organism.
#   complexity scales the RD GRID (96..150) and ITERS. Deterministic from seed.
# =============================================================================

# Pattern -> skin mapping.
const _RD_FEED: float = 0.030               # F: feed rate  -> SPOTS regime (leopard)
const _RD_KILL: float = 0.0615              # K: kill rate  -> larger, separated ocelli
const _RD_DU: float = 0.16                  # U diffusion (substrate, faster)
const _RD_DV: float = 0.08                  # V diffusion (autocatalyst, slower)
const _RD_SEED_PATCHES: int = 18            # initial V seed blobs (fewer -> bigger spots)
const _RD_NORM_LO: float = 0.05             # field value mapped to 0 after normalise
const _RD_NORM_HI: float = 0.42             # field value mapped to 1 after normalise
const _RD_SPOT_THRESHOLD: float = 0.48      # normalised V above this = ocellus crest
const _RD_SPOT_SHARPNESS: float = 0.24      # smoothstep half-width -> rounder bumps
const _RD_RIDGE_HEIGHT: float = 0.034       # outward bump height at a spot crest (m)
const _RD_VALLEY_SINK: float = 0.005        # valleys recede slightly -> crisper relief
# Body (ellipsoid creature).
const _RD_BODY_U_SEG: int = 168             # longitude segments (around)
const _RD_BODY_V_SEG: int = 100             # latitude segments (pole->pole)
const _RD_BODY_RX: float = 0.62             # half-width  (x)
const _RD_BODY_RY: float = 0.50             # half-height (y)
const _RD_BODY_RZ: float = 0.86             # half-depth  (z, the long axis -> snout)
const _RD_BODY_TAPER: float = 0.34          # front (snout) taper of the egg
const _RD_WRAPS_U: float = 2.0              # how many times the maze wraps longitudinally
const _RD_WRAPS_V: float = 1.0              # latitudinal wraps (pole to pole)


func _build_turing() -> void:
	var creature := Node3D.new()
	creature.name = "Turing"
	add_child(creature)

	# RD grid + iters scale with complexity (native 6 -> ~118^2 x ~3680 steps; the spots
	# still fully resolve). The lattice stays dense enough that the ocelli read as round.
	var cnorm: float = clampf(float(complexity - 3) / 9.0, 0.0, 1.0)
	var rd_n: int = int(round(lerpf(96.0, 150.0, cnorm)))
	var rd_iters: int = int(round(lerpf(3000.0, 5200.0, cnorm)))

	# 1. Grow the Turing field once (the morphogenesis step). The RD seed is baked from the
	# local seeded RNG so the whole sim is deterministic.
	var rd_field: PackedFloat32Array = _rd_simulate_gray_scott(
		rd_n, _RD_FEED, _RD_KILL, rd_iters, _rng.randi() & 0x7fffffff)
	_rd_normalize_field(rd_field, _RD_NORM_LO, _RD_NORM_HI)

	# 2. Build the patterned body mesh (RD-displaced ridges + two-tone vertex colour + ramp).
	creature.add_child(_rd_build_body(rd_field, rd_n))

	# 3. Sensor head + eyes + limbs (read as an organism).
	var head_origin := Vector3(0.0, 0.10, _RD_BODY_RZ * 0.94)
	_rd_build_head(creature, head_origin)
	_rd_build_eyes(creature, head_origin)
	_rd_build_limbs(creature)

	# 4. Centre + scale; the creature floats (vertically centred) for the capture.
	_cm_settle(creature, maxf(sculpt_height, 0.4), maxf(sculpt_width, 0.2), false)


# ── GRAY-SCOTT REACTION-DIFFUSION (fully typed, deterministic, one-time) (_rd_) ──

## Integrate Gray-Scott on a toroidal N×N lattice. Returns the V concentration as a flat
## PackedFloat32Array (length N*N) in [0,1]. dt=1 is stable for these small diffusion
## coefficients (the classic Pearson parameterisation). Spots/stripes/mazes are the SAME
## system at different (F,K); here (F,K) sits in the spots region.
func _rd_simulate_gray_scott(n: int, feed: float, kill: float, iters: int, seed_val: int) -> PackedFloat32Array:
	var size: int = n * n
	var u_buf := PackedFloat32Array()
	var v_buf := PackedFloat32Array()
	u_buf.resize(size)
	v_buf.resize(size)
	for i: int in size:
		u_buf[i] = 1.0
		v_buf[i] = 0.0

	# Seed a scatter of V blobs (deterministic from a local RNG). The instability amplifies
	# these into the spot lattice.
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	for _s: int in _RD_SEED_PATCHES:
		var cx: int = rng.randi_range(2, n - 3)
		var cy: int = rng.randi_range(2, n - 3)
		var rad: int = rng.randi_range(2, 5)
		for dy: int in range(-rad, rad + 1):
			for dx: int in range(-rad, rad + 1):
				if dx * dx + dy * dy <= rad * rad:
					var px: int = (cx + dx + n) % n
					var py: int = (cy + dy + n) % n
					var idx: int = py * n + px
					v_buf[idx] = 1.0
					u_buf[idx] = 0.5

	var u_next := u_buf.duplicate()
	var v_next := v_buf.duplicate()
	var dt: float = 1.0

	for _step: int in iters:
		for y: int in n:
			var ym: int = (y - 1 + n) % n
			var yp: int = (y + 1) % n
			var row: int = y * n
			var row_m: int = ym * n
			var row_p: int = yp * n
			for x: int in n:
				var xm: int = (x - 1 + n) % n
				var xp: int = (x + 1) % n
				var i0: int = row + x
				var uu: float = u_buf[i0]
				var vv: float = v_buf[i0]
				# 5-point toroidal Laplacian.
				var lap_u: float = u_buf[row + xm] + u_buf[row + xp] \
					+ u_buf[row_m + x] + u_buf[row_p + x] - 4.0 * uu
				var lap_v: float = v_buf[row + xm] + v_buf[row + xp] \
					+ v_buf[row_m + x] + v_buf[row_p + x] - 4.0 * vv
				var reaction: float = uu * vv * vv
				u_next[i0] = clampf(uu + (_RD_DU * lap_u - reaction + feed * (1.0 - uu)) * dt, 0.0, 1.0)
				v_next[i0] = clampf(vv + (_RD_DV * lap_v + reaction - (kill + feed) * vv) * dt, 0.0, 1.0)
		# Swap buffers (copy back).
		for i: int in size:
			u_buf[i] = u_next[i]
			v_buf[i] = v_next[i]

	return v_buf


## Linearly remap the field so [lo, hi] -> [0, 1] (clamped), spreading the spot contrast
## across the full range regardless of the regime's natural V ceiling.
func _rd_normalize_field(field: PackedFloat32Array, lo: float, hi: float) -> void:
	var span: float = maxf(hi - lo, 0.0001)
	for i: int in field.size():
		field[i] = clampf((field[i] - lo) / span, 0.0, 1.0)


# ── BODY — ellipsoid creature, RD-displaced, two-tone vertex colour (_rd_) ──

func _rd_build_body(rd_field: PackedFloat32Array, rd_n: int) -> MeshInstance3D:
	var cols: int = _RD_BODY_U_SEG + 1
	var rows: int = _RD_BODY_V_SEG + 1

	var positions: PackedVector3Array = PackedVector3Array()
	var spot01: PackedFloat32Array = PackedFloat32Array()
	positions.resize(cols * rows)
	spot01.resize(cols * rows)

	for vi: int in rows:
		var v_frac: float = float(vi) / float(_RD_BODY_V_SEG)
		var phi: float = lerpf(-PI * 0.5, PI * 0.5, v_frac)
		var cos_phi: float = cos(phi)
		var sin_phi: float = sin(phi)
		for ui: int in cols:
			var u_frac: float = float(ui) / float(_RD_BODY_U_SEG)
			var theta: float = u_frac * TAU
			var nx: float = cos_phi * cos(theta)
			var ny: float = sin_phi
			var nz: float = cos_phi * sin(theta)
			var base := Vector3(nx * _RD_BODY_RX, ny * _RD_BODY_RY, nz * _RD_BODY_RZ)
			# Ovoid asymmetry: front half (z>0) tapers to a snout, back stays round.
			var front: float = clampf(nz, 0.0, 1.0)
			var shrink: float = 1.0 - _RD_BODY_TAPER * (front * front)
			base.x *= shrink
			base.y *= shrink

			# Sample the Turing field by spherical UV (wrap longitudinally).
			var su: float = fmod(u_frac * _RD_WRAPS_U, 1.0)
			var sv: float = clampf(v_frac * _RD_WRAPS_V, 0.0, 1.0)
			var raw_v: float = _rd_sample_field_bilinear(rd_field, rd_n, su, sv)
			# Sharpen into an ocellus crest field (0 valley .. 1 spot).
			var spot: float = smoothstep(
				_RD_SPOT_THRESHOLD - _RD_SPOT_SHARPNESS, _RD_SPOT_THRESHOLD + _RD_SPOT_SHARPNESS, raw_v)

			var idx: int = vi * cols + ui
			positions[idx] = base
			spot01[idx] = spot

	# Weld the poles: collapse each pole row to one averaged point so the cap does not fan.
	_rd_weld_pole_row(positions, spot01, 0, cols)
	_rd_weld_pole_row(positions, spot01, _RD_BODY_V_SEG, cols)

	# Displace each vertex outward along its analytic ellipsoid normal by the spot field:
	# crests bump out (ocelli), valleys sink slightly.
	for vi: int in rows:
		for ui: int in cols:
			var idx: int = vi * cols + ui
			var p: Vector3 = positions[idx]
			var nrm: Vector3 = _rd_ellipsoid_normal(p)
			var spot: float = spot01[idx]
			var disp: float = spot * _RD_RIDGE_HEIGHT - (1.0 - spot) * _RD_VALLEY_SINK
			positions[idx] = p + nrm * disp

	# Emit triangles with vertex colour = spot field; normals regenerated AFTER displacement.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vi: int in _RD_BODY_V_SEG:
		for ui: int in _RD_BODY_U_SEG:
			var i00: int = vi * cols + ui
			var i01: int = vi * cols + (ui + 1)
			var i10: int = (vi + 1) * cols + ui
			var i11: int = (vi + 1) * cols + (ui + 1)
			_rd_emit_body_vertex(st, positions[i00], spot01[i00])
			_rd_emit_body_vertex(st, positions[i10], spot01[i10])
			_rd_emit_body_vertex(st, positions[i01], spot01[i01])
			_rd_emit_body_vertex(st, positions[i01], spot01[i01])
			_rd_emit_body_vertex(st, positions[i10], spot01[i10])
			_rd_emit_body_vertex(st, positions[i11], spot01[i11])
	st.generate_normals()
	var body_mesh: ArrayMesh = st.commit()

	var mi := MeshInstance3D.new()
	mi.name = "RDCreatureBody"
	mi.mesh = body_mesh
	mi.material_override = _rd_make_skin_material()
	return mi


## Emit one body vertex; spot field rides in vertex colour (greyscale) and UV.x so the
## material blends teal valley <-> rose crest.
func _rd_emit_body_vertex(st: SurfaceTool, p: Vector3, spot: float) -> void:
	st.set_color(Color(spot, spot, spot, 1.0))
	st.set_uv(Vector2(spot, 0.5))
	st.add_vertex(p)


## Analytic outward normal of the base ellipsoid at a point (gradient of the implicit form).
func _rd_ellipsoid_normal(p: Vector3) -> Vector3:
	var n := Vector3(
		p.x / (_RD_BODY_RX * _RD_BODY_RX),
		p.y / (_RD_BODY_RY * _RD_BODY_RY),
		p.z / (_RD_BODY_RZ * _RD_BODY_RZ))
	if n.length_squared() < 0.000001:
		return Vector3.UP
	return n.normalized()


## Collapse a latitude pole row to its averaged position and spot value so the cap welds to a
## single point (no triangle fan, no pinch artefact).
func _rd_weld_pole_row(positions: PackedVector3Array, spot01: PackedFloat32Array,
		row: int, cols: int) -> void:
	var acc := Vector3.ZERO
	var spot_acc: float = 0.0
	for ui: int in cols:
		var idx: int = row * cols + ui
		acc += positions[idx]
		spot_acc += spot01[idx]
	var avg_p: Vector3 = acc / float(cols)
	var avg_s: float = spot_acc / float(cols)
	for ui: int in cols:
		var idx: int = row * cols + ui
		positions[idx] = avg_p
		spot01[idx] = avg_s


## Bilinear sample of the RD field at normalized (u, v); wraps in u (toroidal field) and
## clamps in v. Keeps the ocellus edges smooth on the dense body mesh.
func _rd_sample_field_bilinear(field: PackedFloat32Array, n: int, u: float, v: float) -> float:
	var fx: float = fposmod(u, 1.0) * float(n)
	var fy: float = clampf(v, 0.0, 0.99999) * float(n - 1)
	var x0: int = int(floorf(fx)) % n
	var y0: int = int(floorf(fy))
	var x1: int = (x0 + 1) % n
	var y1: int = mini(y0 + 1, n - 1)
	var tx: float = fx - floorf(fx)
	var ty: float = fy - floorf(fy)
	var v00: float = field[y0 * n + x0]
	var v10: float = field[y0 * n + x1]
	var v01: float = field[y1 * n + x0]
	var v11: float = field[y1 * n + x1]
	var top: float = lerpf(v00, v10, tx)
	var bot: float = lerpf(v01, v11, tx)
	return lerpf(top, bot, ty)


# ── HEAD / EYES / LIMBS — make it read as an organism (_rd_) ──

func _rd_build_head(parent: Node3D, origin: Vector3) -> void:
	var head_mesh: Mesh = MorphoPrimitive.sphere(0.30, 24, 14)
	_cm_add_mesh(parent, head_mesh, _rd_make_head_material(),
		Transform3D(Basis().scaled(Vector3(1.0, 0.92, 1.05)), origin), "SensorHead")


func _rd_build_eyes(parent: Node3D, head_origin: Vector3) -> void:
	var eye_mesh: Mesh = MorphoPrimitive.sphere(0.075, 16, 10)
	var eye_mat: StandardMaterial3D = _rd_make_eye_material()
	var pupil_mat: StandardMaterial3D = _rd_make_pupil_material()
	var offsets: Array[Vector3] = [
		head_origin + Vector3(-0.135, 0.075, 0.255),
		head_origin + Vector3(0.135, 0.075, 0.255),
	]
	for i: int in offsets.size():
		_cm_add_mesh(parent, eye_mesh, eye_mat,
			Transform3D(Basis(), offsets[i]), "Eye_%d" % i)
		# A tiny dark pupil so the eye reads as an eye, not a lamp.
		_cm_add_mesh(parent, MorphoPrimitive.sphere(0.034, 12, 8), pupil_mat,
			Transform3D(Basis(), offsets[i] + Vector3(0.0, 0.0, 0.052)), "Pupil_%d" % i)


func _rd_build_limbs(parent: Node3D) -> void:
	var limb_mat: StandardMaterial3D = _rd_make_skin_material()
	var foot_y: float = -_RD_BODY_RY * 0.62
	var specs: Array[Vector3] = [
		Vector3(-_RD_BODY_RX * 0.66, foot_y, _RD_BODY_RZ * 0.42),
		Vector3(_RD_BODY_RX * 0.66, foot_y, _RD_BODY_RZ * 0.42),
		Vector3(-_RD_BODY_RX * 0.70, foot_y, -_RD_BODY_RZ * 0.40),
		Vector3(_RD_BODY_RX * 0.70, foot_y, -_RD_BODY_RZ * 0.40),
	]
	for i: int in specs.size():
		var hip: Vector3 = specs[i]
		var knee := hip + Vector3(hip.x * 0.18, -0.16, 0.0)
		var toe := knee + Vector3(hip.x * 0.10, -0.14, 0.04)
		var positions: Array = [hip, knee, toe]
		var radii: Array = [0.135, 0.10, 0.075]
		var limb_mesh: Mesh = MorphoPrimitive.multi_tube(positions, radii, 10)
		if limb_mesh == null:
			continue
		_cm_add_mesh(parent, limb_mesh, limb_mat, Transform3D.IDENTITY, "Limb_%d" % i)


# ── MATERIALS — vertex-colour two-tone skin + runtime ramp texture (_rd_) ──

## Skin: teal base in the valleys, rose ocelli on the crests. The spot field rides in vertex
## colour AND UV.x; a 1x128 ramp texture (sampled by UV.x, built at runtime) carries the
## two-tone, and vertex_color_use_as_albedo multiplies it so the contrast is unmistakable.
## Soft subsurface + a low emissive floor so the skin glows faintly between spots.
func _rd_make_skin_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _rd_build_skin_ramp()
	m.vertex_color_use_as_albedo = true
	m.roughness = clampf(rough_amt * 0.95, 0.02, 1.0)
	m.metallic = clampf(metallic_amt, 0.0, 1.0)
	m.subsurf_scatter_enabled = true
	m.subsurf_scatter_strength = 0.22
	m.emission_enabled = true
	m.emission = color_a
	m.emission_energy_multiplier = _cm_glow_energy(0.07)
	return m


## 1x128 ramp encoding an OCELLUS cross-section along UV.x (the spot field):
##   ~0.00-0.55  teal coat (color_a, valleys + most of the body)
##   ~0.55-0.72  a dark teal HALO ring (the eye-spot's dark rim)
##   ~0.72-1.00  rose/accent centre (the bright ocellus eye, color_b -> accent)
## The dark-rim / bright-centre structure makes a Turing spot read as a Serafini eye-spot.
## Built at runtime — no external asset.
func _rd_build_skin_ramp() -> ImageTexture:
	var coat := color_a.darkened(0.10)   # the valley coat — a touch deeper
	var halo := color_a.darkened(0.46)   # dark rim around each ocellus
	var crest := color_b.lerp(accent, 0.5)  # rose pattern centre warmed by the glow accent
	var w: int = 128
	var img := Image.create(w, 1, false, Image.FORMAT_RGBA8)
	for x: int in w:
		var u: float = float(x) / float(w - 1)
		var col: Color
		if u < 0.55:
			col = coat
		elif u < 0.72:
			col = coat.lerp(halo, smoothstep(0.55, 0.72, u))
		else:
			col = halo.lerp(crest, smoothstep(0.72, 0.96, u))
		img.set_pixel(x, 0, col)
	return ImageTexture.create_from_image(img)


## Head: same skin tone but a touch darker and smoother (a sensor cap).
func _rd_make_head_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color_a.darkened(0.18)
	m.roughness = clampf(rough_amt * 0.85, 0.02, 1.0)
	m.metallic = clampf(metallic_amt, 0.0, 1.0)
	m.subsurf_scatter_enabled = true
	m.subsurf_scatter_strength = 0.30
	m.emission_enabled = true
	m.emission = color_a
	m.emission_energy_multiplier = _cm_glow_energy(0.08)
	return m


## Eye: accent glow, near-unshaded per-pixel so the sphere still rounds — the living glow.
func _rd_make_eye_material() -> StandardMaterial3D:
	return _cm_glow_mat(accent, 3.0, false)


## Pupil: dark, matte — anchors the glowing eye so it reads as an organism's eye.
func _rd_make_pupil_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.05, 0.04, 0.03)
	m.roughness = 0.4
	m.metallic = 0.0
	return m


# =============================================================================
# MODE: taxon — an EVOLVED-VARIANT TAXONOMY GRID (trial v4)
#
# The genuine morphogenesis (GENETIC VARIATION / EVOLUTION, the load-bearing core):
#   One small base GENOME — a typed Dictionary[String, float] of genes (size, elongation,
#   spike_count, spike_length, bump_density, segment_count, hue_shift, core_glow) — is MUTATED
#   per cell to grow a GRID of surreal Codex egg/pods. Each pod is read entirely FROM its
#   genome: a revolution egg body sized/elongated/segmented by genes, radial spikes (count +
#   length from genes, oriented by Basis), surface bumps (density from genes), a hue-shifted
#   tint, and a glowing core. Two forces combine in _tax_mutate_genome:
#     DRIFT     — a per-cell seeded RNG jitters every gene a little (neutral variation; what
#                 makes siblings differ down the rows).
#     SELECTION — a directional trend across columns (sel in [0,1], 0=left): right-hand
#                 specimens are pushed toward "more elaborate" (bigger, more spikes/bumps,
#                 more elongated, hotter hue). This is the fitness axis.
#   Reading left->right is evolution under selection; reading top->bottom is neutral drift.
#   Spikes + bumps are batched per specimen into one ArrayMesh. complexity scales the grid
#   columns (3..4). Deterministic: every per-cell sub-seed is derived from the master seed.
# =============================================================================

const _TAX_TRAY_SPAN: float = 2.40          # board extent across the longer axis
const _TAX_CELL_GAP_FRAC: float = 0.06      # gap between cells as frac of cell pitch
const _TAX_TILT_DEGREES: float = 22.0       # tilt the whole plate toward +X/+Z cam
const _TAX_PLINTH_HEIGHT: float = 0.085     # rise of each little specimen plinth

var _tax_mat_tray: StandardMaterial3D       # tray slab + plinths + spikes (color_b)
var _tax_mat_core: StandardMaterial3D       # glowing core template (accent)


func _build_taxon() -> void:
	# Materials: tray/plinths/spikes (struct), core glow template (accent, duplicated per pod
	# so each can bump its emission by the core_glow gene).
	_tax_mat_tray = _cm_struct_mat(color_b)
	_tax_mat_tray.roughness = clampf(rough_amt * 1.20, 0.02, 1.0)
	_tax_mat_core = _cm_glow_mat(accent, 2.5, true)

	# Grid size scales with complexity: 3x3 -> 4x3 (cols x rows). (native 6 -> 4 cols.)
	var cols: int = clampi(2 + complexity / 3, 3, 4)
	var rows: int = 3

	# Cell pitch from the tray span across the wider (cols) axis.
	var pitch: float = _TAX_TRAY_SPAN / float(cols)
	var gap: float = pitch * _TAX_CELL_GAP_FRAC
	var cell: float = pitch - gap
	var grid_w: float = pitch * float(cols)
	var grid_d: float = pitch * float(rows)

	# Tilt the whole plate toward the +X/+Z capture camera so the grid reads.
	var plate := Node3D.new()
	plate.name = "Taxon"
	plate.basis = Basis().rotated(Vector3(1.0, 0.0, -1.0).normalized(), deg_to_rad(_TAX_TILT_DEGREES))
	add_child(plate)

	# Tray slab (one batched mesh: base + plinths). Sits on y=0.
	_tax_build_tray(plate, cols, rows, pitch, cell, grid_w, grid_d)

	# Specimens, one per cell, each from a mutated genome.
	var base: Dictionary = _tax_base_genome()
	for cx: int in range(cols):
		for cz: int in range(rows):
			# Selection axis = column (left->right). Drift axis = row.
			var sel: float = float(cx) / maxf(float(cols - 1), 1.0)
			var row_t: float = float(cz) / maxf(float(rows - 1), 1.0)
			# Deterministic per-cell sub-seed derived from the master seed.
			var cell_seed: int = seed + cx * 1009 + cz * 7919 + 31
			var genome: Dictionary = _tax_mutate_genome(base, cell_seed, sel, row_t)

			var pod: Node3D = _tax_build_specimen(genome)
			# Cell centre on the tray (centred grid).
			var px: float = (float(cx) + 0.5) * pitch - grid_w * 0.5
			var pz: float = (float(cz) + 0.5) * pitch - grid_d * 0.5
			# Lift the pod so its base meets the plinth top.
			var body_h: float = float(genome["size"]) * float(genome["elongation"])
			pod.position = Vector3(px, _TAX_PLINTH_HEIGHT + body_h, pz)
			plate.add_child(pod)

	# The plate sits on its tray; centre it (float) for the capture.
	_cm_settle(plate, maxf(sculpt_height, 0.4), maxf(sculpt_width, 0.2), false)


# ── GENOME — a typed Dictionary of float genes (the base lineage) (_tax_) ──

## The ancestral base genome. Every specimen in the grid is a mutation of this. All values
## are floats (typed Dictionary[String, float]).
func _tax_base_genome() -> Dictionary:
	var g: Dictionary[String, float] = {
		"size": 0.155,
		"elongation": 1.15,
		"spike_count": 5.0,
		"spike_length": 0.34,
		"bump_density": 6.0,
		"segment_count": 2.0,
		"hue_shift": 0.00,
		"core_glow": 1.6,
	}
	return g


## Produce one cell's genome from the base. DRIFT (per-cell seeded RNG jitter, neutral) +
## SELECTION (directional trend across columns, sel in [0,1], the fitness axis). `row_t` adds
## a gentle secondary drift so rows read distinct. cell_seed is derived from the master seed.
func _tax_mutate_genome(base: Dictionary, cell_seed: int, sel: float, row_t: float) -> Dictionary:
	var cr := RandomNumberGenerator.new()
	cr.seed = cell_seed

	var d: float = 0.12                     # neutral drift fraction
	var s: float = clampf(sel, 0.0, 1.0)

	var size_b: float = float(base["size"])
	var elon_b: float = float(base["elongation"])
	var spl_b: float = float(base["spike_length"])
	var hue_b: float = float(base["hue_shift"])
	var glow_b: float = float(base["core_glow"])

	# size: grows ~0.82->1.40x under selection; ±drift (the most legible selection signal).
	var size_g: float = size_b * lerpf(0.82, 1.40, s) * (1.0 + cr.randf_range(-d, d))
	# elongation: ancestral rounder eggs -> selected spindly pods.
	var elon_g: float = elon_b * lerpf(0.84, 1.42, s) + cr.randf_range(-0.10, 0.10)
	# spike_count: 3 (left) -> 10 (right) before drift; drift ±1.5; rows nudge spikes too.
	var spk_g: float = lerpf(3.0, 10.0, s) + cr.randf_range(-1.5, 1.5)
	spk_g += (row_t - 0.5) * 2.0
	# spike_length: longer under selection.
	var spl_g: float = lerpf(0.18, 0.44, s) * spl_b / 0.34 + cr.randf_range(-0.04, 0.04)
	# bump_density: barer (left) -> encrusted (right).
	var bmp_g: float = lerpf(2.0, 13.0, s) + cr.randf_range(-2.0, 2.0)
	# segment_count: more waist lumps under selection (1->3).
	var seg_g: float = lerpf(1.0, 3.0, s) + cr.randf_range(-0.4, 0.4)
	# hue_shift: a warm pigment cline — pale ochre (left) drifting through coral to a hot
	# rose-pink (right). Signed shift in (-) hue so the family stays in the warm arc.
	var hue_g: float = lerpf(0.0, -0.12, s) + hue_b + (row_t - 0.5) * 0.04 + cr.randf_range(-0.03, 0.03)
	# core_glow: brighter cores on the selected side.
	var glow_g: float = glow_b * lerpf(0.75, 1.4, s) * (1.0 + cr.randf_range(-0.12, 0.12))
	# richness: a derived expression of selection that deepens the body's saturation + value
	# (pale ancestral -> vivid selected). Drift keeps siblings distinct.
	var rich_g: float = clampf(s + cr.randf_range(-0.06, 0.06), 0.0, 1.0)

	var out: Dictionary[String, float] = {
		"size": maxf(size_g, 0.10),
		"elongation": clampf(elon_g, 0.70, 1.9),
		"spike_count": maxf(spk_g, 0.0),
		"spike_length": clampf(spl_g, 0.12, 0.52),
		"bump_density": maxf(bmp_g, 0.0),
		"segment_count": clampf(seg_g, 0.5, 4.0),
		"hue_shift": hue_g,
		"core_glow": maxf(glow_g, 0.4),
		"richness": rich_g,
	}
	return out


# ── ONE SPECIMEN — built entirely from its genome (_tax_) ──

## Build a small Codex pod from `genome`. Returns a Node3D holding the body, the batched
## spikes mesh, the batched bumps mesh, and a glowing core. Centred on its local origin, base
## near y=0; the caller lifts it onto its plinth.
func _tax_build_specimen(genome: Dictionary) -> Node3D:
	var pod := Node3D.new()
	pod.name = "Specimen"

	var size_g: float = float(genome["size"])
	var elon_g: float = float(genome["elongation"])
	var spike_n: int = int(round(float(genome["spike_count"])))
	var spike_len: float = float(genome["spike_length"])
	var bump_n: int = int(round(float(genome["bump_density"])))
	var seg_g: float = float(genome["segment_count"])
	var hue_g: float = float(genome["hue_shift"])
	var glow_g: float = float(genome["core_glow"])
	var rich_g: float = float(genome.get("richness", 0.5))

	var body_r: float = size_g                          # equatorial radius
	var body_h: float = size_g * elon_g                 # half-height of the egg

	# Body: a revolution egg/pod profile, with `segment_count` waist lumps.
	var body_mesh: Mesh = _tax_build_body_mesh(body_r, body_h, seg_g)
	_cm_add_mesh(pod, body_mesh, _tax_body_material(hue_g, rich_g), Transform3D.IDENTITY, "Body")

	# Spikes: radial cones around the upper body, oriented by Basis, batched into one mesh.
	if spike_n > 0:
		var spikes_mesh: ArrayMesh = _tax_build_spikes_mesh(body_r, body_h, spike_n, spike_len, seg_g)
		if spikes_mesh != null:
			_cm_add_mesh(pod, spikes_mesh, _tax_mat_tray, Transform3D.IDENTITY, "Spikes")

	# Bumps: low hemispherical nodes scattered over the surface, batched into one mesh.
	if bump_n > 0:
		var bumps_mesh: ArrayMesh = _tax_build_bumps_mesh(body_r, body_h, bump_n, seg_g)
		if bumps_mesh != null:
			_cm_add_mesh(pod, bumps_mesh, _tax_body_material(hue_g + 0.03, rich_g * 0.85),
				Transform3D.IDENTITY, "Bumps")

	# Glowing core: a small squashed sphere peeking from the pod crown. Kept small so it reads
	# as a luminous aperture, not a halo. Emission energy from the core_glow gene.
	var core_r: float = body_r * 0.20
	var core_mat: StandardMaterial3D = _tax_mat_core.duplicate()
	core_mat.emission_energy_multiplier = _cm_glow_energy(glow_g)
	_cm_add_mesh(pod, MorphoPrimitive.sphere(core_r, 12, 8), core_mat,
		Transform3D(Basis().scaled(Vector3(1.0, 0.8, 1.0)), Vector3(0.0, body_h * 0.55, 0.0)),
		"Core")

	return pod


## Body material for one specimen: the Codex creature colour (color_a as base), hue-rotated by
## the hue_shift gene. `richness` (0-1, from the selection axis) deepens saturation + value so
## ancestral specimens read pale/washed and selected ones read vivid.
func _tax_body_material(hue_shift: float, richness: float) -> StandardMaterial3D:
	var base := color_a
	var r: float = clampf(richness, 0.0, 1.0)
	var h: float = fposmod(base.h + hue_shift, 1.0)
	var sat: float = clampf(lerpf(0.36, 0.78, r), 0.0, 0.95)
	var val: float = clampf(lerpf(0.86, 0.74, r), 0.3, 1.0)
	var col := Color.from_hsv(h, sat, val)
	return _cm_flesh_mat(col)


## Egg/pod body of revolution. `seg` waist lobes ripple the radius along the axis so higher
## segment_count reads as a lumpy segmented Codex specimen. y runs -body_h (bottom) -> +body_h.
func _tax_build_body_mesh(body_r: float, body_h: float, seg: float) -> Mesh:
	var rings: int = 22
	var profile: Array[Vector2] = []
	for i: int in range(rings + 1):
		var t: float = float(i) / float(rings)          # 0 bottom -> 1 top
		var y: float = lerpf(-body_h, body_h, t)
		var env: float = sin(t * PI)
		var bias: float = 1.0 - 0.22 * (t - 0.5)        # fatter low, tapered high
		var ripple: float = 1.0 + 0.12 * cos(t * TAU * maxf(seg, 0.5))
		var r: float = body_r * env * bias * ripple
		r = maxf(r, body_r * 0.012)
		profile.append(Vector2(r, y))
	return MorphoPrimitive.revolution(profile, 20)


## Surface point + outward normal on the egg envelope at parametric (t, ang). Mirrors the body
## profile maths so spikes/bumps sit ON the surface. Returns [pos, normal].
func _tax_surface_point(t: float, ang: float, body_r: float, body_h: float, seg: float) -> Array:
	var y: float = lerpf(-body_h, body_h, t)
	var env: float = sin(t * PI)
	var bias: float = 1.0 - 0.22 * (t - 0.5)
	var ripple: float = 1.0 + 0.12 * cos(t * TAU * maxf(seg, 0.5))
	var r: float = maxf(body_r * env * bias * ripple, body_r * 0.012)
	var pos := Vector3(cos(ang) * r, y, sin(ang) * r)
	var radial := Vector3(cos(ang), 0.0, sin(ang))
	var slope: float = cos(t * PI)
	var normal: Vector3 = (radial - Vector3.UP * slope * 0.5).normalized()
	return [pos, normal]


## Radial spikes batched into one ArrayMesh. Each spike is a thin cone built ring-by-ring from
## a base on the body surface out along the surface normal; oriented via a Basis (no look_at).
func _tax_build_spikes_mesh(body_r: float, body_h: float, spike_n: int, spike_len: float, seg: float) -> ArrayMesh:
	if spike_n <= 0:
		return null
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var spike_extent: float = body_r * (0.30 + spike_len * 0.95)
	var base_radius: float = body_r * 0.10
	for si: int in range(spike_n):
		var ang: float = TAU * float(si) / float(spike_n)
		# Alternate two latitudes for a denser, more organic crown.
		var t: float = 0.62 if (si % 2 == 0) else 0.46
		var sp: Array = _tax_surface_point(t, ang, body_r, body_h, seg)
		var base_pos: Vector3 = sp[0] as Vector3
		var out_dir: Vector3 = sp[1] as Vector3
		var seat: Vector3 = base_pos - out_dir * base_radius * 0.6
		var tip_pos: Vector3 = base_pos + out_dir * spike_extent
		var basis: Basis = _cm_basis_from_up(out_dir)
		_tax_emit_cone(st, seat, tip_pos, basis, base_radius, 6)

	st.generate_normals()
	return st.commit()


## Surface bumps batched into one ArrayMesh: low hemispheres seated on the body surface at
## pseudo-random (t, ang) positions. Uses the master RNG (deterministic order) for placement.
func _tax_build_bumps_mesh(body_r: float, body_h: float, bump_n: int, seg: float) -> ArrayMesh:
	if bump_n <= 0:
		return null
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for bi: int in range(bump_n):
		var t: float = _rng.randf_range(0.18, 0.86)
		var ang: float = _rng.randf_range(0.0, TAU)
		var sp: Array = _tax_surface_point(t, ang, body_r, body_h, seg)
		var pos: Vector3 = sp[0] as Vector3
		var nrm: Vector3 = sp[1] as Vector3
		var bump_r: float = body_r * _rng.randf_range(0.07, 0.13)
		var centre: Vector3 = pos - nrm * bump_r * 0.35
		_tax_emit_hemisphere(st, centre, nrm, bump_r, 6, 3)

	st.generate_normals()
	return st.commit()


# ── taxon batched-geometry sub-helpers (_tax_) ──

## Emit a cone from `base` to `tip` into `st`. `basis` gives the local frame (Y = axis from
## base to tip). `sides` rim segments; radius `base_r` at base tapering to the tip. Base fan.
func _tax_emit_cone(st: SurfaceTool, base: Vector3, tip: Vector3, basis: Basis,
		base_r: float, sides: int) -> void:
	var x: Vector3 = basis.x
	var z: Vector3 = basis.z
	var rim: Array[Vector3] = []
	for si: int in range(sides):
		var a: float = TAU * float(si) / float(sides)
		rim.append(base + (x * cos(a) + z * sin(a)) * base_r)
	# Side faces (rim_i, rim_next, tip).
	for si: int in range(sides):
		var p0: Vector3 = rim[si]
		var p1: Vector3 = rim[(si + 1) % sides]
		var n: Vector3 = (p1 - p0).cross(tip - p0).normalized()
		st.set_normal(n); st.add_vertex(p0)
		st.set_normal(n); st.add_vertex(p1)
		st.set_normal(n); st.add_vertex(tip)
	# Base cap (fan around base centre), facing away from the tip.
	var down: Vector3 = (base - tip).normalized()
	for si: int in range(sides):
		var p0: Vector3 = rim[si]
		var p1: Vector3 = rim[(si + 1) % sides]
		st.set_normal(down); st.add_vertex(base)
		st.set_normal(down); st.add_vertex(p1)
		st.set_normal(down); st.add_vertex(p0)


## Emit a low hemisphere (dome) seated at `centre`, bulging along `up`. A surface bump/node.
func _tax_emit_hemisphere(st: SurfaceTool, centre: Vector3, up: Vector3,
		radius: float, seg: int, rings: int) -> void:
	var basis: Basis = _cm_basis_from_up(up)
	var grid: Array = []
	for ri: int in range(rings + 1):
		var lat: float = (PI * 0.5) * float(ri) / float(rings)
		var ring_r: float = cos(lat) * radius
		var ring_h: float = sin(lat) * radius
		var ring: Array[Vector3] = []
		for sj: int in range(seg):
			var a: float = TAU * float(sj) / float(seg)
			var local := basis.x * (cos(a) * ring_r) + basis.z * (sin(a) * ring_r) + basis.y * ring_h
			ring.append(centre + local)
		grid.append(ring)
	for ri: int in range(rings):
		var ra: Array = grid[ri] as Array
		var rb: Array = grid[ri + 1] as Array
		for sj: int in range(seg):
			var sn: int = (sj + 1) % seg
			var v00: Vector3 = ra[sj] as Vector3
			var v01: Vector3 = ra[sn] as Vector3
			var v10: Vector3 = rb[sj] as Vector3
			var v11: Vector3 = rb[sn] as Vector3
			var n0: Vector3 = (v10 - v00).cross(v01 - v00).normalized()
			st.set_normal(n0); st.add_vertex(v00)
			st.set_normal(n0); st.add_vertex(v10)
			st.set_normal(n0); st.add_vertex(v01)
			var n1: Vector3 = (v11 - v01).cross(v10 - v01).normalized()
			st.set_normal(n1); st.add_vertex(v01)
			st.set_normal(n1); st.add_vertex(v10)
			st.set_normal(n1); st.add_vertex(v11)


## Emit one box (for the tray slab/plinths) — centred at `c`, half-extents (hx,hy,hz) along
## world axes.
func _tax_emit_box(st: SurfaceTool, c: Vector3, hx: float, hy: float, hz: float) -> void:
	var ax := Vector3.RIGHT * hx
	var ay := Vector3.UP * hy
	var az := Vector3.BACK * hz
	var p000: Vector3 = c - ax - ay - az
	var p100: Vector3 = c + ax - ay - az
	var p110: Vector3 = c + ax + ay - az
	var p010: Vector3 = c - ax + ay - az
	var p001: Vector3 = c - ax - ay + az
	var p101: Vector3 = c + ax - ay + az
	var p111: Vector3 = c + ax + ay + az
	var p011: Vector3 = c - ax + ay + az
	_tax_quad(st, p000, p010, p110, p100, Vector3.FORWARD)
	_tax_quad(st, p001, p101, p111, p011, Vector3.BACK)
	_tax_quad(st, p000, p100, p101, p001, Vector3.DOWN)
	_tax_quad(st, p010, p011, p111, p110, Vector3.UP)
	_tax_quad(st, p000, p001, p011, p010, Vector3.LEFT)
	_tax_quad(st, p100, p110, p111, p101, Vector3.RIGHT)


func _tax_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3) -> void:
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(b)
	st.set_normal(n); st.add_vertex(c)
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(c)
	st.set_normal(n); st.add_vertex(d)


## Tray: a thin base slab plus a little square plinth under each cell, all batched into one
## ArrayMesh (struct stone). The slab top sits at y=0; plinths rise _TAX_PLINTH_HEIGHT above.
func _tax_build_tray(parent: Node3D, cols: int, rows: int, pitch: float, cell: float,
		grid_w: float, grid_d: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Base slab: a touch larger than the grid footprint, thin, top at y=0.
	var slab_hx: float = grid_w * 0.5 + pitch * 0.10
	var slab_hz: float = grid_d * 0.5 + pitch * 0.10
	var slab_hy: float = 0.06
	_tax_emit_box(st, Vector3(0.0, -slab_hy, 0.0), slab_hx, slab_hy, slab_hz)

	# Plinths: one per cell, square footprint, top at _TAX_PLINTH_HEIGHT.
	var plinth_half: float = cell * 0.34
	for cx: int in range(cols):
		for cz: int in range(rows):
			var px: float = (float(cx) + 0.5) * pitch - grid_w * 0.5
			var pz: float = (float(cz) + 0.5) * pitch - grid_d * 0.5
			var ch: float = _TAX_PLINTH_HEIGHT * 0.5
			_tax_emit_box(st, Vector3(px, ch, pz), plinth_half, ch, plinth_half)

	st.generate_normals()
	_cm_add_mesh(parent, st.commit(), _tax_mat_tray, Transform3D.IDENTITY, "Tray")
