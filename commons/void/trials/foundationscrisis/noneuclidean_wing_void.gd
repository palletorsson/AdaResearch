extends "res://commons/artifacts/noneuclidean_wing/noneuclidean_wing.gd"
## Void adapter for noneuclidean_wing (Seven Spaces).
##
## The wing builds its chambers and galleries 60 to 195 m above itself and up to
## about 200 m along its local x, and carries the visitor there through
## move_together() -> shift_player(). The original shift_player() moves only an
## Endless Museum player (an ancestor with _eye_pos/_vr/_vr_rig/_player); in the
## Void `museum` is null, so it returned and the visitor walked through an empty
## door frame while a room lit up 60 m overhead.
##
## Three functional changes, nothing else:
##  1. shift_player(): after the original (test_eye, museum), move the Void player
##     by the same translation: XRToolsPlayerBody.teleport() in VR, the walker body
##     on desktop. Then the game's rebase_player_motion(), so the 60 m return is a
##     cut, not a fatal "fell more than one floor" landing.
##  2. void_floor_extension + contains_visitor(): while the visitor is in a remote
##     space (more than REMOTE_Y above the wing) the wing's own floor stays live, so
##     floor residency does not sleep the wing beneath its passenger.
##  3. void_exterior_walk: every collider under the wing (chamber decks and floors)
##     counts as real support outside the tower footprint, so chambers beyond the
##     slab edge are not "fell beyond the building".
## Inside the Endless Museum (museum != null) behaviour is the original's.
const REMOTE_Y := 20.0

func prepare_editor_preview() -> void:
	# GLB cannot preserve Godot's stencil portal. Export the actual entry frame;
	# otherwise the masked remote room appears as a solid box on the Void floor.
	if is_instance_valid(entry_preview): entry_preview.hide()
	if is_instance_valid(entry_writer): entry_writer.hide()

func _ready() -> void:
	add_to_group("void_floor_extension")
	add_to_group("void_exterior_walk")
	super._ready()

## Remote chambers and galleries only; the entry frame on the floor is ordinary.
func contains_visitor(world_position: Vector3) -> bool:
	return to_local(world_position).y > REMOTE_Y

func shift_player(delta: Vector3) -> void:
	super.shift_player(delta)
	if museum != null: return
	var game := _void_game()
	if game == null: return
	var body: Node3D = game.get("body")
	if body == null: return
	if bool(game.get("vr")) and body.has_method("teleport"):
		var pose: Transform3D = body.global_transform
		pose.origin += delta
		body.teleport(pose)
	else:
		body.global_position += delta
	if game.has_method("rebase_player_motion"): game.rebase_player_motion()

func _void_game() -> Node:
	var n: Node = get_parent()
	while n != null:
		if n.is_in_group("void_game"): return n
		n = n.get_parent()
	return get_tree().get_first_node_in_group("void_game")
