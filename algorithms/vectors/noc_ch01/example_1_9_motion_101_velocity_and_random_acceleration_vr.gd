# ===========================================================================
# NOC Example 1.9: Motion 101: Velocity and Random Acceleration
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing -> GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
#
# @identity
# essence: A ball whose acceleration is redrawn from a uniform box every frame, integrated into velocity and position
# desire: To show that a random walk is not disorder — it is one law applied honestly, over and over, to a number nobody chose
# critical_parameter: the +/-0.02 acceleration box and the 0.15 speed cap — together they decide jitter, drift, or a saturated pinball
# triggers: Small box and no cap gives a slow drift; the cap turns the walk into a wall-to-wall traversal at terminal speed
# emerges: A path that looks intentional without any intention in it — the tank fills with a scribble no line of code drew
# relationships: Third of the Motion 101 family. example_1_7 is velocity alone, example_1_8 adds a constant acceleration; this one makes acceleration a coin flip.
# truth: The walk is not random. The DRAW is random; the walk is the only thing the law could have done with it.
# ===========================================================================

extends Node3D

const MAT_BALL := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_TRAIL := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")

# ═══════════════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `evidence`
# ═══════════════════════════════════════════════════════════════════════════
#
# WHAT THIS DEMO OFFERS AS PROOF THAT A LAW IS MOVING THE BALL.
#
# A random walk has the same problem gravity has: the thing being demonstrated is
# not a thing you can look at. `a` is a number redrawn every frame from a box
# nobody can see, and the only visible object — the ball — is the one part of the
# scene that carries no information about the rule. Every demonstration therefore
# has to pick a fiction to draw and stand behind it, and that choice IS the
# teaching. This is the same question example_2_8 and example_2_9 ask about
# attraction, and koch_curve, fibonacci_sequences, sine_wave_controller and
# wave_interference_tank ask about their own working, so this takes THEIR WORD AND
# THEIR VALUE LIST character for character rather than inventing a synonym.
#
# It is also the word the whole Motion 101 family can share: example_1_7 (velocity)
# and example_1_8 (constant acceleration) are the same scene with a different
# right-hand side, and they need to answer the same question about what a viewer
# is allowed to see.
#
#   result    the shipped build, byte for byte: the ball, and the rolling 200-frame
#             trail behind it. Where it is and where it just was — the state, with
#             the rule discarded. The legacy lineage.
#   trace     the rolling window goes away and the WHOLE WALK is drawn: 1400 steps
#             integrated forward here, at build time, through the identical law and
#             the identical Euler step _process runs, laid down as a dotted path.
#             With walk_seed pinned, the ball then walks exactly along it — the
#             future drawn before it happens, which is the flatly anti-intuitive
#             claim a "random" walk makes about itself.
#   longhand  the working instead of the answer. The +/-0.02 box that `a` is drawn
#             from is built at the ball's start, magnified x4 so it is bigger than a
#             fingernail, with the first forty draws scattered inside it; the 0.15
#             speed cap is the circle around it at the same magnification; and the
#             tank the -0.8 bounce acts on stops being invisible and becomes a wire
#             box. The three quantities of `v += a; p += v`, standing on the
#             geometry before anything is added.
#   axiom     the instance gives way to the rule. A plate behind the tank carries
#             the two lines of the update and the uniform density they sample,
#             drawn as its own scatter — no trail, no exhibit, just the statement
#             the ball happens to be an example of.
#
# All four run the SAME physics. _walk_step() is untouched; nothing here reaches the
# accelerations, the cap or the bounce. What changes is what the room is allowed to see.
@export_enum("result", "trace", "longhand", "axiom") var evidence: String = "result"

## Allow-list. An unknown word in a map token falls back to the shipped ball-and-trail
## rather than stranding a placement with a blank exhibit.
const EVIDENCES: PackedStringArray = ["result", "trace", "longhand", "axiom"]

## SEED for the walk, which has always been drawn from the global unseeded generator.
## -1 keeps that behaviour: a different walk every launch, which is the honest default
## for a demo whose whole subject is that nobody chose the numbers. Any other value fixes
## it — which is what a sweep of `evidence` needs, and what `trace` needs if the drawn
## path is to be the path the ball actually takes rather than a sibling of it.
@export var walk_seed: int = -1

