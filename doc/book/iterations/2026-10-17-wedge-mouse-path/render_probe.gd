extends "res://doc/book/iterations/2026-10-17-wedge-sculpture-model/probe.gd"

func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(1.0).timeout
	var alignment:=find_scene("/align_solid.gd")
	var model:=find_scene("/wedge_mouse_model.gd")
	check("model loaded for native capture",model!=null and alignment!=null)
	if model==null or alignment==null:return
	var walker:CharacterBody3D=museum.get("_player")
	walker.global_position=alignment.global_position+Vector3(0,0,-2);walker.velocity=Vector3.ZERO
	await tick()
	check("camera view clear of player body",walker.global_position.distance_to(model.global_position)>10)
	check("approach strip remains non-colliding",model.get_node("ApproachPath").find_children("*","CollisionObject3D",true,false).is_empty())
	await snapshot("mouse-model",model.to_global(Vector3(-2.8,2.3,-1.6)),model.to_global(Vector3(0,0.9,0)),50)
	await snapshot("mouse-path-above",model.to_global(Vector3(0,3.8,-0.01)),model.to_global(Vector3(0,0.9,0)),52)
	await snapshot("model-controls",model.to_global(Vector3(-2.9,1.5,-0.12)),model.to_global(Vector3(-0.9,0.72,0)),50)

func finish() -> void:
	var result:={"checks":checks,"failures":failures,"passed":failures.is_empty(),"scope":"Native captures after moving the test walker away. No repetition of completed route or miniature physics trials."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	quit(0 if failures.is_empty() else 1)
