extends Node3D

## N-Body Gravitational Simulation — 3D
## Bodies attract each other via Newton's gravity (F = G*M*m / r^2).
## Rendered with MultiMeshInstance3D for bodies, ImmediateMesh for force lines.
##
## @identity
## essence: F = G*m1*m2/r^2 for all pairs. O(n^2) pairwise gravity. Every body pulls every other. The computational cost of democracy.
## desire: To summon a miniature galaxy — 20 bodies collapsing, orbiting, scattering — and see the force lines connecting the strongest gravitational relationships.
## critical_parameter: g_constant (0.0001) — the universal coupling. Too high → everything collapses to a point. Too low → bodies drift apart. The sweet spot creates structure.
## triggers: Automatic — all pairs attract every frame, positions update, MultiMesh syncs, top-20 strongest force lines drawn as fading blue connections
## emerges: Clustering — bodies clumping into gravitational groups. Binary pairs forming and dissolving. The force line network revealing gravitational structure.
## needs: MultiMesh body rendering [has], force line visualization [has]. Missing: VR grabbable bodies, Barnes-Hut tree optimization, mass merging on collision.
## relationships: Scales up three_body_problem (3 → 20). The O(n^2) cost motivates Barnes-Hut trees. Lives in ForcesChaos. Force lines preview graph theory concepts (forcedirected3d).
## truth: Gravity is the simplest force and the hardest computation. N bodies, N^2 interactions. Complexity comes from counting, not from the law.

class_name GravitationalSimulation

# Simulation settings
@export var num_bodies: int = 20
@export var random_velocity_range: float = 0.002
@export var spawn_radius: float = 0.35

# Body properties
@export var min_mass: float = 0.005
@export var max_mass: float = 0.03
@export var g_constant: float = 0.0001  # Gravitational constant (scaled for 3D/meters)

## AXIS — WHICH UNIVERSE STARTS. The law was never the frozen thing here; the law is a
## slider (g_constant) and always was. What was frozen is the only thing gravity cannot
## derive for you: where the mass IS at t = 0. Twenty bodies were dropped into a uniform
## random cube with random velocities, once, in a literal loop, and so the exhibit could
## only ever show one story — an unstructured cloud finding structure. That is a claim
## about initial conditions dressed up as a claim about gravity.
##
##   cloud     the shipped scatter: uniform in a cube of side 2*spawn_radius, velocities
##             uniform in ±random_velocity_range. Structure with no ancestry — the
##             clumping is entirely gravity's doing, which is the artifact's own thesis.
##   disc      an annulus in XZ, thin in Y, every body given a TANGENTIAL velocity. The
##             galaxy: order supplied in advance as angular momentum, so what you watch
##             is not structure forming but structure being defended against collapse.
##   shells    two concentric spherical shells, near-static. The gravitational-collapse
##             classic — geometry with no rotation has nothing to hold it up, and the
##             two shells fall through each other.
##   binary    two tight clumps on either side of the origin with opposing bulk drift.
##             The merger. N=20 behaving as N=2 until the encounter, which is the whole
##             argument that N-body structure is hierarchical.
##   lattice   a regular cubic grid, every velocity exactly zero. Perfect order, zero
##             entropy, and the least stable arrangement in the set: gravity's job here
##             is destruction, not construction. The control against `cloud`.
##
## The word is taken from three_body_problem, this artifact's direct predecessor at N=3.
## Its VALUES could not be, and that is the honest part: figure_eight and lagrange are
## theorems about exactly three bodies and mean nothing at twenty. What carries across is
## the question, not the answer sheet.
@export_enum("cloud", "disc", "shells", "binary", "lattice") var configuration: String = "cloud"
const CONFIGURATIONS: PackedStringArray = ["cloud", "disc", "shells", "binary", "lattice"]

