extends SceneTree
## Integration check: the active transformation halls contain their source grids.
var failures: Array = []
var checks := 0
func _initialize() -> void:
	_run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("[museum-stage] ","PASS " if ok else "FAIL ",message)
func _run() -> void:
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	em.set("EM_CONTROL","res://ada_run/simulation_stage/integration-control.json")
	em.set("_overrides_path","res://ada_run/simulation_stage/no-overrides.json")
	em.set("_hand_path","res://ada_run/simulation_stage/no-hand.json")
	em.set("start_chapter","transformation")
	em.set("start_map","Trans_Pre")
	em.set("MIN_SEGMENTS",99)
	em.set("KEEP_AHEAD_M",99999.0)
	em.set("KEEP_BEHIND_M",99999.0)
	var f := FileAccess.open("res://ada_run/simulation_stage/integration-control.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter":"transformation","dollhouse":0,"grid_pack":1}))
	f.close()
	root.add_child(em)
	current_scene = em
	await create_timer(1).timeout
	em.set_process(false)
	em.set("MIN_SEGMENTS",99)
	em.set("KEEP_AHEAD_M",99999.0)
	em.set("KEEP_BEHIND_M",99999.0)
	var expected: Array = JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/sequences/transformation.json")).sequences.transformation.maps
	var galleries: Array[String] = []
	for map_name: String in expected:
		var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/%s/map_data.json" % map_name))
		if not source.map_info.get("museum",{}).get("simulation",{}).get("staged",false): galleries.append(map_name)
	for i in range(expected.size()+3):
		# Entrance segments are not curriculum rooms; count map identities.
		var present: Array = []
		for rec: Dictionary in em.get("_segments"):
			present.append(str(rec.node.get_meta("em_map","")))
		if expected.all(func(map_name): return map_name in present): break
		em.call("_build_segment")
		await process_frame
	em.call("flush_stamps")
	for i in range(1800):
		var finished := true
		for rec: Dictionary in em.get("_segments"):
			var seg: Node3D = rec.node
			var map_name := str(seg.get_meta("em_map",""))
			if not expected.has(map_name): continue
			if galleries.has(map_name): continue
			var gs := seg.get_node_or_null("SimGrid_"+map_name)
			if gs == null or not gs.has_meta("stage_grid_ready"): finished = false
		if finished: break
		await process_frame
	var seen: Array = []
	for rec: Dictionary in em.get("_segments"):
		var seg: Node3D = rec.node
		var map_name := str(seg.get_meta("em_map",""))
		if not expected.has(map_name): continue
		seen.append(map_name)
		if galleries.has(map_name):
			check(not seg.has_meta("em_simulation_stage") and not seg.has_node("SimGrid_"+map_name),map_name+" remains an exhibition gallery")
			continue
		check(seg.has_meta("em_simulation_stage"),map_name+" staged declaration reached museum")
		check(seg.has_node("SimulationFrame"),map_name+" glass frame built")
		var gs := seg.get_node_or_null("SimGrid_"+map_name)
		check(gs != null,map_name+" source GridSystem embedded exactly once")
		if gs == null: continue
		check(gs.has_meta("stage_grid_ready"),map_name+" grid build completed")
		var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/%s/map_data.json" % map_name))
		check(gs.get("data_component").get_structure_layer_raw() == source.layers.structure,map_name+" live grid retains source structure")
		var plan: Dictionary = seg.get_meta("em_simulation_stage")
		check(gs.position.is_equal_approx(Vector3(plan.pad+0.5,-0.5,em.VESTIBULE_H+plan.pad+0.5)),map_name+" grid placed flush at recorded offset")
		check(gs.scale.is_equal_approx(Vector3.ONE),map_name+" source scale retained")
		var ray := PhysicsRayQueryParameters3D.create(seg.to_global(Vector3(0.5,0.3,em.VESTIBULE_H+plan.pad+2)),seg.to_global(Vector3(0.5,-1,em.VESTIBULE_H+plan.pad+2)))
		var hit := seg.get_world_3d().direct_space_state.intersect_ray(ray)
		check(not hit.is_empty() and absf(hit.position.y)<0.02,map_name+" outer gallery actually supports a body at y=0")
	for name in expected: check(seen.count(name)==1,str(name)+" occurs once in the active sequence")
	f = FileAccess.open("res://ada_run/simulation_stage/integration-checks.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"maps":seen},"  "))
	print("[museum-stage] ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
