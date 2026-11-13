extends "res://tools/probes/void_transfer_probe.gd"
## The actual desktop game, pointer and sliders. No synthetic signal acceptance.
const Live = preload("res://commons/modular/sphere_fractal_live.tscn")

func run() -> void:
	trial="spatial_lab_ca573ae619"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	await start(false)
	var item: Node3D=station("variation")
	var controls: Node3D=station("fractal-controls")
	check("separate control stand binds its own editable study",controls.target==item)
	check("saved depth creates 156 independent objects",item._members.size()==156)
	var stage: Node3D=station("fractal-stage")
	check("ten staging boards and blocks remain independently editable",stage.part_defaults.size()==10)
	check("ivory terminal material is a local override",item.get_node("Root_1_1_1/Source/FittedVisual").get_child(0).material_override.albedo_color.is_equal_approx(Color("eee8dc")))
	check("generation two uses pink instead of its source traffic pattern",item.get_node("Root_1_1/Source/FittedVisual").get_child(0).material_override.albedo_color.is_equal_approx(Color("e64b91")))
	check("control handles use the same pink",controls.sliders.speed.get_node("SliderOrigin/InteractableSlider/HandleOrigin/HandleMesh").material_override.albedo_color.is_equal_approx(Color("e64b91")))
	# All-time conservative envelope: add each inherited child offset plus its
	# rotated cube-envelope radius. This covers every phase, not only pictures.
	var lower: float=INF;var upper: float=-INF;var radius: float=0
	for generation in 4:
		var child_size: float=1.8*pow(.5,generation)
		var distance: float=1.5*1.8*(1.0-pow(.5,generation))
		var reach: float=distance+sqrt(3.0)*child_size/2
		lower=minf(lower,1.05+1.8-reach);upper=maxf(upper,1.05+1.8+reach);radius=maxf(radius,reach)
	check("largest setting clears the platform across every spin phase",lower>.12)
	check("largest setting stays below the structural ceiling",upper<5.64)
	check("backdrop and controls stay outside the complete motion envelope",radius<2.8 and absf(stage.get_node("Backdrop").position.z)-.05-radius>.7 and Vector2(controls.get_parent().position.x,controls.get_parent().position.z).length()-radius>.9)
	var initial: Transform3D=item.get_node("Root_1").transform
	await frames(35)
	check("native recursive parts move without touching a control",not item.get_node("Root_1").transform.is_equal_approx(initial))
	game.place_player(controls.global_position+Vector3(0,.06,1.4));await frames(10)
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	await drag_slider(controls.sliders.speed,0.0)
	check("real desktop speed slider can hold the pose",item.runtime_speed<.1)
	initial=item.get_node("Root_1").transform
	await frames(20)
	check("speed zero holds both position and rotation",item.get_node("Root_1").transform.is_equal_approx(initial))
	await drag_slider(controls.sliders.size,1.0)
	check("real desktop size slider reaches 1.8 metres",absf(item.runtime_size-1.8)<.02)
	var source: Node3D=item.get_node("Root/Source")
	check("live visual scale and solid collider match",source.original.scale.is_equal_approx(Vector3.ONE*1.5) and source.get_node("StructuralCollision").get_child(0).shape.size.is_equal_approx(Vector3.ONE*1.8))
	await drag_slider(controls.sliders.depth,0.0)
	check("real desktop depth slider reduces to one root",item.runtime_depth==1 and item._members.size()==1)
	await drag_slider(controls.sliders.depth,1.0)
	check("real desktop depth slider restores all 156 objects",item.runtime_depth==4 and item._members.size()==156)
	await drag_slider(controls.sliders.speed,.7)
	check("real desktop speed slider restarts motion",item.runtime_speed>25)
	initial=item.get_node("Root_1").transform;await frames(25)
	check("restarted motion changes the actual member",not item.get_node("Root_1").transform.is_equal_approx(initial))
	# A saved member pose remains an offset while the hierarchy is moving.
	var base: Dictionary=item.part_defaults["Root_1_2"]
	var edit: Dictionary={"position":[base.position[0]+.3,base.position[1]+.2,base.position[2]-.1],"rotation":[base.rotation[0]+15,base.rotation[1],base.rotation[2]]}
	item.apply_grid_config({"parts":{"Root_1_2":edit}});await frames(8)
	var offset: Vector3=Vector3(.3,.2,-.1)
	check("edited member stores its authored offset",item._offsets.Root_1_2.position.distance_to(offset)<.001)
	var saved_basis: Basis=item._offsets.Root_1_2.basis
	await frames(18)
	check("animation preserves edited translation and rotation",item._offsets.Root_1_2.position.distance_to(offset)<.001 and item._offsets.Root_1_2.basis.is_equal_approx(saved_basis))
	item.set_parameter("depth",2);await frames(5)
	check("lower depth removes hidden members",item._members.size()==6 and not item.has_node("Root_1_2"))
	item.set_parameter("depth",4);await frames(5)
	check("restoring depth restores hidden member edits",item._members.size()==156 and item._offsets.Root_1_2.position.distance_to(offset)<.001 and item._offsets.Root_1_2.basis.is_equal_approx(saved_basis))
	item.set_parameter("speed",0)
	var settings: Dictionary=item.bindings.duplicate();settings.speed=22.5;settings.phase=item.phase_clock;settings.size=item.runtime_size;settings.depth=item.runtime_depth
	for pose in item.SphereRule.expression(settings).parts:
		if pose.id!="Root_1_2":continue
		check("saved move changes the visible animated member",item.get_node(pose.id).position.distance_to(Vector3(pose.at[0],pose.at[1],pose.at[2])+offset)<.001)
		check("saved rotation changes the visible animated member",item.get_node(pose.id).basis.is_equal_approx(saved_basis*Basis.from_euler(Vector3(pose.rot[0],pose.rot[1],pose.rot[2])*PI/180)))
	var copy: Node3D=Live.instantiate()
	copy.apply_grid_config({"recipe":"lab_sphere_fractal","bindings":item.bindings,"parts":{"Root_1_2":edit},"only_parts":["Root_1_2"]})
	copy.position=Vector3(-4,-6,0);game.add_child(copy)
	initial=copy.get_child(0).transform;await frames(12)
	check("an individual copied member stays independently arranged",copy.get_child_count()==1 and copy.get_child(0).transform.is_equal_approx(initial))
	copy.queue_free()
	# Restore the unmodified saved layout before rendering; tests never write it.
	item.apply_grid_config({"recipe":"lab_sphere_fractal","bindings":item.bindings,"parts":{}})
	await frames(15)
	check("control readouts follow reloaded editor settings",absf(controls.sliders.speed.get_normalized_value()-.5)<.001 and absf(controls.sliders.size.get_normalized_value()-(1.2-.4)/1.4)<.001)
	await photograph("desktop-moving",Vector3(0,-2.8,7),Vector3(0,-3.6,-.2))
	await photograph("controls",Vector3(3.05,-4.45,4.3),Vector3(2.85,-4.82,3.15))
	var edit_base: Vector3=stage.get_node("LeftFoot").position
	stage.apply_grid_config({"parts":{"LeftFoot":{"position":[edit_base.x-.2,edit_base.y,edit_base.z],"rotation":[0,20,0]}}})
	check("a staging block can move and rotate independently",stage.get_node("LeftFoot").position.distance_to(edit_base+Vector3(-.2,0,0))<.001 and absf(stage.get_node("LeftFoot").rotation_degrees.y-20)<.001)
	var stage_copy: Node3D=load("res://commons/modular/sphere_fractal_stage.tscn").instantiate()
	stage_copy.apply_grid_config({"only_parts":["Backdrop"]})
	stage_copy.position=Vector3(-7,-6,0);game.add_child(stage_copy);await frames(3)
	check("catalogue stage and isolated copies retain the local recipe and ivory finish",stage_copy.get_child_count()==1 and stage_copy.has_node("Backdrop") and stage_copy.get_node("Backdrop/Source/FittedVisual").get_child(0).material_override.albedo_color.is_equal_approx(Color("eee8dc")))
	stage_copy.queue_free()
	await item.prepare_editor_preview()
	initial=item.get_node("Root_1").transform;await frames(15)
	check("editor export remains fixed at authored pose",item.preview_frozen and item.get_node("Root_1").transform.is_equal_approx(initial))
	check("export returns to the saved size and full depth",item._members.size()==156 and item.get_node("Root/Source").original.scale.is_equal_approx(Vector3.ONE))
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Actual desktop camera ray and mouse drags; native animation, scale, depth, saved offsets and copied parts. No physical headset test."},"  "))
	print("SPHERE_FRACTAL_LIVE_DONE ",checks.size()," checks; ",failed.size()," failed")
	game.queue_free();await frames(3);quit(0 if failed.is_empty() else 1)

func drag_slider(slider: Node3D,norm: float) -> void:
	var driver: Node3D=slider._slider
	var handle: Node3D=driver.get_node("HandleOrigin/InteractableHandle")
	var from: Vector3=handle.global_position
	var change: float=lerpf(driver.slider_limit_min,driver.slider_limit_max,norm)-driver.slider_position
	var to: Vector3=from+driver.get_parent().global_basis.x*change
	await input_aim_camera(from,6)
	var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true
	Input.parse_input_event(event);await frames(3)
	for step in range(1,16):await input_aim_camera(from.lerp(to,step/15.0),1)
	event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=false
	Input.parse_input_event(event);await frames(8)
	print("SLIDER_INPUT ",slider.name," expected=",norm," actual=",slider.get_normalized_value())