var _sim_root: Node3D
var _ball: MeshInstance3D
var _position: Vector3 = Vector3(0, 0.5, 0)
var _velocity: Vector3 = Vector3.ZERO
var _bounds_min: Vector3 = Vector3(-0.45, 0.05, -0.45)
var _bounds_max: Vector3 = Vector3(0.45, 0.95, 0.45)
var _ball_radius: float = 0.03
var _trail_points: Array[Vector3] = []
var _trail_mesh: ImmediateMesh
var _trail_instance: MeshInstance3D
var _max_trail_length: int = 200

## The walk's generator. Historically this was the global randf_range(), i.e. a fresh
## unseeded stream every launch; walk_seed = -1 reproduces that. The seed actually used is
## kept so an exhibit can clone the stream and replay the same walk.
var _rng := RandomNumberGenerator.new()
var _seed_used: int = 0

## Nodes built by trace / longhand / axiom. Freed before any rebuild; empty on the shipped
## path, where not one of them is ever constructed.
var _evidence_parts: Array[Node3D] = []

func _ready() -> void:
	_read_grid_config_meta()
	_seed_walk()
	_setup_environment()
	_spawn_ball()
	_setup_trail()
	_apply_evidence()
	set_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)


func _spawn_ball() -> void:
	_ball = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = _ball_radius
	sphere.height = _ball_radius * 2.0
	_ball.mesh = sphere
	_ball.material_override = MAT_BALL
	_sim_root.add_child(_ball)

func _setup_trail() -> void:
	_trail_mesh = ImmediateMesh.new()
	_trail_instance = MeshInstance3D.new()
	_trail_instance.mesh = _trail_mesh
	_trail_instance.material_override = MAT_TRAIL
	_sim_root.add_child(_trail_instance)


func _seed_walk() -> void:
	if walk_seed < 0:
		_rng.randomize()
	else:
		_rng.seed = walk_seed
	# Setting `seed` resets the stream to its start, so a clone made from this value
	# replays the walk from step zero — which is what `trace` depends on.
	_seed_used = int(_rng.seed)


## ONE STEP OF THE LAW, and the only place it is written.
##
## Extracted from _process so that `trace` cannot drift from the running scene: an exhibit
## that predicts the path with its own copy of the arithmetic is an exhibit that will
## eventually be lying. Returns [position, velocity]; nothing about the numbers changed.
func _walk_step(p: Vector3, v: Vector3, rng: RandomNumberGenerator) -> Array[Vector3]:
	var random_accel := Vector3(
		rng.randf_range(-0.02, 0.02),
		rng.randf_range(-0.02, 0.02),
		rng.randf_range(-0.02, 0.02)
	)

	v += random_accel
	v = v.limit_length(0.15)
	p += v

	if p.x - _ball_radius < _bounds_min.x or p.x + _ball_radius > _bounds_max.x:
		v.x *= -0.8
		p.x = clamp(p.x, _bounds_min.x + _ball_radius, _bounds_max.x - _ball_radius)

	if p.y - _ball_radius < _bounds_min.y or p.y + _ball_radius > _bounds_max.y:
		v.y *= -0.8
		p.y = clamp(p.y, _bounds_min.y + _ball_radius, _bounds_max.y - _ball_radius)

	if p.z - _ball_radius < _bounds_min.z or p.z + _ball_radius > _bounds_max.z:
		v.z *= -0.8
		p.z = clamp(p.z, _bounds_min.z + _ball_radius, _bounds_max.z - _ball_radius)

	var out: Array[Vector3] = [p, v]
	return out


func _process(_delta: float) -> void:
	var stepped: Array[Vector3] = _walk_step(_position, _velocity, _rng)
	_position = stepped[0]
	_velocity = stepped[1]

	_ball.position = _position

	_trail_points.append(_position)
	if _trail_points.size() > _max_trail_length:
		_trail_points.remove_at(0)

	_update_trail()

func _update_trail() -> void:
	_trail_mesh.clear_surfaces()
	if _trail_points.size() < 2:
		return

	_trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for point in _trail_points:
		_trail_mesh.surface_add_vertex(point)
	_trail_mesh.surface_end()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## Grid config arrives twice and by two different routes: GridInteractablesComponent sets
