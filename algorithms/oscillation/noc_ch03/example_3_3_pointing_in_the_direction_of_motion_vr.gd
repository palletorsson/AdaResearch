# ===========================================================================
# NOC Example 3.3: Pointing in the Direction of Motion
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing -> GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================
#
# @identity
# essence: look_at(position + velocity). A cone that always points where it is going. Orientation derived from velocity, not set independently.
# desire: To show that direction of motion IS orientation — the cone's nose traces its velocity vector, making heading a consequence of movement, not a choice.
# critical_parameter: thrust_magnitude (0.01-0.15) — controls how quickly the mover changes direction. Low thrust = gentle curves. High thrust = sharp turns.
# triggers: Automatic — sinusoidal thrust direction drives the mover in Lissajous-like 3D curves. VR thrust slider → adjusts responsiveness. Mover wraps at boundaries.
# emerges: The cone's orientation lagging behind direction changes, showing inertia. Smooth curves from continuous thrust. The mover tracing invisible Lissajous figures.
# needs: VR thrust parameter controller [has], cone visual pointing along velocity [has]. Missing: trail visualization, multiple movers.
# relationships: Companion to example_3_2 (arbitrary angular motion vs velocity-aligned orientation). Used by vector_drone (enemy AI points toward player). Core concept for steering behaviors.
# truth: A thing that points where it moves has surrendered its identity to its velocity. Heading is not chosen; it is inherited from motion.

class_name PointingInDirectionOfMotionVR
extends Node3D
const ARTIFACT_SCENE_PRESENTER := preload("res://commons/artifacts/ArtifactScenePresenter.gd")

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_MOVER := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")

@export var thrust_magnitude: float = 0.05

# ═══════════════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `evidence`
# ═══════════════════════════════════════════════════════════════════════════
#
# WHAT THIS DEMO OFFERS AS PROOF THAT THE CONE IS POINTING WHERE IT IS GOING.
#
# The claim in the header is that orientation is DERIVED and not chosen. The
# shipped scene cannot show that, and not because it is badly made: a cone
# pointing somewhere is just a cone pointing somewhere. Without v in the picture
# there is no difference between a heading inherited from motion and a heading
# typed in by hand, which is exactly the thing this example exists to distinguish.
# So the demonstration has to pick a fiction to draw and stand behind it, and
# that choice IS the teaching.
#
# THE WORD IS NOT NEW HERE. `evidence` with exactly these four values is taken
# character for character from the Motion 101 family (1.7 / 1.8 / 1.9),
# exercise_1_8, example_2_8, three_body_problem and slope_tangent_demo. This is
# the same question those artifacts ask — what may be shown of an invisible law —
# asked of a heading instead of a position.
#
#   result    the shipped build, byte for byte: one cone, drifting and wrapping,
#             with a speed readout. Where it points, now, with the reason
#             discarded. The legacy lineage, and not one node is added.
#   trace     the history drawn instead of watched — and here the history is a
#             history of DIRECTIONS, because that is what this demo is about.
#             1800 steps of the velocity are integrated forward at build time
#             through the same step_velocity() the running scene calls, and the
#             unit vector at each step is laid on a 0.30 m sphere as a coloured
#             strip: the set of headings this cone will take, drawn before it
#             takes them. The POSITION path is deliberately not drawn, and the
#             caption says why — see the note under `longhand`.
#   longhand  the working instead of the answer. The tank the wrap acts on stops
#             being invisible and becomes a wire box; the thrust is drawn at x4;
#             and v is drawn at TRUE SCALE, which is where this artifact's own
#             arithmetic gives itself away. p += v * delta * 60 advances by |v|
#             once per 60 Hz frame, |v| saturates at max_speed = 0.5, and the
#             tank is 0.9 m across. So the arrow you are looking at is one
#             frame, and two frames leave the box. Both are drawn.
#   axiom     the instance gives way to the rule. A slate carries look_at(p + v)
#             and, beside it, THE COUNTEREXAMPLE this demo has never shown: two
#             cones over one identical velocity arrow, the first taking its
#             heading from that arrow, the second holding a heading set
#             independently of it. One of the two is this artifact, and the
#             picture is what makes the sentence in the header falsifiable.
#
# All four run the SAME physics. step_velocity() is the single copy of the law,
# lifted out of update() unchanged; no exhibit touches the velocity, the cap or
# the wrap. What changes is what the room is allowed to see.
@export_enum("result", "trace", "longhand", "axiom") var evidence: String = "result"

