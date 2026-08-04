# ===========================================================================
# NOC Example 1.8: Exercise 1.8: Attraction Magnitude
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing -> GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================
#
# @identity
# essence: F = strength * dir / r^2. Inverse-square attraction. Closer = stronger. Orbit emerges from falling and missing.
# desire: To let the learner grab the attractor in VR and drag it — watching the orbiting ball reshape its path in real time.
# critical_parameter: attraction_strength — controls the force constant. Too weak → ball escapes. Too strong → ball spirals inward. The sweet spot produces stable orbits.
# triggers: VR grab attractor sphere → ball orbit changes shape, strength slider → orbits tighten or loosen, velocity clamped at 0.15 to prevent escape
# emerges: Elliptical orbits from the interplay of tangential velocity and radial attraction. Moving the attractor mid-orbit creates chaotic transitions between orbit shapes.
# needs: VR grabbable attractor [has], strength parameter controller [has], force line visualization [has]. Missing: trail showing orbit history.
# relationships: Extends bouncing_ball (adds attraction). Feeds into three_body_problem and nbody_simulation (many attractors). Gateway to gravitational dynamics.
# truth: An orbit is a perpetual fall that always misses the ground. Attraction creates structure from nothing but distance and direction.

class_name AttractionMagnitudeVR
extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const GRAB_SPHERE_SCENE := preload("res://commons/primitives/math_gallery/GrabSphere.tscn")
const MAT_BALL := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_ATTRACTOR := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")
const MAT_LINE := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_secondary.tres")

@export var attraction_strength: float = 0.5

# ═══════════════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `evidence`
# ═══════════════════════════════════════════════════════════════════════════
#
# WHAT THIS DEMO OFFERS AS PROOF THAT AN INVERSE SQUARE IS MOVING THE BALL.
#
# Gravity has no appearance. The shipped scene draws a ball, a grabbable sphere,
# a hairline between them and a rolling trail — and every number the lesson is
# actually about is invisible: the 1/r^2 itself, the 0.15 speed cap that clips
# every step, and the clamp(0.05, 0.5) that quietly SWITCHES THE LAW OFF inside
# and outside two shells nobody can see. A demonstration of an invisible force
# has to pick a fiction to draw and stand behind it, and that choice IS the
# teaching.
#
# THE WORD IS NOT NEW HERE. `evidence` with exactly these four values is taken
# character for character from example_2_8_two_body_attraction_vr — the same
# chapter, the same F = G m1 m2 / r^2, the same question — and from the Motion
# 101 family (1.7 / 1.8 / 1.9) and three_body_problem. This artifact is 2.8 with
# one body nailed to the player's hand.
#
#   result    the shipped build, byte for byte: ball, attractor, force line, the
#             rolling 300-frame trail, the readout. Where it is, now.
#   trace     the rolling window goes away and 900 steps are integrated forward
#             at BUILD time through the same _step() the running scene calls,
#             laid down as a time-coloured strip before the ball has moved once.
#             There is no random number anywhere in this demo, so this is not a
#             likely path, it is THE path — for as long as nobody touches the
#             attractor, which is the one thing the artifact exists to invite.
#             The drawn future and the walked one separate the moment a hand
#             enters the frame, and that gap is the exhibit.
#   longhand  the working instead of the answer. r drawn as a rod graduated
#             every 5 cm; the two clamp shells at 0.05 and 0.5 finally drawn, so
#             the region where the law is real is a visible band; v as an arrow
#             at x4; and F as an arrow DIVIDED by 10 to fit in the same frame,
#             because at the shipped strength |F| is 2.94 against a speed cap of
#             0.15 — twenty times the most the ball is allowed to do about it.
#   axiom     the instance gives way to the rule. A slate plate carrying
#             F = s * dir / r^2, v += F, |v| <= 0.15, p += v, with the 1/r^2
#             curve plotted against its asymptote and the two clamp radii ruled
#             onto it, so the flat shoulder and the dead tail are part of the
#             statement rather than a secret in the source.
#
# All four run the SAME physics. _step() is the single copy of the law, lifted
# out of _process unchanged; no exhibit touches the velocity, the cap or the
# clamp. What changes is what the room is allowed to see.
@export_enum("result", "trace", "longhand", "axiom") var evidence: String = "result"