## config_<key> metadata on the instantiated root and then calls apply_grid_config(), and the
## capture harness calls apply_grid_config() before the scene enters the tree. Reading the
## metadata on the way in means the exhibit is built once, correctly, instead of built as
## `result` and then torn down.
##
## Costs nothing when no token is present: the exports keep their defaults and not a single
## existing placement changes.
func _read_grid_config_meta() -> void:
	var node: Node = self
	while node != null:
		if node.has_meta("config_evidence"):
			evidence = str(node.get_meta("config_evidence"))
		if node.has_meta("config_walk_seed"):
			walk_seed = int(str(node.get_meta("config_walk_seed")))
		node = node.get_parent()


## Config from map_data.json tokens: #evidence:trace  ·  #evidence:longhand#walk_seed:7
##
## GUARDED ON CHANGE, deliberately. A placement carrying any other token arrives here with no
## `evidence` key at all, and the grid reaches this twice for one placement; an unguarded
## rebuild would tear down and re-raise an exhibit on both of those, for nothing.
func apply_grid_config(config: Dictionary) -> void:
	var was_evidence: String = evidence

	if config.has("walk_seed"):
		# The stream is already running by the time a late seed arrives, so this only takes
		# effect on the next build — it is a fixture for captures, not a live control.
		walk_seed = int(str(config["walk_seed"]))
	if config.has("evidence"):
		evidence = str(config["evidence"])

	if evidence == was_evidence:
		return
	# Before _ready() the ball does not exist yet and _ready() will do this itself.
	if not is_instance_valid(_ball):
		return

	_apply_evidence()


# ═══════════════════════════════════════════════════════════════════════════
# EVIDENCE
# ═══════════════════════════════════════════════════════════════════════════

const EV_STEPS := 900           # trace: steps integrated forward at build time
const EV_EARLY := Color(0.98, 0.74, 0.26)   # trace: colour at step 0
const EV_LATE := Color(0.35, 0.76, 1.0)     # trace: colour at step EV_STEPS
const EV_MAG := 4.0             # longhand: magnification for a and for the speed cap
const EV_SAMPLES := 40          # longhand: draws scattered inside the acceleration box
const EV_CHALK := Color(0.88, 0.90, 0.95)
const EV_INK := Color(0.98, 0.74, 0.26)
const EV_SLATE := Color(0.16, 0.17, 0.20)


func _apply_evidence() -> void:
	var want: String = String(evidence).strip_edges().to_lower()
	if not EVIDENCES.has(want):
		want = "result"                     # an unknown word keeps the shipped build
	evidence = want

	for part in _evidence_parts:
		if is_instance_valid(part):
			part.queue_free()
	_evidence_parts.clear()

	if want == "result":
		if is_instance_valid(_trail_instance):
			_trail_instance.visible = true
		return                              # the legacy lineage: ball + rolling trail, nothing added

	# The three exhibits put the rolling answer away and show something else in its place.
	if is_instance_valid(_trail_instance):
		_trail_instance.visible = false

	var root := Node3D.new()
	root.name = "Evidence_%s" % want
	add_child(root)
	_evidence_parts.append(root)

	match want:
		"trace":
			_ev_trace(root)
		"longhand":
			_ev_longhand(root)
		"axiom":
			_ev_axiom(root)
		_:
			pass


## A second generator on the same seed, at step zero. Every exhibit that needs to know what
## the walk is going to do asks this rather than touching _rng, which the running scene owns.
func _ev_clone_rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed_used
	return rng


## TRACE — the walk drawn instead of watched. EV_STEPS steps run here, at build time, through
## the same _walk_step() the running scene calls, from the same start state and the same seed.
## With walk_seed pinned the ball then follows this dotted path exactly; unpinned, the path is
## still this launch's walk, because the clone starts from the seed randomize() landed on.
func _ev_trace(root: Node3D) -> void:
	var p: Vector3 = _position
	var v: Vector3 = _velocity
	var rng := _ev_clone_rng()
	var path: Array[Vector3] = [p]

	for i in range(EV_STEPS):
		var stepped: Array[Vector3] = _walk_step(p, v, rng)
		p = stepped[0]
		v = stepped[1]
		path.append(p)

	# A line strip, the same primitive the rolling trail uses, so the difference a viewer
	# reads is the EXTENT and not the rendering. Coloured through time: the shipped trail is
	# one flat pink because a sliding window has no history to order, and this does.
	var im := ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in range(path.size()):
		var u: float = float(i) / float(maxi(path.size() - 1, 1))
		im.surface_set_color(EV_EARLY.lerp(EV_LATE, u))
		im.surface_add_vertex(path[i])
	im.surface_end()

	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.material_override = mat
	root.add_child(mi)

	root.add_child(_ev_text("%d steps, drawn before they happen" % EV_STEPS,
		Vector3(-0.24, _bounds_max.y + 0.05, 0.0), 15, EV_CHALK))


