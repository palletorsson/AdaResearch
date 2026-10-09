extends SceneTree

var failures: Array[String] = []
var report := {"walks":[],"shots":[],"scope":"Rendered artifact and continuous controlled capsule walks; no headset or learner test."}
const OUT := "res://doc/book/iterations/2026-09-21-rhizome-immersion/"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	OS.low_processor_usage_mode = false
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.065,0.085,0.10)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.74,0.8,0.85)
	env.environment.ambient_light_energy = 0.60
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55,-25,0)
	sun.light_energy = 1.4
	world.add_child(sun)
	var scene := load("res://algorithms/spacetopology/marchingcubes/scenes/rhizome_cave_demo.tscn") as PackedScene
	var artifact := scene.instantiate()
	artifact.set_meta("config_passage_study",true)
	artifact.set_meta("config_build_synchronously",true)
	world.add_child(artifact)
	var cave: Node3D = artifact.get_node("InhabitableRhizome")
	var start := Time.get_ticks_msec()
	while not cave.ready_to_walk and Time.get_ticks_msec()-start < 90000:
		await process_frame
	if not cave.ready_to_walk:
		push_error("Passage build timed out")
		quit(1)
		return
	report["build_ms"] = Time.get_ticks_msec()-start
	report["vertices"] = cave.shell_mesh.surface_get_array_len(0)+cave.shell_mesh.surface_get_array_len(1)
	# Approach floor reproduces the museum's continuous flat floor under the artifact.
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(32,0.5,38)
	floor_shape.shape = box
	floor_shape.position.y = -0.26
	floor_body.add_child(floor_shape)
	world.add_child(floor_body)
	var floor_mesh := MeshInstance3D.new()
	var plane := BoxMesh.new()
	plane.size = box.size
	floor_mesh.mesh = plane
	floor_mesh.position.y = -0.26
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.17,0.19,0.2)
	floor_mesh.material_override = floor_mat
	world.add_child(floor_mesh)
	var walker := CharacterBody3D.new()
	walker.floor_snap_length = 0.4
	walker.floor_max_angle = deg_to_rad(45)
	var capsule := CollisionShape3D.new()
	var capsule_shape := CapsuleShape3D.new()
	capsule_shape.radius = 0.28
	capsule_shape.height = 1.75
	capsule.shape = capsule_shape
	capsule.position.y = 0.875
	walker.add_child(capsule)
	world.add_child(walker)
	walker.position = Vector3(0,0.08,-16)
	Engine.time_scale = 4.0
	var route: Array[int] = [0,1,4,2,0,1,3,6,7,4,1,3,9,10,11,12,13,14,2,5,7,8]
	for index in route:
		await walk_to(walker,cave.points[index]+Vector3(0,0.05,0),str(index))
	await walk_to(walker,Vector3(0,0.05,16),"exit")
	Engine.time_scale = 1.0
	# At the overcrossing, floor heights must differ without an opening connecting them.
	report["upper_route_height"] = cave.points[12].y
	if DisplayServer.get_name() != "headless":
		var camera := Camera3D.new()
		world.add_child(camera)
		camera.current = true
		for shot in [
			["outside",Vector3(23,19,-26),Vector3(0,1,0),64.0],
			["entry",Vector3(0,1.7,-16),Vector3(0,1.6,-7),78.0],
			["junction",Vector3(0,1.7,-3),Vector3(4,1.6,5),90.0],
			["upper-return",Vector3(-3,5.4,8),Vector3(2,5.3,1),78.0],
			["return-light",Vector3(5.0,1.7,3.5),Vector3(4,2.0,5),86.0]
		]:
			camera.position = shot[1]
			camera.look_at(shot[2])
			camera.fov = shot[3]
			await create_timer(0.25).timeout
			await RenderingServer.frame_post_draw
			var path: String = OUT+shot[0]+".png"
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
			report.shots.append(path)
	report["failures"] = failures
	var file := FileAccess.open(OUT+"artifact-runtime.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("RHIZOME PASSAGES ",failures)
	quit(0 if failures.is_empty() else 1)

func walk_to(walker: CharacterBody3D,target: Vector3,tag: String) -> void:
	var began := Time.get_ticks_msec()
	var distance := Vector2(target.x-walker.position.x,target.z-walker.position.z).length()
	var timeout := int((distance / 3.0 + 3.0) * 1000.0 / Engine.time_scale)
	while Time.get_ticks_msec()-began < timeout:
		var d := target-walker.position
		d.y = 0
		var direction := d.normalized() if d.length()>0.09 else Vector3.ZERO
		walker.velocity.x = direction.x * 3.0
		walker.velocity.z = direction.z * 3.0
		walker.velocity.y = -0.1 if walker.is_on_floor() else walker.velocity.y-12.0*walker.get_physics_process_delta_time()
		walker.move_and_slide()
		await physics_frame
		if d.length()<0.15 and walker.is_on_floor(): break
	var error := walker.position.distance_to(target)
	var passed := error<0.3
	report.walks.append({"tag":tag,"passed":passed,"error":error,"position":[walker.position.x,walker.position.y,walker.position.z]})
	if not passed:
		failures.append("walk "+tag)
		# Continue diagnosis, explicitly recorded; this is not a successful continuous route.
		walker.position = target
		walker.velocity = Vector3.ZERO
