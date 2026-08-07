class_name EmFeel
extends Node
# em_feel.gd — the endless museum walker's body language.
#
# AAA first-person feel is mostly camera. This node owns the walker's velocity
# curve, the head's motion, the view's smoothing and the footfall clock. It owns
# NOTHING else: no geometry, no audio, no lights. It plays no sound — it emits
# `footstep(surface_hint)` at the exact contact moment so an audio module can.
#
# HOST CONTRACT (three calls):
#     _feel = EmFeel.new(); add_child(_feel); _feel.configure(_player, _cam)
#     _player.velocity = _feel.step(delta, world_input_dir, sprinting)   # physics
#     _feel.look(event.relative)                                        # _input
#
# It is INERT until step() is first called, so the proof-shot and autopilot
# paths (which drive the body themselves and never call step) are untouched.
#
# DIVISION OF LABOUR between the two clocks — this is the whole design:
#   step()      runs at physics rate. It MEASURES what actually happened (real
#               displacement, post-slide velocity) and returns the next desired
#               velocity. It never touches the camera.
#   _process()  runs at render rate. It drains the look buffer, advances the bob
#               by distance, fires footsteps, and writes the view. Mouse look and
#               head bob therefore update at the monitor's rate, not at 60 Hz —
#               the single biggest difference between "responsive" and "soupy".
#
# MOMENTUM SURVIVES A WALL SLIDE because step() re-reads `player.velocity` at the
# top of every tick. move_and_slide() has already written the SLID velocity back
# into it, so a 45-degree brush against a wall keeps its tangential speed and
# only loses the component into the wall. An internal integrator that ignored the
# body would instead spring back to full speed the instant you cleared the corner.
#
# EVERY NUMBER BELOW IS STATED IN CENTIMETRES, DEGREES OR SECONDS, because the
# failure mode of head bob is nausea and "0.016" tells you nothing about that.
# The defaults are deliberately at the quiet end: bob you feel, not bob you see.

## Fired at the instant a foot contacts the floor — the bob's lowest point.
## Two per stride. Read `last_step_left` for which foot. Play nothing here.
signal footstep(surface_hint: String)
## Fired when a fall is absorbed. Never fires in the flat museum (no gravity).
signal landed(impact_speed: float)

# The bob's phase runs 0..TAU per STRIDE (two steps). Vertical is sin(2*phase),
# lateral is sin(phase) — a 2:1 Lissajous, i.e. a figure eight, which is what a
# head actually traces: it drops once per FOOTFALL but sways once per STRIDE.
# Contact is where sin(2*phase) bottoms out: phase = 3PI/4 and 7PI/4.
const CONTACT_L: float = 0.75 * PI
const CONTACT_R: float = 1.75 * PI

# ── LOCOMOTION ────────────────────────────────────────────────────────────────
@export_group("Locomotion")
## 3.6 m/s. Real brisk walking is 1.8 m/s, but a 90-degree FOV shows twice the
## world an eye does, so honest speed reads as wading. 2x real is the shipped
## convention; the museum's 1 m grid still resolves at this rate.
@export var walk_speed: float = 3.6
## 6.3 m/s — 1.75x walk. The scene's old 2.5x (10 m/s) strobes the 1 m cells and
## crosses a 30 m gallery in three seconds, which is not a museum, it is a train.
@export var sprint_speed: float = 6.3
## 26 m/s^2: 0 -> walk in ~0.14 s before the launch curve, ~0.17 s after.
@export var ground_accel: float = 26.0
## 18 m/s^2: walk -> 0 in ~0.20 s. Slower than the launch, because a body under
## its own weight stops later than it starts. This asymmetry IS the weight.
@export var ground_decel: float = 18.0
## 34 m/s^2 when the new input opposes the current velocity. Without this a
## reversal has to spend the full decel then the full accel and reads as ice.
@export var turn_accel: float = 34.0
## Acceleration multiplier at a standstill, easing to 1.0 by 60% of top speed.
## 0.65 = a short bite of inertia at the first step. Below ~0.5 it reads as lag.
@export var launch_bite: float = 0.65
## Below 0.12 m/s with no input, snap to rest — 2 mm of drift a frame is
## invisible but keeps the bob phase creeping and the footstep clock ticking.
@export var stop_snap_speed: float = 0.12
## 60 ms low-pass on the measured speed. One frame of displacement is noisy;
## unsmoothed it makes the bob amplitude and the FOV jitter.
@export var speed_smooth_tau: float = 0.060