## Allow-list. An unknown word in a map token falls back to the shipped bare cone
## rather than stranding a placement with a blank exhibit.
const EVIDENCES: PackedStringArray = ["result", "trace", "longhand", "axiom"]

## The release state, named rather than inlined so the exhibits can integrate from the
## same two numbers the mover is actually given. Values unchanged.
const RELEASE_POSITION := Vector3(0.0, 0.5, 0.0)
const RELEASE_VELOCITY := Vector3(0.2, 0.1, 0.0)

var _sim_root: Node3D
var _mover: DirectionalMover
var _status_label: Label3D
var _controller_root: Node3D

## Nodes built by trace / longhand / axiom. Freed before any rebuild; empty on the
## shipped path, where not one of them is ever constructed.
var _evidence_parts: Array[Node3D] = []

func _ready() -> void:
	_read_grid_config_meta()
	_setup_environment()
	_spawn_mover()
	# BEFORE the presentation, deliberately: ArtifactScenePresenter fits _sim_root into the
	# 0.82 m cube, so an exhibit raised after the fit would be framed on its own terms and
	# not with the demo. At `result` nothing is added and the fit is the one it always was.
	_apply_evidence()
	call_deferred("_apply_standard_presentation")
	set_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)


	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 22
	_status_label.modulate = Color(1.0, 0.85, 1.0)
	_status_label.position = Vector3(0, 0.82, 0)
	_sim_root.add_child(_status_label)

	_controller_root = Node3D.new()
	_controller_root.position = Vector3(0.75, 0.45, 0)
	add_child(_controller_root)

	var thrust_controller := CONTROLLER_SCENE.instantiate()
	thrust_controller.parameter_name = "Thrust"
	thrust_controller.min_value = 0.01
	thrust_controller.max_value = 0.15
	thrust_controller.default_value = thrust_magnitude
	thrust_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(thrust_controller)
	thrust_controller.value_changed.connect(func(v: float) -> void:
		thrust_magnitude = v
	)
	thrust_controller.set_value(thrust_magnitude)

func _spawn_mover() -> void:
	_mover = DirectionalMover.new()
	_mover.init(_sim_root, MAT_MOVER)
	_mover.position = RELEASE_POSITION
	_mover.velocity = RELEASE_VELOCITY


## THE THRUST, and the only place it is written. Lifted out of _process with the three
## coefficients untouched, so an exhibit that predicts the heading walk runs the demo's
## own function rather than a second copy that will one day disagree.
##
## Note what `t` is at the call site: Time.get_ticks_msec(), i.e. ENGINE UPTIME. This
## demo's trajectory therefore depends on how long Godot has been running, and it has no
## canonical run. The exhibits integrate from t = 0 and say so.
func _thrust_at(t: float) -> Vector3:
	var thrust_dir: Vector3 = Vector3(sin(t * 0.6), cos(t * 0.8), sin(t * 0.4))
	thrust_dir = thrust_dir.normalized()
	return thrust_dir * thrust_magnitude


func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var thrust := _thrust_at(t)

	_mover.apply_force(thrust)
	_mover.update(delta)
	_mover.wrap_bounds()

	_status_label.text = "Pointing | Speed %.2f" % _mover.velocity.length()

