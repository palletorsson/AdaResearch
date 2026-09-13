# control_pendulum.gd
# Grabbable pendulum that controls oscillation parameters
# When grabbed: oscillation stops. When released: resumes from current position.
# Swing harder = faster oscillation. Higher amplitude = bigger movements.
# Uses XR Tools grabbable sphere for VR interaction.

extends Node3D

class_name ControlPendulum


# @identity
# essence: alpha = -(g/L)*sin(theta) + drive, omega += alpha*dt, theta += omega*dt, decayed by the regime's damping
# desire: Grab a pendulum bob in VR and feel gravity convert your release into oscillation
# critical_parameter: pendulum_length — determines the natural frequency via sqrt(g/L)
# triggers: grab() freezes physics; release() converts hand position to initial angle and starts oscillation
# emerges: harmonic motion from the simplest possible setup — mass, string, gravity
# needs: VR grab on bob [has], oscillation_updated signal output [has], a picture of what the damping is doing [has, under evidence]
# relationships: depends on gravity simulation; drives oscillation_controlled_cube via signal; contrasts with spring_demo (gravity vs spring restoring force) and harmonic_motion_demo, with which it shares the `regime` word
# truth: A pendulum is gravity's metronome — length alone determines the tempo.

## ── the regime axis ───────────────────────────────────────────────────────────────────
## WHICH NAMED CASE OF THE DAMPED OSCILLATOR THIS PENDULUM IS IN. Family word; the first
## four values are harmonic_motion_demo's list character for character, and `resonance` is
## a fifth this artifact can answer and the undriven siblings cannot.
##
## THE FAULT CHECK THAT CAME FIRST, and it is NOT the one spring_demo found. spring_demo's
## damping slider stopped at c = 2.0 where critical was 6.32, so the regime it existed to
## teach was off the end of the hardware. Here there is no slider and no clamp: `damping` is
## a bare @export float and the generic apply_grid_config would have taken any value, so
## critical damping WAS numerically reachable — at exactly 0.874, and nowhere written down.
## The fault is a unit, not a cap. `damping` is a PER-PHYSICS-FRAME multiplier with no
## relation to the pendulum's own omega, so the same number is a different regime at a
## different length, and the declared critical_parameter is the length. Expressed as a
## multiplier the shipped 0.995 is zeta = 0.037; expressed as anything else it is nothing.
## So the four new values are set as a damping RATIO against omega0 = sqrt(g/L), which is
## harmonic_motion_demo's fix rather than spring_demo's, and they stay honest if the length
## moves.
##   free         return the shipped 0.995 multiplier untouched, by short circuit. Not
##                recomputed from its own zeta, so nothing rounds.
##   underdamped  zeta 0.25 — decay you can see inside six seconds, still crossing zero.
##   critical     zeta 1.00 — the fastest return that never crosses.
##   overdamped   zeta 2.50 — no crossing either, and slower, which is the whole joke.
##   resonance    zeta 0.08 and a drive at omega0. The registry has described this artifact
##                as having "driving force and frequency" since it was written and the file
##                had neither; this is the value that makes the sentence true.
##
## ── the evidence axis ─────────────────────────────────────────────────────────────────
## Family word, canonical four-value ladder. IT IS ALSO WHAT MAKES `regime` PHOTOGRAPHABLE.
## A still of a pendulum catches a rod at one arbitrary phase: free and underdamped land
## somewhere in the swing, and critical and overdamped both land hanging straight down —
## two values identical to the byte, which is a fact about the camera, not the physics. So
## the regime is DRAWN, the way bouncing_ball draws its bounce envelope: theta over the next
## six seconds, integrated at build time with the same update rule _physics_process uses, on
## one fixed vertical scale so a decaying trace cannot be mistaken for a free one. The
## capture fixture pins evidence=trace for exactly this reason.
##   result    nothing — THE SHIPPED BUILD.
##   trace     the predicted theta(t) and its zero line.
##   longhand  that, plus the three numbers behind it: zeta, omega0, and the period.
##   axiom     the specimens withdrawn for the rule — the equation of motion and the period
##             law on a slate, with no curve under them.

