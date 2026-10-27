extends "res://tools/probes/void_transfer_probe.gd"
## Actual collision trials through the curated encounters, not mesh-only checks.
var building: Node3D
var scene: Node3D
var lens: Camera3D
var observations: Dictionary = {}

func exhibit(floor: int, id: String) -> Node3D:
	return building.content.exhibits["%d/%s" % [floor,id]].get_node("Artifact")

func surface_ray(from: Vector3, to: Vector3) -> Dictionary:
	return building.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,1))

func visitor(at: Vector3) -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.name = "CuratedWalkabilityWitness"
	body.collision_layer = 1; body.collision_mask = 1
	body.add_to_group("em_walker")
	body.floor_snap_length = .15
	body.floor_max_angle = deg_to_rad(45)
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new(); shape.radius = .22; shape.height = 1.6
	collider.shape = shape; collider.position.y = .8; body.add_child(collider)
	scene.add_child(body); body.global_position = at
	return body

func walk(body: CharacterBody3D, target: Vector3, seconds: float) -> bool:
	for i in range(int(seconds * 60)):
		var direction := target - body.global_position; direction.y = 0
		if direction.length() < .18: return true
		await physics_frame
		body.velocity = direction.normalized() * 1.5 + Vector3.UP * (body.velocity.y - 9.8/60.0)
		body.move_and_slide()
	return false