class DirectionalMover:
	## The tank, named where wrap_bounds() actually uses it. These were six inline literals
	## and the numbers are unchanged; naming them is what lets `longhand` draw the box the
	## wrap acts on and be provably drawing the same box the mover obeys.
	const TANK_MIN := Vector3(-0.45, 0.05, -0.45)
	const TANK_MAX := Vector3(0.45, 0.95, 0.45)

	var root: Node3D
	var body: MeshInstance3D
	var velocity: Vector3 = Vector3.ZERO
	var acceleration: Vector3 = Vector3.ZERO
	var max_speed: float = 0.5

	## ONE STEP OF THE VELOCITY, and the only place it is written. Lifted verbatim out of
	## update() — (v + force) then limit_length(cap), the same two operations in the same
	## order. Static so an exhibit can integrate the law forward without owning a mover.
	static func step_velocity(v: Vector3, force: Vector3, cap: float) -> Vector3:
		return (v + force).limit_length(cap)

	var position: Vector3:
		get:
			if not is_instance_valid(root):
				return Vector3.ZERO
			return root.global_position
		set(value):
			if not is_instance_valid(root):
				return
			if root.get_parent() is Node3D:
				var det := (root.get_parent() as Node3D).global_transform.basis.determinant()
				if abs(det) < 0.0001:
					root.position = value
					return
			root.global_position = value

	func init(parent: Node3D, mat: Material) -> void:
		root = Node3D.new()
		root.name = "Mover"
		parent.add_child(root)

		body = MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0  # Makes it a cone
		cone.bottom_radius = 0.04
		cone.height = 0.14
		body.mesh = cone
		body.material_override = mat
		root.add_child(body)

	func apply_force(force: Vector3) -> void:
		acceleration += force

	func update(delta: float) -> void:
		velocity = step_velocity(velocity, acceleration, max_speed)
		position += velocity * delta * 60.0
		acceleration = Vector3.ZERO

		if velocity.length() > 0.01 and is_instance_valid(root):
			var target_pos := position + velocity
			if root.position.distance_squared_to(target_pos) > 0.0001:
				if root.get_parent() is Node3D:
					var det := (root.get_parent() as Node3D).global_transform.basis.determinant()
					if abs(det) < 0.0001:
						return
				root.look_at_from_position(root.position, target_pos, Vector3.UP)
				root.rotate_object_local(Vector3.RIGHT, -PI / 2)

	func wrap_bounds() -> void:
		var pos := position
		if pos.x < TANK_MIN.x:
			pos.x = TANK_MAX.x
		elif pos.x > TANK_MAX.x:
			pos.x = TANK_MIN.x
		if pos.y < TANK_MIN.y:
			pos.y = TANK_MAX.y
		elif pos.y > TANK_MAX.y:
			pos.y = TANK_MIN.y
		if pos.z < TANK_MIN.z:
			pos.z = TANK_MAX.z
		elif pos.z > TANK_MAX.z:
			pos.z = TANK_MIN.z
		position = pos

	func queue_free() -> void:
		if is_instance_valid(root):
			root.queue_free()

func _apply_standard_presentation() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	ARTIFACT_SCENE_PRESENTER.present(self, _sim_root)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## Grid config arrives twice and by two different routes: GridInteractablesComponent sets
## config_<key> metadata on the instantiated root and then calls apply_grid_config(), and
## the capture harness calls apply_grid_config() before the scene enters the tree. Reading
## the metadata on the way in means the exhibit is built once, correctly, instead of built
## as `result` and then torn down.
##
## Costs nothing when no token is present: the export keeps its default and not a single
## existing placement changes.
func _read_grid_config_meta() -> void:
	var node: Node = self
	while node != null:
		if node.has_meta("config_evidence"):
			evidence = str(node.get_meta("config_evidence"))
		node = node.get_parent()


## Config from map_data.json tokens: #evidence:trace  ·  #evidence:longhand
##
## GUARDED ON CHANGE, deliberately. All 7 map files carrying this token arrive here with no
## `evidence` key at all, and the grid reaches this twice for one placement; an unguarded
## rebuild would tear down and re-raise an exhibit on both of those, for nothing. This
## function used to be a bare `pass`, so every one of those calls was already a no-op and
## stays one.
func apply_grid_config(config: Dictionary) -> void:
	var was_evidence: String = evidence

	if config.has("evidence"):
		evidence = str(config["evidence"])

	if evidence == was_evidence:
		return
	# Before _ready() the mover does not exist yet and _ready() will do this itself.
	if _mover == null:
		return

	_apply_evidence()
	# The exhibit changed size, so the 0.82 m fit is stale. present() sets scale absolutely
	# and re-centres, so calling it again converges rather than compounding.
	call_deferred("_apply_standard_presentation")


# ═══════════════════════════════════════════════════════════════════════════
# EVIDENCE
# ═══════════════════════════════════════════════════════════════════════════

