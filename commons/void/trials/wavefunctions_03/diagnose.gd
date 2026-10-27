extends "res://commons/void/trials/wavefunctions_03/probe.gd"

func press(button: Node3D) -> void:
	var target:Vector3=button.get_node("InteractableAreaButton/CollisionShape3D").global_position
	game.camera.look_at(target);await frames(25)
	var query:=PhysicsRayQueryParameters3D.create(game.camera.global_position,target,1310720)
	query.collide_with_areas=true
	var hit:Dictionary=game.get_world_3d().direct_space_state.intersect_ray(query)
	print("FM_AIM ",button.get_path()," collider=",hit.get("collider")," at=",target," eye=",game.camera.global_position)
	await super.press(button)
	print("FM_STATE ",artifact("DualBallFMController").get_audition_state())

func button_event(area:Node) -> void:
	print("FM_ACTUAL_BUTTON ",area.get_path())

func run() -> void:
	trial="wavefunctions_03"
	await start(false)
	var fm:Node3D=artifact("DualBallFMController")
	for i in 4:fm._panel.find_child("Btn_"+str(i),true,false).get_node("InteractableAreaButton").button_pressed.connect(button_event)
	await sound_checks("diagnostic: ")
	game.queue_free();await frames(10);quit()
