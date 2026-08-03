# ===========================================================================
# NOC Example 2.9: N-Body Attraction
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
#
# @identity
# essence: N bodies each attracting every other — O(n²) gravitational sum, classic chaotic dynamics with no closed-form solution
# desire: To show that two-body solvability vanishes the moment a third body enters — chaos arrives at n=3, not n=∞
# critical_parameter: body count and gravitational_constant — count gates whether the system can be reasoned about; G scales how fast collapse comes
# triggers: Three bodies near-equal mass produce sensitive-dependence chaos; one heavy body recovers near-Keplerian orbits for the rest; high G collapses everything to a singular cluster
# emerges: Self-organization without design — clusters form, eject members, stabilize into binaries; Poincaré's three-body insight lived as motion
# needs: per-body mass [has], pairwise force computation [has], trails [has], stability tuning [has]
# relationships: Direct successor to example_2_8_two_body. Anchor in forces/N-Body_and_Chaos. Companion to vector_field_visualizer (field view)
# truth: Three bodies cannot be solved — they can only be watched. The future is a fact computed forward, not predicted from the past.
# ===========================================================================

extends Node3D

const DEFAULT_GRAVITY_STRENGTH := 0.35
const MAX_BODIES := 8
const ARROW_LENGTH_SCALE := 0.35
const MIN_ARROW_LENGTH := 0.05
const MAX_ARROW_LENGTH := 0.7

var bodies: Array[Mover] = []
var force_visuals: Dictionary = {}
var initial_states: Dictionary = {}

var gravity_strength: float = DEFAULT_GRAVITY_STRENGTH
var body_count: int = 6
var show_force_vectors: bool = true

# UI — Ada rack panel
var _panel: ForcesRackPanel
var _gravity_slider: Node3D
var _bodies_slider: Node3D
var auto_reset_timer: Timer

# ═══════════════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `evidence`
# ═══════════════════════════════════════════════════════════════════════════
#
# WHAT THIS DEMO OFFERS AS PROOF THAT A FORCE IS THERE.
#
# The same word, the same four values and the same question as
# example_2_8_two_body_attraction_vr, which this example is the direct successor to —
# and behind both, the six artifacts that already say `evidence` about their own
# working. Two demos that argue about the same law should not argue in two
# vocabularies, so nothing here is a synonym: the list is taken character for
# character from koch_curve and fibonacci_sequences.
#
# Where 2.8 and 2.9 part company is `longhand`, and that is the whole point of the
# pair. With two bodies the resultant IS the single term, so the sum has nothing to
# show. With six, each arrow is fifteen pair-pulls added up and thrown away.
#
#   result    the shipped build, byte for byte: one arrow per body carrying the
#             resultant of every attraction acting on it. Six arrows, six answers,
#             and no sign of the thirty terms behind them.
#   trace     the arrows go away and the TRAJECTORIES are drawn: all six paths
#             integrated forward through the same equations this scene runs, laid
#             down as dotted lines in each body's own colour. Poincaré's point made
#             photographable — the future is a fact computed forward, so it can be
#             drawn before it happens.
#   longhand  the sum written out. Every one of the fifteen pairs gets its own line,
#             brightness and thickness scaled by that pair's force, drawn BEFORE the
#             addition instead of after it. The O(n²) in the docstring stops being a
#             complexity class and becomes a thicket you can count.
#   axiom     the instance gives way to the rule. A plate carries the law with its
#             summation, and the 1/r² curve plotted against the asymptote it never
#             reaches. The bodies keep moving in front of it as an example of it.
#
# All four run the SAME physics. calculate_attraction() is untouched; the seeded
# spawn, the masses and the velocities are identical in every value. What changes is
# what the room is allowed to see.
@export_enum("result", "trace", "longhand", "axiom") var evidence: String = "result"

## Allow-list. An unknown word in a map token falls back to the shipped arrows rather
## than stranding a placement with a blank exhibit.
const EVIDENCES: PackedStringArray = ["result", "trace", "longhand", "axiom"]

## Nodes built by trace / longhand / axiom. Freed before any rebuild; empty on the
## shipped path, where not one of them is ever constructed.
var _evidence_parts: Array[Node3D] = []

func _ready() -> void:
	_read_grid_config_meta()

	# Scale down for VR reachability
	scale = Vector3(0.8, 0.8, 0.8)

	_create_panel()
	spawn_bodies(body_count)
	setup_auto_reset()
	print("Example 2.9: N-body attraction")

func setup_auto_reset() -> void:
	auto_reset_timer = Timer.new()
	auto_reset_timer.wait_time = 20.0
	auto_reset_timer.autostart = true
	auto_reset_timer.timeout.connect(reset_scene)
	add_child(auto_reset_timer)

