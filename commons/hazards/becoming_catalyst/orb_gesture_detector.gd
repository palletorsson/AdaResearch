# @identity
# essence: two_hands_close + far_from_head -> orb forms; one hand presenting -> burst then cool
# desire: replace the projectile gun-shot with a relational gesture — the orb is the relation between the palms while it is held, not a thing you own
# critical_parameter: TWO_HAND_PROXIMITY / TWO_HAND_FROM_HEAD / ONE_HAND_FROM_HEAD — the body becomes the parameter
# triggers: physics_process reads both XR controller transforms; state machine flips between IDLE / FORMING / ACTIVE / FIRING / COOLDOWN
# emerges: capability-as-relation — the orb cannot be possessed, exists only while the gesture is held
# needs: XROrigin3D with LeftHand + RightHand + XRCamera3D (found at runtime)
# relationships: emits orb_formed/dissolved to CatalystOrb; emits hand_cooldown to bracelet luminance
# truth: the catalyst is a reaction the body catalyses — two hands as stable vessel, one hand as dispenser with recharge.

# OrbGestureDetector.gd
# Reads both XR controller transforms each frame, runs the orb-gesture
# state machine (two-handed sustained dose + one-handed burst + per-hand
# cooldown), and emits signals consumed by CatalystOrb.
#
# Per the sieve-recorded design rule (doc/ORB_GESTURE_SLICE.md): no UI,
# no numbers, no toast. Audiotactile + creature-visual change only.
#
# Cooldown is FELT: during cooldown the gesture simply produces no orb
# on that hand, and the bracelet stone (separate listener) dims.

extends Node3D
class_name OrbGestureDetector

# ── Gesture thresholds ───────────────────────────────────────────────────
const TWO_HAND_PROXIMITY: float = 0.30        # palms within 30 cm
const TWO_HAND_FROM_HEAD: float = 0.40        # midpoint >= 40 cm from head
const TWO_HAND_SUSTAIN: float = 0.30          # held > 0.3 s to form

const ONE_HAND_FROM_HEAD: float = 0.35        # one hand >= 35 cm out
const ONE_HAND_FORWARD_DOT: float = 0.40      # palm forward angle tolerance
const ONE_HAND_SUSTAIN: float = 0.20          # presenting pose > 0.2 s
const ONE_HAND_BURST_LIFETIME: float = 0.40   # burst projects for this long
const ONE_HAND_COOLDOWN: float = 1.20         # then that hand cools

# Cone-length range for two-handed (one-handed is fixed at 2.0 m).
const CONE_MIN: float = 1.5
const CONE_MAX: float = 3.5
const ONE_HAND_CONE: float = 2.0

# ── State ────────────────────────────────────────────────────────────────
enum State {
	IDLE,
	FORMING_TWO_HANDED,
	TWO_HANDED_ACTIVE,
	FORMING_ONE_HANDED_LEFT,
	FORMING_ONE_HANDED_RIGHT,
	ONE_HANDED_FIRING_LEFT,
	ONE_HANDED_FIRING_RIGHT,
}

var _state: int = State.IDLE
var _sustain_timer: float = 0.0
var _burst_timer: float = 0.0

# Per-hand cooldown timers (seconds remaining).
var _cooldown_left: float = 0.0
var _cooldown_right: float = 0.0

# XR rig refs resolved at runtime.
var _xr_origin: Node3D = null
var _left_controller: Node3D = null
var _right_controller: Node3D = null
var _xr_camera: Node3D = null

# Active catalyst mode (advisory — orb visual reads this).
var _active_mode: String = "primitives"

# ── Signals ──────────────────────────────────────────────────────────────
signal orb_formed(mode: String, origin: Vector3, direction: Vector3, two_handed: bool)
signal orb_dissolved
signal orb_state_tick(mode: String, origin: Vector3, direction: Vector3, cone_length: float, two_handed: bool)
signal hand_cooldown_started(hand: String)
signal hand_cooldown_finished(hand: String)


