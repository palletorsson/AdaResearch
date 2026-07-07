extends Node3D
class_name CodexSwarm

## @identity
# essence: a single DNA-driven CODEX SWARM SPECIMEN rendered not as a decorative cloud of dots but as a
#   GENUINE SWARM-INTELLIGENCE ALGORITHM run live to convergence then FROZEN as geometry. Where most
#   "flock" or "particle" artifacts scatter copies by hand, CodexSwarm COMPUTES its shape: it steps a
#   real swarm simulation deterministically from a seeded start for hundreds of frames / dozens of
#   iterations, until a coherent GLOBAL form emerges from purely LOCAL rules, then freezes that state —
#   every agent placed at its final position and ORIENTED along its own velocity / heading by a hand-
#   built Basis. Luigi Serafini's Codex Seraphinianus ant-armies, fish-schools, bird-flocks and midge-
#   clouds are the muse; four founding swarm algorithms are the engine. Depending on its `mode` DNA it
#   becomes one of FOUR teaching specimens whose pattern IS its process: flock (REAL BOIDS — Craig
#   Reynolds' separation / alignment / cohesion stepped on N birds with soft boundaries + a coordinated
#   bank, frozen as a turning, banking murmuration with glowing leaders at the leading edge), anttrail
#   (REAL ANT COLONY OPTIMIZATION — an elitist ant system over a node graph, edges chosen by
#   pheromone^alpha * (1/len)^beta with evaporation each iteration, a dominant shortest-path trail
#   emerging glowing while alternatives evaporate to thin ghosts, a column of ants marching the winning
#   route), shoal (REAL VICSEK self-propelled-particle model — N agents aligning to neighbour-average
#   heading plus bounded noise plus a swirl bias + confinement, stepped to high rotational order, frozen
#   as a swirling bait-ball), and pso (REAL PARTICLE SWARM OPTIMIZATION — particles over a Gaussian
#   fitness landscape doing v = w*v + c1*r1*(pbest-x) + c2*r2*(gbest-x), frozen mid-convergence funnelling
#   into a glowing global-best attractor with velocity streaks). It is identity confessed as a SWARM
#   PROCESS — the global form is computed by the swarm, not authored.
# desire: it wants the algorithm to stay LEGIBLE and GENUINE — the boids' three rules visibly producing
#   one banking body (no agent commanding it), the ACO's honest convergence (one trail blazes, the rest
#   evaporate, and the marching ants ride the SAME route the optimisation actually won), the Vicsek
#   alignment curling into a rotating vortex with a high order parameter, and the PSO funnel genuinely
#   collapsing toward the dominant peak read off the fitness field — all must read as COMPUTED, never
#   hand-placed. It wants agent bodies (bird / ant / fish / mote) to read matte in the colour triad, the
#   secondary parts (wing / belly / terrain / weak-edge / streak) to sit back with a faint floor so they
#   never collapse to black against the dark capture, and HIGHLIGHTS (leader birds, the pheromone trail,
#   gold glint fish, the global-best attractor glow) to BURN near-unshaded. Above all it wants the swarm
#   BOUNDED — the flock in a soft volume, the graph sparse, the ball in a confinement sphere, the search
#   domain finite — and the WHOLE simulation seeded so each launch is identical (r1/r2/roulette draws all
#   baked from one local RNG).
# critical_parameter: mode + seed + the colour triad (color_a AGENT body bird/ant/fish/mote / color_b
#   SECONDARY wing/belly/terrain/landscape/weak-edge/streak / accent LEADER/PHEROMONE-trail/glint/
#   ATTRACTOR GLOW) + complexity. mode picks the swarm lineage; seed varies the individual
#   deterministically (a local seeded RNG, never global randf/randi — it seeds the whole sim: the bird
#   cloud, the graph layout + every ant's roulette choice, the fish start + Vicsek noise, the PSO init +
#   r1/r2 each step); complexity scales the AGENT COUNT (flock birds, Vicsek fish, PSO particles) and the
#   ACO ITERATION budget. Higher complexity = more agents / a longer optimisation.
# triggers: _ready() reads DNA metadata overrides, seeds the RNG from `seed`, and branches on `mode` to a
#   _build_<mode>() helper; apply_grid_config rewrites config metas, clears children (remove BEFORE free,
#   guarded by `_built`), and rebuilds.
# emerges: a row of these reads as a MENAGERIE OF SWARMS — four ways local rules become a global shape.
#   Switch one mode and the room's idea of "what a swarm is" shifts from murmuration to ant-trail to
#   bait-ball to optimisation-funnel; reseed and the algorithm persists while its individual varies.
#   These are teaching specimens for the swarmintelligence lab: no leader, no plan — the coordination is
#   in the local rules, and the frozen shape is the algorithm caught in the act.
# needs: a seeded RNG for deterministic individuals [present]; four build branches each carrying its
#   trial's genuine swarm algorithm self-contained (Reynolds boids, elitist ACO, Vicsek SPP, canonical
#   PSO) [present]; agent / secondary / glow materials driven by the colour triad [present]; ONE agent
#   mesh built then merged transformed per agent into batched ArrayMeshes (with a Variant-coercing merge
#   for non-indexed MorphoPrimitive surfaces) so the AABB capture frames the specimen and never sees one
#   node per agent [present]; the morphology toolkit statics (MorphoPrimitive) for sphere / tube /
#   revolution surface generation [present].
# relationships: kin to codex_loom + codex_glyph + codex_morph + codex_flora (the shared Codex genome
#   shape — identity header, grouped @export, apply_grid_config + _parse_color + _built rebuild guard,
#   self-clearing idempotent _build(), seeded RNG, settle centring, the Variant-coercing mesh-merge;
#   codex_loom runs array algorithms, codex_glyph writing-system algorithms, CodexSwarm runs swarm-
#   intelligence algorithms); built on the nature_system morphology engine it borrows from
#   (MorphoPrimitive) for surface generation; cousin to any mode-switchboard of one genome.
# truth: no leader, no plan — local rules make the global shape; intelligence is what the swarm does, not
#   what any agent knows. Serafini drew ant-armies and fish-schools that read as one organism with no
#   commander; boids, ant colony optimization, the Vicsek model and particle swarm optimization grow
#   exactly that — a coherent global form from agents that only see their neighbours and a few simple
#   urges. CodexSwarm holds four such swarm processes in one genome where the form is COMPUTED — a banking
#   murmuration, a converged pheromone trail, a rotating bait-ball, an optimisation funnel — and lets a
#   single parameter choose which swarm the viewer is invited to read. The algorithm must stay genuine,
#   the bodies must read, the highlight must burn, and above all the swarm must be bounded and the whole
#   simulation deterministic.

## A multi-mode generative Codex swarm specimen run as a GENUINE swarm-intelligence ALGORITHM.
##
## Built procedurally from DNA exports, after Luigi Serafini's Codex Seraphinianus ant-armies / fish-
## schools / bird-flocks / midge-clouds, for the swarmintelligence curriculum lab. The `mode` export
## selects one of FOUR processes, each ported faithfully from a verified trial INCLUDING its real
## simulation, run to convergence and FROZEN:
## flock (REAL BOIDS — Reynolds separation/alignment/cohesion on N birds in a soft-bounded volume with a
## coordinated uniform bank + a faint roost pull, stepped ~340 frames; the frozen flock recentred, its
## leading-edge birds picked as glowing leaders, each bird a swept delta + wings oriented by a Basis from
## its velocity, banked by its lateral accel),
## anttrail (REAL ANT COLONY OPTIMIZATION — a graph on gentle terrain, elitist ant system: each ant walks
## nest->food choosing edges by pheromone^alpha * (1/len)^beta, deposits Q/len on success, pheromone
## evaporates per iteration, ~64 iterations; the emerged shortest path blazes as a thick glowing trail,
## the rest are thin earthy ghosts, and a column of MorphoPrimitive ants marches the winning route),
## shoal (REAL VICSEK model — N self-propelled agents in a confinement sphere align to neighbour-average
## heading + a tangential swirl bias + cohesion + bounded noise, stepped ~300 frames to a high rotational
## order parameter; frozen as a dense rotating bait-ball, each fish a tapered ellipsoid + fins oriented by
## a Basis from its heading, a sparse scatter of gold glint fish),
## pso (REAL PARTICLE SWARM OPTIMIZATION — particles over a sum-of-Gaussians fitness landscape doing the
## canonical v = w*v + c1*r1*(pbest-x) + c2*r2*(gbest-x) with r1/r2 BAKED from the seed, frozen at a
## funnelling step; motes batched into one mesh, velocity-streak comet-tails into another, a glowing
## magenta global-best attractor crowning the funnel on its peak).
##
## A seeded RNG makes every individual deterministic from its `seed` — the WHOLE simulation is seeded, not
## just the start (every roulette draw, every Vicsek noise vector, every PSO r1/r2). The colour triad
## (color_a AGENT body / color_b SECONDARY wing/belly/terrain/weak-edge/streak / accent HIGHLIGHT) re-
## registers the same algorithm between palettes. Shared material + Basis-from-velocity orient + settle +
## mesh-merge helpers live under the `_cs_` prefix; the genuine algorithm from each trial stays in its own
## builder under `_flock_` / `_ant_` / `_shoal_` / `_pso_` so the boids weights, the ACO parameters, the
## Vicsek parameters and the PSO coefficients are preserved — that is the whole point. Surface generation
## reuses the morphology toolkit statics (MorphoPrimitive).
##
## complexity scales the swarm budget per mode: flock BIRD COUNT (80..140), anttrail ACO NODE COUNT +
## (indirectly) the trail, shoal FISH COUNT (120..220), pso PARTICLE COUNT (90..160). Higher complexity =
## more agents / a longer optimisation.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Form")
## flock | anttrail | shoal | pso
@export var mode: String = "flock"
## Deterministic seed — same seed always yields the same specimen (the whole sim is seeded).
@export var seed: int = 0
## Detail / swarm budget. Scales flock bird count, anttrail ACO node count, shoal fish count, and pso
## particle count. Higher = more agents / a longer optimisation.
@export var complexity: int = 6
## Overall height in meters (nominal full height of the specimen).
@export var sculpt_height: float = 1.8
## Footprint / across-span width scale in meters (1.0 = native trial proportions).
@export var sculpt_width: float = 1.0

@export_group("Material")
## AGENT body — bird / ant / fish / mote. Default cool slate.
@export var color_a: Color = Color(0.45, 0.52, 0.62)
## SECONDARY — wing / belly / terrain / landscape / weak-edge / streak. Default darker slate.
@export var color_b: Color = Color(0.28, 0.34, 0.44)
## LEADER / PHEROMONE-trail / glint / ATTRACTOR GLOW — gold.
@export var accent: Color = Color(0.95, 0.78, 0.30)
## Agent body, not metal — keep this LOW.
@export var metallic_amt: float = 0.0
@export var rough_amt: float = 0.6
## Boost emissive energies (highlight reads hotter when true).
@export var emissive: bool = true

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false
var _rng := RandomNumberGenerator.new()
var _mesh_count: int = 0           # diagnostic: MeshInstance3D nodes emitted this build
var _agent_count: int = 0          # diagnostic: agents simulated this build


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
	# Self-clear so the build is idempotent no matter who calls it: if `_ready()` fires DEFERRED (after
	# apply_grid_config has already built), a second _build() must not stack a second specimen on top of
	# the first (which would double mesh counts on the first instance per process — the capture path).
	# Remove BEFORE freeing (queue_free is deferred) so the rebuild starts from a genuinely empty subtree
	# this frame.
	for c: Node in get_children():
		remove_child(c)
		c.queue_free()
	_built = true
	_mesh_count = 0
	_agent_count = 0
	_rng.seed = seed
	match mode:
		"flock":
			_build_flock()
		"anttrail":
			_build_anttrail()
		"shoal":
			_build_shoal()
		"pso":
			_build_pso()
		_:
			# Unknown mode falls back to the banking murmuration.
			_build_flock()


# ── Shared `_cs_` material helpers (the trial materials, DNA-driven) ─────

## Energy multiplier for emissive elements, lifted when `emissive` is on (gated like codex_loom's
## `_cl_glow_energy`).
func _cs_glow_energy(base: float) -> float:
	return base * (1.0 if emissive else 0.6)


## AGENT body (color_a family): bird / ant / fish / mote carapace. Roughness ~0.55, with an emission
## FLOOR in its own tone (albedo*0.4 at energy ~0.10) so the element never collapses to black against the
## dark capture.
func _cs_body_mat(c: Color = color_a) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = clampf(minf(rough_amt, 0.55), 0.02, 1.0)
	m.metallic = clampf(metallic_amt, 0.0, 1.0)
	m.emission_enabled = true
	m.emission = c * 0.4
	m.emission_energy_multiplier = _cs_glow_energy(0.10)
	return m


