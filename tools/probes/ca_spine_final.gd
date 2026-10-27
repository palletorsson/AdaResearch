extends "res://tools/probes/ca_spine_catalyst.gd"
func press(key: Node3D) -> void:
	await super.press(key)
	if xr:
		var pointer: Node3D = game.pointers[1];var suppress: Area3D = pointer.get_node("SuppressArea");var raycast: RayCast3D = pointer.get_node("RayCast")
		print("CA_POINTER ",key.get_path()," enabled=",pointer.enabled," target=",pointer.last_target," ray=",raycast.get_collider()," suppressed_bodies=",suppress.get_overlapping_bodies().map(func(n):return str(n.get_path()))," suppressed_areas=",suppress.get_overlapping_areas().map(func(n):return str(n.get_path())))
func neighbour_checks(tag: String) -> void:
	if xr:
		var b: Node = game.get_node("XROrigin3D/RightHand").get_node_or_null("CapacityBracelet")
		if b!=null:
			var handle: Node3D = b.find_child("InteractableHandle",true,false)
			check(tag+"wrist handle excludes its wearer before grab selection",not handle.can_pick_up(game.pickups[1]))
			check(tag+"opposite hand can still operate the bracelet",handle.can_pick_up(game.pickups[0]))
	await super.neighbour_checks(tag)
	var work: Node3D = artifact("ca_rule_explorer")
	var wall: Node3D = artifact("void_ca_history_wall")
	await frames(12)
	var actual: Array = work._grid.duplicate(true);actual.reverse()
	check(tag+"architectural wall reads the original desk history exactly",wall.source==work and wall.rendered==actual and wall.cells.instance_count==768)
	var before: int = work.generation
	await control_press(work,work.get_node("NeighbourStudy/StudyControls"),0);await frames(12)
	actual = work._grid.duplicate(true);actual.reverse()
	check(tag+"real desk STEP changes the monumental receiver and floor together",work.generation==before+1 and wall.rendered==actual and work.get_node("NeighbourStudy").floor_history.rendered==actual)
