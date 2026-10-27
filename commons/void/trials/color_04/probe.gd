extends "res://tools/probes/void_transfer_probe.gd"

func focused_checks(tag: String) -> void:
	check(tag+"standard 42 x 32 x 6 tower retained",game.building.spec.width==42 and game.building.spec.depth==32 and game.building.spec.storey_height==6)
	for i in 6: await frames(1)
	if level==1: await paint_checks(tag)
	else: await walls_checks(tag)

func mouse_button(button: int, down: bool) -> void:
	var e:=InputEventMouseButton.new(); e.button_index=button; e.pressed=down
	Input.parse_input_event(e)
	for i in 8: await frames(1)

func paint_checks(tag: String) -> void:
	var gallery: Node3D=artifact("albers_wall_gallery")
	check(tag+"all 98 source Albers canvases retained",gallery.find_children("Canvas_*","Node3D",false,false).size()==98 and gallery.columns==14 and gallery.rows==7)
	var painting: Node3D=artifact("ball_painting_demo")
	var cans: Node3D=painting.get_node("PaintBalls")
	check(tag+"original spray setup has thirty cans and autonomous brush",painting.automated and painting.spray_mode and cans.get_child_count()==30)
	var strokes: int=painting.strokes
	for i in 20: await frames(1)
	check(tag+"machine spray advances on original GPU surface",painting.strokes>strokes and painting.surface.viewport.get_texture()!=null)
	# Pause only the automatic brush in this fixture, so the next deposit is the hand's.
	painting.set_process(false)
	var can: RigidBody3D=cans.get_node("SprayCan_23")
	var dock: Transform3D=can.global_transform
	await approach(painting,2.7)
	if xr:
		for i in 20: hand_at(right,can.global_position); await frames(1)
		right.set_input("grip",1.0)
		for i in 15: await frames(1)
	else:
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
		game.camera.look_at(can.global_position)
		for i in 15: await frames(1)
		await mouse_button(MOUSE_BUTTON_RIGHT,true); await mouse_button(MOUSE_BUTTON_RIGHT,false)
	check(tag+"actual grip picks up a source spray can",can.is_picked_up() if xr else game.body.desktop_pointer._held==can)
	if xr:
		for i in 20:
			hand_at(right,painting.to_global(Vector3(0,1.2,.6))); await frames(1)
		right.set_input("trigger",1.0); right.set_input("trigger_click",true)
	else:
		game.camera.look_at(painting.to_global(Vector3(0,1.3,-.5)))
		await mouse_button(MOUSE_BUTTON_LEFT,true)
	for i in 35: await frames(1)
	check(tag+"held trigger paints the canvas with the original nozzle",can.painted_samples>0 and can.paper_surface==painting.surface and can.is_spraying)
	if xr: right.set_input("trigger_click",false); right.set_input("trigger",0.0)
	else: await mouse_button(MOUSE_BUTTON_LEFT,false)
	for i in 10: await frames(1)
	check(tag+"release stops aerosol and sound",not can.is_spraying and not can.hiss.playing)
	if xr: right.set_input("grip",0.0)
	else: await mouse_button(MOUSE_BUTTON_RIGHT,true); await mouse_button(MOUSE_BUTTON_RIGHT,false)
	for i in 15: await frames(1)
	check(tag+"drop returns spray can to its placed dock",can.global_transform.is_equal_approx(dock) and can.freeze)
	check(tag+"dropped can remains on the shared pickup layer",can.get_collision_layer_value(3) and (can.original_collision_layer & 4)!=0)
	painting.set_process(true)
	game.place_player(game.spawn_for(1)); await frames(12)

func point_press(parent: Node3D) -> void:
	# The source film/study buttons expose pointer_event on a StaticBody.
	var proxy:=Node3D.new(); parent.add_child(proxy)
	var area:=Node3D.new(); area.name="InteractableAreaButton"; proxy.add_child(area)
	var target:=Node3D.new(); target.name="CollisionShape3D"; area.add_child(target)
	await press(proxy); proxy.queue_free()

