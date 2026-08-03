# ===========================================================================
# NOC Example 1.7: Motion 101: Velocity
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const MAT_BALL := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")

# ═══════════════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `evidence`
# ═══════════════════════════════════════════════════════════════════════════
#
# WHAT THIS DEMO OFFERS AS PROOF THAT A LAW IS MOVING THE BALL.
#
# The shipped scene is a pink sphere drifting and bouncing in an invisible box.
# `v` is a constant nobody can see, the tank is nowhere in the picture, and the
# only visible object — the ball — carries no information at all about the rule
# it obeys. Every demonstration therefore has to pick a fiction to draw and stand
# behind it, and that choice IS the teaching.
#
# THE WORD IS NOT NEW HERE. example_1_9 (velocity + random acceleration) was
# promoted on `evidence` first, and this takes ITS WORD AND ITS VALUE LIST
# character for character. The three Motion 101 demos — 1.7 velocity, 1.8
# velocity + constant acceleration, 1.9 velocity + random acceleration — are one
# scene with a different right-hand side, and one argument at three stages; a map
# that asks all three for `longhand` should get three answers to the same
# question, not three vocabularies.
#
# What the shared word buys HERE is the extreme case. 1.9's trace has to be drawn
# from a pinned seed or it is a sibling of the walk rather than the walk. This one
# has no dice in it whatsoever: the whole future is already implied by three
# numbers, and `trace` draws it with nothing pinned, nothing seeded, nothing
# hedged. That is the difference between the two demos, made into a picture.
#
#   result    the shipped build, byte for byte: the ball, and nothing else. Where
#             it is, with the rule and the history both discarded. The legacy
#             lineage.
#   trace     the ENTIRE PATH, integrated forward here at build time through the
#             identical _step() the running scene calls, and laid down as a
#             coloured line strip before the ball has moved once. The ball then
#             runs along it exactly. No seed, no fixture: a demo with no random
#             number in it can print its own future and be held to it.
#   longhand  the working instead of the answer. The tank the bounce acts on
#             stops being invisible and becomes a wire box; v is drawn from the
#             ball as an arrow magnified x4 so a 0.11 m/s vector is bigger than a
#             fingernail; and the first forty Euler steps are dropped as dots, all
#             the same distance apart, which is what "constant velocity" looks
#             like when you stop saying it and draw it.
#   axiom     the instance gives way to the rule. A plate behind the tank carries
#             the two lines of the update and the wall condition, and where 1.9
#             draws a uniform box full of scatter this draws its support: a single
#             dot. v is not sampled. That IS the difference between the two demos,
#             stated on the wall in the same layout.
#
# All four run the SAME physics. _step() is untouched; nothing here reaches the
# velocity or the bounce. What changes is what the room is allowed to see.
@export_enum("result", "trace", "longhand", "axiom") var evidence: String = "result"

## Allow-list. An unknown word in a map token falls back to the shipped bare ball
## rather than stranding a placement with a blank exhibit.
const EVIDENCES: PackedStringArray = ["result", "trace", "longhand", "axiom"]

var _sim_root: Node3D
var _ball: MeshInstance3D
var _position: Vector3 = Vector3(0, 0.5, 0)
var _velocity: Vector3 = Vector3(0.08, 0.05, 0.06)
var _bounds_min: Vector3 = Vector3(-0.45, 0.05, -0.45)
var _bounds_max: Vector3 = Vector3(0.45, 0.95, 0.45)
var _ball_radius: float = 0.03

## Nodes built by trace / longhand / axiom. Freed before any rebuild; empty on the
## shipped path, where not one of them is ever constructed.
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
## Extracted from _process so that `trace` cannot drift from the running scene: an
## exhibit that predicts the path with its own copy of the arithmetic is an exhibit
## that will eventually be lying. Returns [position, velocity]; nothing about the
## numbers changed.
func _step(p: Vector3, v: Vector3, dt: float) -> Array[Vector3]:
	p += v * dt * 10.0

	if p.x - _ball_radius < _bounds_min.x or p.x + _ball_radius > _bounds_max.x:
		v.x *= -1.0
		p.x = clamp(p.x, _bounds_min.x + _ball_radius, _bounds_max.x - _ball_radius)

	if p.y - _ball_radius < _bounds_min.y or p.y + _ball_radius > _bounds_max.y:
		v.y *= -1.0
		p.y = clamp(p.y, _bounds_min.y + _ball_radius, _bounds_max.y - _ball_radius)

	if p.z - _ball_radius < _bounds_min.z or p.z + _ball_radius > _bounds_max.z:
		v.z *= -1.0
		p.z = clamp(p.z, _bounds_min.z + _ball_radius, _bounds_max.z - _ball_radius)

	var out: Array[Vector3] = [p, v]
	return out


