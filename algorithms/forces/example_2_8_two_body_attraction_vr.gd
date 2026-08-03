# ===========================================================================
# NOC Example 2.8: Two-Body Attraction
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
#
# @identity
# essence: Two bodies pulling each other via inverse-square gravitation, producing closed orbits, escapes, or collisions
# desire: To make the two-body problem visible — Kepler's elliptical solution emerges from F = G·m₁·m₂/r² applied symmetrically
# critical_parameter: gravitational_constant and initial tangential velocity — together they decide circular, elliptical, parabolic, or hyperbolic
# triggers: Low velocity collapses bodies into each other; tuned velocity yields stable ellipse; high velocity becomes escape trajectory
# emerges: Conic sections appear without being coded — the orbit shape is not chosen, it is what the algebra of mutual attraction does
# needs: per-body mass [has], inverse-square attraction force [has], trail visualization [has]
# relationships: Bridge between forces/Newton's_Laws (single-body) and example_2_9_n_body (chaotic many-body). Anchor in forces/N-Body_and_Chaos
# truth: An orbit is not a path drawn around a center — it is the trajectory two bodies negotiate when neither wants to let the other go.
# ===========================================================================

extends Node3D

const DEFAULT_GRAVITY_STRENGTH := 0.4
const ARROW_LENGTH_SCALE := 0.5
const MIN_ARROW_LENGTH := 0.08
const MAX_ARROW_LENGTH := 0.9

var body_a: Mover
var body_b: Mover

var gravity_strength: float = DEFAULT_GRAVITY_STRENGTH
var show_force_vectors: bool = true

# UI — Ada rack panel
var _panel: ForcesRackPanel
var _gravity_slider: Node3D

var arrow_a: Node3D
var arrow_b: Node3D
var auto_reset_timer: Timer

# ═══════════════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `evidence`
# ═══════════════════════════════════════════════════════════════════════════
#
# WHAT THIS DEMO OFFERS AS PROOF THAT A FORCE IS THERE.
#
# Gravity has no appearance. Every demonstration of it must choose a fiction — a
# thing to draw that is not the force, and stand behind it. That choice is the
# argument, and it is the same question koch_curve, fibonacci_sequences,
# sine_wave_controller and wave_interference_tank already ask about their own
# working, so this TAKES THEIR WORD AND THEIR VALUE LIST character for character
# rather than inventing a synonym. Six siblings say `evidence`; this is the seventh.
#
#   result    the shipped build, byte for byte: one orange arrow on each body
#             carrying the resultant — the answer of the sum, and nothing of the
#             sum. The legacy lineage.
#   trace     the arrows go away and the ORBIT ITSELF is drawn: both trajectories
#             integrated forward through the same equations this scene runs, laid
#             down as two dotted paths in each body's own colour. The whole motion
#             at once instead of one frame of it — and for a deterministic system,
#             the future drawn before it happens.
#   longhand  the working instead of the answer. The separation r is drawn as a
#             graduated rod between the two bodies with a tick every 0.05, and each
#             body wears a ring whose AREA is its mass. The three quantities that
#             go into F = G·m₁m₂/r², measured on the geometry at the moment of
#             release, before anything is multiplied.
#   axiom     the instance gives way to the rule. A plate stands behind the bodies
#             carrying the law itself and the 1/r² curve plotted against its own
#             asymptote — no arrows, no orbit, just the statement the two bodies
#             happen to be an example of.
#
# All four run the SAME physics. calculate_attraction() is untouched; nothing here
# reaches _physics_process, the masses or the velocities. What changes is what the
# room is allowed to see.
@export_enum("result", "trace", "longhand", "axiom") var evidence: String = "result"

## Allow-list. An unknown word in a map token falls back to the shipped arrows rather
## than stranding a placement with a blank exhibit.
const EVIDENCES: PackedStringArray = ["result", "trace", "longhand", "axiom"]

