extends "res://tools/probes/ca_spine_active.gd"
## Targeted dependency check: the original offer must activate its original vent.
func proximity_checks(tag: String) -> void:
	var box: Node3D = artifact("catalyst_prompter_box")
	var vent: Node3D = artifact("catalyst_vent")
	check(tag+"vent waits for the actual catalyst pickup",vent._emitted==0 and vent.require_catalyst_armed)
	var at: Vector3 = box.global_position+Vector3(0,0,1.05);at.y = game.building.spec.levels[level]+.06
	game.place_player(at);await frames(75)
	check(tag+"real proximity opens hatch and raises its original crystal",box._lid_open and box._crystal.visible and box._crystal_base_y>.5)
	var crystal: Node3D = box._crystal
	var collider: CollisionShape3D = crystal.find_child("CollisionShape3D",true,false)
	var grabbed := await input_grab(tag+"catalyst: ",crystal,collider,.5,.10)
	if grabbed:
		await frames(40)
		if xr:right.set_input("grip",0.0);await frames(12)
		check(tag+"crystal is absorbed through the normal pickup callback",crystal._absorbed and box._leased_out)
		for i in 500:
			if vent._emitted>0:break
			await frames(1)
		var expected: String = preload("res://commons/hazards/catalyst_sequence_binding.gd").foe_kind_for_sequence("cellularautomata")
		check(tag+"armed catalyst starts the original cellular vent",vent._emitted>0 and vent.default_foe_mode==expected)
		var local_spawn := false
		for node in vent.get_parent().get_children():
			if node!=vent and node.get_script()!=null and node.get_script().resource_path.ends_with("catalyst_foe.gd"):
				local_spawn = local_spawn or absf(node.global_position.y-game.building.spec.levels[level])<5
		check(tag+"emitted body inhabits the negative floor rather than world zero",local_spawn)