func _process(delta: float) -> void:
	var stepped: Array[Vector3] = _step(_position, _velocity, delta)
	_position = stepped[0]
	_velocity = stepped[1]

	_ball.position = _position

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## Grid config arrives twice and by two different routes: GridInteractablesComponent
## sets config_<key> metadata on the instantiated root and then calls
## apply_grid_config(), and the capture harness calls apply_grid_config() before the
## scene enters the tree. Reading the metadata on the way in means the exhibit is
## built once, correctly, instead of built as `result` and then torn down.
##
## Costs nothing when no token is present: the export keeps its default and not a
## single existing placement changes.
func _read_grid_config_meta() -> void:
	var node: Node = self
	while node != null:
		if node.has_meta("config_evidence"):
			evidence = str(node.get_meta("config_evidence"))
		node = node.get_parent()


## Config from map_data.json tokens: #evidence:trace  ·  #evidence:longhand
##
## GUARDED ON CHANGE, deliberately. A placement carrying any other token arrives here
## with no `evidence` key at all, and the grid reaches this twice for one placement;
## an unguarded rebuild would tear down and re-raise an exhibit on both of those, for
## nothing.
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

const EV_STEPS := 1200          # trace: steps integrated forward at build time
const EV_DT := 0.016666         # trace/longhand: one 60 Hz frame, the tick the demo runs at
const EV_EARLY := Color(0.98, 0.74, 0.26)   # trace: colour at step 0
const EV_LATE := Color(0.35, 0.76, 1.0)     # trace: colour at step EV_STEPS
const EV_MAG := 4.0             # longhand: magnification for v
const EV_SAMPLES := 40          # longhand: Euler steps dropped as dots
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
		return                              # the legacy lineage: a bare ball, nothing added

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


## The path this demo is going to take, run here through the same _step() the running
## scene calls, from the same start state. Every exhibit that needs to know where the
## ball is going asks this rather than writing the arithmetic out a second time.
func _ev_path(steps: int) -> Array[Vector3]:
	var p: Vector3 = _position
	var v: Vector3 = _velocity
	var path: Array[Vector3] = [p]
	for i in range(steps):
		var stepped: Array[Vector3] = _step(p, v, EV_DT)
		p = stepped[0]
		v = stepped[1]
		path.append(p)
	return path


## TRACE — the walk drawn instead of watched, and here the strong form of that claim:
## there is no random number anywhere in this demo, so the whole billiard is implied by
## three constants and can be printed before the ball has moved once. The ball then runs
## along it. Coloured through time, amber to blue, so the ORDER of the bounces is legible
## and the drawing is not just a tangle.
func _ev_trace(root: Node3D) -> void:
	var path: Array[Vector3] = _ev_path(EV_STEPS)

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

	root.add_child(_ev_text("%d steps, drawn before they happen — and not one of them a draw" % EV_STEPS,
		Vector3(-0.34, _bounds_max.y + 0.05, 0.0), 14, EV_CHALK))


## LONGHAND — the working, not the answer. Everything `p += v` consumes is put on the
## geometry at the release state: the tank the bounce acts on, v itself as an arrow, and
## the first forty steps as evenly spaced dots. Magnified x4 and labelled as such, because
## v at true scale is shorter than the ball's diameter and would be evidence of nothing.
func _ev_longhand(root: Node3D) -> void:
	var at: Vector3 = _position

	# The tank. Hard-coded in _bounds_min/_bounds_max and never drawn until now.
	_ev_wire_box(root, (_bounds_min + _bounds_max) * 0.5, _bounds_max - _bounds_min,
		0.004, _ev_mat(EV_CHALK, 0.25))
	root.add_child(_ev_text("wall: v *= -1", Vector3(_bounds_min.x + 0.10, _bounds_min.y + 0.03, _bounds_max.z),
		13, EV_CHALK))

	# v itself, from the ball, magnified.
	_ev_arrow(root, at, _velocity * EV_MAG, 0.008, _ev_mat(EV_INK, 1.0))
	root.add_child(_ev_text("v = (0.08, 0.05, 0.06)  x%d" % int(EV_MAG),
		at + _velocity * EV_MAG + Vector3(0.02, 0.03, 0.0), 14, EV_INK))

	# Forty real steps, dropped where they land. Not decoration — these are the first
	# forty positions this ball is about to occupy, and the fact that the gaps are all
	# identical is the entire content of "constant velocity".
	var path: Array[Vector3] = _ev_path(EV_SAMPLES)
	_ev_dotted(root, path, EV_INK, 0.008)
	root.add_child(_ev_text("p += v  ·  equal steps, forever",
		path[path.size() - 1] + Vector3(0.02, -0.04, 0.0), 13, EV_INK))


