# ===========================================================================
# NOC Example 1.8: Motion 101: Velocity and Constant Acceleration
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing -> GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_BALL := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")

@export var acceleration: Vector3 = Vector3(0, -0.01, 0)

# ═══════════════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `evidence`
# ═══════════════════════════════════════════════════════════════════════════
#
# WHAT THIS DEMO OFFERS AS PROOF THAT A LAW IS MOVING THE BALL.
#
# Middle member of the Motion 101 family, and it has the family's problem in its
# purest form: `acceleration` is a constant vector nobody can see, `v` is a number
# nobody can see, and the one visible object — the ball — carries no information
# about either. The slider makes gravity settable, which is a real gift, but a
# slider is a control, not evidence: it lets you change the law without ever
# showing you what the law does between two frames.
#
# example_1_9 (the same scene with a random right-hand side) already answers this
# question with the word `evidence` and the values result / trace / longhand /
# axiom, taken there from example_2_8, example_2_9 and the six artifacts that use
# it about their own working. This takes the SAME WORD AND THE SAME FOUR VALUES
# character for character rather than inventing a synonym, so the family answers
# one question in one vocabulary.
#
#   result    the shipped build, byte for byte: the pink ball falling, bouncing
#             at -0.95, and the Gravity slider beside it. Where it is, now. No
#             history at all — this demo does not even keep a trail. The legacy
#             lineage.
#   trace     the whole future, drawn before it happens. EV_STEPS steps integrated
#             forward here, at build time, through the identical _step() the running
#             _process calls, laid down as a line strip coloured through time. With
#             a constant acceleration and no random draw anywhere, this is not a
#             replay of a likely path — it is THE path, and the decaying bounce
#             envelope it exposes is something a single moving ball can never show.
#   longhand  the working instead of the answer. The tank the -0.95 bounce acts on
#             stops being invisible and becomes a wire box; `a` is drawn as an arrow
#             at the ball, magnified x20 so a 0.01 step is bigger than the ball it
#             moves; `v` as a second arrow at x4; and the first EV_STROBE_COUNT
#             positions are stamped every EV_STROBE_EVERY steps — equal time, growing
#             gap, which IS what constant acceleration looks like from outside.
#   axiom     the instance gives way to the rule. A plate behind the tank carries the
#             two lines of the update, the constant it adds, and the second-difference
#             statement they amount to, with a ruler of n-squared ticks under it. The
#             ball keeps falling in front, demoted from subject to example.
#
# All four run the SAME physics. _step() is untouched and is the only copy of the
# law; nothing here reaches the acceleration, the integration or the bounce. What
# changes is what the room is allowed to see.
@export_enum("result", "trace", "longhand", "axiom") var evidence: String = "result"

## Allow-list. An unknown word in a map token falls back to the shipped ball-and-slider
## rather than stranding a placement with a blank exhibit.
const EVIDENCES: PackedStringArray = ["result", "trace", "longhand", "axiom"]

var _sim_root: Node3D
var _ball: MeshInstance3D
var _position: Vector3 = Vector3(0, 0.8, 0)
var _velocity: Vector3 = Vector3(0.05, 0, 0.03)
var _bounds_min: Vector3 = Vector3(-0.45, 0.05, -0.45)
var _bounds_max: Vector3 = Vector3(0.45, 0.95, 0.45)
var _ball_radius: float = 0.03
var _controller_root: Node3D

## Nodes built by trace / longhand / axiom. Freed before any rebuild; empty on the shipped
## path, where not one of them is ever constructed.
var _evidence_parts: Array[Node3D] = []

func _ready() -> void:
	_read_grid_config_meta()
	_setup_environment()
	_spawn_ball()
	_apply_evidence()
	set_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)


	_controller_root = Node3D.new()
	_controller_root.position = Vector3(0.75, 0.5, 0)
	add_child(_controller_root)

	var gravity_controller := CONTROLLER_SCENE.instantiate()
	gravity_controller.parameter_name = "Gravity"
	gravity_controller.min_value = -0.03
	gravity_controller.max_value = 0.03
	gravity_controller.default_value = acceleration.y
	gravity_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(gravity_controller)
	gravity_controller.value_changed.connect(func(v: float) -> void:
		acceleration.y = v
	)
	gravity_controller.set_value(acceleration.y)

