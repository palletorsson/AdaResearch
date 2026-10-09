from pathlib import Path
base = Path('doc/book/iterations/2026-09-19-forces-review/relations/probes')
s = Path('commons/testing/probe_arena_relations.gd').read_text(encoding='utf-8')
s = s.replace('var checks := 0', 'var OUT := ""\nvar baseline := false\nvar inventory: Dictionary = {}\nvar checks := 0')
s = s.replace('func _initialize() -> void:run.call_deferred()', '''func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): OUT=arg.trim_prefix("--out=")
	baseline="--baseline" in OS.get_cmdline_user_args()
	run.call_deferred()''')
s=s.replace('"res://ada_run/arena-relations-"', 'OUT+"arena-relations-"')
s=s.replace('for i in 25:await process_frame', 'await create_timer(0.4).timeout')
s=s.replace('\tvar cam=Camera3D.new();em.add_child(cam);cam.fov=65', '''	var map_data=JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/VFM_08_Arena/map_data.json"))
	var expected: Dictionary = {}
	for row in map_data.layers.interactables:
		for cell in row:
			if cell is String and cell!="" and cell!="0":
				var token=cell.split("#")[0].split(":")[0]
				expected[token]=expected.get(token,0)+1
	var present: Dictionary = {}
	var placed: Array = []
	for node in seg.find_children("*","Node3D",true,false):
		var key=str(node.get_meta("artifact_lookup_name",""))
		if expected.has(key):
			present[key]=present.get(key,0)+1
			placed.append({"token":key,"node":str(node.get_path()),"world_position":str(node.global_position),"scale":str(node.global_basis.get_scale())})
	var missing: Array = []
	for token in expected:
		if present.get(token,0)!=expected[token]: missing.append(token)
	missing.sort()
	var original_missing=["momentum_collision","parlour_orbits","paused_fountain","prop_mobile","prop_spigot","revolving_door","three_gravities","umbrella_field"]
	check(missing==original_missing if baseline else missing==["momentum_collision"],"authored inventory matches baseline omissions or restored21 plus explicitly disabled momentum_collision")
	check(placed.size()==(14 if baseline else 21),"authored instantiated placement count "+str(placed.size()))
	inventory={"expected":expected,"present":present,"missing":missing,"placements":placed,"headless":true}
	var cam=Camera3D.new();em.add_child(cam);cam.fov=65''')
s=s[:s.index('\tui.beacon_index=0;ui.beacon.position=ui.BEACONS[0];ui.screen_on=true')]+'''	if carts!=null:
		for at in [Vector3(0,1,1.4),Vector3(0,1,2.0)]:
			q.transform.origin=carts.to_global(at)
			check(seg.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty(),"collision-carts body-sized front approach "+str(at))
	f=FileAccess.open(OUT+"arena_relations_probe.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"headset_tested":false,"baseline":baseline,"inventory":inventory},"  "));f.close()
	print("ARENA COMPLETE ",checks," / ",failures.size())
	root.remove_child(em);em.free()
	await process_frame
	print("ARENA SCENE CLEANUP COMPLETE")
	quit(0 if failures.is_empty() else 1)
'''
(base/'probe_arena.gd').write_text(s,encoding='utf-8')
s=(base/'run.py').read_text(encoding='utf-8')
s=s.replace("'commons/maps/VFM_07_Gravity/map_data.json'", "'commons/maps/VFM_08_Arena/map_data.json', 'commons/artifacts/registry/vectors_demos.json'")
s=s.replace("'--rendering-method', 'mobile', '--rendering-driver', 'vulkan',", "'--headless',")
s=s.replace('if phase=="before": cmd.append("--replay-before")','if phase=="arena-before": cmd.append("--baseline")')
s=s.replace('p.wait(timeout=180)', 'p.wait(timeout=60)')
s=s.replace('    try:\n', '    (out/(name+"-pid.json")).write_text(json.dumps({"pid":p.pid,"command":cmd},indent=2))\n    try:\n')
s=s.replace("'commons/artifacts/registry/vectors_demos.json'", "'commons/artifacts/registry/vectors_demos.json', 'commons/artifacts/registry/physics_simulation.json', 'commons/artifacts/arena_relation_lab/arena_relation_lab.gd', 'commons/artifacts/arena_relation_lab/lesson_crab.gd', 'commons/artifacts/arena_relation_lab/lesson_food.gd', 'commons/hazards/head_crab/head_crab.gd', 'commons/artifacts/spore_mushroom/spore_mushroom.gd'")
(base/'run_arena.py').write_text(s,encoding='utf-8')
