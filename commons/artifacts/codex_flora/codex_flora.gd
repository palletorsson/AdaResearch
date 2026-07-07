extends Node3D
class_name CodexFlora

## @identity
# essence: a single DNA-driven CODEX BOTANICAL SPECIMEN grown as a GENUINE L-SYSTEM —
#   Luigi Serafini's imaginary-botany plates rendered not as primitive-stacks but as
#   actual recursive grammars walked by 3D turtles. Where most artifacts assemble a
#   plant from boxes and spheres, CodexFlora GROWS each body from a rule: a sentence is
#   rewritten generation by generation, then interpreted as form. Depending on its `mode`
#   DNA it becomes one of FOUR teaching specimens whose shape IS its production rule:
#   bracketed (a canonical bracketed L-system tree — axiom "F" rewritten by a seed-chosen
#   rule like F->FF+[+F-F-F]-[-F+F+F], a typed 3D turtle with push/pop brackets emitting
#   tapered tube branches that decay with depth, surreal Codex canopy — broccoli domes,
#   glowing fruit, a single eye, leaf tufts — at the leaf-bracket tips, and recursive
#   thread-roots gripping the ground with the same grammar), helix (a PARAMETRIC L-system
#   — two phase-offset helical strands climbing as a DNA ladder with base-pair rungs, a
#   turtle advancing up with constant roll, phyllotactic golden-angle leaves, topped by a
#   layered artichoke head of overlapping scale-caps with a glowing core peeking through),
#   spacefill (a SPACE-FILLING L-system — the Koch quadric F->F+F-F-F+F rewritten N
#   generations into a dense crinkled polyline, then COILED by arc-length onto a fiddlehead
#   log-spiral and swept as a lacy ribbon tendril, the recursion riding as the edge crinkle,
#   capped with a glowing bloom at each free curl-tip), and inflorescence (a RECURSIVE
#   PHYLLOTACTIC grammar — a stem rule re-applied for DEPTH levels, each shoot shedding
#   golden-angle leaves and branching into a whorl of sub-stems that each re-run the rule,
#   terminating in size-graded Codex blooms whose petals + Vogel-spiral seed-dots are
#   batched into one mesh). It is identity confessed as a GRAMMAR — the plant is its rule,
#   not its parts.
# desire: it wants the L-system to stay LEGIBLE — the recursion (branching depth, the
#   coiled crinkle, the candelabra forks, the helix turns) read as rule-generated rather
#   than hand-placed. It wants FOLIAGE to glow soft-green with an emission floor so leaves
#   never collapse to black against the dark capture, WOODY stems to read warm and matte,
#   and BLOOMS / fruit / cores to BURN bioluminescent. Above all it wants every string to
#   TERMINATE — each rewrite capped so expansion never explodes.
# critical_parameter: mode + seed + the colour triad (color_a FOLIAGE/PETAL / color_b
#   WOODY STEM / accent BLOOM/core GLOW) + complexity. mode picks the grammar lineage;
#   seed varies the individual deterministically (a local seeded RNG, no global randf/randi
#   ever — it drives the rule pick, every angle jitter, every canopy choice); complexity
#   scales L-system GENERATIONS (bracketed/spacefill), branch DEPTH + bloom count
#   (inflorescence), and helix TURNS + scale rows (helix).
# triggers: _ready() reads DNA metadata overrides, seeds the RNG from `seed`, and branches
#   on `mode` to a _build_<mode>() helper; apply_grid_config rewrites config metas, clears
#   children (remove BEFORE free, guarded by `_built`), and rebuilds.
# emerges: a row of these reads as a HERBARIUM OF GRAMMARS — four ways a sentence can
#   become a plant. Switch one mode and the room's idea of "what makes a plant" shifts
#   from assembly to GENERATION; reseed and the species persists while its individual
#   varies. These are teaching specimens for the `lsystems` curriculum room.
# needs: the project's LSystem string rewriter (class_name LSystem) for the bracketed +
#   spacefill grammars [present]; a seeded RNG for deterministic individuals [present];
#   four build branches each carrying its trial's bespoke machinery (bracketed turtle,
#   parametric helix, coiled Koch sweep, recursive phyllotactic grow) [present]; foliage /
#   wood / glow materials driven by the colour triad [present]; petals / leaves / seed-dots
#   batched into one ArrayMesh per kind so the AABB capture frames the spray [present].
# relationships: kin to haeckel (same genome shape + conventions — identity header, grouped
#   @export, apply_grid_config + _parse_color + _built rebuild guard, seeded RNG, settle
#   centring; haeckel grows open lattices, CodexFlora grows grammars); built on the
#   nature_system morphology engine it borrows from (MorphoPrimitive / MorphoSweep /
#   MorphoModifier); cousin to tree_morphology + flower_morphology (the project's L-system +
#   flower references the trials drew on); cousin to any mode-switchboard of one genome.
# truth: a sentence can become a forest — grammar is generative; the plant is its rule.
#   Serafini drew botany that could not exist; an L-system grows botany that did not exist
#   until the rule ran. CodexFlora holds four such grammars in one genome where the body is
#   GROWN from a string — a bracketed tree, a helical ladder, a coiled space-filling frond,
#   a recursive flowering candelabra — and lets a single parameter choose which grammar the
#   viewer is invited to read. The recursion must stay legible, the foliage must glow, the
#   bloom must burn, and above all the string must terminate.

## A multi-mode generative Codex-botany specimen grown as a GENUINE L-SYSTEM.
##
## Built procedurally from DNA exports, after Luigi Serafini's Codex Seraphinianus, for
## the `lsystems` curriculum sequence ("A sentence can become a forest. Grammar is
## generative."). The `mode` export selects one of FOUR grammars, each ported faithfully
## from a verified trial:
## bracketed (a bracketed L-system tree — axiom + seed-chosen production rule expanded N
## generations, walked by a typed 3D turtle with push/pop brackets, tapered tube branches
## decaying with depth, surreal Codex canopy at leaf-bracket tips, recursive thread-roots),
## helix (a parametric L-system — two phase-offset helical strands as a DNA ladder with
## base-pair rungs, phyllotaxis leaves, a layered artichoke head with a glowing core),
## spacefill (a space-filling L-system — the Koch rule F->F+F-F-F+F rewritten into a dense
## polyline, coiled by arc-length onto a fiddlehead log-spiral, swept as a lacy ribbon
## tendril with glowing blooms at the curl-tips), inflorescence (a recursive phyllotactic
## grammar — a stem rule re-applied for DEPTH levels, golden-angle leaves + sub-stem
## whorls, terminating in size-graded Codex blooms with batched petals + seed-dots).
##
## A seeded RNG makes every individual deterministic from its `seed`. The colour triad
## (color_a FOLIAGE/PETAL / color_b WOODY STEM / accent BLOOM/core GLOW) re-registers the
## same anatomy between palettes. Shared material + orient + settle helpers live under the
## `_cfl_` prefix; the bespoke grammar machinery from each trial stays in its own builder
## under `_brk_` / `_hlx_` / `_spf_` / `_inf_` so the genuine L-system logic (string
## rewriting + turtle, parametric helix, coiled Koch sweep, recursive branching) is
## preserved — that is the whole point. Surface generation reuses the morphology toolkit
## statics (MorphoPrimitive, MorphoSweep, MorphoModifier).
##
## complexity scales the grammar's recursion budget per mode: bracketed L-system
## GENERATIONS (3..5), helix TURNS + head scale-rows, spacefill Koch GENERATIONS (3..4),
## inflorescence branch DEPTH (2..4) + bloom count. Higher complexity = deeper recursion.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Form")
## bracketed | helix | spacefill | inflorescence
@export var mode: String = "bracketed"
## Deterministic seed — same seed always yields the same plant.
@export var seed: int = 0
## Detail / recursion budget. Scales L-system generations (bracketed/spacefill), branch
## depth + bloom count (inflorescence), and helix turns + head scale-rows (helix).
@export var complexity: int = 6
## Overall height in meters (nominal full height of the plant).
@export var sculpt_height: float = 2.2
## Footprint / across-span width scale in meters (1.0 = native trial proportions).
@export var sculpt_width: float = 1.0

@export_group("Material")
## FOLIAGE / PETAL — vivid Codex green / bloom leaf.
@export var color_a: Color = Color(0.36, 0.55, 0.34)
## WOODY STEM / branch / strand — warm brown backbone.
@export var color_b: Color = Color(0.46, 0.34, 0.24)
## BLOOM / FRUIT / core GLOW — bioluminescent accent.
@export var accent: Color = Color(0.98, 0.78, 0.30)
## Plant matter, not metal — keep this LOW.
@export var metallic_amt: float = 0.0
@export var rough_amt: float = 0.75
## Boost emissive energies (glow reads hotter when true).
@export var emissive: bool = true

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false
var _rng := RandomNumberGenerator.new()

# Hard caps so every rewrite terminates (the genuine L-systems never explode).
const _BRK_STRING_CAP: int = 9000
const _SPF_STRING_CAP: int = 4000


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
	# DEFERRED (after apply_grid_config has already built), a second _build() must not
	# stack a second plant on top of the first. Remove BEFORE freeing (queue_free is
	# deferred) so the rebuild starts from a genuinely empty subtree this frame.
	for c: Node in get_children():
		remove_child(c)
		c.queue_free()
	_built = true
	_rng.seed = seed
	match mode:
		"bracketed":
			_build_bracketed()
		"helix":
			_build_helix()
		"spacefill":
			_build_spacefill()
		"inflorescence":
			_build_inflorescence()
		_:
			# Unknown mode falls back to the canonical bracketed L-system tree.
			_build_bracketed()


# ── Shared `_cfl_` material helpers (the three trial materials, DNA-driven) ─────

## Energy multiplier for emissive elements, lifted when `emissive` is on (gated like
## haeckel's `_hk_glow_energy`).
func _cfl_glow_energy(base: float) -> float:
	return base * (1.0 if emissive else 0.6)


## FOLIAGE / leaf / petal (color_a family): soft green with a little subsurface and an
## emission FLOOR in its own tone so thin blades read against the dark capture. Two-sided
## so thin sheets show both faces.
func _cfl_foliage_mat(c: Color = color_a) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = clampf(rough_amt * 0.93, 0.02, 1.0)
	m.metallic = clampf(metallic_amt, 0.0, 1.0)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.subsurf_scatter_enabled = true
	m.subsurf_scatter_strength = 0.2
	m.emission_enabled = true
	m.emission = c * 0.4
	m.emission_energy_multiplier = _cfl_glow_energy(0.10)
	return m


## WOODY stem / branch / strand (color_b family): warm matte backbone with a faint
## emission floor so the recursive skeleton never collapses to black.
func _cfl_wood_mat(c: Color = color_b) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = clampf(rough_amt * 1.13, 0.02, 1.0)
	m.metallic = clampf(metallic_amt, 0.0, 1.0)
	m.emission_enabled = true
	m.emission = c * 0.4
	m.emission_energy_multiplier = _cfl_glow_energy(0.10)
	return m


