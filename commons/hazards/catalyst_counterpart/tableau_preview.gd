extends RefCounted
## Test-only substitution. The authored Dürer tableau remains recoverable.
static func mount(tableau: Node3D) -> Node3D:
	var figure := tableau.get_node_or_null("Melencolia") as Node3D
	if figure == null:
		push_error("The preview needs the existing engraved tableau's seated figure")
		return null
	figure.hide()
	# Hiding the model must not leave the old seated body's invisible collider.
	for body in figure.find_children("*", "CollisionObject3D", true, false):
		body.collision_layer = 0; body.collision_mask = 0
	var skull := load("res://commons/hazards/catalyst_counterpart/flying_skull.gd").new() as CharacterBody3D
	skull.position = figure.position + Vector3(-0.19, 2.35, 0.15)
	tableau.add_child(skull)
	skull.rotation.y = PI # The tableau's front is +Z.
	skull.scale = Vector3.ONE * 1.65
	skull.collision_layer = 0; skull.collision_mask = 0
	skull.set_physics_process(false)
	skull.active = false
	return skull
