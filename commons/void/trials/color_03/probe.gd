extends "res://tools/probes/void_transfer_probe.gd"

func focused_checks(tag: String) -> void:
	check(tag+"standard 42 x 32 x 6 tower retained",game.building.spec.width==42 and game.building.spec.depth==32 and game.building.spec.storey_height==6)
	for i in 6: await frames(1)
	if level==1: await pillar_checks(tag)
	else: await grid_checks(tag)

func mouse_grip() -> void:
	var e:=InputEventMouseButton.new(); e.button_index=MOUSE_BUTTON_RIGHT; e.pressed=true
	Input.parse_input_event(e); await frames(8)
	e=InputEventMouseButton.new(); e.button_index=MOUSE_BUTTON_RIGHT; e.pressed=false
	Input.parse_input_event(e); await frames(8)

func pillar_checks(tag: String) -> void:
	var field: Node3D=artifact("pillarcolorcollection")
	check(tag+"35 source colour pillars and neutral reference",field.spatial_gradient and field.columns==5 and field.rows==7 and field.find_children("Pillar_*","Node3D",false,false).size()==35 and field.has_node("NeutralValueReference"))
	var sample: RigidBody3D=field.sampler
	var arrival: Vector3=sample.global_position+Vector3(0,0,1.3)
	arrival.y=game.building.spec.levels[level]+.06
	game.place_player(arrival); await frames(20)
	var before: Vector3=sample.global_position
	if xr:
		for i in 20:
			hand_at(right,sample.global_position); await frames(1)
		print("SAMPLER_CONTACT ",game.pickups[1].closest_object," target ",sample," at ",sample.global_position," hand ",game.pickups[1].global_position)
		right.set_input("grip",1.0)
		for i in 15: await frames(1)
	else:
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED; game.camera.look_at(before); await frames(15); await mouse_grip()
	check(tag+"actual grip picks up the original field sampler",sample.is_picked_up() if xr else game.body.desktop_pointer._held==sample)
	var initial_value: float=sample.sampled_hsv.z
	if xr: hand_at(right,before+Vector3(.2,.35,.1))
	else: game.camera.rotate_x(.15)
	for i in 12: await frames(1)
	check(tag+"hand height changes value and field marker",absf(sample.sampled_hsv.z-initial_value)>.02 and field.sample_marker.position.is_equal_approx(sample.field_point))
	check(tag+"readout and colour match local HSV field below zero",sample.sampled_rgb.is_equal_approx(field.sample_volume(sample.field_point)) and sample._readout.text.contains("HSV"))
	if xr: right.set_input("grip",0.0); await frames(12)
	else: await mouse_grip()
	var atlas: Node3D=artifact("color_sets_overview")
	check(tag+"twelve original named palettes with 144 pickups",atlas.wall_mount and atlas.structure=="named" and atlas.find_children("*","RigidBody3D",true,false).size()==144)
	var mix: Node3D=artifact("visual_color_mixing")
	check(tag+"original comparison bench retains eighteen disks",mix.mixture=="bench" and mix.find_children("*","RigidBody3D",true,false).size()==18)
	var spectrum: Node3D=artifact("SpectrumVisualizer")
	var t: float=spectrum.time
	for i in 10: await frames(1)
	check(tag+"original wavelength animation advances with magenta seam",spectrum._dots.size()==60 and spectrum._magenta_dots.size()==20 and spectrum.time>t)
	await film_check(tag,"film_colour_edge")
	game.place_player(game.spawn_for(1)); await frames(12)

func point_press(parent: Node3D) -> void:
	var proxy:=Node3D.new(); parent.add_child(proxy)
	var area:=Node3D.new(); area.name="InteractableAreaButton"; proxy.add_child(area)
	var target:=Node3D.new(); target.name="CollisionShape3D"; area.add_child(target)
	await press(proxy); proxy.queue_free()

func film_check(tag: String, key: String) -> void:
	var monitor: Node3D=artifact(key)
	await approach(monitor,1.8); await point_press(monitor.buttons["pause"])
	check(tag+key+" pauses by actual pointer",not monitor.stage.running)
	await point_press(monitor.buttons["pause"])
	check(tag+key+" resumes by actual pointer",monitor.stage.running)

func grid_checks(tag: String) -> void:
	var wrapper: Node3D=artifact("gridcolorizer")
	var lesson: Node3D=wrapper.source.address_lesson
	for i in 30:
		if lesson.ready_for_input: break
		await frames(1)
	check(tag+"original address lesson binds to local floor grid",lesson.ready_for_input and lesson.cells.size()>250 and wrapper.source.grid_structure==wrapper.grid)
	if not lesson.ready_for_input: return
	var mesh: MultiMesh=wrapper.source.multimesh
	var index: int=lesson.cells[lesson.selected]
	var before: Color=mesh.get_instance_color(index)
	var transform_before: Transform3D=mesh.get_instance_transform(index)
	await approach(lesson.get_node("AddressConsole"),1.4)
	await press(lesson.buttons[2])
	check(tag+"COLOUR writes one addressed cell without moving it",mesh.get_instance_color(index)!=before and mesh.get_instance_transform(index)==transform_before and lesson.swatch.material_override.albedo_color.is_equal_approx(mesh.get_instance_color(index)))
	var address: Vector2i=lesson.selected
	await press(lesson.buttons[0]); await press(lesson.buttons[1])
	check(tag+"X and Z select another address while stored colour remains",lesson.selected!=address and mesh.get_instance_color(index)!=before)
	await press(lesson.buttons[3])
	check(tag+"RULE restores palette mapping at the old address",mesh.get_instance_color(index).is_equal_approx(before))
	await press(lesson.buttons[4])
	check(tag+"PALETTE changes the rule palette",lesson.palette_index==1)
	check(tag+"grid overlay leaves both fixed shaft openings clear",wrapper.grid.cube_positions.all(func(c):return wrapper._over_slab(wrapper.frame.to_global(Vector3(c.x,-.49,c.z)),game)))
	check(tag+"original spectrum forest keeps authored scale",is_equal_approx(artifact("spectrum_forest").scale.x,.22))
	await film_check(tag,"film_foundation_class")
	game.place_player(game.spawn_for(2)); await frames(12)

func capture_floor() -> void:
	if level==1:
		await photo("01-colour-field",Vector3(3,-2,13),Vector3(0,-4,-5))
		await photo("02-palette-wall",Vector3(10,-3.6,3),Vector3(15,-4.8,9))
	else:
		var wrapper: Node3D=artifact("gridcolorizer")
		await photo("03-addressed-floor",wrapper.to_global(Vector3(6,4.5,11)),wrapper.to_global(Vector3(0,.2,-2)))
		await photo("04-original-console",wrapper.to_global(Vector3(2,2.2,13)),wrapper.to_global(Vector3(1,1.1,10)))