## Allow-list. An unknown word in a map token falls back to the shipped build
## rather than stranding a placement with a blank exhibit.
const EVIDENCES: PackedStringArray = ["result", "trace", "longhand", "axiom"]

## The three constants the law is made of. Values unchanged — these were the inline
## literals in _process's clamp() and limit_length() and are only named so the exhibits
## can point at them.
const R_CLAMP_MIN := 0.05
const R_CLAMP_MAX := 0.5
const SPEED_CAP := 0.15

var _sim_root: Node3D
var _ball: MeshInstance3D
var _attractor_grab: Node3D  # GrabSphere for VR interaction
var _position: Vector3 = Vector3(-0.3, 0.7, 0.2)
var _velocity: Vector3 = Vector3(0.05, 0, 0.03)
var _attractor_position: Vector3 = Vector3(0, 0.5, 0)
var _ball_radius: float = 0.03
var _line_mesh: ImmediateMesh
var _line_instance: MeshInstance3D
var _trail_mesh: ImmediateMesh
var _trail_instance: MeshInstance3D
var _trail_points: Array[Vector3] = []
var _max_trail_length: int = 300
var _status_label: Label3D
var _controller_root: Node3D

## Set on the way through _force_at() / _step() so the readout can print the same two
## numbers it always printed without a second copy of the arithmetic living in _process.
var _last_distance: float = 0.0
var _last_force: Vector3 = Vector3.ZERO

## Nodes built by trace / longhand / axiom. Freed before any rebuild; empty on the
## shipped path, where not one of them is ever constructed.
var _evidence_parts: Array[Node3D] = []

func _ready() -> void:
	_read_grid_config_meta()
	_setup_environment()
	_spawn_objects()
	_setup_line()
	_apply_evidence()
	set_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)


	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 20
	_status_label.modulate = Color(1.0, 0.85, 1.0)
	_status_label.position = Vector3(0, 0.82, 0)
	_sim_root.add_child(_status_label)

	_controller_root = Node3D.new()
	_controller_root.position = Vector3(0.75, 0.5, 0)
	add_child(_controller_root)

	var strength_controller := CONTROLLER_SCENE.instantiate()
	strength_controller.parameter_name = "Strength"
	strength_controller.min_value = 0.0
	strength_controller.max_value = 1.5
	strength_controller.default_value = attraction_strength
	strength_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(strength_controller)
	strength_controller.value_changed.connect(func(v: float) -> void:
		attraction_strength = v
	)
	strength_controller.set_value(attraction_strength)

func _spawn_objects() -> void:
	_ball = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = _ball_radius
	sphere.height = _ball_radius * 2.0
	_ball.mesh = sphere
	_ball.material_override = MAT_BALL
	_sim_root.add_child(_ball)

	# Grabbable attractor sphere — move it in VR to redirect the orbiting ball
	_attractor_grab = GRAB_SPHERE_SCENE.instantiate()
	_attractor_grab.base_color = Color(1.0, 0.4, 0.7)
	_attractor_grab.object_scale = 0.08
	_attractor_grab.snap_to_shelf = false
	_attractor_grab.position = _attractor_position
	_sim_root.add_child(_attractor_grab)

func _setup_line() -> void:
	_line_mesh = ImmediateMesh.new()
	_line_instance = MeshInstance3D.new()
	_line_instance.mesh = _line_mesh
	_line_instance.material_override = MAT_LINE
	_sim_root.add_child(_line_instance)

	# Orbit trail — shows the path history
	_trail_mesh = ImmediateMesh.new()
	_trail_instance = MeshInstance3D.new()
	_trail_instance.mesh = _trail_mesh
	var trail_mat := StandardMaterial3D.new()
	trail_mat.albedo_color = Color(1.0, 0.4, 0.7, 0.35)
	trail_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_trail_instance.material_override = trail_mat
	_sim_root.add_child(_trail_instance)