## AXIOM — the rule, standing where the example was. A plate behind the tank carries the
## update and the wall condition, and the square that in example_1_9 is filled with two
## hundred draws from a uniform holds exactly one dot here, because v is not sampled from
## anything. Same plate, same layout, one dot against two hundred: the family argument.
func _ev_axiom(root: Node3D) -> void:
	var plate := Node3D.new()
	plate.position = Vector3(0.0, 0.55, _bounds_min.z - 0.10)
	root.add_child(plate)

	var pw: float = 0.70
	var ph: float = 0.42
	plate.add_child(_ev_box(Vector3(0.0, 0.0, -0.012), Vector3(pw + 0.04, ph + 0.04, 0.014),
		_ev_mat(Color(0.28, 0.24, 0.20), 0.0)))
	plate.add_child(_ev_box(Vector3.ZERO, Vector3(pw, ph, 0.012), _ev_mat(EV_SLATE, 0.0)))

	# ASCII on purpose: Label3D falls back to the project font, and an operator that
	# renders as a tofu box is worse evidence than a plain line of code.
	plate.add_child(_ev_text("v = (0.08, 0.05, 0.06)", Vector3(-0.03, ph * 0.34, 0.014), 22, EV_CHALK))
	plate.add_child(_ev_text("p += v", Vector3(-0.03, ph * 0.16, 0.014), 22, EV_INK))
	plate.add_child(_ev_text("wall: v *= -1", Vector3(-0.03, ph * 0.02, 0.014), 22, EV_INK))

	# The support of v: a point. The frame is the one example_1_9 fills with scatter.
	var sq: float = 0.20
	var cx: float = -pw * 0.30
	var cy: float = -ph * 0.22
	_ev_plate_frame(plate, Vector3(cx, cy, 0.014), sq, _ev_mat(EV_CHALK, 0.4))
	var dot := _ev_box(Vector3(cx, cy, 0.018), Vector3(0.012, 0.012, 0.006), _ev_mat(EV_INK, 1.2))
	plate.add_child(dot)
	plate.add_child(_ev_text("constant", Vector3(cx - 0.024, cy - sq * 0.5 - 0.035, 0.016), 13, EV_CHALK))


# ── Small builders (ev_-prefixed so nothing in the demo can collide) ──────

## One shared mesh and one shared material for a whole path — N nodes that all point at
## the same two resources, rather than N meshes and N materials.
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


## A shaft along `vec`, oriented with Basis.looking_at rather than look_at() so it does
## not care whether the node is in the tree or where the map put the artifact.
func _ev_arrow(root: Node3D, from: Vector3, vec: Vector3, thick: float, m: StandardMaterial3D) -> void:
	var length: float = vec.length()
	if length < 0.001:
		return
	var up: Vector3 = Vector3.UP
	if absf(vec.normalized().dot(up)) > 0.99:
		up = Vector3.FORWARD

	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(thick, thick, length)
	mi.mesh = bm
	mi.material_override = m
	mi.transform = Transform3D(Basis.looking_at(vec, up), from + vec * 0.5)
	root.add_child(mi)

	# The head: a cube at the tip, so the shaft reads as pointing somewhere.
	root.add_child(_ev_box(from + vec, Vector3(thick * 2.2, thick * 2.2, thick * 2.2), m))


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


func _ev_text(content: String, p: Vector3, size: int, c: Color) -> Label3D:
	var l := Label3D.new()
	l.text = content
	l.font_size = size
	l.pixel_size = 0.0012
	l.modulate = c
	l.position = p
	l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	return l