func _ready() -> void:
	add_to_group("orb_gesture_detector")
	_resolve_xr_rig()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_left_controller) or not is_instance_valid(_right_controller):
		_resolve_xr_rig()
		return

	# Tick cooldowns regardless of state.
	if _cooldown_left > 0.0:
		_cooldown_left = max(0.0, _cooldown_left - delta)
		if _cooldown_left == 0.0:
			hand_cooldown_finished.emit("left")
	if _cooldown_right > 0.0:
		_cooldown_right = max(0.0, _cooldown_right - delta)
		if _cooldown_right == 0.0:
			hand_cooldown_finished.emit("right")

	var lp: Vector3 = _left_controller.global_position
	var rp: Vector3 = _right_controller.global_position
	var hp: Vector3 = _xr_camera.global_position if is_instance_valid(_xr_camera) else Vector3.ZERO
	var midpoint: Vector3 = (lp + rp) * 0.5
	var two_hand_dist: float = lp.distance_to(rp)
	var mid_from_head: float = midpoint.distance_to(hp)
	var two_hand_match: bool = two_hand_dist <= TWO_HAND_PROXIMITY \
		and mid_from_head >= TWO_HAND_FROM_HEAD

	match _state:
		State.IDLE:
			_run_idle(two_hand_match, lp, rp, hp)
		State.FORMING_TWO_HANDED:
			_run_forming_two_handed(delta, two_hand_match, midpoint, hp)
		State.TWO_HANDED_ACTIVE:
			_run_two_handed_active(two_hand_match, midpoint, hp)
		State.FORMING_ONE_HANDED_LEFT, State.FORMING_ONE_HANDED_RIGHT:
			_run_forming_one_handed(delta, two_hand_match, lp, rp, hp)
		State.ONE_HANDED_FIRING_LEFT, State.ONE_HANDED_FIRING_RIGHT:
			_run_one_handed_firing(delta)


# ── State handlers ───────────────────────────────────────────────────────

func _run_idle(two_hand_match: bool, lp: Vector3, rp: Vector3, hp: Vector3) -> void:
	if two_hand_match:
		_state = State.FORMING_TWO_HANDED
		_sustain_timer = 0.0
		return
	# One-handed paths: only available if that hand isn't cooling.
	if _cooldown_left == 0.0 and _one_hand_pose("left", lp, hp):
		_state = State.FORMING_ONE_HANDED_LEFT
		_sustain_timer = 0.0
	elif _cooldown_right == 0.0 and _one_hand_pose("right", rp, hp):
		_state = State.FORMING_ONE_HANDED_RIGHT
		_sustain_timer = 0.0


func _run_forming_two_handed(delta: float, two_hand_match: bool, mid: Vector3, hp: Vector3) -> void:
	if not two_hand_match:
		_state = State.IDLE
		_sustain_timer = 0.0
		return
	_sustain_timer += delta
	if _sustain_timer >= TWO_HAND_SUSTAIN:
		_state = State.TWO_HANDED_ACTIVE
		var dir: Vector3 = _average_palm_forward()
		orb_formed.emit(_active_mode, mid, dir, true)


func _run_two_handed_active(two_hand_match: bool, mid: Vector3, hp: Vector3) -> void:
	if not two_hand_match:
		_state = State.IDLE
		_sustain_timer = 0.0
		orb_dissolved.emit()
		return
	var dir: Vector3 = _average_palm_forward()
	var from_head: float = mid.distance_to(hp)
	var cone_len: float = clamp(CONE_MIN + (from_head - TWO_HAND_FROM_HEAD), CONE_MIN, CONE_MAX)
	orb_state_tick.emit(_active_mode, mid, dir, cone_len, true)


func _run_forming_one_handed(delta: float, two_hand_match: bool, lp: Vector3, rp: Vector3, hp: Vector3) -> void:
	if two_hand_match:
		# Two-handed wins; abandon and start forming there instead.
		_state = State.FORMING_TWO_HANDED
		_sustain_timer = 0.0
		return
	var hand: String = "left" if _state == State.FORMING_ONE_HANDED_LEFT else "right"
	var hp_pos: Vector3 = lp if hand == "left" else rp
	if not _one_hand_pose(hand, hp_pos, hp):
		_state = State.IDLE
		_sustain_timer = 0.0
		return
	_sustain_timer += delta
	if _sustain_timer >= ONE_HAND_SUSTAIN:
		var ctrl: Node3D = _left_controller if hand == "left" else _right_controller
		var origin: Vector3 = ctrl.global_position
		var dir: Vector3 = -ctrl.global_transform.basis.z
		_burst_timer = 0.0
		_state = State.ONE_HANDED_FIRING_LEFT if hand == "left" else State.ONE_HANDED_FIRING_RIGHT
		orb_formed.emit(_active_mode, origin, dir, false)


