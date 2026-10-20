extends "res://tools/probes/camera_pixels_room.gd"

func landing_checks() -> void:
	await super.landing_checks()
	var work:=find_scene("/camera_glitch_study/CameraGlitchStudy.gd")
	if work==null:return
	check("two live dials keep native unit scale",work.amount_dial.scale==Vector3.ONE and work.effect_dial.scale==Vector3.ONE)
	var selector=work.effect_dial.get_node("DialOrigin/InteractableHinge")
	var choices:Array[int]=[]
	for i in 10:
		selector.move_hinge(deg_to_rad(i*30));await tick()
		choices.append(work.mode)
	check("selector reaches exactly ten effects",choices==[0,1,2,3,4,5,6,7,8,9])
	work.act("NEXT")
	check("next wraps and synchronises selector",work.mode==0 and is_zero_approx(work.effect_dial.get_normalized_value()))
	var square:=true
	for id in work.buttons:
		var button=work.buttons[id]
		square=square and button.get_node("Button/ButtonMesh").mesh is BoxMesh and button.get_node("InteractableAreaButton/CollisionShape3D").shape is BoxShape3D
	check("all console buttons have rectangular caps and hit areas",square)
	var min_at:=Vector3(INF,INF,INF);var max_at:=-min_at
	for id in work.buttons:
		min_at=min_at.min(work.buttons[id].position);max_at=max_at.max(work.buttons[id].position)
	check("buttons remain grouped within one faceplate",max_at.x-min_at.x<.8 and max_at.y-min_at.y<.5)
	work.act("PIXELS / FORM")
	check("bank state has latched visual feedback",work.buttons["PIXELS / FORM"].is_selected()==work.pixel_mode)
	work.act("LIVE / HOLD")
	check("hold state has latched visual feedback",work.buttons["LIVE / HOLD"].is_selected()==work.paused)
	# Exercise the shared pointer path on the dial, then release ownership.
	var pointer:=Node3D.new();root.add_child(pointer)
	var dial:Node3D=work.amount_dial
	var from:=dial.to_global(Vector3.ZERO)
	var destination:=dial.to_global(Vector3(0,-.27,0))
	dial.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.PRESSED,pointer,dial,from,from))
	dial.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.MOVED,pointer,dial,destination,from))
	dial.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.RELEASED,pointer,dial,destination,destination))
	await tick()
	check("pointer dial drag changes strength",work.amount<.7)
	check("pointer release relinquishes the dial",not dial.get_node("ScalarPointer").is_processing())
	work.act("RESET")
	check("reset restores both displayed dial values",is_equal_approx(work.amount_dial.get_normalized_value(),.8) and is_zero_approx(work.effect_dial.get_normalized_value()))
	pointer.queue_free()
	work.pixel_mode=true;work.select(1);work.paused=true;work.bind_images()
	await snapshot("new-console",work.to_global(Vector3(.5,1.65,2.62)),work.panel.face.global_position,62)
	await snapshot("new-gallery",work.to_global(Vector3(-1.6,1.65,4.8)),work.to_global(Vector3(-.3,2,0)),74)