func _spawn_ball() -> void:
	_ball = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = _ball_radius
	sphere.height = _ball_radius * 2.0
	_ball.mesh = sphere
	_ball.material_override = MAT_BALL
	_sim_root.add_child(_ball)


## ONE STEP OF THE LAW, and the only place it is written.
##
## Lifted out of _process unchanged so that `trace` cannot drift from the running scene: an
## exhibit that predicts the path with its own copy of the arithmetic is an exhibit that will
## eventually be lying. Returns [position, velocity]; nothing about the numbers changed.
func _step(p: Vector3, v: Vector3) -> Array[Vector3]:
	v += acceleration
	p += v

	if p.x - _ball_radius < _bounds_min.x or p.x + _ball_radius > _bounds_max.x:
		v.x *= -0.95
		p.x = clamp(p.x, _bounds_min.x + _ball_radius, _bounds_max.x - _ball_radius)

	if p.y - _ball_radius < _bounds_min.y or p.y + _ball_radius > _bounds_max.y:
		v.y *= -0.95
		p.y = clamp(p.y, _bounds_min.y + _ball_radius, _bounds_max.y - _ball_radius)

	if p.z - _ball_radius < _bounds_min.z or p.z + _ball_radius > _bounds_max.z:
		v.z *= -0.95
		p.z = clamp(p.z, _bounds_min.z + _ball_radius, _bounds_max.z - _ball_radius)

	var out: Array[Vector3] = [p, v]
	return out


func _process(_delta: float) -> void:
	var stepped: Array[Vector3] = _step(_position, _velocity)
	_position = stepped[0]
	_velocity = stepped[1]

	_ball.position = _position

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
		node = node.get_parent()


## Config from map_data.json tokens: #evidence:trace  ·  #evidence:longhand
##
## GUARDED ON CHANGE, deliberately. A placement carrying any other token arrives here with no
## `evidence` key at all, and the grid reaches this twice for one placement; an unguarded
## rebuild would tear down and re-raise an exhibit on both of those, for nothing.
func apply_grid_config(config: Dictionary) -> void:
	var was_evidence: String = evidence

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

const EV_STEPS := 240           # trace: steps integrated forward at build time
const EV_EARLY := Color(0.98, 0.74, 0.26)   # trace: colour at step 0
const EV_LATE := Color(0.35, 0.76, 1.0)     # trace: colour at step EV_STEPS
const EV_MAG_A := 20.0          # longhand: magnification for the acceleration arrow
const EV_MAG_V := 4.0           # longhand: magnification for the velocity arrow
const EV_STROBE_COUNT := 14     # longhand: how many stamped positions
const EV_STROBE_EVERY := 2      # longhand: steps between stamps
const EV_CHALK := Color(0.88, 0.90, 0.95)
const EV_INK := Color(0.98, 0.74, 0.26)
const EV_SKY := Color(0.35, 0.76, 1.0)
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
		return                              # the legacy lineage: ball + slider, nothing added

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


## Integrate the release state forward without touching the running scene's own state.
func _ev_forecast(steps: int) -> Array[Vector3]:
	var p: Vector3 = _position
	var v: Vector3 = _velocity
	var path: Array[Vector3] = [p]
	for i in range(steps):
		var stepped: Array[Vector3] = _step(p, v)
		p = stepped[0]
		v = stepped[1]
		path.append(p)
	return path


