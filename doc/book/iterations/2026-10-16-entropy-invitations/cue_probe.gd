extends "res://doc/book/iterations/2026-10-16-entropy-button-reach/control_probe.gd"
## Check the invitation and selected/pressed feedback in the actual room.

func types_controls() -> void:
	var doors=find_scene("/ordinary_entropies/door_study.gd")
	var guesses=find_scene("/ordinary_entropies/one_guess.gd")
	check("door and guess studies installed",doors!=null and guesses!=null)
	if doors==null or guesses==null:return
	await snapshot("doors-invitation",doors.to_global(Vector3(2.25,1.65,2.5)),doors.to_global(Vector3(2.25,1.48,0.22)),64)
	await exercise(doors.buttons["STEP"],doors,"door STEP")
	check("primary cue does not mark STEP as selected",not doors.buttons["STEP"].is_selected())
	var table=guesses.versions[1]
	await snapshot("guess-invitation",table.to_global(Vector3(0,1.65,2.35)),table.to_global(Vector3(0,0.95,0.5)),78)
	await exercise(table.buttons["PINK"],table,"pink choice")
	await exercise(table.buttons["DRAW"],table,"draw")
	check("choice remains selected after hand and ray release",table.buttons["PINK"].is_selected() and not table.buttons["DRAW"].is_selected() and table.model.guess==0)
	await snapshot("guess-result",table.to_global(Vector3(0,1.65,2.35)),table.to_global(Vector3(0,0.95,0.5)),78)

func cabinet_controls() -> void:
	var cabinet=find_scene("/entropy_compartments/entropy_compartments.gd")
	check("cabinet installed",cabinet!=null)
	if cabinet==null:return
	await snapshot("cabinet-invitation",cabinet.to_global(Vector3(0,1.65,2.2)),cabinet.to_global(Vector3(0,1.1,0.1)),65)
	await exercise(cabinet.buttons["A LEFT -"],cabinet,"exchange",cabinet.global_basis.y)
	await snapshot("cabinet-result",cabinet.to_global(Vector3(0,1.65,2.2)),cabinet.to_global(Vector3(0,1.1,0.1)),65)