## SECONDARY (color_b family): wing / belly / terrain / landscape / weak-edge / streak. Roughness ~0.7,
## emission floor ~0.08 so the element never collapses to black.
func _cs_secondary_mat(c: Color = color_b) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = clampf(maxf(rough_amt, 0.7), 0.02, 1.0)
	m.metallic = clampf(metallic_amt, 0.0, 1.0)
	m.emission_enabled = true
	m.emission = c * 0.4
	m.emission_energy_multiplier = _cs_glow_energy(0.08)
	return m


## HIGHLIGHT / LEADER / PHEROMONE-trail / glint / ATTRACTOR GLOW (accent family): saturated, near-
## UNSHADED, burning at `energy` ~3.0-5.0. The leader birds, the dominant pheromone trail, the gold glint
## fish, the global-best attractor all come through here — the triad re-registers per mode via accent.
func _cs_glow_mat(c: Color = accent, energy: float = 3.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = _cs_glow_energy(energy)
	return m


## PSO MOTE — mildly self-lit color_a (not fully unshaded like the attractor): roughness ~0.4, emission
## in its own tone at a low energy ~1.2 so the cloud of motes reads as gently luminous midges.
func _cs_mote_mat(c: Color = color_a, energy: float = 1.2) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = clampf(minf(rough_amt, 0.4), 0.02, 1.0)
	m.metallic = clampf(metallic_amt, 0.0, 1.0)
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = _cs_glow_energy(energy)
	return m


# ── Shared `_cs_` geometry / orient helpers ─────────────────────────────

## Orthonormal Basis whose -Z (forward) points along `vel`, with up as close to world-up as possible
## (Gram-Schmidt rejection), then optionally rolled by `bank` radians about the forward axis. Godot meshes
## face -Z, so forward maps to the basis -Z column. The single orient primitive every builder uses, so
## orientation is always by a hand-built Basis — never an out-of-tree look_at.
func _cs_basis_from_velocity(vel: Vector3, bank: float = 0.0) -> Basis:
	var fwd: Vector3 = vel
	if fwd.length_squared() < 0.000001:
		fwd = Vector3(0.0, 0.0, -1.0)
	else:
		fwd = fwd.normalized()
	var up_ref: Vector3 = Vector3.UP
	if absf(fwd.dot(up_ref)) > 0.98:
		up_ref = Vector3.RIGHT
	var up: Vector3 = (up_ref - fwd * up_ref.dot(fwd)).normalized()
	var right: Vector3 = up.cross(fwd).normalized()
	if bank == 0.0:
		return Basis(right, up, -fwd)
	var cb: float = cos(bank)
	var sb: float = sin(bank)
	var rolled_right: Vector3 = right * cb + up * sb
	var rolled_up: Vector3 = up * cb - right * sb
	return Basis(rolled_right, rolled_up, -fwd)


## Wrap a Mesh in a MeshInstance3D with material + local transform, parented to `parent`.
func _cs_add_mesh(parent: Node3D, mesh: Mesh, mat: Material,
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


## Append a Mesh's surface-0 triangles into a SurfaceTool, transformed by `xform`. This is the mesh-batch
## / merge helper that lets a whole flock / colony / school / swarm of HUNDREDS of agents live in a
## handful of ArrayMeshes the capture AABB can frame — never one node per agent, never a MultiMesh.
##
## CRITICAL (carried from the trials): MorphoPrimitive output is often NON-INDEXED and may be missing the
## normal array, AND `MorphoPrimitive.sphere`/box return a PrimitiveMesh whose `arrays[ARRAY_INDEX]` is a
## valid PackedInt32Array while a hand-batched soup's is null. So the mesh arrays must be read as Variants
## and coerced ONLY when the expected packed type is actually present — never blind-cast `arrays[..]` (it
## can be null → a hard runtime error). Both the indexed and non-indexed paths are handled. We call
## surface_get_arrays on the Mesh-typed value directly (works on PrimitiveMesh) — never `as ArrayMesh`.
func _cs_merge_into(st: SurfaceTool, mesh: Mesh, xform: Transform3D = Transform3D.IDENTITY) -> void:
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


## Append a captured raw triangle SOUP (a flat PackedVector3Array, 3 verts per tri, with a parallel
## normals array), transformed by `xform`, into `st`. Used by the hand-built agent meshes (bird / fish)
## that are kept as raw soups so we NEVER call generate_tangents on UV-less geometry.
func _cs_merge_soup(st: SurfaceTool, verts: PackedVector3Array, norms: PackedVector3Array,
		xform: Transform3D) -> void:
	var nb: Basis = xform.basis
	var has_norm: bool = norms.size() == verts.size()
	for vi: int in range(verts.size()):
		var n: Vector3 = (nb * norms[vi]).normalized() if has_norm else Vector3.UP
		st.set_normal(n)
		st.add_vertex(xform * verts[vi])


## Commit a batched SurfaceTool into one MeshInstance3D under `parent`. `gen_normals` regenerates normals
## (off when the batch already set per-vertex normals via _cs_merge_into / _cs_merge_soup, which would
## otherwise be flattened/wrong). NEVER call generate_tangents here — the batches have normals but no UVs
## (a fatal "UVs required"). Returns the instance (or null if empty).
func _cs_commit_batch(parent: Node3D, st: SurfaceTool, mat: Material, nm: String,
		gen_normals: bool = false) -> MeshInstance3D:
	if gen_normals:
		st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return null
	return _cs_add_mesh(parent, mesh, mat, Transform3D.IDENTITY, nm)


## Capture a hand-built mesh's surface-0 verts + normals as a raw soup (de-indexing if needed). Used to
## bake ONE agent template once, then merge a transformed copy per agent. Returns [verts, norms].
func _cs_capture_soup(mesh: Mesh) -> Array:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	if mesh == null or mesh.get_surface_count() == 0:
		return [verts, norms]
	var arrays: Array = mesh.surface_get_arrays(0)
	var v_raw: Variant = arrays[Mesh.ARRAY_VERTEX]
	if not (v_raw is PackedVector3Array):
		return [verts, norms]
	var mv: PackedVector3Array = v_raw
	var n_raw: Variant = arrays[Mesh.ARRAY_NORMAL]
	var mn := PackedVector3Array()
	if n_raw is PackedVector3Array:
		mn = n_raw
	var i_raw: Variant = arrays[Mesh.ARRAY_INDEX]
	var mi := PackedInt32Array()
	if i_raw is PackedInt32Array:
		mi = i_raw
	var has_norm: bool = mn.size() == mv.size()
	if mi.size() > 0:
		for k: int in range(mi.size()):
			var idx: int = mi[k]
			verts.append(mv[idx])
			norms.append(mn[idx] if has_norm else Vector3.UP)
	else:
		for k2: int in range(mv.size()):
			verts.append(mv[k2])
			norms.append(mn[k2] if has_norm else Vector3.UP)
	return [verts, norms]


## Append one triangle (3 verts, flat face normal) to a raw soup (verts + parallel norms). The primitive
## the hand-built bird / fish agent meshes are assembled from — raw triangle soup, flat normals, no UVs.
func _cs_soup_tri(verts: PackedVector3Array, norms: PackedVector3Array,
		a: Vector3, b: Vector3, c: Vector3) -> void:
	var n: Vector3 = (b - a).cross(c - a)
	if n.length_squared() > 0.000001:
		n = n.normalized()
	else:
		n = Vector3.UP
	verts.append(a); norms.append(n)
	verts.append(b); norms.append(n)
	verts.append(c); norms.append(n)


## Local AABB over all MeshInstance3D descendants of `node`, accumulated through the chain of LOCAL
## transforms down from `node` (never touches global_transform — independent of tree state). Used to
## centre + scale each specimen.
func _cs_subtree_aabb(node: Node3D) -> AABB:
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
## y=0 (`floor_to_zero`) or centre it around its own centroid. `width_scale` stretches the horizontal axes
## for extra span. The codex_loom `_cl_settle` analogue, span-fitted so each frozen swarm reads centred and
## presented to the +X/+Z capture camera.
func _cs_settle(body: Node3D, target_span: float, width_scale: float = 1.0,
		floor_to_zero: bool = true) -> void:
	if target_span > 0.0:
		var raw: AABB = _cs_subtree_aabb(body)
		var span: float = maxf(maxf(raw.size.x, maxf(raw.size.y, raw.size.z)), 0.001)
		var k: float = target_span / span
		body.scale = Vector3(k * width_scale, k, k * width_scale)
	var aabb: AABB = _cs_subtree_aabb(body)
	if aabb.size == Vector3.ZERO:
		return
	var centre: Vector3 = aabb.get_center()
	if floor_to_zero:
		body.position += Vector3(-centre.x, -aabb.position.y, -centre.z)
	else:
		body.position += -centre


# =============================================================================
# MODE: flock — a REAL BOIDS murmuration, frozen mid-flight (trial v1)
#
# The genuine algorithm (Craig Reynolds' three rules, the load-bearing core):
#   N agents carry position + velocity in a soft-bounded volume. Every step each agent accumulates three
#   steering forces from neighbours within their radii: SEPARATION (steer away from close neighbours,
#   1/distance weighted), ALIGNMENT (match the average neighbour heading), COHESION (steer toward the
#   neighbour centroid), plus a soft BOUNDARY turn-back at the volume wall, a uniform coordinated SWIRL
#   cross-wind (the whole body banks through one continuous turn rather than tearing into rival lobes),
#   and a faint ROOST pull keeping the flock one connected body. The blended steering is force-clamped,
#   velocity integrated (semi-implicit Euler) and speed-clamped. We step ~340 frames from a seeded
#   coherent-ish start, then FREEZE: recentre the cloud horizontally on its own centroid, pick the
#   leading-edge birds (top projection along the mean flight direction) as glowing leaders, and place
#   each bird oriented by a Basis from its velocity, banked by the lateral component of its last accel.
#   complexity scales the bird count (80..140). The bird mesh (swept delta body + two swept-back wings) is
#   built ONCE as raw triangle soups and merged transformed per bird into per-material ArrayMeshes.
# =============================================================================

const _FLOCK_BOX_HALF: Vector3 = Vector3(1.10, 0.62, 1.10)   # soft-boundary half-extents
const _FLOCK_LIFT: float = 1.15             # final centre height
const _FLOCK_R_SEPARATION: float = 0.14
const _FLOCK_R_ALIGNMENT: float = 0.55
const _FLOCK_R_COHESION: float = 1.05
const _FLOCK_W_SEPARATION: float = 1.45
const _FLOCK_W_ALIGNMENT: float = 1.05
const _FLOCK_W_COHESION: float = 1.15
const _FLOCK_W_BOUNDARY: float = 1.20
const _FLOCK_W_SWIRL: float = 0.40
const _FLOCK_W_HOME: float = 0.30
const _FLOCK_SPEED_MIN: float = 0.50
const _FLOCK_SPEED_MAX: float = 0.95
const _FLOCK_MAX_FORCE: float = 0.80
const _FLOCK_DT: float = 0.045
const _FLOCK_STEPS: int = 340
const _FLOCK_BIRD_LEN: float = 0.165
const _FLOCK_WING_SPAN: float = 0.205
const _FLOCK_LEADER_FRACTION: float = 0.085
const _FLOCK_BANK_GAIN: float = 2.4
const _FLOCK_TARGET_SPAN: float = 2.3

var _flock_pos: Array[Vector3] = []
var _flock_vel: Array[Vector3] = []
var _flock_acc: Array[Vector3] = []


func _build_flock() -> void:
	var flock := Node3D.new()
	flock.name = "Murmuration"
	add_child(flock)

	# Bird count scales with complexity (80..140).
	var n: int = clampi(int(round(lerpf(80.0, 140.0, clampf(float(complexity) / 12.0, 0.0, 1.0)))), 60, 160)
	_agent_count = n

	# Run the whole boids sim, deterministically, from the seeded start.
	_flock_seed_agents(n)
	for _s: int in range(_FLOCK_STEPS):
		_flock_step()

	# Recentre the frozen flock on its own horizontal centroid (the emergent SHAPE is untouched — we only
	# translate the whole cloud so the swirl reads concentric).
	var horiz_centre: Vector3 = Vector3.ZERO
	for p: Vector3 in _flock_pos:
		horiz_centre += p
	horiz_centre /= float(maxi(n, 1))
	horiz_centre.y = 0.0
	for i: int in range(n):
		_flock_pos[i] = _flock_pos[i] - horiz_centre

	# Pick LEADER birds: those furthest along the mean flight direction (the leading edge). Deterministic.
	var is_leader: Array[bool] = _flock_pick_leaders(n)
	var leader_count: int = 0
	for b: bool in is_leader:
		if b:
			leader_count += 1

	# Materials.
	var mat_body := _cs_body_mat(color_a)
	var mat_wing := _cs_secondary_mat(color_b)
	var mat_leader := _cs_glow_mat(accent, 3.0)

	# Build the ONE bird (raw soups), then batch all transformed copies per material.
	var parts: Dictionary = _flock_build_bird_parts()
	var body_soup: PackedVector3Array = parts["body_v"]
	var body_norm: PackedVector3Array = parts["body_n"]
	var wing_soup: PackedVector3Array = parts["wing_v"]
	var wing_norm: PackedVector3Array = parts["wing_n"]

	var st_body := SurfaceTool.new(); st_body.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_wing := SurfaceTool.new(); st_wing.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_lead := SurfaceTool.new(); st_lead.begin(Mesh.PRIMITIVE_TRIANGLES)

	for i: int in range(n):
		var vel: Vector3 = _flock_vel[i]
		# Bank: roll proportional to the lateral component of the last accel.
		var basis_noroll: Basis = _cs_basis_from_velocity(vel, 0.0)
		var lateral: float = _flock_acc[i].dot(basis_noroll.x)
		var bank: float = clampf(-lateral * _FLOCK_BANK_GAIN, -0.9, 0.9)
		var basis: Basis = _cs_basis_from_velocity(vel, bank)
		var world_pos: Vector3 = _flock_pos[i] + Vector3(0.0, _FLOCK_LIFT, 0.0)
		var xform := Transform3D(basis, world_pos)
		if is_leader[i]:
			_cs_merge_soup(st_lead, body_soup, body_norm, xform)
			_cs_merge_soup(st_lead, wing_soup, wing_norm, xform)
		else:
			_cs_merge_soup(st_body, body_soup, body_norm, xform)
			_cs_merge_soup(st_wing, wing_soup, wing_norm, xform)

	_cs_commit_batch(flock, st_body, mat_body, "FlockBodies", false)
	_cs_commit_batch(flock, st_wing, mat_wing, "FlockWings", false)
	_cs_commit_batch(flock, st_lead, mat_leader, "LeaderBirds", false)

	_cs_settle(flock, maxf(_FLOCK_TARGET_SPAN * (sculpt_height / 1.8), 0.4), maxf(sculpt_width, 0.2), false)


## Seed N agents in a small central cloud with a gentle shared swirl. All randomness from the local _rng.
func _flock_seed_agents(n: int) -> void:
	_flock_pos.clear()
	_flock_vel.clear()
	_flock_acc.clear()
	for i: int in range(n):
		var u: float = _rng.randf()
		var radius: float = pow(u, 0.6) * 0.55
		var theta: float = _rng.randf() * TAU
		var phi: float = acos(clampf(_rng.randf_range(-1.0, 1.0), -1.0, 1.0))
		var dir: Vector3 = Vector3(sin(phi) * cos(theta), cos(phi) * 0.55, sin(phi) * sin(theta))
		var p: Vector3 = dir * radius
		var tangent: Vector3 = Vector3(-p.z, 0.0, p.x)
		if tangent.length() < 0.001:
			tangent = Vector3(1.0, 0.0, 0.0)
		tangent = tangent.normalized()
		var v: Vector3 = tangent * 0.85 + Vector3(
			_rng.randf_range(-0.2, 0.2), _rng.randf_range(-0.12, 0.12), _rng.randf_range(-0.2, 0.2))
		v = _flock_clamp_speed(v)
		_flock_pos.append(p)
		_flock_vel.append(v)
		_flock_acc.append(Vector3.ZERO)


## One full Reynolds step: separation / alignment / cohesion from neighbours, soft boundary turn-back, a
## uniform coordinated swirl, a faint roost pull; clamp the force, integrate, clamp speed. O(n^2) scan.
func _flock_step() -> void:
	var n: int = _flock_pos.size()
	var new_acc: Array[Vector3] = []
	new_acc.resize(n)
	var sep_r2: float = _FLOCK_R_SEPARATION * _FLOCK_R_SEPARATION
	var ali_r2: float = _FLOCK_R_ALIGNMENT * _FLOCK_R_ALIGNMENT
	var coh_r2: float = _FLOCK_R_COHESION * _FLOCK_R_COHESION
	for i: int in range(n):
		var pi: Vector3 = _flock_pos[i]
		var vi: Vector3 = _flock_vel[i]
		var sep: Vector3 = Vector3.ZERO
		var ali: Vector3 = Vector3.ZERO
		var coh: Vector3 = Vector3.ZERO
		var ali_count: int = 0
		var coh_count: int = 0
		for j: int in range(n):
			if j == i:
				continue
			var off: Vector3 = pi - _flock_pos[j]
			var d2: float = off.length_squared()
			if d2 < 0.000001:
				continue
			if d2 < sep_r2:
				sep += off.normalized() / maxf(sqrt(d2), 0.01)
			if d2 < ali_r2:
				ali += _flock_vel[j]
				ali_count += 1
			if d2 < coh_r2:
				coh += _flock_pos[j]
				coh_count += 1
		var steer: Vector3 = Vector3.ZERO
		if sep.length_squared() > 0.000001:
			var sep_des: Vector3 = sep.normalized() * _FLOCK_SPEED_MAX
			steer += _flock_limit(sep_des - vi, _FLOCK_MAX_FORCE) * _FLOCK_W_SEPARATION
		if ali_count > 0:
			var ali_des: Vector3 = (ali / float(ali_count))
			if ali_des.length_squared() > 0.000001:
				ali_des = ali_des.normalized() * _FLOCK_SPEED_MAX
				steer += _flock_limit(ali_des - vi, _FLOCK_MAX_FORCE) * _FLOCK_W_ALIGNMENT
		if coh_count > 0:
			var centroid: Vector3 = coh / float(coh_count)
			var coh_des: Vector3 = centroid - pi
			if coh_des.length_squared() > 0.000001:
				coh_des = coh_des.normalized() * _FLOCK_SPEED_MAX
				steer += _flock_limit(coh_des - vi, _FLOCK_MAX_FORCE) * _FLOCK_W_COHESION
		steer += _flock_boundary_force(pi) * _FLOCK_W_BOUNDARY
		# Coordinated bank — a uniform cross-wind perpendicular to heading (same sense for every bird).
		var heading: Vector3 = vi.normalized()
		var turn: Vector3 = Vector3(-heading.z, 0.0, heading.x)
		if turn.length_squared() > 0.000001:
			steer += turn.normalized() * _FLOCK_SPEED_MAX * _FLOCK_W_SWIRL
		# Roost pull — a faint pull toward the home point keeps the flock one body.
		var to_home: Vector3 = -pi
		if to_home.length() > 0.55:
			steer += to_home.normalized() * _FLOCK_SPEED_MAX * _FLOCK_W_HOME
		new_acc[i] = _flock_limit(steer, _FLOCK_MAX_FORCE)
	for i2: int in range(n):
		var v: Vector3 = _flock_vel[i2] + new_acc[i2] * _FLOCK_DT
		v = _flock_clamp_speed(v)
		_flock_vel[i2] = v
		_flock_pos[i2] = _flock_pos[i2] + v * _FLOCK_DT
		_flock_acc[i2] = new_acc[i2]


## Smooth inward push that grows as an agent nears (or passes) a wall of the bounded volume.
func _flock_boundary_force(p: Vector3) -> Vector3:
	var f: Vector3 = Vector3.ZERO
	var margin: float = 0.30
	f.x = _flock_axis_turnback(p.x, _FLOCK_BOX_HALF.x, margin)
	f.y = _flock_axis_turnback(p.y, _FLOCK_BOX_HALF.y, margin)
	f.z = _flock_axis_turnback(p.z, _FLOCK_BOX_HALF.z, margin)
	return f


## Per-axis turn-back: 0 in the safe core, ramps to ±SPEED_MAX as |coord| approaches the half-extent.
func _flock_axis_turnback(coord: float, half: float, margin: float) -> float:
	var inner: float = half - margin
	if absf(coord) <= inner:
		return 0.0
	var over: float = (absf(coord) - inner) / margin
	var mag: float = clampf(over, 0.0, 1.6) * _FLOCK_SPEED_MAX
	return -signf(coord) * mag


func _flock_clamp_speed(v: Vector3) -> Vector3:
	var s: float = v.length()
	if s < 0.000001:
		return Vector3(_FLOCK_SPEED_MIN, 0.0, 0.0)
	if s < _FLOCK_SPEED_MIN:
		return v / s * _FLOCK_SPEED_MIN
	if s > _FLOCK_SPEED_MAX:
		return v / s * _FLOCK_SPEED_MAX
	return v


func _flock_limit(v: Vector3, m: float) -> Vector3:
	var s: float = v.length()
	if s > m and s > 0.000001:
		return v / s * m
	return v


## Pick the leading-edge birds (top fraction by projection along the mean flight direction). Returns a
## parallel Array[bool]. Deterministic — no randomness (a selection by score).
func _flock_pick_leaders(n: int) -> Array[bool]:
	var mean_vel: Vector3 = Vector3.ZERO
	for v: Vector3 in _flock_vel:
		mean_vel += v
	if mean_vel.length_squared() > 0.000001:
		mean_vel = mean_vel.normalized()
	else:
		mean_vel = Vector3(0.0, 0.0, -1.0)
	var flock_centre: Vector3 = Vector3.ZERO
	for p: Vector3 in _flock_pos:
		flock_centre += p
	flock_centre /= float(maxi(n, 1))
	var projs: Array[float] = []
	projs.resize(n)
	for i: int in range(n):
		projs[i] = (_flock_pos[i] - flock_centre).dot(mean_vel)
	var k: int = maxi(1, int(round(float(n) * _FLOCK_LEADER_FRACTION)))
	var is_leader: Array[bool] = []
	is_leader.resize(n)
	for i2: int in range(n):
		is_leader[i2] = false
	for _pick: int in range(k):
		var best_i: int = -1
		var best_v: float = -1.0e20
		for i3: int in range(n):
			if is_leader[i3]:
				continue
			if projs[i3] > best_v:
				best_v = projs[i3]
				best_i = i3
		if best_i >= 0:
			is_leader[best_i] = true
	return is_leader


## Build ONE stylised bird in local space (nose at -Z, wings on X, up +Y) as two raw triangle soups — a
## body part and a wing part — each a flat list of verts + parallel flat normals (no UVs). Returns a
## Dictionary of the four PackedVector3Arrays.
func _flock_build_bird_parts() -> Dictionary:
	var body_v := PackedVector3Array()
	var body_n := PackedVector3Array()
	var wing_v := PackedVector3Array()
	var wing_n := PackedVector3Array()

	var hl: float = _FLOCK_BIRD_LEN * 0.5
	var bw: float = _FLOCK_BIRD_LEN * 0.12
	var bh: float = _FLOCK_BIRD_LEN * 0.10

	var nose: Vector3 = Vector3(0.0, 0.0, -hl)
	var tail_top: Vector3 = Vector3(0.0, bh * 0.4, hl)
	var tail_bot: Vector3 = Vector3(0.0, -bh * 0.5, hl)
	var mz: float = -hl * 0.35
	var ml: Vector3 = Vector3(-bw, 0.0, mz)
	var mr: Vector3 = Vector3(bw, 0.0, mz)
	var mt: Vector3 = Vector3(0.0, bh, mz)
	var mb: Vector3 = Vector3(0.0, -bh, mz)

	# Nose cone (4 tris).
	_cs_soup_tri(body_v, body_n, nose, mr, mt)
	_cs_soup_tri(body_v, body_n, nose, mt, ml)
	_cs_soup_tri(body_v, body_n, nose, ml, mb)
	_cs_soup_tri(body_v, body_n, nose, mb, mr)
	# Tail cones (4 tris).
	_cs_soup_tri(body_v, body_n, tail_top, mt, mr)
	_cs_soup_tri(body_v, body_n, tail_top, ml, mt)
	_cs_soup_tri(body_v, body_n, tail_bot, mr, mb)
	_cs_soup_tri(body_v, body_n, tail_bot, mb, ml)
	# Close the tail edge (2 tris).
	_cs_soup_tri(body_v, body_n, tail_top, mr, tail_bot)
	_cs_soup_tri(body_v, body_n, tail_top, tail_bot, ml)
	# Forked tail fan (2 tris).
	var fan_l: Vector3 = Vector3(-bw * 1.6, 0.0, hl + _FLOCK_BIRD_LEN * 0.18)
	var fan_r: Vector3 = Vector3(bw * 1.6, 0.0, hl + _FLOCK_BIRD_LEN * 0.18)
	_cs_soup_tri(body_v, body_n, tail_bot, fan_l, fan_r)
	_cs_soup_tri(body_v, body_n, tail_top, fan_r, fan_l)

	# Wings — two swept-back drooped delta planes, each double-faced.
	var span: float = _FLOCK_WING_SPAN * 0.5
	var shoulder_z: float = mz
	var sweep_z: float = hl * 0.62
	var droop: float = -bh * 0.55
	var chord_z: float = _FLOCK_BIRD_LEN * 0.30
	var r_root_f: Vector3 = Vector3(bw * 0.6, bh * 0.15, shoulder_z - chord_z * 0.3)
	var r_root_b: Vector3 = Vector3(bw * 0.6, bh * 0.05, shoulder_z + chord_z * 0.7)
	var r_tip: Vector3 = Vector3(span, droop, sweep_z)
	_flock_wing_quad(wing_v, wing_n, r_root_f, r_root_b, r_tip)
	var l_root_f: Vector3 = Vector3(-bw * 0.6, bh * 0.15, shoulder_z - chord_z * 0.3)
	var l_root_b: Vector3 = Vector3(-bw * 0.6, bh * 0.05, shoulder_z + chord_z * 0.7)
	var l_tip: Vector3 = Vector3(-span, droop, sweep_z)
	_flock_wing_quad(wing_v, wing_n, l_root_b, l_root_f, l_tip)

	return {"body_v": body_v, "body_n": body_n, "wing_v": wing_v, "wing_n": wing_n}


## Append a double-faced triangular wing (root-front, root-back, tip) to a soup, both windings so the thin
## plane shows from above and below.
func _flock_wing_quad(verts: PackedVector3Array, norms: PackedVector3Array,
		root_f: Vector3, root_b: Vector3, tip: Vector3) -> void:
	_cs_soup_tri(verts, norms, root_f, root_b, tip)
	_cs_soup_tri(verts, norms, root_f, tip, root_b)


# =============================================================================
# MODE: anttrail — a REAL ANT COLONY OPTIMIZATION trail, frozen (trial v2)
#
# The genuine algorithm (elitist Ant System / stigmergy, the load-bearing core):
#   A graph is laid on a gentle analytic terrain: a NEST node (west), a FOOD node (east), and
#   intermediate nodes, connected to their K nearest neighbours into a sparse graph (real choices, not a
#   complete graph). Pheromone starts uniform. For ~64 ITERATIONS, each iteration releases ANTS that walk
#   nest->food, at each node choosing the next edge with probability proportional to pheromone^alpha *
#   (1/length)^beta (preferring unvisited), via roulette-wheel selection on the seeded RNG; a successful
#   ant deposits Q/tour_length on its tour edges. The single global-best tour also deposits, weighted by
#   ACO_ELITE (elitist reinforcement → the genuine shortest path accumulates dominant pheromone).
#   Pheromone evaporates by RHO each iteration (with a tiny floor). We FREEZE the final pheromone field:
#   every edge becomes a draped tube whose radius + glow scale with pheromone — the emerged shortest path
#   (the best tour) blazes thick + glowing, the alternatives are thin earthy ghosts — and a COLUMN of ants
#   marches the winning route, each oriented to the trail by a Basis. complexity scales the node count.
#   Ants / trails / nodes are MorphoPrimitive surfaces merged into a handful of ArrayMeshes (no node-per-
#   ant). pow() — NOT powf — drives the alpha/beta exponents (Godot 4.6 has no powf).
# =============================================================================

const _ANT_SPAN: float = 2.6
const _ANT_TERRAIN_AMP: float = 0.16
const _ANT_TILT_DEG: float = 10.0
const _ANT_ALPHA: float = 1.0
const _ANT_BETA: float = 3.2
const _ANT_RHO: float = 0.12
const _ANT_Q: float = 1.0
const _ANT_ITERATIONS: int = 64
const _ANT_ANTS: int = 24
const _ANT_TAU0: float = 0.10
const _ANT_MAX_HOPS: int = 40
const _ANT_ELITE: float = 6.0
const _ANT_TRAIL_MIN_R: float = 0.004
const _ANT_TRAIL_MAX_R: float = 0.048
const _ANT_WEAK_MAX_R: float = 0.013
const _ANT_LENGTH: float = 0.150
const _ANT_SPACING: float = 0.190
const _ANT_TARGET_SPAN: float = 2.6

var _ant_nodes: Array[Vector3] = []
var _ant_node_kind: Array[int] = []          # 0 = intermediate, 1 = nest, 2 = food
var _ant_nest_idx: int = 0
var _ant_food_idx: Array[int] = []
var _ant_edges: Array[Vector2i] = []
var _ant_edge_len: Array[float] = []
var _ant_adj: Array = []                       # _ant_adj[i] = Array[int] of edge indices
var _ant_pher: Array[float] = []
var _ant_best_path: Array[int] = []
var _ant_best_len: float = INF


func _build_anttrail() -> void:
	# Reset graph state (these are instance vars, so a rebuild must clear them).
	_ant_nodes = []
	_ant_node_kind = []
	_ant_food_idx = []
	_ant_edges = []
	_ant_edge_len = []
	_ant_adj = []
	_ant_pher = []
	_ant_best_path = []
	_ant_best_len = INF
	_ant_nest_idx = 0

	_ant_build_graph()
	_ant_run_aco()

	# Centre the network on its planar mean, then tip it toward the +X/+Z camera.
	var centroid := Vector3.ZERO
	for p: Vector3 in _ant_nodes:
		centroid += p
	centroid /= float(maxi(_ant_nodes.size(), 1))
	var tilt := Basis().rotated(Vector3(1.0, 0.0, -1.0).normalized(), deg_to_rad(_ANT_TILT_DEG))
	var colony := Node3D.new()
	colony.name = "Colony"
	colony.basis = tilt
	colony.position = -(tilt * Vector3(centroid.x, 0.0, centroid.z))
	add_child(colony)

	var mat_ant := _cs_body_mat(color_a)
	var mat_earth := _cs_secondary_mat(color_b)
	var mat_glow := _cs_glow_mat(accent, 3.0)
	mat_glow.vertex_color_use_as_albedo = true
	var mat_glow_weak := _cs_secondary_mat(color_b)
	mat_glow_weak.vertex_color_use_as_albedo = true

	_ant_build_terrain(colony, mat_earth)
	_ant_build_trails(colony, mat_glow, mat_glow_weak)
	_ant_build_nodes(colony, mat_earth, mat_glow)
	_ant_build_marching_ants(colony, mat_ant)

	_cs_settle(colony, maxf(_ANT_TARGET_SPAN * (sculpt_height / 1.8), 0.4), maxf(sculpt_width, 0.2), false)


## Smooth, low analytic terrain height at planar (x, z). A couple of sine lobes (deterministic, no noise).
func _ant_terrain_h(x: float, z: float) -> float:
	var u: float = x / _ANT_SPAN
	var v: float = z / _ANT_SPAN
	return _ANT_TERRAIN_AMP * (
		0.6 * sin(u * 3.1 + 0.7) * cos(v * 2.4 - 0.3)
		+ 0.4 * sin((u + v) * 2.0 + 1.4))


func _ant_on_terrain(x: float, z: float) -> Vector3:
	return Vector3(x, _ant_terrain_h(x, z), z)


## Lay out nest + food + intermediate nodes on the terrain and connect near neighbours into a sparse
## graph. complexity scales the node total.
func _ant_build_graph() -> void:
	var node_total: int = clampi(9 + complexity, 11, 16)
	var half: float = _ANT_SPAN * 0.5
	# NEST — west.
	_ant_add_node(Vector2(-half * 0.82, -half * 0.18), 1)
	_ant_nest_idx = 0
	# FOOD — east.
	_ant_add_node(Vector2(half * 0.82, half * 0.22), 2)
	_ant_food_idx.append(1)
	# INTERMEDIATE — jittered, rejecting too-close candidates.
	var want: int = node_total - 2
	var placed: int = 0
	var attempts: int = 0
	var min_sep: float = _ANT_SPAN * 0.20
	while placed < want and attempts < 400:
		attempts += 1
		var px: float = _rng.randf_range(-half * 0.92, half * 0.92)
		var pz: float = _rng.randf_range(-half * 0.92, half * 0.92)
		var cand: Vector2 = Vector2(px, pz)
		var ok: bool = true
		for existing: Vector3 in _ant_nodes:
			if Vector2(existing.x, existing.z).distance_to(cand) < min_sep:
				ok = false
				break
		if not ok:
			continue
		_ant_add_node(cand, 0)
		placed += 1
	# EDGES — connect each node to its K nearest neighbours (sparse so the ACO has real choices).
	var k_near: int = 4
	var n: int = _ant_nodes.size()
	var seen: Dictionary = {}
	for i: int in range(n):
		var dists: Array = []
		for j: int in range(n):
			if j == i:
				continue
			dists.append(Vector2i(j, int(round(_ant_nodes[i].distance_to(_ant_nodes[j]) * 10000.0))))
		dists.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y)
		var added: int = 0
		for entry: Vector2i in dists:
			if added >= k_near:
				break
			var j2: int = entry.x
			var a_idx: int = mini(i, j2)
			var b_idx: int = maxi(i, j2)
			var key: int = a_idx * 1000 + b_idx
			if seen.has(key):
				added += 1
				continue
			seen[key] = true
			_ant_add_edge(a_idx, b_idx)
			added += 1
	# Guard reachability nest -> food.
	_ant_ensure_reachable(_ant_nest_idx, _ant_food_idx[0])
	# Initialise pheromone uniformly.
	_ant_pher.resize(_ant_edges.size())
	for ei: int in range(_ant_edges.size()):
		_ant_pher[ei] = _ANT_TAU0


func _ant_add_node(planar: Vector2, kind: int) -> void:
	_ant_nodes.append(_ant_on_terrain(planar.x, planar.y))
	_ant_node_kind.append(kind)
	_ant_adj.append([] as Array[int])


func _ant_add_edge(a: int, b: int) -> void:
	var ei: int = _ant_edges.size()
	_ant_edges.append(Vector2i(a, b))
	_ant_edge_len.append(maxf(_ant_nodes[a].distance_to(_ant_nodes[b]), 0.0001))
	(_ant_adj[a] as Array[int]).append(ei)
	(_ant_adj[b] as Array[int]).append(ei)


## BFS check that `goal` is reachable from `start`; if not, bridge the goal to the nearest reachable node.
func _ant_ensure_reachable(start: int, goal: int) -> void:
	var comp: Dictionary = _ant_component_of(start)
	if comp.has(goal):
		return
	var best_j: int = -1
	var best_d: float = INF
	for j: int in comp.keys():
		var d: float = _ant_nodes[goal].distance_to(_ant_nodes[j])
		if d < best_d:
			best_d = d
			best_j = j
	if best_j >= 0:
		_ant_add_edge(mini(best_j, goal), maxi(best_j, goal))


func _ant_component_of(start: int) -> Dictionary:
	var seen: Dictionary = {start: true}
	var stack: Array[int] = [start]
	while not stack.is_empty():
		var cur: int = stack.pop_back()
		for ei: int in (_ant_adj[cur] as Array[int]):
			var e: Vector2i = _ant_edges[ei]
			var nxt: int = e.y if e.x == cur else e.x
			if not seen.has(nxt):
				seen[nxt] = true
				stack.append(nxt)
	return seen


## Run ACO for _ANT_ITERATIONS. Each iteration: ants walk nest->food by pheromone^alpha*(1/len)^beta,
## deposit Q/len on success; the global-best tour deposits ELITE-weighted; pheromone evaporates by RHO.
func _ant_run_aco() -> void:
	var food: int = _ant_food_idx[0]
	for _it: int in range(_ANT_ITERATIONS):
		var deposit: Array[float] = []
		deposit.resize(_ant_edges.size())
		for di: int in range(_ant_edges.size()):
			deposit[di] = 0.0
		for _ant: int in range(_ANT_ANTS):
			var walk: Array[int] = _ant_walk(_ant_nest_idx, food)
			if walk.is_empty():
				continue
			var tour_len: float = _ant_path_length(walk)
			if tour_len <= 0.0:
				continue
			if tour_len < _ant_best_len:
				_ant_best_len = tour_len
				_ant_best_path = walk.duplicate()
			var add: float = _ANT_Q / tour_len
			for hi: int in range(walk.size() - 1):
				var ei: int = _ant_edge_between(walk[hi], walk[hi + 1])
				if ei >= 0:
					deposit[ei] += add
		# Elitist reinforcement of the global best.
		if _ant_best_path.size() >= 2 and _ant_best_len > 0.0:
			var elite_add: float = _ANT_ELITE * _ANT_Q / _ant_best_len
			for hi2: int in range(_ant_best_path.size() - 1):
				var eei: int = _ant_edge_between(_ant_best_path[hi2], _ant_best_path[hi2 + 1])
				if eei >= 0:
					deposit[eei] += elite_add
		# Evaporate, then deposit.
		for ei2: int in range(_ant_edges.size()):
			_ant_pher[ei2] = _ant_pher[ei2] * (1.0 - _ANT_RHO) + deposit[ei2]
			_ant_pher[ei2] = maxf(_ant_pher[ei2], _ANT_TAU0 * 0.05)


## One ant's probabilistic walk start->goal: pick an outgoing edge by pheromone^alpha*(1/len)^beta over
## unvisited neighbours (roulette wheel on the seeded RNG). Returns the node path, or [] on failure.
func _ant_walk(start: int, goal: int) -> Array[int]:
	var path: Array[int] = [start]
	var visited: Dictionary = {start: true}
	var current: int = start
	var hops: int = 0
	while current != goal and hops < _ANT_MAX_HOPS:
		hops += 1
		var cand_nodes: Array[int] = []
		var weights: Array[float] = []
		var wsum: float = 0.0
		for ei: int in (_ant_adj[current] as Array[int]):
			var e: Vector2i = _ant_edges[ei]
			var nxt: int = e.y if e.x == current else e.x
			if visited.has(nxt):
				continue
			var tau: float = pow(_ant_pher[ei], _ANT_ALPHA)
			var eta: float = pow(1.0 / _ant_edge_len[ei], _ANT_BETA)
			var w: float = tau * eta
			cand_nodes.append(nxt)
			weights.append(w)
			wsum += w
		if cand_nodes.is_empty() or wsum <= 0.0:
			return [] as Array[int]
		var r: float = _rng.randf() * wsum
		var pick: int = cand_nodes.size() - 1
		var acc: float = 0.0
		for ci: int in range(cand_nodes.size()):
			acc += weights[ci]
			if r <= acc:
				pick = ci
				break
		var chosen: int = cand_nodes[pick]
		path.append(chosen)
		visited[chosen] = true
		current = chosen
	if current != goal:
		return [] as Array[int]
	return path


func _ant_path_length(path: Array[int]) -> float:
	var total: float = 0.0
	for hi: int in range(path.size() - 1):
		var ei: int = _ant_edge_between(path[hi], path[hi + 1])
		if ei < 0:
			return -1.0
		total += _ant_edge_len[ei]
	return total


## Edge index joining nodes a and b, or -1 if none.
func _ant_edge_between(a: int, b: int) -> int:
	var lo: int = mini(a, b)
	var hi: int = maxi(a, b)
	for ei: int in (_ant_adj[a] as Array[int]):
		var e: Vector2i = _ant_edges[ei]
		if e.x == lo and e.y == hi:
			return ei
	return -1


## Normalised pheromone strength of an edge in [0, 1] relative to the strongest edge.
func _ant_edge_strength(ei: int) -> float:
	var pmax: float = 0.0
	for v: float in _ant_pher:
		pmax = maxf(pmax, v)
	if pmax <= 0.0:
		return 0.0
	return clampf(_ant_pher[ei] / pmax, 0.0, 1.0)


## Hash-set of edge indices that lie on the emerged best path (so trail glow + ant column coincide).
func _ant_best_path_edge_set() -> Dictionary:
	var s: Dictionary = {}
	for hi: int in range(_ant_best_path.size() - 1):
		var ei: int = _ant_edge_between(_ant_best_path[hi], _ant_best_path[hi + 1])
		if ei >= 0:
			s[ei] = true
	return s


## A gentle terrain patch under the network (subdivided grid lifted by the height field). One ArrayMesh.
func _ant_build_terrain(parent: Node3D, mat: Material) -> void:
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var res: int = 26
	var half: float = _ANT_SPAN * 0.62
	var step: float = (half * 2.0) / float(res)
	for ix: int in range(res):
		for iz: int in range(res):
			var x0: float = -half + float(ix) * step
			var z0: float = -half + float(iz) * step
			var x1: float = x0 + step
			var z1: float = z0 + step
			var p00: Vector3 = _ant_on_terrain(x0, z0)
			var p10: Vector3 = _ant_on_terrain(x1, z0)
			var p11: Vector3 = _ant_on_terrain(x1, z1)
			var p01: Vector3 = _ant_on_terrain(x0, z1)
			_ant_tri(st, p00, p01, p11)
			_ant_tri(st, p00, p11, p10)
	st.generate_normals()
	_cs_commit_batch(parent, st, mat, "Terrain", false)


func _ant_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var n: Vector3 = (b - a).cross(c - a)
	if n.length_squared() > 0.000001:
		n = n.normalized()
	else:
		n = Vector3.UP
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(b)
	st.set_normal(n); st.add_vertex(c)


## Render every edge as a draped tube whose radius + glow scale with final pheromone. The emerged shortest
## path (best tour) blazes (accent glow, vertex-coloured by strength); every other edge is a thin earthy
## ghost. Two ArrayMeshes (strong / weak).
func _ant_build_trails(parent: Node3D, mat_glow: Material, mat_weak: Material) -> void:
	var best_edges: Dictionary = _ant_best_path_edge_set()
	var st_strong := SurfaceTool.new(); st_strong.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_weak := SurfaceTool.new(); st_weak.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ei: int in range(_ant_edges.size()):
		var e: Vector2i = _ant_edges[ei]
		var s: float = _ant_edge_strength(ei)
		var is_dominant: bool = best_edges.has(ei)
		var radius: float
		if is_dominant:
			radius = lerpf(_ANT_TRAIL_MAX_R * 0.82, _ANT_TRAIL_MAX_R, clampf(s, 0.0, 1.0))
		else:
			radius = lerpf(_ANT_TRAIL_MIN_R, _ANT_WEAK_MAX_R, pow(clampf(s, 0.0, 1.0), 0.8))
		var a: Vector3 = _ant_nodes[e.x]
		var b: Vector3 = _ant_nodes[e.y]
		var samples: int = 7
		var positions: Array[Vector3] = []
		var radii: Array[float] = []
		for si: int in range(samples):
			var t: float = float(si) / float(samples - 1)
			var planar: Vector3 = a.lerp(b, t)
			var on_ground: Vector3 = _ant_on_terrain(planar.x, planar.z)
			on_ground.y += radius * 0.6
			positions.append(on_ground)
			var end_taper: float = lerpf(0.7, 1.0, sin(t * PI))
			radii.append(radius * end_taper)
		var tube: Mesh = MorphoPrimitive.multi_tube(positions, radii, 8)
		if tube == null:
			continue
		if is_dominant:
			var col_s: Color = accent * clampf(0.9 + s * 0.5, 0.0, 1.4)
			col_s.a = 1.0
			_ant_merge_coloured(st_strong, tube, col_s)
		else:
			var blend: float = clampf(s, 0.0, 1.0)
			var col_w: Color = color_b.lerp(accent, blend * 0.4)
			col_w.a = 1.0
			_ant_merge_coloured(st_weak, tube, col_w)
	_cs_commit_batch(parent, st_weak, mat_weak, "TrailsWeak", false)
	_cs_commit_batch(parent, st_strong, mat_glow, "TrailsDominant", false)


## Merge a mesh's surface-0 triangles into `st`, untransformed, tagging each vertex with `col`. Handles
## non-indexed and indexed (Variant-coerced like _cs_merge_into).
func _ant_merge_coloured(st: SurfaceTool, mesh: Mesh, col: Color) -> void:
	if mesh == null or mesh.get_surface_count() == 0:
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
	if indices.size() > 0:
		for i: int in range(indices.size()):
			var idx: int = indices[i]
			st.set_color(col)
			st.set_normal(norms[idx] if idx < norms.size() else Vector3.UP)
			st.add_vertex(verts[idx])
	else:
		for i2: int in range(verts.size()):
			st.set_color(col)
			st.set_normal(norms[i2] if i2 < norms.size() else Vector3.UP)
			st.add_vertex(verts[i2])


## Build node geometry: intermediate = small earth mounds (revolution); nest = larger mound with a crater
## + glow ring; food = a cluster of glowing accent spheres. Earth batched into one mesh, glow into another.
func _ant_build_nodes(parent: Node3D, mat_earth: Material, mat_glow: Material) -> void:
	var st_earth := SurfaceTool.new(); st_earth.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_glow := SurfaceTool.new(); st_glow.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in range(_ant_nodes.size()):
		var p: Vector3 = _ant_nodes[i]
		var kind: int = _ant_node_kind[i]
		if kind == 2:
			# FOOD — cluster of small glowing spheres.
			var cluster: int = 7
			var crumb_r: float = 0.05
			for ci: int in range(cluster):
				var ang: float = TAU * float(ci) / float(cluster) + 0.4
				var rad: float = 0.0 if ci == 0 else crumb_r * 1.6
				var off: Vector3 = Vector3(cos(ang) * rad, crumb_r * (0.6 if ci == 0 else 0.3), sin(ang) * rad)
				var sph: Mesh = MorphoPrimitive.sphere(crumb_r * (1.2 if ci == 0 else 0.85), 10, 6)
				_cs_merge_into(st_glow, sph, Transform3D(Basis.IDENTITY, p + off))
			continue
		if kind == 1:
			# NEST — larger mound with a crater (revolution profile dips at the axis).
			var nest_r: float = 0.20
			var nest_h: float = 0.13
			var profile: Array[Vector2] = [
				Vector2(0.0, nest_h * 0.18),
				Vector2(nest_r * 0.30, nest_h * 0.10),
				Vector2(nest_r * 0.55, nest_h * 0.74),
				Vector2(nest_r * 0.78, nest_h * 1.00),
				Vector2(nest_r * 1.00, nest_h * 0.46),
				Vector2(nest_r * 1.14, 0.0),
			]
			_cs_merge_into(st_earth, MorphoPrimitive.revolution(profile, 22), Transform3D(Basis.IDENTITY, p))
			# Glow ring at the mouth.
			var ring_n: int = 8
			for ri: int in range(ring_n):
				var a2: float = TAU * float(ri) / float(ring_n)
				var rr: float = nest_r * 0.42
				var ringp: Vector3 = p + Vector3(cos(a2) * rr, nest_h * 0.22, sin(a2) * rr)
				_cs_merge_into(st_glow, MorphoPrimitive.sphere(0.018, 8, 5), Transform3D(Basis.IDENTITY, ringp))
			continue
		# INTERMEDIATE — small low earth mound.
		var m_r: float = 0.075
		var m_h: float = 0.045
		var disc: Array[Vector2] = [
			Vector2(0.0, m_h),
			Vector2(m_r * 0.55, m_h * 0.86),
			Vector2(m_r * 0.90, m_h * 0.42),
			Vector2(m_r * 1.05, 0.0),
		]
		_cs_merge_into(st_earth, MorphoPrimitive.revolution(disc, 14), Transform3D(Basis.IDENTITY, p))
	_cs_commit_batch(parent, st_earth, mat_earth, "Mounds", false)
	_cs_commit_batch(parent, st_glow, mat_glow, "NodeGlow", false)


## Build ONE ant in local space (nose at +X), then march a COLUMN of copies along the emerged dominant
## trail, each oriented to the local trail direction by a Basis. All ants baked into a single ArrayMesh.
func _ant_build_marching_ants(parent: Node3D, mat: Material) -> void:
	if _ant_best_path.size() < 2:
		return
	# The polyline of the dominant trail, draped on the terrain, + its cumulative arc length.
	var poly: Array[Vector3] = []
	var dense: int = 10
	for hi: int in range(_ant_best_path.size() - 1):
		var a: Vector3 = _ant_nodes[_ant_best_path[hi]]
		var b: Vector3 = _ant_nodes[_ant_best_path[hi + 1]]
		var seg_start: int = 0 if hi == 0 else 1
		for si: int in range(seg_start, dense + 1):
			var t: float = float(si) / float(dense)
			var planar: Vector3 = a.lerp(b, t)
			var g: Vector3 = _ant_on_terrain(planar.x, planar.z)
			g.y += _ANT_TRAIL_MAX_R * 0.6 + _ANT_LENGTH * 0.18
			poly.append(g)
	var arc: Array[float] = [0.0]
	for pi: int in range(1, poly.size()):
		arc.append(arc[pi - 1] + poly[pi].distance_to(poly[pi - 1]))
	var total_len: float = arc[arc.size() - 1]
	if total_len < _ANT_SPACING:
		return
	# Build the one ant template (raw soup), then bake copies along the trail.
	var tmpl: Array = _ant_build_ant_template()
	var tverts: PackedVector3Array = tmpl[0]
	var tnorms: PackedVector3Array = tmpl[1]
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var margin: float = _ANT_SPACING * 0.9
	var d: float = margin
	while d < total_len - margin:
		var pose: Transform3D = _ant_trail_pose(poly, arc, d)
		_cs_merge_soup(st, tverts, tnorms, pose)
		_agent_count += 1
		d += _ANT_SPACING
	_cs_commit_batch(parent, st, mat, "Ants", false)


## Sample a pose on the trail polyline at arc length `d`. Basis: local +X along the tangent, +Y up.
func _ant_trail_pose(poly: Array[Vector3], arc: Array[float], d: float) -> Transform3D:
	var idx: int = 1
	while idx < arc.size() - 1 and arc[idx] < d:
		idx += 1
	var seg_a: int = idx - 1
	var seg_b: int = idx
	var seg_len: float = maxf(arc[seg_b] - arc[seg_a], 0.0001)
	var local_t: float = clampf((d - arc[seg_a]) / seg_len, 0.0, 1.0)
	var pos: Vector3 = poly[seg_a].lerp(poly[seg_b], local_t)
	var forward: Vector3 = (poly[seg_b] - poly[seg_a])
	forward.y *= 0.3
	if forward.length_squared() < 0.0000001:
		forward = Vector3.RIGHT
	forward = forward.normalized()
	var up: Vector3 = Vector3.UP
	var right: Vector3 = forward.cross(up)
	if right.length_squared() < 0.0000001:
		right = Vector3.FORWARD
	right = right.normalized()
	var true_up: Vector3 = right.cross(forward).normalized()
	# Basis columns: X = forward (ant nose), Y = up, Z = right.
	return Transform3D(Basis(forward, true_up, right), pos)


## Build one ant in local space (nose toward +X, up = +Y) as a raw triangle soup. Three body spheres +
## waist tube + six legs + two antennae. Returns [verts, norms].
func _ant_build_ant_template() -> Array:
	var L: float = _ANT_LENGTH
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var gaster_c := Vector3(-L * 0.32, L * 0.12, 0.0)
	var thorax_c := Vector3(0.0, L * 0.11, 0.0)
	var head_c := Vector3(L * 0.34, L * 0.12, 0.0)
	# Three squashed body spheres.
	_ant_soup_sphere(verts, norms, gaster_c, L * 0.20, Vector3(1.15, 0.92, 1.0))
	_ant_soup_sphere(verts, norms, thorax_c, L * 0.135, Vector3(1.0, 0.95, 0.92))
	_ant_soup_sphere(verts, norms, head_c, L * 0.135, Vector3(0.95, 0.95, 1.0))
	# Waist tube.
	var waist: Mesh = MorphoPrimitive.multi_tube([gaster_c, thorax_c, head_c],
		[L * 0.05, L * 0.06, L * 0.05], 6)
	_ant_soup_append_mesh(verts, norms, waist, Transform3D.IDENTITY)
	# Six legs.
	var leg_thick: float = L * 0.014
	var leg_len: float = L * 0.30
	var side_signs: Array[float] = [1.0, -1.0]
	var leg_fwd: Array[float] = [L * 0.10, 0.0, -L * 0.10]
	for sgn: float in side_signs:
		for fwd_off: float in leg_fwd:
			var hip: Vector3 = thorax_c + Vector3(fwd_off, 0.0, sgn * L * 0.07)
			var dir: Vector3 = Vector3(fwd_off * 0.4, -L * 0.16, sgn * L * 0.22).normalized()
			var foot: Vector3 = hip + dir * leg_len
			_ant_soup_segment_box(verts, norms, hip, foot, leg_thick)
	# Two antennae.
	var ant_thick: float = L * 0.010
	for sgn2: float in side_signs:
		var base: Vector3 = head_c + Vector3(L * 0.08, L * 0.02, sgn2 * L * 0.03)
		var tip: Vector3 = base + Vector3(L * 0.12, L * 0.10, sgn2 * L * 0.05)
		_ant_soup_segment_box(verts, norms, base, tip, ant_thick)
	return [verts, norms]


## Append a sphere (translated + non-uniformly scaled) into a raw soup.
func _ant_soup_sphere(verts: PackedVector3Array, norms: PackedVector3Array,
		centre: Vector3, radius: float, scale: Vector3) -> void:
	var sph: Mesh = MorphoPrimitive.sphere(radius, 10, 6)
	_ant_soup_append_mesh(verts, norms, sph, Transform3D(Basis().scaled(scale), centre))


## Append a thin box spanning start->end (a leg/antenna segment) into the raw soup, Basis-oriented.
func _ant_soup_segment_box(verts: PackedVector3Array, norms: PackedVector3Array,
		start: Vector3, end: Vector3, thick: float) -> void:
	var axis: Vector3 = end - start
	var length: float = axis.length()
	if length < 0.00001:
		return
	var x: Vector3 = axis / length
	var ref: Vector3 = Vector3.UP
	if absf(x.dot(ref)) > 0.95:
		ref = Vector3.RIGHT
	var y: Vector3 = ref.cross(x).normalized()
	var z: Vector3 = x.cross(y).normalized()
	var c: Vector3 = (start + end) * 0.5
	_ant_soup_box(verts, norms, c, x, y, z, length * 0.5, thick, thick)


## Append a generic mesh (surface 0) transformed by xf into the raw soup. Variant-coerced; de-indexes.
func _ant_soup_append_mesh(verts: PackedVector3Array, norms: PackedVector3Array,
		mesh: Mesh, xf: Transform3D) -> void:
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var nb: Basis = xf.basis
	var arrays: Array = mesh.surface_get_arrays(0)
	var v_raw: Variant = arrays[Mesh.ARRAY_VERTEX]
	if not (v_raw is PackedVector3Array):
		return
	var mv: PackedVector3Array = v_raw
	var n_raw: Variant = arrays[Mesh.ARRAY_NORMAL]
	var mn := PackedVector3Array()
	if n_raw is PackedVector3Array:
		mn = n_raw
	var i_raw: Variant = arrays[Mesh.ARRAY_INDEX]
	var mi := PackedInt32Array()
	if i_raw is PackedInt32Array:
		mi = i_raw
	var has_norm: bool = mn.size() == mv.size()
	if mi.size() > 0:
		for k: int in range(mi.size()):
			var idx: int = mi[k]
			verts.append(xf * mv[idx])
			norms.append((nb * mn[idx]).normalized() if has_norm else Vector3.UP)
	else:
		for k2: int in range(mv.size()):
			verts.append(xf * mv[k2])
			norms.append((nb * mn[k2]).normalized() if has_norm else Vector3.UP)


## Append a box (centre c, orthonormal axes, half-extents) into the raw soup.
func _ant_soup_box(verts: PackedVector3Array, norms: PackedVector3Array, c: Vector3,
		x: Vector3, y: Vector3, z: Vector3, hx: float, hy: float, hz: float) -> void:
	var ex: Vector3 = x * hx
	var ey: Vector3 = y * hy
	var ez: Vector3 = z * hz
	var p000: Vector3 = c - ex - ey - ez
	var p100: Vector3 = c + ex - ey - ez
	var p110: Vector3 = c + ex + ey - ez
	var p010: Vector3 = c - ex + ey - ez
	var p001: Vector3 = c - ex - ey + ez
	var p101: Vector3 = c + ex - ey + ez
	var p111: Vector3 = c + ex + ey + ez
	var p011: Vector3 = c - ex + ey + ez
	_ant_soup_quad(verts, norms, p000, p010, p110, p100)
	_ant_soup_quad(verts, norms, p001, p101, p111, p011)
	_ant_soup_quad(verts, norms, p000, p100, p101, p001)
	_ant_soup_quad(verts, norms, p010, p011, p111, p110)
	_ant_soup_quad(verts, norms, p000, p001, p011, p010)
	_ant_soup_quad(verts, norms, p100, p110, p111, p101)


func _ant_soup_quad(verts: PackedVector3Array, norms: PackedVector3Array,
		a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_cs_soup_tri(verts, norms, a, b, c)
	_cs_soup_tri(verts, norms, a, c, d)


# =============================================================================
# MODE: shoal — a REAL VICSEK bait-ball, frozen mid-swirl (trial v3)
#
# The genuine algorithm (Vicsek self-propelled particles, the load-bearing core):
#   N agents live inside a soft confinement sphere, each carrying a position + a unit heading. Every step
#   each agent: (1) averages the headings of all neighbours within radius r (Vicsek alignment, includes
#   self); (2) blends in a tangential SWIRL bias about a swirl axis so the school organises into a
#   rotating ball, not a translating flock; (3) adds a linear inward COHESION pull (a FILLED solid ball,
#   no torus hole) plus a stronger CONFINEMENT steer past the rim; (4) adds a bounded random NOISE vector
#   (the Vicsek noise term eta) from the seeded RNG; (5) renormalises and advances at CONSTANT speed v0,
#   hard-clamped at the shell. After ~300 frames the ROTATIONAL order parameter (mean dot of heading with
#   the local tangential direction) is high — a coherent vortex. We FREEZE: one fish per agent, oriented
#   by a Basis from its heading, with a sparse scatter of gold glint fish. complexity scales the fish
#   count (120..220). ONE fish (tapered ellipsoid body + caudal & dorsal fins) is built once as raw soups
#   and merged transformed per agent into per-material ArrayMeshes.
# =============================================================================

const _SHOAL_CONFINE_RADIUS: float = 1.05
const _SHOAL_NEIGHBOR_RADIUS: float = 0.34
const _SHOAL_NOISE: float = 0.20
const _SHOAL_SPEED: float = 0.020
const _SHOAL_SWIRL_BIAS: float = 0.78
const _SHOAL_CONFINE_PUSH: float = 0.95
const _SHOAL_CONFINE_START: float = 0.78
const _SHOAL_COHESION: float = 0.40
const _SHOAL_STEPS: int = 300
const _SHOAL_FISH_LEN: float = 0.165
const _SHOAL_FISH_GIRTH: float = 0.046
const _SHOAL_BODY_LON: int = 9
const _SHOAL_BODY_LAT: int = 7
const _SHOAL_CENTRE_Y: float = 1.10
const _SHOAL_TARGET_SPAN: float = 2.3

# Captured single-fish geometry (local space, nose toward -Z, up = +Y).
var _shoal_body_v: PackedVector3Array
var _shoal_body_n: PackedVector3Array
var _shoal_fin_v: PackedVector3Array
var _shoal_fin_n: PackedVector3Array


func _build_shoal() -> void:
	_shoal_build_fish_template()

	var n: int = clampi(int(round(lerpf(120.0, 220.0, clampf(float(complexity) / 12.0, 0.0, 1.0)))), 90, 240)
	_agent_count = n

	var sim: Dictionary = _shoal_run_vicsek(n)
	var positions: Array[Vector3] = sim["pos"]
	var headings: Array[Vector3] = sim["head"]

	var root := Node3D.new()
	root.name = "BaitBall"
	root.position = Vector3(0.0, _SHOAL_CENTRE_Y, 0.0)
	add_child(root)

	var mat_body := _cs_body_mat(color_a)
	var mat_belly := _cs_secondary_mat(color_b)
	var mat_glint := _cs_glow_mat(accent, 3.0)

	var body_st := SurfaceTool.new(); body_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var fin_st := SurfaceTool.new(); fin_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var glint_st := SurfaceTool.new(); glint_st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var max_glints: int = int(round(float(n) * 0.05)) + 3
	var glint_count: int = 0

	for i: int in range(n):
		var p: Vector3 = positions[i]
		var h: Vector3 = headings[i]
		var basis: Basis = _cs_basis_from_velocity(h, 0.0)
		var s: float = _rng.randf_range(0.86, 1.12)
		var fish_xform := Transform3D(basis.scaled(Vector3(s, s, s)), p)
		var is_glint: bool = false
		if glint_count < max_glints:
			is_glint = _rng.randf() < 0.045
		if is_glint:
			_cs_merge_soup(glint_st, _shoal_body_v, _shoal_body_n, fish_xform)
			_cs_merge_soup(glint_st, _shoal_fin_v, _shoal_fin_n, fish_xform)
			glint_count += 1
		else:
			_cs_merge_soup(body_st, _shoal_body_v, _shoal_body_n, fish_xform)
			_cs_merge_soup(fin_st, _shoal_fin_v, _shoal_fin_n, fish_xform)

	_cs_commit_batch(root, body_st, mat_body, "BodyBatch", false)
	_cs_commit_batch(root, fin_st, mat_belly, "FinBatch", false)
	_cs_commit_batch(root, glint_st, mat_glint, "GlintBatch", false)

	_cs_settle(root, maxf(_SHOAL_TARGET_SPAN * (sculpt_height / 1.8), 0.4), maxf(sculpt_width, 0.2), false)


## Run the Vicsek model and return frozen poses: {"pos": Array[Vector3], "head": Array[Vector3]}.
func _shoal_run_vicsek(n: int) -> Dictionary:
	var pos: Array[Vector3] = []
	var head: Array[Vector3] = []
	for i: int in range(n):
		pos.append(_shoal_rand_in_ball(_SHOAL_CONFINE_RADIUS * 0.65))
		head.append(_shoal_rand_unit())
	var r2: float = _SHOAL_NEIGHBOR_RADIUS * _SHOAL_NEIGHBOR_RADIUS
	# Global swirl axis, leaning toward the capture camera so the vortex curls around the line of sight.
	var swirl_axis: Vector3 = Vector3(0.50, 0.62, 0.95).normalized()
	for _step: int in range(_SHOAL_STEPS):
		var new_head: Array[Vector3] = []
		new_head.resize(n)
		for i: int in range(n):
			var pi: Vector3 = pos[i]
			# 1. Vicsek alignment: average heading of neighbours within r (includes self).
			var avg: Vector3 = head[i]
			for j: int in range(n):
				if j == i:
					continue
				if pi.distance_squared_to(pos[j]) <= r2:
					avg += head[j]
			if avg.length_squared() > 0.0:
				avg = avg.normalized()
			else:
				avg = head[i]
			# 2. Swirl bias: tangential about the swirl axis through the centre.
			var radial: Vector3 = pi
			var tangent: Vector3 = swirl_axis.cross(radial)
			if tangent.length_squared() > 0.000001:
				tangent = tangent.normalized()
				avg = (avg + tangent * _SHOAL_SWIRL_BIAS).normalized()
			# 3. Cohesion + confinement.
			var dist: float = pi.length()
			if dist > 0.0001:
				var inward: Vector3 = (-pi).normalized()
				avg = (avg + inward * (_SHOAL_COHESION * (dist / _SHOAL_CONFINE_RADIUS)))
				if avg.length_squared() > 0.0:
					avg = avg.normalized()
				if dist > _SHOAL_CONFINE_RADIUS * _SHOAL_CONFINE_START:
					var over: float = clampf((dist - _SHOAL_CONFINE_RADIUS * _SHOAL_CONFINE_START)
						/ (_SHOAL_CONFINE_RADIUS * (1.0 - _SHOAL_CONFINE_START)), 0.0, 1.0)
					avg = (avg + inward * (_SHOAL_CONFINE_PUSH * over)).normalized()
			# 4. Bounded noise term eta.
			var noisy: Vector3 = (avg + _shoal_rand_unit() * _SHOAL_NOISE)
			if noisy.length_squared() > 0.0:
				new_head[i] = noisy.normalized()
			else:
				new_head[i] = avg
		# 5. Advance at constant speed, commit headings.
		for i2: int in range(n):
			head[i2] = new_head[i2]
			var np: Vector3 = pos[i2] + head[i2] * _SHOAL_SPEED
			var d: float = np.length()
			if d > _SHOAL_CONFINE_RADIUS:
				np = np.normalized() * _SHOAL_CONFINE_RADIUS
			pos[i2] = np
	return {"pos": pos, "head": head}


func _shoal_rand_unit() -> Vector3:
	var z: float = _rng.randf_range(-1.0, 1.0)
	var t: float = _rng.randf_range(0.0, TAU)
	var rr: float = sqrt(maxf(1.0 - z * z, 0.0))
	return Vector3(rr * cos(t), rr * sin(t), z)


func _shoal_rand_in_ball(radius: float) -> Vector3:
	var dir: Vector3 = _shoal_rand_unit()
	var rad: float = radius * pow(_rng.randf(), 1.0 / 3.0)
	return dir * rad


## Build ONE fish in local space (nose toward -Z, up +Y): a tapered ellipsoid body + caudal & dorsal fins,
## captured into raw soups (body verts/norms; fin verts/norms). Built via SurfaceTool then captured.
func _shoal_build_fish_template() -> void:
	var body_st := SurfaceTool.new(); body_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half_len: float = _SHOAL_FISH_LEN * 0.5
	var rings: Array = []
	for li: int in range(_SHOAL_BODY_LON + 1):
		var u: float = float(li) / float(_SHOAL_BODY_LON)
		var z: float = lerpf(half_len, -half_len, u)
		var radius: float = _shoal_body_radius(u)
		var ring: Array[Vector3] = []
		for ai: int in range(_SHOAL_BODY_LAT):
			var ang: float = TAU * float(ai) / float(_SHOAL_BODY_LAT)
			var x: float = cos(ang) * radius * 0.78
			var y: float = sin(ang) * radius * 1.06
			ring.append(Vector3(x, y, z))
		rings.append(ring)
	# Weld the nose ring to a point.
	var nose: Vector3 = Vector3(0.0, 0.0, half_len)
	var nose_ring: Array[Vector3] = rings[0] as Array[Vector3]
	for ai: int in range(_SHOAL_BODY_LAT):
		nose_ring[ai] = nose
	# Triangulate consecutive rings.
	for li: int in range(_SHOAL_BODY_LON):
		var ra: Array[Vector3] = rings[li] as Array[Vector3]
		var rb: Array[Vector3] = rings[li + 1] as Array[Vector3]
		for ai: int in range(_SHOAL_BODY_LAT):
			var an: int = (ai + 1) % _SHOAL_BODY_LAT
			_shoal_tri(body_st, ra[ai], rb[ai], ra[an])
			_shoal_tri(body_st, ra[an], rb[ai], rb[an])
	# Close the tail base.
	var tail_centre: Vector3 = Vector3(0.0, 0.0, -half_len)
	var tail_ring: Array[Vector3] = rings[_SHOAL_BODY_LON] as Array[Vector3]
	for ai: int in range(_SHOAL_BODY_LAT):
		var an: int = (ai + 1) % _SHOAL_BODY_LAT
		_shoal_tri(body_st, tail_ring[ai], tail_ring[an], tail_centre)
	body_st.generate_normals()
	var body_cap: Array = _cs_capture_soup(body_st.commit())
	_shoal_body_v = body_cap[0]
	_shoal_body_n = body_cap[1]

	# Fins — caudal (tail) + dorsal, into one belly-material soup.
	var fin_st := SurfaceTool.new(); fin_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tail_base_z: float = -half_len
	var tail_tip_z: float = -half_len - _SHOAL_FISH_LEN * 0.16
	var tail_spread: float = _SHOAL_FISH_GIRTH * 0.62
	_shoal_tri(fin_st,
		Vector3(0.0, _SHOAL_FISH_GIRTH * 0.18, tail_base_z),
		Vector3(0.0, 0.0, tail_base_z),
		Vector3(0.0, tail_spread, tail_tip_z))
	_shoal_tri(fin_st,
		Vector3(0.0, 0.0, tail_base_z),
		Vector3(0.0, -_SHOAL_FISH_GIRTH * 0.18, tail_base_z),
		Vector3(0.0, -tail_spread, tail_tip_z))
	_shoal_tri(fin_st,
		Vector3(0.0, _SHOAL_FISH_GIRTH * 0.18, tail_base_z),
		Vector3(0.0, tail_spread, tail_tip_z),
		Vector3(0.0, -tail_spread, tail_tip_z))
	var dor_front_z: float = half_len * 0.10
	var dor_back_z: float = -half_len * 0.55
	var dor_base_y: float = _shoal_body_radius(0.42) * 1.02
	var dor_height: float = _SHOAL_FISH_GIRTH * 0.50
	_shoal_tri(fin_st,
		Vector3(0.0, dor_base_y, dor_front_z),
		Vector3(0.0, dor_base_y, dor_back_z),
		Vector3(0.0, dor_base_y + dor_height, (dor_front_z + dor_back_z) * 0.5))
	fin_st.generate_normals()
	var fin_cap: Array = _cs_capture_soup(fin_st.commit())
	_shoal_fin_v = fin_cap[0]
	_shoal_fin_n = fin_cap[1]


## Fish silhouette radius along the body, u in [0,1] (nose->tail base).
func _shoal_body_radius(u: float) -> float:
	var uu: float = clampf(u, 0.0, 1.0)
	var swell: float = sin(pow(uu, 0.62) * PI)
	var taper: float = lerpf(1.0, 0.18, smoothstep(0.30, 1.0, uu))
	return _SHOAL_FISH_GIRTH * maxf(swell * taper, 0.0) + _SHOAL_FISH_GIRTH * 0.05 * (1.0 - uu)


func _shoal_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var n: Vector3 = (b - a).cross(c - a)
	if n.length_squared() > 0.0:
		n = n.normalized()
	else:
		n = Vector3.UP
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(b)
	st.set_normal(n); st.add_vertex(c)


# =============================================================================
# MODE: pso — a REAL PARTICLE SWARM OPTIMIZATION funnel, frozen (trial v4)
#
# The genuine algorithm (canonical PSO, the load-bearing core):
#   Particles search a 3D fitness LANDSCAPE (a sum of Gaussian peaks with one dominant global optimum +
#   decoys that make the early exploration real). Each carries a planar position + velocity in SEARCH
#   space; Y is read from the field. Every step every particle does the canonical update
#     v = w*v + c1*r1*(pbest - x) + c2*r2*(gbest - x)   (per-axis clamped, walls reflect)
#     x = x + v
#   with inertia w, cognitive c1, social c2, and r1/r2 BAKED from the seeded RNG (so the WHOLE run is
#   deterministic, not just the init). We FREEZE at FREEZE_STEP — a dramatic partly-collapsed funnel, not
#   a singular dot. We render the snapshot: motes (translated copies of a canonical sphere) batched into
#   one ArrayMesh; velocity-streak comet-tails (a canonical tapered multi_tube re-oriented per particle by
#   a Basis from its world velocity) into another; a glowing magenta global-best ATTRACTOR crowning the
#   funnel on its peak; the fitness landscape as a low-relief heightfield underneath. complexity scales
#   the particle count (90..160). pow() — NOT powf — is used for the field exponents (Godot 4.6 has no
#   powf; exp() drives the Gaussians, pow() the taper curves).
# =============================================================================

const _PSO_PARTICLE_MIN: int = 90
const _PSO_PARTICLE_MAX: int = 160
const _PSO_FREEZE_STEP: int = 5
const _PSO_INERTIA_W: float = 0.66
const _PSO_COGNITIVE_C1: float = 1.05
const _PSO_SOCIAL_C2: float = 1.25
const _PSO_VEL_CLAMP: float = 0.13
const _PSO_DOMAIN_HALF: float = 1.20
const _PSO_FIELD_HEIGHT: float = 0.62
const _PSO_SWARM_SPAN: float = 2.5
const _PSO_SWARM_LIFT: float = 1.10
const _PSO_MOTE_RADIUS: float = 0.028
const _PSO_STREAK_MAX_LEN: float = 0.34
const _PSO_STREAK_SEGMENTS: int = 6
const _PSO_TARGET_SPAN: float = 2.5

var _pso_world_scale: float = 1.0
var _pso_gbest_search: Vector3 = Vector3.ZERO
var _pso_peaks: Array[Vector4] = [
	Vector4(0.34, -0.28, 1.00, 0.46),    # GLOBAL best — the attractor
	Vector4(-0.62, 0.55, 0.58, 0.40),    # decoy ridge
	Vector4(0.70, 0.66, 0.47, 0.34),     # decoy
	Vector4(-0.45, -0.70, 0.42, 0.30),   # decoy
]


func _build_pso() -> void:
	_pso_world_scale = _PSO_SWARM_SPAN / (_PSO_DOMAIN_HALF * 2.0)
	_pso_gbest_search = Vector3.ZERO

	var n: int = clampi(int(round(lerpf(
		float(_PSO_PARTICLE_MIN), float(_PSO_PARTICLE_MAX), clampf(float(complexity) / 12.0, 0.0, 1.0)))),
		_PSO_PARTICLE_MIN, _PSO_PARTICLE_MAX)
	_agent_count = n

	var swarm := Node3D.new()
	swarm.name = "Swarm"
	add_child(swarm)

	var frozen: Dictionary = _pso_run(n)
	var pos: Array[Vector3] = frozen["pos"]
	var vel: Array[Vector3] = frozen["vel"]
	var best: Array = frozen["best"]

	var mat_mote := _cs_mote_mat(color_a, 1.2)
	var mat_streak := _cs_secondary_mat(color_b)
	var mat_attractor := _cs_glow_mat(accent, 5.0)
	var mat_terrain := _cs_secondary_mat(color_b.lerp(Color(0.16, 0.18, 0.23), 0.6))

	_pso_build_terrain(swarm, mat_terrain)
	_pso_build_attractor(swarm, mat_attractor)
	_pso_build_swarm_meshes(swarm, pos, vel, best, mat_mote, mat_streak)

	_cs_settle(swarm, maxf(_PSO_TARGET_SPAN * (sculpt_height / 1.8), 0.4), maxf(sculpt_width, 0.2), false)


## Scalar fitness at search-space planar (sx, sz): a sum of Gaussians. Higher is better; PSO maximises it.
func _pso_fitness(sx: float, sz: float) -> float:
	var total: float = 0.0
	for pk: Vector4 in _pso_peaks:
		var dx: float = sx - pk.x
		var dz: float = sz - pk.y
		var d2: float = dx * dx + dz * dz
		var sigma: float = pk.w
		total += pk.z * exp(-d2 / (2.0 * sigma * sigma))
	return total


func _pso_terrain_height(sx: float, sz: float) -> float:
	return _pso_fitness(sx, sz) * _PSO_FIELD_HEIGHT


## Run PSO to FREEZE_STEP. Returns {"pos": Array[Vector3], "vel": Array[Vector3], "best": Array[bool]}.
## Every random draw (init scatter + r1/r2 each step) comes from the seeded RNG.
func _pso_run(n: int) -> Dictionary:
	var pos: Array[Vector3] = []
	var vel: Array[Vector3] = []
	var pbest: Array[Vector3] = []
	var pbest_fit: Array[float] = []
	pos.resize(n); vel.resize(n); pbest.resize(n); pbest_fit.resize(n)
	var gbest: Vector3 = Vector3.ZERO
	var gbest_fit: float = -INF
	for i: int in range(n):
		var sx: float = _rng.randf_range(-_PSO_DOMAIN_HALF, _PSO_DOMAIN_HALF)
		var sz: float = _rng.randf_range(-_PSO_DOMAIN_HALF, _PSO_DOMAIN_HALF)
		var p: Vector3 = Vector3(sx, 0.0, sz)
		pos[i] = p
		vel[i] = Vector3(
			_rng.randf_range(-_PSO_VEL_CLAMP, _PSO_VEL_CLAMP), 0.0,
			_rng.randf_range(-_PSO_VEL_CLAMP, _PSO_VEL_CLAMP))
		pbest[i] = p
		var fit: float = _pso_fitness(sx, sz)
		pbest_fit[i] = fit
		if fit > gbest_fit:
			gbest_fit = fit
			gbest = p
	for _step: int in range(_PSO_FREEZE_STEP):
		for i2: int in range(n):
			# Bake r1/r2 from the seeded RNG — this is what makes the WHOLE run deterministic.
			var r1: float = _rng.randf()
			var r2: float = _rng.randf()
			var to_pbest: Vector3 = pbest[i2] - pos[i2]
			var to_gbest: Vector3 = gbest - pos[i2]
			var v: Vector3 = _PSO_INERTIA_W * vel[i2] \
				+ _PSO_COGNITIVE_C1 * r1 * to_pbest \
				+ _PSO_SOCIAL_C2 * r2 * to_gbest
			v.x = clampf(v.x, -_PSO_VEL_CLAMP, _PSO_VEL_CLAMP)
			v.z = clampf(v.z, -_PSO_VEL_CLAMP, _PSO_VEL_CLAMP)
			v.y = 0.0
			vel[i2] = v
			var np: Vector3 = pos[i2] + v
			if np.x < -_PSO_DOMAIN_HALF or np.x > _PSO_DOMAIN_HALF:
				np.x = clampf(np.x, -_PSO_DOMAIN_HALF, _PSO_DOMAIN_HALF)
				vel[i2].x *= -0.5
			if np.z < -_PSO_DOMAIN_HALF or np.z > _PSO_DOMAIN_HALF:
				np.z = clampf(np.z, -_PSO_DOMAIN_HALF, _PSO_DOMAIN_HALF)
				vel[i2].z *= -0.5
			pos[i2] = np
			var fit2: float = _pso_fitness(np.x, np.z)
			if fit2 > pbest_fit[i2]:
				pbest_fit[i2] = fit2
				pbest[i2] = np
			if fit2 > gbest_fit:
				gbest_fit = fit2
				gbest = np
	_pso_gbest_search = Vector3(gbest.x, gbest_fit, gbest.z)
	# Flag the particle closest to gbest (rendered hottest).
	var best_flags: Array = []
	best_flags.resize(n)
	var best_i: int = 0
	var best_d: float = INF
	for i3: int in range(n):
		best_flags[i3] = false
		var d: float = Vector2(pos[i3].x - gbest.x, pos[i3].z - gbest.z).length()
		if d < best_d:
			best_d = d
			best_i = i3
	best_flags[best_i] = true
	return {"pos": pos, "vel": vel, "best": best_flags}


## Map a frozen search-space planar point to its WORLD position (X/Z scaled, Y from the field + a hover
## that grows toward the optimum so the funnel rises into the attractor).
func _pso_search_to_world(sp: Vector3) -> Vector3:
	var wx: float = sp.x * _pso_world_scale
	var wz: float = sp.z * _pso_world_scale
	var fit_frac: float = clampf(_pso_fitness(sp.x, sp.z) / maxf(_pso_peaks[0].z, 0.0001), 0.0, 1.2)
	var hover: float = _PSO_MOTE_RADIUS * 5.0 + fit_frac * 0.34
	var wy: float = _pso_terrain_height(sp.x, sp.z) + hover + _PSO_SWARM_LIFT
	return Vector3(wx, wy, wz)


## The fitness landscape as a low-relief heightfield (all four Gaussian peaks show as swellings).
func _pso_build_terrain(parent: Node3D, mat: Material) -> void:
	var grid: int = 44
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var verts: Array = []
	verts.resize(grid + 1)
	for ix: int in range(grid + 1):
		var row: Array[Vector3] = []
		row.resize(grid + 1)
		var fx: float = lerpf(-_PSO_DOMAIN_HALF, _PSO_DOMAIN_HALF, float(ix) / float(grid))
		for iz: int in range(grid + 1):
			var fz: float = lerpf(-_PSO_DOMAIN_HALF, _PSO_DOMAIN_HALF, float(iz) / float(grid))
			var wy: float = _pso_terrain_height(fx, fz) + _PSO_SWARM_LIFT
			row[iz] = Vector3(fx * _pso_world_scale, wy, fz * _pso_world_scale)
		verts[ix] = row
	for ix2: int in range(grid):
		var row_a: Array = verts[ix2] as Array
		var row_b: Array = verts[ix2 + 1] as Array
		for iz2: int in range(grid):
			var v00: Vector3 = row_a[iz2] as Vector3
			var v01: Vector3 = row_a[iz2 + 1] as Vector3
			var v10: Vector3 = row_b[iz2] as Vector3
			var v11: Vector3 = row_b[iz2 + 1] as Vector3
			st.add_vertex(v00); st.add_vertex(v10); st.add_vertex(v01)
			st.add_vertex(v01); st.add_vertex(v10); st.add_vertex(v11)
	st.generate_normals()
	_cs_commit_batch(parent, st, mat, "FitnessLandscape", false)


## The global-best attractor: a bright unshaded orb on the global peak (the cloud funnels into it).
func _pso_build_attractor(parent: Node3D, mat: Material) -> void:
	var world_pos: Vector3 = _pso_search_to_world(Vector3(_pso_gbest_search.x, 0.0, _pso_gbest_search.z))
	world_pos.y += _PSO_MOTE_RADIUS * 2.0
	_cs_add_mesh(parent, MorphoPrimitive.sphere(_PSO_MOTE_RADIUS * 3.2, 18, 12), mat,
		Transform3D(Basis(), world_pos), "GlobalBestAttractor")


## Build the swarm as exactly TWO batched meshes: one ArrayMesh of every mote (translated copies of a
## canonical sphere), one of every velocity streak (a canonical comet-tail re-oriented per particle by a
## Basis from its velocity). No node-per-particle.
func _pso_build_swarm_meshes(parent: Node3D, pos: Array[Vector3], vel: Array[Vector3], best: Array,
		mat_mote: Material, mat_streak: Material) -> void:
	# Canonical mote sphere captured once (PrimitiveMesh — surface_get_arrays works directly).
	var mote_cap: Array = _cs_capture_soup(MorphoPrimitive.sphere(_PSO_MOTE_RADIUS, 8, 6))
	var mote_verts: PackedVector3Array = mote_cap[0]
	var mote_norms: PackedVector3Array = mote_cap[1]

	var mote_st := SurfaceTool.new(); mote_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var streak_st := SurfaceTool.new(); streak_st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for i: int in range(pos.size()):
		var world_pos: Vector3 = _pso_search_to_world(pos[i])
		var is_best: bool = best[i] as bool
		var mote_scale: float = 1.55 if is_best else 1.0
		_cs_merge_soup(mote_st, mote_verts, mote_norms,
			Transform3D(Basis().scaled(Vector3(mote_scale, mote_scale, mote_scale)), world_pos))
		var world_vel: Vector3 = _pso_search_velocity_to_world(pos[i], vel[i])
		var speed: float = world_vel.length()
		if speed > 0.0008:
			_pso_emit_streak(streak_st, world_pos, world_vel, speed, pos[i])

	_cs_commit_batch(parent, mote_st, mat_mote, "SwarmMotes", false)
	_cs_commit_batch(parent, streak_st, mat_streak, "VelocityStreaks", false)


## Convert a planar search-space velocity into a world direction whose Y follows the terrain slope.
func _pso_search_velocity_to_world(sp: Vector3, sv: Vector3) -> Vector3:
	var wx: float = sv.x * _pso_world_scale
	var wz: float = sv.z * _pso_world_scale
	var ahead: Vector3 = sp + sv
	var dy: float = _pso_terrain_height(ahead.x, ahead.z) - _pso_terrain_height(sp.x, sp.z)
	return Vector3(wx, dy, wz)


## Emit one velocity-streak comet-tail (a tapered multi_tube trailing behind the mote along its velocity),
## merged into the batched streak SurfaceTool. Built in world space; no look_at.
func _pso_emit_streak(st: SurfaceTool, mote_world: Vector3, world_vel: Vector3,
		speed: float, planar: Vector3) -> void:
	var dir: Vector3 = world_vel.normalized()
	var clamp_world_speed: float = _PSO_VEL_CLAMP * _pso_world_scale * 1.4142
	var t: float = clampf(speed / maxf(clamp_world_speed, 0.0001), 0.0, 1.0)
	var length: float = lerpf(_PSO_STREAK_MAX_LEN * 0.28, _PSO_STREAK_MAX_LEN, t)
	var fit_frac: float = clampf(_pso_fitness(planar.x, planar.z) / maxf(_pso_peaks[0].z, 0.0001), 0.0, 1.0)
	length *= lerpf(1.0, 0.34, smoothstep(0.55, 1.0, fit_frac))
	var head: Vector3 = mote_world + dir * (_PSO_MOTE_RADIUS * 0.4)
	var tail: Vector3 = head - dir * length
	var rings: int = _PSO_STREAK_SEGMENTS
	var positions: Array[Vector3] = []
	var radii: Array[float] = []
	var base_r: float = _PSO_MOTE_RADIUS * lerpf(0.62, 0.82, t)
	for ri: int in range(rings):
		var f: float = float(ri) / float(rings - 1)
		positions.append(head.lerp(tail, f))
		radii.append(base_r * pow(1.0 - f, 2.0) + base_r * 0.015)
	var tube: Mesh = MorphoPrimitive.multi_tube(positions, radii, 5)
	if tube == null:
		return
	_cs_merge_into(st, tube)