## TRACE — the flight drawn instead of watched. EV_STEPS steps run here, at build time, through
## the same _step() the running scene calls, from the same release state. There is no random
## draw anywhere in this demo, so this is not a likely path or a sibling of the real one: it is
## the path, available in full at frame zero. What it shows that a moving ball cannot is the
## ENVELOPE — bounce after bounce at -0.95, the arcs shrinking toward the floor.
func _ev_trace(root: Node3D) -> void:
	var path: Array[Vector3] = _ev_forecast(EV_STEPS)

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
		Vector3(-0.26, _bounds_max.y + 0.05, 0.0), 15, EV_CHALK))


## LONGHAND — the working, not the answer. Everything `v += a; p += v` consumes is put on the
## geometry at the release state: the tank the -0.95 bounce acts on, the constant `a` as an
## arrow, the current `v` as a second arrow, and the first fall stamped every other step.
## Magnified and labelled as such, because 0.01 m at true scale is a third of the ball's radius
## and would be evidence of nothing.
func _ev_longhand(root: Node3D) -> void:
	var at: Vector3 = _position

	# The tank. Hard-coded in _bounds_min/_bounds_max and never drawn until now.
	_ev_wire_box(root, (_bounds_min + _bounds_max) * 0.5, _bounds_max - _bounds_min,
		0.004, _ev_mat(EV_CHALK, 0.25))
	root.add_child(_ev_text("bounce -0.95", Vector3(_bounds_min.x + 0.10, _bounds_min.y + 0.03, _bounds_max.z),
		13, EV_CHALK))

	# The constant. This is the whole subject of the demo and it has never been visible.
	_ev_arrow(root, at, at + acceleration * EV_MAG_A, 0.006, _ev_mat(EV_INK, 1.0))
	root.add_child(_ev_text("a = (0, %.2f, 0)  x%d" % [acceleration.y, int(EV_MAG_A)],
		at + acceleration * EV_MAG_A + Vector3(0.04, -0.02, 0.0), 14, EV_INK))

	# The thing the constant is being added TO, at its release value.
	_ev_arrow(root, at, at + _velocity * EV_MAG_V, 0.005, _ev_mat(EV_SKY, 1.0))
	root.add_child(_ev_text("v  x%d" % int(EV_MAG_V),
		at + _velocity * EV_MAG_V + Vector3(0.02, 0.03, 0.0), 13, EV_SKY))

	# EQUAL TIME, GROWING GAP. The first fall stamped every EV_STROBE_EVERY steps: the gaps
	# between stamps are the velocity, and the fact that they lengthen by the same amount each
	# time is the acceleration. This is constant acceleration seen from outside, with no
	# arithmetic in it.
	var path: Array[Vector3] = _ev_forecast(EV_STROBE_COUNT * EV_STROBE_EVERY)
	var stamps: Array[Vector3] = []
	var i: int = 0
	while i < path.size():
		stamps.append(path[i])
		i += EV_STROBE_EVERY
	_ev_ghosts(root, stamps, _ev_mat(EV_CHALK, 0.5))
	root.add_child(_ev_text("every %d steps: equal time, growing gap" % EV_STROBE_EVERY,
		Vector3(-0.30, _bounds_max.y + 0.05, 0.0), 13, EV_CHALK))