signal oscillation_updated(y_offset: float, angular_velocity: float, amplitude: float)
signal grabbed
signal released
## The bob passed through the hanging position. direction is the sign of the
## angular velocity at the crossing: +1 towards +x, -1 towards -x. Two visits to
## the same place with opposite signs are the Intro room's whole first lesson,
## and this is what a probe listens to when it asks whether they happened.
signal centre_crossed(direction: int, angular_velocity: float)

@export var pendulum_length: float = 0.6
@export var bob_radius: float = 0.06
@export var gravity: float = 9.8
@export var damping: float = 0.995
## Stage-2 DNA axis — which named case of the damped oscillator this pendulum is in.
@export_enum("free", "underdamped", "critical", "overdamped", "resonance") var regime: String = "free"
## Stage-2 DNA axis — how much of the working stands behind the swing.
@export_enum("result", "trace", "longhand", "axiom") var evidence: String = "result"
## The still thing the swing is measured against (2026-09-10, the Intro pilot in
## doc/research/waves-chance-noise: "keep a still reference and a visible centre
## crossing").
##   none   the shipped build — pivot, rod, bob, a label. Every placement so far.
##   plumb  a hairline from the pivot to the rest point, a ring at the rest point
##          that brightens for a moment each time the bob passes through it, and
##          the label counts those crossings with their direction.
## Word-valued, so a map spells it in the token (#reference:plumb) without the
## grid mistaking it for a rotation.
@export_enum("none", "plumb") var reference: String = "none"

const GRAB_SPHERE_SCENE = preload("res://commons/primitives/point/grab_sphere_point.tscn")

const REGIMES: PackedStringArray = ["free", "underdamped", "critical", "overdamped", "resonance"]
const EVIDENCE: PackedStringArray = ["result", "trace", "longhand", "axiom"]
const REFERENCES: PackedStringArray = ["none", "plumb"]
## A crossing counts only when the bob is actually moving: a bob parked at the
## rest point by a rebuild, or released from exactly the centre, does not "cross".
const CROSSING_MIN_OMEGA: float = 0.02

## The shipped starting angle. `_angle`'s initialiser below is this same number; it is named
## here so the drawn prediction is a statement about the artifact's design rather than about
## whatever moment a rebuild happened to catch.
const START_ANGLE: float = 0.3
## Drive amplitude in radians, applied as an angular acceleration of DRIVE_AMP * omega0^2.
## At zeta = 0.08 the steady amplitude is DRIVE_AMP / (2 * zeta) = 0.375 rad, comfortably
## larger than START_ANGLE and comfortably inside the +/- 0.45*PI clamp, so resonance reads
## as a swing that GROWS rather than as a clipped one.
const DRIVE_AMP: float = 0.06
## Plot geometry. Behind the swing plane, inside the vertical extent the rod already has.
const PLOT_SECONDS: float = 6.0
const PLOT_W: float = 0.60
const PLOT_H: float = 0.16
const PLOT_Y: float = -0.32
const PLOT_Z: float = -0.16
## One fixed vertical scale for every regime — per-curve normalisation would draw a dying
## swing and a free one as the same picture.
const PLOT_THETA_MAX: float = 0.45

var _pivot: Node3D
var _rod: MeshInstance3D
var _bob_sphere: Node3D  # The grabbable sphere instance
var _label: Label3D
var _evidence_root: Node3D
var _reference_root: Node3D
var _ring_mat: StandardMaterial3D
var _ring_glow: float = 0.0

var _angle: float = 0.3  # Starting angle (radians)
var _angular_velocity: float = 0.0
var _prev_angle: float = 0.3      # last frame's angle, for the sign change that is a crossing
var _crossings: int = 0
var _last_crossing_dir: int = 0
var _is_grabbed: bool = false
var _last_bob_position: Vector3
var _grab_start_time: float = 0.0
var _grab_velocity_samples: Array[Vector3] = []
var _drive_t: float = 0.0