## AXIS — WHAT THE ROOM IS ALLOWED TO SEE OF IT. The family word, taken character for
## character from example_2_8_two_body_attraction_vr, example_2_9_n_body_attraction_vr,
## three_body_problem and the other siblings that already ask this question. Gravity has
## no appearance; every demonstration of it picks a fiction to draw and stands behind it.
##
##   result    the bodies alone. Position with the working thrown away.
##   trace     the future, integrated forward at BUILD time through this scene's own
##             O(n^2) sum and its own Euler step, and laid down as a fading path per
##             body. Poincaré's point made photographable at frame zero.
##   longhand  the shipped exhibit: the twenty strongest pair-pulls drawn as fading
##             lines. Note that this is a FILTERED longhand where the two- and six-body
##             siblings draw every pair — at N=20 there are 190 of them, and the fact
##             that you cannot draw the working is precisely what the O(n^2) claim means.
##   axiom     the instance gives way to the rule: no lines, a slate carrying the law and
##             the pair count, and the barycentre with its own track — which is a
##             straight line however violent the swarm, because momentum is conserved.
##             The one predictable thing in an exhibit about unpredictability.
##
## The physics is untouched in all four. _attract, _process and the integrator never see
## this axis; only the drawing does.
@export_enum("result", "trace", "longhand", "axiom") var evidence: String = "longhand"
const EVIDENCE_MODES: PackedStringArray = ["result", "trace", "longhand", "axiom"]

## -1 keeps the shipped behaviour exactly: an unseeded draw, a different galaxy every
## launch. Any value >= 0 pins the spawn so a sweep of `configuration` or `evidence`
## measures the axis and not the dice. Untyped on purpose at the config boundary — the
## cast lives in apply_grid_config so a fixture may pass "7" as a string.
@export var spawn_seed: int = -1

const TRACE_STEPS: int = 320
const TRACE_SAMPLE: int = 2
const TRACE_MAX_POINTS: int = 150

# Data-driven bodies: Array of Dictionaries
# Each: { pos: Vector3, vel: Vector3, acc: Vector3, mass: float, radius: float, color: Color }
var bodies: Array[Dictionary] = []

# Rendering
var multi_mesh: MultiMesh
var multi_mesh_instance: MultiMeshInstance3D

var force_mesh: ImmediateMesh
var force_instance: MeshInstance3D
var force_material: StandardMaterial3D

var label: Label3D

# Evidence scaffolding — built lazily, and only outside `longhand`/`result`.
var _static_mesh: ImmediateMesh
var _static_instance: MeshInstance3D
var _axiom_slate: Label3D
var _extent_anchor: MeshInstance3D

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_normalise_axes()
	_build_force_lines()
	_build_label()
	_create_bodies()
	_build_multi_mesh()
	_build_extent_anchor()
	_rebuild_evidence()

func _normalise_axes() -> void:
	var c: String = str(configuration).strip_edges().to_lower()
	configuration = c if CONFIGURATIONS.has(c) else "cloud"
	var e: String = str(evidence).strip_edges().to_lower()
	evidence = e if EVIDENCE_MODES.has(e) else "longhand"

func _build_force_lines() -> void:
	force_mesh = ImmediateMesh.new()
	force_instance = MeshInstance3D.new()
	force_instance.mesh = force_mesh
	force_material = StandardMaterial3D.new()
	force_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	force_material.vertex_color_use_as_albedo = true
	force_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	force_material.no_depth_test = true
	add_child(force_instance)

func _build_label() -> void:
	label = Label3D.new()
	label.text = "N-Body Gravity"
	label.font_size = 32
	label.pixel_size = 0.001
	label.position = Vector3(0.0, 0.5, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1.0, 1.0, 1.0, 0.9)
	label.no_depth_test = true
	add_child(label)

