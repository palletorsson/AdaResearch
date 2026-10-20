extends "res://tools/probes/transformation_encounters.gd"
var complete := false
func landing_checks() -> void:
	museum.call("flush_stamps")
	var stream = museum.get("_portal_stream")
	if stream != null: stream.process_mode = Node.PROCESS_MODE_DISABLED
	var player = museum.get("_player")
	if player is Node3D:
		player.hide(); player.process_mode = Node.PROCESS_MODE_DISABLED; player.global_position = Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var exposure := CameraAttributesPractical.new(); exposure.exposure_multiplier = .55; camera.attributes = exposure
	var atlas := find_scene("/ant_scale_atlas.gd")
	check("V2 comparison is in the live ACO hall", atlas != null)
	if atlas == null: return
	atlas.buttons[2].pressed.emit(); atlas.restart(); atlas.model.playing = true
	var v2 = atlas.model.v2
	var started := Time.get_ticks_msec()
	var samples: Array = []
	var had_returning := false
	for seconds in [5,30,90]:
		while Time.get_ticks_msec()-started < seconds*1000:
			for ant in v2.ants:
				if ant.current_state == SimpleAnt.State.RETURNING: had_returning = true
			await process_frame
		samples.append({"requested_seconds":seconds,"wall_seconds":(Time.get_ticks_msec()-started)/1000.0,"physics_ticks":v2.ticks})
		await snapshot("v2-%d"%seconds, atlas.to_global(Vector3(-3.5,13,8)), atlas.to_global(Vector3(-2,0,0)),72)
	check("All hundred ants remain in the colony after ninety seconds", v2.ants.size()==100)
	check("The original colony reaches food without a scripted capture shortcut", had_returning)
	check("V2 field and ant state continue advancing", v2.ticks>100 and v2.ants[0].position.length()>.01)
	atlas.toggle_play()
	var stopped: String = v2.digest()
	await create_timer(.2).timeout
	check("Pause holds V2 field and agents inside the museum", v2.digest()==stopped)
	await snapshot("v2-table",atlas.to_global(Vector3(-7.5,2.2,4.1)),atlas.to_global(Vector3(-6,.96,2.5)),64)
	await snapshot("v2-walk-in",atlas.to_global(Vector3(-3.5,1.7,4.8)),atlas.to_global(Vector3(.4,.05,-.8)),86)
	var pointer := Node3D.new(); root.add_child(pointer); atlas.point.on_desktop_grab(pointer)
	atlas.point.global_position=atlas.to_global(Vector3(-5.5,1.55,-2.1)); atlas.point.rotation.x=.35
	await snapshot("v2-hand",atlas.to_global(Vector3(-5.4,2.15,-1.3)),atlas.point.to_global(Vector3(0,.06,-.31)),65)
	check("The V2 hand tile carries the same field as the floor",atlas.point.held() and atlas.views.all(func(v): return v.plane.material_override==atlas.v2_material and v.ants.multimesh.visible_instance_count==100))
	atlas.point.action(); await create_timer(.3).timeout
	check("Held point trigger resumes V2",v2.running and v2.digest()!=stopped)
	atlas.point.action(); atlas.point.on_desktop_drop(pointer)
	atlas.select(0); stopped=v2.digest(); await create_timer(.2).timeout
	check("Switching away retains the V2 history",stopped==v2.digest())
	atlas.select(2)
	observations.timeline=samples; observations.headset_tested=false
	observations.model="Original AntColonyV2 scene, 100 SimpleAnt bodies, 256 x 256 field, original 50m world"
	complete=true; pointer.queue_free()

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":complete and failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
	quit(0 if complete and failures.is_empty() else 1)