# Output values for the controlled cube
var current_y_offset: float = 0.0
var current_angular_velocity: float = 0.0
var current_amplitude: float = 0.0

func _ready():
	regime = _pick(regime, REGIMES, "free")
	evidence = _pick(evidence, EVIDENCE, "result")
	reference = _pick(reference, REFERENCES, "none")
	_build_all()

func _build_all() -> void:
	_create_pivot()
	_create_rod()
	_create_grabbable_bob()
	_create_label()
	_build_reference()
	_update_bob_position()
	_build_evidence()

func _pick(value: String, allowed: PackedStringArray, fallback: String) -> String:
	if allowed.has(value):
		return value
	return fallback

func _create_pivot():
	_pivot = Node3D.new()
	_pivot.name = "Pivot"
	add_child(_pivot)

	# Pivot point visual
	var pivot_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.02
	sphere.height = 0.04
	pivot_mesh.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.4, 0.5)
	mat.metallic = 0.8
	pivot_mesh.material_override = mat
	_pivot.add_child(pivot_mesh)

func _create_rod():
	_rod = MeshInstance3D.new()
	_rod.name = "Rod"
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.008
	cylinder.bottom_radius = 0.008
	cylinder.height = pendulum_length
	_rod.mesh = cylinder
	_rod.position.y = -pendulum_length / 2

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.55, 0.5)
	mat.metallic = 0.6
	_rod.material_override = mat
	_pivot.add_child(_rod)

func _create_grabbable_bob():
	# Instance the grabbable sphere
	_bob_sphere = GRAB_SPHERE_SCENE.instantiate()
	_bob_sphere.name = "BobSphere"

	# Configure the sphere for pendulum use
	if _bob_sphere.has_method("set"):
		_bob_sphere.freeze = true  # Start frozen (controlled by pendulum)
		_bob_sphere.alter_freeze = false  # Don't toggle freeze on drop
		_bob_sphere.glow_color = Color(0.9, 0.4, 0.3)

	# Scale to match bob_radius
	var scale_factor = bob_radius / 0.045  # Default grab sphere radius is ~0.045
	_bob_sphere.scale = Vector3.ONE * scale_factor

	# Connect to picked_up and dropped signals
	if _bob_sphere.has_signal("picked_up"):
		_bob_sphere.picked_up.connect(_on_bob_picked_up)
	if _bob_sphere.has_signal("dropped"):
		_bob_sphere.dropped.connect(_on_bob_dropped)
	# THE DESKTOP HAND (2026-09-13, W0). The desktop pointer's right-click carry never
	# emits picked_up or dropped, so until now a desktop visitor carried the bob while
	# the integrator kept writing its position, and the release handler never ran. The
	# bob is a shared grab-sphere scene, so the hooks live here and the bob names this
	# node as the one to ask.
	_bob_sphere.set_meta("desktop_hook_target", self)

	# Add as child of the main node (not pivot) so it can move freely when grabbed
	add_child(_bob_sphere)

func _create_label():
	_label = Label3D.new()
	_label.pixel_size = 0.001
	_label.font_size = 12
	_label.text = "GRAB & SWING"
	_label.position = Vector3(0, 0.1, 0)
	_label.modulate = Color(0.7, 0.7, 0.8)
	add_child(_label)