## LONGHAND — the working, not the answer. Everything `v += a; p += v` consumes is put on the
## geometry at the release state: the box `a` is drawn from, forty actual draws from it, the
## cap that clips v, and the tank the -0.8 bounce acts on. Magnified x4 and labelled as such,
## because +/-0.02 m at true scale is smaller than the ball and would be evidence of nothing.
func _ev_longhand(root: Node3D) -> void:
	var at: Vector3 = _position

	# The tank. Hard-coded in _bounds_min/_bounds_max and never drawn until now.
	_ev_wire_box(root, (_bounds_min + _bounds_max) * 0.5, _bounds_max - _bounds_min,
		0.004, _ev_mat(EV_CHALK, 0.25))
	root.add_child(_ev_text("bounce -0.8", Vector3(_bounds_min.x + 0.10, _bounds_min.y + 0.03, _bounds_max.z),
		13, EV_CHALK))

	# The acceleration box: the uniform support of a, magnified.
	var box: float = 0.04 * EV_MAG      # the full width of U(-0.02, 0.02)
	_ev_wire_box(root, at, Vector3(box, box, box), 0.003, _ev_mat(EV_INK, 1.0))
	root.add_child(_ev_text("a ~ U(-0.02, 0.02)  x%d" % int(EV_MAG),
		at + Vector3(0.0, box * 0.5 + 0.035, 0.0), 14, EV_INK))

	# Forty real draws, scattered inside it. Not decoration — these are the first forty
	# accelerations this walk is about to use, at the same magnification.
	var rng := _ev_clone_rng()
	var draws: Array[Vector3] = []
	for i in range(EV_SAMPLES):
		var a := Vector3(
			rng.randf_range(-0.02, 0.02),
			rng.randf_range(-0.02, 0.02),
			rng.randf_range(-0.02, 0.02)
		)
		draws.append(at + a * EV_MAG)
	_ev_dotted(root, draws, EV_INK, 0.008)

	# The cap. limit_length(0.15) is a sphere in velocity space; drawn here as the ring it
	# would be if v were a displacement from the ball, at the same x4.
	root.add_child(_ev_ring(at, 0.15 * EV_MAG, 0.006, _ev_mat(EV_CHALK, 0.8)))
	root.add_child(_ev_text("|v| <= 0.15  x%d" % int(EV_MAG),
		at + Vector3(0.15 * EV_MAG + 0.03, 0.0, 0.0), 13, EV_CHALK))


