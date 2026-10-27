extends "res://tools/probes/movable_pivot_probe.gd"
## Assembly-model verification only; not full-size player traversal acceptance.
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--pictures="):pictures=arg.trim_prefix("--pictures=")
	DirAccess.make_dir_recursive_absolute(pictures)
	host=Node3D.new();root.add_child(host);current_scene=host
	var environment:=WorldEnvironment.new();var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("b6b3ba");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color.WHITE;env.ambient_light_energy=.8;environment.environment=env;host.add_child(environment)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-50,-35,0);sun.light_energy=1.2;sun.shadow_enabled=true;host.add_child(sun)
	var building: Node3D=load("res://commons/void/architecture.gd").new();host.add_child(building);await ticks(8)
	artifact=building.content.exhibits["1/portal-copies"].get_node("Artifact");await artifact.prepare_editor_preview();await ticks(4)
	check("saved assembly contains 24 portal copies and five study members",artifact.part_defaults.size()==29)
	var sources: Array=[];var same:=true;var ready:=true
	for i in 24:
		var node: Node3D=artifact.get_node("Portal%02d/Source"%(i+1));sources.append(node)
		same=same and node.get_meta("outer_size").is_equal_approx(Vector3(2.3,3.5,1.35))
		ready=ready and node.ready_mesh and node.get_meta("shared_openings")==24
	check("every copy retains one identical unscaled outer portal element",same)
	check("all 24 actual Boolean pieces finish with the shared opening union",ready)
	check("a separate single portal is visible beside the assembly",artifact.has_node("OneElement/Source/PortalResult"))
	var connected:=true
	for i in 23:
		var a: Vector3=sources[i].global_position;var b: Vector3=sources[i+1].global_position
		if not host.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(a,b,1)).is_empty():connected=false
	check("no collision caps interrupt the 23 links between portal centres",connected)
	var first: Vector3=sources[0].global_position;var last: Vector3=sources[-1].global_position
	check("assembly represents the same 12m / two-storey drop at 1:10",absf(first.y-last.y-1.2)<.0001)
	check("pitch, heading and accumulated roll change while uniform scale stays 1:10",sources[8].global_basis.orthonormalized().get_euler().distance_to(sources[0].global_basis.orthonormalized().get_euler())>.3 and absf(sources[8].global_basis.get_scale().x-.1)<.0001)
	check("portal 9 visibly combines X, Y and Z turns",absf(artifact.get_node("Portal09").rotation_degrees.x)>20 and absf(artifact.get_node("Portal09").rotation_degrees.y)>20 and absf(artifact.get_node("Portal09").rotation_degrees.z)>5)
	check("first portal stands upright and last rests on its head",sources[0].global_basis.y.normalized().dot(Vector3.UP)>.999 and sources[-1].global_basis.y.normalized().dot(Vector3.UP)<-.999)
	check("no extra middle landing is present",not artifact.has_node("LevelGuide6") and not artifact.has_node("TurnLanding"))
	camera=Camera3D.new();camera.fov=45;camera.near=.015;host.add_child(camera)
	for layer in root.find_children("*","CanvasLayer",true,false):layer.hide()
	var fill:=OmniLight3D.new();fill.light_energy=.5;fill.omni_range=5;host.add_child(fill);fill.global_position=artifact.to_global(Vector3(-1,2.6,2))
	await shot("01-portal-copies",Vector3(2.4,2.7,3.3),Vector3(-.05,1.3,0))
	await shot("02-falling-turn",Vector3(1.4,2,1.5),Vector3(.2,1.25,0))
	await shot("03-one-element",Vector3(-.1,1.2,1.1),Vector3(-.75,.84,.35))
	await shot("04-side-sequence",Vector3(-.2,1.65,3.5),Vector3(0,1.3,0))
	var failed: Array=checks.filter(func(c):return not c.passed)
	FileAccess.open(pictures.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"metrics":{"parts":artifact.part_defaults},"scope":"Assembly model: equal portal elements, changed poses, actual Boolean shared openings, connected centreline rays and native photography. Not full-size desktop/VR walkability acceptance."},"  "))
	print("PORTAL_COPIES_DONE ",JSON.stringify(failed));building.free();host.free();quit(0 if failed.is_empty() else 1)
