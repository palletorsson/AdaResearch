extends "res://commons/artifacts/endless_racer/endless_racer.gd"
## Preserve the remote road, controls and return pose while its floor stays live.
var void_host: Node
var void_pitch := 0.0

func _ready() -> void:
	super._ready()
	void_host = get_tree().get_first_node_in_group("void_game")
	add_to_group("void_floor_extension")
	add_to_group("void_controlled_carry")

func board_nearest() -> void:
	if void_host != null: board(void_host.body)

func board(body: CharacterBody3D) -> bool:
	if is_instance_valid(rider): return false
	if not body is XRToolsPlayerBody: void_pitch = body.camera.rotation.x
	var boarded := super.board(body)
	if boarded and not body is XRToolsPlayerBody: body.camera.rotation = Vector3.ZERO
	return boarded

func leave() -> void:
	var body := rider
	super.leave()
	if is_instance_valid(body) and not body is XRToolsPlayerBody:
		body.camera.rotation.x = void_pitch

func contains_visitor(at: Vector3) -> bool:
	return is_instance_valid(arena) and is_instance_valid(rider) and arena.to_local(at).length() < 3.0
