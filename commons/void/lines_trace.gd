extends "res://commons/primitives/point/player_trace.gd"
## Same recorder; restrict its input to this floor, with no teleport segment.
var game: Node3D
var active_last_frame := false
var preferred_recorder := false
var preserve_museum_style := false
func _notification(what: int) -> void:
	# Streaming can suspend this floor before its next _process callback.
	if what == NOTIFICATION_DISABLED and is_node_ready():
		clear_trail()
		active_last_frame = false
func _ready() -> void:
	add_to_group("void_lines_recorders")
	if not preserve_museum_style:
		show_reference_frame = false
		show_endpoints = false
		velocity_color = false
		trail_color = Color("c34482")
		min_segment_distance = 0.08
	super()
func _find_xr_origin() -> Node3D:
	game = get_tree().get_first_node_in_group("void_game")
	return game.body if game != null and is_instance_valid(game.body) else null
func _origin_is_live(o: Node) -> bool:
	return is_instance_valid(o) and game != null and o == game.body
func _tracked_position() -> Vector3:
	var p: Vector3 = game.body.global_position
	if game.vr:
		p.x = game.camera.global_position.x
		p.z = game.camera.global_position.z
	p.y = global_position.y
	return p
func _process(delta: float) -> void:
	if game == null or not is_instance_valid(game.body):
		_find_xr_origin()
		return
	var active: bool = game.ready_for_play and not game.recovering and absf(game.body.global_position.y-global_position.y)<0.3
	if active:
		for other in get_tree().get_nodes_in_group("void_lines_recorders"):
			if other == self or not other.can_process() or absf(other.global_position.y-global_position.y)>.3: continue
			if (other.preferred_recorder and not preferred_recorder) or (other.preferred_recorder == preferred_recorder and other.get_instance_id()<get_instance_id()):
				active = false
				break
	if not active and active_last_frame:
		clear_trail()
	if active:
		_xr_origin = game.body
		if not active_last_frame: clear_trail()
		super(delta)
	active_last_frame = active