## The AABB probe counts MeshInstance3D only, and the bodies live in a MultiMesh — without
## this the artifact measures as a 1 m box under `longhand` (where the force lines happen
## to bound it) and as something else under `result` (where nothing is drawn). An anchor
## on render layer 0 is present in every value and drawn in none of them, so all four
## frames are framed alike and no existing placement gains a visible object.
func _build_extent_anchor() -> void:
	var side: float = maxf(spawn_radius, 0.05) * 2.2
	var box := BoxMesh.new()
	box.size = Vector3(side, side, side)
	_extent_anchor = MeshInstance3D.new()
	_extent_anchor.name = "ExtentAnchor"
	_extent_anchor.mesh = box
	_extent_anchor.layers = 0
	add_child(_extent_anchor)

func _create_bodies() -> void:
	bodies.clear()
	if spawn_seed < 0:
		_rng.randomize()
	else:
		_rng.seed = spawn_seed

	var n: int = maxi(num_bodies, 1)
	for i in range(n):
		var state: Array = _initial_state(i, n)
		var pos: Vector3 = state[0]
		var vel: Vector3 = state[1]
		var mass: float = _rng.randf_range(min_mass, max_mass)
		var radius: float = sqrt(mass) * 0.15
		# Color based on mass: lighter = more massive
		var t: float = (mass - min_mass) / maxf(max_mass - min_mass, 0.001)
		var color := Color(0.4 + t * 0.5, 0.5 + t * 0.3, 0.9 - t * 0.3, 0.85)
		bodies.append({
			"pos": pos,
			"vel": vel,
			"acc": Vector3.ZERO,
			"mass": mass,
			"radius": radius,
			"color": color,
		})

## Position and velocity for body `i` of `n`, as [Vector3 pos, Vector3 vel].
## The `cloud` branch is the shipped loop: three randf_range for position and three for
## velocity, in that order, over the same ranges.
func _initial_state(i: int, n: int) -> Array:
	match configuration:
		"disc":
			var ang: float = TAU * float(i) / float(n) + _rng.randf_range(-0.18, 0.18)
			var rad: float = spawn_radius * (0.35 + 0.65 * sqrt(_rng.randf()))
			var p_disc := Vector3(
				cos(ang) * rad,
				_rng.randf_range(-1.0, 1.0) * spawn_radius * 0.06,
				sin(ang) * rad)
			var tangent := Vector3(-sin(ang), 0.0, cos(ang))
			return [p_disc, tangent * random_velocity_range * 3.0]
		"shells":
			var inner: bool = (i % 2) == 0
			var shell_r: float = spawn_radius * (0.45 if inner else 1.0)
			var u: float = _rng.randf() * TAU
			var v: float = acos(clampf(_rng.randf_range(-1.0, 1.0), -1.0, 1.0))
			var p_shell := Vector3(
				sin(v) * cos(u),
				cos(v),
				sin(v) * sin(u)) * shell_r
			return [p_shell, Vector3.ZERO]
		"binary":
			var right: bool = i >= (n / 2)
			var side: float = 1.0 if right else -1.0
			var clump := Vector3(
				_rng.randf_range(-1.0, 1.0),
				_rng.randf_range(-1.0, 1.0),
				_rng.randf_range(-1.0, 1.0)) * spawn_radius * 0.22
			var p_bin: Vector3 = clump + Vector3(side * spawn_radius * 0.75, 0.0, 0.0)
			return [p_bin, Vector3(0.0, 0.0, side * random_velocity_range * 2.0)]
		"lattice":
			var per_side: int = maxi(int(ceil(pow(float(n), 1.0 / 3.0))), 1)
			var lx: int = i % per_side
			var ly: int = (i / per_side) % per_side
			var lz: int = i / (per_side * per_side)
			var step: float = (spawn_radius * 2.0) / float(maxi(per_side - 1, 1))
			var corner: Vector3 = Vector3.ONE * spawn_radius
			var p_lat: Vector3 = Vector3(float(lx), float(ly), float(lz)) * step - corner
			return [p_lat, Vector3.ZERO]
		_:
			# "cloud" — the shipped scatter, statement for statement.
			var p_cloud := Vector3(
				_rng.randf_range(-spawn_radius, spawn_radius),
				_rng.randf_range(-spawn_radius, spawn_radius),
				_rng.randf_range(-spawn_radius, spawn_radius))
			var v_cloud := Vector3(
				_rng.randf_range(-random_velocity_range, random_velocity_range),
				_rng.randf_range(-random_velocity_range, random_velocity_range),
				_rng.randf_range(-random_velocity_range, random_velocity_range))
			return [p_cloud, v_cloud]