## SEED for the two body colours, which spawn_bodies() has always drawn from an
## unseeded rng.randomize() — see the note on _body_rng(). -1 keeps that behaviour
## exactly as shipped: a different pair of colours every launch. Any other value
## fixes them, which is what a sweep of `evidence` needs if it is to measure the
## axis and not the paintwork.
@export var color_seed: int = -1

## Nodes built by trace / longhand / axiom. Freed before any rebuild; empty on the
## shipped path, where not one of them is ever constructed.
var _evidence_parts: Array[Node3D] = []

func _ready() -> void:
	_read_grid_config_meta()

	# Scale down for VR reachability
	scale = Vector3(0.8, 0.8, 0.8)

	_create_panel()
	spawn_bodies()
	setup_auto_reset()
	print("Example 2.8: Two-body attraction")

func setup_auto_reset() -> void:
	auto_reset_timer = Timer.new()
	auto_reset_timer.wait_time = 20.0
	auto_reset_timer.autostart = true
	auto_reset_timer.timeout.connect(reset_scene)
	add_child(auto_reset_timer)

func _process(_delta: float) -> void:
	pass  # Slider labels auto-update

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(body_a) or not is_instance_valid(body_b):
		return

	var force_ab: Vector3 = calculate_attraction(body_a, body_b)
	var force_ba: Vector3 = -force_ab

	body_a.apply_force(force_ab)
	body_b.apply_force(force_ba)

	update_force_arrow(arrow_a, force_ab)
	update_force_arrow(arrow_b, force_ba)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				reset_scene()
			KEY_T:
				toggle_force_vectors()

func _create_panel() -> void:
	_panel = ForcesRackPanel.new()
	_panel.setup("2.8  Two-Body Attraction", 1, 3)
	_panel.set_instructions("[T] Toggle arrows  [R] Reset")

	_gravity_slider = _panel.add_slider("Gravity", 0.1, 1.0, gravity_strength, 0.02)
	_gravity_slider.slider_moved.connect(_on_gravity_slider_moved)

	# Position panel to the left, at chest height, angled toward viewer
	_panel.position = Vector3(-0.45, 0.35, 0.1)
	_panel.rotation_degrees = Vector3(0, 25, 0)
	add_child(_panel)

func spawn_bodies() -> void:
	if is_instance_valid(body_a):
		body_a.queue_free()
	if is_instance_valid(body_b):
		body_b.queue_free()

	var rng := _body_rng()

	body_a = create_body("BodyA", 1.8, Vector3(-0.25, 0.0, 0.0), Vector3(0.0, 0.05, 0.22), rng)
	body_b = create_body("BodyB", 1.1, Vector3(0.25, 0.0, 0.0), Vector3(0.0, -0.05, -0.18), rng)

	arrow_a = create_force_arrow()
	arrow_b = create_force_arrow()
	body_a.add_child(arrow_a)
	body_b.add_child(arrow_b)

	# APPENDED LAST, and a no-op on the shipped path. Placed here rather than in
	# _ready() so that the 20-second auto-reset re-draws an exhibit against the
	# bodies it now has, instead of leaving a trace of an orbit that is over.
	_apply_evidence()


## The colour rng. Historically this was RandomNumberGenerator.new() + randomize(),
## i.e. a fresh unseeded stream every spawn, and color_seed = -1 reproduces that
## exactly. It draws SIX floats per spawn (three per body, inside create_body), so
## nothing may be added above the two create_body() calls without moving the stream.
func _body_rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	if color_seed < 0:
		rng.randomize()
	else:
		rng.seed = color_seed
	return rng

func create_body(body_name: String, mass: float, pos: Vector3, velocity: Vector3, rng: RandomNumberGenerator) -> Mover:
	var body := Mover.new()
	body.name = body_name
	body.mass = mass
	body.position_v = pos
	body.velocity = velocity
	body.acceleration = Vector3.ZERO
	body.bounce_damping = 0.5
	add_child(body)
	body.set_size(0.03 + mass * 0.01)

	var random_color := Color(
		rng.randf_range(0.7, 1.0),
		rng.randf_range(0.4, 0.7),
		rng.randf_range(0.8, 1.0)
	)
	body.set_color(random_color)
	return body