const EV_DT := 0.016666          # one 60 Hz frame, the tick `p += v * delta * 60` assumes
const EV_HEADING_STEPS := 1800   # trace: 30 s of headings — one full beat of 0.6/0.8/0.4
const EV_HEADING_R := 0.30       # trace: radius of the sphere the directions are laid on
const EV_THRUST_MAG := 4.0       # longhand: magnification for the thrust
const EV_FRAMES_SHOWN := 2       # longhand: frames of p dropped as dots. Two is enough.
## axiom: a heading CHOSEN rather than derived. Straight down, and in the plate's own plane
## on purpose — (0, 0, 1) was the obvious "unrelated" direction and it points at the camera,
## where a cone foreshortens to a dot and the counterexample says nothing. A wrong heading
## has to be wrong ACROSS the picture to be visible as a heading at all.
const EV_FIXED_HEADING := Vector3(0.0, -1.0, 0.0)
const EV_EARLY := Color(0.98, 0.74, 0.26)
const EV_LATE := Color(0.35, 0.76, 1.0)
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

	if want == "result":
		return                              # the legacy lineage: a bare cone, nothing added

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


## The headings this demo is going to take, run here through the same step_velocity() the
## running scene calls and the same _thrust_at() it drives with, from the release velocity.
##
## FROM t = 0, and that is a statement rather than a convenience. The live thrust is a
## function of Time.get_ticks_msec(), so the demo has a different future every launch and
## no canonical run to draw. This is the reference run of the same law.
func _ev_headings(steps: int) -> Array[Vector3]:
	var v: Vector3 = RELEASE_VELOCITY
	var cap: float = _mover.max_speed
	var out: Array[Vector3] = []
	for i in range(steps):
		var t: float = float(i) * EV_DT
		v = DirectionalMover.step_velocity(v, _thrust_at(t), cap)
		if v.length() > 0.0001:
			out.append(v.normalized())
	return out


## TRACE — the walk drawn instead of watched, and in this demo the walk that carries the
## argument is the walk of a DIRECTION. Every sibling in this family traces a position
## because position is what those artifacts are about; 3.3 is about heading, and its
## positions are worth nothing to look at for the reason `longhand` draws out — thirty
## metres a second in a 0.9 m tank is not a curve, it is a wrap every third frame.
##
## So: the unit velocity at each of 1800 steps, laid on a sphere, amber to blue through
## time. Two rings give the sphere its shape and a rod marks the heading at release.
func _ev_trace(root: Node3D) -> void:
	var center: Vector3 = (DirectionalMover.TANK_MIN + DirectionalMover.TANK_MAX) * 0.5
	var dirs: Array[Vector3] = _ev_headings(EV_HEADING_STEPS)
	if dirs.size() < 2:
		return

	var im := ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in range(dirs.size()):
		var u: float = float(i) / float(maxi(dirs.size() - 1, 1))
		im.surface_set_color(EV_EARLY.lerp(EV_LATE, u))
		im.surface_add_vertex(center + dirs[i] * EV_HEADING_R)
	im.surface_end()

	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.material_override = mat
	root.add_child(mi)

	_ev_rings(root, center, EV_HEADING_R, _ev_mat(EV_CHALK, 0.25))
	_ev_arrow(root, center, dirs[0] * EV_HEADING_R, 0.007, _ev_mat(EV_INK, 1.2))

	root.add_child(_ev_text("every direction this cone will point, %d steps ahead" % EV_HEADING_STEPS,
		Vector3(-0.36, DirectionalMover.TANK_MAX.y + 0.03, 0.0), 14, EV_CHALK))
	root.add_child(_ev_text("the rod is the heading at release",
		Vector3(-0.36, DirectionalMover.TANK_MAX.y - 0.01, 0.0), 12, EV_INK))