func _process(_delta: float) -> void:
	pass  # Slider labels auto-update

func _physics_process(_delta: float) -> void:
	for i in range(bodies.size()):
		var mover := bodies[i]
		if not is_instance_valid(mover):
			continue

		var total_force: Vector3 = Vector3.ZERO
		for j in range(bodies.size()):
			if i == j:
				continue
			var other := bodies[j]
			if not is_instance_valid(other):
				continue
			total_force += calculate_attraction(mover, other)

		mover.apply_force(total_force)
		update_force_arrow(force_visuals.get(mover, null), total_force)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				reset_scene()
			KEY_T:
				toggle_force_vectors()

func _create_panel() -> void:
	_panel = ForcesRackPanel.new()
	_panel.setup("2.9  N-Body Attraction", 2, 3)
	_panel.set_instructions("[T] Toggle arrows  [R] Reset")

	_gravity_slider = _panel.add_slider("Gravity", 0.1, 0.8, gravity_strength, 0.02)
	_gravity_slider.slider_moved.connect(_on_gravity_slider_moved)

	# Bodies slider — use snap for integer stepping
	_bodies_slider = _panel.add_slider("Bodies", 3.0, 8.0, float(body_count), 1.0, true)
	_bodies_slider.slider_moved.connect(_on_bodies_slider_moved)

	# Position panel to the left, at chest height, angled toward viewer
	_panel.position = Vector3(-0.5, 0.35, 0.15)
	_panel.rotation_degrees = Vector3(0, 30, 0)
	add_child(_panel)

func spawn_bodies(count: int) -> void:
	clear_bodies()

	var rng := RandomNumberGenerator.new()
	rng.seed = 12345

	for i in range(count):
		var mass := rng.randf_range(0.6, 2.2)
		var pos := Vector3(
			rng.randf_range(-0.4, 0.4),
			rng.randf_range(-0.1, 0.4),
			rng.randf_range(-0.4, 0.4)
		)
		var velocity := Vector3(
			rng.randf_range(-0.1, 0.1),
			rng.randf_range(-0.08, 0.08),
			rng.randf_range(-0.1, 0.1)
		)

		var random_color := Color(
			rng.randf_range(0.7, 1.0),
			rng.randf_range(0.4, 0.7),
			rng.randf_range(0.8, 1.0)
		)

		var body := create_body("Body_%d" % i, mass, pos, velocity, random_color)

		bodies.append(body)
		initial_states[body] = {
			"position": pos,
			"velocity": velocity,
			"mass": mass
		}

		var arrow := create_force_arrow(random_color)
		body.add_child(arrow)
		force_visuals[body] = arrow

	# APPENDED LAST, and a no-op on the shipped path. Placed here rather than in
	# _ready() so that the 20-second auto-reset and the Bodies slider both re-draw an
	# exhibit against the bodies they now have, instead of leaving the working of a
	# sum that no longer exists.
	_apply_evidence()

func create_body(body_name: String, mass: float, pos: Vector3, velocity: Vector3, color: Color) -> Mover:
	var body := Mover.new()
	body.name = body_name
	body.mass = mass
	body.position_v = pos
	body.velocity = velocity
	body.acceleration = Vector3.ZERO
	body.bounce_damping = 0.5
	add_child(body)
	body.set_size(0.03 + mass * 0.01)
	body.set_color(color)
	return body

func create_force_arrow(base_color: Color) -> Node3D:
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
	shaft.material_override = _create_arrow_material(base_color)
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
	head.material_override = _create_arrow_material(base_color)
	arrow_root.add_child(head)

	return arrow_root

