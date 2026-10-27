extends "res://commons/void/trials/forces_04/probe.gd"

func press(button: Node3D) -> void:
	if button.has_node("InteractableAreaButton/CollisionShape3D"):
		await super.press(button);return
	var target:Vector3=button.get_children().filter(func(n):return n is CollisionShape3D)[0].global_position
	if not xr:
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED;game.camera.look_at(target);await frames(25)
		await mouse_button(MOUSE_BUTTON_LEFT,true);await mouse_button(MOUSE_BUTTON_LEFT,false)
	else:
		var origin:Node3D=game.get_node("XROrigin3D")
		var pointer:Node3D=game.pointers[1]
		for i in 20:
			var at:Vector3=game.camera.global_position+Vector3(.1,-.2,0)
			var aim:=Basis.looking_at(target-at)
			at-=aim*Vector3(0,pointer.y_offset*XRServer.world_scale,0)
			right.set_pose("aim",Transform3D(origin.global_basis.inverse()*aim,origin.to_local(at)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
			await frames(1)
		right.set_input("trigger_click",true);await frames(6);right.set_input("trigger_click",false);await frames(8)

func focused_checks(tag: String) -> void:
	check(tag+"standard floor "+str(level),game.building.spec.width==42 and game.building.spec.depth==32 and game.building.spec.storey_height==6)
	match level:
		1:await catenary_checks(tag)
		2:await relaxation_checks(tag)
		3:await equilibrium_checks(tag)
		4:await annealing_checks(tag)
	game.place_player(game.spawn_for(level));await frames(15)

func catenary_checks(tag: String) -> void:
	var cable:Node3D=artifact("cable_builder")
	await stand_local(cable,Vector3(-.66,.06,-1.3))
	var p:Node3D=cable.control_points[1]
	var before:Vector3=cable.curve.get_point_position(1)
	await grab_point(tag,p)
	var target:Vector3=p.global_position+Vector3(.5,.4,0)
	if xr:await palm_at(target);await frames(25)
	else:
		game.body.desktop_pointer._hold_distance=game.camera.global_position.distance_to(target)
		game.camera.look_at(target);await frames(30)
	check(tag+"held control reshapes original four-point spline",cable.curve.point_count==4 and cable.curve.get_point_position(1).distance_to(before)>.15 and cable.mesh_instance.mesh!=null)
	await drop_point()
	var film:Node3D=artifact("film_catenoid_sections")
	await stand_local(film,Vector3(0,.06,1.7))
	await press(film.buttons.pause)
	check(tag+"film pause uses actual pointer",not film.stage.running)
	await press(film.buttons.step)
	check(tag+"film retains original analytic catenoid evidence",film.stage.validation().passed and film.viewport.own_world_3d)
	var laundry:Node3D=artifact("laundry_line_cathedral")
	check(tag+"three analytic hanging and mirrored arches",laundry.sags.size()==3 and is_equal_approx(laundry.span,3.2) and laundry._cat_y(0,1)<laundry._cat_y(1.6,1))
	for key in ["catenoid","helicoid"]:
		var body:Node3D=artifact(key)
		check(tag+key+" retains original pickable surface",body.has_method("pick_up") and body.mesh_instance.mesh!=null)

func relaxation_checks(tag: String) -> void:
	var bench:Node3D=artifact("verlet_workbench")
	await stand_local(bench,Vector3(1,.06,1.8))
	await press(bench.buttons.PASSES)
	check(tag+"PASSES changes live cloth budget",bench._sim.constraint_passes==8 and bench.comparison)
	await press(bench.buttons.WIND)
	check(tag+"WIND disables original disturbance",not bench.wind_enabled)
	await press(bench.buttons.WIND)
	await press(bench.buttons.RESET);await frames(25)
	var metrics:Dictionary=bench.comparison_metrics()
	check(tag+"RESET restarts comparison and reports finite errors",bench.simulation_steps>0 and bench.wind_enabled and is_finite(metrics.worst_absolute_percent))
	var film:Node3D=artifact("film_form_relaxation")
	check(tag+"relaxation film remains an independent private world",film.stage!=null and film.viewport.own_world_3d)
	var screen:Node3D=artifact("science_screen")
	check(tag+"screen finds same-floor spring source",screen._tracking_generic==artifact("mass_spring_bench"))

func equilibrium_checks(tag: String) -> void:
	var mobile:Node3D=artifact("calder_mobile")
	check(tag+"original mobile reports static moment model",mobile._n_leaves>1 and mobile._total_mass>0 and "no dynamic solver" in mobile._plaque.text.to_lower())
	var triangle:Node3D=artifact("tensegrity_triangle")
	var old:float=triangle._phase;await frames(25)
	check(tag+"original triangle retains prescribed pulse",triangle._built and triangle._phase>old and triangle.scale.y<=1.0)
	var screen:Node3D=artifact("science_screen")
	await frames(100)
	check(tag+"screen stays scoped to truss on same floor",screen._tracking_generic==artifact("fractal_truss_tower"))

func annealing_checks(tag: String) -> void:
	var basin:Node3D=artifact("max_q_basin_room")
	await stand_local(basin,Vector3(1.6,.06,4.2))
	check(tag+"basin starts with interpretation withheld",not basin._interpretation_visible and is_equal_approx(basin.floor_size,4.9))
	await press(basin._interpretation_button)
	check(tag+"INTERPRET reveals original qualification",basin._interpretation_visible and "not a test of life" in basin._interpretation_title.text)
	await press(basin._interpretation_button)
	check(tag+"interpretation can be hidden again",not basin._interpretation_visible)
	var anneal:Node3D=artifact("simulated_annealing")
	await stand_local(anneal,Vector3(0,.06,1.6))
	await press(anneal._control_panel.find_child("Btn_0",true,false));await frames(30)
	check(tag+"RESET starts original annealing search",anneal._is_running and anneal.current_iteration>0 and is_finite(anneal.current_energy))
	var old:Vector2=anneal.current_solution
	await press(anneal._control_panel.find_child("Btn_1",true,false));await frames(10)
	check(tag+"HOP changes search location",anneal.current_solution.distance_to(old)>.01)
	check(tag+"basin retains live 27-point lattice",basin._sim.positions.size()==27 and basin._live_mm.instance_count==27)

func capture_floor() -> void:
	var y:float=game.building.spec.levels[level]
	if level==1:
		await photo("01-catenary",Vector3(8,y+3.4,12),Vector3(-1,y+1,3))
		await photo("02-laundry-arches",Vector3(3,y+2.5,-5),Vector3(0,y+1.7,-9))
	elif level==2:await photo("03-relaxation",Vector3(-4,y+2.5,4),Vector3(0,y+1,0))
	elif level==3:await photo("04-equilibrium",Vector3(3,y+3.4,13),Vector3(-5,y+2,8))
	else:
		await photo("05-annealing",Vector3(-13,y+3,13),Vector3(-5,y+1,9))
		await photo("06-two-wells",Vector3(-1,y+3.7,5),Vector3(-4,y+1,10))
