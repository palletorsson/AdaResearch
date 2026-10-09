extends "res://tools/probes/transformation_encounters.gd"
const Journey = preload("res://tools/probes/array_entered_address.gd")
var office: Node3D
var actor: CharacterBody3D
var driver: Journey.KeyJourney
var complete := false
var routes: Array = []

func travel(point: Vector3, limit := 7000) -> bool:
	driver.target = office.to_global(point)
	driver.arrived = false
	driver.moving = true
	var started := Time.get_ticks_msec()
	while not driver.arrived and Time.get_ticks_msec()-started < limit:
		await physics_frame
		# The museum advances in fixed movement steps. Accept a 15 cm landing
		# radius instead of oscillating around the driver's 11 cm threshold.
		var delta := driver.target-actor.global_position
		if Vector2(delta.x,delta.z).length()<0.15 and absf(delta.y)<0.12:
			driver.arrived=true
	driver.moving = false
	driver.release()
	# Let the release reach the ordinary input map before the next key press.
	await create_timer(0.08).timeout
	routes.append({"glass":office.glass_visible,"target":xyz(point),"reached":xyz(office.to_local(actor.global_position)),"arrived":driver.arrived})
	return driver.arrived

func press() -> void:
	var area: Node3D = office.glass_button.get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(camera,area,area.global_position)
	XRToolsPointerEvent.released(camera,area,area.global_position)
	await create_timer(0.1).timeout

func shot(title: String, eye: Vector3, aim: Vector3, fov := 70.0) -> void:
	await snapshot(title,office.to_global(eye),office.to_global(aim),fov)

