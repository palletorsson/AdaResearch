# fitness_landscape_politics.gd
# Same swarm, switchable fitness landscapes. Reveals that "optimal" is a political choice.
#
# @identity
# essence: 30 PSO particles on 4 switchable fitness landscapes — convergence (corporate), spread (ecological), novelty (artistic), ridge (meritocratic) — same agents, different power structures
# desire: to make the learner feel the moment the swarm reorganizes when you switch landscapes, and realize that "optimal" was never neutral
# critical_parameter: mandate — switching it does not change the particles, only what counts as success, and the swarm obeys
# triggers: pressing CONVERGE makes the swarm collapse to center; pressing SPREAD makes it explode outward; pressing NOVELTY makes it seek the unvisited; the ridge mandate funnels it onto one diagonal path
# emerges: the transition animations between landscapes — particles hesitate, reorient, sometimes oscillate before committing to the new definition of success
# needs: [has] landscape buttons via ArtifactControls; [has] inertia slider; [has] terrain recolor; [has] addressable mandate axis; [missing] no history trace; no fitness graph
# relationships: placed in SwarmIntelligence_Particle_Swarm_Optimization alongside self_organizing_patterns; responds to the critical.md question "whose fitness function?"
# truth: the swarm always optimizes — the question is never whether to optimize but who wrote the objective function
#
# ── STAGE-2 DNA: `mandate` ────────────────────────────────────────────────────
#
# The truth line above says the question is who wrote the objective function. Until
# now this artifact answered that question the same way in every placement and every
# capture: CONVERGE, silently, as if a bullseye were simply what a fitness landscape
# IS. `current_landscape` was an untyped enum @export with no string ladder and no
# declaration, so nothing addressed it. The axis makes the handover visible.
#
# A mandate is an instruction someone was given BY SOMEONE ELSE. That is the whole
# word. It is deliberately not `objective` — that is the loss-function vocabulary the
# artifact is critiquing, and naming the axis in the critiqued vocabulary concedes the
# argument before the swarm has moved.
#
# The axis rides on the 3 x 3 m terrain plate, the largest surface here, and it is
# coloured inside _ready — so it is legible at frame zero with no pre-roll. The
# particles are NOT touched by the axis: their scatter is the same at all four values,
# which keeps the swarm from becoming a second, confounding variable.

extends Node3D

class_name FitnessLandscapePolitics

enum Landscape { CONVERGE, SPREAD, NOVELTY, RIDGE }

## Which definition of success the swarm has been handed — and therefore whose
## interest the landscape encodes as low energy.
##
##   converge  a bright disc ~1.2 m across at dead centre, dark to the rim.
##             Corporate fitness: one right answer, and everyone toward it.
##   spread    the exact inverse — a dark disc in the middle, a bright annulus
##             out to the 3 m edge. Ecological fitness: distance from everyone
##             else is the value.
##   novelty   uniformly bright across the whole plate, no gradient anywhere.
##             With the archive empty every point scores identically (see
##             _evaluate_fitness, which returns a flat 10.0), so this is what
##             artistic fitness looks like before anyone has been anywhere.
##   ridge     dark except for a bright band ~0.5 m wide running corner to
##             corner on the diagonal z = x. Meritocratic fitness: exactly one
##             narrow path counts, and it is the only value with a straight
##             edge anywhere on the plate.
@export_enum("converge", "spread", "novelty", "ridge") var mandate: String = "converge"

## The allow-list. A value outside it is a typo and falls back to whatever is
## already set — a half-recognised mandate would strand a placement with a
## landscape nobody asked for.
const MANDATES: PackedStringArray = ["converge", "spread", "novelty", "ridge"]

## Number of particles in the swarm
@export_range(10, 60) var particle_count: int = 30

## Current fitness landscape (kept as the runtime enum the buttons switch;
## `mandate` is the addressable spelling and drives this at build time).
@export var current_landscape: Landscape = Landscape.CONVERGE

## PSO inertia weight (0=reactive, 1=stubborn)
@export_range(0.0, 1.0, 0.05) var inertia: float = 0.6:
	set(value):
		inertia = clampf(value, 0.0, 1.0)

## Arena size in meters
@export var arena_size: float = 3.0

