extends RefCounted
## Desktop CharacterBody movement does not itself push a RigidBody.
## Only bodies implementing this opt-in contact hook receive a nudge.
static func after_move(walker: CharacterBody3D, incoming: Vector3, delta: float) -> void:
	var seen: Array=[]
	for i in walker.get_slide_collision_count():
		var hit:=walker.get_slide_collision(i)
		var body:=hit.get_collider()
		if body!=null and body.has_method("on_walk_push") and not body in seen:
			seen.append(body)
			body.on_walk_push(incoming,hit.get_normal(),delta)
