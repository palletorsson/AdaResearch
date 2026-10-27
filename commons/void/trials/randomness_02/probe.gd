extends "res://commons/void/trials/wavefunctions_05/probe.gd"
## Real input checks. Source room/ceiling conflicts are recorded, not hidden.
func expected_empty_source(_node: Node3D) -> bool:
	return false

func debug_cases() -> Dictionary:
	return {"ledger":1,"jars":1,"compartments":1,"ruin":1,"signal":1}

func run_debug_case(name: String, tag: String) -> void:
	match name:
		"ledger":await ledger_checks(tag)
		"jars":await jars_checks(tag)
		"compartments":await compartments_checks(tag)
		"ruin":await ruin_checks(tag)
		"signal":await signal_checks(tag)

func focused_checks(tag: String) -> void:
	check(tag+"standard 42 x 32 m floor",game.building.spec.width==42 and game.building.spec.depth==32)
	await fit_checks(tag)
	await ledger_checks(tag);await jars_checks(tag);await compartments_checks(tag)
	await ruin_checks(tag);await signal_checks(tag)
	var axiom:Node3D=artifact("entropy_axiom")
	check(tag+"source square uses 16 x 5 x 16 points",axiom.square_room and axiom.multimesh_instance.multimesh.instance_count==1280)
	check(tag+"source glass enclosure is installed",axiom.has_node("ExhibitStage/GlassSimulation"))
	game.place_player(game.spawn_for(level));await frames(15)

func ledger_checks(tag: String) -> void:
	var meter:Node3D=artifact("shannon_entropy_meter")
	var marker:Node3D=meter.get_node("ExhibitStage/ReachConsole/StandingPosition")
	game.place_player(marker.global_position+Vector3.UP*.06);await frames(20)
	var sequence:Array=meter.get_sequence();var h:float=meter.get_entropy()
	await press(meter._panel.find_child("Btn_0",true,false));await frames(40)
	check(tag+"SORT rearranges the copy without changing Shannon entropy",meter.sorted_view and meter.get_sequence()==sequence and is_equal_approx(meter.get_entropy(),h))
	await press(meter._panel.find_child("Btn_0",true,false))
	check(tag+"SORT returns to original order",not meter.sorted_view)

func jars_checks(tag: String) -> void:
	var states:Node3D=artifact("entropy_jar_states")
	await stand_local(states,Vector3(-4.2,.06,1.35))
	await press(states.buttons["PAUSE"])
	var elapsed:float=states.elapsed;await frames(20)
	check(tag+"PAUSE holds all four original starting arrangements",states.jars.size()==4 and states.paused and is_equal_approx(states.elapsed,elapsed))
	await press(states.buttons["RESTART"])
	check(tag+"RESTART restores the initial eight-second comparison",not states.paused and states.elapsed<1)
	var jar:Node3D=artifact("entropy_jar")
	await stand_local(jar,Vector3(0,.06,.85))
	var pickable:Node3D=jar._jar_body
	var held:bool=await input_grab(tag+"entropy jar / ",pickable,pickable.get_node("CollisionShape3D"),.45,.13)
	if held:
		check(tag+"jar receives native pickup state",jar._is_held)
		await drop_point()
	check(tag+"original jar retains 80 particles",jar._particles_a.size()==40 and jar._particles_b.size()==40)

func compartments_checks(tag: String) -> void:
	var c:Node3D=artifact("entropy_compartments")
	await stand_local(c,Vector3(0,.06,1.55))
	await press(c.buttons["ONE SWAP"])
	check(tag+"ONE SWAP records a seeded exchange even for equal colours",c.cursor==1 and c.history.size()==2)
	await press(c.buttons["RESET"])
	check(tag+"RESET restores separated baseline",c.cursor==0 and c.history.size()==1 and not c.running)

func ruin_checks(tag: String) -> void:
	var ruin:Node3D=artifact("entropy_ruin")
	check(tag+"source ruin has 116 physical stones",ruin.pieces.size()==116 and ruin.pieces[0].body is RigidBody3D)
	var marker:Node3D=ruin.get_node("ExhibitStage/ReachConsole/StandingPosition")
	game.place_player(marker.global_position+Vector3.UP*.06);await frames(20)
	await press(ruin.controls["ONE STONE"]);await frames(75)
	check(tag+"ONE STONE extracts a support and releases it to gravity",ruin.history.size()==1 and ruin.extracting<0)
	await press(ruin.controls["RESTORE"]);await frames(6)
	check(tag+"RESTORE returns original supports",ruin.history.is_empty() and not ruin.running)

func signal_checks(tag: String) -> void:
	var room:Node3D=artifact("signal_room")
	await stand_local(room,Vector3(0,.06,14.2))
	var target:Vector3=room.controls[2].global_position
	# Study controls are original StaticBody3D pointer_event receivers, not
	# push_button.tscn. A click at a fixed target uses the same native ray path.
	await pointer_drag(target,target)
	check(tag+"CELLS changes original room permutation",room.specimen.mode==2)
	var values:PackedByteArray=room.specimen.values.duplicate()
	await pointer_drag(room.controls[0].global_position,room.controls[0].global_position)
	check(tag+"ORDERED keeps the same population",room.specimen.mode==0 and room.specimen.values.size()==values.size())
	print("SIGNAL_ROOM ",tag," original 7.15 m enclosure intersects 5.64 m storey ceiling; curation deferred")

func capture_floor() -> void:
	var y:float=game.building.spec.levels[level]
	await photo("01-entropy-ledger-and-jars",Vector3(-10,y+2.2,12),Vector3(-15,y+1,6))
	await photo("02-physical-ruin",Vector3(-11,y+2.4,-4),Vector3(-15,y+1.5,-9))
	await photo("03-signal-room",Vector3(0,y+1.7,13),Vector3(0,y+2,-4))
	await photo("04-displacement-and-compartments",Vector3(8,y+2,2),Vector3(15,y+1.5,7))
