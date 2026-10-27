extends "res://tools/probes/export_void_editor.gd"
## Real saved floor slice, desktop mouse drags, synthetic XRTools pickup API,
## real CharacterBody support. No headset or whole-tower acceptance claim.
var checks: Array=[]
var host: Node3D
var artifact: Node3D
var mechanism: Node3D
var camera: Camera3D
var pictures := ""

func check(title: String, passed: bool) -> void:
	checks.append({"name":title,"passed":passed});print("[pivot] ","PASS " if passed else "FAIL ",title)

func ticks(count:=5) -> void:
	for i in count: await physics_frame;await process_frame

func shot(title: String, eye: Vector3, target: Vector3) -> void:
	camera.global_position=artifact.to_global(eye);camera.look_at(artifact.to_global(target));camera.make_current()
	await ticks(4);await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	check("native screenshot / "+title,not image.is_empty() and image.save_png(pictures.path_join(title+".png"))==OK)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--pictures="):pictures=arg.trim_prefix("--pictures=")
	DirAccess.make_dir_recursive_absolute(out);DirAccess.make_dir_recursive_absolute(pictures)
	host=Node3D.new();host.name="PivotFloorReview";root.add_child(host);current_scene=host
	var world:=WorldEnvironment.new();var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("b7b7c0")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color.WHITE;env.ambient_light_energy=.65
	world.environment=env;host.add_child(world)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-45,-35,0);sun.light_energy=1.6;sun.shadow_enabled=true;host.add_child(sun)
	var building: Node3D=load("res://tools/probes/pivot_floor_slice.gd").new();host.add_child(building)
	artifact=building.content.exhibits["15/movable-pivot"].get_node("Artifact");mechanism=artifact.mechanism
	camera=Camera3D.new();camera.fov=57;host.add_child(camera)
	await ticks(10)
	check("production registry and saved floor 15 instantiate the new kit",artifact.global_position.is_equal_approx(Vector3(0,-90,-5.4)))
	check("independent editable mechanism, three landings and ramp",artifact.part_defaults.size()==6 and artifact.part_defaults.has("EntryRamp") and artifact.part_defaults.has("PivotWalkway"))
	# Fixed point: a deck material coordinate at the bearing stays on its axle.
	for p in [-1.5,0,1.5]:
		mechanism.configure(p,18)
		var fixed: Vector3=mechanism.deck.transform*Vector3(p,0,0)
		check("bearing remains fixed under rotation at %.1f m"%p,fixed.distance_to(Vector3(p,.64,0))<.0001)
	mechanism.configure(0,18);var central: Vector3=mechanism.deck.position
	await shot("01-central-pivot",Vector3(6.8,4.7,7.5),Vector3(-.4,.45,0))
	mechanism.configure(1.5,18)
	check("same angle has a different deck trajectory with an end pivot",mechanism.deck.position.distance_to(central)>.4)
	await shot("02-offset-pivot",Vector3(6.8,4.7,7.5),Vector3(-.4,.45,0))
	await shot("03-bearing-and-grips",Vector3(3.7,2.5,4.2),Vector3(1.0,.55,.4))
	# Desktop events enter the existing player pointer through real mouse input.
	mechanism.configure(0,0)
	var driver: Node=load("res://commons/testing/wcn_desktop_driver.gd").new();host.add_child(driver)
	driver.spawn(artifact.to_global(Vector3(0,0,2.7)),host);await ticks(12)
	var from: Vector3=mechanism.pivot_grip.global_position
	driver.aim_at(from)
	check("actual desktop pointer targets the pivot grip",await driver.hover_target()==mechanism.pivot_grip)
	var drag: Dictionary=await driver.drag(from,from+artifact.global_basis.x*1.1,50);await ticks(55)
	print("PIVOT_DRAG ",drag," target=",mechanism.target_pivot," actual=",mechanism.pivot_x)
	check("mouse drag slides and retains the physical bearing",mechanism.pivot_x>.65 and not is_instance_valid(mechanism.pivot_grip.pointer_owner))
	driver.rig.global_position=artifact.to_global(Vector3(2.5,0,2.7));await ticks(10)
	from=mechanism.turn_grip.global_position;driver.aim_at(from)
	check("actual desktop pointer targets the turning grip",await driver.hover_target()==mechanism.turn_grip)
	var turn: Dictionary=await driver.drag(from,from+artifact.global_basis.z*.65,50);await ticks(60)
	print("TURN_DRAG ",turn," angle=",mechanism.angle_degrees)
	check("mouse end grip rotates the walkable deck",absf(mechanism.angle_degrees)>9)
	driver.queue_free();await ticks(5)
	# Synthetic XR uses the shipped pickup implementation, not a new grab system.
	var origin:=XROrigin3D.new();host.add_child(origin)
	var controller:=XRController3D.new();origin.add_child(controller)
	var pickup: Node3D=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	mechanism.configure(0,0);controller.global_transform=mechanism.pivot_grip.global_transform
	mechanism.pivot_grip.pick_up(pickup);await ticks(4)
	check("synthetic XRTools pickup API holds the bearing",mechanism.pivot_grip.is_picked_up())
	controller.global_position-=artifact.global_basis.x*1.0;await ticks(60)
	check("synthetic held hand slides the constrained bearing",mechanism.pivot_x<-.6)
	mechanism.pivot_grip.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await ticks(5)
	check("XR release retains bearing without a loose falling grip",not mechanism.pivot_grip.is_picked_up() and mechanism.pivot_grip.freeze)
	mechanism.configure(0,0);controller.global_transform=mechanism.turn_grip.global_transform
	mechanism.turn_grip.pick_up(pickup);await ticks(4)
	controller.global_position+=artifact.global_basis.z*.6;await ticks(60)
	check("synthetic held end grip turns the deck",mechanism.angle_degrees < -8)
	mechanism.turn_grip.let_go(pickup,Vector3.ZERO,Vector3.ZERO);origin.queue_free();await ticks(4)
	# Real physics contact on the deck, including incremental platform rotation.
	mechanism.configure(0,0)
	var rider:=CharacterBody3D.new();rider.name="PhysicsVisitor";rider.collision_layer=2;rider.collision_mask=1
	var hit:=CollisionShape3D.new();hit.shape=CapsuleShape3D.new();hit.shape.radius=.2;hit.shape.height=1.5;hit.position.y=.75;rider.add_child(hit);host.add_child(rider)
	rider.global_position=mechanism.to_global(Vector3(1,.76,0))
	for i in 30:rider.velocity=Vector3(0,-2,0);rider.move_and_slide();await ticks(1)
	check("actual CharacterBody stands on matching deck collision",rider.is_on_floor() and absf(mechanism.to_local(rider.global_position).y-.72)<.04)
	mechanism.target_angle=18
	for i in 100:rider.velocity=Vector3(0,-2,0);rider.move_and_slide();await ticks(1)
	var local_rider: Vector3=mechanism.deck.to_local(rider.global_position)
	check("incrementally rotating deck carries its standing visitor",rider.is_on_floor() and absf(local_rider.x-1)<.15 and absf(local_rider.z)<.15)
	rider.queue_free()
	# Moved/rotated negative-floor assembly must retain the same local law.
	var clone: Node3D=load("res://commons/artifacts/movable_pivot/movable_pivot.tscn").instantiate();clone.position=Vector3(16,-102,0);clone.rotation.y=PI/2;host.add_child(clone);clone.mechanism.configure(1.3,21)
	var fixed_world: Vector3=clone.mechanism.deck.to_global(Vector3(1.3,0,0))
	check("moved and rotated copy uses its own local bearing",fixed_world.distance_to(clone.mechanism.to_global(Vector3(1.3,.64,0)))<.0001)
	clone.apply_grid_config({"only_parts":["NearLanding"],"parts":{"NearLanding":{"position":[1,.1,2],"rotation":[0,90,0]}}});await ticks(2)
	check("isolated editor part copy can run without a freed mechanism",clone.part_defaults.size()==1 and clone.get_node("NearLanding").position.is_equal_approx(Vector3(1,.1,2)))
	clone.queue_free();await ticks(3)
	mechanism.configure(0,0)
	await shot("04-floor-15-bay",Vector3(9.4,6.4,10.3),Vector3(-.6,.5,1))
	# Export the actual native geometry through the existing GLB snapshot helper.
	await artifact.prepare_editor_preview()
	var data: Dictionary={"artifact":"movable_pivot_walkway","config":{"pivot_x":0,"angle_degrees":0},"parts":{}}
	for child in artifact.get_children():
		if child is Node3D and artifact.part_defaults.has(str(child.name)):
			var part: Dictionary=snapshot(child,"15-movable-pivot-"+str(child.name))
			part["default"]=artifact.part_defaults[str(child.name)];part["scale"]=[1,1,1];data.parts[str(child.name)]=part
	FileAccess.open(out.path_join("assembly.json"),FileAccess.WRITE).store_string(JSON.stringify({"artifact":data,"failures":failures},"  "))
	var failed: Array=checks.filter(func(c):return not c.passed)
	FileAccess.open(pictures.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty() and failures.is_empty(),"checks":checks,"failed":failed,"export_errors":failures,"scope":"Saved main floor 15 slice, real production builders. Desktop mouse input; XRTools synthetic pickup API; real CharacterBody platform contact. Physical headset and full tower not tested."},"  "))
	host.queue_free();await ticks(8)
	quit(0 if failed.is_empty() and failures.is_empty() else 1)