# Internal state
var _particles: Array[Dictionary] = []  # {pos, vel, best_pos, best_fitness}
var _global_best_pos: Vector3 = Vector3.ZERO
var _global_best_fitness: float = -INF
var _multi_mesh_instance: MultiMeshInstance3D
var _multi_mesh: MultiMesh
var _particle_mat: StandardMaterial3D
var _terrain_mesh: MeshInstance3D
var _terrain_im: ImmediateMesh
var _controls: Node
var _caption: Node3D
var _landscape_label: Label3D
var _subtitle_label: Label3D
var _novelty_archive: Array[Vector3] = []  # for novelty search
var _time: float = 0.0

## Nodes THIS script parented to itself. A rebuild frees exactly these — never
## get_children(), which would take the grid's own added plates with it.
var _owned: Array[Node] = []
var _built: bool = false
var _emissive_on: bool = true

const COGNITIVE_WEIGHT := 1.5
const SOCIAL_WEIGHT := 1.5
const MAX_SPEED := 2.0
const TERRAIN_RES := 32

## Every draw in this artifact comes off this stream, seeded from one constant.
## The global RNG is never touched: seed()/randomize() from inside one artifact
## reseeds the whole process, and a swarm built from an unseeded draw makes the
## critic read noise as signal.
const RNG_SEED: int = 20260730
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

## ridge: metres of perpendicular distance from the line z = x at which fitness
## reaches zero. 0.625 puts the bright part of the band (f > 0.6) at 0.5 m wide,
## running the full 4.24 m diagonal of the plate.
const RIDGE_FALLOFF: float = 0.625
const SQRT_HALF: float = 0.7071067811865476

# ── Caption geometry ─────────────────────────────────────────────
#
# LabelFramer turns every hanging Label3D into an opaque anthracite plate. Two
# labels in one column with a small gap MERGE into a single plate, and that is
# the outcome we want here — one nameplate, not two cards. So it is designed for
# rather than fought: both labels sit at x = 0 under a shared Caption parent,
# 0.03 m apart, and become one plate about 1.82 x 0.47 m (bezel 1.85 x 0.50).
#
# Every line is padded to a constant column count at all four mandate values, so
# the plate is the same object in every tile and cannot itself carry the axis.
# The block hangs at y 1.41..1.98: above the particles (y 0.15) by 1.26 m, above
# the terrain (y -0.05), and above the top of the ArtifactControls chassis
# (y 1.225) by 0.185 m — which is what keeps probe_label_placement at crossing=0,
# since that probe measures a plate against the UNION box of the whole body.
const CAPTION_COLS: int = 26
const CAPTION_TITLE_Y: float = 1.75
const CAPTION_SUB_Y: float = 1.50
const CAPTION_TITLE_SIZE: int = 24
const CAPTION_SUB_SIZE: int = 16
const CAPTION_SUB_TEXT: String = "Same swarm. Someone chose."


func _ready() -> void:
	_build_all()
	_built = true


## Everything, synchronously, from the @export values alone. No await, no
## call_deferred: a deferred rebuild that removes children first makes the grid's
## auto-grounding measure a zero AABB and bail, and an await can hang a headless
## capture. This function RETURNS.
func _build_all() -> void:
	mandate = _pick_axis(mandate, MANDATES, "converge")
	current_landscape = _landscape_for(mandate)
	_build_terrain()
	_build_particles()
	_build_controls()
	_build_labels()
	_init_swarm()
	_color_terrain()


func apply_grid_config(config_data: Dictionary) -> void:
	var before_mandate: String = mandate
	var before_count: int = particle_count
	var before_arena: float = arena_size

	# Stage-2 DNA axis — #mandate:ridge
	if config_data.has("mandate"):
		mandate = _pick_axis(str(config_data["mandate"]), MANDATES, mandate)
	if config_data.has("particle_count"):
		particle_count = int(clampf(float(config_data["particle_count"]), 10.0, 60.0))
	if config_data.has("arena_size"):
		arena_size = clampf(float(config_data["arena_size"]), 1.0, 8.0)

	# Non-geometry keys are applied IN PLACE, before any early return — an
	# accepted key that only took effect via a rebuild would silently do nothing
	# for every caller that changes nothing else. curation_station hands every
	# curated artifact {"emissive": false} and no axis key, so this is that path.
	if config_data.has("inertia"):
		inertia = clampf(float(config_data["inertia"]), 0.0, 1.0)
	if config_data.has("emissive"):
		_emissive_on = _coerce_bool(config_data["emissive"], _emissive_on)
		_apply_emissive()

	if not _built:
		return
	if mandate == before_mandate and particle_count == before_count \
			and is_equal_approx(arena_size, before_arena):
		return
	_rebuild_now()
	print("[FitnessLandscapePolitics] Config applied — mandate=%s, particles=%d, arena=%.2f" % [
		mandate, particle_count, arena_size])