func landing_checks() -> void:
	root.content_scale_size = Vector2i(1600,1000)
	root.size = Vector2i(1600,1000)
	var grid := hall.get_node_or_null("SimGrid_Color_Walls")
	check("authored Color_Walls grid present",grid!=null)
	if grid==null:return
	for i in 3600:
		if grid.has_meta("stage_grid_ready"):break
		await process_frame
	office = find_scene("/color_constellation_office.gd")
	check("office and the two colour benches remain in the museum",office!=null and find_scene("/gradient_interpolator.gd")!=null and find_scene("/color_space_navigator.gd")!=null)
	if office==null:return
	observations["office_world"] = xyz(office.global_position)
	observations["materials"] = office.office_panes.map(func(p):return {"colour":str(p.material_override.albedo_color),"shading":p.material_override.shading_mode,"fog_disabled":p.material_override.disable_fog})
	await shot("arrival-glass",Vector3(0.65,1.65,-7.1),Vector3(0,1.65,3.0),72)
	if str(office.get_meta("config_layout","")) != "planes":
		check("baseline records the former forty-pane office",office.office_panes.size()==40)
		complete=true
		return
	check("new layout has twelve independent panes",office.open_office and office.office_panes.size()==12)
	check("office remains at floor level",absf(office.global_position.y)<0.02)
	check("three furnished positions remain",office.find_children("Workstation*","Node3D",false,false).size()==3)
	var poses: Array = []
	var bodies: Array = []
	var colours: Array = []
	for pane in office.office_panes:
		poses.append(pane.global_transform)
		bodies.append(pane.get_child(0).get_rid())
		colours.append(pane.material_override.albedo_color)
	check("one quad per filter, avoiding doubled box-face blending",office.office_panes.all(func(p):return p.mesh is QuadMesh and p.material_override.cull_mode==BaseMaterial3D.CULL_DISABLED))
	check("filters layer translucent colour once",office.office_panes.all(func(p):return p.material_override.blend_mode==BaseMaterial3D.BLEND_MODE_MIX and is_equal_approx(p.material_override.albedo_color.a,0.52) and p.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF))
	check("filter coefficients stay unshaded and do not fog the view twice",office.office_panes.all(func(p):return p.material_override.shading_mode==BaseMaterial3D.SHADING_MODE_UNSHADED and p.material_override.disable_fog))
	check("angled edge screens interrupt the orthogonal pattern",office.office_panes.any(func(p):return not is_zero_approx(fposmod(p.rotation_degrees.y,90))))
	await shot("layers-glass",Vector3(-0.7,1.65,-4.6),Vector3(0.0,1.65,3.6),72)
	await shot("across-glass",Vector3(-3.7,1.65,-3.8),Vector3(2.8,1.65,2.5),76)
	await shot("back-glass",Vector3(-0.2,1.65,6.7),Vector3(0,1.65,-4.5),76)
	await shot("plan-oblique",Vector3(4.8,3.8,-7),Vector3(0,1.2,0.7),72)
	actor = museum.get("_player")
	museum.set("_dollhouse",false)
	driver = Journey.KeyJourney.new()
	driver.world = museum
	driver.actor = actor
	driver.view = museum.get("_cam")
	root.add_child(driver)
	var route := [Vector3(0,0.05,-3),Vector3(1.2,0.05,-3),Vector3(1.2,0.05,-0.8),Vector3(-1.2,0.05,-0.8),Vector3(-1.2,0.05,1.8),Vector3(1.2,0.05,1.8),Vector3(1.2,0.05,4.7),Vector3(-0.2,0.05,4.7),Vector3(-0.2,0.05,6.8),Vector3(-0.2,0.05,8.5)]
	for mode in 2:
		var label := "glass" if mode==0 else "opaque"
		actor.global_position = office.to_global(Vector3(0,0.05,-7.1))
		actor.velocity = Vector3.ZERO
		for i in route.size():
			if not await travel(route[i]):
				check(label+" route leg "+str(i),false)
				break
			check(label+" route leg "+str(i),true)
		# Approach the middle of the magenta sheet with the ordinary controller.
		actor.global_position = office.to_global(Vector3(-1.1,0.05,-3))
		actor.velocity = Vector3.ZERO
		var passed := await travel(Vector3(-1.1,0.05,-1),1200)
		check(label+" pane stops the ordinary body",not passed and office.to_local(actor.global_position).z < -1.9)
		await press()
		check(label+" pointer event changes surface mode",office.glass_visible==(mode==1))
		if mode==0:
			actor.global_position = office.to_global(Vector3(-10,0.05,-10))
			await shot("arrival-opaque",Vector3(0.65,1.65,-7.1),Vector3(0,1.65,3.0),72)
			await shot("layers-opaque",Vector3(-0.7,1.65,-4.6),Vector3(0.0,1.65,3.6),72)
			check("opaque mode uses solid material and normal blend",office.office_panes.all(func(p):return p.material_override.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED and p.material_override.blend_mode==BaseMaterial3D.BLEND_MODE_MIX))
	var same := true
	for i in poses.size():
		same = same and office.office_panes[i].global_transform.is_equal_approx(poses[i]) and office.office_panes[i].get_child(0).get_rid()==bodies[i] and office.office_panes[i].material_override.albedo_color.is_equal_approx(colours[i])
	check("two switches preserve every collider, pane transform and colour",same and office.glass_visible)
	var ids: Array = []
	for p in office.office_panes:ids.append(p.get_instance_id())
	office.apply_grid_config({"emissive":false,"layout":"planes"})
	check("reapplying placement config does not rebuild",ids==office.office_panes.map(func(p):return p.get_instance_id()))
	var legacy: Node3D = load("res://algorithms/color/color_mixing/color_constellation_office.gd").new()
	legacy.position = Vector3(1000,0,1000)
	root.add_child(legacy)
	check("unconfigured placements retain the eighteen-pane installation",not legacy.open_office and not legacy.cubicle_office and legacy.find_children("*","MeshInstance3D",false,false).size()==18)
	legacy.queue_free()
	var cubicles: Node3D = load("res://algorithms/color/color_mixing/color_constellation_office.gd").new()
	cubicles.set_meta("config_layout","cubicles")
	cubicles.position = Vector3(1000,0,1000)
	root.add_child(cubicles)
	check("old cubicle option remains available",cubicles.cubicle_office and cubicles.office_panes.size()==40)
	cubicles.queue_free()
	observations["routes"] = routes
	complete = true

func finish() -> void:
	if driver!=null:
		driver.release()
		driver.set_physics_process(false)
	check("inspection completed",complete)
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Actual isolated production museum and ordinary controller; supplied pointer events. Native interior cameras. No headset or learner trial."},"  "))
	print("OPEN COLOUR ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
