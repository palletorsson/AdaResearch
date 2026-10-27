extends "res://commons/hazards/becoming_catalyst/catalyst_projectile.gd"
## Three ray pulses from the shared catalyst. World geometry always stops them.
const FX := preload("laser_fx.gd")
var pulses := 0
var _clock := 0.0
var _game: Node3D
var _excluded: Array[RID] = []

func _ready() -> void:
	freeze = true
	collision_layer = 0; collision_mask = 0
	_game = get_tree().get_first_node_in_group("void_game") as Node3D
	for body in get_tree().get_nodes_in_group("player_body"):
		if body is CollisionObject3D: _excluded.append(body.get_rid())
	if is_instance_valid(_game):
		for body in _game.get_node("XROrigin3D").find_children("*","PhysicsBody3D",true,false):
			_excluded.append(body.get_rid())
	_excluded.append(get_rid())
	color_primary = Color("9cf8ff")

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_game) or not _game.ready_for_play or _game.recovering or _game.returning:
		queue_free(); return
	_clock -= delta
	if _clock > 0: return
	if pulses >= 3:
		queue_free(); return
	pulses += 1; _clock = 0.09
	var space := get_world_3d().direct_space_state
	# Both VR and desktop hands must remain on the player's side of cover.
	var guard := PhysicsRayQueryParameters3D.create(_game.camera.global_position, global_position, 1)
	guard.exclude = _excluded
	var obstruction := space.intersect_ray(guard)
	if not obstruction.is_empty():
		if "--laser-debug" in OS.get_cmdline_user_args(): print("LASER_GUARD ",obstruction.collider.get_path())
		return
	var ray := PhysicsRayQueryParameters3D.create(global_position, global_position+direction*32.0, 1 | 2 | (1<<23))
	ray.exclude = _excluded
	var hit := space.intersect_ray(ray)
	if "--laser-debug" in OS.get_cmdline_user_args(): print("LASER_RAY ",hit.get("collider")," from=",global_position," dir=",direction)
	var end: Vector3 = ray.to if hit.is_empty() else hit.position
	FX.beam(_game, global_position, end, color_primary)
	FX.sound(_game,global_position,"shot")
	FX.sparks(_game, global_position)
	if not hit.is_empty():
		# Preserve catalyst receivers and their mode contract for existing artifacts.
		var start := global_position
		global_position = end
		_dispatch_transformation(hit.collider)
		global_position = start
		FX.sparks(_game, end)

func _infer_mode_id() -> String:
	return "primitives"