# ── HEAD BOB ──────────────────────────────────────────────────────────────────
@export_group("Head bob")
## 1.6 cm peak = 3.2 cm peak-to-peak at walk. A real head moves ~5 cm p-p, but a
## real head is counter-stabilised by the vestibulo-ocular reflex, which a
## monitor cannot reproduce — so the honest number is the nauseating one.
## 3.2 cm p-p sits at the low end of shipped values: felt, not noticed.
@export var bob_vertical_cm: float = 1.6
## 1.1 cm peak = 2.2 cm p-p, about 0.7x the vertical. Lateral reads STRONGER
## than vertical because it slides against a corridor's vertical edges, so it
## has to be quieter to weigh the same.
@export var bob_lateral_cm: float = 1.1
## 0.25 degrees of nod at footfall, in phase with the vertical drop. A quarter
## of a degree is under the conscious threshold; it exists to keep the drop from
## reading as the whole room moving down.
@export var bob_pitch_deg: float = 0.25
## 0.35 degrees of roll following the lateral sway. Couples the two axes so the
## figure eight reads as one motion instead of two oscillators.
@export var bob_roll_deg: float = 0.35
## Amplitude multiplier is speed/walk_speed, capped at 1.5 — at sprint that is
## 2.4 cm vertical, 1.65 cm lateral. Uncapped, a speed powerup becomes an emetic.
@export var bob_amp_cap: float = 1.5
## 120 ms fade of the whole bob envelope in and out of rest. Faster than this and
## stopping snaps the head; slower and the head keeps nodding after you have.
@export var bob_fade_tau: float = 0.12
## 1.65 m per step at walk = 2.2 steps/s. A real 3.6 m/s stride would be ~4.8
## steps/s, which reads as scurrying — above ~2.5 Hz the ear stops hearing a walk
## and starts hearing a rattle. Games lengthen the virtual stride for this reason.
@export var step_length_walk: float = 1.65
## 2.10 m per step at sprint = 3.0 steps/s. The +38% cadence jump (2.2 -> 3.0 Hz)
## is what makes a sprint audibly a sprint, not a fast walk. Both the bob
## frequency and the footstep signal inherit it, so they can never desync.
@export var step_length_sprint: float = 2.10

@export_group("Strafe and idle")
## 0.9 degrees of roll at a full sidestep. 1 degree is roughly the threshold of
## noticing a tilt; past ~2 degrees the horizon visibly cants and reads as drunk.
@export var strafe_roll_deg: float = 0.9
## 180 ms to reach the roll. Shorter and a strafe tap flicks the horizon.
@export var strafe_roll_tau: float = 0.18
## 0.4 cm of vertical drift while standing still — breathing. Costs nothing and
## is the difference between a person standing and a camera on a tripod.
@export var idle_sway_cm: float = 0.4
## 0.22 Hz = 13 breaths a minute, a resting adult rate.
@export var idle_sway_hz: float = 0.22

# ── FIELD OF VIEW ─────────────────────────────────────────────────────────────
@export_group("Field of view")
## +6.0 degrees at full sprint. On a 90-degree base that is +6.7%: enough that
## the periphery streaks and speed reads, below the ~10 degrees where the frame
## visibly breathes and straight architectural lines start to bow.
@export var fov_sprint_gain: float = 6.0
## 220 ms to widen — the FOV should arrive slightly AFTER the speed, so it reads
## as a consequence of running rather than as a button press.
@export var fov_in_tau: float = 0.22
## 300 ms to return. Asymmetric on purpose: a snap back to base is a visible cut.
@export var fov_out_tau: float = 0.30
## -3.5 degrees at the bottom of a landing. Narrowing on impact is the opposite
## sign to the sprint, so the two can never be confused.
@export var fov_land_dip: float = 3.5

@export_group("Landing")
## 6 cm of knee absorb at a reference-speed landing. Four times the walk bob,
## which is what makes a landing an event rather than a big step.
@export var land_dip_cm: float = 6.0
## 280 ms total: ~70 ms down (the impact), ~210 ms smoothstep back up (the push).
@export var land_dip_time: float = 0.28
## 8 m/s of descent = a full-strength dip. Roughly a 3.2 m drop under 1g.
@export var land_reference_speed: float = 8.0