## Free only what this script built, then build again inline. Synchronous by
## contract: see _build_all.
func _rebuild_now() -> void:
	for c in _owned:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_owned.clear()
	_terrain_mesh = null
	_terrain_im = null
	_multi_mesh = null
	_multi_mesh_instance = null
	_particle_mat = null
	_controls = null
	_caption = null
	_landscape_label = null
	_subtitle_label = null
	_particles.clear()
	_novelty_archive.clear()
	_global_best_fitness = -INF
	_global_best_pos = Vector3.ZERO
	_build_all()


## Accept an axis value only if it names something we actually build. A typo in a
## map token has to fall back to the shipped look rather than strand the
## placement on a landscape nobody wrote.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## bool("false") is TRUE, which inverts the meaning of every string-valued flag
## that ever comes out of map JSON. Coerce properly.
func _coerce_bool(raw: Variant, fallback: bool) -> bool:
	if raw is bool:
		return bool(raw)
	if raw is int or raw is float:
		return float(raw) != 0.0
	var s: String = str(raw).strip_edges().to_lower()
	if s in ["true", "1", "yes", "on"]:
		return true
	if s in ["false", "0", "no", "off"]:
		return false
	return fallback


func _landscape_for(m: String) -> Landscape:
	match m:
		"spread":
			return Landscape.SPREAD
		"novelty":
			return Landscape.NOVELTY
		"ridge":
			return Landscape.RIDGE
	return Landscape.CONVERGE


func _mandate_for(l: Landscape) -> String:
	match l:
		Landscape.SPREAD:
			return "spread"
		Landscape.NOVELTY:
			return "novelty"
		Landscape.RIDGE:
			return "ridge"
	return "converge"


func _process(delta: float) -> void:
	if not _built:
		return
	_time += delta
	_update_swarm(delta)
	_update_multimesh()


# ── Terrain ─────────────────────────────────────────────────

func _build_terrain() -> void:
	_terrain_im = ImmediateMesh.new()
	_terrain_mesh = MeshInstance3D.new()
	_terrain_mesh.name = "Terrain"
	_terrain_mesh.mesh = _terrain_im
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_terrain_mesh.material_override = mat
	_terrain_mesh.position = Vector3(0, -0.05, 0)
	add_child(_terrain_mesh)
	_owned.append(_terrain_mesh)


func _color_terrain() -> void:
	_terrain_im.clear_surfaces()
	_terrain_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var half := arena_size * 0.5
	var step := arena_size / float(TERRAIN_RES)

	for ix in range(TERRAIN_RES):
		for iz in range(TERRAIN_RES):
			var x0 := -half + ix * step
			var z0 := -half + iz * step
			var x1 := x0 + step
			var z1 := z0 + step

			# Fitness at corners
			var f00 := _terrain_fitness(Vector3(x0, 0, z0))
			var f10 := _terrain_fitness(Vector3(x1, 0, z0))
			var f01 := _terrain_fitness(Vector3(x0, 0, z1))
			var f11 := _terrain_fitness(Vector3(x1, 0, z1))

			# Triangle 1
			_terrain_im.surface_set_color(_fitness_color(f00))
			_terrain_im.surface_add_vertex(Vector3(x0, 0, z0))
			_terrain_im.surface_set_color(_fitness_color(f10))
			_terrain_im.surface_add_vertex(Vector3(x1, 0, z0))
			_terrain_im.surface_set_color(_fitness_color(f01))
			_terrain_im.surface_add_vertex(Vector3(x0, 0, z1))

			# Triangle 2
			_terrain_im.surface_set_color(_fitness_color(f10))
			_terrain_im.surface_add_vertex(Vector3(x1, 0, z0))
			_terrain_im.surface_set_color(_fitness_color(f11))
			_terrain_im.surface_add_vertex(Vector3(x1, 0, z1))
			_terrain_im.surface_set_color(_fitness_color(f01))
			_terrain_im.surface_add_vertex(Vector3(x0, 0, z1))

	_terrain_im.surface_end()