func encounter_photo(name: String, floor: int, at: Vector3, target: Vector3) -> void:
	var shown:Array[int]=[floor]
	building.show_floor_window(shown)
	for n in [16,18,19]: building.content.roots[n].visible = n == floor
	lens.global_position = at + Vector3.UP * building.spec.levels[floor]
	lens.look_at(target + Vector3.UP * building.spec.levels[floor])
	await frames(3); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name+".png"))

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	Source.use_main_tower = true
	scene=Node3D.new(); root.add_child(scene); current_scene=scene
	building=load("res://commons/void/architecture.gd").new(); building.stream_content=true; scene.add_child(building)
	for n in [16,18,19]: building.content.load_floor(n)
	var shown:Array[int]=[16]
	building.show_floor_window(shown)
	building.content.roots[18].visible=false; building.content.roots[19].visible=false
	root.size = Vector2i(1440,900)
	var environment := WorldEnvironment.new(); environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR; environment.environment.background_color=Color("20252d")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color("d7dfef"); environment.environment.ambient_light_energy=.7
	scene.add_child(environment)
	var light := DirectionalLight3D.new(); light.rotation_degrees=Vector3(-55,-35,0); light.light_energy=1.8; light.shadow_enabled=true; scene.add_child(light)
	lens=Camera3D.new(); lens.fov=80; lens.far=90; scene.add_child(lens); lens.current=true
	await frames(45)
	check("standard floor dimensions unchanged",building.spec.width==42 and building.spec.depth==18 and building.spec.storey_height==6)
	var array:Node3D=exhibit(16,"angle-bands")
	check("four full-size walkable strips, not a display row",array.tower_walkways and not array.tower_row and array.columns==1 and array.bands.size()==4)
	for band in array.bands:
		check(str(band.id)+" preserves full cube scale",band.node.global_basis.get_scale().is_equal_approx(Vector3.ONE))
		check(str(band.id)+" keeps original six-angle gradient",band.cubes.size()==6 and array.row_angle_step==18)
		var cube:Node3D=band.cubes[0]
		check(str(band.id)+" keeps 2.04 m mesh and collider",cube.get_child(0).mesh.size.is_equal_approx(Vector3.ONE*2.04) and cube.get_node("Body").get_child(0).shape.size.is_equal_approx(Vector3.ONE*2.04))
		check(str(band.id)+" has actual launch-bank collision",not surface_ray(band.node.to_global(Vector3(0,.3,-1.4)),band.node.to_global(Vector3(0,-.3,-1.4))).is_empty())
	check("two-width physical comparison restored",array.show_body_comparison and array.body_comparison!=null)
	array.body_comparison.auto_repeat=false
	for i in range(2700):
		if array.body_comparison.results.has("WIDE"):break
		await frames(1)
	observations.rotation=array.body_comparison.results.duplicate(true)
	check("both body widths finish their real collision trials",observations.rotation.has("NARROW") and observations.rotation.has("WIDE"))
	for width in observations.rotation:
		var results: Array=observations.rotation[width]
		var control:Dictionary=results.filter(func(r):return r.band=="Y")[0]
		check(width+" can walk the horizontal Y strip",control.reason=="ARRIVED")
		check(width+" encounters a real limit in another orientation",results.any(func(r):return r.band!="Y" and r.reason!="ARRIVED"))
	await encounter_photo("01-rotation-walking",16,Vector3(-6.5,4.65,7.3),Vector3(3,2.8,0))

	var y:float=building.spec.levels[18]
	var wall:Node3D=exhibit(18,"f1_approach_wall_5_6")
	var cut:Node3D=exhibit(18,"f1_carve_grid_5_12")
	var scale_field:Node3D=exhibit(18,"f1_approach_scale_5_18")
	check("body thresholds keep unit scale so sensing matches the body",wall.global_basis.get_scale().is_equal_approx(Vector3.ONE) and cut.global_basis.get_scale().is_equal_approx(Vector3.ONE) and scale_field.global_basis.get_scale().is_equal_approx(Vector3.ONE))
	check("wall spans twelve metres of the floor",wall.width_m==12 and wall.height_m==4.4)
	check("carving is a body-height threshold",cut.cells_x==35 and cut.cells_y==7 and cut.cells_z==13)
	check("scale field has fifteen shoulder-height blocks",scale_field._count==15 and scale_field.block_m==2.1)
	var body:=visitor(Vector3(-18,y+.03,0))
	var crossed:bool=await walk(body,Vector3(-13.8,y,0),7)
	check("walk into the wall and it makes a passage",crossed and wall._peak>.8)
	await encounter_photo("02-body-opens",18,Vector3(-18.7,1.7,4.7),Vector3(-14,1.8,0))
	body.queue_free(); await frames(15)
	body=visitor(Vector3(-3.4,y+.03,0))
	crossed=await walk(body,Vector3(3.3,y,0),9)
	check("real visitor walks a persistent cut through the lattice",crossed and cut._carved>0)
	observations.carved_cells=cut._carved
	body.queue_free();await frames(30)
	check("the body leaves but the cut remains",cut._carved==observations.carved_cells)
	await encounter_photo("03-body-carved",18,Vector3(-4.2,1.7,0),Vector3(4,1.7,0))
	body=visitor(Vector3(13.3,y+.03,1.15))
	crossed=await walk(body,Vector3(20.5,y,1.15),10)
	check("walk between blocks that shrink near the body",crossed and scale_field._ever_open)
	body.queue_free();await frames(180)
	check("scaling blocks return when the body leaves",scale_field._factor[7]>.95)
	observations.body={"wall_peak":wall._peak,"carved":cut._carved,"scale_crossed":crossed}

	# Inspect actual time-driven motion and the cleared waiting/turning spaces.
	var pusher:Node3D=exhibit(19,"f2_pusher_block_7_3")
	check("pushers move toward the existing shaft",pusher._end_pos.x>pusher._start_pos.x+2.2 and pusher._end_pos.x< -12.9)
	check("pusher collision stays at original size",pusher._body.get_child(0).shape.size.is_equal_approx(Vector3.ONE*.98))
	var grower:Node3D=exhibit(19,"f2_grower_block_7_21")
	check("scale boundary narrows the edge route without covering the shaft",is_equal_approx(grower.global_position.x-3.5/2.0,13.45) and grower.anchor=="floor")
	for n in [16,18,19]:
		building.content.roots[n].visible=true
		for entry in building.content.data.floors[n].artifacts:
			var host:Node3D=exhibit(n,entry.id);var boxes:Array=[];geometry(host,boxes)
			if boxes.is_empty():continue
			var bounds:AABB=boxes[0]
			for b in boxes:bounds=bounds.merge(b)
			measured.append({"floor":n,"id":entry.id,"min":[bounds.position.x,bounds.position.y-building.spec.levels[n],bounds.position.z],"max":[bounds.end.x,bounds.end.y-building.spec.levels[n],bounds.end.z]})
	await encounter_photo("04-pit-pushers",19,Vector3(-17.7,1.7,-5),Vector3(-13.4,.9,.5))
	await encounter_photo("05-pit-turning-lane",19,Vector3(-5.7,1.7,5),Vector3(4.5,1.2,5))
	await encounter_photo("06-pit-scale",19,Vector3(13.8,1.7,7.7),Vector3(14.6,1.4,0))
	FileAccess.open(out.path_join("native.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"observations":observations,"bounds":measured,"scope":"Real CharacterBody3D collision and natural proximity responses in the main tower. Neutral inspection lighting. No physical-headset or full desktop-input playthrough claim."},"  "))
	print("TRANSFORMATION_WALKABILITY ",failed)
	building.queue_free();await frames(2);quit(0 if failed.is_empty() else 1)
