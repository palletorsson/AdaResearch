extends "res://doc/book/iterations/2026-10-17-wedge-mouse-path/render_probe.gd"

func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(1.0).timeout
	var alignment:=find_scene("/align_solid.gd")
	var model:=find_scene("/wedge_mouse_model.gd")
	check("maze loaded in Polythedra",model!=null and alignment!=null)
	if model==null or alignment==null:return
	var origin:=alignment.global_position-Vector3(7,0,4)
	check("maze plinth on raised platform",absf(model.global_position.y-origin.y-1)<0.02)
	check("maze has 23 upright movable walls",model.pieces.size()==23)
	check("upright joystick is the only control",model.joystick.global_basis.z.dot(Vector3.UP)>0.99 and model.find_children("InteractableAreaButton","",true,false).is_empty())
	var walker:CharacterBody3D=museum.get("_player")
	walker.global_position=origin+Vector3(9.5,1.02,31);walker.velocity=Vector3.ZERO
	await tick()
	check("standing approach behind joystick is accessible",await walk_to(walker,model.to_global(Vector3(-1.85,0,0))))
	for p in [Vector2(9.5,31),Vector2(16,31)]:
		check("platform crossing remains clear "+str(p),await walk_to(walker,origin+Vector3(p.x,1,p.y)))
	walker.global_position=alignment.global_position+Vector3(0,0,-2);walker.velocity=Vector3.ZERO
	await tick()
	await snapshot("mouse-maze",model.to_global(Vector3(-2.6,2.8,-1.5)),model.to_global(Vector3(0,0.9,0)),50)
	await snapshot("maze-above",model.to_global(Vector3(0,3.2,-0.01)),model.to_global(Vector3(0,0.9,0)),62)
	await snapshot("upright-stick",model.to_global(Vector3(-2.3,1.6,-0.65)),model.to_global(Vector3(-0.8,0.86,0)),55)

func finish() -> void:
	var result:={"checks":checks,"failures":failures,"passed":failures.is_empty(),"scope":"Native museum: maze, standing joystick, walking approach and platform crossing. Camera views verified; headset use remains untested."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("MAZE HALL ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