func _build_multi_mesh() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 10
	sphere.rings = 6

	multi_mesh = MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.use_colors = true
	multi_mesh.mesh = sphere
	multi_mesh.instance_count = num_bodies

	# Material
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.6, 0.8)
	mat.emission_energy_multiplier = 0.4
	sphere.material = mat

	multi_mesh_instance = MultiMeshInstance3D.new()
	multi_mesh_instance.multimesh = multi_mesh
	add_child(multi_mesh_instance)

	_sync_multimesh()

func _process(_delta: float) -> void:
	# Apply gravitational attraction between all pairs
	for i in range(bodies.size()):
		for j in range(bodies.size()):
			if i != j:
				_attract(bodies[i], bodies[j])

	# Update positions
	for body in bodies:
		body["vel"] += body["acc"]
		body["pos"] += body["vel"]
		body["acc"] = Vector3.ZERO

	_sync_multimesh()
	_draw_evidence()

func _attract(attractor: Dictionary, body: Dictionary) -> void:
	# Gravitational force: attractor pulls body toward it
	var force_dir: Vector3 = attractor["pos"] - body["pos"]
	var distance: float = force_dir.length()
	# Clamp distance to avoid extreme forces (scaled for 3D meter space)
	distance = clampf(distance, 0.01, 0.15)
	# F = G * M * m / r²
	var strength: float = (g_constant * attractor["mass"] * body["mass"]) / (distance * distance)
	var force: Vector3 = force_dir.normalized() * strength
	# a = F / m
	body["acc"] += force / body["mass"]

func _sync_multimesh() -> void:
	if not multi_mesh:
		return
	for i in range(mini(bodies.size(), multi_mesh.instance_count)):
		var body: Dictionary = bodies[i]
		var t := Transform3D()
		var r: float = body["radius"]
		t = t.scaled(Vector3(r, r, r))
		t.origin = body["pos"]
		multi_mesh.set_instance_transform(i, t)
		multi_mesh.set_instance_color(i, body["color"])


# ── EVIDENCE ─────────────────────────────────────────────────────────────────
# The per-frame branch. `longhand` calls the shipped routine untouched; every other value
# leaves the live surface empty and puts its case into the static mesh built once at ready.

func _draw_evidence() -> void:
	if evidence == "longhand":
		_draw_force_lines()
	elif force_mesh and force_mesh.get_surface_count() > 0:
		force_mesh.clear_surfaces()

func _draw_force_lines() -> void:
	force_mesh.clear_surfaces()
	var n := bodies.size()
	if n < 2:
		return

	# Collect all pair forces, pick top 20 strongest
	var pairs: Array[Dictionary] = []
	for i in range(n):
		for j in range(i + 1, n):
			var diff: Vector3 = bodies[i]["pos"] - bodies[j]["pos"]
			var dist: float = maxf(diff.length(), 0.01)
			var strength: float = (g_constant * bodies[i]["mass"] * bodies[j]["mass"]) / (dist * dist)
			pairs.append({"i": i, "j": j, "s": strength})

	# Sort descending by strength
	pairs.sort_custom(func(a, b): return a["s"] > b["s"])

	var draw_count := mini(pairs.size(), 20)

	force_mesh.surface_begin(Mesh.PRIMITIVE_LINES, force_material)
	for k in range(draw_count):
		var pair: Dictionary = pairs[k]
		var alpha: float = lerpf(0.4, 0.08, float(k) / maxf(float(draw_count - 1), 1.0))
		var c := Color(0.5, 0.7, 1.0, alpha)
		force_mesh.surface_set_color(c)
		force_mesh.surface_add_vertex(bodies[pair["i"]]["pos"])
		force_mesh.surface_set_color(c)
		force_mesh.surface_add_vertex(bodies[pair["j"]]["pos"])
	force_mesh.surface_end()

