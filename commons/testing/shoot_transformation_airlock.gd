extends SceneTree
## Actual Godot renders. Add --museum after -- to use the Trans_Pit placement.
## Run with the Windows display driver, XR off and an absolute --log-file.

const OUT := "res://doc/space/transformation-airlock-2026-09-17/"
const AIRLOCK := "res://commons/artifacts/transformation_airlock/transformation_airlock.tscn"
var camera: Camera3D
var stage: Node3D
var door: Node3D
var results: Array[Dictionary] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	if "--museum" in OS.get_cmdline_user_args():
		await _museum()
	else:
		await _isolated()
	quit(0 if results.all(func(row: Dictionary) -> bool: return bool(row.pass)) else 1)

func _isolated() -> void:
	stage = Node3D.new(); stage.name = "AirlockPhotoStage"
	root.add_child(stage); current_scene = stage
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("101c27")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("a7bfd3")
	environment.ambient_light_energy = 0.65
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment; stage.add_child(world)
	var floor_mesh := MeshInstance3D.new()
	var floor_box := BoxMesh.new(); floor_box.size = Vector3(24,0.12,24)
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("243542"); floor_material.roughness = 0.75
	floor_mesh.mesh = floor_box; floor_mesh.material_override = floor_material
	floor_mesh.position.y = -0.06; stage.add_child(floor_mesh)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42,-27,0)
	sun.light_color = Color("dbe6ee"); sun.light_energy = 1.2
	sun.shadow_enabled = true; stage.add_child(sun)
	for spec: Array in [[Vector3(-4,4,-4),Color("8bc4e6"),2.0], [Vector3(5,3,2),Color("ffba82"),2.8]]:
		var fill := OmniLight3D.new()
		fill.position = spec[0]; fill.light_color = spec[1]; fill.light_energy = spec[2]
		fill.omni_range = 13; stage.add_child(fill)
	door = load(AIRLOCK).instantiate(); stage.add_child(door)
	door.set_physics_process(false)
	camera = Camera3D.new(); camera.fov = 48; stage.add_child(camera)
	for sample: Array in [[0.0,"closed"],[0.4,"translation"],[0.7,"rotation"],[1.0,"open"]]:
		door.set("progress",float(sample[0])); door.call("_apply_pose")
		await _shot(Vector3(0,2.1,-9.5),Vector3(0,1.8,0),"airlock-"+str(sample[1]))
	door.set("progress",0.7); door.call("_apply_pose")
	await _shot(Vector3(-6,3.5,-9),Vector3(0,1.6,0),"airlock-three-quarter")
	door.set("progress",1.0); door.call("_apply_pose")
	await _shot(Vector3(-4.2,2.6,-7.5),Vector3(0,1.6,0),"airlock-open-angle")
	_write_report("renders.json",{"mode":"isolated","states":[0,0.4,0.7,1],"screenshots":6})