## LONGHAND — the working, not the answer. Everything one frame of this demo consumes is
## put on the geometry at the release state, and one of those things turns out to be a
## finding rather than an illustration: v is drawn at TRUE SCALE because at true scale it
## is most of the room. p advances by |v| per 60 Hz frame, |v| saturates at max_speed
## within about a tenth of a second, and the tank is 0.9 m wide.
func _ev_longhand(root: Node3D) -> void:
	var at: Vector3 = RELEASE_POSITION
	var lo: Vector3 = DirectionalMover.TANK_MIN
	var hi: Vector3 = DirectionalMover.TANK_MAX
	var cap: float = _mover.max_speed

	# The tank. Six literals in wrap_bounds() and drawn nowhere until now.
	_ev_wire_box(root, (lo + hi) * 0.5, hi - lo, 0.004, _ev_mat(EV_CHALK, 0.25))
	root.add_child(_ev_text("wrap: p leaves one wall and enters the other",
		Vector3(lo.x + 0.05, lo.y + 0.03, hi.z), 12, EV_CHALK))

	# The thrust, magnified. At true scale it is 0.05 m and would be a smudge.
	var th: Vector3 = _thrust_at(0.0)
	_ev_arrow(root, at, th * EV_THRUST_MAG, 0.006, _ev_mat(EV_CHALK, 1.0))
	root.add_child(_ev_text("thrust = %.3f  x%d to be seen" % [th.length(), int(EV_THRUST_MAG)],
		at + th * EV_THRUST_MAG + Vector3(0.02, 0.03, 0.0), 12, EV_CHALK))

	# v at release, TRUE SCALE. This is one frame of travel.
	_ev_arrow(root, at, RELEASE_VELOCITY, 0.008, _ev_mat(EV_COOL, 1.0))
	root.add_child(_ev_text("v at release = %.3f  ONE FRAME, true scale" % RELEASE_VELOCITY.length(),
		at + RELEASE_VELOCITY + Vector3(0.02, 0.03, 0.0), 13, EV_COOL))

	# ...and the cap it reaches almost at once, in the same direction, for comparison.
	_ev_arrow(root, at, RELEASE_VELOCITY.normalized() * cap, 0.010, _ev_mat(EV_INK, 1.4))
	root.add_child(_ev_text("cap = %.2f per frame, in a tank %.2f wide" % [cap, hi.x - lo.x],
		at + RELEASE_VELOCITY.normalized() * cap + Vector3(0.02, -0.05, 0.0), 13, EV_INK))

	# Two real frames, dropped where they land. Not decoration: these are the next two
	# positions this cone occupies, and the second one is outside the box.
	var p: Vector3 = at
	var v: Vector3 = RELEASE_VELOCITY
	for i in range(EV_FRAMES_SHOWN):
		v = DirectionalMover.step_velocity(v, _thrust_at(float(i) * EV_DT), cap)
		p += v
		root.add_child(_ev_box(p, Vector3(0.018, 0.018, 0.018), _ev_mat(EV_INK, 1.0)))
	root.add_child(_ev_text("two frames of p",
		p + Vector3(0.02, -0.04, 0.0), 12, EV_INK))


## AXIOM — the rule, standing where the example was, and beside it the counterexample this
## artifact has never drawn. Same velocity arrow twice. On the left the cone takes its
## heading from it; on the right the cone holds a heading set independently. One of the two
## is this demo, and until both are in the frame the header's claim cannot be checked.
func _ev_axiom(root: Node3D) -> void:
	var plate := Node3D.new()
	plate.position = Vector3(0.0, 0.60, DirectionalMover.TANK_MIN.z - 0.12)
	root.add_child(plate)

	var pw: float = 0.72
	var ph: float = 0.46
	plate.add_child(_ev_box(Vector3(0.0, 0.0, -0.012), Vector3(pw + 0.04, ph + 0.04, 0.014),
		_ev_mat(Color(0.28, 0.24, 0.20), 0.0)))
	plate.add_child(_ev_box(Vector3.ZERO, Vector3(pw, ph, 0.012), _ev_mat(EV_SLATE, 0.0)))

	# ASCII on purpose: Label3D falls back to the project font, and an operator that renders
	# as a tofu box is worse evidence than a plain line of code.
	plate.add_child(_ev_text("look_at(p + v)", Vector3(-0.02, ph * 0.36, 0.014), 24, EV_CHALK))
	plate.add_child(_ev_text("heading is not a variable", Vector3(-0.02, ph * 0.22, 0.014), 15, EV_CHALK))

	var vdir: Vector3 = RELEASE_VELOCITY.normalized()
	var lx: float = -pw * 0.26
	var rx: float = pw * 0.26
	var yy: float = -ph * 0.10
	for k in range(2):
		var ox: float = lx if k == 0 else rx
		var base: Vector3 = Vector3(ox, yy, 0.030)
		var ink: StandardMaterial3D = _ev_mat(EV_CHALK, 1.0) if k == 0 else _ev_mat(EV_INK, 1.0)
		# The arrow sits BELOW its cone rather than through it. Drawn through, the aligned
		# cone swallows its own velocity and the two halves of the comparison stop being
		# the same picture twice.
		var rail: Vector3 = base + Vector3(0.0, -0.075, 0.0)
		_ev_arrow(plate, rail - vdir * 0.09, vdir * 0.18, 0.005, _ev_mat(EV_COOL, 1.0))
		var facing: Vector3 = vdir if k == 0 else EV_FIXED_HEADING
		_ev_cone(plate, base, facing, 0.09, 0.026, ink)

	# Laid out down the plate so nothing lands on anything: title 0.166, subtitle 0.101,
	# the summary line 0.037, the cones at -0.046, their arrows at -0.121, captions -0.181.
	plate.add_child(_ev_text("same v, two headings. only one of these is this demo.",
		Vector3(-pw * 0.44, ph * 0.08, 0.016), 12, EV_CHALK))
	plate.add_child(_ev_text("derived from v", Vector3(lx - 0.07, yy - 0.135, 0.016), 12, EV_CHALK))
	plate.add_child(_ev_text("set independently", Vector3(rx - 0.08, yy - 0.135, 0.016), 12, EV_INK))


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


