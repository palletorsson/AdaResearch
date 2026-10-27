extends "res://commons/void/trials/fractals/probe.gd"
## Transfer acceptance: the original algorithms and their actual mouse/XR controls.

func start(use_xr: bool) -> void:
	xr=use_xr
	if xr:
		head=tracker("head",XRServer.TRACKER_HEAD,"default",Vector3(0,1.65,0))
		left=tracker("left_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(-.3,1.2,-.4))
		right=tracker("right_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO);right.set_input("primary",Vector2.ZERO)
		right.set_input("trigger_click",false);right.set_input("grip",0.0)
	game=load("res://commons/void/trials/softbodies/trial.tscn").instantiate()
	game.force_xr=xr;root.add_child(game);current_scene=game
	if not xr:game.body.scripted_input=true
	await frames(45);game.scene_loaded();game.scene_visible();await frames(30)
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
		if arg=="--capture":take_photos=true
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated saves",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed:quit(1);return
	for use_xr in [false,true]:await visit_soft(use_xr)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Original deformation and cloth controls through desktop mouse and synthetic tracked XR. Native Mobile renderer, shaft descent, residency, relocation and retry. No physical headset test."},"\t"))
	print("SOFT_TRANSFER_RESULT ",checks.size()," failures: ",failed)
	quit(0 if failed.is_empty() else 1)

func photo(filename: String, at: Vector3, target: Vector3) -> void:
	if not take_photos:return
	for layer in game.find_children("*","CanvasLayer",true,false):
		if layer.get_viewport()==game.get_viewport():layer.hide()
	game.status.hide();game.notice_time=-1
	var before:Vector3=game.body.global_position
	game.place_player(Vector3(-18,game.building.spec.levels[level]+.06,13));await frames(4)
	var origin:Node3D=game.get_node("XROrigin3D");origin.hide()
	root.msaa_3d=Viewport.MSAA_4X
	await photograph(filename,at,target)
	origin.show();game.place_player(before);await frames(4)

func pins(soft: SoftBody3D) -> int:
	return (soft.get("pinned_points") as Array).size()

func visit_soft(use_xr: bool) -> void:
	level=1;await start(use_xr);await frames(60)
	var tag := "XR: " if xr else "Desktop: "
	check(tag+"safe start",game.checkpoint==1 and game.body.is_on_floor())
	check(tag+"seven opening placements",game.building.content.exhibits.keys().filter(func(k):return str(k).begins_with("1/")).size()==7)
	for x in [-10,10]:check(tag+"shaft %d open"%x,ray(Vector3(x,-5,0),Vector3(x,-6.5,0)).is_empty())
	var desk:Node3D=artifact("soft_workshop_console")
	check(tag+"deformation desk finds original pair",desk.ready_for_input and desk.model==artifact("jelly_cube") and desk.other==artifact("softmill"))
	if not desk.ready_for_input:game.queue_free();await frames(10);return
	var jelly:Node3D=desk.model
	var mill:Node3D=desk.other
	var sphere:SoftBody3D=mill.get_node("SphereSoftBody08")
	var sphere_at:Vector3=sphere.get_point_transform(1047)
	check(tag+"mill sphere stays on its floor",sphere_at.y>-6 and sphere_at.y<-.36)
	check(tag+"inherited body keeps original pin",sphere.is_point_pinned(1047))
	game.place_player(desk.to_global(Vector3(0,.06,3.1)));await frames(15)
	await press(desk.buttons["STIFFNESS"])
	check(tag+"STIFFNESS reaches original jelly",is_equal_approx(jelly.stiffness,.1))
	await press(desk.buttons["DAMPING"])
	check(tag+"DAMPING reaches original jelly",is_equal_approx(jelly.damping,.05))
	await press(desk.buttons["PRESSURE"])
	check(tag+"PRESSURE reaches original jelly",is_zero_approx(jelly.pressure))
	await press(desk.buttons["MILL"])
	check(tag+"MILL holds scripted drive",desk.drive_held)
	await press(desk.buttons["MILL"])
	check(tag+"MILL resumes scripted drive",not desk.drive_held)
	await press(desk.buttons["RULE"])
	check(tag+"original RULE available",desk.rule_card.visible)
	await press(desk.buttons["RULE"])
	await press(desk.buttons["RESET"])
	check(tag+"RESET keeps bound original body",is_instance_valid(desk.model))
	if not xr:
		await photo("01-deformation",Vector3(12,-2,12),Vector3(3,-4,3))
		await photo("02-mill-and-skin",Vector3(-9,-3.5,7),Vector3(-4,-4,0))
	game.place_player(Vector3(-8.3,-5.94,-1.9));await frames(140);level=2
	check(tag+"shaft descent reaches cloth",game.checkpoint==2 and game.body.is_on_floor())
	check(tag+"deformation floor scripts sleep",not desk.can_process() and not mill.can_process())
	check(tag+"five cloth placements",game.building.content.exhibits.keys().filter(func(k):return str(k).begins_with("2/")).size()==5)
	var cloth:Node3D=artifact("soft_workshop_console")
	check(tag+"cloth desk finds original pair",cloth.ready_for_input and cloth.model==artifact("cloth_straps") and cloth.other==artifact("softstopscene"))
	if not cloth.ready_for_input:game.queue_free();await frames(10);return
	var strips:Array=cloth._bodies(cloth.model)
	check(tag+"eight original strap bodies",strips.size()==8)
	var start_pins:int=pins(strips[0])
	check(tag+"top row pinned initially",start_pins>2)
	game.place_player(cloth.to_global(Vector3(0,.06,3.1)));await frames(15)
	await press(cloth.buttons["PINS"])
	check(tag+"PINS switches row to corners",cloth.pin_mode==1 and pins(strips[0])==2)
	await press(cloth.buttons["SUPPORT"])
	check(tag+"SUPPORT changes frame without pinning",cloth.model.suspension=="none" and pins(strips[0])==2)
	await press(cloth.buttons["STIFFNESS"])
	check(tag+"STIFFNESS changes actual soft body",is_equal_approx(strips[0].linear_stiffness,.1))
	await press(cloth.buttons["RELEASE"])
	check(tag+"RELEASE frees cloth points",cloth.pin_mode==2 and pins(strips[0])==0)
	await press(cloth.buttons["REBUILD"])
	strips=cloth._bodies(cloth.model)
	check(tag+"REBUILD restores row-pinned strips",strips.size()==8 and cloth.pin_mode==0 and pins(strips[0])==start_pins)
	await press(cloth.buttons["LANDING"])
	check(tag+"LANDING selects pan",cloth.other.landing=="pan")
	var stops:Array=cloth._bodies(cloth.other)
	for n in stops:print("STOP_POINT ",n.get_point_transform(100))
	check(tag+"four rebuilt stop bodies remain below roof",stops.size()==4 and stops.all(func(n):return n.get_point_transform(100).y>-12.1 and n.get_point_transform(100).y<-6))
	var film:Node3D=artifact("film_cloth_relations")
	check(tag+"film retains independent world",film.stage!=null and film.viewport.own_world_3d and film.screen.material_override.albedo_texture!=null)
	check(tag+"visitor camera retained",game.get_viewport().get_camera_3d()==game.camera)
	# A relocated console remains bound to the floor's pair.
	var mount:Node3D=cloth.get_parent();var saved:Transform3D=mount.transform
	mount.position.x-=1;mount.rotation_degrees.y+=90;await frames(5)
	game.place_player(cloth.to_global(Vector3(0,.06,3.1)));await frames(15)
	await press(cloth.buttons["SUPPORT"])
	check(tag+"turned and moved console works",cloth.model.suspension=="hoop")
	mount.transform=saved;await frames(5)
	if not xr:
		await photo("03-cloth-and-console",Vector3(13,-8.5,14),Vector3(7,-10,5))
		await photo("04-tension-and-stops",Vector3(-13,-7.5,10),Vector3(-1,-10,-4))
	game.place_player(Vector3(0,-11.94,12));game.die("Transfer retry");await frames(150)
	check(tag+"retry restores second lesson",game.checkpoint==2 and not game.recovering and artifact("soft_workshop_console").ready_for_input and artifact("softstopscene").landing=="rail")
	game.queue_free();await frames(10)
	if xr:
		for item in [head,left,right]:XRServer.remove_tracker(item)

