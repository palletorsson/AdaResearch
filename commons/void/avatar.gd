extends RefCounted
## The appearance from base.tscn, mounted on the Void's existing controllers.
## Movement, collision body and pickup ownership remain with game.gd.
const LEFT_HAND := preload("res://commons/body/hands/left_hand.tscn")
const RIGHT_HAND := preload("res://commons/body/hands/right_hand.tscn")
const HAND := preload("res://addons/godot-xr-tools/hands/hand.gd")
const LEFT_BLEND := preload("res://addons/godot-xr-tools/hands/animations/left/hand_blend_tree.tres")
const RIGHT_BLEND := preload("res://addons/godot-xr-tools/hands/animations/right/hand_blend_tree.tres")
const LEFT_POSE := preload("res://addons/godot-xr-tools/hands/poses/pose_default_left.tres")
const RIGHT_POSE := preload("res://addons/godot-xr-tools/hands/poses/pose_default_right.tres")
const CUSTOMIZATION := preload("res://commons/player/PlayerCustomization.gd")

static func mount(origin: XROrigin3D) -> void:
	for is_left in [true, false]:
		var controller := origin.get_node("LeftHand" if is_left else "RightHand")
		var hand: Node3D = (LEFT_HAND if is_left else RIGHT_HAND).instantiate()
		# base.tscn overrides the right scene's root script in exactly this way.
		hand.set_script(HAND)
		hand.name = "AvatarHand"
		hand.hand_blend_tree = LEFT_BLEND if is_left else RIGHT_BLEND
		hand.default_pose = LEFT_POSE if is_left else RIGHT_POSE
		controller.add_child(hand)
		# XRTools' grab-driver hand search includes owned nodes only.
		hand.owner = origin
	var appearance := CUSTOMIZATION.new()
	appearance.name = "PlayerCustomization"
	var manager := origin.get_node_or_null("/root/GameManager")
	if manager != null and manager.has_method("get_hand_color"):
		appearance.skin_color = manager.get_hand_color()
	origin.add_child(appearance)
