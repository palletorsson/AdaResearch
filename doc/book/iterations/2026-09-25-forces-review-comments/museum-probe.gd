extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(2.0).timeout
	for n in root.find_children("*","Node",true,false):
		if n.get_script()!=null and str(n.get_script().resource_path).ends_with("/MushroomHand.gd"):
			var hud:CanvasLayer=n.get("_hud")
			if hud!=null:hud.visible=false
	if map_id=="Vectors_Act5_ForceAsPlace":await place_checks()
	else:await drag_checks()

func place_checks() -> void:
	var machine=find_scene("/vector_machine.gd")
	var field=find_scene("/force_field_zone.gd")
	var cube=find_scene("/force_cube.gd")
	check("machine field and probe loaded",machine!=null and field!=null and cube!=null)
	if machine==null or field==null or cube==null:return
	check("local carry lesson enabled",machine.is_carry_lesson() and field.is_carry_lesson() and str(cube.get_meta("config_lesson",""))=="force_as_place")
	machine._set_slider(0,0);machine._set_slider(1,0);machine._update()
	var down:Vector3=machine.current_vector()
	machine._set_slider(1,0.25);machine._update()
	check("yaw at pole preserves downward vector",down.is_equal_approx(machine.current_vector()))
	check("yaw at pole changes the held bearing",machine._yaw_idle() and machine._yaw_ghost().is_equal_approx(Vector3.RIGHT))
	await snapshot("aim-before-lift",machine.to_global(Vector3(0,1.7,2.8)),machine.to_global(Vector3(0,1.15,0)),62)
	machine._set_slider(0,0.02);machine._update()
	check("small tilt still uses idle readout",machine._yaw_idle())
	machine._set_slider(0,0.5);machine._update()
	check("horizontal pitch admits full yaw",not machine._yaw_idle() and absf(machine.current_vector().y)<0.001)
	machine._set_slider(2,1);machine._update()
	check("acceleration limit is fifteen",is_equal_approx(machine.current_vector().length(),15.0) and str(machine._readout.text).contains("m/s²"))
	machine._set_slider(0,0.67);machine._set_slider(1,0);machine._set_slider(2,9.8/15.0);machine._update()
	check("field receives local machine vector",field.field_vector.is_equal_approx(machine.current_vector()))
	# Supplied position differences exercise the actual production arrow update.
	cube.set_process(false);cube.freeze=true
	var fixed:bool=cube.get_script().get_script_constant_map().has("LESSON_STILL_ARROW_M")
	var states=[]
	for speed in [0.16,0.03,0.0,0.03,0.20,0.039,0.041,0.0]:
		cube._last_pos=cube.global_position-cube.global_basis*Vector3.RIGHT*speed*0.1
		cube._process(0.1)
		states.append({"speed":speed,"drawn_length":cube._last_f.length(),"mesh_count":cube.demo_root.find_children("*","MeshInstance3D",true,false).size()})
		if fixed and speed<0.04:check("small motion clears arrow at "+str(states.size()),cube._last_f==Vector3.ZERO and cube.demo_root.find_children("*","MeshInstance3D",true,false).is_empty())
		if fixed and speed==0.041:check("motion just above threshold returns",cube._last_f.length()>0.02)
		if speed==0.20:check("arrow returns for visible motion",cube._last_f.length()>0.09)
		if not fixed and states.size()==3:check("baseline reproduces retained arrow after stopping",cube._last_f.length()>0.001)
	observations["motion_display_states"]=states
	observations["stillness_fix_present"]=fixed
	# Legacy gallery/resting display must remain available outside the lesson.
	cube.set_meta("config_lesson","");check("legacy resting vector remains nonzero",cube._resting_force().length()>0.1)
	cube.set_meta("config_lesson","force_as_place");check("lesson has no invented resting vector",cube._resting_force()==Vector3.ZERO)
	cube._last_f=Vector3.INF;cube._redraw(Vector3.ZERO)
	var body=CharacterBody3D.new();root.add_child(body)
	var v=field.carry_velocity(body,0.1,Vector3(1,2,3))
	check("entry retains incoming velocity",v.is_equal_approx(Vector3(1,2,3)+field.field_vector*0.1))
	body.velocity=Vector3.ZERO;field.record_carry(body)
	check("next step retains post-contact velocity",field.carry_velocity(body,0.1,Vector3.ONE*99).is_equal_approx(field.field_vector*0.1))
	field.release_carry(body)
	check("release removes retained carry state",not field._carry.has(body.get_instance_id()))
	body.queue_free()
	var xr=load("res://doc/book/iterations/2026-09-25-forces-review-comments/receiver-fixture.gd").new()
	root.add_child(xr);xr.global_position=field.to_global(Vector3(0,0.1,0))
	var provider=load("res://commons/artifacts/force_field_zone/field_carry_provider.gd").new()
	root.add_child(provider);provider.receiver=xr
	xr.velocity=Vector3(1,2,3)
	check("XR contract accepts entry exclusively",provider.physics_movement(0.1,xr,false)==true)
	check("XR contract applies incoming plus field",xr.velocity.is_equal_approx(Vector3(1,2,3)+field.field_vector*0.1))
	xr.contact_stop=true;provider.physics_movement(0.1,xr,false)
	check("XR contract records supplied contact result",field._carry[xr.get_instance_id()]==Vector3.ZERO)
	xr.contact_stop=false;xr.global_position=field.to_global(Vector3(0,0.1,field.size/2+0.1));xr.velocity=Vector3(1,2,3)
	check("XR provider yields outside the field",provider.physics_movement(0.1,xr,false)==false)
	check("exit leaves velocity for ordinary movement",xr.velocity==Vector3(1,2,3) and not field._carry.has(xr.get_instance_id()))
	xr.on_ground=false;check("default XR stick control waits for ground",not xr._can_apply_ground_control())
	xr.on_ground=true;check("default XR stick control resumes on ground",xr._can_apply_ground_control())
	xr.global_position=field.to_global(Vector3(0,0.1,0));provider.physics_movement(0.1,xr,false)
	check("disabled XR carry releases its state",provider.physics_movement(0.1,xr,true)==false and not field._carry.has(xr.get_instance_id()))
	provider.queue_free();xr.queue_free()
	var eye:Vector3=field.to_global(Vector3(0,0,-4.0));eye.y=hall.global_position.y+1.7
	await snapshot("two-crossings",eye,field.to_global(Vector3(0,1.8,0)),72)
	observations["headset"]="Not tested. Supplied position differences, production provider with a nontracked receiver fixture and native standing museum cameras. Fixture move_player returns a supplied contact outcome; no collision or human motion claim."