# ── LOOK ──────────────────────────────────────────────────────────────────────
@export_group("Look")
## 0.0020 rad per mouse pixel — unchanged from the scene's existing value, so
## nobody's muscle memory is rewritten by a feel pass.
@export var mouse_sensitivity: float = 0.0020
## 18 ms. A first-order lag's mean added latency IS its time constant, so this is
## 1.1 frames at 60 Hz and 2.6 at 144 Hz — the honest cost of the smoothing, and
## the reason the drain runs in _process and not in _physics_process. Set to 0
## for raw input. Anything past ~35 ms is felt as the mouse being on a string.
@export var look_tau: float = 0.018
## +/- 1.20 rad = 68.8 degrees, matching the scene. Full 90 lets the walker look
## at their own feet, which in a museum is never what you want.
@export var pitch_limit: float = 1.20
## Passed verbatim to the footstep signal. The host sets it from whatever it
## knows about the floor; this node never guesses.
@export var current_surface: String = "stone"

## Which foot last landed — for alternating footstep samples.
var last_step_left: bool = false

var _player: CharacterBody3D = null
var _cam: Camera3D = null
var _cam_base: Vector3 = Vector3.ZERO
var _base_fov: float = 75.0
var _live: bool = false

var _yaw: float = 0.0
var _pitch: float = 0.0
var _look_pending: Vector2 = Vector2.ZERO

var _vel: Vector3 = Vector3.ZERO
var _prev_pos: Vector3 = Vector3.ZERO
var _have_prev: bool = false
var _speed: float = 0.0
var _step_len: float = 1.65
var _strafe: float = 0.0

var _bob_phase: float = 0.0
var _bob_env: float = 0.0
var _roll: float = 0.0
var _fov_bonus: float = 0.0
var _idle_t: float = 0.0

var _land_t: float = -1.0
var _land_scale: float = 0.0
var _was_on_floor: bool = true
var _prev_vy: float = 0.0


func _ready() -> void:
	# the view must be written after anything else that might touch the camera
	process_priority = 100
	set_process(true)


## Bind the walker and its camera. Call once, after both exist and after the
## walker's starting yaw is set — the current yaw/pitch/FOV become the baseline.
func configure(player: CharacterBody3D, cam: Camera3D) -> void:
	_player = player
	_cam = cam
	if _player == null or _cam == null:
		push_error("EmFeel.configure: needs a CharacterBody3D and a Camera3D")
		return
	_yaw = _player.rotation.y
	_pitch = _cam.rotation.x
	_cam_base = _cam.position
	_base_fov = _cam.fov
	_prev_pos = _player.global_position
	_have_prev = true
	_was_on_floor = _player.is_on_floor()