## Ensures the static surface exists, wipes it, and rebuilds it for the current value.
## `result` and `longhand` build nothing at all: no node is constructed outside them, so
## the shipped exhibit's scene tree is what it always was plus the layer-0 anchor.
func _rebuild_evidence() -> void:
	if _axiom_slate and is_instance_valid(_axiom_slate):
		_axiom_slate.queue_free()
		_axiom_slate = null
	if _static_mesh:
		_static_mesh.clear_surfaces()

	if evidence == "result" or evidence == "longhand":
		return

	if _static_instance == null:
		_static_mesh = ImmediateMesh.new()
		_static_instance = MeshInstance3D.new()
		_static_instance.name = "EvidenceStatic"
		_static_instance.mesh = _static_mesh
		_static_instance.material_override = force_material
		add_child(_static_instance)

	var preview: Array = _integrate_preview(TRACE_STEPS)
	var paths: Array = preview[0]
	var com_track: PackedVector3Array = preview[1]

	if evidence == "trace":
		_draw_paths(paths)
	else:
		_draw_axiom(com_track)

## Forward integration of a COPY of the system through this scene's own law and Euler
## step. Returns [paths: Array of PackedVector3Array, com_track: PackedVector3Array].
## Nothing here touches `bodies` — the live simulation is unaffected.
func _integrate_preview(steps: int) -> Array:
	var n: int = bodies.size()
	var pos: Array[Vector3] = []
	var vel: Array[Vector3] = []
	var mass: Array[float] = []
	for i in range(n):
		pos.append(bodies[i]["pos"])
		vel.append(bodies[i]["vel"])
		mass.append(float(bodies[i]["mass"]))

	var frames: Array = []
	var com_track := PackedVector3Array()

	for s in range(steps):
		var acc: Array[Vector3] = []
		for i in range(n):
			acc.append(Vector3.ZERO)
		for i in range(n):
			for j in range(n):
				if i == j:
					continue
				var d: Vector3 = pos[j] - pos[i]
				var dist: float = clampf(d.length(), 0.01, 0.15)
				var strength: float = (g_constant * mass[j] * mass[i]) / (dist * dist)
				acc[i] += (d.normalized() * strength) / mass[i]

		var com := Vector3.ZERO
		var total_mass: float = 0.0
		for i in range(n):
			vel[i] += acc[i]
			pos[i] += vel[i]
			com += pos[i] * mass[i]
			total_mass += mass[i]
		if total_mass > 0.0:
			com = com / total_mass

		if s % TRACE_SAMPLE == 0 and frames.size() < TRACE_MAX_POINTS:
			var snapshot: Array[Vector3] = []
			for i in range(n):
				snapshot.append(pos[i])
			frames.append(snapshot)
			com_track.append(com)

	var paths: Array = []
	for i in range(n):
		var path := PackedVector3Array()
		for f in frames:
			var snap: Array = f
			path.append(snap[i])
		paths.append(path)
	return [paths, com_track]