func _terrain_fitness(pos: Vector3) -> float:
	# Normalized 0-1 fitness for terrain coloring
	match current_landscape:
		Landscape.CONVERGE:
			var d := Vector2(pos.x, pos.z).length()
			return clampf(1.0 - d / (arena_size * 0.5), 0.0, 1.0)
		Landscape.SPREAD:
			var d := Vector2(pos.x, pos.z).length()
			return clampf(d / (arena_size * 0.5), 0.0, 1.0)
		Landscape.NOVELTY:
			# THE SHADING NOW AGREES WITH THE FITNESS FUNCTION. This branch used to
			# shade by chebyshev distance to the edge — bright rim, dark middle —
			# which is a picture of SPREAD, not of novelty, and _evaluate_fitness
			# has never returned anything of the kind. On an empty archive it
			# returns a flat 10.0: every point is equally novel because nobody has
			# been anywhere. So the plate is uniform. Once the archive has entries
			# (runtime, after the swarm has been somewhere) the field is distance
			# to the nearest visited point, which is what the swarm is climbing.
			if _novelty_archive.is_empty():
				return 1.0
			var near: float = INF
			for archived in _novelty_archive:
				var d2: float = Vector2(pos.x - archived.x, pos.z - archived.z).length()
				if d2 < near:
					near = d2
			return clampf(near / (arena_size * 0.5), 0.0, 1.0)
		Landscape.RIDGE:
			# Fitness falls off with perpendicular distance from the line z = x.
			var dperp: float = absf(pos.x - pos.z) * SQRT_HALF
			return clampf(1.0 - dperp / RIDGE_FALLOFF, 0.0, 1.0)
	return 0.0


func _fitness_color(f: float) -> Color:
	# Low fitness = dark blue, high fitness = bright yellow
	var c := Color(0.1, 0.1, 0.3, 0.5).lerp(Color(1.0, 0.9, 0.2, 0.6), f)
	return c


# ── Particles ───────────────────────────────────────────────

func _build_particles() -> void:
	_multi_mesh = MultiMesh.new()
	_multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	_multi_mesh.use_colors = true
	_multi_mesh.instance_count = particle_count

	var sphere := SphereMesh.new()
	sphere.radius = 0.04
	sphere.height = 0.08
	sphere.radial_segments = 8
	sphere.rings = 4
	_multi_mesh.mesh = sphere

	_multi_mesh_instance = MultiMeshInstance3D.new()
	_multi_mesh_instance.name = "Particles"
	_multi_mesh_instance.multimesh = _multi_mesh

	_particle_mat = StandardMaterial3D.new()
	_particle_mat.vertex_color_use_as_albedo = true
	_particle_mat.emission_enabled = _emissive_on
	_particle_mat.emission_energy_multiplier = 0.5
	_multi_mesh_instance.material_override = _particle_mat

	add_child(_multi_mesh_instance)
	_owned.append(_multi_mesh_instance)


func _apply_emissive() -> void:
	if _particle_mat:
		_particle_mat.emission_enabled = _emissive_on


func _init_swarm() -> void:
	_particles.clear()
	_global_best_fitness = -INF
	_novelty_archive.clear()
	# One fixed stream, reset here, so the scatter is the same picture at every
	# mandate value and in every run. The DISTRIBUTION is exactly the shipped one
	# — uniform inside +/-1.2 m — only the draw is now repeatable.
	_rng.seed = RNG_SEED

	var half := arena_size * 0.4
	for i in range(particle_count):
		var pos := Vector3(
			_rng.randf_range(-half, half),
			0.15,
			_rng.randf_range(-half, half)
		)
		var vel := Vector3(
			_rng.randf_range(-0.5, 0.5),
			0,
			_rng.randf_range(-0.5, 0.5)
		)
		var fit := _evaluate_fitness(pos)
		_particles.append({
			"pos": pos,
			"vel": vel,
			"best_pos": pos,
			"best_fitness": fit,
		})
		if fit > _global_best_fitness:
			_global_best_fitness = fit
			_global_best_pos = pos