## ONE STEP OF THE LAW, and the only place it is written.
##
## Lifted out of _process with the arithmetic untouched — the same clamp, the same
## normalized() of the UNCLAMPED separation, the same 0.15 cap, the same per-frame
## integration with no delta. Extracted so `trace` cannot drift from the running
## scene: an exhibit that predicts the path with its own copy of the arithmetic is
## an exhibit that will eventually be lying.
##
## Returns [position, velocity]. The two numbers the readout prints are stashed on
## the way through rather than recomputed by the caller.
func _step(p: Vector3, v: Vector3, att: Vector3) -> Array[Vector3]:
	var force: Vector3 = _force_at(p, att)

	v += force
	v = v.limit_length(SPEED_CAP)

	p += v

	_last_force = force

	var out: Array[Vector3] = [p, v]
	return out


## THE LAW ITSELF, in one place. The literals it used to carry inline are now named,
## with the same values: clamp(distance, 0.05, 0.5) and the 0.15 cap in _step above.
## Naming them is what lets `longhand` draw the two shells and `axiom` rule them onto
## the curve and be provably drawing the numbers the ball is actually obeying, rather
## than a second copy that will one day disagree.
func _force_at(p: Vector3, att: Vector3) -> Vector3:
	var to_attractor: Vector3 = att - p
	var distance: float = to_attractor.length()

	distance = clamp(distance, R_CLAMP_MIN, R_CLAMP_MAX)

	_last_distance = distance
	return to_attractor.normalized() * (attraction_strength / (distance * distance))


func _process(_delta: float) -> void:
	# Track attractor position from the grabbable sphere (local to sim_root)
	if _attractor_grab:
		_attractor_position = _attractor_grab.position

	var stepped: Array[Vector3] = _step(_position, _velocity, _attractor_position)
	_position = stepped[0]
	_velocity = stepped[1]
	_ball.position = _position

	_line_mesh.clear_surfaces()
	_line_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_line_mesh.surface_add_vertex(_position)
	_line_mesh.surface_add_vertex(_attractor_position)
	_line_mesh.surface_end()

	# Orbit trail
	_trail_points.append(_position)
	if _trail_points.size() > _max_trail_length:
		_trail_points.remove_at(0)
	_trail_mesh.clear_surfaces()
	if _trail_points.size() >= 2:
		_trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		for p in _trail_points:
			_trail_mesh.surface_add_vertex(p)
		_trail_mesh.surface_end()

	_status_label.text = "Attraction | dist: %.3f, force: %.4f" % [_last_distance, _last_force.length()]

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
## GUARDED ON CHANGE, deliberately. All 7 existing placements arrive here with no
## `evidence` key at all, and the grid reaches this twice for one placement; an
## unguarded rebuild would tear down and re-raise an exhibit on both of those, for
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

const EV_STEPS := 900           # trace: steps integrated forward at build time
const EV_EARLY := Color(0.98, 0.74, 0.26)   # trace: colour at step 0
const EV_LATE := Color(0.35, 0.76, 1.0)     # trace: colour at step EV_STEPS
const EV_V_MAG := 4.0           # longhand: magnification for v
const EV_F_DIV := 10.0          # longhand: DIVISION for F — it does not fit otherwise
const EV_TICK := 0.05           # longhand: graduation on the r rod, in metres
const EV_CHALK := Color(0.88, 0.90, 0.95)
const EV_INK := Color(0.98, 0.74, 0.26)
const EV_COOL := Color(0.35, 0.76, 1.0)
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

	# The rolling 300-frame window is the shipped trail and stays on everywhere except
	# `trace`, where a drawn future and a drawn past in the same colour would read as
	# one tangle. It is still ACCUMULATED — only the drawing is withheld.
	if is_instance_valid(_trail_instance):
		_trail_instance.visible = (want != "trace")

	if want == "result":
		return                              # the legacy lineage: nothing added

	var root := Node3D.new()
	root.name = "Evidence_%s" % want
	_sim_root.add_child(root)
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
## scene calls, from the same release state and with the attractor held where it
## currently stands.
func _ev_path(steps: int) -> Array[Vector3]:
	var p: Vector3 = _position
	var v: Vector3 = _velocity
	var att: Vector3 = _attractor_position
	var path: Array[Vector3] = [p]
	for i in range(steps):
		var stepped: Array[Vector3] = _step(p, v, att)
		p = stepped[0]
		v = stepped[1]
		path.append(p)
	return path


