extends "res://tools/probes/void_transfer_probe.gd"

func focused_checks(tag: String) -> void:
	if level==1:
		var cabinet:Node3D=artifact("bias_visualizer")
		await approach(cabinet)
		await press(cabinet._control_panel.find_child("Btn_1",true,false))
		check(tag+"TRAIT via real pointer selects the original analogy",cabinet.analogy_type==1)
		await press(cabinet._control_panel.find_child("Btn_2",true,false))
		check(tag+"REDLN via real pointer selects the original analogy",cabinet.analogy_type==2)
		await press(cabinet._control_panel.find_child("Btn_0",true,false))
		check(tag+"PROF via real pointer returns the source default",cabinet.analogy_type==0)
		var words:Node3D=artifact("bias_from_inside")
		await approach(words)
		await press(words._controls.find_child("Btn_0",true,false))
		check(tag+"READ via real pointer reveals the authored interpretation",words._reading.visible)
		await press(words._controls.find_child("Btn_0",true,false))
		check(tag+"READ closes without replacing the instrument",not words._reading.visible)
		var original:Transform3D=words._marginalized_multimesh.multimesh.get_instance_transform(0)
		var camera_position:Vector3=game.camera.global_position
		# Label this as an API test; it does not claim a physical slider drag.
		words._slider.set_normalized_value(1.0)
		words._on_perspective_changed(0.0)
		await frames(5)
		var compressed:Transform3D=words._marginalized_multimesh.multimesh.get_instance_transform(0)
		check(tag+"compression API changes positions, keeps 24 words and sphere size",compressed.origin.distance_to(original.origin)>.05 and compressed.basis==original.basis and words._marginalized_multimesh.multimesh.instance_count==12 and words._default_multimesh.multimesh.instance_count==12)
		check(tag+"compression leaves visitor camera in place",game.camera.global_position.distance_to(camera_position)<.02)
		words._slider.set_normalized_value(0.0);words._on_perspective_changed(0.0)
		check(tag+"compression API restores the seeded arrangement",words._marginalized_multimesh.multimesh.get_instance_transform(0).is_equal_approx(original))
		var pocket:Node3D=artifact("filled_pocket")
		check(tag+"original sealed ring computes a pocket and an outside route",not pocket._pocket.is_empty() and not pocket._route.is_empty())
	else:
		var room:Node3D=artifact("room_shape_demonstrator")
		check(tag+"ethics room retains HEAD / NEUTRAL and console",room.plan=="head" and room.palette=="neutral" and room.interactive and room._console.visible)
		await approach(room,2.2)
		await press(room._panel.find_child("Btn_1",true,false))
		check(tag+"CIRCLE via real pointer rebuilds the miniature",room.plan=="circle")
		await press(room._panel.find_child("Btn_6",true,false))
		check(tag+"COLOUR via real pointer changes palette only",room.palette=="authored" and room.plan=="circle")
		await press(room._panel.find_child("Btn_0",true,false))
		await press(room._panel.find_child("Btn_5",true,false))
		check(tag+"HEAD and NEUTRAL restore original configuration",room.plan=="head" and room.palette=="neutral")
		var plaque:Node3D=artifact("godel_statement_plaque")
		await approach(plaque,1.5)
		var before:int=plaque.current_index
		await press(plaque.next_panel.find_child("Btn_0",true,false))
		check(tag+"NEXT adapter calls original plaque via real pointer",plaque.current_index==(before+1)%plaque.statements.size() and plaque._text_label.text==plaque.get_current_statement())
		var boxes:Array=[]
		geometry(artifact("synthesis_stand"),boxes)
		check(tag+"synthesis stand is entirely above the slab",boxes.all(func(box):return box.position.y>=game.building.spec.levels[level]-.03))

func capture_floor() -> void:
	await super.capture_floor()
	var subject:Node3D=artifact("bias_from_inside" if level==1 else "room_shape_demonstrator")
	await photo("%02d-original-instrument"%(level*2),subject.to_global(Vector3(3.2,2.6,4.4)),subject.to_global(Vector3(0,.35,0)))
