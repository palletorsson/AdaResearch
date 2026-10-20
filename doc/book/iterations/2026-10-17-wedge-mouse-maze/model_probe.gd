extends SceneTree
var study:Node3D
var checks:Array=[]
func _initialize() -> void:run.call_deferred()
func check(title:String,ok:bool)->void:
	checks.append({"name":title,"passed":ok});print("MAZE ","PASS " if ok else "FAIL ",title)
func drive_to(target:Vector2,budget:int=250)->bool:
	for i in budget:
		var offset:=target-Vector2(study.mouse.position.x,study.mouse.position.z)
		if offset.length()<0.018:
			study.joystick.set_angles_degrees(Vector2.ZERO);return true
		var input:=offset.normalized()*minf(1.0,offset.length()*25)
		study.joystick.set_angles_degrees(Vector2(input.y,-input.x)*45)
		await physics_frame
	study.joystick.set_angles_degrees(Vector2.ZERO);return false
func visit(cell:Vector2i)->bool:
	var p:Vector3=study.cell_position(cell)
	return await drive_to(Vector2(p.x,p.z))
func run()->void:
	create_timer(80).timeout.connect(func():quit(124))
	study=load("res://commons/artifacts/primitive_encounters/wedge_mouse_model.tscn").instantiate();root.add_child(study)
	await create_timer(0.4).timeout
	check("23 separate grabbable wedge walls",study.pieces.size()==23)
	var feet_ok:=true
	for p in study.pieces:
		var bottom:=0;var top:=0
		for vertex in p.get_node("CollisionShape3D").shape.points:
			var height:float=(p.transform*vertex).y
			if absf(height-study.TOP)<0.001:bottom+=1
			if absf(height-study.TOP-study.WALL_HEIGHT)<0.001:top+=1
		feet_ok=feet_ok and bottom==4 and top==2
	check("every wedge has broad base on floor and ridge above",feet_ok)
	check("one primitive mesh for mouse and cheese",study.mouse.find_children("*","MeshInstance3D",true,false).size()==1 and study.cheese.find_children("*","MeshInstance3D",true,false).size()==1)
	var cheese_points:PackedVector3Array=study.cheese.get_node("CollisionShape3D").shape.points
	check("cheese ridge is centred",cheese_points[2].x==0 and cheese_points[5].x==0 and is_equal_approx(cheese_points[0].x,-cheese_points[1].x))
	check("symmetric cheese stays at far end",Vector2(study.cheese.position.x,study.cheese.position.z).distance_to(Vector2(0.82,0))<0.01)
	check("joystick stands vertically on top behind mouse",study.joystick.basis.z.is_equal_approx(Vector3.UP) and study.joystick.position.x<study.START.x and study.joystick.position.y>study.TOP)
	check("no buttons or large control panel",study.find_children("InteractableAreaButton","",true,false).is_empty() and not study.has_node("Controls"))
	var start:Vector3=study.mouse.position
	await create_timer(0.2).timeout
	check("mouse waits without input",study.mouse.position.distance_to(start)<0.005)
	check("entrance can be entered",await visit(Vector2i(0,1)))
	check("initial upright wedge blocks direct advance",not await visit(Vector2i(1,1)) and study.mouse.position.x< -0.48)
	check("first branch can be explored",await visit(Vector2i(0,2)))
	check("branch ends in a physical wall",not await drive_to(Vector2(-0.26,0.30),100))
	check("mouse can backtrack",await visit(Vector2i(0,1)))
	for cell in [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(3,0),Vector2i(4,0)]:
		check("floor route reaches "+str(cell),await visit(cell))
	check("joystick alone reaches cheese",await drive_to(Vector2(0.82,-0.15)) and study.outcome=="arrived")
	check("route needs no jump",absf(study.mouse.position.y-study.TOP)<0.03)
	study.reset_mouse();await physics_frame
	check("return to initial fork",await visit(Vector2i(0,1)))
	var wall:Node3D=study.get_node("WallX_1_1");wall.position.y+=0.5
	await physics_frame
	check("moving one wedge opens formerly blocked passage",await visit(Vector2i(1,1)))
	study.joystick.set_angles_degrees(Vector2(0,-45));wall.on_desktop_grab(study)
	check("holding a wall centres joystick",study.joystick.get_angles_degrees().length()<0.01)
	start=study.mouse.position;study.joystick.set_angles_degrees(Vector2(0,-45))
	await create_timer(0.2).timeout
	check("steering pauses while rearranging",Vector2(study.mouse.position.x-start.x,study.mouse.position.z-start.z).length()<0.005)
	wall.on_desktop_drop(study);study.joystick.set_angles_degrees(Vector2.ZERO)
	var edited:Transform3D=wall.transform
	study.mouse.position=Vector3(-1.6,study.TOP-0.2,0)
	await create_timer(0.9).timeout
	check("fallen mouse returns without another control",Vector2(study.mouse.position.x-study.START.x,study.mouse.position.z-study.START.z).length()<0.01)
	check("automatic return preserves edited walls",wall.transform.is_equal_approx(edited))
	var pointer:=Node3D.new();root.add_child(pointer)
	var press:Vector3=study.joystick.to_global(Vector3(0,0,0.04))
	var moved:Vector3=study.joystick.to_global(Vector3(0.03,0.03,0.04))
	study.joystick.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.PRESSED,pointer,study.joystick,press,press))
	study.joystick.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.MOVED,pointer,study.joystick,moved,press))
	check("pointer forward and right match tabletop axes",study.steering().x>0 and study.steering().z>0)
	study.joystick.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.RELEASED,pointer,study.joystick,moved,moved))
	check("pointer release centres stick",study.steering().length()<0.01)
	var joint:Node3D=study.joystick.get_node("JoystickOrigin/InteractableJoystick")
	var hand:=Node3D.new();root.add_child(hand);hand.global_position=study.joystick.to_global(Vector3(0.03,0.03,0.1))
	joint.grabbed_handles.append(hand);joint._process(0.016)
	check("grip direction matches upright joystick",study.steering().x>0 and study.steering().z>0)
	joint.grabbed_handles.clear();joint.released.emit(joint)
	check("grip release centres stick",study.steering().length()<0.01)
	hand.queue_free();pointer.queue_free()
	var failed:=checks.filter(func(c):return not c.passed)
	FileAccess.open("res://doc/book/iterations/2026-10-17-wedge-mouse-maze/model-report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":failed.is_empty(),"scope":"Supplied pointer, grip and steering inputs; actual contact, dead-end/backtrack, full route and moved-wall trials. No wearer usability claim."},"  "))
	print("MAZE RESULT ",checks.size()-failed.size(),"/",checks.size());quit(0 if failed.is_empty() else 1)