func walls_checks(tag: String) -> void:
	var office: Node3D=artifact("color_constellation_office")
	check(tag+"twelve original filtering panes",office.open_office and office.office_panes.size()==12)
	var pane: MeshInstance3D=office.office_panes[0]
	var pane_before: Transform3D=pane.global_transform
	await approach(office.get_node("VisibilityConsole"),1.3)
	await press(office.glass_button)
	check(tag+"FILTER toggles opacity through actual pointer without moving panes",not office.glass_visible and pane.global_transform==pane_before and pane.has_node("PaneBody"))
	await press(office.glass_button)
	check(tag+"filter mode returns with same collision",office.glass_visible)
	var gradient: Node3D=artifact("gradient_interpolator")
	await approach(gradient,1.7)
	var middle: Color=gradient._cubes[8].material_override.albedo_color
	await press(gradient.comparison_controls[2])
	check(tag+"RGB HSV button changes the path between fixed endpoints",gradient._mode_hsv and gradient._cubes[8].material_override.albedo_color!=middle and gradient._color_a_idx==0 and gradient._color_b_idx==5)
	await press(gradient.comparison_controls[0]); await press(gradient.comparison_controls[1])
	check(tag+"both endpoint colour buttons work",gradient._color_a_idx==1 and gradient._color_b_idx==6)
	var model: Node3D=artifact("color_space_navigator")
	check(tag+"original RGB and HSV models each retain 500 samples",model._sample_multimesh.multimesh.instance_count==500 and model._hsl_sample_multimesh.multimesh.instance_count==500)
	var pixel: Node3D=artifact("subpixel_display")
	var slider: Node3D=pixel.get_node("SUBPIXEL/Param_0")
	slider.set_normalized_value(.25); slider.slider_moved.emit(.25)
	check(tag+"subpixel slider API changes red channel and combined swatch",is_equal_approx(pixel._r,.25) and is_equal_approx(pixel._combined_mat.albedo_color.r,.25))
	var tunnel: Node3D=artifact("rainbow_hallway")
	check(tag+"original eight-segment tapered CSG tunnel retained",tunnel.num_segments==8 and tunnel.start_radius==4 and tunnel.end_radius==1.5 and tunnel.shader_material!=null)
	var assembly: Node3D=artifact("colour_assembly")
	check(tag+"twelve original assembly panels",assembly.specimen.panels.size()==12)
	await approach(assembly,assembly.console_z+1.5)
	await point_press(assembly.controls[1])
	check(tag+"SCREENS button rearranges the original panels",assembly.specimen.arrangement==1)
	await point_press(assembly.controls[3])
	check(tag+"assembly COLOUR preserves arrangement",assembly.specimen.colour_rule==1 and assembly.specimen.arrangement==1)
	await point_press(assembly.controls[4])
	check(tag+"assembly RESET restores canopy",assembly.specimen.arrangement==0 and assembly.specimen.colour_rule==0)
	var wall: Node3D=artifact("colour_wall_studies")
	await approach(wall,wall.console_z+1.5)
	var spacing: float=wall.specimen.spacing
	await point_press(wall.controls[0]); await point_press(wall.controls[2])
	check(tag+"wall spacing and omission controls work",wall.specimen.spacing!=spacing and wall.specimen.omitted)
	await point_press(wall.controls[4])
	check(tag+"wall reset restores source members",not wall.specimen.omitted and is_equal_approx(wall.specimen.spacing,spacing))
	var film: Node3D=artifact("film_gradient_paths")
	await approach(film,1.8); await point_press(film.buttons["pause"])
	check(tag+"original gradient film pauses by pointer",not film.stage.running)
	await point_press(film.buttons["pause"])
	check(tag+"original gradient film resumes",film.stage.running)
	game.place_player(game.spawn_for(2)); await frames(12)

func capture_floor() -> void:
	if level==1:
		var gallery: Node3D=artifact("albers_wall_gallery")
		await photo("01-albers-gallery",gallery.to_global(Vector3(-2,2.9,7.5)),gallery.to_global(Vector3(0,2,0)))
		var painting: Node3D=artifact("ball_painting_demo")
		await photo("02-spray-paint",painting.to_global(Vector3(2.8,2.3,5.0)),painting.to_global(Vector3(0,1.1,0)))
	else:
		var office: Node3D=artifact("color_constellation_office")
		await photo("03-filtering-planes",office.to_global(Vector3(1.5,2.2,-10)),office.to_global(Vector3(0,1.7,2)))
		var wall: Node3D=artifact("colour_wall_studies")
		await photo("04-wall-studies",wall.to_global(Vector3(-4,3.3,6)),wall.to_global(Vector3(0,2,-3.8)))
