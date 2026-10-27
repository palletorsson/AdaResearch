extends "res://commons/interfaces/nail_color_controller.gd"
## Resolve the current Void rig rather than a museum-relative node path.
## The source mapper, materials, signals and saved colours remain unchanged.

func _find_hand_nodes() -> void:
	var game: Node = get_tree().get_first_node_in_group("void_game")
	if game == null:
		super._find_hand_nodes()
		return
	# Desktop uses the same RGB controls and display hands without tracked hands.
	if not game.vr:
		return
	var origin: Node = game.get_node("XROrigin3D")
	left_hand = origin.get_node_or_null("LeftHand/XRToolsCollisionHand/LeftHand")
	right_hand = origin.get_node_or_null("RightHand/XRToolsCollisionHand/RightHand")