## AXIOM — the rule, standing where the example was. A plate behind the tank carries the two
## lines of the update, the constant they add, and what those two lines amount to: a constant
## SECOND difference. Under it, a ruler of n-squared ticks, which is the same statement drawn.
## The ball keeps falling in front of it, demoted from the subject to an instance.
func _ev_axiom(root: Node3D) -> void:
	var plate := Node3D.new()
	plate.position = Vector3(0.0, 0.55, _bounds_min.z - 0.10)
	root.add_child(plate)

	var pw: float = 0.70
	var ph: float = 0.42
	plate.add_child(_ev_box(Vector3(0.0, 0.0, -0.012), Vector3(pw + 0.04, ph + 0.04, 0.014),
		_ev_mat(Color(0.28, 0.24, 0.20), 0.0)))
	plate.add_child(_ev_box(Vector3.ZERO, Vector3(pw, ph, 0.012), _ev_mat(EV_SLATE, 0.0)))

	# ASCII on purpose: Label3D falls back to the project font, and a delta or a subscript that
	# renders as a tofu box is worse evidence than a plain line of code.
	plate.add_child(_ev_text("a = (0, %.2f, 0)   constant" % acceleration.y,
		Vector3(-0.03, ph * 0.34, 0.014), 20, EV_CHALK))
	plate.add_child(_ev_text("v += a", Vector3(-0.03, ph * 0.16, 0.014), 22, EV_INK))
	plate.add_child(_ev_text("p += v", Vector3(-0.03, ph * 0.02, 0.014), 22, EV_INK))
	plate.add_child(_ev_text("so  p(n+1) - 2p(n) + p(n-1) = a", Vector3(-0.03, -ph * 0.16, 0.014),
		15, EV_SKY))

	# The same sentence as geometry: ticks at n-squared spacing along a rule. Equal steps in n,
	# widening steps in p — the signature, with the demo taken out of it.
	var rule_y: float = -ph * 0.34
	var rule_x: float = -pw * 0.42
	var span: float = pw * 0.80
	plate.add_child(_ev_box(Vector3(rule_x + span * 0.5, rule_y, 0.014),
		Vector3(span, 0.004, 0.006), _ev_mat(EV_CHALK, 0.4)))
	var ticks: int = 9
	for n in range(ticks + 1):
		var u: float = float(n) / float(ticks)
		var mi: MeshInstance3D = _ev_box(Vector3(rule_x + span * u * u, rule_y, 0.018),
			Vector3(0.006, 0.030, 0.006), _ev_mat(EV_INK, 1.2))
		plate.add_child(mi)
	plate.add_child(_ev_text("n = 0 .. %d, drawn at n squared" % ticks,
		Vector3(rule_x, rule_y - 0.045, 0.016), 12, EV_CHALK))


# ── Small builders (ev_-prefixed so nothing in the demo can collide) ──────

## Hollow-looking stand-ins for the ball at earlier moments: same radius, dimmer, unlit.
func _ev_ghosts(root: Node3D, points: Array[Vector3], m: StandardMaterial3D) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = _ball_radius * 0.7
	mesh.height = _ball_radius * 1.4
	for p in points:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = m
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


## Shaft plus cone head, both aimed down `to - from`. Cylinder meshes run along +Y, so each
## piece is rotated by the shortest arc from UP to the direction.
func _ev_arrow(root: Node3D, from: Vector3, to: Vector3, thick: float, m: StandardMaterial3D) -> void:
	var d: Vector3 = to - from
	var total: float = d.length()
	if total < 0.001:
		return
	var dir: Vector3 = d / total
	var head: float = minf(total * 0.4, thick * 6.0)
	var shaft_len: float = maxf(total - head, 0.001)

	var shaft := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = thick
	cyl.bottom_radius = thick
	cyl.height = shaft_len
	shaft.mesh = cyl
	shaft.material_override = m
	shaft.position = from + dir * (shaft_len * 0.5)
	_ev_aim(shaft, dir)
	root.add_child(shaft)

	var tip := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = thick * 2.4
	cone.height = head
	tip.mesh = cone
	tip.material_override = m
	tip.position = from + dir * (shaft_len + head * 0.5)
	_ev_aim(tip, dir)
	root.add_child(tip)


func _ev_aim(node: Node3D, dir: Vector3) -> void:
	var d: Vector3 = dir.normalized()
	var dot: float = clampf(Vector3.UP.dot(d), -1.0, 1.0)
	if dot > 0.9999:
		return
	if dot < -0.9999:
		node.rotation_degrees = Vector3(180.0, 0.0, 0.0)
		return
	var axis: Vector3 = Vector3.UP.cross(d).normalized()
	var ang: float = acos(dot)
	node.rotation = Basis(axis, ang).get_euler()


func _ev_text(content: String, p: Vector3, size: int, c: Color) -> Label3D:
	var l := Label3D.new()
	l.text = content
	l.font_size = size
	l.pixel_size = 0.0012
	l.modulate = c
	l.position = p
	l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	return l