func _evaluate_fitness(pos: Vector3) -> float:
	match current_landscape:
		Landscape.CONVERGE:
			# Minimize distance to center = maximize negative distance
			return -Vector2(pos.x, pos.z).length()
		Landscape.SPREAD:
			# Maximize distance from center
			return Vector2(pos.x, pos.z).length()
		Landscape.NOVELTY:
			# Maximize distance from nearest archived point
			if _novelty_archive.is_empty():
				return 10.0
			var min_dist := INF
			for archived in _novelty_archive:
				var d := pos.distance_to(archived)
				if d < min_dist:
					min_dist = d
			return min_dist
		Landscape.RIDGE:
			# Minimize perpendicular distance from the diagonal z = x. One path.
			return -absf(pos.x - pos.z) * SQRT_HALF
	return 0.0


func _update_swarm(delta: float) -> void:
	var half := arena_size * 0.5

	for p in _particles:
		var r1 := _rng.randf()
		var r2 := _rng.randf()

		# PSO velocity update
		var cognitive: Vector3 = COGNITIVE_WEIGHT * r1 * (p["best_pos"] - p["pos"])
		var social: Vector3 = SOCIAL_WEIGHT * r2 * (_global_best_pos - p["pos"])
		p["vel"] = inertia * p["vel"] + cognitive + social

		# Clamp speed
		var spd: float = p["vel"].length()
		if spd > MAX_SPEED:
			p["vel"] = p["vel"] / spd * MAX_SPEED

		# Keep on XZ plane
		p["vel"].y = 0

		# Move
		p["pos"] += p["vel"] * delta
		p["pos"].y = 0.15

		# Boundary wrap
		p["pos"].x = wrapf(p["pos"].x, -half, half)
		p["pos"].z = wrapf(p["pos"].z, -half, half)

		# Evaluate
		var fit := _evaluate_fitness(p["pos"])
		if fit > p["best_fitness"]:
			p["best_fitness"] = fit
			p["best_pos"] = p["pos"]
		if fit > _global_best_fitness:
			_global_best_fitness = fit
			_global_best_pos = p["pos"]

	# For novelty search, periodically archive positions
	if current_landscape == Landscape.NOVELTY:
		if Engine.get_frames_drawn() % 30 == 0 and _particles.size() > 0:
			var rand_p: Dictionary = _particles[_rng.randi() % _particles.size()]
			_novelty_archive.append(rand_p["pos"])
			if _novelty_archive.size() > 200:
				_novelty_archive.pop_front()


func _update_multimesh() -> void:
	for i in range(min(particle_count, _particles.size())):
		var p: Dictionary = _particles[i]
		var t := Transform3D()
		t.origin = p["pos"]
		_multi_mesh.set_instance_transform(i, t)

		# Color by fitness
		var fit := _evaluate_fitness(p["pos"])
		var norm_fit := clampf(remap(fit, -arena_size, arena_size, 0.0, 1.0), 0.0, 1.0)
		var col: Color
		match current_landscape:
			Landscape.CONVERGE:
				col = Color(0.2, 0.4, 1.0).lerp(Color(1.0, 1.0, 0.2), norm_fit)
			Landscape.SPREAD:
				col = Color(0.2, 0.6, 0.2).lerp(Color(0.1, 1.0, 0.4), norm_fit)
			Landscape.NOVELTY:
				col = Color(0.6, 0.1, 0.6).lerp(Color(1.0, 0.5, 1.0), norm_fit)
			Landscape.RIDGE:
				col = Color(0.9, 0.35, 0.1).lerp(Color(1.0, 0.85, 0.3), norm_fit)
			_:
				col = Color.WHITE
		_multi_mesh.set_instance_color(i, col)


# ── Controls ────────────────────────────────────────────────