func drag_checks() -> void:
	var medium=find_scene("/kinetic_drag.gd")
	check("kinetic drag passage loaded",medium!=null)
	if medium==null:return
	check("WALK initially optional and off",not medium.walk_enabled)
	check("off leaves walking request unchanged",is_equal_approx(medium.walk_multiplier(medium.to_global(Vector3.ZERO)),1.0))
	medium.buttons["WALK"].pressed.emit()
	var values=[]
	for z in [-3.0,0.0,3.0]:values.append(medium.walk_multiplier(medium.to_global(Vector3(0,0,z))))
	observations["walk_multipliers"]=values
	check("three media reduce the same stick request progressively",values[0]>values[1] and values[1]>values[2] and is_equal_approx(values[0],1.0/1.4) and is_equal_approx(values[2],1.0/4.2))
	check("beside the passage normal request returns",is_equal_approx(medium.walk_multiplier(medium.to_global(Vector3(1.6,0,0))),1.0))
	medium.buttons["PARTS"].pressed.emit();medium.buttons["FIRE"].pressed.emit()
	await create_timer(0.7).timeout
	check("same launch has different drag speeds",medium.bodies[0].linear_velocity.length()>medium.bodies[1].linear_velocity.length() and medium.bodies[1].linear_velocity.length()>medium.bodies[2].linear_velocity.length())
	await snapshot("three-resistances",medium.to_global(Vector3(0,1.7,-7.3)),medium.to_global(Vector3(0,1.0,0)),74)
	await snapshot("inside-the-passage",medium.to_global(Vector3(0,1.7,-2.7)),medium.to_global(Vector3(0,1.2,4.5)),74)
	medium.buttons["WALK"].pressed.emit()
	check("WALK can return to ordinary request",not medium.walk_enabled and is_equal_approx(medium.walk_multiplier(medium.to_global(Vector3.ZERO)),1.0))
