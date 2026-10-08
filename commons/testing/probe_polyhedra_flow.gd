extends SceneTree
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
	print(("PASS " if ok else "FAIL ")+label)
func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	var museum: Node = load("res://commons/scenes/endless_museum.tscn").instantiate()
	museum.set("_studio",true)
	museum.set("_headless",true)
	var row: Dictionary = museum.call("_derive_map_row","Primitives_Polythedra")
	var counts := {"concrete_barrier":0,"street_sign":0,"trafficcone":0}
	for entry: Dictionary in row.artifacts:
		if not counts.has(entry.token): continue
		var folder: String = "commons/primitives/trafficcone" if entry.token=="trafficcone" else "commons/artifacts/"+entry.token
		var cell: Array = entry.tile_cell
		check(museum.call("_stamp",world,"res://"+folder+"/"+entry.token+".tscn",entry.token,
			{"x":cell[0],"y":cell[1],"top":0.0},0,1,{},false,0.0,float(entry.rotation),entry.get("config",{})),"stamp "+entry.token)
		counts[entry.token] += 1
	check(counts.concrete_barrier==12 and counts.street_sign==5 and counts.trafficcone==2,"map contains barrier ring, five signs and two cones")
	var directions: Array[String] = []
	for child in world.get_children():
		if child.get_meta("artifact_lookup_name","")=="street_sign": directions.append(child.direction)
		if child.get_meta("artifact_lookup_name","")=="concrete_barrier":
			check(child.get_node_or_null("TrafficCollision/CollisionShape3D")!=null,"placed barrier has physical hull")
	directions.sort()
	check(directions==["ahead","both","left","none","right"],"STOP, ahead, left, right and either-way variants")
	# Isolated physics comparison using the same artifact and museum ramp builder.
	var ground := StaticBody3D.new()
	var ground_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20,0.2,12)
	ground_shape.shape = box
	ground.position = Vector3(0,-0.1,-10)
	ground.add_child(ground_shape)
	world.add_child(ground)
	var barrier = load("res://commons/artifacts/concrete_barrier/concrete_barrier.tscn").instantiate()
	barrier.set_meta("config_blocking","1")
	barrier.position = Vector3(0,0,-10)
	world.add_child(barrier)
	check(museum.call("_stamp_wedge",world,Vector2i(-4,-10),"north",0.4,0),"museum builds real walkable wedge")
	var stage := StaticBody3D.new()
	var stage_shape := CollisionShape3D.new()
	var stage_box := BoxShape3D.new()
	stage_box.size = Vector3(1,0.4,2)
	stage_shape.shape = stage_box
	stage.add_child(stage_shape)
	stage.position = Vector3(-3.5,0.2,-8)
	world.add_child(stage)
	var walker := CharacterBody3D.new()
	walker.collision_layer = 2
	walker.collision_mask = 1
	walker.floor_snap_length = 0.15
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.2
	capsule.height = 1.6
	var collision := CollisionShape3D.new()
	collision.shape = capsule
	collision.position.y = 0.8
	walker.add_child(collision)
	world.add_child(walker)
	await physics_frame
	walker.position = Vector3(0,0.05,-11.2)
	await walk(walker,150)
	check(walker.position.z < -10.35,"concrete stops forward walking")
	walker.position = Vector3(-3.5,0.05,-11.2)
	walker.velocity = Vector3.ZERO
	await walk(walker,150)
	check(walker.position.y > 0.35 and walker.position.z > -9,"wedge carries the same capsule onto the stage")
	# A sign is a visual instruction: its scene contributes no solid wall.
	var sign = load("res://commons/artifacts/street_sign/street_sign.tscn").instantiate()
	world.add_child(sign)
	check(sign.find_children("*","CollisionObject3D",true,false).is_empty(),"STOP sign itself does not enforce a collision barrier")
	sign.queue_free()
	if "--shot" in OS.get_cmdline_user_args():
		var camera := Camera3D.new()
		world.add_child(camera)
		camera.position = Vector3(5.8,3.8,6.2)
		camera.look_at(Vector3(6,0.9,12))
		camera.current = true
		var env := WorldEnvironment.new()
		env.environment = Environment.new()
		env.environment.background_mode = Environment.BG_COLOR
		env.environment.background_color = Color(0.12,0.14,0.17)
		env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.environment.ambient_light_color = Color.WHITE
		env.environment.ambient_light_energy = 0.8
		world.add_child(env)
		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-40,-25,0)
		world.add_child(light)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://ada_run/polyhedra_flow/preview.png")
	FileAccess.open("res://ada_run/polyhedra_flow/checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Current-map stamping, barrier hull and museum wedge with supplied capsule movement; full-room/headset routes unverified."},"  "))
	museum.free()
	print("RESULT ",checks," ",failures)
	quit(0 if failures.is_empty() else 1)
func walk(body: CharacterBody3D, frames: int) -> void:
	for i in frames:
		body.velocity = Vector3(0,body.velocity.y-9.8/60.0,1.0)
		body.move_and_slide()
		await physics_frame
