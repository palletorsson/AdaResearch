extends SceneTree
## Production tower geometry, roof content and atmosphere; scripted observer camera.
## Does not run player controls or change saved placements.
var out := ""
var camera: Camera3D
var building: Node3D
var records: Array = []

func _initialize() -> void:
	run.call_deferred()

func settle(count := 3) -> void:
	for i in count: await process_frame
	await RenderingServer.frame_post_draw

func shot(name: String) -> void:
	await settle()
	root.get_texture().get_image().save_png(out.path_join(name+".png"))
	records.append({"image":name+".png","camera":[camera.global_position.x,camera.global_position.y,camera.global_position.z],"basis":str(camera.global_basis)})

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	root.msaa_3d=Viewport.MSAA_4X
	var world := Node3D.new()
	root.add_child(world)
	current_scene=world
	building=load("res://commons/void/architecture.gd").new()
	building.stream_content=true
	world.add_child(building)
	var visible_floors: Array[int]=[0,1,2,3,4]
	building.show_floor_window(visible_floors)
	building.content.load_floor(0)
	var sky: Node3D=load("res://commons/void/atmosphere.gd").new()
	world.add_child(sky)
	sky.animate_sky=false
	sky.set_sky_time(0.0)
	sky.environment.fog_enabled=true
	sky.environment.fog_depth_end=30.0
	sky.environment.fog_depth_curve=1.5
	sky.environment.fog_density=1.0
	sky.get_node("WarmSun").directional_shadow_max_distance=28.0
	camera=Camera3D.new()
	camera.near=.05
	camera.far=4000.0
	world.add_child(camera)
	camera.environment=sky.environment
	camera.make_current()
	await settle(30)
	for side in range(building.spec.service_x.size()):
		var target := Vector3(float(building.spec.service_x[side])+.42,0,float(building.spec.service_z))
		var prefix := "pipe-"+str(side)
		camera.global_position=target+Vector3(.24,1.1,1.05)
		camera.look_at(target)
		var pose: Transform3D=camera.global_transform
		for i in 12: await shot(prefix+"-still-%03d"%i)
		for i in 49:
			var phase: float=TAU*float(i)/48.0
			camera.global_position=pose.origin+Vector3(.28*sin(phase),.15*sin(phase),0)
			await shot(prefix+"-move-%03d"%i)
		camera.global_transform=pose
		await shot(prefix+"-baseline")
		var found := false
		for node in building.floor_details[1].get_children():
			if node is MeshInstance3D and node.mesh is CylinderMesh and is_equal_approx(node.mesh.top_radius,.07):
				if absf(node.global_position.x-target.x)<.01:
					node.hide()
					await shot(prefix+"-cap-hidden-control")
					node.show()
					found=true
		await shot(prefix+"-restored")
		records.append({"control":prefix,"candidate_found":found,"target":[target.x,target.y,target.z]})
	var crate: Node3D=building.content.props["0/arrival-crate"].get_node("Prefab")
	var counter: Node3D=building.content.exhibits["0/clock"].get_node("Artifact")
	camera.global_position=crate.to_global(Vector3(0,1.65,.65))
	camera.look_at(counter.label.global_position)
	await shot("crate-closed")
	var opened: bool=crate.strike(crate.to_global(Vector3(0,1.4,0)),crate.to_global(Vector3(0,1.4,-1.4)))
	await settle(65)
	await shot("crate-open-standing")
	var stand: Transform3D=camera.global_transform
	for i in 49:
		var phase: float=TAU*float(i)/48.0
		var drop: float=.6*(.5-.5*cos(phase))
		camera.global_position=stand.origin-Vector3.UP*drop
		await shot("crate-lower-%03d"%i)
	camera.global_transform=stand
	await shot("crate-standing-return")
	camera.global_position=stand.origin-Vector3.UP*.6
	await shot("crate-lowered")
	records.append({"crate_opened_by_production_strike":opened,"crate_transform":str(crate.global_transform),"counter_label_position":str(counter.label.global_position),"camera_motion":"1.65m to 1.05m eye height and back; fixed camera orientation"})
	FileAccess.open(out.path_join("capture.json"),FileAccess.WRITE).store_string(JSON.stringify({"scope":"Native Mobile renderer, production architecture/roof content and sky. Scripted observer; no player rig or headset. Sky frozen; below-roof artifact content unloaded. Candidate cap hidden only for isolated control images, then restored.","resolution":str(root.size),"frames":records},"\t"))
	print("ROOF_CAPTURE_COMPLETE ",records.size())
	quit()