func create_force_arrow() -> Node3D:
	var arrow_root := Node3D.new()
	arrow_root.name = "ForceArrow"
	arrow_root.visible = show_force_vectors

	var shaft := MeshInstance3D.new()
	shaft.name = "Shaft"
	var shaft_mesh: CylinderMesh = CylinderMesh.new()
	shaft_mesh.top_radius = 0.005
	shaft_mesh.bottom_radius = 0.005
	shaft_mesh.height = 1.0
	shaft.mesh = shaft_mesh
	shaft.position = Vector3(0, 0, 0.5)
	shaft.rotation_degrees = Vector3(-90, 0, 0)
	shaft.material_override = _create_attraction_arrow_material()
	arrow_root.add_child(shaft)

	var head := MeshInstance3D.new()
	head.name = "Head"
	var head_mesh: CylinderMesh = CylinderMesh.new()
	head_mesh.top_radius = 0.0
	head_mesh.bottom_radius = 0.02
	head_mesh.height = 0.08
	head.mesh = head_mesh
	head.position = Vector3(0, 0, 1.0)
	head.rotation_degrees = Vector3(-90, 0, 0)
	head.material_override = _create_attraction_arrow_material()
	arrow_root.add_child(head)

	return arrow_root

func _create_attraction_arrow_material() -> StandardMaterial3D:
	# Use Ada accent_orange for attraction arrows
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.45, 0.15, 0.25)
	mat.emission_enabled = true
	mat.emission = Color(0.95, 0.45, 0.15)
	mat.emission_energy_multiplier = 0.4
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat

func calculate_attraction(source: Mover, target: Mover) -> Vector3:
	var direction: Vector3 = target.position_v - source.position_v
	var distance: float = direction.length()
	distance = clamp(distance, 0.08, 0.8)
	direction = direction.normalized()
	var strength: float = (gravity_strength * source.mass * target.mass) / (distance * distance)
	return direction * strength

func update_force_arrow(arrow: Node3D, force: Vector3) -> void:
	if not arrow or not is_instance_valid(arrow):
		return

	var magnitude: float = force.length()
	if not show_force_vectors or magnitude < 0.01:
		arrow.visible = false
		return

	arrow.visible = true
	var length: float = clamp(magnitude * ARROW_LENGTH_SCALE, MIN_ARROW_LENGTH, MAX_ARROW_LENGTH)

	var shaft := arrow.get_node("Shaft") if arrow.has_node("Shaft") else null
	var head := arrow.get_node("Head") if arrow.has_node("Head") else null

	if shaft and shaft is MeshInstance3D:
		shaft.scale = Vector3(1, 1, length)
		shaft.position = Vector3(0, 0, length * 0.5)

	if head and head is MeshInstance3D:
		head.position = Vector3(0, 0, length)
		head.scale = Vector3(1, 1, clamp(length * 0.4, 0.3, 0.9))

	var direction: Vector3 = -force.normalized()
	var up_vector := Vector3.UP
	if abs(direction.dot(up_vector)) > 0.95:
		up_vector = Vector3.RIGHT
	var basis := Basis().looking_at(direction, up_vector)
	arrow.transform = Transform3D(basis, Vector3.ZERO)

func reset_scene() -> void:
	gravity_strength = DEFAULT_GRAVITY_STRENGTH
	if _panel:
		_panel.set_slider_value(0, gravity_strength)
	spawn_bodies()

func toggle_force_vectors() -> void:
	show_force_vectors = !show_force_vectors
	if is_instance_valid(arrow_a):
		arrow_a.visible = show_force_vectors
	if is_instance_valid(arrow_b):
		arrow_b.visible = show_force_vectors

func _on_gravity_slider_moved(_position) -> void:
	gravity_strength = _panel.get_slider_value(0)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# ═══════════════════════════════════════════════════════════════════════════
# `evidence` — EVERYTHING BELOW THIS LINE IS APPENDED. Nothing above it moved.
# ═══════════════════════════════════════════════════════════════════════════

