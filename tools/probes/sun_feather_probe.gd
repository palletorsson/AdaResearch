extends "res://tools/probes/movable_pivot_final.gd"
## Focused saved-floor test. Inherited helpers use the Void's real mouse hand;
## XR lane invokes actual XRTools pickup with a synthetic controller.
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--pictures="):pictures=arg.trim_prefix("--pictures=")
	DirAccess.make_dir_recursive_absolute(out);DirAccess.make_dir_recursive_absolute(pictures)
	host=ReviewWorld.new();root.add_child(host);current_scene=host
	var world:=WorldEnvironment.new();var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("a9a5b0")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("ded3df");env.ambient_light_energy=.4
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC;world.environment=env;host.add_child(world)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-55,-25,0);sun.light_energy=.9;sun.shadow_enabled=true;host.add_child(sun)
	var building: Node3D=load("res://tools/probes/pivot_floor_slice.gd").new();host.add_child(building)
	artifact=building.content.exhibits["15/sun-feather"].get_node("Artifact")
	await ticks(8)
	check("actual floor 15 registry loads the sun feather",artifact.global_position.distance_to(Vector3(0,-90,1.4))<.0001)
	check("ten independently editable copies plus table and controls",artifact.specimens.size()==10 and artifact.part_defaults.size()==12)
	var correct:=true
	for i in 10:
		var part: Node3D=artifact.specimens[i]
		correct=correct and part.get_node("ScaledPrefab/TimberPlank2m").get_script().resource_path.ends_with("/line_body.gd")
		correct=correct and part.get_node("ScaledPrefab/BlueDoNotCross").get_script().resource_path.ends_with("/do_not_cross_barrier.gd")
	check("uses original timber plank and blue barricade prefab implementations",correct)
	artifact.set_parameters(30,.9,"timber")
	var last: Node3D=artifact.specimens[9]
	var base_radius: float=.65 if artifact.layout_mode=="circumference" else .5
	check("copy ten applies nine rotations and nine scale ratios",absf(last.rotation_degrees.y+90)<.01 and absf(last.position.length_squared()-(artifact.TOP*artifact.TOP+pow(base_radius*pow(.9,9),2)))<.001 and last.get_node("ScaledPrefab").scale.distance_to(Vector3.ONE*.3*pow(.9,9))<.0001)
	# Bound the full prototype on its two standard sheets across both sources.
	var fits:=true
	for family in ["timber","barrier"]:
		for angle in [0,17,42]:
			artifact.set_parameters(angle,1.04,family)
			for part in artifact.specimens:
				var source: Node3D=part.get_node("ScaledPrefab/"+("TimberPlank2m" if family=="timber" else "BlueDoNotCross"))
				var b: AABB=artifact._mesh_bounds(source,artifact)
				fits=fits and b.position.x>=-1.22 and b.end.x<=1.22 and b.position.z>=-1.22 and b.end.z<=1.22
	check("all permitted copies stay on the tabletop, including the blue barriers",fits)
	artifact.set_parameters(27,.92,"timber")
	# Test the actual Void player hand on all three physical sliders.
	var visitor: Node3D=load("res://commons/void/walker.gd").new();host.add_child(visitor);visitor.scripted_input=true
	visitor.global_position=artifact.to_global(Vector3(-.42,.06,2.2));await ticks(15)
	var before: float=artifact.turn_per_copy
	var hit:=await drag_grip(visitor,artifact.turn_slider._handle,Vector3.UP*.055)
	check("Void mouse drag changes rotation per copy",hit and artifact.turn_per_copy>before+5)
	visitor.global_position=artifact.to_global(Vector3(0,.06,2.2));await ticks(8)
	before=artifact.scale_ratio
	hit=await drag_grip(visitor,artifact.scale_slider._handle,Vector3.DOWN*.065)
	check("Void mouse drag changes scale between copies",hit and artifact.scale_ratio<before-.04)
	visitor.global_position=artifact.to_global(Vector3(.42,.06,2.2));await ticks(8)
	hit=await drag_grip(visitor,artifact.source_slider._handle,Vector3.UP*.2)
	check("Void source slider selects ten blue DO NOT CROSS prefabs",hit and artifact.source_family=="barrier" and artifact.specimens.all(func(part):return part.get_node("ScaledPrefab/BlueDoNotCross").visible and not part.get_node("ScaledPrefab/TimberPlank2m").visible))
	visitor.queue_free();await ticks(5)
	# Near-grab the retained native slider through XRTools, move and release.
	var origin:=XROrigin3D.new();host.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup: Node3D=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	artifact.set_parameters(12,.9,"timber");var grip: Node3D=artifact.turn_slider._handle
	controller.global_transform=grip.global_transform;grip.pick_up(pickup);await ticks(5)
	check("synthetic XRTools hand holds the rotation slider",grip.is_picked_up())
	controller.global_position+=Vector3.UP*.07;await ticks(12)
	check("synthetic hand motion changes the same copy rule",artifact.turn_per_copy>20)
	grip.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await ticks(6);before=artifact.turn_per_copy;await ticks(8)
	check("released XR slider retains the rule",not grip.is_picked_up() and is_equal_approx(before,artifact.turn_per_copy))
	origin.queue_free();await ticks(4)
	# Configuration/part isolation: moved copies must not depend on world zero.
	var clone: Node3D=load("res://commons/artifacts/sun_feather/sun_feather.tscn").instantiate();clone.position=Vector3(16,-108,0);clone.rotation.y=PI/2;host.add_child(clone)
	clone.apply_grid_config({"turn_per_copy":21,"scale_ratio":.94,"source_family":"barrier","only_parts":["Copy04"],"parts":{"Copy04":{"position":[.3,.9,.4],"rotation":[0,57,0]}}})
	await ticks(3)
	check("individual moved/rotated copy survives isolation without controls or table",clone.part_defaults.size()==1 and clone.get_node("Copy04").position.distance_to(Vector3(.3,.9,.4))<.0001 and absf(clone.get_node("Copy04").rotation_degrees.y-57)<.01)
	clone.set_parameters(30,.95,"timber");await ticks(3)
	check("isolated copy still accepts the recipe without freed-node errors",clone.get_node("Copy04/ScaledPrefab/TimberPlank2m").visible)
	clone.queue_free();await ticks(4)
	for layer in root.find_children("*","CanvasLayer",true,false):layer.hide()
	camera=Camera3D.new();camera.fov=52;host.add_child(camera)
	artifact.set_parameters(27,.92,"timber")
	await shot("01-ten-planks",Vector3(2.3,2.9,3.3),Vector3(0,.75,.05))
	artifact.set_parameters(36,.98,"timber")
	await shot("02-changed-rule",Vector3(2.3,2.9,3.3),Vector3(0,.75,.05))
	artifact.set_parameters(27,.92,"barrier")
	await shot("03-blue-barriers",Vector3(2.3,2.9,3.3),Vector3(0,.75,.05))
	await shot("04-controls",Vector3(.2,1.65,2.3),Vector3(0,.98,1.05))
	artifact.set_parameters(27,.92,"timber")
	await shot("05-in-transformation",Vector3(5,4.3,6),Vector3(0,.8,0))
	await artifact.prepare_editor_preview();await ticks(3)
	var data: Dictionary={"artifact":"sun_feather","config":{"turn_per_copy":27,"scale_ratio":.92,"source_family":"timber"},"parts":{}}
	for child in artifact.get_children():
		if child is Node3D and artifact.part_defaults.has(str(child.name)):
			var part: Dictionary=snapshot(child,"15-sun-feather-"+str(child.name));part["default"]=artifact.part_defaults[str(child.name)];part["scale"]=[1,1,1];data.parts[str(child.name)]=part
	FileAccess.open(out.path_join("assembly.json"),FileAccess.WRITE).store_string(JSON.stringify({"artifact":data,"failures":failures},"  "))
	var failed: Array=checks.filter(func(c):return not c.passed)
	FileAccess.open(pictures.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty() and failures.is_empty(),"checks":checks,"failed":failed,"export_errors":failures,"scope":"Saved main floor 15 slice through production builders. Actual Void mouse hand, synthetic XRTools pickup API, original prefab geometry and independent part placement. Headset untested; no electrical trap or shaft change."},"  "))
	host.queue_free();await ticks(8);quit(0 if failed.is_empty() and failures.is_empty() else 1)