func _build_controls() -> void:
	_controls = ArtifactControls.new()
	_controls.name = "Controls"
	_controls.position = Vector3(2.2, 1.2, 0.0)
	add_child(_controls)
	_owned.append(_controls)

	_controls.add_button("CONVERGE", func():
		_switch_landscape(Landscape.CONVERGE)
	)
	_controls.add_button("SPREAD", func():
		_switch_landscape(Landscape.SPREAD)
	)
	_controls.add_button("NOVELTY", func():
		_switch_landscape(Landscape.NOVELTY)
	)
	# The RIDGE button exists only where the ridge mandate was handed over. Two
	# rules meet here: the shipped default look must stay pixel-exact (a fourth
	# chassis in the control column would change it), and no value may be a
	# one-way door in VR (leaving ridge with no way back would be exactly that).
	# A return path is only needed to where you started, so it is built there.
	if mandate == "ridge":
		_controls.add_button("RIDGE", func():
			_switch_landscape(Landscape.RIDGE)
		)
	_controls.add_slider("INERTIA", inertia, func(v: float):
		inertia = v
	)


func _build_labels() -> void:
	# A shared parent so the framer's merged plate is parented to something this
	# script owns — freeing Caption on rebuild takes the plate with it instead of
	# stranding an orphan panel in mid-air.
	_caption = Node3D.new()
	_caption.name = "Caption"
	add_child(_caption)
	_owned.append(_caption)

	_landscape_label = Label3D.new()
	_landscape_label.name = "LandscapeLabel"
	_landscape_label.font_size = CAPTION_TITLE_SIZE
	_landscape_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_landscape_label.position = Vector3(0, CAPTION_TITLE_Y, 0)
	_landscape_label.modulate = Color(1, 1, 1, 0.9)
	_caption.add_child(_landscape_label)
	_update_landscape_label()

	_subtitle_label = Label3D.new()
	_subtitle_label.name = "Subtitle"
	_subtitle_label.text = _fit_cols(CAPTION_SUB_TEXT)
	_subtitle_label.font_size = CAPTION_SUB_SIZE
	_subtitle_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_subtitle_label.position = Vector3(0, CAPTION_SUB_Y, 0)
	_subtitle_label.modulate = Color(0.8, 0.8, 0.8, 0.7)
	_caption.add_child(_subtitle_label)


## Pad a caption line out to a constant column count, centred. Every line at
## every mandate value is the same number of characters, so the merged plate is
## the same nameplate in every tile and cannot be mistaken for the axis.
func _fit_cols(s: String) -> String:
	var t: String = s
	if t.length() > CAPTION_COLS:
		t = t.substr(0, CAPTION_COLS)
	var pad: int = CAPTION_COLS - t.length()
	var left: int = pad / 2
	var right: int = pad - left
	return " ".repeat(left) + t + " ".repeat(right)


func _switch_landscape(mode: Landscape) -> void:
	current_landscape = mode
	mandate = _mandate_for(mode)
	# Reset personal bests and global best for new landscape
	_global_best_fitness = -INF
	_novelty_archive.clear()
	for p in _particles:
		var fit := _evaluate_fitness(p["pos"])
		p["best_fitness"] = fit
		p["best_pos"] = p["pos"]
		if fit > _global_best_fitness:
			_global_best_fitness = fit
			_global_best_pos = p["pos"]
	_color_terrain()
	_update_landscape_label()


func _update_landscape_label() -> void:
	if not _landscape_label:
		return
	var l1: String = ""
	var l2: String = ""
	var tint: Color = Color(0.4, 0.6, 1.0, 0.9)
	match current_landscape:
		Landscape.CONVERGE:
			l1 = "CONVERGE — Corporate"
			l2 = "Minimize distance to zero."
			tint = Color(0.4, 0.6, 1.0, 0.9)
		Landscape.SPREAD:
			l1 = "SPREAD — Ecological"
			l2 = "Distance from the rest."
			tint = Color(0.3, 0.9, 0.4, 0.9)
		Landscape.NOVELTY:
			l1 = "NOVELTY — Artistic"
			l2 = "Nowhere visited yet."
			tint = Color(0.9, 0.5, 1.0, 0.9)
		Landscape.RIDGE:
			l1 = "RIDGE — Meritocratic"
			l2 = "One narrow path counts."
			tint = Color(1.0, 0.65, 0.25, 0.9)
	_landscape_label.text = "%s\n%s" % [_fit_cols(l1), _fit_cols(l2)]
	_landscape_label.modulate = tint