func _run_one_handed_firing(delta: float) -> void:
	var hand: String = "left" if _state == State.ONE_HANDED_FIRING_LEFT else "right"
	var ctrl: Node3D = _left_controller if hand == "left" else _right_controller
	if not is_instance_valid(ctrl):
		_state = State.IDLE
		_burst_timer = 0.0
		orb_dissolved.emit()
		return
	_burst_timer += delta
	var origin: Vector3 = ctrl.global_position
	var dir: Vector3 = -ctrl.global_transform.basis.z
	orb_state_tick.emit(_active_mode, origin, dir, ONE_HAND_CONE, false)
	if _burst_timer >= ONE_HAND_BURST_LIFETIME:
		if hand == "left":
			_cooldown_left = ONE_HAND_COOLDOWN
		else:
			_cooldown_right = ONE_HAND_COOLDOWN
		hand_cooldown_started.emit(hand)
		_state = State.IDLE
		_burst_timer = 0.0
		orb_dissolved.emit()


# ── Pose & direction helpers ─────────────────────────────────────────────

func _one_hand_pose(hand: String, hand_pos: Vector3, hp: Vector3) -> bool:
	# "Presenting" pose: hand forward of head past a threshold,
	# palm-forward roughly away from head.
	var ctrl: Node3D = _left_controller if hand == "left" else _right_controller
	if not is_instance_valid(ctrl):
		return false
	if hand_pos.distance_to(hp) < ONE_HAND_FROM_HEAD:
		return false
	var fwd: Vector3 = -ctrl.global_transform.basis.z
	var to_hand: Vector3 = hand_pos - hp
	if to_hand.length_squared() < 0.0001:
		return false
	to_hand = to_hand.normalized()
	return fwd.dot(to_hand) > ONE_HAND_FORWARD_DOT


func _average_palm_forward() -> Vector3:
	if not is_instance_valid(_left_controller) or not is_instance_valid(_right_controller):
		return Vector3.FORWARD
	var lf: Vector3 = -_left_controller.global_transform.basis.z
	var rf: Vector3 = -_right_controller.global_transform.basis.z
	var avg: Vector3 = (lf + rf) * 0.5
	if avg.length_squared() < 0.01:
		return Vector3.FORWARD
	return avg.normalized()


# ── Public mode setter (bracelet calls this on stone-change) ─────────────

func set_active_mode(mode_id: String) -> void:
	_active_mode = mode_id


# ── XR rig resolution (runtime tree walk) ────────────────────────────────

func _resolve_xr_rig() -> void:
	var root: Node = get_tree().root
	_xr_origin = _find_first_of_class(root, "XROrigin3D")
	if _xr_origin == null:
		return
	_left_controller = _xr_origin.get_node_or_null("LeftHand")
	if _left_controller == null:
		_left_controller = _find_first_of_class(_xr_origin, "XRController3D")
	_right_controller = _xr_origin.get_node_or_null("RightHand")
	if _right_controller == null and is_instance_valid(_left_controller):
		# Try the second XRController3D.
		var ctrls: Array[Node] = []
		_collect_of_class(_xr_origin, "XRController3D", ctrls)
		for c in ctrls:
			if c != _left_controller:
				_right_controller = c
				break
	_xr_camera = _xr_origin.get_node_or_null("XRCamera3D")
	if _xr_camera == null:
		_xr_camera = _find_first_of_class(_xr_origin, "XRCamera3D")


static func _find_first_of_class(node: Node, type_name: String) -> Node:
	if node.get_class() == type_name:
		return node
	for c in node.get_children():
		var r := _find_first_of_class(c, type_name)
		if r != null:
			return r
	return null


static func _collect_of_class(node: Node, type_name: String, out: Array[Node]) -> void:
	if node.get_class() == type_name:
		out.append(node)
	for c in node.get_children():
		_collect_of_class(c, type_name, out)
