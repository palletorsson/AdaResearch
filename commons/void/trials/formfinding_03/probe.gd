extends "res://commons/void/trials/formfinding_02/probe.gd"

func focused_checks(tag: String) -> void:
	check(tag+"standard floor",game.building.spec.width==42 and game.building.spec.depth==32 and game.building.spec.storey_height==6)
	var forge:Node3D=artifact("self_shaping_forge")
	var t:float=forge._t;await frames(30)
	check(tag+"forge retains 180 programmed target particles and animation",forge._mm.instance_count==180 and forge._targets.size()==180 and forge._t>t)
	var descent:Node3D=artifact("gradient_descent_optimizer")
	var old:float=descent._t;await frames(25)
	check(tag+"optimizer advances with finite objective",descent._t>old and is_finite(descent._energy(descent._p.x,descent._p.y)))
	check(tag+"optimizer distinguishes boundary from slope",descent._readout.text.contains("GRADIENT DESCENT"))
	var puzzle:Node3D=artifact("balance_puzzle")
	check(tag+"original twelve movable pieces and success thresholds",puzzle._pieces.size()==12 and is_equal_approx(puzzle.height_threshold,.6) and is_equal_approx(puzzle.stability_time,1.5))
	var p:Node3D=puzzle._pieces[0]
	await stand_local(puzzle,Vector3(.3,.06,1))
	await grab_point(tag,p);await drop_point()
	check(tag+"balance piece releases into original physics",not p.is_picked_up() and not p.freeze)
	game.place_player(game.spawn_for(level));await frames(15)

func capture_floor() -> void:
	var y:float=game.building.spec.levels[level]
	await photo("01-forge-and-balance",Vector3(1,y+2.7,11),Vector3(-1,y+.8,5))
	await photo("02-gradient-study",Vector3(-1,y+1.9,3.5),Vector3(-4,y+.7,1))
