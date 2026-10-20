extends "res://doc/book/iterations/2026-10-16-entropy-columns/museum_probe.gd"
func landing_checks() -> void:
	var bank:=find_scene("/ordinary_entropies/jar_states.gd")
	check("mixing bank installed",bank!=null)
	if bank==null:return
	bank.set_process(false);bank.restart()
	await super.landing_checks()
	var start: Array=bank.jars[0].positions()
	bank.activated=false
	camera.global_position=bank.to_global(Vector3(0,1.6,8));bank._process(0.1)
	check("distant visitor does not start mixing",not bank.activated)
	camera.global_position=bank.to_global(Vector3(0,1.6,1.4));bank._process(0.1)
	check("approaching visitor starts the observation hold",bank.activated and bank.elapsed<bank.START_HOLD)
	bank.restart();bank.advance(bank.START_HOLD)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=2.7
	var earlier:=0.0
	for seconds in [0.0,15.0,45.0,90.0,180.0]:
		bank.advance(seconds-earlier);earlier=seconds;bank.update_reading()
		await snapshot("mixing-%03d" % seconds,bank.to_global(Vector3(0,1.35,1.4)),bank.to_global(Vector3(0,1.35,0)),70)
	var panel: Node3D=bank.get_node("ReadingPanel")
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	await snapshot("live-reading",panel.to_global(Vector3(0,1.45,1.6)),panel.to_global(Vector3(0,1.45,0)),64)
	var hand:=Node3D.new();root.add_child(hand)
	for action in ["PAUSE","PAUSE","RESTART"]:
		var was_paused: bool=bank.paused
		var button: Node3D=bank.buttons[action].get_node("InteractableAreaButton")
		var contact:=button.global_position
		XRToolsPointerEvent.pressed(hand,button,contact);await create_timer(0.1).timeout
		XRToolsPointerEvent.released(hand,button,contact);await create_timer(0.1).timeout
		if action=="RESTART":check("pointer restart restores baseline",bank.elapsed==0 and bank.jars[0].positions()==start and not bank.paused)
		else:check("pointer toggles pause and updates label",bank.paused!=was_paused and bank.pause_label.text==("RESUME" if bank.paused else "PAUSE"))
	check("pause and restart remain on the side panel",bank.buttons.PAUSE.get_parent()==panel and bank.buttons.RESTART.get_parent()==panel)
	observations.scope="Actual museum. Deterministically advanced snapshots at 0, 15, 45, 90 and 180 mixing seconds; not a claim of human perceptual equivalence. Same starting coordinates and no change to the shakeable jar. Supplied ray-pointer controls exercised; physical headset comfort remains open."