## The still reference. Nothing here moves: a hairline where the rod would hang
## at rest, and a ring around the rest point that the bob passes THROUGH. The
## ring is lit briefly by _physics_process on each crossing, so "the bob is at
## the centre" is something the room says out loud rather than something the
## visitor has to judge against thin air. Built only under reference=plumb; at
## the default this function returns before a node exists, so every shipped
## placement is what it was.
func _build_reference() -> void:
	if reference != "plumb":
		return
	_reference_root = Node3D.new()
	_reference_root.name = "Reference"
	add_child(_reference_root)
	var plumb := MeshInstance3D.new()
	plumb.name = "Plumb"
	var hair := CylinderMesh.new()
	hair.top_radius = 0.0015
	hair.bottom_radius = 0.0015
	hair.height = pendulum_length
	plumb.mesh = hair
	plumb.position = Vector3(0.0, -pendulum_length * 0.5, 0.0)
	plumb.material_override = _flat_mat(Color(0.6, 0.66, 0.78, 1.0), 0.35)
	_reference_root.add_child(plumb)
	var ring := MeshInstance3D.new()
	ring.name = "RestRing"
	var torus := TorusMesh.new()
	torus.inner_radius = bob_radius * 1.7
	torus.outer_radius = bob_radius * 1.7 + 0.006
	ring.mesh = torus
	# TorusMesh lies in the XZ plane; the bob swings in XY along x, so turn the
	# ring's normal to x and the bob threads it at every crossing.
	ring.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	ring.position = Vector3(0.0, -pendulum_length, 0.0)
	_ring_mat = _flat_mat(Color(1.0, 0.84, 0.42, 1.0), 0.4)
	ring.material_override = _ring_mat
	_reference_root.add_child(ring)
	# the visual pass of 12 September: the pale bob, rod and ring vanished against the
	# museum's bright wall and floor, and the state label was small above the pivot. A dark
	# matte slate behind the swing plane (behind the trace plot too, at -0.30) gives the
	# bob, the ring and the plot something to be seen against; the label is made a cased
	# readout beside the pivot, out of the swing, at a size a standing eye reads.
	var slate := MeshInstance3D.new()
	slate.name = "Slate"
	var sbox := BoxMesh.new()
	sbox.size = Vector3(1.6, 1.9, 0.02)
	slate.mesh = sbox
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.13, 0.13, 0.15)
	smat.roughness = 0.9
	slate.material_override = smat
	slate.position = Vector3(0.0, -0.62, -0.30)
	_reference_root.add_child(slate)
	if _label != null:
		var plate := MeshInstance3D.new()
		plate.name = "LabelPlate"
		var pbox := BoxMesh.new()
		pbox.size = Vector3(0.62, 0.20, 0.012)
		plate.mesh = pbox
		plate.material_override = smat
		plate.position = Vector3(0.78, -0.10, -0.012)
		_reference_root.add_child(plate)
		_label.position = Vector3(0.78, -0.10, 0.0)
		_label.font_size = 24
		_label.pixel_size = 0.0011
		_label.modulate = Color(0.85, 0.95, 1.0)

func _update_bob_position():
	# Calculate bob position from angle
	if _bob_sphere and not _is_grabbed:
		var bob_x = sin(_angle) * pendulum_length
		var bob_y = -cos(_angle) * pendulum_length
		_bob_sphere.global_position = to_global(Vector3(bob_x, bob_y, 0))
		_last_bob_position = _bob_sphere.global_position

# ── the regime family ─────────────────────────────────────────────────────────────────

func _omega0() -> float:
	return sqrt(gravity / maxf(0.0001, pendulum_length))

## The damping ratio. `free` is the only member that is MEASURED rather than chosen: it is
## the shipped 0.995-per-frame multiplier expressed in the pendulum's own units, and it is
## used for drawing only — the physics path below never routes `free` through it.
func _zeta() -> float:
	match regime:
		"underdamped":
			return 0.25
		"critical":
			return 1.0
		"overdamped":
			return 2.5
		"resonance":
			return 0.08
		_:
			var fps: float = maxf(1.0, float(Engine.physics_ticks_per_second))
			return -log(clampf(damping, 0.0001, 0.9999)) * fps / (2.0 * _omega0())

## Short circuit at `free`: the raw shipped constant, not a round trip through zeta. Bit
## identical to the line this replaced, including its frame-rate dependence.
func _damping_multiplier(delta: float) -> float:
	if regime == "free":
		return damping
	return exp(-2.0 * _zeta() * _omega0() * delta)

func _drive_accel() -> float:
	return DRIVE_AMP * _omega0() * _omega0()

