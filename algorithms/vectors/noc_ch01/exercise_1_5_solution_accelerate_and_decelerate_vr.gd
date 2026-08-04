# ===========================================================================
# NOC Example 1.5: Exercise 1.5: Accelerate and Decelerate
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

# @identity
# essence: steer = (desired - velocity).clamp(max_force). Seek + arrival. Distance to target scales desired speed.
# desire: to watch a ball chase a moving target, accelerating when far and decelerating when close — smooth arrival from pure math
# critical_parameter: slowing_radius — the only line that separates arrival from seek. Inside it, desired speed is scaled by d/r.
# triggers: automatic — target traces sinusoidal curves, ball steers toward it every frame
# emerges: smooth deceleration zone near the target where speed ramps down proportionally to distance
# needs: auto-running simulation [has], evidence axis [has]. Missing: VR grabbable target, max_force slider
# relationships: extends bouncing_ball (adds steering instead of bouncing). Prepares for boid_flocking (many agents steering). Contrasts with exercise_1_8 (attraction vs steering).
# truth: smooth arrival is not a decision — it is a feedback loop. The closer you get, the gentler the approach.

class_name AccelerateDecelerateVR
extends Node3D

const MAT_TARGET := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")

# ═══════════════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `evidence`
# ═══════════════════════════════════════════════════════════════════════════
#
# WHAT THIS DEMO OFFERS AS PROOF THAT ARRIVAL — AND NOT SEEK — IS MOVING THE BALL.
#
# THE WORD IS NOT NEW HERE. example_1_9 was promoted on `evidence` first and
# 1.7, 1.8 and exercise_1_8 took its word and its value list character for
# character. This takes the same four. The noc_ch01 bench is one argument at
# several stages, and a map that asks the whole shelf for `longhand` should get
# several answers to one question rather than several vocabularies.
#
# What the shared word has to carry HERE is a radius. Everything visible in the
# shipped scene — ball, glowing target, rolling trail, hairline connector — is
# identical to what a pure SEEK would produce; the ONE line that makes this
# arrival is `if distance < 0.15: desired *= distance / 0.15`, and 0.15 is a
# number in a source file that nothing in the room can see. The chase looks
# smooth and the reason for the smoothness is invisible. So the deceleration
# zone is a place with an edge, and the evidence axis is what gets to draw it.
#
#   result    the shipped build, byte for byte: ball, target, 200-frame trail,
#             connector line, and no explanation. The legacy lineage.
#   trace     the WHOLE CHASE, integrated forward here at build time through the
#             identical _step() the running scene calls, and laid down before the
#             ball has moved once — the ball's future path against the target's
#             own sinusoid. There is no random number anywhere in this demo, so
#             it can print its own future and be held to it.
#   longhand  the working. The slowing radius becomes a translucent shell with a
#             ring at the equator, travelling with the target, so the zone is a
#             room the ball enters rather than a constant; and `desired` and `v`
#             are drawn live from the ball, magnified, so the shrinking of
#             `desired` inside the shell can be watched happening.
#   axiom     the instance gives way to the rule. A plate carries the three lines
#             of the update and, beside them, the ramp itself plotted: desired
#             speed against distance, rising to max at d = r and flat beyond —
#             with SEEK's flat line dashed over it. The gap between the two
#             curves is the entire content of this exercise.
#
# All four run the SAME physics. _step() is untouched by every one of them.
@export_enum("result", "trace", "longhand", "axiom") var evidence: String = "result"

## Allow-list. An unknown word in a map token falls back to the shipped build
## rather than stranding a placement with a blank exhibit.
const EVIDENCES: PackedStringArray = ["result", "trace", "longhand", "axiom"]

@export var max_speed: float = 0.08
@export var max_force: float = 0.005
## The arrival radius. Was the literal 0.15, written twice in _process; exported
## so the exhibits draw the same number the physics uses instead of a second copy.
@export var slowing_radius: float = 0.15
@export var ball_radius: float = 0.05
@export_color_no_alpha var ball_color: Color = Color(0.3, 0.9, 1.0)
@export_color_no_alpha var target_color: Color = Color(1.0, 0.4, 0.7)