## AXIOM — the rule, standing where the example was. A plate behind the tank carries the two
## lines of the update and the density they draw from, the uniform square filled in with its
## own scatter. The ball keeps walking in front of it, demoted from the subject to an instance.
func _ev_axiom(root: Node3D) -> void:
	var plate := Node3D.new()
	plate.position = Vector3(0.0, 0.55, _bounds_min.z - 0.10)
	root.add_child(plate)

	var pw: float = 0.70
	var ph: float = 0.42
	plate.add_child(_ev_box(Vector3(0.0, 0.0, -0.012), Vector3(pw + 0.04, ph + 0.04, 0.014),
		_ev_mat(Color(0.28, 0.24, 0.20), 0.0)))
	plate.add_child(_ev_box(Vector3.ZERO, Vector3(pw, ph, 0.012), _ev_mat(EV_SLATE, 0.0)))

	# ASCII on purpose: Label3D falls back to the project font, and a subscript or a tilde
	# operator that renders as a tofu box is worse evidence than a plain line of code.
	plate.add_child(_ev_text("a = U(-0.02, 0.02)^3", Vector3(-0.03, ph * 0.34, 0.014), 22, EV_CHALK))
	plate.add_child(_ev_text("v += a", Vector3(-0.03, ph * 0.16, 0.014), 22, EV_INK))
	plate.add_child(_ev_text("p += v", Vector3(-0.03, ph * 0.02, 0.014), 22, EV_INK))

	# The density itself: the square is the support, the dots are draws from it. Two hundred
	# of them, so the flatness of a uniform is something you can see rather than be told.
	var sq: float = 0.20
	var cx: float = -pw * 0.30
	var cy: float = -ph * 0.22
	_ev_plate_frame(plate, Vector3(cx, cy, 0.014), sq, _ev_mat(EV_CHALK, 0.4))
	var rng := _ev_clone_rng()
	var mat: StandardMaterial3D = _ev_mat(EV_INK, 1.2)
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.006, 0.006, 0.006)
	for i in range(200):
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = mat
		mi.position = Vector3(
			cx + rng.randf_range(-0.5, 0.5) * sq,
			cy + rng.randf_range(-0.5, 0.5) * sq,
			0.018)
		plate.add_child(mi)
	plate.add_child(_ev_text("uniform", Vector3(cx - 0.02, cy - sq * 0.5 - 0.035, 0.016), 13, EV_CHALK))


# ── Small builders (ev_-prefixed so nothing in the demo can collide) ──────

## One shared mesh and one shared material for a whole path — N nodes that all point at the
## same two resources, rather than N meshes and N materials.
func _ev_dotted(root: Node3D, points: Array[Vector3], color: Color, size: float) -> void:
	var mat: StandardMaterial3D = _ev_mat(color, 1.0)
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size, size, size)
	for p in points:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = mat
		mi.position = p
		root.add_child(mi)


func _ev_mat(c: Color, emit: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.6
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	return m


func _ev_box(p: Vector3, s: Vector3, m: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = s
	mi.mesh = bm
	mi.material_override = m
	mi.position = p
	return mi


## Twelve edges, no faces — a box you can see the contents of.
func _ev_wire_box(root: Node3D, center: Vector3, size: Vector3, thick: float, m: StandardMaterial3D) -> void:
	var hx: float = size.x * 0.5
	var hy: float = size.y * 0.5
	var hz: float = size.z * 0.5
	var signs: Array[float] = [-1.0, 1.0]
	for sy: float in signs:
		for sz: float in signs:
			root.add_child(_ev_box(center + Vector3(0.0, hy * sy, hz * sz),
				Vector3(size.x, thick, thick), m))
	for sx: float in signs:
		for sz2: float in signs:
			root.add_child(_ev_box(center + Vector3(hx * sx, 0.0, hz * sz2),
				Vector3(thick, size.y, thick), m))
	for sx2: float in signs:
		for sy2: float in signs:
			root.add_child(_ev_box(center + Vector3(hx * sx2, hy * sy2, 0.0),
				Vector3(thick, thick, size.z), m))


## Four rules bounding a square on the plate face.
func _ev_plate_frame(plate: Node3D, center: Vector3, side: float, m: StandardMaterial3D) -> void:
	var h: float = side * 0.5
	plate.add_child(_ev_box(center + Vector3(0.0, h, 0.0), Vector3(side, 0.004, 0.006), m))
	plate.add_child(_ev_box(center + Vector3(0.0, -h, 0.0), Vector3(side, 0.004, 0.006), m))
	plate.add_child(_ev_box(center + Vector3(h, 0.0, 0.0), Vector3(0.004, side, 0.006), m))
	plate.add_child(_ev_box(center + Vector3(-h, 0.0, 0.0), Vector3(0.004, side, 0.006), m))


func _ev_ring(p: Vector3, radius: float, thick: float, m: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = maxf(radius - thick, 0.002)
	tm.outer_radius = maxf(radius, 0.006)
	mi.mesh = tm
	mi.material_override = m
	mi.position = p
	mi.rotation_degrees = Vector3(90.0, 0.0, 0.0)   # ring faces the viewer, not the floor
	return mi


func _ev_text(content: String, p: Vector3, size: int, c: Color) -> Label3D:
	var l := Label3D.new()
	l.text = content
	l.font_size = size
	l.pixel_size = 0.0012
	l.modulate = c
	l.position = p
	l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	return l
