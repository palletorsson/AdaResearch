extends SceneTree
var study:Node3D
var checks:Array=[]
var observations:Dictionary={}
func _initialize() -> void: run.call_deferred()
func check(title:String,ok:bool)->void:
	checks.append({"name":title,"passed":ok});print("MODEL ","PASS " if ok else "FAIL ",title)
func drive_to(target:Vector2,budget:int=400)->bool:
	for i in budget:
		var offset:=target-Vector2(study.mouse.position.x,study.mouse.position.z)
		if offset.length()<0.025:
			study.joystick.set_angles_degrees(Vector2.ZERO);return true
		var input:=offset.normalized()*minf(1.0,offset.length()*20)
		study.joystick.set_angles_degrees(Vector2(-input.x,-input.y)*45)
		await physics_frame
	study.joystick.set_angles_degrees(Vector2.ZERO);return false
func approach()->bool:
	for p in [Vector2(-1.03,-0.32),Vector2(-0.43,-0.32),Vector2(-0.43,0),Vector2(0.15,0),Vector2(0.50,0)]:
		if not await drive_to(p):return false
	return true
func jump_and_wait()->void:
	study.joystick.set_angles_degrees(Vector2(-45,0))
	var area:Node=study.jump_button.get_node("InteractableAreaButton")
	area.button_pressed.emit(area)
	study.joystick.set_angles_degrees(Vector2.ZERO)
	for i in 100:
		await physics_frame
		if not study.airborne:break
	observations[str(observations.size())]={"outcome":study.outcome,"position":str(study.mouse.position),"highest":study.highest,"cheese":str(study.cheese.position)}
func run()->void:
	create_timer(85).timeout.connect(func():quit(124))
	study=load("res://commons/artifacts/primitive_encounters/wedge_mouse_model.tscn").instantiate();root.add_child(study)
	await create_timer(0.4).timeout
	check("seven movable wedges share one vertex set",study.pieces.size()==7)
	var points:PackedVector3Array=study.pieces[0].get_node("CollisionShape3D").shape.points
	for p in study.pieces:check(p.name+" retains unit collider",p.get_node("CollisionShape3D").shape.points==points)
	var start:Vector3=study.mouse.position
	await create_timer(0.25).timeout
	check("mouse waits without player input",Vector2(study.mouse.position.x-start.x,study.mouse.position.z-start.z).length()<0.001)
	check("straight steering meets a standing stopper",not await drive_to(Vector2(-0.43,-0.03),100) and study.mouse.position.x< -0.7)
	study.reset_mouse();await physics_frame
	check("player can steer around blockers and up ramp",await approach())
	check("physical ascent reaches the platform",study.mouse.position.y-study.TOP>0.22)
	await jump_and_wait()
	check("jump button makes a ballistic flight",study.jumped and study.highest>0.32)
	check("player lands by the cheese on raised support",study.outcome=="arrived" and study.mouse.position.y-study.TOP>0.20)
	study.reset_layout();study.pieces[2].position.z=0.38;await physics_frame
	check("moving the ramp removes this ascent",not await approach())
	check("mouse remains below platform without ramp",study.mouse.position.y-study.TOP<0.10)
	study.reset_layout();study.pieces[5].position.z=0.38;study.pieces[6].position.z=0.38;await physics_frame
	check("departure platform survives moving far support",await approach())
	await jump_and_wait()
	check("removing far support makes the landing lower",study.mouse.position.y-study.TOP<0.18)
	study.reset_layout()
	study.pieces[0].position.z-=0.1;var changed:Transform3D=study.pieces[0].transform
	study.home_button.get_node("InteractableAreaButton").button_pressed.emit(study.home_button.get_node("InteractableAreaButton"))
	check("HOME preserves the edited construction",study.pieces[0].transform.is_equal_approx(changed))
	study.reset_button.get_node("InteractableAreaButton").button_pressed.emit(study.reset_button.get_node("InteractableAreaButton"))
	var restored:=true
	for i in study.pieces.size():restored=restored and study.pieces[i].transform.is_equal_approx(study.homes[i])
	check("RESTORE returns every construction wedge",restored)
	study.joystick.set_angles_degrees(Vector2(-45,0));study.pieces[0].on_desktop_grab(study)
	check("holding a wedge centres steering",study.piece_held() and study.joystick.get_angles_degrees().length()<0.01)
	study.pieces[0].on_desktop_drop(study)
	study.joystick.set_angles_degrees(Vector2(20,15))
	study.joystick.get_node("JoystickOrigin/InteractableJoystick").released.emit(study.joystick.get_node("JoystickOrigin/InteractableJoystick"))
	check("release centres the joystick",study.joystick.get_angles_degrees().length()<0.01)
	var pointer:=Node3D.new();root.add_child(pointer)
	var press:Vector3=study.joystick.to_global(Vector3(0,0,0.04))
	var moved:Vector3=study.joystick.to_global(Vector3(0.03,0.03,0.04))
	study.joystick.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.PRESSED,pointer,study.joystick,press,press))
	study.joystick.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.MOVED,pointer,study.joystick,moved,press))
	check("pointer right and up steer right and away on model",study.steering().x<0 and study.steering().z>0)
	study.joystick.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.RELEASED,pointer,study.joystick,moved,moved))
	check("pointer release stops steering",study.steering().length()<0.01)
	pointer.queue_free()
	var failed:=checks.filter(func(c):return not c.passed)
	FileAccess.open("res://doc/book/iterations/2026-10-17-wedge-sculpture-model/model-report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"observations":observations,"passed":failed.is_empty(),"scope":"Supplied joystick directions and production button signals; real contact and gravity. Not a headset usability test."},"  "))
	print("MODEL RESULT ",checks.size()-failed.size(),"/",checks.size());quit(0 if failed.is_empty() else 1)