func _museum() -> void:
	var control := "res://ada_run/airlock-capture-control.json"
	var f := FileAccess.open(control,FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter":"transformation","first_map":"Trans_Pit","grid_pack":1,"dollhouse":0})); f.close()
	stage = load("res://commons/scenes/endless_museum.tscn").instantiate()
	stage.set("EM_CONTROL",control)
	stage.set("_overrides_path",control+".unused")
	stage.set("_hand_path",control+".unused")
	stage.set("_cartridge_read_enabled",false)
	stage.set("_costume_on",false)
	stage.set("start_chapter","transformation"); stage.set("start_map","Trans_Pit")
	root.add_child(stage); current_scene = stage
	await create_timer(3).timeout
	stage.set_process(false); stage.set_physics_process(false); stage.call("flush_stamps")
	for i in 200: await process_frame
	var grid: Node3D = stage.find_child("SimGrid_Trans_Pit",true,false)
	_check("Trans_Pit uses its actual embedded grid",grid != null)
	if grid == null:
		_write_report("museum-placement.json",{}); return
	for candidate: Node in grid.find_children("*","Node3D",true,false):
		var script: Script = candidate.get_script()
		if script != null and script.resource_path.ends_with("/transformation_airlock.gd"):
			door = candidate as Node3D; break
	_check("airlock builds inside the Trans_Pit grid",door != null)
	if door == null:
		_write_report("museum-placement.json",{}); return
	door.set_physics_process(false)
	var player: CharacterBody3D = stage.get("_player")
	if player != null:
		player.hide(); player.set_physics_process(false)
	var old_camera: Camera3D = stage.get("_cam")
	if old_camera != null:
		for child: Node in old_camera.get_children():
			if child is Timer: child.stop()
	camera = Camera3D.new(); camera.fov = 62; stage.add_child(camera)
	var local: Vector3 = grid.to_local(door.global_position)
	_check("door remains at source cell (7,29)",absf(local.x-7)<0.02 and absf(local.z-29)<0.02,str(local))
	_check("door keeps metre scale",door.global_basis.get_scale().is_equal_approx(Vector3.ONE))
	var space := grid.get_world_3d().direct_space_state
	var capsule := CapsuleShape3D.new(); capsule.radius = 0.22; capsule.height = 1.7
	var q := PhysicsShapeQueryParameters3D.new(); q.shape = capsule; q.collision_mask = 1
	if player != null: q.exclude = [player.get_rid()]
	for sample: Array in [[0.0,"closed"],[0.7,"moving"],[1.0,"open"]]:
		door.set("progress",float(sample[0])); door.call("_apply_pose")
		for i in 3: await physics_frame
		q.transform.origin = door.to_global(Vector3(0,0.9,-2)); q.motion = Vector3(0,0,4)
		var clear: bool = space.cast_motion(q)[0] > 0.99
		if float(sample[0]) == 0.0: _check("closed leaves block a 44 cm body",not clear)
		if float(sample[0]) == 1.0: _check("open leaves admit the same body",clear)
		await _shot(door.to_global(Vector3(0,1.75,-5.2)),door.to_global(Vector3(0,1.65,0)),"museum-airlock-"+str(sample[1]))
	for x in [-4.25,4.25]:
		q.transform.origin = door.to_global(Vector3(x,0.9,-1.2)); q.motion = Vector3(0,0,2.4)
		_check("frame joins side wall at x="+str(x),space.cast_motion(q)[0] < 0.99)
	var floor_ok := true
	for z in range(25,33):
		var at: Vector3 = grid.to_global(Vector3(7,0.5,z))
		var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(at+Vector3.UP*0.08,at-Vector3.UP*0.15,1))
		floor_ok = floor_ok and not hit.is_empty() and absf(hit.position.y-at.y)<0.02
	_check("runway rows25 through32 stay on the existing floor level",floor_ok)
	# Stay beyond the previous study's row24 wall, inside the new alcove.
	await _shot(door.to_global(Vector3(-4.0,2.7,-4.0)),door.to_global(Vector3(0,1.6,0)),"museum-airlock-angle")
	_write_report("museum-placement.json",{"mode":"actual_museum","grid_origin":str(grid.global_position),"door_source_position":str(local),"map_sha256":FileAccess.get_sha256("res://commons/maps/Trans_Pit/map_data.json"),"headset_checked":false})

func _shot(at: Vector3, target: Vector3, title: String) -> void:
	camera.global_position = at; camera.look_at(target)
	for i in 18:
		camera.make_current(); await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(OUT+title+".png")
	_check("saved "+title,result == OK)

func _check(label: String, passed: bool, detail: Variant = null) -> void:
	results.append({"check":label,"pass":passed,"detail":detail})
	print("[airlock-shot] ","PASS " if passed else "FAIL ",label," ",detail if detail != null else "")

func _write_report(name: String, data: Dictionary) -> void:
	data["results"] = results
	data["artifact_sha256"] = FileAccess.get_sha256("res://commons/artifacts/transformation_airlock/transformation_airlock.gd")
	var f := FileAccess.open(OUT+name,FileAccess.WRITE)
	f.store_string(JSON.stringify(data,"  ")); f.close()