## `trace` — one fading polyline per body, in that body's own colour.
func _draw_paths(paths: Array) -> void:
	if paths.is_empty():
		return
	_static_mesh.surface_begin(Mesh.PRIMITIVE_LINES, force_material)
	for i in range(paths.size()):
		var path: PackedVector3Array = paths[i]
		if path.size() < 2:
			continue
		var body_color: Color = bodies[i]["color"]
		for k in range(path.size() - 1):
			var fade: float = lerpf(0.85, 0.05, float(k) / maxf(float(path.size() - 2), 1.0))
			var c := Color(body_color.r, body_color.g, body_color.b, fade)
			_static_mesh.surface_set_color(c)
			_static_mesh.surface_add_vertex(path[k])
			_static_mesh.surface_set_color(c)
			_static_mesh.surface_add_vertex(path[k + 1])
	_static_mesh.surface_end()

## `axiom` — the law on a slate, and the barycentre track: a straight line through a
## swarm that is doing anything but travelling in straight lines.
func _draw_axiom(com_track: PackedVector3Array) -> void:
	var n: int = bodies.size()
	if com_track.size() >= 2:
		_static_mesh.surface_begin(Mesh.PRIMITIVE_LINES, force_material)
		var gold := Color(1.0, 0.85, 0.4, 0.9)
		for k in range(com_track.size() - 1):
			_static_mesh.surface_set_color(gold)
			_static_mesh.surface_add_vertex(com_track[k])
			_static_mesh.surface_set_color(gold)
			_static_mesh.surface_add_vertex(com_track[k + 1])
		# A cross at the present barycentre so the track has an origin you can find.
		var tick: float = spawn_radius * 0.12
		var origin: Vector3 = com_track[0]
		for axis in [Vector3.RIGHT, Vector3.UP, Vector3.FORWARD]:
			var dir: Vector3 = axis
			_static_mesh.surface_set_color(gold)
			_static_mesh.surface_add_vertex(origin - dir * tick)
			_static_mesh.surface_set_color(gold)
			_static_mesh.surface_add_vertex(origin + dir * tick)
		_static_mesh.surface_end()

	_axiom_slate = Label3D.new()
	_axiom_slate.name = "AxiomSlate"
	_axiom_slate.text = "F = G m1 m2 / r^2\nN = %d   pairs = N(N-1)/2 = %d" % [n, n * (n - 1) / 2]
	_axiom_slate.font_size = 26
	_axiom_slate.pixel_size = 0.001
	_axiom_slate.position = Vector3(0.0, -spawn_radius - 0.12, 0.0)
	_axiom_slate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_axiom_slate.modulate = Color(1.0, 0.92, 0.75, 0.95)
	_axiom_slate.no_depth_test = true
	add_child(_axiom_slate)


func _exit_tree() -> void:
	bodies.clear()
	if force_mesh:
		force_mesh.clear_surfaces()
	if _static_mesh:
		_static_mesh.clear_surfaces()
	if multi_mesh:
		multi_mesh.instance_count = 0

## Gated per key, and gated on _ready having built once. A map that says nothing about
## configuration, evidence or spawn_seed gets no rebuild at all, so a token carrying only
## other keys cannot disturb a placement that is already running.
func apply_grid_config(config: Dictionary) -> void:
	var respawn: bool = false
	var redraw: bool = false

	if config.has("spawn_seed"):
		var s: int = int(config["spawn_seed"])
		if s != spawn_seed:
			spawn_seed = s
			respawn = true

	if config.has("configuration"):
		var want: String = str(config["configuration"]).strip_edges().to_lower()
		if CONFIGURATIONS.has(want) and want != configuration:
			configuration = want
			respawn = true

	if config.has("evidence"):
		var want_e: String = str(config["evidence"]).strip_edges().to_lower()
		if EVIDENCE_MODES.has(want_e) and want_e != evidence:
			evidence = want_e
			redraw = true

	if not (respawn or redraw):
		return
	# Called before the node entered the tree: leave the values in the exports and let
	# _ready build with them. Rebuilding here would run against a half-built artifact.
	if not is_node_ready():
		return

	if respawn:
		_create_bodies()
		if multi_mesh:
			multi_mesh.instance_count = bodies.size()
		_sync_multimesh()
	_rebuild_evidence()