var _sim_root: Node3D
var _ball: MeshInstance3D
var _target: MeshInstance3D
var _position: Vector3 = Vector3(-0.3, 0.5, 0)
var _velocity: Vector3 = Vector3.ZERO
var _target_position: Vector3 = Vector3(0.3, 0.5, 0)
var _target_y: float = 0.5
var _time: float = 0.0
var _trail_points: Array[Vector3] = []
var _trail_mesh: ImmediateMesh
var _trail_instance: MeshInstance3D
var _line_mesh: ImmediateMesh
var _line_instance: MeshInstance3D
var _max_trail_length: int = 200

## Nodes built by trace / longhand / axiom. Freed before any rebuild; empty on the
## shipped path, where not one of them is ever constructed.
var _evidence_parts: Array[Node3D] = []
## longhand only. Null everywhere else, and _process pays two null checks for it.
var _zone: Node3D = null
var _arrow_v: MeshInstance3D = null
var _arrow_d: MeshInstance3D = null

func _ready() -> void:
	_read_grid_config_meta()
	_setup_environment()
	_spawn_objects()
	_setup_trail()
	_apply_evidence()
	set_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)

func _spawn_objects() -> void:
	# Ball — the chaser
	_ball = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = ball_radius
	sphere.height = ball_radius * 2.0
	_ball.mesh = sphere
	var ball_mat := StandardMaterial3D.new()
	ball_mat.albedo_color = ball_color
	ball_mat.emission_enabled = true
	ball_mat.emission = ball_color * 0.4
	ball_mat.emission_energy_multiplier = 1.5
	ball_mat.metallic = 0.3
	ball_mat.roughness = 0.4
	_ball.material_override = ball_mat
	_sim_root.add_child(_ball)

	# Target — glowing pulsing sphere
	_target = MeshInstance3D.new()
	var target_sphere := SphereMesh.new()
	target_sphere.radius = 0.04
	target_sphere.height = 0.08
	_target.mesh = target_sphere
	var target_mat := StandardMaterial3D.new()
	target_mat.albedo_color = target_color
	target_mat.emission_enabled = true
	target_mat.emission = target_color
	target_mat.emission_energy_multiplier = 2.0
	target_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_target.material_override = target_mat
	_target.position = _target_position
	_sim_root.add_child(_target)

func _setup_trail() -> void:
	# Chase trail
	_trail_mesh = ImmediateMesh.new()
	_trail_instance = MeshInstance3D.new()
	_trail_instance.mesh = _trail_mesh
	var trail_mat := StandardMaterial3D.new()
	trail_mat.albedo_color = Color(ball_color, 0.4)
	trail_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_trail_instance.material_override = trail_mat
	_sim_root.add_child(_trail_instance)
	# Connection line to target
	_line_mesh = ImmediateMesh.new()
	_line_instance = MeshInstance3D.new()
	_line_instance.mesh = _line_mesh
	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.15)
	line_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_line_instance.material_override = line_mat
	_sim_root.add_child(_line_instance)


## WHERE THE TARGET IS AT TIME t. Lifted out of _process unchanged — the same
## sin(t*0.8)*0.3 and cos(t*0.5)*0.25, with y held at the value it has always
## held — so `trace` can ask where the target will be instead of guessing.
func _target_at(t: float) -> Vector3:
	return Vector3(sin(t * 0.8) * 0.3, _target_y, cos(t * 0.5) * 0.25)


## ONE STEP OF THE LAW, and the only place it is written.
##
## Extracted from _process so that `trace` cannot drift from the running scene: an
## exhibit that predicts the chase with its own copy of the arithmetic is an exhibit
## that will eventually be lying. Returns [position, velocity]; nothing about the
## numbers changed, and slowing_radius defaults to the 0.15 that was inline.
func _step(p: Vector3, v: Vector3, target: Vector3) -> Array[Vector3]:
	var to_target: Vector3 = target - p
	var distance: float = to_target.length()

	if distance > 0.01:
		var desired: Vector3 = to_target.normalized() * max_speed

		if distance < slowing_radius:
			var m: float = remap(distance, 0.0, slowing_radius, 0.0, 1.0)
			desired *= m

		var steer: Vector3 = desired - v
		steer = steer.limit_length(max_force)

		v += steer
		v = v.limit_length(max_speed)
	else:
		v *= 0.95

	p += v
	var out: Array[Vector3] = [p, v]
	return out