## BLOOM / FRUIT / core GLOW (accent family): saturated near-unshaded bioluminescence.
## `energy` ~3; `unshaded` toggles full unshaded (cores/seed-dots) vs shaded glow (domes).
func _cfl_glow_mat(c: Color = accent, energy: float = 3.0, unshaded: bool = true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	else:
		m.roughness = clampf(rough_amt * 0.53, 0.02, 1.0)
		m.metallic = clampf(metallic_amt, 0.0, 1.0)
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = _cfl_glow_energy(energy)
	return m


# ── Shared `_cfl_` geometry helpers ────────────────────────────────────

## Orthonormal Basis whose Y (heading/up) axis is `up_axis`. The single orient primitive
## the turtles + blooms use so orientation is always via Basis, never out-of-tree look_at.
func _cfl_basis_from_up(up_axis: Vector3) -> Basis:
	var y: Vector3 = up_axis.normalized()
	if y.length_squared() < 0.0001:
		y = Vector3.UP
	var ref: Vector3 = Vector3.RIGHT
	if absf(y.dot(ref)) > 0.95:
		ref = Vector3.FORWARD
	var x: Vector3 = ref.cross(y).normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Basis(x, y, z)


## Any unit vector perpendicular to v (for degenerate-frame fallbacks).
func _cfl_any_perp(v: Vector3) -> Vector3:
	var ref: Vector3 = Vector3.RIGHT
	if absf(v.normalized().dot(ref)) > 0.95:
		ref = Vector3.FORWARD
	return ref.cross(v).normalized()


## Wrap a Mesh in a MeshInstance3D with material + local transform, parented to `parent`.
func _cfl_add_mesh(parent: Node3D, mesh: Mesh, mat: Material,
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


## Commit a batched SurfaceTool into one MeshInstance3D under `parent` (petals, leaves,
## seed-dots — the trials batch many small blades into a single ArrayMesh for the capture).
func _cfl_commit_batch(parent: Node3D, st: SurfaceTool, mat: Material, nm: String) -> void:
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return
	_cfl_add_mesh(parent, mesh, mat, Transform3D.IDENTITY, nm)


## Local AABB over all MeshInstance3D descendants of `node`, accumulated through the chain
## of LOCAL transforms down from `node` (never touches global_transform — independent of
## tree state). Used to centre + scale each plant.
func _cfl_subtree_aabb(node: Node3D) -> AABB:
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


## Centre `body` and scale it to ~`target_h` tall, base dropped to y=0 (these are standing
## plants), then horizontally centred at the origin so the +X/+Z capture frames it. The
## haeckel `_hk_settle` analogue — width_scale stretches the horizontal axes for span.
func _cfl_settle(body: Node3D, target_h: float, width_scale: float = 1.0) -> void:
	if target_h > 0.0:
		var raw: AABB = _cfl_subtree_aabb(body)
		var span_y: float = maxf(raw.size.y, 0.001)
		var k: float = target_h / span_y
		body.scale = Vector3(k * width_scale, k, k * width_scale)
	var aabb: AABB = _cfl_subtree_aabb(body)
	if aabb.size == Vector3.ZERO:
		return
	var centre: Vector3 = aabb.get_center()
	# Drop floor to y=0 (standing plant), centre x/z at the origin.
	body.position += Vector3(-centre.x, -aabb.position.y, -centre.z)


# =============================================================================
# MODE: bracketed — the canonical BRACKETED L-SYSTEM tree (trial v1)
#
# The genuine grammar (the load-bearing core):
#   Axiom:  "F"
#   Rules (one chosen by seed — three plant "species"):
#     0:  F -> FF+[+F-F-F]-[-F+F+F]   (Lindenmayer's bushy tree)
#     1:  F -> F[+F]F[-F][F]          (sparse upward shrub)
#     2:  F -> FF-[-F+F+F]+[+F-F-F]   (mirror of 0)
#   Generations: 3..5 scaled from `complexity`; string length CAPPED so it terminates.
# The sentence is walked by a typed 3D turtle: F draws a tapered segment (radius+length
# DECAY with bracket depth), +/- yaw, &/^ pitch, \ / roll, [ push, ] pop (and grow Codex
# canopy at a leaf-bracket tip). Angles seed-jittered for the hand-drawn Codex feel.
# =============================================================================

const _BRK_BASE_ANGLE_DEG: float = 24.0
const _BRK_ANGLE_JITTER_DEG: float = 7.0
const _BRK_STEP_LENGTH: float = 0.30
const _BRK_START_RADIUS: float = 0.052
const _BRK_RADIUS_DECAY: float = 0.74
const _BRK_LENGTH_DECAY: float = 0.80
const _BRK_TUBE_SIDES: int = 7


## One frame of turtle state for the bracket stack (typed Array of these).
class BrkTurtle:
	var pos: Vector3
	var basis: Basis        # columns: x=right, y=up(heading), z=binormal
	var radius: float
	var length: float
	var depth: int


func _build_bracketed() -> void:
	var plant := Node3D.new()
	plant.name = "Bracketed"
	add_child(plant)

	# Materials (DNA-driven; the trial's woody/foliage/accent + the eye's dark iris).
	var mat_wood := _cfl_wood_mat(color_b)
	var mat_foliage := _cfl_foliage_mat(color_a)
	var mat_accent := _cfl_glow_mat(accent, 3.0, true)
	var mat_eye_dark := StandardMaterial3D.new()
	mat_eye_dark.albedo_color = Color(0.06, 0.05, 0.08)
	mat_eye_dark.roughness = 0.25
	mat_eye_dark.metallic = 0.1

	# 1) Expand the L-system (the genuine grammar core), capped so it terminates.
	var sentence: String = _brk_expand_lsystem()

	# 2) Interpret it with the 3D turtle (branches + canopy + leaves).
	_brk_interpret(sentence, plant, mat_wood, mat_foliage, mat_accent, mat_eye_dark)

	# 3) Thread-roots gripping the ground (their own tiny recursive bracketed walk).
	_brk_build_roots(plant, mat_wood)

	# 4) Centre + scale + drop to y=0, present to the +X/+Z camera with a gentle yaw.
	_cfl_settle(plant, maxf(sculpt_height, 0.4), maxf(sculpt_width, 0.2))
	plant.rotation_degrees = Vector3(0.0, -28.0, 0.0)


## Pick one of three production rules by seed (the "genome" → species), expand the axiom
## for the complexity-scaled generation count using the project's LSystem rewriter,
## guarding the sentence length so it always terminates.
func _brk_expand_lsystem() -> String:
	var generations: int = clampi(1 + complexity / 2, 3, 5)

	var rules: Array[String] = [
		"FF+[+F-F-F]-[-F+F+F]",   # 0 — Lindenmayer bushy tree
		"F[+F]F[-F][F]",          # 1 — sparse upward shrub
		"FF-[-F+F+F]+[+F-F-F]",   # 2 — mirror of 0
	]
	var pick: int = _rng.randi() % rules.size()
	var rule: String = rules[pick]

	var lsys := LSystem.new("F")
	lsys.add_rule("F", rule)

	# Expand generation by generation, but STOP early if the next rewrite would blow past
	# the cap — keeps memory bounded and guarantees termination.
	for _g: int in range(generations):
		var before: String = lsys.get_sentence()
		var f_in: int = before.count("F")
		var est: int = before.length() + f_in * (rule.length() - 1)
		if est > _BRK_STRING_CAP:
			break
		lsys.generate()

	var sentence: String = lsys.get_sentence()
	if sentence.length() > _BRK_STRING_CAP:
		sentence = sentence.substr(0, _BRK_STRING_CAP)
	return sentence


## Walk the sentence with a 3D turtle. Each run of consecutive 'F' draws is accumulated
## into a single multi_tube path (cheaper, smoother joints), flushed at any turn/push/pop.
## Canopy is grown at leaf-bracket tips.
func _brk_interpret(sentence: String, parent: Node3D, mat_wood: StandardMaterial3D,
		mat_foliage: StandardMaterial3D, mat_accent: StandardMaterial3D,
		mat_eye_dark: StandardMaterial3D) -> void:
	var base_angle: float = deg_to_rad(_BRK_BASE_ANGLE_DEG)

	# Initial turtle frame: heading is the UP column (basis.y) so the tree grows skyward;
	# yaw/pitch rotate the heading about OTHER axes (z / x) so turns splay the heading.
	var st := BrkTurtle.new()
	st.pos = Vector3.ZERO
	st.basis = Basis(Vector3.RIGHT, Vector3.UP, Vector3.BACK)
	st.radius = _BRK_START_RADIUS
	st.length = _BRK_STEP_LENGTH
	st.depth = 0

	var stack: Array[BrkTurtle] = []

	var path: Array[Vector3] = [st.pos]
	var radii: Array[float] = [st.radius]
	var drew_in_branch: bool = false

	for ci: int in range(sentence.length()):
		var ch: String = sentence[ci]
		match ch:
			"F":
				var heading: Vector3 = st.basis.y
				st.pos = st.pos + heading * st.length
				path.append(st.pos)
				radii.append(st.radius)
				drew_in_branch = true
			"+":
				_brk_flush_branch(parent, path, radii, mat_wood, mat_foliage)
				st.basis = _brk_turn(st.basis, st.basis.z, _brk_jittered(base_angle))
				path = [st.pos]; radii = [st.radius]
			"-":
				_brk_flush_branch(parent, path, radii, mat_wood, mat_foliage)
				st.basis = _brk_turn(st.basis, st.basis.z, -_brk_jittered(base_angle))
				path = [st.pos]; radii = [st.radius]
			"&":
				_brk_flush_branch(parent, path, radii, mat_wood, mat_foliage)
				st.basis = _brk_turn(st.basis, st.basis.x, _brk_jittered(base_angle))
				path = [st.pos]; radii = [st.radius]
			"^":
				_brk_flush_branch(parent, path, radii, mat_wood, mat_foliage)
				st.basis = _brk_turn(st.basis, st.basis.x, -_brk_jittered(base_angle))
				path = [st.pos]; radii = [st.radius]
			"/":
				_brk_flush_branch(parent, path, radii, mat_wood, mat_foliage)
				st.basis = _brk_turn(st.basis, st.basis.y, _brk_jittered(base_angle))
				path = [st.pos]; radii = [st.radius]
			"\\":
				_brk_flush_branch(parent, path, radii, mat_wood, mat_foliage)
				st.basis = _brk_turn(st.basis, st.basis.y, -_brk_jittered(base_angle))
				path = [st.pos]; radii = [st.radius]
			"[":
				_brk_flush_branch(parent, path, radii, mat_wood, mat_foliage)
				var saved := BrkTurtle.new()
				saved.pos = st.pos
				saved.basis = st.basis
				saved.radius = st.radius
				saved.length = st.length
				saved.depth = st.depth
				stack.append(saved)
				st.depth += 1
				st.radius = maxf(st.radius * _BRK_RADIUS_DECAY, 0.006)
				st.length = st.length * _BRK_LENGTH_DECAY
				path = [st.pos]; radii = [st.radius]
				drew_in_branch = false
			"]":
				_brk_flush_branch(parent, path, radii, mat_wood, mat_foliage)
				if drew_in_branch:
					_brk_grow_canopy(parent, st.pos, st.basis.y, st.radius, st.depth,
						mat_wood, mat_foliage, mat_accent, mat_eye_dark)
				if stack.size() > 0:
					var popped: BrkTurtle = stack.pop_back()
					st.pos = popped.pos
					st.basis = popped.basis
					st.radius = popped.radius
					st.length = popped.length
					st.depth = popped.depth
				path = [st.pos]; radii = [st.radius]
				drew_in_branch = true

	# Flush whatever trunk remains, and crown the very apex.
	_brk_flush_branch(parent, path, radii, mat_wood, mat_foliage)
	_brk_grow_canopy(parent, st.pos, st.basis.y, st.radius, st.depth,
		mat_wood, mat_foliage, mat_accent, mat_eye_dark)


## Jitter an angle by a seeded +/- wobble for the hand-drawn Codex feel.
func _brk_jittered(angle: float) -> float:
	return angle + deg_to_rad(_rng.randf_range(-_BRK_ANGLE_JITTER_DEG, _BRK_ANGLE_JITTER_DEG))


## Rotate a turtle basis about one of its own columns; re-orthonormalise to keep the frame
## clean across many jittered turns.
func _brk_turn(b: Basis, axis: Vector3, angle: float) -> Basis:
	return (Basis(axis.normalized(), angle) * b).orthonormalized()


## Flush an accumulated branch path into a single tapered multi_tube mesh, scattering the
## occasional leaf along thinner mid/outer branches (never the trunk).
func _brk_flush_branch(parent: Node3D, path: Array[Vector3], radii: Array[float],
		mat_wood: StandardMaterial3D, mat_foliage: StandardMaterial3D) -> void:
	if path.size() < 2:
		return
	var mesh: Mesh = MorphoPrimitive.multi_tube(path, radii, _BRK_TUBE_SIDES)
	if mesh == null:
		return
	_cfl_add_mesh(parent, mesh, mat_wood, Transform3D.IDENTITY, "Branch")
	if radii.size() > 0 and (radii[0] as float) < _BRK_START_RADIUS * 0.6:
		if _rng.randf() < 0.18:
			_brk_scatter_leaves(parent, path, mat_foliage)


## Grow one of four surreal Codex canopy forms at a branch tip, chosen by seed:
## broccoli/mushroom-cloud dome cluster, glowing fruit, a single eye, or a leaf tuft.
func _brk_grow_canopy(parent: Node3D, tip: Vector3, heading: Vector3, radius: float,
		depth: int, mat_wood: StandardMaterial3D, mat_foliage: StandardMaterial3D,
		mat_accent: StandardMaterial3D, mat_eye_dark: StandardMaterial3D) -> void:
	var basis: Basis = _cfl_basis_from_up(heading)
	var scale_by_depth: float = lerpf(1.0, 0.6, clampf(float(depth) / 5.0, 0.0, 1.0))
	# Weighted mix: the broccoli/mushroom-cloud dome (the Codex-botany signature) dominates;
	# leaf tufts keep the crown green; fruit + the surreal EYE are rare striking accents.
	var r: float = _rng.randf()
	if r < 0.46:
		_brk_canopy_broccoli(parent, tip, basis, radius, scale_by_depth, mat_wood, mat_foliage)
	elif r < 0.76:
		_brk_canopy_tuft(parent, tip, basis, radius, scale_by_depth, mat_foliage, mat_accent)
	elif r < 0.91:
		_brk_canopy_fruit(parent, tip, basis, radius, scale_by_depth, mat_wood, mat_foliage, mat_accent)
	else:
		_brk_canopy_eye(parent, tip, basis, radius, scale_by_depth, mat_accent, mat_eye_dark)


## BROCCOLI / MUSHROOM-CLOUD — a clustered crown of small foliage domes around the tip,
## each a revolution dome, plus a woody pedicel collar under the crown.
func _brk_canopy_broccoli(parent: Node3D, tip: Vector3, basis: Basis, radius: float,
		s: float, mat_wood: StandardMaterial3D, mat_foliage: StandardMaterial3D) -> void:
	var crown_r: float = (0.10 + radius * 1.6) * s
	_brk_add_dome(parent, tip + basis.y * crown_r * 0.3, basis, crown_r, mat_foliage)
	var florets: int = 5 + (_rng.randi() % 4)
	for i: int in range(florets):
		var ang: float = TAU * float(i) / float(florets) + _rng.randf_range(-0.25, 0.25)
		var out_r: float = crown_r * _rng.randf_range(0.55, 0.85)
		var local: Vector3 = (basis.x * cos(ang) + basis.z * sin(ang)) * out_r \
			+ basis.y * crown_r * _rng.randf_range(0.1, 0.6)
		var floret_r: float = crown_r * _rng.randf_range(0.4, 0.62)
		_brk_add_dome(parent, tip + local, basis, floret_r, mat_foliage)
	_brk_add_sphere(parent, tip, radius * 1.4, mat_wood, basis, Vector3(1.0, 0.7, 1.0))


## GLOWING FRUIT — a hanging accent orb on a short woody stalk, with a calyx.
func _brk_canopy_fruit(parent: Node3D, tip: Vector3, basis: Basis, radius: float, s: float,
		mat_wood: StandardMaterial3D, mat_foliage: StandardMaterial3D,
		mat_accent: StandardMaterial3D) -> void:
	var fruit_r: float = (0.06 + radius * 1.2) * s
	var droop: Vector3 = (basis.y * 0.4 - basis.x * 0.2).normalized()
	var stalk_end: Vector3 = tip + droop * fruit_r * 2.4
	var stalk: Mesh = MorphoPrimitive.tube(tip, stalk_end, radius * 0.7, radius * 0.5, 6)
	_cfl_add_mesh(parent, stalk, mat_wood, Transform3D.IDENTITY, "FruitStalk")
	var teardrop: Array[Vector2] = [
		Vector2(0.0, -fruit_r * 1.15),
		Vector2(fruit_r * 0.55, -fruit_r * 0.7),
		Vector2(fruit_r * 0.98, -fruit_r * 0.1),
		Vector2(fruit_r * 0.92, fruit_r * 0.55),
		Vector2(fruit_r * 0.42, fruit_r * 0.95),
		Vector2(0.0, fruit_r * 1.05)]
	var fruit_mesh: Mesh = MorphoPrimitive.revolution(teardrop, 16)
	var fbasis: Basis = _cfl_basis_from_up(droop)
	_cfl_add_mesh(parent, fruit_mesh, mat_accent, Transform3D(fbasis, stalk_end), "Fruit")
	_brk_add_dome(parent, stalk_end, fbasis, fruit_r * 0.5, mat_foliage)


## SINGLE EYE — a Codex eye-fruit: pale sclera ball, dark iris disc, glowing accent pupil.
## Stares roughly along the branch heading.
func _brk_canopy_eye(parent: Node3D, tip: Vector3, basis: Basis, radius: float, s: float,
		mat_accent: StandardMaterial3D, mat_eye_dark: StandardMaterial3D) -> void:
	var eye_r: float = (0.07 + radius * 1.3) * s
	var gaze: Vector3 = basis.y
	var centre: Vector3 = tip + gaze * eye_r * 0.6
	var sclera := StandardMaterial3D.new()
	sclera.albedo_color = Color(0.86, 0.88, 0.82)
	sclera.roughness = 0.45
	_cfl_add_mesh(parent, MorphoPrimitive.sphere(eye_r, 16, 10), sclera,
		Transform3D(basis, centre), "EyeSclera")
	var iris_pos: Vector3 = centre + gaze * eye_r * 0.82
	var ibasis: Basis = _cfl_basis_from_up(gaze)
	_brk_add_sphere(parent, iris_pos, eye_r * 0.5, mat_eye_dark, ibasis, Vector3(1.0, 0.35, 1.0))
	_brk_add_sphere(parent, iris_pos + gaze * eye_r * 0.10, eye_r * 0.22, mat_accent,
		ibasis, Vector3(1.0, 0.5, 1.0))


## TUFT — a spray of thin foliage spikes (bezier_sweep ribbons) fanning up.
func _brk_canopy_tuft(parent: Node3D, tip: Vector3, basis: Basis, radius: float, s: float,
		mat_foliage: StandardMaterial3D, mat_accent: StandardMaterial3D) -> void:
	var spikes: int = 5 + (_rng.randi() % 4)
	var length: float = (0.14 + radius * 2.0) * s
	for i: int in range(spikes):
		var ang: float = TAU * float(i) / float(spikes) + _rng.randf_range(-0.3, 0.3)
		var lean: Vector3 = ((basis.x * cos(ang) + basis.z * sin(ang)) * 0.5 + basis.y).normalized()
		var tipward: Vector3 = tip + lean * length
		var mid: Vector3 = tip + (basis.y + lean) * 0.5 * length * 0.6
		var ctrl: Array = [tip, mid, tipward - lean * length * 0.2, tipward]
		var cross: Array = _brk_leaf_cross(radius * 0.6 + 0.004)
		var twist: float = _rng.randf_range(-30.0, 30.0)
		var blade: Mesh = MorphoPrimitive.bezier_sweep(ctrl, cross, 6, twist)
		_cfl_add_mesh(parent, blade, mat_foliage, Transform3D.IDENTITY, "TuftBlade")
	_brk_add_sphere(parent, tip + basis.y * length * 0.2, radius * 0.9, mat_accent,
		basis, Vector3.ONE)


## Scatter a couple of leaf blades from points along a branch path.
func _brk_scatter_leaves(parent: Node3D, path: Array[Vector3], mat_foliage: StandardMaterial3D) -> void:
	if path.size() < 2:
		return
	var n: int = 1 + (_rng.randi() % 2)
	for _i: int in range(n):
		var idx: int = _rng.randi_range(0, path.size() - 2)
		var a: Vector3 = path[idx]
		var b: Vector3 = path[idx + 1]
		var attach: Vector3 = a.lerp(b, _rng.randf())
		var heading: Vector3 = (b - a).normalized()
		var basis: Basis = _cfl_basis_from_up(heading)
		var side_ang: float = _rng.randf_range(0.0, TAU)
		var out_dir: Vector3 = (basis.x * cos(side_ang) + basis.z * sin(side_ang))
		var leaf_len: float = _rng.randf_range(0.06, 0.11)
		var dir: Vector3 = (out_dir * 1.2 + basis.y * 0.6).normalized()
		var leaf_tip: Vector3 = attach + dir * leaf_len
		var mid: Vector3 = attach + dir * leaf_len * 0.45 + basis.y * leaf_len * 0.15
		var ctrl: Array = [attach, mid, leaf_tip - dir * leaf_len * 0.2, leaf_tip]
		var cross: Array = _brk_leaf_cross(leaf_len * 0.28)
		var blade: Mesh = MorphoPrimitive.bezier_sweep(ctrl, cross, 6, 0.0)
		_cfl_add_mesh(parent, blade, mat_foliage, Transform3D.IDENTITY, "Leaf")


## A flattened lens cross-section for leaf / tuft ribbons (wide, thin).
func _brk_leaf_cross(half_width: float) -> Array:
	var w: float = half_width
	var t: float = half_width * 0.18
	return [
		Vector2(-w, 0.0), Vector2(-w * 0.5, t), Vector2(0.0, t * 1.1), Vector2(w * 0.5, t),
		Vector2(w, 0.0), Vector2(w * 0.5, -t), Vector2(0.0, -t * 1.1), Vector2(-w * 0.5, -t)]


## A few thin recursive roots branching downward and outward, gripping the ground. Each
## root is its own tiny recursive bracketed walk so the roots echo the canopy grammar.
func _brk_build_roots(parent: Node3D, mat_wood: StandardMaterial3D) -> void:
	var primaries: int = 4 + (_rng.randi() % 2)
	for i: int in range(primaries):
		var ang: float = TAU * float(i) / float(primaries) + _rng.randf_range(-0.3, 0.3)
		var out_dir: Vector3 = Vector3(cos(ang), 0.0, sin(ang))
		var dir: Vector3 = (out_dir * 0.65 - Vector3.UP).normalized()
		_brk_grow_root(parent, Vector3(0.0, 0.02, 0.0), dir, _BRK_START_RADIUS * 0.6, 3, mat_wood)


## Recursively grow one root: draw a curved segment, then fork into 1-2 thinner children
## with jittered downward headings. Terminates by depth.
func _brk_grow_root(parent: Node3D, start: Vector3, dir: Vector3, radius: float,
		depth: int, mat_wood: StandardMaterial3D) -> void:
	if depth <= 0 or radius < 0.004:
		return
	var seg_len: float = lerpf(0.22, 0.12, clampf(float(3 - depth) / 3.0, 0.0, 1.0))
	var mid: Vector3 = start + dir * seg_len * 0.5 + Vector3.DOWN * seg_len * 0.12
	var end_pt: Vector3 = start + dir * seg_len + Vector3.DOWN * seg_len * 0.20
	var path: Array[Vector3] = [start, mid, end_pt]
	var radii: Array[float] = [radius, radius * 0.78, radius * 0.55]
	_cfl_add_mesh(parent, MorphoPrimitive.multi_tube(path, radii, 5), mat_wood,
		Transform3D.IDENTITY, "Root")
	var children: int = 1 + (_rng.randi() % 2)
	for _c: int in range(children):
		var yaw: float = deg_to_rad(_rng.randf_range(-40.0, 40.0))
		var pitch: float = deg_to_rad(_rng.randf_range(5.0, 35.0))
		var b: Basis = _cfl_basis_from_up(dir)
		var child_dir: Vector3 = (Basis(b.y, yaw) * (Basis(b.x, pitch) * dir)).normalized()
		child_dir = (child_dir + Vector3.DOWN * 0.4).normalized()
		_brk_grow_root(parent, end_pt, child_dir, radius * 0.62, depth - 1, mat_wood)


## A foliage dome (quarter-revolution) sitting on the surface, oriented by basis.
func _brk_add_dome(parent: Node3D, centre: Vector3, basis: Basis, r: float,
		mat: StandardMaterial3D) -> void:
	var profile: Array[Vector2] = []
	var rings: int = 5
	for i: int in range(rings + 1):
		var t: float = float(i) / float(rings)
		var ph: float = t * (PI * 0.5)
		profile.append(Vector2(cos(ph) * r, sin(ph) * r))
	_cfl_add_mesh(parent, MorphoPrimitive.revolution(profile, 12), mat,
		Transform3D(basis, centre), "Dome")


## A (optionally squashed) sphere at a point, oriented by basis.
func _brk_add_sphere(parent: Node3D, centre: Vector3, r: float, mat: StandardMaterial3D,
		basis: Basis, scale: Vector3) -> void:
	_cfl_add_mesh(parent, MorphoPrimitive.sphere(r, 12, 8), mat,
		Transform3D(basis.scaled(scale), centre), "Bud")


# =============================================================================
# MODE: helix — a PARAMETRIC L-system DNA-ladder double helix (trial v2)
#
# The genuine grammar (parametric / helical turtle):
#   strand_point(t, phase) = ( R*envelope(t)*cos(theta+phase), t*HEIGHT,
#                              R*envelope(t)*sin(theta+phase) )
#   with theta = TAU * TURNS * t — a turtle climbing up with CONSTANT ROLL.
# Two strands phase-offset by 180deg sweep tubes along these helices; RUNGS span A->B at
# regular t (base pairs); LEAVES spiral up by the golden angle (phyllotaxis); the head is a
# layered artichoke of overlapping scale-caps (each row golden-angle offset) with a glowing
# core peeking through. complexity scales turns / rungs / leaves / head scale-rows.
# =============================================================================

const _HLX_STEM_HEIGHT: float = 2.05
const _HLX_TURNS: float = 2.7
const _HLX_RADIUS: float = 0.275
const _HLX_SAMPLES: int = 168
const _HLX_STRAND_R_BASE: float = 0.050
const _HLX_STRAND_R_TIP: float = 0.030
const _HLX_STRAND_SIDES: int = 8
const _HLX_RUNG_COUNT: int = 14
const _HLX_RUNG_RADIUS: float = 0.0215
const _HLX_RUNG_SIDES: int = 6
const _HLX_GOLDEN_DEG: float = 137.50776
const _HLX_LEAF_COUNT: int = 6
const _HLX_HEAD_ROWS: int = 6
const _HLX_HEAD_BASE_RADIUS: float = 0.40
const _HLX_HEAD_RISE: float = 0.62


func _build_helix() -> void:
	var plant := Node3D.new()
	plant.name = "Helix"
	add_child(plant)

	# complexity in [3..12+] → a 0..1 norm scaling turns/rungs/leaves/rows (native ~0.7).
	var cnorm: float = clampf(float(complexity - 3) / 6.0, 0.0, 1.0)
	var turns: float = _HLX_TURNS * lerpf(0.85, 1.15, cnorm)

	# Materials: stem (strands+rungs), leaf (leaves+scales), core (glow).
	var mat_stem := _cfl_wood_mat(color_b)
	var mat_leaf := _cfl_foliage_mat(color_a)
	var mat_core := _cfl_glow_mat(accent, 3.0, true)

	_hlx_build_root_bulb(plant, mat_stem)
	_hlx_build_strand(plant, 0.0, turns, mat_stem)        # strand A
	_hlx_build_strand(plant, PI, turns, mat_stem)         # strand B (180deg offset)
	_hlx_build_rungs(plant, turns, cnorm, mat_stem)
	_hlx_build_collar(plant, turns, mat_stem)
	_hlx_build_leaves(plant, turns, cnorm, mat_leaf)
	_hlx_build_head(plant, cnorm, mat_leaf, mat_core)

	_cfl_settle(plant, maxf(sculpt_height, 0.4), maxf(sculpt_width, 0.2))
	plant.rotation_degrees = Vector3(0.0, -22.0, 0.0)


## A single strand point at climb fraction t in [0,1], with angular phase offset.
## theta = TAU*turns*t is the turtle's accumulated roll; y rises linearly; a radius
## envelope gathers both strands inward near the head.
func _hlx_strand_point(t: float, phase: float, turns: float) -> Vector3:
	var theta: float = TAU * turns * t + phase
	var r: float = _HLX_RADIUS * _hlx_radius_envelope(t)
	return Vector3(cos(theta) * r, t * _HLX_STEM_HEIGHT, sin(theta) * r)


func _hlx_radius_envelope(t: float) -> float:
	var root_in: float = smoothstep(0.0, 0.10, t)
	var head_in: float = 1.0 - 0.42 * smoothstep(0.78, 1.0, t)
	return lerpf(0.55, 1.0, root_in) * head_in


func _hlx_strand_radius(t: float) -> float:
	var base: float = lerpf(_HLX_STRAND_R_BASE, _HLX_STRAND_R_TIP, smoothstep(0.0, 1.0, t))
	var wobble: float = 1.0 + 0.10 * sin(t * PI * 7.0)
	return base * wobble


## Sweep one helical strand tube along the parametric path with phase `phase`.
func _hlx_build_strand(parent: Node3D, phase: float, turns: float, mat: StandardMaterial3D) -> void:
	var positions: Array[Vector3] = []
	var radii: Array[float] = []
	for i: int in range(_HLX_SAMPLES):
		var t: float = float(i) / float(_HLX_SAMPLES - 1)
		positions.append(_hlx_strand_point(t, phase, turns))
		radii.append(_hlx_strand_radius(t))
	_cfl_add_mesh(parent, MorphoPrimitive.multi_tube(positions, radii, _HLX_STRAND_SIDES),
		mat, Transform3D.IDENTITY, "Strand")


## Connect strand A to strand B at regular climb fractions (base pairs). Each rung is a
## short multi_tube swept directly between the two strand points with a slight central sag.
func _hlx_build_rungs(parent: Node3D, turns: float, cnorm: float, mat: StandardMaterial3D) -> void:
	var count: int = maxi(int(round(_HLX_RUNG_COUNT * lerpf(0.8, 1.2, cnorm))), 4)
	for i: int in range(count):
		var t: float = lerpf(0.11, 0.80, float(i) / float(count - 1))
		var a: Vector3 = _hlx_strand_point(t, 0.0, turns)
		var b: Vector3 = _hlx_strand_point(t, PI, turns)
		var mid: Vector3 = (a + b) * 0.5
		mid.y -= 0.012
		var positions: Array[Vector3] = [a, mid, b]
		var rr: float = _HLX_RUNG_RADIUS * _rng.randf_range(0.92, 1.06)
		var radii: Array[float] = [rr * 0.85, rr, rr * 0.85]
		_cfl_add_mesh(parent, MorphoPrimitive.multi_tube(positions, radii, _HLX_RUNG_SIDES),
			mat, Transform3D.IDENTITY, "Rung")


## Gather both strand tops into a short merged neck under the head so the bulb seats ON the
## stem, plus two shoulder tubes pulling each strand tip inward.
func _hlx_build_collar(parent: Node3D, turns: float, mat: StandardMaterial3D) -> void:
	var stem_top := Vector3(0.0, _HLX_STEM_HEIGHT, 0.0)
	var a_top: Vector3 = _hlx_strand_point(1.0, 0.0, turns)
	var b_top: Vector3 = _hlx_strand_point(1.0, PI, turns)
	var gather: Vector3 = (a_top + b_top) * 0.5
	var neck_top: Vector3 = stem_top + Vector3(0.0, 0.06, 0.0)

	var neck_pos: Array[Vector3] = [gather, gather.lerp(neck_top, 0.5), neck_top]
	var neck_radii: Array[float] = [
		_HLX_STRAND_R_TIP * 1.5, _HLX_STRAND_R_TIP * 2.2, _HLX_HEAD_BASE_RADIUS * 0.34]
	_cfl_add_mesh(parent, MorphoPrimitive.multi_tube(neck_pos, neck_radii, _HLX_STRAND_SIDES),
		mat, Transform3D.IDENTITY, "Neck")

	for tip: Vector3 in [a_top, b_top]:
		var sh_pos: Array[Vector3] = [tip, tip.lerp(gather, 0.6), gather]
		var sh_rad: Array[float] = [
			_HLX_STRAND_R_TIP, _HLX_STRAND_R_TIP * 1.2, _HLX_STRAND_R_TIP * 1.5]
		_cfl_add_mesh(parent, MorphoPrimitive.multi_tube(sh_pos, sh_rad, _HLX_STRAND_SIDES),
			mat, Transform3D.IDENTITY, "Shoulder")


## A few blade leaves spiral up the stem at golden-angle increments (phyllotaxis). Each is
## a tapered bezier ribbon arcing outward and drooping; the twist is baked before the sweep.
func _hlx_build_leaves(parent: Node3D, turns: float, cnorm: float, mat: StandardMaterial3D) -> void:
	var count: int = maxi(int(round(_HLX_LEAF_COUNT * lerpf(0.8, 1.2, cnorm))), 3)
	var blade_cs: Array[Vector2] = [
		Vector2(0.0, 0.012), Vector2(0.055, 0.004), Vector2(0.072, 0.0),
		Vector2(0.055, -0.004), Vector2(0.0, -0.012), Vector2(-0.055, -0.004),
		Vector2(-0.072, 0.0), Vector2(-0.055, 0.004)]
	for i: int in range(count):
		var t: float = lerpf(0.18, 0.74, float(i) / float(count - 1))
		var ang: float = deg_to_rad(_HLX_GOLDEN_DEG * float(i)) + 0.6
		var outward := Vector3(cos(ang), 0.0, sin(ang))
		var attach_r: float = _HLX_RADIUS * _hlx_radius_envelope(t) + _HLX_STRAND_R_BASE
		var base := Vector3(outward.x * attach_r, t * _HLX_STEM_HEIGHT, outward.z * attach_r)

		var leaf_len: float = lerpf(0.46, 0.30, t) * _rng.randf_range(0.92, 1.08)
		var lift: float = leaf_len * 0.55
		var p0: Vector3 = base
		var p1: Vector3 = base + outward * (leaf_len * 0.32) + Vector3(0.0, lift, 0.0)
		var p2: Vector3 = base + outward * (leaf_len * 0.78) + Vector3(0.0, lift * 0.85, 0.0)
		var p3: Vector3 = base + outward * leaf_len + Vector3(0.0, lift * 0.25, 0.0)
		var control: Array = [p0, p1, p2, p3]
		var twist: float = _rng.randf_range(-25.0, 25.0)
		var mesh: Mesh = MorphoPrimitive.bezier_sweep(control, blade_cs, 14, twist)
		if mesh == null:
			continue
		var tapered: ArrayMesh = MorphoModifier.taper(mesh, (p3 - p0).normalized(),
			func(tt: float) -> float: return lerpf(0.55, 0.06, tt))
		var final_mesh: Mesh = tapered if tapered != null else mesh
		_cfl_add_mesh(parent, final_mesh, mat, Transform3D.IDENTITY, "Leaf")


## A layered artichoke/pinecone bulb at the climb top: HEAD_ROWS rings of overlapping
## scale-caps (each row golden-angle offset so scales cover the seams below), a glowing core
## peeking through the gaps, and a crowning bud.
func _hlx_build_head(parent: Node3D, cnorm: float, mat_leaf: StandardMaterial3D,
		mat_core: StandardMaterial3D) -> void:
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0.0, _HLX_STEM_HEIGHT, 0.0) - Vector3(0.0, 0.07, 0.0)
	parent.add_child(head)

	var rows: int = maxi(int(round(_HLX_HEAD_ROWS * lerpf(0.8, 1.2, cnorm))), 4)

	var core_mesh: Mesh = MorphoPrimitive.sphere(_HLX_HEAD_BASE_RADIUS * 0.40, 14, 8)
	_cfl_add_mesh(head, core_mesh, mat_core,
		Transform3D(Basis().scaled(Vector3(1.0, 1.35, 1.0)),
			Vector3(0.0, _HLX_HEAD_RISE * 0.50, 0.0)), "Core")

	var scale_profile: Array[Vector2] = [
		Vector2(0.0, 0.0), Vector2(0.26, 0.018), Vector2(0.54, 0.034),
		Vector2(0.78, 0.030), Vector2(0.93, 0.006), Vector2(1.0, -0.018)]
	var unit_scale_mesh: Mesh = MorphoPrimitive.revolution(scale_profile, 9)

	var angle_offset: float = 0.0
	for row: int in range(rows):
		var rf: float = float(row) / float(rows - 1)
		var ring_radius: float = _HLX_HEAD_BASE_RADIUS * lerpf(1.0, 0.22, _hlx_ease_out(rf))
		var ring_y: float = lerpf(0.02, _HLX_HEAD_RISE * 0.96, _hlx_ease_in(rf))
		var per_row: int = maxi(int(round(lerpf(12.0, 5.0, rf))), 4)
		var cap_radius: float = lerpf(0.215, 0.10, rf)
		var splay_deg: float = lerpf(76.0, 34.0, rf)

		for s: int in range(per_row):
			var a: float = TAU * float(s) / float(per_row) + angle_offset
			var outward := Vector3(cos(a), 0.0, sin(a))
			var seat: Vector3 = outward * ring_radius + Vector3(0.0, ring_y, 0.0)
			var splay: float = deg_to_rad(splay_deg)
			var cap_up: Vector3 = (Vector3.UP * cos(splay) + outward * sin(splay)).normalized()
			var basis: Basis = _cfl_basis_from_up(cap_up)
			var cap_scale := Basis().scaled(Vector3(cap_radius, cap_radius * 0.85, cap_radius))
			_cfl_add_mesh(head, unit_scale_mesh, mat_leaf,
				Transform3D(basis * cap_scale, seat), "Scale")
		angle_offset += deg_to_rad(_HLX_GOLDEN_DEG)

	var bud_mesh: Mesh = MorphoPrimitive.sphere(_HLX_HEAD_BASE_RADIUS * 0.11, 10, 6)
	_cfl_add_mesh(head, bud_mesh, mat_core,
		Transform3D(Basis.IDENTITY, Vector3(0.0, _HLX_HEAD_RISE * 0.95, 0.0)), "Bud")


## A small bulb/onion at y=0 from which the two strands emerge, plus a few root tendrils.
func _hlx_build_root_bulb(parent: Node3D, mat: StandardMaterial3D) -> void:
	var bulb_profile: Array[Vector2] = [
		Vector2(0.0, -0.16), Vector2(0.10, -0.14), Vector2(0.18, -0.06),
		Vector2(0.205, 0.05), Vector2(0.17, 0.15), Vector2(0.10, 0.205), Vector2(0.0, 0.225)]
	_cfl_add_mesh(parent, MorphoPrimitive.revolution(bulb_profile, 18), mat,
		Transform3D(Basis.IDENTITY, Vector3(0.0, 0.12, 0.0)), "RootBulb")

	var tendrils: int = 5
	for i: int in range(tendrils):
		var a: float = TAU * float(i) / float(tendrils) + 0.35
		var outward := Vector3(cos(a), 0.0, sin(a))
		var t_len: float = _rng.randf_range(0.16, 0.26)
		var p0 := Vector3(outward.x * 0.06, 0.08, outward.z * 0.06)
		var p1: Vector3 = p0 + outward * (t_len * 0.5) + Vector3(0.0, -0.04, 0.0)
		var p2: Vector3 = p0 + outward * t_len + Vector3(0.0, -0.075, 0.0)
		var positions: Array[Vector3] = [p0, p1, p2]
		var radii: Array[float] = [0.030, 0.018, 0.006]
		_cfl_add_mesh(parent, MorphoPrimitive.multi_tube(positions, radii, 6), mat,
			Transform3D.IDENTITY, "Root")


func _hlx_ease_in(t: float) -> float:
	var c: float = clampf(t, 0.0, 1.0)
	return c * c


func _hlx_ease_out(t: float) -> float:
	var c: float = clampf(t, 0.0, 1.0)
	return 1.0 - (1.0 - c) * (1.0 - c)


# =============================================================================
# MODE: spacefill — a SPACE-FILLING (Koch) L-system frond (trial v3)
#
# The genuine grammar (string rewriting + turtle, swept):
#   Axiom "F", rule F -> F+F-F-F+F (the classic Koch quadric, 5x per generation),
#   GENERATIONS scaled from complexity, capped so the rewrite terminates. A 2D turtle
#   (+/- are 90deg turns) walks the sentence into a flat space-filling polyline; that
#   polyline is re-mapped BY ARC LENGTH onto a logarithmic-spiral fiddlehead (the Koch
#   crinkle preserved verbatim as a perpendicular ribbon displacement), then SWEPT as a
#   thin lacy ribbon along the coiled curve. Several fronds splay from a stem, each capped
#   with a glowing Codex bloom at its free curl-tip.
# =============================================================================

const _SPF_AXIOM: String = "F"
const _SPF_KOCH_RULE: String = "F+F-F-F+F"
const _SPF_TURN_DEG: float = 90.0
const _SPF_FROND_COUNT: int = 3
const _SPF_SPIRAL_TURNS: float = 2.05
const _SPF_SPIRAL_GROWTH: float = 0.62
const _SPF_CRINKLE_DEPTH: float = 0.20
const _SPF_RIBBON_WIDTH: float = 0.11
const _SPF_RIBBON_THICK: float = 0.010
const _SPF_SWEEP_SEGMENTS: int = 460
const _SPF_FROND_TILT_DEG: float = 18.0
const _SPF_BASE_RADIUS: float = 0.28
const _SPF_BASE_HEIGHT: float = 0.16
const _SPF_STEM_HEIGHT: float = 1.35
const _SPF_STEM_RADIUS: float = 0.045

# Codex palette tints for the spacefill bloom (color_a leaf, color_b stem, accent bud).
var _spf_color_stem: Color = Color(0.34, 0.52, 0.32)
var _spf_color_leaf: Color = Color(0.40, 0.62, 0.46)
var _spf_color_bud: Color = Color(0.95, 0.55, 0.75)


func _build_spacefill() -> void:
	var plant := Node3D.new()
	plant.name = "Spacefill"
	add_child(plant)

	# Map the DNA triad onto the trial's stem/leaf/bud roles.
	_spf_color_stem = color_b
	_spf_color_leaf = color_a
	_spf_color_bud = accent

	# Stem material carries a vertex-colour gradient (stem->leaf along the ribbon).
	var mat_stem := _cfl_foliage_mat(_spf_color_stem)
	mat_stem.vertex_color_use_as_albedo = true
	var mat_leaf := _cfl_foliage_mat(_spf_color_leaf)
	var mat_bud := _cfl_glow_mat(_spf_color_bud, 3.0, true)
	# Stem/base tubes use a plain wood-ish version of the stem colour (no vertex blend).
	var mat_stem_solid := _cfl_foliage_mat(_spf_color_stem)

	# 1. Generate the genuine L-system string once (shared by all fronds), capped.
	var sentence: String = _spf_expand_lsystem()
	var flat: Array[Vector2] = _spf_turtle_polyline(sentence)

	# 2. Base disc + stem at y=0.
	_spf_build_base(plant, mat_stem_solid)
	_spf_build_stem(plant, mat_stem_solid)

	# 3. Several fronds splay from the stem top — each coils the SAME Koch curve with a
	#    different phase + span, leans into the +X/+Z camera quadrant, sweeps a ribbon,
	#    and caps its free curl-tip with a glowing bloom.
	var cluster := Node3D.new()
	cluster.name = "Fronds"
	cluster.position = Vector3(0.0, _SPF_STEM_HEIGHT, 0.0)
	plant.add_child(cluster)

	var lean_centre: float = deg_to_rad(45.0)
	var lean_spread: float = deg_to_rad(78.0)
	# complexity adds fronds (native 3 at complexity 6).
	var frond_count: int = clampi(_SPF_FROND_COUNT + (complexity - 6) / 3, 3, 6)

	for fi: int in range(frond_count):
		var frac: float = float(fi) / maxf(frond_count - 1.0, 1.0)
		var lean_yaw: float = lean_centre + lerpf(-lean_spread * 0.5, lean_spread * 0.5, frac)
		var span: float = (1.0 + (0.06 * float(fi - 1))) + _rng.randf_range(-0.05, 0.05)
		var phase: float = TAU * frac + _rng.randf_range(-0.35, 0.35)

		var coiled: Array[Vector3] = _spf_coil_polyline(flat, span * 0.95, phase)
		if coiled.size() < 4:
			continue

		# Anchor the open OUTER end (wide base) at the frond origin so the coil curls away
		# from the stem, the tight curl + glowing bud held aloft (the fiddlehead).
		var anchor: Vector3 = coiled[coiled.size() - 1]
		for ci: int in range(coiled.size()):
			coiled[ci] = coiled[ci] - anchor

		var frond := Node3D.new()
		frond.name = "FrondGroup_%d" % fi
		var stand := Basis(Vector3.RIGHT, deg_to_rad(-90.0 + _SPF_FROND_TILT_DEG))
		var yaw := Basis(Vector3.UP, lean_yaw)
		frond.basis = yaw * stand
		var out_dir := Vector3(cos(lean_yaw), 0.0, sin(lean_yaw))
		frond.position = out_dir * 0.08
		cluster.add_child(frond)

		var ribbon: MeshInstance3D = _spf_sweep_ribbon(coiled, mat_stem)
		if ribbon != null:
			frond.add_child(ribbon)

		var tip: Vector3 = coiled[0]
		var nxt: Vector3 = coiled[mini(5, coiled.size() - 1)]
		var tan: Vector3 = (tip - nxt)
		if tan.length_squared() < 0.0001:
			tan = Vector3.UP
		var bloom_basis: Basis = _cfl_basis_from_up(tan.normalized())
		_spf_build_bloom(frond, tip, bloom_basis, 0.36 * span, mat_leaf, mat_bud)

	_cfl_settle(plant, maxf(sculpt_height, 0.4), maxf(sculpt_width, 0.2))


## Expand the axiom under the Koch rule for the complexity-scaled generation count, capped
## at _SPF_STRING_CAP so the rewrite always terminates. Returns the final String.
func _spf_expand_lsystem() -> String:
	var gens: int = clampi(complexity / 2, 3, 4)
	var lsys := LSystem.new(_SPF_AXIOM)
	lsys.add_rule("F", _SPF_KOCH_RULE)
	var current: String = _SPF_AXIOM
	for _g: int in range(gens):
		# Each F becomes 5 symbols; estimate growth before committing so it terminates.
		var f_count: int = current.count("F")
		if current.length() + f_count * 4 > _SPF_STRING_CAP:
			break
		lsys.generate()
		current = lsys.get_sentence()
	if current.length() > _SPF_STRING_CAP:
		current = current.substr(0, _SPF_STRING_CAP)
	return current


## Interpret an L-system string with a 2D turtle. 'F' steps forward one unit, '+'/'-' turn
## by _SPF_TURN_DEG. Returns the visited points as a flat polyline (Array[Vector2]).
func _spf_turtle_polyline(sentence: String) -> Array[Vector2]:
	var pts: Array[Vector2] = []
	var pos: Vector2 = Vector2.ZERO
	var heading: float = 0.0
	var turn: float = deg_to_rad(_SPF_TURN_DEG)
	pts.append(pos)
	for ci: int in range(sentence.length()):
		var ch: String = sentence[ci]
		match ch:
			"F":
				pos += Vector2(cos(heading), sin(heading))
				pts.append(pos)
			"+":
				heading += turn
			"-":
				heading -= turn
	return pts


## Coil the flat Koch polyline into a 3D fiddlehead frond. The recursion's SEQUENCE is
## preserved by walking the turtle path IN ORDER BY ARC LENGTH onto a logarithmic spiral;
## the Koch crinkle (each point's signed deviation from a wide-window baseline) rides as an
## in-plane normal displacement off the spiral spine, so the space-filling structure stays
## legible while the whole frond coils. Tip at index 0 (tight inner end).
func _spf_coil_polyline(flat: Array[Vector2], span: float, phase: float) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var n: int = flat.size()
	if n < 2:
		return out

	var cum: PackedFloat32Array = PackedFloat32Array()
	cum.resize(n)
	cum[0] = 0.0
	for i: int in range(1, n):
		cum[i] = cum[i - 1] + (flat[i] - flat[i - 1]).length()
	var total_len: float = maxf(cum[n - 1], 0.0001)

	var crink: PackedFloat32Array = PackedFloat32Array()
	crink.resize(n)
	var win: int = 16
	var max_crink: float = 0.0001
	for i: int in range(n):
		var a: int = maxi(i - win, 0)
		var b: int = mini(i + win, n - 1)
		var drift: Vector2 = flat[b] - flat[a]
		var dlen: float = drift.length()
		if dlen < 0.0001:
			crink[i] = 0.0
			continue
		var drift_dir: Vector2 = drift / dlen
		var centre: Vector2 = (flat[a] + flat[b]) * 0.5
		var rel: Vector2 = flat[i] - centre
		crink[i] = rel.x * drift_dir.y - rel.y * drift_dir.x
		max_crink = maxf(max_crink, absf(crink[i]))

	for i: int in range(n):
		var t: float = cum[i] / total_len                 # 0 = tip, 1 = base
		var ang: float = phase + (1.0 - t) * _SPF_SPIRAL_TURNS * TAU
		var r_norm: float = (exp(t * _SPF_SPIRAL_GROWTH * TAU) - 1.0) / (exp(_SPF_SPIRAL_GROWTH * TAU) - 1.0)
		var radius: float = lerpf(0.05, 1.0, r_norm) * span
		var radial := Vector2(cos(ang), sin(ang))
		var spine: Vector2 = radial * radius
		var amp: float = _SPF_CRINKLE_DEPTH * span * lerpf(0.5, 1.0, t)
		var wob: float = (crink[i] / max_crink) * amp
		var p2: Vector2 = spine + radial * wob
		var lift: float = span * 0.22 * sin((1.0 - t) * PI) * (0.35 + 0.65 * (1.0 - t))
		out.append(Vector3(p2.x, lift, p2.y))

	return out


## Sweep a thin ribbon along the baked coiled points using MorphoSweep.sweep, then bake a
## per-vertex stem->leaf->bud gradient so the recursion reads. All seeded/derived values
## are baked into locals BEFORE the path Callable so the closure captures plain floats.
func _spf_sweep_ribbon(points: Array[Vector3], mat: StandardMaterial3D) -> MeshInstance3D:
	var count: int = points.size()
	if count < 4:
		return null

	var baked: Array[Vector3] = points.duplicate()
	var last_idx: float = float(count - 1)

	var path_func: Callable = func(t: float) -> Vector3:
		var ft: float = clampf(t, 0.0, 1.0) * last_idx
		var i0: int = int(floor(ft))
		var i1: int = mini(i0 + 1, count - 1)
		var frac: float = ft - float(i0)
		return (baked[i0] as Vector3).lerp(baked[i1] as Vector3, frac)

	var profile: Array[Vector2] = MorphoSweep.profile_rectangle(_SPF_RIBBON_WIDTH * 2.0, _SPF_RIBBON_THICK)
	var rad_func: Callable = MorphoSweep.radius_taper(0.55, 1.0)

	var mesh: Mesh = MorphoSweep.sweep(profile, path_func, rad_func, 0.0, _SPF_SWEEP_SEGMENTS, false)
	if mesh == null:
		return null

	var gradient_mesh: ArrayMesh = _spf_apply_length_gradient(mesh)
	var mi := MeshInstance3D.new()
	mi.name = "Frond"
	mi.mesh = gradient_mesh
	mi.material_override = mat
	return mi


## Read the swept ArrayMesh back, write a per-vertex Color from UV.y (path t), return a new
## ArrayMesh carrying ARRAY_COLOR. Base (t=1) stem -> curl tip (t=0) leaf, heating to bud.
func _spf_apply_length_gradient(mesh: Mesh) -> ArrayMesh:
	var arrays: Array = mesh.surface_get_arrays(0)
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors: PackedColorArray = PackedColorArray()
	colors.resize(verts.size())
	for i: int in range(verts.size()):
		var t: float = clampf(uvs[i].y, 0.0, 1.0)
		var base_to_tip: float = 1.0 - t
		var c: Color = _spf_color_stem.lerp(_spf_color_leaf, clampf(base_to_tip / 0.7, 0.0, 1.0))
		if base_to_tip > 0.78:
			var k: float = (base_to_tip - 0.78) / 0.22
			c = c.lerp(_spf_color_bud, clampf(k * 0.75, 0.0, 1.0))
		colors[i] = c
	arrays[Mesh.ARRAY_COLOR] = colors
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out


## Build a small Codex bloom at world-space `tip_pos`, oriented by `basis`: a ring of
## revolution-swept petal blades (leaf accent) cupping a glowing bud core.
func _spf_build_bloom(parent: Node3D, tip_pos: Vector3, basis: Basis, scale: float,
		mat_leaf: StandardMaterial3D, mat_bud: StandardMaterial3D) -> void:
	var bloom := Node3D.new()
	bloom.name = "Bloom"
	bloom.transform = Transform3D(basis, tip_pos)
	parent.add_child(bloom)

	var petal_mesh: Mesh = _spf_build_petal_blade(scale)
	var petal_n: int = 6 + (_rng.randi() % 3)
	for pi: int in range(petal_n):
		var ang: float = TAU * float(pi) / float(petal_n) + _rng.randf_range(-0.10, 0.10)
		var lean: float = deg_to_rad(_rng.randf_range(46.0, 62.0))
		var around := Basis(Vector3.UP, ang)
		var tilt := Basis(Vector3.RIGHT, lean)
		var local := around * tilt
		_cfl_add_mesh(bloom, petal_mesh, mat_leaf,
			Transform3D(local, around * Vector3(0.06 * scale, 0.0, 0.0)), "Petal")

	var bud_mesh: Mesh = MorphoPrimitive.sphere(0.26 * scale, 14, 10)
	var squash := Basis().scaled(Vector3(1.0, 1.2, 1.0))
	_cfl_add_mesh(bloom, bud_mesh, mat_bud,
		Transform3D(squash, Vector3(0.0, 0.20 * scale, 0.0)), "Bud")


## Build one petal blade: a flat lens cross-section swept along an outward-and-up curling
## arc with a radius taper to a point. `scale` is baked into the Callables before sweep.
func _spf_build_petal_blade(scale: float) -> Mesh:
	var sc: float = scale
	var path_func: Callable = func(t: float) -> Vector3:
		var u: float = clampf(t, 0.0, 1.0)
		var x: float = sin(u * PI * 0.55) * 0.16 * sc
		var y: float = u * 0.58 * sc
		var z: float = (1.0 - cos(u * PI * 0.7)) * 0.10 * sc
		return Vector3(x, y, z)
	var cross: Array[Vector2] = [
		Vector2(-0.16 * sc, 0.0), Vector2(-0.08 * sc, 0.010 * sc), Vector2(0.0, 0.016 * sc),
		Vector2(0.08 * sc, 0.010 * sc), Vector2(0.16 * sc, 0.0), Vector2(0.08 * sc, -0.010 * sc),
		Vector2(0.0, -0.016 * sc), Vector2(-0.08 * sc, -0.010 * sc)]
	var rad_func: Callable = func(t: float) -> float:
		return lerpf(1.0, 0.12, clampf(t, 0.0, 1.0))
	return MorphoSweep.sweep(cross, path_func, rad_func, 0.0, 12, false)


## A low revolution disc seat the stem rises from.
func _spf_build_base(parent: Node3D, mat: StandardMaterial3D) -> void:
	var profile: Array[Vector2] = [
		Vector2(0.0, 0.0), Vector2(_SPF_BASE_RADIUS * 0.96, 0.0),
		Vector2(_SPF_BASE_RADIUS, _SPF_BASE_HEIGHT * 0.35),
		Vector2(_SPF_BASE_RADIUS * 0.72, _SPF_BASE_HEIGHT * 0.85),
		Vector2(_SPF_BASE_RADIUS * 0.40, _SPF_BASE_HEIGHT), Vector2(0.0, _SPF_BASE_HEIGHT)]
	_cfl_add_mesh(parent, MorphoPrimitive.revolution(profile, 28), mat,
		Transform3D.IDENTITY, "Base")


## A tapered tube stem from the base up to the frond cluster.
func _spf_build_stem(parent: Node3D, mat: StandardMaterial3D) -> void:
	var mesh: Mesh = MorphoPrimitive.tube(
		Vector3(0.0, _SPF_BASE_HEIGHT * 0.6, 0.0), Vector3(0.0, _SPF_STEM_HEIGHT, 0.0),
		_SPF_STEM_RADIUS * 1.4, _SPF_STEM_RADIUS, 10)
	_cfl_add_mesh(parent, mesh, mat, Transform3D.IDENTITY, "Stem")


# =============================================================================
# MODE: inflorescence — a recursive PHYLLOTACTIC L-system (trial v4)
#
# The genuine grammar (recursive branching + phyllotaxis):
#   S(d) -> I L I L … I  [ \φ &θ S(d-1) ] [ \2φ &θ S(d-1) ] … *(d)
#   where I = internode (forward+draw), L = leaf, \φ = roll by golden angle (137.507°),
#   &θ = pitch outward, [..] = push/branch/pop, *(d) = a bloom sized by branch order d.
# A stem re-applies its OWN rule on each sub-stem (recursive) AND every leaf + sub-stem is
# placed at a cumulative golden-angle roll (phyllotactic). DEPTH, branch count, and bloom
# count all scale with complexity. Petals / leaves / seed-dots are batched into one
# ArrayMesh each so the capture frames one coherent spray.
# =============================================================================

const _INF_GOLDEN_DEG: float = 137.50776
const _INF_MAX_DEPTH: int = 3
const _INF_INTERNODES_BASE: int = 5
const _INF_BRANCH_PITCH_DEG: float = 46.0
const _INF_LEAF_EVERY: int = 1

# Batched accumulators + materials for the current inflorescence build (set in _build_inflorescence).
var _inf_petal_st: SurfaceTool
var _inf_leaf_st: SurfaceTool
var _inf_seed_st: SurfaceTool
var _inf_mat_stem: StandardMaterial3D
var _inf_mat_petal: StandardMaterial3D
var _inf_mat_glow: StandardMaterial3D
var _inf_complexity_norm: float = 0.7


func _build_inflorescence() -> void:
	var plant := Node3D.new()
	plant.name = "Inflorescence"
	add_child(plant)

	# complexity in [3..12+] → a 0..1 norm scaling depth/branches/blooms (native ~0.7).
	_inf_complexity_norm = clampf(float(complexity - 3) / 6.0, 0.0, 1.0)

	# Materials: stem/leaves green (color_a), petals (color_a brightened toward accent for
	# a bloom hue), bloom-centre + seed-dots glow (accent).
	_inf_mat_stem = _cfl_foliage_mat(color_a)
	_inf_mat_petal = _cfl_foliage_mat(color_a.lerp(accent, 0.35))
	_inf_mat_glow = _cfl_glow_mat(accent, 3.0, false)
	var mat_seed := _cfl_glow_mat(accent, 3.4, true)

	# Open the batched accumulators.
	_inf_petal_st = SurfaceTool.new(); _inf_petal_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_inf_leaf_st = SurfaceTool.new(); _inf_leaf_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_inf_seed_st = SurfaceTool.new(); _inf_seed_st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Basal bulb on y=0.
	var bulb_r: float = 0.16
	_inf_build_bulb(plant, bulb_r)

	# Depth scales (a little) with complexity; clamp so it always terminates.
	var depth: int = clampi(_INF_MAX_DEPTH + int(floor(_inf_complexity_norm * 1.5 - 0.75)), 2, 4)

	# Native trial reach is ~2.45; _cfl_settle rescales to sculpt_height afterward, so build
	# at the native target and let settle normalise.
	var target_h: float = 2.45
	var origin := Vector3(0.0, bulb_r * 0.55, 0.0)
	var dir: Vector3 = Vector3.UP
	var roll_ref := Vector3(0.0, 0.0, 1.0)

	var k_main: int = _INF_INTERNODES_BASE + int(round(_inf_complexity_norm * 2.0 - 1.0))
	k_main = clampi(k_main, 4, 8)
	var decay: float = 0.86
	var geom_sum: float = (1.0 - pow(decay, float(k_main))) / (1.0 - decay)
	var trunk_reach: float = target_h * 0.60
	var base_internode: float = trunk_reach / geom_sum
	var base_radius: float = 0.052

	# GROW — the recursive phyllotactic L-system from the apex of the bulb.
	_inf_grow(plant, depth, origin, dir, roll_ref, base_internode, base_radius, k_main, decay)

	# Commit the batched meshes (petals / leaves / seed-dots → one ArrayMesh each).
	_cfl_commit_batch(plant, _inf_petal_st, _inf_mat_petal, "Petals")
	_cfl_commit_batch(plant, _inf_leaf_st, _inf_mat_stem, "Leaves")
	_cfl_commit_batch(plant, _inf_seed_st, mat_seed, "SeedDots")

	_cfl_settle(plant, maxf(sculpt_height, 0.4), maxf(sculpt_width, 0.2))
	plant.rotation_degrees = Vector3(0.0, -18.0, 0.0)


## Grow one STEM at branch order `depth` (0 = terminal). This IS the production rule,
## applied recursively: emit K internodes as a tapering tube (the turtle climbing along
## `dir`, arcing phototropically back toward vertical), shed a golden-angle LEAF at each
## internode (phyllotaxis), then at the apex either a terminal BLOOM (depth 0) or a whorl
## of B sub-stems (each a recursive _inf_grow at depth-1) plus a small axillary BLOOM. All
## randomness is baked into locals from `_rng` before any sweep Callable.
func _inf_grow(parent: Node3D, depth: int, base_pos: Vector3, base_dir: Vector3,
		roll_ref: Vector3, internode_len: float, start_radius: float,
		internodes: int, decay: float) -> void:

	var fwd: Vector3 = base_dir.normalized()
	var right: Vector3 = roll_ref - fwd * roll_ref.dot(fwd)
	if right.length_squared() < 0.0001:
		right = _cfl_any_perp(fwd)
	right = right.normalized()

	var bend_axis: Vector3 = _inf_tropism_axis(fwd, Vector3.UP)
	var off_vertical: float = fwd.angle_to(Vector3.UP)
	var is_trunk: bool = depth >= _INF_MAX_DEPTH
	var straighten_frac: float = 0.0 if is_trunk else lerpf(0.28, 0.16, float(_INF_MAX_DEPTH - depth) / float(maxi(_INF_MAX_DEPTH, 1)))
	var arc_per_node: float = (off_vertical * straighten_frac) + deg_to_rad(_rng.randf_range(-0.8, 0.8))
	if is_trunk:
		arc_per_node = deg_to_rad(0.5 + _rng.randf_range(-0.4, 0.4))

	var path: Array[Vector3] = []
	var radii: Array[float] = []
	var pos: Vector3 = base_pos
	var cur_dir: Vector3 = fwd
	var cur_right: Vector3 = right
	var seg_len: float = internode_len
	var radius: float = start_radius
	path.append(pos)
	radii.append(radius)

	var phyllo_roll: float = _rng.randf_range(0.0, TAU)

	for i: int in range(internodes):
		var step_basis := Basis(bend_axis, arc_per_node)
		cur_dir = (step_basis * cur_dir).normalized()
		cur_right = (step_basis * cur_right).normalized()
		pos = pos + cur_dir * seg_len
		radius = radius * 0.84 + 0.004
		path.append(pos)
		radii.append(radius)

		phyllo_roll += deg_to_rad(_INF_GOLDEN_DEG)
		if (i % _INF_LEAF_EVERY) == 0 and i < internodes - 1:
			var leaf_t: float = float(i) / float(maxi(internodes - 1, 1))
			var leaf_scale: float = lerpf(1.0, 0.45, leaf_t) * lerpf(0.6, 1.0, float(depth) / float(maxi(_INF_MAX_DEPTH, 1)))
			if depth >= 1 and leaf_scale > 0.3:
				_inf_add_leaf(pos, cur_dir, cur_right, phyllo_roll, leaf_scale)

	_cfl_add_mesh(parent, MorphoPrimitive.multi_tube(path, radii, _inf_stem_sides(depth)),
		_inf_mat_stem, Transform3D.IDENTITY, "Stem_d%d" % depth)

	var apex: Vector3 = path[path.size() - 1]
	var apex_dir: Vector3 = cur_dir
	var apex_right: Vector3 = cur_right
	var apex_radius: float = radii[radii.size() - 1]

	if depth <= 0:
		var term_size: float = lerpf(0.24, 0.30, _inf_complexity_norm) * _rng.randf_range(0.88, 1.12)
		var face_tilt: float = deg_to_rad(_rng.randf_range(30.0, 52.0))
		var bloom_face: Vector3 = _inf_tilt_outward(apex, apex_dir, face_tilt)
		_inf_add_bloom(parent, apex, bloom_face, apex_right, term_size, 0)
		return

	var fork_bloom: float = lerpf(0.10, 0.15, float(depth) / float(maxi(_INF_MAX_DEPTH, 1)))
	_inf_add_bloom(parent, apex, apex_dir, apex_right, fork_bloom, depth)

	var branches: int = _inf_branches_at(depth)
	var child_internodes: int = maxi(internodes - 1, 3)
	var child_internode_len: float = internode_len * 0.86
	var child_radius: float = apex_radius * 0.9

	var roll: float = phyllo_roll
	var pitch: float = deg_to_rad(_INF_BRANCH_PITCH_DEG * lerpf(1.0, 0.7, float(_INF_MAX_DEPTH - depth) / float(maxi(_INF_MAX_DEPTH, 1))))

	for b: int in range(branches):
		roll += deg_to_rad(_INF_GOLDEN_DEG)
		var rolled_right: Vector3 = (Basis(apex_dir, roll) * apex_right).normalized()
		var pitch_axis: Vector3 = apex_dir.cross(rolled_right).normalized()
		if pitch_axis.length_squared() < 0.0001:
			pitch_axis = _cfl_any_perp(apex_dir)
		var child_dir: Vector3 = (Basis(pitch_axis, pitch) * apex_dir).normalized()
		_inf_grow(parent, depth - 1, apex, child_dir, rolled_right,
			child_internode_len, child_radius, child_internodes, decay)


## Branches per fork at a given order — wider fan near the base, refining to pairs at tips.
func _inf_branches_at(depth: int) -> int:
	var extra: int = int(round(_inf_complexity_norm * 1.0 - 0.5))
	match depth:
		3: return clampi(3 + extra, 3, 4)
		2: return clampi(2 + extra, 2, 3)
		_: return clampi(2 + extra, 2, 2)


## Stem cross-section sides by order (thicker trunk → more sides).
func _inf_stem_sides(depth: int) -> int:
	return 8 if depth >= _INF_MAX_DEPTH else (6 if depth >= 1 else 5)


## Build a surreal Codex bloom at `at`, facing `face_dir`, with `right` seeding the petal-
## whorl phyllotaxis. Petals & seed-dots go into the shared batches; the centre dome + a
## small calyx cup are their own small revolution meshes.
func _inf_add_bloom(parent: Node3D, at: Vector3, face_dir: Vector3, right: Vector3,
		size: float, _order: int) -> void:
	var y: Vector3 = face_dir.normalized()
	var x: Vector3 = (right - y * right.dot(y))
	if x.length_squared() < 0.0001:
		x = _cfl_any_perp(y)
	x = x.normalized()
	var z: Vector3 = x.cross(y).normalized()
	var frame := Basis(x, y, z)

	var outer_petals: int = clampi(int(round(lerpf(7.0, 11.0, clampf(size / 0.4, 0.0, 1.0)))), 6, 12)
	var inner_petals: int = clampi(outer_petals - 3, 4, 9)

	var curl: float = _rng.randf_range(0.9, 1.15)
	var open_outer: float = deg_to_rad(_rng.randf_range(54.0, 66.0))
	var open_inner: float = deg_to_rad(_rng.randf_range(26.0, 36.0))

	var roll0: float = _rng.randf_range(0.0, TAU)
	_inf_emit_petal_ring(at, frame, outer_petals, size, open_outer, curl, roll0, 1.0)
	_inf_emit_petal_ring(at, frame, inner_petals, size * 0.66, open_inner, curl * 1.1,
		roll0 + deg_to_rad(_INF_GOLDEN_DEG * 0.5), 0.82)

	_inf_add_calyx(parent, at, frame, size)
	_inf_add_center(parent, at, frame, size)


## Emit one ring of petals into the shared petal batch. Each petal is a bezier_sweep blade
## in the bloom frame, rolled to its phyllotactic slot and tilted outward by `open_angle`.
func _inf_emit_petal_ring(at: Vector3, frame: Basis, count: int, reach: float,
		open_angle: float, curl: float, roll_start: float, width_scale: float) -> void:
	if count <= 0:
		return
	var blade_w: float = reach * 0.42 * width_scale
	var cross: Array = [
		Vector2(-blade_w, 0.0), Vector2(-blade_w * 0.5, blade_w * 0.10), Vector2(0.0, blade_w * 0.14),
		Vector2(blade_w * 0.5, blade_w * 0.10), Vector2(blade_w, 0.0)]

	for p: int in range(count):
		var roll: float = roll_start + float(p) * deg_to_rad(_INF_GOLDEN_DEG)
		var azim: Vector3 = (cos(roll) * frame.x + sin(roll) * frame.z).normalized()
		var tilt_axis: Vector3 = frame.y.cross(azim).normalized()
		if tilt_axis.length_squared() < 0.0001:
			tilt_axis = frame.x
		var petal_up: Vector3 = (Basis(tilt_axis, open_angle) * frame.y).normalized()

		var base: Vector3 = at + petal_up * (reach * 0.10)
		var tip: Vector3 = at + petal_up * (reach * 0.55) + azim * (reach * 0.92 * curl)
		var c1: Vector3 = at + petal_up * (reach * 0.55) + azim * (reach * 0.18)
		var c2: Vector3 = at + petal_up * (reach * 0.78) + azim * (reach * 0.62 * curl)
		var ctrl: Array = [base, c1, c2, tip]

		var blade: Mesh = MorphoPrimitive.bezier_sweep(ctrl, cross, 9, 0.0)
		if blade != null:
			_inf_petal_st.append_from(blade, 0, Transform3D.IDENTITY)


## Green calyx cup behind the petals (revolution), seating the bloom on the stem.
func _inf_add_calyx(parent: Node3D, at: Vector3, frame: Basis, size: float) -> void:
	var cup_r: float = size * 0.34
	var cup_h: float = size * 0.30
	var profile: Array[Vector2] = [
		Vector2(0.0, -cup_h * 0.5), Vector2(cup_r * 0.5, -cup_h * 0.30), Vector2(cup_r * 0.9, cup_h * 0.05),
		Vector2(cup_r * 0.6, cup_h * 0.45), Vector2(cup_r * 0.18, cup_h * 0.55)]
	_cfl_add_mesh(parent, MorphoPrimitive.revolution(profile, 12), _inf_mat_stem,
		Transform3D(frame, at), "Calyx")


## Glowing gold centre: a domed disc (revolution) + a Vogel-spiral stud of seed-dots
## (golden-angle packed: r = c·sqrt(n), θ = n·golden_angle) sitting on the dome.
func _inf_add_center(parent: Node3D, at: Vector3, frame: Basis, size: float) -> void:
	var disc_r: float = size * 0.30
	var disc_h: float = size * 0.20
	var profile: Array[Vector2] = []
	var rings: int = 6
	for i: int in range(rings + 1):
		var t: float = float(i) / float(rings)
		var r: float = disc_r * (1.0 - t)
		var h: float = disc_h * sin(t * PI * 0.5)
		profile.append(Vector2(r, h))
	_cfl_add_mesh(parent, MorphoPrimitive.revolution(profile, 16), _inf_mat_glow,
		Transform3D(frame, at + frame.y * (size * 0.06)), "BloomCenter")

	var dot_count: int = clampi(int(round(disc_r * 220.0)), 14, 46)
	var dot_r: float = disc_r * 0.085
	var dot_mesh: Mesh = MorphoPrimitive.sphere(dot_r, 6, 4)
	var spread: float = disc_r * 0.92
	for n: int in range(dot_count):
		var nn: float = float(n) + 0.5
		var rr: float = spread * sqrt(nn / float(dot_count))
		var th: float = nn * deg_to_rad(_INF_GOLDEN_DEG)
		var planar: Vector3 = frame.x * (cos(th) * rr) + frame.z * (sin(th) * rr)
		var local_r: float = rr / maxf(disc_r, 0.0001)
		var hh: float = disc_h * sin(clampf(local_r, 0.0, 1.0) * PI * 0.5)
		var dot_pos: Vector3 = at + frame.y * (size * 0.06 + hh + dot_r * 0.4) + planar
		_inf_seed_st.append_from(dot_mesh, 0, Transform3D(Basis().scaled(Vector3.ONE), dot_pos))


## Add one leaf at stem position `pos`, springing outward at the phyllotactic `roll` about
## the stem direction `dir`, drooping slightly. Swept as a bezier blade into the leaf batch.
func _inf_add_leaf(pos: Vector3, dir: Vector3, right: Vector3, roll: float, scale: float) -> void:
	var length: float = 0.42 * scale
	var width: float = 0.13 * scale

	var azim: Vector3 = (Basis(dir, roll) * right).normalized()
	var up_tilt_axis: Vector3 = dir.cross(azim).normalized()
	if up_tilt_axis.length_squared() < 0.0001:
		up_tilt_axis = _cfl_any_perp(dir)
	var out_up: Vector3 = (Basis(up_tilt_axis, deg_to_rad(-28.0)) * azim).normalized()

	var base: Vector3 = pos + azim * (width * 0.4)
	var tip: Vector3 = pos + out_up * (length * 0.55) + azim * (length * 0.6) - dir * (length * 0.12)
	var c1: Vector3 = pos + out_up * (length * 0.30) + azim * (length * 0.25)
	var c2: Vector3 = pos + out_up * (length * 0.50) + azim * (length * 0.50)
	var ctrl: Array = [base, c1, c2, tip]

	var cross: Array = [
		Vector2(-width, 0.0), Vector2(-width * 0.4, width * 0.12), Vector2(0.0, width * 0.16),
		Vector2(width * 0.4, width * 0.12), Vector2(width, 0.0)]
	var blade: Mesh = MorphoPrimitive.bezier_sweep(ctrl, cross, 8, 0.0)
	if blade != null:
		_inf_leaf_st.append_from(blade, 0, Transform3D.IDENTITY)


## A small onion-ish bulb the plant rises from at y=0.
func _inf_build_bulb(parent: Node3D, r: float) -> void:
	var profile: Array[Vector2] = [
		Vector2(0.0, 0.0), Vector2(r * 0.85, r * 0.18), Vector2(r * 1.0, r * 0.55),
		Vector2(r * 0.78, r * 0.95), Vector2(r * 0.40, r * 1.18), Vector2(r * 0.16, r * 1.30)]
	_cfl_add_mesh(parent, MorphoPrimitive.revolution(profile, 20), _inf_mat_stem,
		Transform3D.IDENTITY, "Bulb")


## Rotation axis such that rotating `dir` about it by a POSITIVE angle moves `dir` toward
## `target` (the tropism / straightening axis). Falls back to any perpendicular when
## (anti)parallel.
func _inf_tropism_axis(dir: Vector3, target: Vector3) -> Vector3:
	var ax: Vector3 = dir.normalized().cross(target.normalized())
	if ax.length_squared() < 0.0001:
		return _cfl_any_perp(dir)
	return ax.normalized()


## Tilt a near-vertical direction `dir` OUTWARD from world-up by `angle` radians, in the
## vertical plane containing the stem's horizontal heading, so a terminal bloom faces out
## to the side rather than straight up.
func _inf_tilt_outward(at: Vector3, dir: Vector3, angle: float) -> Vector3:
	var horiz := Vector3(dir.x, 0.0, dir.z)
	if horiz.length_squared() < 0.0001:
		horiz = Vector3(at.x, 0.0, at.z)
	if horiz.length_squared() < 0.0001:
		horiz = Vector3(1.0, 0.0, 0.6)
	horiz = horiz.normalized()
	var ax: Vector3 = Vector3.UP.cross(horiz)
	if ax.length_squared() < 0.0001:
		ax = _cfl_any_perp(Vector3.UP)
	ax = ax.normalized()
	return (Basis(ax, angle) * Vector3.UP).normalized()
