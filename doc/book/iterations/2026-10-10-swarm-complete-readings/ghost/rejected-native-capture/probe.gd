extends "res://tools/probes/transformation_encounters.gd"
const GHOST := "res://doc/book/iterations/2026-10-10-swarm-ghost-student/"
var completed := false

func landing_checks() -> void:
	museum.call("flush_stamps")
	var stream = museum.get("_portal_stream")
	if stream != null: stream.process_mode=Node.PROCESS_MODE_DISABLED
	var player = museum.get("_player")
	if player is Node3D:
		player.hide(); player.process_mode=Node.PROCESS_MODE_DISABLED; player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var attributes := CameraAttributesPractical.new(); attributes.exposure_multiplier=.35; camera.attributes=attributes
	var original = find_scene("/particle_swarm_walk.gd")
	check("Existing museum PSO placement located",original!=null)
	if original==null:return
	var parent = original.get_parent()
	var placement: Transform3D = original.transform
	original.queue_free(); await tick()
	var receipt: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GHOST+"transfer-checks.json"))
	var rows: Array = []
	for seed in [101006,101007]:
		for pull in [1.5,0.3]:
			var host = load(GHOST+"investigation/seed-%d-pull-%.1f/study.gd" % [seed,pull]).new()
			host.transform=placement
			parent.add_child(host);host.set_process(false);host.playing=false
			host.change(2);host.restart();await tick()
			check("Reconstructed host retains24 bodies in museum: %d/%.1f" % [seed,pull],host.points.size()==24 and host.global_basis.get_scale().is_equal_approx(Vector3.ONE))
			if seed==101006 and is_equal_approx(pull,1.5):
				await snapshot("ridge-start",host.to_global(Vector3(8,12,9)),host.to_global(Vector3(0,0,0)),66)
			for step in range(1,101):
				host.single_step()
				if step in [20,100]:
					host.paint();await tick()
					var reference: Array=[]
					for record in receipt.observations.ridge:
						if int(record.seed)==seed and is_equal_approx(float(record.social_pull),pull):
							for sample in record.samples:
								if int(sample.step)==step:reference=sample.positions
					var matches: bool = reference.size()==24
					for i in range(reference.size()):
						matches = matches and host.model.positions[i].distance_to(Vector2(reference[i][0],reference[i][1]))<.00001
					check("Museum controls reproduce recorded model: %d/%.1f/step%d" % [seed,pull,step],matches and host.model.steps==step)
					var name: String = "ridge-%d-pull-%s-step-%d" % [seed,str(pull).replace(".","-"),step]
					await snapshot(name,host.to_global(Vector3(8,12,9)),host.to_global(Vector3(0,0,0)),66)
					rows.append({"seed":seed,"social_pull":pull,"step":step,"image":name+".png","positions_match_headless":matches})
			host.queue_free();await tick()
	observations.ridge=rows
	observations.temporary_reconstruction=true
	observations.production_artifact_files_edited=false
	completed=true

func finish() -> void:
	var result: Dictionary={"completed":completed,"passed":completed and failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Fresh ZIP-extracted PSO host temporarily replaces one artifact inside an isolated run of the existing museum. Exact controls, state matching and native images; no headset or continuous seven-hall traversal."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	quit(0 if result.passed else 1)