## A shaft along `vec`, oriented with Basis.looking_at rather than look_at() so it does not
## care whether the node is in the tree or where the map put the artifact.
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
	root.add_child(_ev_box(from + vec, Vector3(thick * 2.2, thick * 2.2, thick * 2.2), m))


## A cone pointing along `dir`, built with the SAME orientation convention the mover uses —
## Basis.looking_at then a -PI/2 turn about local X — so the counterexample and the running
## body are the same object seen twice, not two different constructions.
func _ev_cone(root: Node3D, at_pos: Vector3, dir: Vector3, length: float, radius: float,
		m: StandardMaterial3D) -> void:
	if dir.length() < 0.001:
		return
	var up: Vector3 = Vector3.UP
	if absf(dir.normalized().dot(up)) > 0.99:
		up = Vector3.FORWARD
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = radius
	cm.height = length
	mi.mesh = cm
	mi.material_override = m
	mi.transform = Transform3D(Basis.looking_at(dir, up) * Basis(Vector3.RIGHT, -PI / 2.0), at_pos)
	root.add_child(mi)


## Twelve edges, no faces — a box you can see the contents of.
func _ev_wire_box(root: Node3D, center: Vector3, size: Vector3, thick: float,
		m: StandardMaterial3D) -> void:
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


## Two orthogonal rings — a sphere you can see through, rather than a translucent ball that
## would swallow the curve drawn on it.
func _ev_rings(root: Node3D, center: Vector3, radius: float, m: StandardMaterial3D) -> void:
	var segments: int = 32
	var seg_len: float = TAU * radius / float(segments) * 1.05
	var bead := BoxMesh.new()
	bead.size = Vector3(0.003, 0.003, seg_len)
	for plane in range(2):
		for i in range(segments):
			var a: float = TAU * float(i) / float(segments)
			var p: Vector3 = Vector3(cos(a) * radius, 0.0, sin(a) * radius)
			var tg: Vector3 = Vector3(-sin(a), 0.0, cos(a))
			if plane == 1:
				p = Vector3(cos(a) * radius, sin(a) * radius, 0.0)
				tg = Vector3(-sin(a), cos(a), 0.0)
			var up: Vector3 = Vector3.UP
			if absf(tg.dot(up)) > 0.99:
				up = Vector3.FORWARD
			var mi := MeshInstance3D.new()
			mi.mesh = bead
			mi.material_override = m
			mi.transform = Transform3D(Basis.looking_at(tg, up), center + p)
			root.add_child(mi)


func _ev_text(content: String, p: Vector3, size: int, c: Color) -> Label3D:
	var l := Label3D.new()
	l.text = content
	l.font_size = size
	l.pixel_size = 0.0012
	l.modulate = c
	l.position = p
	l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	return l