func _physics_process(delta):
	if _is_grabbed:
		# When grabbed, track the bob position and calculate angle
		if _bob_sphere:
			var local_pos = to_local(_bob_sphere.global_position)
			var new_angle = atan2(local_pos.x, -local_pos.y)
			new_angle = clampf(new_angle, -PI * 0.45, PI * 0.45)

			# Track velocity for release impulse
			var current_pos = _bob_sphere.global_position
			if _grab_velocity_samples.size() > 0:
				var velocity = (current_pos - _last_bob_position) / delta
				_grab_velocity_samples.append(velocity)
				if _grab_velocity_samples.size() > 5:
					_grab_velocity_samples.pop_front()
			else:
				_grab_velocity_samples.append(Vector3.ZERO)

			_last_bob_position = current_pos
			_angle = new_angle
			_angular_velocity = 0.0
		# a held bob does not cross anything; the count resumes at the release
		_prev_angle = _angle

		_update_label("GRABBED\nRelease to swing")
	else:
		# Simple pendulum physics
		var angular_acceleration: float = -(gravity / pendulum_length) * sin(_angle)
		if regime == "resonance":
			_drive_t += delta
			angular_acceleration += _drive_accel() * cos(_omega0() * _drive_t)
		_angular_velocity += angular_acceleration * delta
		_angular_velocity *= _damping_multiplier(delta)
		_angle += _angular_velocity * delta

		# Clamp angle
		_angle = clampf(_angle, -PI * 0.45, PI * 0.45)

		# A CROSSING is a sign change of the angle while the bob is moving. The
		# direction is the sign of omega at that moment — the thing a still
		# picture of "the bob at the centre" cannot show.
		if signf(_angle) != signf(_prev_angle) and signf(_angle) != 0.0 \
				and absf(_angular_velocity) > CROSSING_MIN_OMEGA:
			_crossings += 1
			_last_crossing_dir = 1 if _angular_velocity > 0.0 else -1
			_ring_glow = 1.0
			centre_crossed.emit(_last_crossing_dir, _angular_velocity)
		_prev_angle = _angle

		# Update bob position
		_update_bob_position()

		# The angle and the SIGNED angular velocity. The shipped label printed
		# abs(omega), which is the one number this room exists to reveal — two
		# crossings of the same point with opposite signs — thrown away.
		var line := "θ %+.1f°   ω %+.2f rad/s" % [rad_to_deg(_angle), _angular_velocity]
		if reference == "plumb":
			line += "\ncrossings %d%s" % [_crossings, _dir_word()]
		_update_label(line)

	if _ring_mat != null:
		_ring_glow = maxf(0.0, _ring_glow - delta * 3.0)
		_ring_mat.emission_energy_multiplier = 0.4 + 2.4 * _ring_glow

	# Update visual rotation of pivot (for rod)
	_pivot.rotation.z = _angle

	# Calculate output values
	current_y_offset = sin(_angle) * pendulum_length
	current_angular_velocity = _angular_velocity
	current_amplitude = abs(_angle) / (PI * 0.45)  # Normalized 0-1

	# Emit signal for connected objects
	oscillation_updated.emit(current_y_offset, current_angular_velocity, current_amplitude)

func _update_label(text: String):
	if _label:
		_label.text = text

func _dir_word() -> String:
	if _last_crossing_dir > 0:
		return ", last → +x"
	if _last_crossing_dir < 0:
		return ", last → -x"
	return ""

# ── read by the Intro probe (commons/testing/probe_wcn_intro.gd) ──────────────
func crossings() -> int:
	return _crossings

func last_crossing_direction() -> int:
	return _last_crossing_dir

func angle() -> float:
	return _angle

func angular_velocity() -> float:
	return _angular_velocity

func is_grabbed() -> bool:
	return _is_grabbed

func bob_world_position() -> Vector3:
	return _bob_sphere.global_position if _bob_sphere != null else global_position

func rest_world_position() -> Vector3:
	return to_global(Vector3(0.0, -pendulum_length, 0.0))

func _on_bob_picked_up(_pickable):
	_is_grabbed = true
	_grab_start_time = Time.get_ticks_msec() / 1000.0
	_grab_velocity_samples.clear()
	_last_bob_position = _bob_sphere.global_position
	grabbed.emit()

