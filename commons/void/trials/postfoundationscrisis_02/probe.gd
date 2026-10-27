extends "res://tools/probes/void_transfer_probe.gd"

func focused_checks(tag: String) -> void:
	if level == 1:
		var merge: Node3D = artifact("merge_conflict_visualizer")
		check(tag+"source junction exposes its console", merge.merge=="junction" and merge.interactive)
		await approach(merge)
		for i in [1,2,3,0]:
			await press(merge._panel.find_child("Btn_%d"%i,true,false))
			check(tag+"merge pointer selects "+merge.MERGES[i],merge.merge==merge.MERGES[i])
		await press(merge._panel.find_child("Btn_4",true,false))
		check(tag+"marker pointer hides only the marker", not merge.marker_visible and not merge._conflict_glow.visible)
		await press(merge._panel.find_child("Btn_4",true,false))
		var sphere: Node3D = artifact("florensky_sphere")
		sphere.set_state(sphere.LogicState.BOTH)
		await approach(sphere)
		await press(sphere.controls.find_child("Btn_0",true,false))
		check(tag+"OBSERVE pointer calls original sphere state change",sphere.current_state in [sphere.LogicState.A,sphere.LogicState.NOT_A])
		sphere.set_state(sphere.LogicState.BOTH)
		await press(sphere.controls.find_child("Btn_1",true,false))
		check(tag+"CYCLE pointer reaches NEITHER",sphere.current_state==sphere.LogicState.NEITHER)
		sphere.set_state(sphere.LogicState.BOTH)
		var box: Node3D = artifact("schrodinger_box")
		check(tag+"unrelated pointer clicks did not open the box", box.current_state==box.State.SUPERPOSITION and not box.is_processing_input())
		await approach(box)
		await press(box.controls.find_child("Btn_0",true,false))
		check(tag+"OPEN pointer reveals an original random outcome",box.current_state in [box.State.ALIVE,box.State.DEAD] and box._lid_open)
		await press(box.controls.find_child("Btn_1",true,false))
		check(tag+"RESET pointer reseals the original box",box.current_state==box.State.SUPERPOSITION and not box._lid_open)
		var shannon: Node3D = artifact("shannon_workbench")
		var draws: PackedFloat32Array = shannon._draws.duplicate()
		# Slider API test; physical dragging is outside this focused smoke test.
		shannon._slider.set_normalized_value(0.0); shannon._on_slider_changed(0.0)
		await frames(12)
		check(tag+"Shannon API at zero: unchanged sample, zero entropy",shannon._p==0.0 and shannon._draws==draws and shannon._plate_readout.text.contains("0.000"))
		shannon._slider.set_normalized_value(.5); shannon._on_slider_changed(.5)
		await frames(12)
		check(tag+"Shannon API at half: unchanged sample, one bit",is_equal_approx(shannon._p,.5) and shannon._draws==draws and shannon._plate_readout.text.contains("1.000"))
		var vault: Node3D = artifact("rhizome_vault")
		check(tag+"original vault preserves six pods and graph connections",vault._pods.size()==6 and vault._connections.size()>=6 and vault.ground_top==0)
		var cap: Node3D = artifact("cap_theorem_walk")
		var before: float = cap._t
		await frames(10)
		check(tag+"original passive CAP cycle advances",cap.sacrifice=="cycle" and cap._t>before and cap._pillars.size()==3)
	else:
		var crab: Node3D = artifact("head_crab")
		var gm: Node = root.get_node("GameManager")
		var original_health: float = gm.player_health
		game.health.reset()
		crab.global_position = game.body.global_position + Vector3(.5,0,.2)
		await frames(65)
		check(tag+"original crab pursuit/contact damages Void charge",game.health.get_health()<100 and game.health.sight_impairment>0)
		check(tag+"crab preserves museum health and scene",gm.player_health==original_health and current_scene==game)
		# Pause the active hazard only while checking independent exhibit controls.
		crab.set_process(false)
		game.health.reset()
		for entry in game.building.content.data.floors[level].artifacts:
			if entry.artifact != "situated_readout": continue
			var readout: Node3D = station(entry.id)
			check(tag+entry.id+" keeps its configured claim", readout._verdict_override==entry.config.verdict and readout.address=="footnote" and readout.interactive)
		var readout: Node3D = station("f2_situated_readout_2_2")
		await approach(readout,1.8)
		var original_claim: String = readout._verdict_label.text
		await press(readout._controls.find_child("Btn_1",true,false))
		check(tag+"COVER pointer changes address, retains claim",readout.address=="erasure" and readout._verdict_label.text==original_claim)
		await press(readout._controls.find_child("Btn_2",true,false))
		check(tag+"WITNESS pointer retains configured NW claim",readout.address=="witness" and readout._verdict_override=="NW")
		await press(readout._controls.find_child("Btn_0",true,false))
		check(tag+"FOOTNOTE pointer restores disclosed address",readout.address=="footnote")
		var witness: Node3D = artifact("museum_witnesses")
		var film: Node3D = witness.specimen
		check(tag+"witness binds four actual readouts in this Void floor",film.ready_sources and film.sources.size()==4)
		game.place_player(witness.to_global(Vector3(0,.06,7.6)))
		await frames(45)
		check(tag+"witness captures real rendered frames",not film.latest.is_empty() and film.viewports[0].world_3d==witness.get_world_3d())
		# The original station exposes StaticBody pointer buttons, not rack caps.
		await study_press(witness.controls[2])
		check(tag+"HOLD pointer freezes an actual frame",film.held and not film.held_frame.is_empty())
		var held_time: float = float(film.held_frame.get("time",-1))
		await frames(30)
		check(tag+"held exposure stays fixed while live capture advances",float(film.held_frame.get("time",-1))==held_time and float(film.latest.get("time",-1))>held_time)
		await study_press(witness.controls[2])
		check(tag+"RELEASE pointer resumes following",not film.held)
		await study_press(witness.controls[1])
		check(tag+"DELAY pointer selects six seconds",film.delay_seconds==6)
		await study_press(witness.controls[1])
		check(tag+"DELAY pointer selects one second",film.delay_seconds==1)
		await frames(90)
		check(tag+"changing delay preserves every buffered timestamp",film.frames.all(func(frame): return frame.has("time") and frame.has("image")))
		check(tag+"delayed monitor receives a past real frame",not film.delayed_frame.is_empty() and float(film.latest.get("time",0))-float(film.delayed_frame.get("time",0))>=1.0)
		await study_press(witness.controls[0])
		check(tag+"VIEWPOINT pointer selects next readout",film.view_index==1)
		await study_press(witness.controls[3])
		check(tag+"RETURN pointer restores camera homes",film.handles[0].global_transform.is_equal_approx(film.home_poses[0]))
		crab.set_process(true)
		game.health.reset()

func study_press(button: Node3D) -> void:
	# Reuse the shared real-input driver; the proxy path only locates the target.
	var proxy := Node3D.new()
	button.add_child(proxy)
	var area := Node3D.new(); area.name="InteractableAreaButton"; proxy.add_child(area)
	var point := Node3D.new(); point.name="CollisionShape3D"; area.add_child(point)
	await press(proxy)
	proxy.queue_free()

func capture_floor() -> void:
	await super.capture_floor()
	if level == 1:
		var subject: Node3D = artifact("merge_conflict_visualizer")
		await photo("02-merge-controls",subject.to_global(Vector3(2.4,2.2,3.6)),subject.to_global(Vector3(0,1,0)))
	else:
		var subject: Node3D = artifact("situated_readout")
		await photo("04-situated-readout",subject.to_global(Vector3(2.6,2.2,4.0)),subject.to_global(Vector3(0,1.1,0)))