## Feed one physics tick. `input_dir` is a WORLD-space direction (it need not be
## normalised; y is ignored). Returns the velocity to assign before
## move_and_slide(). Does not touch the camera — that happens at render rate.
func step(delta: float, input_dir: Vector3, sprinting: bool) -> Vector3:
	if _player == null or _cam == null or delta <= 0.0:
		return Vector3.ZERO
	_live = true

	# 1. MEASURE. Distance is what the body actually covered last tick, not what
	#    it was told to cover — walking into a wall must not tick the bob.
	var pos: Vector3 = _player.global_position
	var travelled: float = 0.0
	if _have_prev:
		var d: Vector3 = pos - _prev_pos
		d.y = 0.0
		travelled = d.length()
		if travelled > 2.0:
			travelled = 0.0  # a teleport, not a stride
	_prev_pos = pos
	_have_prev = true
	var raw_speed: float = travelled / delta
	_speed += (raw_speed - _speed) * _lag(delta, speed_smooth_tau)

	# 2. INHERIT. move_and_slide() wrote the post-slide velocity back into the
	#    body; taking it as our base is what makes momentum survive a wall.
	var vy: float = _player.velocity.y
	_vel = _player.velocity
	_vel.y = 0.0

	# 3. TARGET.
	var dir: Vector3 = input_dir
	dir.y = 0.0
	var top: float = sprint_speed if sprinting else walk_speed
	var target: Vector3 = Vector3.ZERO
	var wants_move: bool = dir.length_squared() > 1e-6
	if wants_move:
		dir = dir.normalized()
		target = dir * top

	# 4. CURVE. Launch bite at rest, turn accel against the grain, decel is
	#    gentler than accel so stopping carries weight.
	var cur: float = _vel.length()
	var a: float = ground_decel
	if wants_move:
		a = ground_accel
		if cur > 0.05 and _vel.normalized().dot(dir) < 0.5:
			a = turn_accel
		var ramp: float = clampf(cur / maxf(0.001, top * 0.6), 0.0, 1.0)
		a *= lerpf(launch_bite, 1.0, ramp)
	_vel = _vel.move_toward(target, a * delta)
	if not wants_move and _vel.length() < stop_snap_speed:
		_vel = Vector3.ZERO

	# 5. STRAFE SIGN for the roll — the sideways part of the input, in the
	#    walker's own frame, damped by how fast we are actually going (leaning
	#    into a wall you cannot move along must not tilt the horizon).
	var strafe_target: float = 0.0
	if wants_move:
		strafe_target = _player.global_transform.basis.x.dot(dir)
		strafe_target *= clampf(_speed / maxf(0.001, walk_speed), 0.0, 1.0)
	_strafe += (strafe_target - _strafe) * _lag(delta, strafe_roll_tau)

	# 6. STRIDE LENGTH follows speed, so the bob frequency and the footstep
	#    signal are the same clock and cannot drift apart.
	var f: float = clampf((_speed - walk_speed) / maxf(0.001, sprint_speed - walk_speed), 0.0, 1.0)
	_step_len = lerpf(step_length_walk, step_length_sprint, f)

	# 7. LANDING (inert in the flat museum: no gravity means vy is always 0).
	var on_floor: bool = _player.is_on_floor()
	if on_floor and not _was_on_floor and _prev_vy < -1.0:
		land(absf(_prev_vy))
	_was_on_floor = on_floor
	_prev_vy = vy

	return Vector3(_vel.x, vy, _vel.z)


## Accumulate raw mouse motion. Call from _input on InputEventMouseMotion.
## Buffered, not applied — the drain happens in _process at render rate.
func look(relative: Vector2) -> void:
	_look_pending += relative


## Absorb a landing by hand (for scripted drops). `impact_speed` in m/s.
func land(impact_speed: float) -> void:
	var scale: float = clampf(impact_speed / maxf(0.001, land_reference_speed), 0.0, 1.0)
	if scale < 0.05:
		return  # a scuff, not a landing — and do not clobber a dip in progress
	_land_scale = scale
	_land_t = 0.0
	landed.emit(impact_speed)


## After a teleport: forget the last position so the jump is not read as a
## sprint, and drop any queued mouse motion.
func teleported() -> void:
	_have_prev = false
	_speed = 0.0
	_vel = Vector3.ZERO
	_look_pending = Vector2.ZERO
	_bob_phase = 0.0
	_bob_env = 0.0
	if _player != null:
		_prev_pos = _player.global_position
		_yaw = _player.rotation.y
		_have_prev = true


## Adopt a yaw/pitch set from outside (a scripted look, a cutscene handover).
## Takes the angles explicitly rather than reading them back off the camera,
## because the camera's live rotation carries the bob and would fold it in.
func resync_view(yaw: float, pitch: float) -> void:
	_yaw = fposmod(yaw, TAU)
	_pitch = clampf(pitch, -pitch_limit, pitch_limit)
	_look_pending = Vector2.ZERO


func _process(delta: float) -> void:
	# INERT until the host drives us — the proof-shot and autopilot paths aim the
	# camera themselves and must not be fought over.
	if not _live or _player == null or _cam == null or delta <= 0.0:
		return
	_drain_look(delta)
	_advance_bob(delta)
	_apply_view(delta)


## First-order lag: drains a fixed FRACTION of the pending motion each frame, so
## the response is frame-rate independent and adds exactly `look_tau` of mean
## latency — no queue, no accumulation, no rubber band.
func _drain_look(delta: float) -> void:
	if _look_pending == Vector2.ZERO:
		return
	var k: float = 1.0 if look_tau <= 0.0 else _lag(delta, look_tau)
	var applied: Vector2 = _look_pending * k
	_look_pending -= applied
	if _look_pending.length_squared() < 1e-8:
		_look_pending = Vector2.ZERO
	_yaw = fposmod(_yaw - applied.x * mouse_sensitivity, TAU)
	var want_pitch: float = _pitch - applied.y * mouse_sensitivity
	_pitch = clampf(want_pitch, -pitch_limit, pitch_limit)
	if not is_equal_approx(want_pitch, _pitch):
		_look_pending.y = 0.0  # clamped: do not wind up a debt at the limit