## TRACE — the orbit drawn instead of watched. There is no random number in this demo,
## so the whole future is implied by the release state, the strength and the position of
## the attractor, and can be printed before the ball has moved once. Coloured amber to
## blue so the ORDER of the passes is legible.
##
## The caption is not decoration. This path is true exactly as long as nobody touches the
## attractor, and touching the attractor is the entire invitation of the artifact: the
## drawn future is a standing prediction that the player is being asked to break.
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

	root.add_child(_ev_text("%d steps, drawn before they happen" % EV_STEPS,
		Vector3(-0.34, 0.92, 0.0), 14, EV_CHALK))
	root.add_child(_ev_text("true until a hand moves the attractor",
		Vector3(-0.34, 0.88, 0.0), 12, EV_COOL))


## LONGHAND — the working, not the answer. Everything _step() consumes is put on the
## geometry at the release state, including the two constants that decide where the
## inverse square is even allowed to apply.
func _ev_longhand(root: Node3D) -> void:
	var at: Vector3 = _position
	var att: Vector3 = _attractor_position
	var r: Vector3 = att - at

	# r, graduated. A rod every 5 cm, so the denominator is a countable length instead
	# of a hairline. Same graduation as example_2_8's rod.
	_ev_rod(root, at, r, 0.005, _ev_mat(EV_CHALK, 0.4))
	var ticks: int = int(r.length() / EV_TICK)
	var dir: Vector3 = r.normalized()
	var side: Vector3 = dir.cross(Vector3.UP)
	if side.length() < 0.01:
		side = dir.cross(Vector3.FORWARD)
	side = side.normalized() * 0.014
	for i in range(1, ticks + 1):
		var q: Vector3 = at + dir * (float(i) * EV_TICK)
		_ev_rod(root, q - side, side * 2.0, 0.004, _ev_mat(EV_CHALK, 0.6))
	root.add_child(_ev_text("r = %.3f  ·  tick 5 cm" % r.length(),
		at + r * 0.5 + Vector3(0.0, 0.045, 0.0), 13, EV_CHALK))

	# The two shells the law lives between. clamp(distance, 0.05, 0.5) is written into
	# _step and drawn nowhere: inside the inner shell the force stops growing, outside
	# the outer one it stops falling. Both are flat lies about gravity that this demo
	# tells every frame.
	_ev_shell(root, att, R_CLAMP_MIN, _ev_mat(EV_INK, 0.8))
	_ev_shell(root, att, R_CLAMP_MAX, _ev_mat(EV_COOL, 0.5))
	root.add_child(_ev_text("r clamped to %.2f" % R_CLAMP_MIN, att + Vector3(0.06, -0.07, 0.0), 12, EV_INK))
	root.add_child(_ev_text("...and to %.2f" % R_CLAMP_MAX, att + Vector3(R_CLAMP_MAX * 0.72, 0.30, 0.0), 12, EV_COOL))

	# v, magnified. At true scale it is about twice the ball's radius.
	_ev_arrow(root, at, _velocity * EV_V_MAG, 0.008, _ev_mat(EV_COOL, 1.0))
	root.add_child(_ev_text("v  x%d  (cap %.2f)" % [int(EV_V_MAG), SPEED_CAP],
		at + _velocity * EV_V_MAG + Vector3(0.02, 0.03, 0.0), 13, EV_COOL))

	# F, DIVIDED. Every other exhibit in this family magnifies its force arrow; this one
	# has to shrink it, and that reversal is the finding. |F| = 2.94 at the shipped
	# strength and the ball may move 0.15 — so the arrow you are looking at is twenty
	# times longer than anything the ball is permitted to do about it.
	var f_now: Vector3 = _force_at(at, att)   # the law itself, not an illustration of it
	_ev_arrow(root, at, f_now / EV_F_DIV, 0.010, _ev_mat(EV_INK, 1.4))
	root.add_child(_ev_text("F = %.2f   /%d to fit" % [f_now.length(), int(EV_F_DIV)],
		at + f_now / EV_F_DIV + Vector3(0.02, -0.04, 0.0), 13, EV_INK))