## `desired` at this instant, for the longhand arrow. Same two lines as _step().
func _desired_at(p: Vector3, target: Vector3) -> Vector3:
	var to_target: Vector3 = target - p
	var distance: float = to_target.length()
	if distance <= 0.01:
		return Vector3.ZERO
	var desired: Vector3 = to_target.normalized() * max_speed
	if distance < slowing_radius:
		desired *= remap(distance, 0.0, slowing_radius, 0.0, 1.0)
	return desired


func _process(delta: float) -> void:
	_time += delta

	_target_position = _target_at(_time)
	_target.position = _target_position

	var stepped: Array[Vector3] = _step(_position, _velocity, _target_position)
	_position = stepped[0]
	_velocity = stepped[1]

	_ball.position = _position

	# Trail
	_trail_points.append(_position)
	if _trail_points.size() > _max_trail_length:
		_trail_points.remove_at(0)
	_trail_mesh.clear_surfaces()
	if _trail_points.size() >= 2:
		_trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		for p in _trail_points:
			_trail_mesh.surface_add_vertex(p)
		_trail_mesh.surface_end()

	# Connection line
	_line_mesh.clear_surfaces()
	_line_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_line_mesh.surface_add_vertex(_position)
	_line_mesh.surface_add_vertex(_target_position)
	_line_mesh.surface_end()

	# longhand only — both are null on every other value, including the shipped one.
	if _zone != null and is_instance_valid(_zone):
		_zone.position = _target_position
	if _arrow_v != null and is_instance_valid(_arrow_v):
		_ev_aim(_arrow_v, _position, _velocity * EV_MAG)
		_ev_aim(_arrow_d, _position, _desired_at(_position, _target_position) * EV_MAG)

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
## GUARDED ON CHANGE, deliberately. All seven existing placements arrive here with no
## `evidence` key at all — six bare tokens and one curation_station collection whose
## #with_wall / #layout flags belong to the station — and the grid reaches this twice
## for one placement; an unguarded rebuild would tear down and re-raise an exhibit on
## both of those, for nothing.
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

const EV_STEPS := 1400          # trace: steps integrated forward at build time
const EV_DT := 0.016666         # trace: one 60 Hz frame, the tick the demo runs at
const EV_EARLY := Color(0.98, 0.74, 0.26)   # trace: colour at step 0
const EV_LATE := Color(0.35, 0.76, 1.0)     # trace: colour at step EV_STEPS
const EV_MAG := 4.0             # longhand: magnification for v and desired
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
	_zone = null
	_arrow_v = null
	_arrow_d = null

	# The rolling trail is the demo's own record and stays on everywhere except
	# `trace`, where the whole path is already drawn and the two would overprint.
	if is_instance_valid(_trail_instance):
		_trail_instance.visible = (want != "trace")

	if want == "result":
		return                              # the legacy lineage: nothing added at all

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


## The chase this demo is about to run, integrated here through the same _step() and
## the same _target_at() the running scene calls, from the same start state. Returns
## [ball_path, target_path].
func _ev_paths(steps: int) -> Array:
	var p: Vector3 = _position
	var v: Vector3 = _velocity
	var t: float = _time
	var ball: PackedVector3Array = PackedVector3Array()
	var targ: PackedVector3Array = PackedVector3Array()
	ball.append(p)
	for _i in range(steps):
		t += EV_DT
		var tp: Vector3 = _target_at(t)
		targ.append(tp)
		var stepped: Array[Vector3] = _step(p, v, tp)
		p = stepped[0]
		v = stepped[1]
		ball.append(p)
	return [ball, targ]


## TRACE — the chase drawn instead of watched. There is no random number in this demo,
## so the entire pursuit is implied by two start states and a pair of sine waves, and it
## can be printed before the ball has moved once. Coloured amber to blue through time so
## the ORDER of the loops is legible: the ball's early lunge across the open, then the
## tight coils where it has caught the target and is riding inside the slowing radius.
func _ev_trace(root: Node3D) -> void:
	var paths: Array = _ev_paths(EV_STEPS)
	var ball: PackedVector3Array = paths[0]
	var targ: PackedVector3Array = paths[1]

	var im := ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in range(ball.size()):
		var u: float = float(i) / float(maxi(ball.size() - 1, 1))
		im.surface_set_color(EV_EARLY.lerp(EV_LATE, u))
		im.surface_add_vertex(ball[i])
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.material_override = mat
	root.add_child(mi)

	# The target's own closed curve — what the ball is chasing, drawn as a thing in
	# its own right rather than a moving dot.
	var tim := ImmediateMesh.new()
	tim.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for j in range(targ.size()):
		tim.surface_add_vertex(targ[j])
	tim.surface_end()
	var tmi := MeshInstance3D.new()
	tmi.mesh = tim
	tmi.material_override = _ev_mat(target_color, 1.0)
	root.add_child(tmi)

	# ASCII on purpose: Label3D falls back to the project font, and a character that
	# renders as a tofu box is worse evidence than a plain sentence.
	root.add_child(_ev_text("%d steps, drawn before they happen - the coils are arrival" % EV_STEPS,
		Vector3(-0.36, 0.92, 0.0), 14, EV_CHALK))


