extends "res://tools/probes/transformation_encounters.gd"
const Journey=preload("res://tools/probes/array_entered_address.gd")
var wall:Node3D
var study:Node3D
var actor:CharacterBody3D
var driver:Journey.KeyJourney
var completed:=false

func press(area:Node3D) -> void:
	XRToolsPointerEvent.pressed(camera,area,area.global_position)
	XRToolsPointerEvent.released(camera,area,area.global_position)
	await create_timer(0.15).timeout
func photo(title:String) -> void:
	await snapshot(title,wall.to_global(Vector3(-4.4,2.45,2.7)),wall.to_global(Vector3(0.3,2.3,0.5)),67)
func travel(point:Vector3,seconds:float=7.0) -> bool:
	driver.target=wall.to_global(point);driver.arrived=false;driver.moving=true
	var start:=Time.get_ticks_msec()
	while not driver.arrived and Time.get_ticks_msec()-start<seconds*1000.0:await physics_frame
	driver.moving=false;driver.release()
	return driver.arrived
func landing_checks() -> void:
	wall=find_scene("/wall_exception.gd");study=find_scene("/tiling_principles.gd")
	check("both existing studies are placed",wall!=null and study!=null)
	if wall==null or study==null:return
	check("six wall fields and shared pattern",study.walls and study.surfaces.size()==6 and wall.study==study)
	actor=museum.get("_player");actor.global_position=wall.to_global(Vector3(-2.1,0.05,1));actor.velocity=Vector3.ZERO
	museum.set("_dollhouse",false)
	driver=Journey.KeyJourney.new();driver.world=museum;driver.actor=actor;driver.view=museum.get("_cam");root.add_child(driver)
	await create_timer(0.3).timeout
	await snapshot("wall-fields",study.to_global(Vector3(0,1.65,-9)),study.to_global(Vector3(0,2.5,4)),72)
	await photo("closed-pattern")
	var original:PackedByteArray=wall.face.material_override.albedo_texture.get_image().get_data()
	var initial:Transform3D=wall.hinge.global_transform
	var buttons:=study.find_children("InteractableAreaButton","Area3D",true,false)
	check("existing pattern controls found",buttons.size()==2)
	if buttons.size()!=2:return
	await press(buttons[1])
	check("EXCEPTION updates the actual enclosure image",study.exception and wall.face.material_override.albedo_texture==study.surfaces[5].material_override.albedo_texture and wall.face.material_override.albedo_texture.get_image().get_data()!=original)
	check("image change leaves the boundary fixed",wall.hinge.global_transform.is_equal_approx(initial) and not wall.open)
	await photo("changed-pattern")
	var reached:bool=await travel(Vector3(3.3,0.05,1),2.2)
	var stopped:Vector3=wall.to_local(actor.global_position)
	check("changed image still stops ordinary walking",not reached and stopped.x > -0.6 and stopped.x < -0.2)
	observations["closed_walk_end"]=xyz(stopped)
	check("visitor retreats clear of the hinge",await travel(Vector3(-2.1,0.05,1)))
	await create_timer(0.2).timeout
	var print_texture:Texture2D=wall.face.material_override.albedo_texture
	await press(wall.turn_button.get_node("InteractableAreaButton"))
	await create_timer(0.65).timeout
	check("wall turns gradually with its collision body",wall.moving and wall.angle>0.1 and wall.angle<PI/2 and absf(wall.hinge.rotation.y-wall.angle)<0.03)
	await create_timer(2.1).timeout
	check("wall completes a quarter turn",wall.open and not wall.moving and is_equal_approx(wall.angle,PI/2))
	check("turning the surface preserves the image",wall.face.material_override.albedo_texture==print_texture)
	await photo("opened-wall")
	check("ordinary walking reaches the exterior landing",await travel(Vector3(3.3,0.05,1)))
	observations["landing_walk_end"]=xyz(wall.to_local(actor.global_position))
	var landing_hit:=floor_at(actor.global_position)
	check("landing supports the visitor at hall floor height",not landing_hit.is_empty() and absf(landing_hit.position.y-wall.global_position.y)<0.02)
	await snapshot("outside-return",actor.global_position+Vector3.UP*1.65,wall.to_global(Vector3(-0.5,1.7,0.2)),75)
	await snapshot("plain-reverse",wall.to_global(Vector3(3.4,1.65,-1.1)),wall.to_global(Vector3(0.85,2,-0.5)),75)
	var past:=floor_at(wall.to_global(Vector3(5,0,0.5)))
	check("the outside landing has a finite floor",past.is_empty())
	await press(wall.turn_button.get_node("InteractableAreaButton"))
	check("occupied landing prevents closure",wall.open and not wall.moving and wall.caption.text.contains("RETURN INSIDE"))
	check("ordinary walking returns inside",await travel(Vector3(-2.1,0.05,1)))
	await create_timer(0.2).timeout
	await press(wall.turn_button.get_node("InteractableAreaButton"))
	await create_timer(2.7).timeout
	check("wall closes after the visitor returns",not wall.open and not wall.moving and is_zero_approx(wall.angle))
	await press(buttons[1])
	check("image returns to its original pixels",wall.face.material_override.albedo_texture.get_image().get_data()==original)
	observations["wall_world"]=xyz(wall.global_position)
	for path in ["commons/artifacts/regularity/wall_exception.gd","commons/artifacts/regularity/tiling_principles.gd","commons/artifacts/regularity/room_tools.gd","tools/probes/array_entered_address.gd"]:
		observations[path]=FileAccess.get_sha256("res://"+path)
	completed=true
func finish() -> void:
	if driver!=null:driver.release();driver.set_physics_process(false)
	check("encounter completed",completed)
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Isolated production museum; supplied pointer events and key input through the ordinary museum controller. Selected walking approaches, return route and camera positions; no headset or learner claim. The remotely supplied control events test callbacks, not physical reach."},"  "))
	print("WALL AND OUTSIDE ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