## Advance the figure eight by DISTANCE (speed measured from real displacement,
## times elapsed time) and fire the footstep at each contact.
func _advance_bob(delta: float) -> void:
	_idle_t += delta
	var moving: bool = _speed > 0.35
	var amp_target: float = 0.0
	if moving:
		amp_target = clampf(_speed / maxf(0.001, walk_speed), 0.0, bob_amp_cap)
	_bob_env += (amp_target - _bob_env) * _lag(delta, bob_fade_tau)
	if _bob_env < 0.02 and not moving:
		_bob_env = 0.0
		_bob_phase = 0.0
		return
	# one full phase turn per STRIDE, and a stride is two steps
	var dphase: float = TAU * (_speed * delta) / maxf(0.05, _step_len * 2.0)
	if dphase <= 0.0:
		return
	var prev: float = _bob_phase
	_bob_phase = fposmod(_bob_phase + dphase, TAU)
	if not moving:
		return
	var window: float = minf(dphase, TAU)
	for i in range(2):
		var contact: float = CONTACT_L if i == 0 else CONTACT_R
		var gap: float = fposmod(contact - prev, TAU)
		if gap > 0.0 and gap <= window:
			last_step_left = (i == 0)
			footstep.emit(current_surface)


func _apply_view(delta: float) -> void:
	# — FOV from the speed actually achieved, so sprinting into a wall lets it
	#   fall back instead of holding a lie.
	var span: float = maxf(0.001, sprint_speed - walk_speed)
	var fov_target: float = fov_sprint_gain * clampf((_speed - walk_speed) / span, 0.0, 1.0)
	var tau: float = fov_in_tau if fov_target > _fov_bonus else fov_out_tau
	_fov_bonus += (fov_target - _fov_bonus) * _lag(delta, tau)

	# — landing: a fast drop, a smoothstep push back up
	var dip: float = 0.0
	if _land_t >= 0.0:
		_land_t += delta
		if _land_t >= land_dip_time:
			_land_t = -1.0
		else:
			var u: float = _land_t / maxf(0.001, land_dip_time)
			if u < 0.25:
				dip = u / 0.25
			else:
				var k: float = (u - 0.25) / 0.75
				dip = 1.0 - (k * k * (3.0 - 2.0 * k))
			dip *= _land_scale

	# — the figure eight: vertical at twice the lateral frequency
	var s1: float = sin(_bob_phase)
	var s2: float = sin(2.0 * _bob_phase)
	var bob_y: float = (bob_vertical_cm * 0.01) * s2 * _bob_env
	var bob_x: float = (bob_lateral_cm * 0.01) * s1 * _bob_env
	var idle_env: float = 1.0 - clampf(_speed / maxf(0.001, walk_speed * 0.5), 0.0, 1.0)
	bob_y += (idle_sway_cm * 0.01) * sin(TAU * idle_sway_hz * _idle_t) * idle_env
	bob_y -= (land_dip_cm * 0.01) * dip

	var pitch_bob: float = deg_to_rad(bob_pitch_deg) * s2 * _bob_env
	var roll_bob: float = deg_to_rad(bob_roll_deg) * s1 * _bob_env
	_roll = deg_to_rad(-strafe_roll_deg) * _strafe

	_player.rotation.y = _yaw
	_cam.rotation = Vector3(_pitch + pitch_bob, 0.0, _roll + roll_bob)
	_cam.position = _cam_base + Vector3(bob_x, bob_y, 0.0)
	_cam.fov = _base_fov + _fov_bonus - fov_land_dip * dip


## Frame-rate-independent fraction of the way to a target for time constant tau.
## Written out rather than using lerp with a raw delta, which is the classic bug
## that makes every smoothing in a project frame-rate dependent.
func _lag(delta: float, tau: float) -> float:
	if tau <= 0.0:
		return 1.0
	return 1.0 - exp(-delta / tau)