func _create_arrow_material(base_color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(base_color.r, base_color.g, base_color.b, 0.25)
	mat.emission_enabled = true
	mat.emission = base_color
	mat.emission_energy_multiplier = 0.4
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat

func calculate_attraction(source: Mover, target: Mover) -> Vector3:
	var direction: Vector3 = target.position_v - source.position_v
	var distance: float = direction.length()
	distance = clamp(distance, 0.08, 0.9)
	direction = direction.normalized()
	var strength: float = (gravity_strength * source.mass * target.mass) / (distance * distance)
	return direction * strength

func update_force_arrow(arrow: Node3D, force: Vector3) -> void:
	if not arrow or not is_instance_valid(arrow):
		return

	var magnitude: float = force.length()
	if not show_force_vectors or magnitude < 0.02:
		arrow.visible = false
		return

	arrow.visible = true
	var length: float = clamp(magnitude * ARROW_LENGTH_SCALE, MIN_ARROW_LENGTH, MAX_ARROW_LENGTH)

	var shaft: Node = arrow.get_node("Shaft") if arrow.has_node("Shaft") else null
	var head: Node = arrow.get_node("Head") if arrow.has_node("Head") else null

	if shaft and shaft is MeshInstance3D:
		shaft.scale = Vector3(1, 1, length)
		shaft.position = Vector3(0, 0, length * 0.5)

	if head and head is MeshInstance3D:
		head.position = Vector3(0, 0, length)
		head.scale = Vector3(1, 1, clamp(length * 0.4, 0.25, 0.8))

	var direction: Vector3 = -force.normalized()
	var up_vector := Vector3.UP
	if abs(direction.dot(up_vector)) > 0.95:
		up_vector = Vector3.RIGHT
	var basis := Basis().looking_at(direction, up_vector)
	arrow.transform = Transform3D(basis, Vector3.ZERO)

func reset_scene() -> void:
	body_count = int(_panel.get_slider_value(1))
	spawn_bodies(body_count)

func toggle_force_vectors() -> void:
	show_force_vectors = !show_force_vectors
	for arrow in force_visuals.values():
		if is_instance_valid(arrow):
			arrow.visible = show_force_vectors

func _on_gravity_slider_moved(_position) -> void:
	gravity_strength = _panel.get_slider_value(0)

func _on_bodies_slider_moved(_position) -> void:
	var new_count: int = int(round(_panel.get_slider_value(1)))
	if new_count != body_count:
		body_count = new_count
		spawn_bodies(body_count)

func clear_bodies() -> void:
	for body in bodies:
		if is_instance_valid(body):
			body.queue_free()
	bodies.clear()
	force_visuals.clear()
	initial_states.clear()

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
		node = node.get_parent()


## Config from map_data.json tokens: #evidence:longhand
##
## GUARDED ON CHANGE, deliberately. The grid reaches this twice for one placement — once as
## metadata read in _ready(), once as the deferred push down from forces_demo_root — and a
## placement carrying any OTHER token arrives here with no `evidence` key at all. An
## unguarded _apply_evidence() would tear down and re-raise an exhibit on both of those, for
## nothing. Rebuild only when the word actually moved.
func apply_grid_config(config: Dictionary) -> void:
	var was_evidence: String = evidence

	if config.has("evidence"):
		evidence = str(config["evidence"])

	if evidence == was_evidence:
		return
	# Before _ready() the bodies do not exist yet and _ready() will do this itself.
	if bodies.is_empty():
		return

	# Coming back to `result` from an exhibit: _apply_evidence() cannot restore the arrows
	# itself, because it also runs on every auto-reset and every move of the Bodies slider,
	# and would undo the player's [T] toggle. It is safe here, where we know the word changed.
	if String(evidence).strip_edges().to_lower() == "result" and was_evidence != "result":
		show_force_vectors = true
		for arrow in force_visuals.values():
			if is_instance_valid(arrow):
				arrow.visible = true

	_apply_evidence()


# ── The exhibits ──────────────────────────────────────────────────────────
const EV_STEPS := 900                       # 15 s of motion at the physics tick
const EV_DT := 1.0 / 60.0
# Plot every fifteenth step — 60 dots per body. Six bodies at EV_EVERY = 6 would be 900
# separate MeshInstance3Ds, i.e. 900 draw calls in a scene that has to hold 90 fps in a headset.
const EV_EVERY := 15
const EV_BOUND := 0.9                       # stop plotting a body once it leaves this radius
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
	for arrow in force_visuals.values():
		if is_instance_valid(arrow):
			arrow.visible = false

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


## TRACE — the trajectories drawn instead of watched. Every body is integrated forward here,
## at build time, through the identical O(n²) pairwise sum and the identical semi-implicit
## Euler step the running scene uses (VREntity.update_motion), so the dotted paths are the
## paths these bodies are about to take. The spawn is seeded (rng.seed = 12345), so the
## drawing is the same drawing every launch. The tank's bouncing walls are NOT in the
## prediction; a path stops when it leaves EV_BOUND instead.
func _ev_trace(root: Node3D) -> void:
	var n: int = bodies.size()
	if n == 0:
		return

	var pos: Array[Vector3] = []
	var vel: Array[Vector3] = []
	var mas: Array[float] = []
	var colors: Array[Color] = []
	var live: Array[bool] = []
	var dots: Array = []
	for i in range(n):
		var b: Mover = bodies[i]
		if not is_instance_valid(b):
			return
		pos.append(b.position_v)
		vel.append(b.velocity)
		mas.append(b.mass)
		colors.append(_ev_body_color(b, EV_INK))
		live.append(true)
		dots.append([])                     # one plain Array of Vector3 per body

	for step in range(EV_STEPS):
		var accel: Array[Vector3] = []
		for i in range(n):
			var total: Vector3 = Vector3.ZERO
			for j in range(n):
				if i == j:
					continue
				var d: Vector3 = pos[j] - pos[i]
				var dist: float = clampf(d.length(), 0.08, 0.9)
				var strength: float = (gravity_strength * mas[i] * mas[j]) / (dist * dist)
				total += d.normalized() * strength
			accel.append(total / mas[i])
		for i in range(n):
			vel[i] += accel[i] * EV_DT
			pos[i] += vel[i] * EV_DT
			if pos[i].length() > EV_BOUND:
				live[i] = false
			if step % EV_EVERY == 0 and live[i]:
				dots[i].append(pos[i])

	for i in range(n):
		_ev_dotted(root, dots[i], colors[i])


## LONGHAND — the sum written out. The shipped build shows one arrow per body: the answer,
## with the fifteen pair-pulls that made it already discarded. Here every pair gets its own
## line, thickness and brightness scaled by that pair's force, so the near pairs shout and
## the far pairs whisper — inverse-square drawn as a weight of ink rather than an arrow
## length. Drawn once, from the release state: this is the sum as it was set up.
func _ev_longhand(root: Node3D) -> void:
	var n: int = bodies.size()
	if n < 2:
		return

	# One pass to find the strongest pair, so the ink scale is relative to this spawn.
	var peak: float = 0.0
	for i in range(n):
		for j in range(i + 1, n):
			peak = maxf(peak, _ev_pair_force(i, j))
	if peak <= 0.0:
		return

	for i in range(n):
		for j in range(i + 1, n):
			var a: Mover = bodies[i]
			var b: Mover = bodies[j]
			if not is_instance_valid(a) or not is_instance_valid(b):
				continue
			var w: float = clampf(_ev_pair_force(i, j) / peak, 0.06, 1.0)
			var thickness: float = lerpf(0.0016, 0.010, w)
			var col: Color = EV_CHALK.lerp(EV_INK, w)
			root.add_child(_ev_rod(a.position_v, b.position_v, thickness, _ev_mat(col, w * 1.4)))

	var pairs: int = (n * (n - 1)) / 2
	root.add_child(_ev_text("%d BODIES   %d TERMS" % [n, pairs], Vector3(0.0, 0.46, 0.0), 16, EV_CHALK))


## The magnitude of the attraction between two spawned bodies, by the scene's own rule.
func _ev_pair_force(i: int, j: int) -> float:
	var a: Mover = bodies[i]
	var b: Mover = bodies[j]
	if not is_instance_valid(a) or not is_instance_valid(b):
		return 0.0
	var dist: float = clampf((b.position_v - a.position_v).length(), 0.08, 0.9)
	return (gravity_strength * a.mass * b.mass) / (dist * dist)


## AXIOM — the rule, standing where the example was. A slate plate behind the swarm carries
## the law with its summation and the 1/r² curve plotted against the asymptote it never
## touches. The bodies keep moving in front of it, demoted from the subject to an instance.
func _ev_axiom(root: Node3D) -> void:
	var plate := Node3D.new()
	plate.position = Vector3(0.0, 0.34, -0.34)
	root.add_child(plate)

	var pw: float = 0.72
	var ph: float = 0.42
	plate.add_child(_ev_box(Vector3(0.0, 0.0, -0.012), Vector3(pw + 0.04, ph + 0.04, 0.014),
		_ev_mat(Color(0.28, 0.24, 0.20), 0.0)))
	plate.add_child(_ev_box(Vector3.ZERO, Vector3(pw, ph, 0.012), _ev_mat(EV_SLATE, 0.0)))
	# ASCII on purpose: Label3D falls back to the project font, and a summation sign that
	# renders as a tofu box is worse evidence than a plain "SUM".
	plate.add_child(_ev_text("F_i = SUM  G * m_i * m_j / r^2", Vector3(0.0, ph * 0.34, 0.014), 22, EV_CHALK))
	plate.add_child(_ev_text("j != i", Vector3(-pw * 0.24, ph * 0.22, 0.014), 13, EV_INK))

	var x0: float = -pw * 0.34
	var x1: float = pw * 0.40
	var y0: float = -ph * 0.36
	var y1: float = ph * 0.12
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


## One shared BoxMesh and one shared material for a whole path — sixty nodes that all point at
## the same two resources, rather than sixty meshes and sixty materials.
func _ev_dotted(root: Node3D, points: Array, color: Color) -> void:
	var mat: StandardMaterial3D = _ev_mat(color, 1.0)
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.013, 0.013, 0.013)
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