## LONGHAND — the working, not the answer, and the one value that puts the radius in the
## room. The shell is the deceleration zone: outside it `desired` has length max_speed,
## inside it `desired` is scaled by d/r and the ball is being asked to slow down. Both
## vectors are drawn live from the ball, magnified x4, because at true scale 0.08 m/frame
## is shorter than the ball's own radius and would be evidence of nothing.
func _ev_longhand(root: Node3D) -> void:
	_zone = Node3D.new()
	_zone.name = "SlowingRadius"
	_zone.position = _target_position
	root.add_child(_zone)

	# The volume. Alpha-blended and unshaded so it reads as a region, not an object.
	var shell := MeshInstance3D.new()
	var shell_mesh := SphereMesh.new()
	shell_mesh.radius = slowing_radius
	shell_mesh.height = slowing_radius * 2.0
	shell_mesh.radial_segments = 32
	shell_mesh.rings = 16
	shell.mesh = shell_mesh
	var shell_mat := StandardMaterial3D.new()
	shell_mat.albedo_color = Color(target_color.r, target_color.g, target_color.b, 0.16)
	shell_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shell_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shell_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	shell.material_override = shell_mat
	_zone.add_child(shell)

	# The edge, in the plane the chase actually happens in.
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = slowing_radius - 0.006
	torus.outer_radius = slowing_radius + 0.006
	torus.rings = 48
	ring.mesh = torus
	ring.material_override = _ev_mat(EV_INK, 1.2)
	_zone.add_child(ring)

	_zone.add_child(_ev_text("r = %.2f   inside: desired *= d / r" % slowing_radius,
		Vector3(slowing_radius + 0.02, 0.02, 0.0), 13, EV_INK))

	# v and desired, rebuilt in place every frame by _ev_aim().
	_arrow_v = _ev_shaft(root, 0.008, _ev_mat(ball_color, 1.0))
	_arrow_d = _ev_shaft(root, 0.008, _ev_mat(EV_CHALK, 0.8))
	_ev_aim(_arrow_v, _position, _velocity * EV_MAG)
	_ev_aim(_arrow_d, _position, _desired_at(_position, _target_position) * EV_MAG)

	root.add_child(_ev_text("v  (x%d)" % int(EV_MAG), Vector3(-0.40, 0.62, 0.0), 14, ball_color))
	root.add_child(_ev_text("desired  (x%d)" % int(EV_MAG), Vector3(-0.40, 0.56, 0.0), 14, EV_CHALK))
	root.add_child(_ev_text("steer = clamp(desired - v, max_force)",
		Vector3(-0.40, 0.50, 0.0), 13, EV_CHALK))