## THE ONLY PATH THAT REACHES THIS SCRIPT FROM A MAP OR THE SWEEP.
##
## This scene's root is a Node3D two levels up — the whole NOC forces family is shaped
## root -> FishTank -> Demo, and this script sits on the grandchild. Both callers address
## the ROOT: the grid writes every #key:value token onto it as `config_<key>` metadata and
## then calls apply_grid_config() there, and the capture harness calls apply_grid_config()
## on the instantiated root before the scene enters the tree. forces_demo_root.gd now sits
## on that root and turns both into the same thing — metadata, in place before this _ready()
## runs. So: walk up and read it.
##
## Costs nothing when no token is present. The exports keep their defaults and not a single
## existing placement changes.
func _read_grid_config_meta() -> void:
	var node: Node = self
	while node != null:
		if node.has_meta("config_evidence"):
			evidence = str(node.get_meta("config_evidence"))
		if node.has_meta("config_color_seed"):
			color_seed = int(str(node.get_meta("config_color_seed")))
		node = node.get_parent()


## Config from map_data.json tokens: #evidence:trace  ·  #evidence:axiom#color_seed:7
##
## GUARDED ON CHANGE, deliberately. The grid reaches this twice for one placement — once as
## metadata read in _ready(), once as the deferred push down from forces_demo_root — and a
## placement carrying any OTHER token arrives here with no `evidence` key at all. An
## unguarded _apply_evidence() would tear down and re-raise an exhibit on both of those, for
## nothing. Rebuild only when the word actually moved.
func apply_grid_config(config: Dictionary) -> void:
	var was_evidence: String = evidence

	if config.has("color_seed"):
		# Colours are drawn at spawn, so a seed arriving after _ready lands on the next
		# auto-reset rather than restyling bodies mid-orbit. Nothing to rebuild here.
		color_seed = int(str(config["color_seed"]))
	if config.has("evidence"):
		evidence = str(config["evidence"])

	if evidence == was_evidence:
		return
	# Before _ready() the bodies do not exist yet and _ready() will do this itself.
	if not is_instance_valid(body_a):
		return

	# Coming back to `result` from an exhibit: _apply_evidence() cannot restore the arrows
	# itself, because it also runs on every 20-second auto-reset and would undo the player's
	# [T] toggle. It is safe here, where we know the word changed.
	if String(evidence).strip_edges().to_lower() == "result" and was_evidence != "result":
		show_force_vectors = true
		if is_instance_valid(arrow_a):
			arrow_a.visible = true
		if is_instance_valid(arrow_b):
			arrow_b.visible = true

	_apply_evidence()


# ── The exhibits ──────────────────────────────────────────────────────────
const EV_STEPS := 900                       # 15 s of orbit at the physics tick
const EV_DT := 1.0 / 60.0
const EV_EVERY := 6                         # plot every sixth step
const EV_BOUND := 0.8                       # stop plotting a body once it leaves this radius
const EV_CHALK := Color(0.93, 0.93, 0.88)
const EV_SLATE := Color(0.12, 0.13, 0.16)
const EV_INK := Color(0.98, 0.74, 0.26)


func _apply_evidence() -> void:
	var want: String = String(evidence).strip_edges().to_lower()
	if not EVIDENCES.has(want):
		want = "result"                     # an unknown word keeps the shipped arrows
	evidence = want

	for part in _evidence_parts:
		if is_instance_valid(part):
			part.queue_free()
	_evidence_parts.clear()

	if want == "result":
		return                              # the legacy lineage: resultant arrows, nothing added

	# The three exhibits put the ANSWER away and show something else in its place.
	show_force_vectors = false
	if is_instance_valid(arrow_a):
		arrow_a.visible = false
	if is_instance_valid(arrow_b):
		arrow_b.visible = false

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