## AXIOM — the rule, standing where the example was. The plate carries the four lines
## _step() actually executes and the 1/r^2 curve with both clamp radii ruled onto it, so
## the flat shoulder and the dead tail are part of the statement.
func _ev_axiom(root: Node3D) -> void:
	var plate := Node3D.new()
	plate.position = Vector3(0.0, 0.62, -0.42)
	root.add_child(plate)

	var pw: float = 0.70
	var ph: float = 0.44
	plate.add_child(_ev_box(Vector3(0.0, 0.0, -0.012), Vector3(pw + 0.04, ph + 0.04, 0.014),
		_ev_mat(Color(0.28, 0.24, 0.20), 0.0)))
	plate.add_child(_ev_box(Vector3.ZERO, Vector3(pw, ph, 0.012), _ev_mat(EV_SLATE, 0.0)))

	# ASCII on purpose: Label3D falls back to the project font, and an operator that
	# renders as a tofu box is worse evidence than a plain line of code.
	plate.add_child(_ev_text("F = s * dir / r^2", Vector3(-0.02, ph * 0.36, 0.014), 22, EV_CHALK))
	plate.add_child(_ev_text("s = %.2f" % attraction_strength, Vector3(-0.02, ph * 0.22, 0.014), 16, EV_CHALK))
	plate.add_child(_ev_text("v += F", Vector3(-0.02, ph * 0.08, 0.014), 20, EV_INK))
	plate.add_child(_ev_text("|v| <= %.2f" % SPEED_CAP, Vector3(-0.02, ph * -0.04, 0.014), 20, EV_INK))
	plate.add_child(_ev_text("p += v", Vector3(-0.02, ph * -0.16, 0.014), 20, EV_INK))

	# 1/r^2 against its asymptote, with the two clamp radii ruled on. The curve is only
	# ever READ between them: to the left it is held flat, to the right it is held low.
	var gw: float = 0.26
	var gh: float = 0.30
	var cx: float = -pw * 0.30
	var cy: float = -ph * 0.04
	_ev_plate_frame(plate, Vector3(cx, cy, 0.014), gw, gh, _ev_mat(EV_CHALK, 0.4))

	var r_hi: float = 0.6
	var f_hi: float = attraction_strength / (R_CLAMP_MIN * R_CLAMP_MIN)
	var samples: int = 42
	for i in range(samples):
		var t: float = float(i) / float(samples - 1)
		var rr: float = 0.02 + t * (r_hi - 0.02)
		var ff: float = attraction_strength / (rr * rr)
		var gx: float = cx - gw * 0.5 + (rr / r_hi) * gw
		var gy: float = cy - gh * 0.5 + clampf(ff / f_hi, 0.0, 1.0) * gh
		plate.add_child(_ev_box(Vector3(gx, gy, 0.018), Vector3(0.006, 0.006, 0.006),
			_ev_mat(EV_INK, 1.0)))

	var x_min: float = cx - gw * 0.5 + (R_CLAMP_MIN / r_hi) * gw
	var x_max: float = cx - gw * 0.5 + (R_CLAMP_MAX / r_hi) * gw
	plate.add_child(_ev_box(Vector3(x_min, cy, 0.016), Vector3(0.004, gh, 0.006), _ev_mat(EV_COOL, 0.8)))
	plate.add_child(_ev_box(Vector3(x_max, cy, 0.016), Vector3(0.004, gh, 0.006), _ev_mat(EV_COOL, 0.8)))
	plate.add_child(_ev_text("%.2f" % R_CLAMP_MIN, Vector3(x_min - 0.020, cy - gh * 0.5 - 0.030, 0.016), 11, EV_COOL))
	plate.add_child(_ev_text("%.2f" % R_CLAMP_MAX, Vector3(x_max - 0.020, cy - gh * 0.5 - 0.030, 0.016), 11, EV_COOL))
	plate.add_child(_ev_text("the law is only read between the rules",
		Vector3(cx - gw * 0.5, cy - gh * 0.5 - 0.062, 0.016), 11, EV_CHALK))