## AXIOM — the instance gives way to the rule. The plate carries the three lines of the
## update, and beside them the ramp is PLOTTED: desired speed against distance to target.
## Arrival is the solid curve, rising from nothing at d = 0 to max_speed at d = r and flat
## after; seek is the dashed line straight across the top. Everything this exercise adds to
## seek is the wedge between the two, and it is the only place in the demo where that wedge
## can be seen at all.
func _ev_axiom(root: Node3D) -> void:
	var plate := Node3D.new()
	plate.position = Vector3(0.0, 0.62, -0.42)
	root.add_child(plate)

	var pw: float = 0.76
	var ph: float = 0.46
	plate.add_child(_ev_box(Vector3(0.0, 0.0, -0.012), Vector3(pw + 0.04, ph + 0.04, 0.014),
		_ev_mat(Color(0.28, 0.24, 0.20), 0.0)))
	plate.add_child(_ev_box(Vector3.ZERO, Vector3(pw, ph, 0.012), _ev_mat(EV_SLATE, 0.0)))

	# ASCII on purpose: Label3D falls back to the project font, and an operator that
	# renders as a tofu box is worse evidence than a plain line of code.
	plate.add_child(_ev_text("desired = norm(target - p) * max_speed",
		Vector3(-pw * 0.46, ph * 0.36, 0.014), 19, EV_CHALK))
	plate.add_child(_ev_text("if d < r:  desired *= d / r",
		Vector3(-pw * 0.46, ph * 0.22, 0.014), 19, EV_INK))
	plate.add_child(_ev_text("steer = clamp(desired - v, max_force)",
		Vector3(-pw * 0.46, ph * 0.08, 0.014), 19, EV_CHALK))

	# The ramp. Domain 0..PLOT_D metres, range 0..max_speed.
	var plot_w: float = 0.44
	var plot_h: float = 0.15
	var ox: float = -pw * 0.24
	var oy: float = -ph * 0.30
	var plot_d: float = 0.40

	plate.add_child(_ev_box(Vector3(ox + plot_w * 0.5, oy, 0.014),
		Vector3(plot_w, 0.004, 0.006), _ev_mat(EV_CHALK, 0.4)))
	plate.add_child(_ev_box(Vector3(ox, oy + plot_h * 0.5, 0.014),
		Vector3(0.004, plot_h, 0.006), _ev_mat(EV_CHALK, 0.4)))

	var arrival: Array[Vector3] = []
	var seek: Array[Vector3] = []
	for i in range(49):
		var d: float = plot_d * float(i) / 48.0
		var s: float = max_speed
		if d < slowing_radius:
			s = max_speed * (d / slowing_radius)
		arrival.append(Vector3(ox + plot_w * (d / plot_d),
			oy + plot_h * (s / max_speed), 0.018))
		if i % 4 == 0:
			seek.append(Vector3(ox + plot_w * (d / plot_d), oy + plot_h, 0.020))
	_ev_dotted(plate, arrival, EV_INK, 0.008)
	_ev_dotted(plate, seek, EV_CHALK, 0.006)

	# Where the two curves part company.
	var rx: float = ox + plot_w * (slowing_radius / plot_d)
	plate.add_child(_ev_box(Vector3(rx, oy + plot_h * 0.5, 0.016),
		Vector3(0.003, plot_h, 0.006), _ev_mat(EV_INK, 0.6)))
	plate.add_child(_ev_text("r", Vector3(rx - 0.008, oy - 0.045, 0.016), 15, EV_INK))
	plate.add_child(_ev_text("seek", Vector3(ox + plot_w + 0.012, oy + plot_h - 0.012, 0.016),
		13, EV_CHALK))
	plate.add_child(_ev_text("arrival", Vector3(ox + plot_w + 0.012, oy + plot_h * 0.42, 0.016),
		13, EV_INK))
	plate.add_child(_ev_text("|desired|  vs  distance",
		Vector3(ox - 0.01, oy - 0.09, 0.016), 13, EV_CHALK))


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


## An empty shaft, made once and aimed every frame by _ev_aim(). Rebuilding a mesh per
## frame to move a 2 cm arrow would be a lot of garbage for a line.
func _ev_shaft(root: Node3D, thick: float, m: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(thick, thick, 1.0)
	mi.mesh = bm
	mi.material_override = m
	root.add_child(mi)
	return mi


## Point a shaft along `vec` from `from`, scaled to its length. Basis.looking_at rather
## than look_at() so it does not care where in the tree the map put the artifact.
func _ev_aim(mi: MeshInstance3D, from: Vector3, vec: Vector3) -> void:
	if mi == null or not is_instance_valid(mi):
		return
	var length: float = vec.length()
	if length < 0.002:
		mi.visible = false
		return
	mi.visible = true
	var up: Vector3 = Vector3.UP
	if absf(vec.normalized().dot(up)) > 0.99:
		up = Vector3.FORWARD
	# Stretch the shaft's own mesh rather than scaling the basis: one resource, edited
	# in place, and no question about which axis a scaled Basis actually stretched.
	var bm: BoxMesh = mi.mesh as BoxMesh
	if bm != null:
		bm.size = Vector3(bm.size.x, bm.size.y, length)
	mi.transform = Transform3D(Basis.looking_at(vec, up), from + vec * 0.5)


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


func _ev_text(content: String, p: Vector3, size: int, c: Color) -> Label3D:
	var l := Label3D.new()
	l.text = content
	l.font_size = size
	l.pixel_size = 0.0012
	l.modulate = c
	l.position = p
	l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	return l