## TRACE — the orbit drawn instead of watched. The two trajectories are integrated
## forward here, at build time, through the identical inverse-square law and the identical
## semi-implicit Euler step the running scene uses (VREntity.update_motion), so the dotted
## path a viewer sees is the path the bodies are about to take. The tank's bouncing walls
## are NOT in the prediction; a path stops when it leaves EV_BOUND instead.
func _ev_trace(root: Node3D) -> void:
	if not is_instance_valid(body_a) or not is_instance_valid(body_b):
		return

	var pa: Vector3 = body_a.position_v
	var pb: Vector3 = body_b.position_v
	var va: Vector3 = body_a.velocity
	var vb: Vector3 = body_b.velocity
	var ma: float = body_a.mass
	var mb: float = body_b.mass

	var dots_a: Array[Vector3] = []
	var dots_b: Array[Vector3] = []
	var live_a: bool = true
	var live_b: bool = true

	for i in range(EV_STEPS):
		var d: Vector3 = pb - pa
		var dist: float = clampf(d.length(), 0.08, 0.8)
		var strength: float = (gravity_strength * ma * mb) / (dist * dist)
		var f: Vector3 = d.normalized() * strength
		va += (f / ma) * EV_DT
		vb += (-f / mb) * EV_DT
		pa += va * EV_DT
		pb += vb * EV_DT
		if pa.length() > EV_BOUND:
			live_a = false
		if pb.length() > EV_BOUND:
			live_b = false
		if i % EV_EVERY == 0:
			if live_a:
				dots_a.append(pa)
			if live_b:
				dots_b.append(pb)

	_ev_dotted(root, dots_a, _ev_body_color(body_a, Color(0.95, 0.55, 0.85)))
	_ev_dotted(root, dots_b, _ev_body_color(body_b, Color(0.75, 0.60, 1.0)))


## LONGHAND — the working, not the answer. r is measured with a graduated rod between the
## two bodies and each body wears a ring whose AREA is its mass, so m₁, m₂ and r all stand
## on the geometry before anything is multiplied. Drawn once, from the release state: this
## is the sum as it was set up, not a readout that chases the bodies around.
func _ev_longhand(root: Node3D) -> void:
	if not is_instance_valid(body_a) or not is_instance_valid(body_b):
		return

	var pa: Vector3 = body_a.position_v
	var pb: Vector3 = body_b.position_v
	var span: Vector3 = pb - pa
	var r: float = span.length()
	if r < 0.001:
		return
	var dir: Vector3 = span / r

	# The separation rod, with a tick every 5 cm — r made countable.
	root.add_child(_ev_rod(pa, pb, 0.006, _ev_mat(EV_CHALK, 0.9)))
	var ticks: int = int(r / 0.05)
	for i in range(1, ticks + 1):
		var at: Vector3 = pa + dir * (float(i) * 0.05)
		var long_tick: bool = (i % 2) == 0
		var tick_h: float = 0.028
		var tick_c: Color = EV_INK
		if long_tick:
			tick_h = 0.05
			tick_c = EV_CHALK
		root.add_child(_ev_box(at, Vector3(0.004, tick_h, 0.004), _ev_mat(tick_c, 0.9)))
	root.add_child(_ev_text("r", (pa + pb) * 0.5 + Vector3(0.0, 0.075, 0.0), 15, EV_CHALK))

	# Mass as area: ring radius scales with sqrt(m), so the two rings compare like the
	# two numbers do rather than like their cube roots.
	root.add_child(_ev_ring(pa, 0.09 * sqrt(body_a.mass), _ev_mat(EV_INK, 1.1)))
	root.add_child(_ev_ring(pb, 0.09 * sqrt(body_b.mass), _ev_mat(EV_INK, 1.1)))
	# ASCII on purpose: Label3D falls back to the project font, and a subscript that
	# renders as a tofu box is worse evidence than a plain "m1".
	root.add_child(_ev_text("m1 %.1f" % body_a.mass, pa + Vector3(0.0, -0.13, 0.0), 13, EV_INK))
	root.add_child(_ev_text("m2 %.1f" % body_b.mass, pb + Vector3(0.0, -0.13, 0.0), 13, EV_INK))