func _on_bob_dropped(_pickable):
	_is_grabbed = false

	# Calculate angular velocity from grab movement
	if _grab_velocity_samples.size() > 0:
		var avg_velocity = Vector3.ZERO
		for v in _grab_velocity_samples:
			avg_velocity += v
		avg_velocity /= _grab_velocity_samples.size()
		# Samples are world-space hand motion; the angle belongs to this pivot.
		avg_velocity = global_basis.inverse() * avg_velocity

		# Convert linear velocity to angular velocity
		# Tangential velocity at pendulum length gives angular velocity
		var tangent_direction = Vector3(cos(_angle), sin(_angle), 0)
		var tangent_velocity = avg_velocity.dot(tangent_direction)
		_angular_velocity = tangent_velocity / pendulum_length

		# Clamp to reasonable values
		_angular_velocity = clampf(_angular_velocity, -10.0, 10.0)

	_grab_velocity_samples.clear()
	_prev_angle = _angle
	released.emit()

## The desktop pointer's carry, routed into the SAME handlers the VR grab uses: the
## release angle comes from the carried bob's position about this pivot and the angular
## velocity from the hand's own motion samples — not from a stand-in.
func on_desktop_grab(_pointer: Node) -> void:
	if _bob_sphere != null and not _is_grabbed:
		_on_bob_picked_up(_bob_sphere)


func on_desktop_drop(_pointer: Node) -> void:
	if _bob_sphere != null and _is_grabbed:
		_on_bob_dropped(_bob_sphere)


func grab():
	# Manual grab (for non-VR)
	_is_grabbed = true
	grabbed.emit()

func release():
	# Manual release (for non-VR)
	_is_grabbed = false
	released.emit()

func push(impulse: float):
	# Add angular velocity (for VR swing gesture)
	_angular_velocity += impulse

# For manual control (click/drag)
func set_angle_from_position(world_pos: Vector3):
	var local_pos = to_local(world_pos)
	_angle = atan2(local_pos.x, -local_pos.y)
	_angle = clampf(_angle, -PI * 0.45, PI * 0.45)
	_update_bob_position()

## The four numeric exports keep their pre-promotion behaviour exactly, generic setter and
## all — including the part of it that is broken, which is recorded rather than quietly
## repaired: `pendulum_length` is the declared critical_parameter and setting it moves the
## physics and the bob but NOT the rod mesh, which was sized once during _ready. No map
## passes it, so nothing is standing on either the bug or a fix for it.
## The two axis words are handled separately and never through `set`, so they validate,
## and they rebuild only when the word actually differs and only after _ready has built.
func apply_grid_config(config_data: Dictionary):
	for key in config_data:
		if key == "regime" or key == "evidence" or key == "reference":
			continue
		if key in self:
			set(key, config_data[key])
	var dirty: bool = false
	if config_data.has("regime"):
		var r: String = _pick(str(config_data["regime"]), REGIMES, regime)
		if r != regime:
			regime = r
			dirty = true
	if config_data.has("evidence"):
		var e: String = _pick(str(config_data["evidence"]), EVIDENCE, evidence)
		if e != evidence:
			evidence = e
			dirty = true
	if config_data.has("reference"):
		var f: String = _pick(str(config_data["reference"]), REFERENCES, reference)
		if f != reference:
			reference = f
			dirty = true
	if dirty and is_node_ready():
		_rebuild()

func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_pivot = null
	_rod = null
	_bob_sphere = null
	_label = null
	_evidence_root = null
	_reference_root = null
	_ring_mat = null
	_ring_glow = 0.0
	_is_grabbed = false
	_grab_velocity_samples.clear()
	_angle = START_ANGLE
	_prev_angle = START_ANGLE
	_angular_velocity = 0.0
	_crossings = 0
	_last_crossing_dir = 0
	_drive_t = 0.0
	_build_all()

# ── evidence ──────────────────────────────────────────────────────────────────────────
# Nothing below runs at the shipped default: `result` returns before a node is constructed,
# so the scene tree, the measured AABB and the grounding are what they were.