# ── Small builders (ev_-prefixed so nothing in the demo can collide) ──────

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


## A shaft along `vec`, oriented with Basis.looking_at rather than look_at() so it does
## not care whether the node is in the tree or where the map put the artifact.
func _ev_rod(root: Node3D, from: Vector3, vec: Vector3, thick: float, m: StandardMaterial3D) -> void:
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


func _ev_arrow(root: Node3D, from: Vector3, vec: Vector3, thick: float, m: StandardMaterial3D) -> void:
	_ev_rod(root, from, vec, thick, m)
	if vec.length() < 0.001:
		return
	# The head: a cube at the tip, so the shaft reads as pointing somewhere.
	root.add_child(_ev_box(from + vec, Vector3(thick * 2.2, thick * 2.2, thick * 2.2), m))


## A clamp radius, drawn as two orthogonal rings rather than a translucent ball — a
## 0.5 m sphere around the attractor would swallow the whole demonstration.
func _ev_shell(root: Node3D, center: Vector3, radius: float, m: StandardMaterial3D) -> void:
	var segments: int = 28
	var seg_len: float = TAU * radius / float(segments) * 1.05
	var bead := BoxMesh.new()
	bead.size = Vector3(0.004, 0.004, seg_len)
	for plane in range(2):
		for i in range(segments):
			var a: float = TAU * float(i) / float(segments)
			var p: Vector3 = Vector3(cos(a) * radius, 0.0, sin(a) * radius)
			var t: Vector3 = Vector3(-sin(a), 0.0, cos(a))
			if plane == 1:
				p = Vector3(cos(a) * radius, sin(a) * radius, 0.0)
				t = Vector3(-sin(a), cos(a), 0.0)
			var up: Vector3 = Vector3.UP
			if absf(t.dot(up)) > 0.99:
				up = Vector3.FORWARD
			var mi := MeshInstance3D.new()
			mi.mesh = bead
			mi.material_override = m
			mi.transform = Transform3D(Basis.looking_at(t, up), center + p)
			root.add_child(mi)


## Four rules bounding a rectangle on the plate face.
func _ev_plate_frame(plate: Node3D, center: Vector3, w: float, h: float, m: StandardMaterial3D) -> void:
	var hw: float = w * 0.5
	var hh: float = h * 0.5
	plate.add_child(_ev_box(center + Vector3(0.0, hh, 0.0), Vector3(w, 0.004, 0.006), m))
	plate.add_child(_ev_box(center + Vector3(0.0, -hh, 0.0), Vector3(w, 0.004, 0.006), m))
	plate.add_child(_ev_box(center + Vector3(hw, 0.0, 0.0), Vector3(0.004, h, 0.006), m))
	plate.add_child(_ev_box(center + Vector3(-hw, 0.0, 0.0), Vector3(0.004, h, 0.006), m))


func _ev_text(content: String, p: Vector3, size: int, c: Color) -> Label3D:
	var l := Label3D.new()
	l.text = content
	l.font_size = size
	l.pixel_size = 0.0012
	l.modulate = c
	l.position = p
	l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	return l