## AXIOM — the rule, standing where the example was. A slate plate behind the bodies carries
## the law and the 1/r² curve plotted against the asymptote it never touches. The two bodies
## keep orbiting in front of it, demoted from the subject to an instance of it.
func _ev_axiom(root: Node3D) -> void:
	var plate := Node3D.new()
	plate.position = Vector3(0.0, 0.30, -0.30)
	root.add_child(plate)

	var pw: float = 0.66
	var ph: float = 0.38
	plate.add_child(_ev_box(Vector3(0.0, 0.0, -0.012), Vector3(pw + 0.04, ph + 0.04, 0.014),
		_ev_mat(Color(0.28, 0.24, 0.20), 0.0)))
	plate.add_child(_ev_box(Vector3.ZERO, Vector3(pw, ph, 0.012), _ev_mat(EV_SLATE, 0.0)))
	plate.add_child(_ev_text("F = G * m1 * m2 / r^2", Vector3(0.0, ph * 0.32, 0.014), 26, EV_CHALK))

	# Axes for the plot, then the curve itself: 1/r² sampled across the plate width.
	var x0: float = -pw * 0.34
	var x1: float = pw * 0.40
	var y0: float = -ph * 0.36
	var y1: float = ph * 0.14
	plate.add_child(_ev_box(Vector3((x0 + x1) * 0.5, y0, 0.014), Vector3(x1 - x0, 0.005, 0.006),
		_ev_mat(EV_CHALK, 0.4)))
	plate.add_child(_ev_box(Vector3(x0, (y0 + y1) * 0.5, 0.014), Vector3(0.005, y1 - y0, 0.006),
		_ev_mat(EV_CHALK, 0.4)))

	var samples: int = 46
	for i in range(samples):
		var u: float = float(i) / float(samples - 1)
		var rr: float = lerpf(0.42, 2.6, u)
		var v: float = 1.0 / (rr * rr)
		var vy: float = clampf(v / (1.0 / (0.42 * 0.42)), 0.0, 1.0)
		plate.add_child(_ev_box(Vector3(lerpf(x0, x1, u), y0 + (y1 - y0) * vy, 0.018),
			Vector3(0.010, 0.010, 0.008), _ev_mat(EV_INK, 1.2)))
	plate.add_child(_ev_text("r", Vector3(x1 + 0.03, y0, 0.016), 13, EV_CHALK))
	plate.add_child(_ev_text("F", Vector3(x0 - 0.035, y1, 0.016), 13, EV_CHALK))


# ── Small builders (ev_-prefixed so nothing in the demo can collide) ──────
func _ev_body_color(body: Mover, fallback: Color) -> Color:
	if is_instance_valid(body) and body.material != null:
		return body.material.albedo_color
	return fallback


## One shared BoxMesh and one shared material for a whole path — 150 nodes that all point at
## the same two resources, rather than 150 meshes and 150 materials.
func _ev_dotted(root: Node3D, points: Array[Vector3], color: Color) -> void:
	var mat: StandardMaterial3D = _ev_mat(color, 1.0)
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.014, 0.014, 0.014)
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


func _ev_ring(p: Vector3, radius: float, m: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = maxf(radius - 0.008, 0.002)
	tm.outer_radius = maxf(radius, 0.006)
	mi.mesh = tm
	mi.material_override = m
	mi.position = p
	mi.rotation_degrees = Vector3(90.0, 0.0, 0.0)   # ring faces the viewer, not the floor
	return mi


## A cylinder spanning a to b, oriented by a hand-built Basis — look_at() needs the node to
## be inside the tree already, and these are built before they are parented.
func _ev_rod(a: Vector3, b: Vector3, r: float, m: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	var d: Vector3 = b - a
	var span: float = d.length()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = maxf(span, 0.002)
	mi.mesh = cm
	mi.material_override = m
	var dir: Vector3 = Vector3.UP
	if span > 0.0001:
		dir = d / span
	var up: Vector3 = Vector3.UP
	if absf(dir.dot(up)) > 0.99:
		up = Vector3.RIGHT
	var right: Vector3 = dir.cross(up).normalized()
	var fwd: Vector3 = right.cross(dir).normalized()
	mi.transform = Transform3D(Basis(right, dir, fwd), (a + b) * 0.5)
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