func _build_evidence() -> void:
	if evidence == "result":
		return
	_evidence_root = Node3D.new()
	_evidence_root.name = "Evidence"
	add_child(_evidence_root)
	if evidence == "axiom":
		var slate := _make_label(Color(0.95, 0.9, 0.75, 1.0), 30)
		slate.text = "θ̈ + 2ζω₀θ̇ + ω₀² sin θ = 0\nT = 2π √(L / g)"
		slate.position = Vector3(0.0, PLOT_Y, PLOT_Z)
		_evidence_root.add_child(slate)
		return
	_build_theta_plot()
	if evidence == "longhand":
		var z: float = _zeta()
		var w: float = _omega0()
		var readout := _make_label(Color(0.75, 0.9, 1.0, 1.0), 22)
		readout.text = "ζ = %.3f    ω₀ = %.2f rad/s    T = %.2f s" % [z, w, TAU / w]
		readout.position = Vector3(0.0, PLOT_Y - PLOT_H - 0.06, PLOT_Z)
		_evidence_root.add_child(readout)

## theta over the next PLOT_SECONDS, integrated with the SAME update rule _physics_process
## uses, at the same step it will actually run at. Asking the integrator beats transcribing
## five closed forms, and it means resonance needs no special case: the drive is in the loop
## because it is in the loop upstairs.
func _predict() -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	var dt: float = 1.0 / maxf(1.0, float(Engine.physics_ticks_per_second))
	var mult: float = _damping_multiplier(dt)
	var th: float = START_ANGLE
	var om: float = 0.0
	var t: float = 0.0
	var steps: int = int(PLOT_SECONDS / dt)
	for i in steps:
		var acc: float = -(gravity / pendulum_length) * sin(th)
		if regime == "resonance":
			t += dt
			acc += _drive_accel() * cos(_omega0() * t)
		om += acc * dt
		om *= mult
		th += om * dt
		th = clampf(th, -PI * 0.45, PI * 0.45)
		out.append(th)
	return out

func _build_theta_plot() -> void:
	var series: PackedFloat32Array = _predict()
	if series.size() < 2:
		return
	# Zero line — the thing "no crossing" is a statement about.
	var axis_bar := MeshInstance3D.new()
	var abox := BoxMesh.new()
	abox.size = Vector3(PLOT_W, 0.004, 0.004)
	axis_bar.mesh = abox
	axis_bar.material_override = _flat_mat(Color(0.45, 0.46, 0.52, 1.0), 0.0)
	axis_bar.position = Vector3(0.0, PLOT_Y, PLOT_Z)
	_evidence_root.add_child(axis_bar)
	# The prediction.
	var line := MeshInstance3D.new()
	line.name = "Theta"
	var imm := ImmediateMesh.new()
	imm.clear_surfaces()
	imm.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in series.size():
		var u: float = float(i) / float(series.size() - 1)
		var v: float = clampf(series[i] / PLOT_THETA_MAX, -1.0, 1.0)
		imm.surface_add_vertex(Vector3(
			lerp(-PLOT_W * 0.5, PLOT_W * 0.5, u),
			PLOT_Y + v * PLOT_H,
			PLOT_Z
		))
	imm.surface_end()
	line.mesh = imm
	line.material_override = _flat_mat(Color(1.0, 0.75, 0.35, 1.0), 1.6)
	_evidence_root.add_child(line)
	var tag := _make_label(Color(1.0, 0.75, 0.35, 1.0), 20)
	tag.text = "θ(t)"
	tag.position = Vector3(-PLOT_W * 0.5 - 0.07, PLOT_Y, PLOT_Z)
	_evidence_root.add_child(tag)

func _flat_mat(c: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if energy > 0.0:
		mat.emission_enabled = true
		mat.emission = c
		mat.emission_energy_multiplier = energy
	return mat

func _make_label(c: Color, size: int) -> Label3D:
	var l := Label3D.new()
	l.pixel_size = 0.0006
	l.font_size = size
	l.outline_size = 5
	l.modulate = c
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	return l
