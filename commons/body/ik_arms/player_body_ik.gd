class_name PlayerBodyIK
extends Node3D
## PlayerBodyIK — Orchestrator for the IK arm system
##
## "The body is not given — it is composed. Each limb extends the boundary
## between self and world." In VR, embodiment is always partial: three points
## of tracking become an entire upper body through inference, interpolation,
## and the willingness to treat an approximation as presence. This system
## composes a torso from a headset and two controllers, then solves two
## arms that reach from estimated shoulders to tracked hands — bridging
## the gap between what is measured and what is felt.

## ————————————————————————————————————————————————————————————————————
## Internal references
## ————————————————————————————————————————————————————————————————————

## PRELOAD, NOT class_name — 2026-08-29, and this cost a live VR session.
##
## These were TorsoEstimator.new() and IKArmRig.new(), resolved through Godot's
## global class cache. That cache went stale (a class_name added and removed in
## the same session, in a namespace that already held TartanBoxes3D), and the
## names then resolved to plain GDScript RESOURCES — so `.new()` failed with
## "Nonexistent function 'new' in base 'GDScript'" and the arms never built.
##
## A preload is resolved by PATH at parse time and cannot go stale. The typed
## vars drop to Node3D for the same reason: a `: TorsoEstimator` annotation needs
## the same cache the constructor did.
const TorsoEstimatorScript = preload("res://commons/body/ik_arms/torso_estimator.gd")
const IKArmRigScript = preload("res://commons/body/ik_arms/ik_arm_rig.gd")

var _torso: Node3D
var _left_arm: Node3D
var _right_arm: Node3D

## ————————————————————————————————————————————————————————————————————
## Lifecycle
## ————————————————————————————————————————————————————————————————————

func _ready() -> void:
	## Step 1 — Find the XROrigin3D parent
	var xr_origin: XROrigin3D = _find_xr_origin()
	if not xr_origin:
		push_error("[PlayerBodyIK] No XROrigin3D found in ancestors — IK arms disabled")
		set_physics_process(false)
		return

	## Step 2 — Locate camera and hand controllers
	var camera: XRCamera3D = _find_child_of_type(xr_origin, "XRCamera3D") as XRCamera3D
	var left_hand: Node3D = _find_hand(xr_origin, true)
	var right_hand: Node3D = _find_hand(xr_origin, false)

	if not camera:
		push_error("[PlayerBodyIK] XRCamera3D not found under XROrigin3D")
		set_physics_process(false)
		return
	if not left_hand:
		push_error("[PlayerBodyIK] Left hand controller not found under XROrigin3D")
	if not right_hand:
		push_error("[PlayerBodyIK] Right hand controller not found under XROrigin3D")

	## Step 3 — Create TorsoEstimator
	_torso = TorsoEstimatorScript.new()
	_torso.name = "TorsoEstimator"
	add_child(_torso)
	if left_hand and right_hand:
		_torso.set_tracking_refs(camera, left_hand, right_hand)

	## Step 4 — Create arm rigs
	_left_arm = IKArmRigScript.new()
	_left_arm.name = "LeftArmRig"
	_left_arm.is_left = true
	add_child(_left_arm)
	if left_hand:
		_left_arm.set_controller(left_hand)

	_right_arm = IKArmRigScript.new()
	_right_arm.name = "RightArmRig"
	_right_arm.is_left = false
	add_child(_right_arm)
	if right_hand:
		_right_arm.set_controller(right_hand)

	print("[PlayerBodyIK] Initialized with 2 arm rigs")


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_torso):
		return

	## Feed shoulder positions AND THE TORSO'S AXES from the estimator into the arm
	## rigs. The axes are what let an arm know which way "outboard" is — without
	## them the elbow pole was placed against the play space's forward, so it did
	## not turn when the player did, and it could not be mirrored per side.
	var t_right: Vector3 = _torso.torso_right
	var t_fwd: Vector3 = _torso.torso_forward
	if is_instance_valid(_left_arm):
		_left_arm.set_torso_frame(t_right, t_fwd)
		_left_arm.set_shoulder_position(_torso.left_shoulder_pos)
	if is_instance_valid(_right_arm):
		_right_arm.set_torso_frame(t_right, t_fwd)
		_right_arm.set_shoulder_position(_torso.right_shoulder_pos)


## ————————————————————————————————————————————————————————————————————
## Public API
## ————————————————————————————————————————————————————————————————————

## Set skin color on both arms.
func set_skin_color(color: Color) -> void:
	if is_instance_valid(_left_arm):
		_left_arm.set_arm_color(color)
	if is_instance_valid(_right_arm):
		_right_arm.set_arm_color(color)


## Toggle arm visibility.
func set_visible_arms(v: bool) -> void:
	if is_instance_valid(_left_arm):
		_left_arm.visible = v
	if is_instance_valid(_right_arm):
		_right_arm.visible = v


## ————————————————————————————————————————————————————————————————————
## Discovery helpers
## ————————————————————————————————————————————————————————————————————

func _find_xr_origin() -> XROrigin3D:
	## Walk up the tree looking for an XROrigin3D ancestor
	var node: Node = get_parent()
	while node:
		if node is XROrigin3D:
			return node as XROrigin3D
		node = node.get_parent()
	return null


func _find_child_of_type(parent: Node, type_name: String) -> Node:
	## Breadth-first search for the first child matching a class name
	for child in parent.get_children():
		if child.get_class() == type_name or child.is_class(type_name):
			return child
	for child in parent.get_children():
		var found := _find_child_of_type(child, type_name)
		if found:
			return found
	return null


func _find_hand(xr_origin: XROrigin3D, left: bool) -> Node3D:
	## Look for XRController3D or XRNode3D children with common hand names
	var left_names: Array[String] = ["LeftHand", "Left", "left_hand", "left_controller"]
	var right_names: Array[String] = ["RightHand", "Right", "right_hand", "right_controller"]
	var search_names: Array[String] = left_names if left else right_names

	for child in xr_origin.get_children():
		if child is Node3D:
			var child_name: String = child.name.to_lower()
			for sname in search_names:
				if child_name.contains(sname.to_lower()):
					return child as Node3D

	## Fallback: look for XRController3D by tracker name
	for child in xr_origin.get_children():
		if child is XRController3D:
			var ctrl := child as XRController3D
			var tracker: String = ctrl.tracker.to_lower() if ctrl.tracker else ""
			if left and tracker.contains("left"):
				return ctrl
			if not left and tracker.contains("right"):
				return ctrl

	return null
