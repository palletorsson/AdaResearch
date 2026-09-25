extends "res://tools/probes/transformation_encounters.gd"
const Journey=preload("res://tools/probes/array_entered_address.gd")
var study:Node3D
var actor:CharacterBody3D
var driver:Journey.KeyJourney
var completed:=false

func pixel_data(index:int) -> PackedByteArray:
	return study.surfaces[index].material_override.albedo_texture.get_image().get_data()
func export_image(index:int,title:String) -> void:
	var result:int=study.surfaces[index].material_override.albedo_texture.get_image().save_png(folder+title+".png")
	check("saved artifact texture: "+title,result==OK)
func press(index:int) -> void:
	var buttons:=study.find_children("InteractableAreaButton","Area3D",true,false)
	check("two live control buttons",buttons.size()==2)
	if buttons.size()!=2:return
	var area:Node3D=buttons[index]
	XRToolsPointerEvent.pressed(camera,area,area.global_position)
	XRToolsPointerEvent.released(camera,area,area.global_position)
	await create_timer(0.15).timeout
func photo(title:String,eye:Vector3,aim:Vector3,fov:=58.0) -> void:
	await snapshot(title,study.to_global(eye),study.to_global(aim),fov)
func walk(point:Vector3,title:String) -> bool:
	driver.target=study.to_global(point);driver.arrived=false;driver.moving=true
	var start:=Time.get_ticks_msec();var low:=INF;var high:=-INF
	while not driver.arrived and Time.get_ticks_msec()-start<10000:
		await physics_frame
		var h:float=study.to_local(actor.global_position).y;low=minf(low,h);high=maxf(high,h)
	driver.moving=false;driver.release()
	check(title,driver.arrived and low > -0.08 and high < 0.25)
	observations[title]={"arrived":driver.arrived,"feet":xyz(study.to_local(actor.global_position)),"minimum_y":low,"maximum_y":high}
	return driver.arrived

func landing_checks() -> void:
	study=find_scene("/tiling_principles.gd")
	check("floor study exists",study!=null)
	if study==null:return
	check("six fields are in floor mode",not study.walls and study.surfaces.size()==6)
	actor=museum.get("_player");actor.global_position=study.to_global(Vector3(0,0.05,-12));actor.velocity=Vector3.ZERO
	museum.set("_dollhouse",false)
	await create_timer(0.3).timeout
	var baseline:Array=[];var transforms:Array=[]
	for surface in study.surfaces:
		baseline.append(surface.material_override.albedo_texture.get_image().get_data())
		transforms.append(surface.global_transform)
	check("exception begins as the translation field",baseline[0]==baseline[5] and not study.exception and study.phase==0)
	check("each image is a five-metre field above the floor",study.surfaces.all(func(s):return s.mesh.size==Vector2(5,5) and absf(s.position.y-0.025)<0.001))
	check("pattern planes carry no collision shapes",study.surfaces.all(func(s):return s.find_children("*","CollisionShape3D",true,false).is_empty()))
	await photo("six-fields",Vector3(0,14,-14),Vector3(0,0.1,0),64)
	await photo("floor-eye",Vector3(0,1.65,-8.6),Vector3(-3.2,0.025,-5.5),68)
	await photo("console",Vector3(0,1.65,-11.65),Vector3(0,1.5,-10.1),53)
	for index in 6:export_image(index,"rule-"+str(index)+"-ordered")
	await press(0)
	check("TURN MOTIF changes the shared phase",study.phase==1)
	var all_changed:=true
	for index in 6:all_changed=all_changed and pixel_data(index)!=baseline[index]
	check("all six fields respond to the source turn",all_changed)
	export_image(0,"translate-turned");export_image(3,"reflect-turned")
	for repeat in 3:await press(0)
	var returned:=true
	for index in 6:returned=returned and pixel_data(index)==baseline[index]
	check("four presses return all six images exactly",study.phase==0 and returned)
	await photo("exception-before",Vector3(5.0,4.0,2.0),Vector3(3.2,0.025,6),64)
	var rays:Array=[]
	for p in [Vector3(3.05,0,5.5),Vector3(2.85,0,5.5),Vector3(3.4,0,5.5)]:
		var hit:=floor_at(study.to_global(p));rays.append(hit)
	check("black and white sample positions have floor support",rays.all(func(hit):return not hit.is_empty()))
	await press(1)
	check("EXCEPTION enables the local change",study.exception)
	var others_same:=true
	for index in 5:others_same=others_same and pixel_data(index)==baseline[index]
	check("exception leaves the other five images identical",others_same)
	var changed:=0;var local_only:=true;var updated:=pixel_data(5)
	for y in 256:
		for x in 256:
			var at: int=(y*256+x)*3
			if updated[at]!=baseline[5][at]:
				changed+=1;local_only=local_only and x>=96 and x<128 and y>=96 and y<128
	check("only the designated tile pixels change",changed>0 and local_only)
	observations["exception_changed_pixels"]=changed
	export_image(5,"rule-5-exception")
	var fixed:=true
	for index in 6:fixed=fixed and study.surfaces[index].global_transform.is_equal_approx(transforms[index])
	check("both controls preserve the floor geometry",fixed)
	await photo("exception-after",Vector3(5.0,4.0,2.0),Vector3(3.2,0.025,6),64)
	for i in rays.size():
		var before:Dictionary=rays[i]
		var at:Vector3=before.get("position",Vector3.ZERO)
		var after:=floor_at(at)
		check("unchanged collision under sample "+str(i),not before.is_empty() and not after.is_empty() and before.collider==after.collider and before.position.is_equal_approx(after.position))
	# Each route passes through black/white regions and crosses the image boundary.
	actor.global_position=study.to_global(Vector3(-3.2,0.05,-9));actor.velocity=Vector3.ZERO
	driver=Journey.KeyJourney.new();driver.world=museum;driver.actor=actor;driver.view=museum.get("_cam");root.add_child(driver)
	if not await walk(Vector3(-3.2,0.05,-3),"cross TRANSLATE and its far border"):return
	if not await walk(Vector3(3.2,0.05,3),"approach ONE EXCEPTION across the hall"):return
	if not await walk(Vector3(3.2,0.05,9),"cross ONE EXCEPTION and its far border"):return
	await press(1)
	check("exception off restores the original sixth image",not study.exception and pixel_data(5)==baseline[5])
	observations["artifact_sha256"]=FileAccess.get_sha256("res://commons/artifacts/regularity/tiling_principles.gd")
	observations["study_world"]=xyz(study.global_position)
	completed=true
func finish() -> void:
	if driver!=null:driver.release();driver.set_physics_process(false)
	check("study completed",completed)
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Isolated production museum. Existing buttons receive supplied pointer events; actual generated textures are exported. Supplied key input drives the ordinary museum body across three selected paths; camera views are staged. No headset or learner claim."},"  "))
	print("TILING UNDERFOOT ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
