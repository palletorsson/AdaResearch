class_name TorsoEstimator
extends Node3D
## TorsoEstimator — 3-point tracking for torso orientation
##
## Estimates torso pose from head (XRCamera3D) and two hand controllers.
## "The body is not given — it is composed." The torso is never directly
## tracked in 3-point VR; it must be inferred, an act of composition
## that mirrors how identity itself is assembled from partial signals.

## ————————————————————————————————————————————————————————————————————
## Exports
## ————————————————————————————————————————————————————————————————————

## Full shoulder span (meters). Shoulders are placed at +/- half this width.
@export var shoulder_width: float = 0.36

## Vertical offset from camera to estimated neck pivot (meters downward).
@export var neck_offset: float = 0.15

## Blend weight for head forward vs hand-midpoint forward (0-1).
## Higher = torso follows head gaze more; lower = follows hand direction.
@export var head_weight: float = 0.7

## ————————————————————————————————————————————————————————————————————
## References — set by parent (PlayerBodyIK)
## ————————————————————————————————————————————————————————————————————

var camera: XRCamera3D
var left_hand: Node3D
var right_hand: Node3D

## ————————————————————————————————————————————————————————————————————
## Readable properties
## ————————————————————————————————————————————————————————————————————

## World-space shoulder positions, updated every physics frame.
var left_shoulder_pos: Vector3
var right_shoulder_pos: Vector3

## Current smoothed torso yaw (radians).
var _torso_yaw: float = 0.0

## ————————————————————————————————————————————————————————————————————
## Lifecycle
## ————————————————————————————————————————————————————————————————————

func _ready() -> void:
	set_physics_process(false) # enabled once references are valid


func _physics_process(delta: float) -> void:
	if not _refs_valid():
		return

	## Step 1 — Neck position: camera lowered by neck_offset
	var neck_pos: Vector3 = camera.global_position - Vector3(0.0, neck_offset, 0.0)

	## Step 2 — Head forward projected onto XZ plane
	var head_fwd_raw: Vector3 = -camera.global_basis.z
	var head_fwd: Vector3 = Vector3(head_fwd_raw.x, 0.0, head_fwd_raw.z).normalized()

	## Step 3 — Hand midpoint forward from neck
	var hand_mid: Vector3 = (left_hand.global_position + right_hand.global_position) * 0.5
	var hand_dir_raw: Vector3 = hand_mid - neck_pos
	var hand_fwd: Vector3 = Vector3(hand_dir_raw.x, 0.0, hand_dir_raw.z)
	if hand_fwd.length_squared() < 0.001:
		hand_fwd = head_fwd # fallback when hands are directly above/below neck
	else:
		hand_fwd = hand_fwd.normalized()

	## Step 4 — Blended torso forward
	var blended_fwd: Vector3 = (head_fwd * head_weight + hand_fwd * (1.0 - head_weight)).normalized()
	var target_yaw: float = atan2(blended_fwd.x, blended_fwd.z)

	## Step 5 — Exponential smoothing on yaw
	var smooth_speed: float = 10.0
	_torso_yaw = lerp_angle(_torso_yaw, target_yaw, clampf(smooth_speed * delta, 0.0, 1.0))

	## Derive torso basis vectors
	var torso_fwd_final: Vector3 = Vector3(sin(_torso_yaw), 0.0, cos(_torso_yaw))
	var torso_right: Vector3 = torso_fwd_final.cross(Vector3.UP).normalized()

	## Step 6 — Shoulder positions
	var shoulder_half: float = shoulder_width * 0.5
	var shoulder_down: float = 0.1 # shoulders sit slightly below neck
	left_shoulder_pos = neck_pos - torso_right * shoulder_half - Vector3(0.0, shoulder_down, 0.0)
	right_shoulder_pos = neck_pos + torso_right * shoulder_half - Vector3(0.0, shoulder_down, 0.0)

	## Update this node's own transform for debug visualization
	global_position = neck_pos
	global_basis = Basis.looking_at(torso_fwd_final, Vector3.UP) if torso_fwd_final.length_squared() > 0.001 else Basis.IDENTITY


## ————————————————————————————————————————————————————————————————————
## Helpers
## ————————————————————————————————————————————————————————————————————

func set_tracking_refs(cam: XRCamera3D, l_hand: Node3D, r_hand: Node3D) -> void:
	camera = cam
	left_hand = l_hand
	right_hand = r_hand
	if _refs_valid():
		set_physics_process(true)
		print("[TorsoEstimator] Tracking refs set — physics processing enabled")
	else:
		push_error("[TorsoEstimator] One or more tracking references are null")


func _refs_valid() -> bool:
	return is_instance_valid(camera) and is_instance_valid(left_hand) and is_instance_valid(right_hand)
