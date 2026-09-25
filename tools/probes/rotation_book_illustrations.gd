extends "res://tools/probes/transformation_encounters.gd"
## Freeze the actual hall's study for paired book illustrations. No live save/bake writes.
var study: Node3D

func press(index: int) -> void:
	var area: Node3D = study.buttons[index].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(camera, area, area.global_position)
	XRToolsPointerEvent.released(camera, area, area.global_position)
	await tick()

func portrait(name: String) -> void:
	await snapshot(name, study.to_global(Vector3(-1.25, 2.7, -2.15)), study.to_global(Vector3(0, 2.03, 0)), 32.0)

func rotation_checks() -> void:
	study = find_scene("/axial_sweep.gd")
	check("existing spindle study loaded", study != null)
	if study == null: return
	observations["artifact_world"] = xyz(study.global_position)
	check("viewing plate remains at 1.7 metres", is_equal_approx(study.plane_height, 1.7))
	check("default cube and hidden contour", study.shape_id == "cube" and not study.show_envelope)
	if study.playing: await press(1)
	check("PAUSE pointer event stops study", not study.playing)
	study.seek(0)
	var marker: Node3D = study.meshspin.get_node("FaceWitness")
	var first_direction: Vector3 = marker.global_basis * Vector3.FORWARD
	var original: PackedVector3Array = study.get_shape_vertices()
	await portrait("cube-zero")
	study.seek(5)
	check("five seconds selects quarter-turn at authored speed", is_equal_approx(study.meshspin.rotation.y, PI / 2))
	var same_occupied_vertices := true
	for v in original:
		var transformed: Vector3 = study.meshspin.basis * v
		var found := false
		for p in original:
			if p.distance_to(transformed) < 0.00001: found = true; break
		if not found: same_occupied_vertices = false
	check("quarter-turn permutes the cube's occupied vertices", same_occupied_vertices)
	check("attached mark turns ninety degrees", absf(first_direction.dot(marker.global_basis * Vector3.FORWARD)) < 0.00001)
	await portrait("cube-ninety")
	await press(2)
	check("BOUNDARY pointer event reveals contour", study.show_envelope and study.envelope.visible)
	study.seek(2.5)
	check("cube contour reaches the corner radius", is_equal_approx(study.envelope_radius_at(0), sqrt(2.0) * 0.3))
	await portrait("cube-sweep")
	await press(0)
	check("SHAPE pointer event selects triangle", study.shape_id == "triangle")
	check("triangle cone narrows from base to axle tip", is_equal_approx(study.envelope_radius_at(-0.35),0.45) and is_zero_approx(study.envelope_radius_at(0.35)))
	check("contour is a visual mesh without a solid body", study.envelope.find_children("*","CollisionObject3D",true,false).is_empty())
	study.seek(2.5)
	await portrait("triangle-sweep")
	await press(1)
	var before_angle: float = study.meshspin.rotation.y
	await create_timer(0.3).timeout
	check("PLAY pointer event resumes actual motion", study.playing and study.meshspin.rotation.y > before_angle)
	await press(1)
	before_angle = study.meshspin.rotation.y
	await create_timer(0.15).timeout
	check("PAUSE retains the selected orientation", not study.playing and is_equal_approx(study.meshspin.rotation.y,before_angle))
	observations["figure_states"] = {"cube-zero":0,"cube-ninety":90,"cube-sweep":45,"triangle-sweep":45}
	observations["camera_local"] = {"eye":[-1.25,2.7,-2.15],"target":[0,2.03,0],"fov":32}

func finish() -> void:
	var result := {"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Isolated actual museum; pointer button events, supplied frozen poses and native captures. No runtime source or geometry edits. This is not a headset or learner test."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("ROTATION ILLUSTRATIONS ", checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
