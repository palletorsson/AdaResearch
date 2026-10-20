extends SceneTree
const DIR="res://doc/book/iterations/2026-10-16-ghost-student-pilot/gallery-regression/"
const SCENE="res://commons/artifacts/prefab_disorder/preview.tscn"
var checks: Array=[]
var failures: Array=[]
var bench: Node3D
func _initialize() -> void: run.call_deferred()
func check(title: String, ok: bool) -> void:
	checks.append({"name":title,"passed":ok})
	if not ok: failures.append(title);print("FAIL ",title)
func press(key: String) -> void:
	var area: Node=bench.buttons[key].get_node("InteractableAreaButton")
	area.button_pressed.emit(area)
func transforms() -> Array:
	var results: Array=[]
	for part in bench.pieces: results.append([part.views[0].transform,part.views[1].transform])
	return results
func shot(name_text: String) -> void:
	if DisplayServer.get_name()=="headless": return
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(DIR+name_text+".png")
func detail(preview: Node3D, title: String) -> void:
	var camera: Camera3D=preview.get_node("Camera")
	var previous:=camera.transform
	camera.position=Vector3(1.18,2.5,2.1);camera.look_at(Vector3(1.18,1.23,-0.1));camera.fov=47
	for child in preview.get_children():
		if child is CanvasLayer: child.visible=false
	await shot(title)
	for child in preview.get_children():
		if child is CanvasLayer: child.visible=true
	camera.transform=previous;camera.fov=44
func collisions_off(node: Node) -> bool:
	if node is CollisionObject3D and (node.collision_layer!=0 or node.collision_mask!=0): return false
	for child in node.get_children():
		if not collisions_off(child): return false
	return true
func membership(entries: Array) -> String:
	var groups: Array=[[],[],[],[]]
	for entry in entries: groups[int(entry.group)].append(str(int(entry.item))+":"+entry.key)
	var names: Array[String]=[]
	for group in groups:
		group.sort();names.append(",".join(group))
	names.sort();return "|".join(names)
func run() -> void:
	root.size=Vector2i(1600,1050)
	var preview: Node3D=load(SCENE).instantiate();root.add_child(preview)
	bench=preview.bench;bench.pointer_path="user://hybrid-gallery-test-%d-latest.json" % Time.get_ticks_usec()
	for i in 5: await process_frame
	check("four actual gallery prefabs retained",bench.inventory.map(func(item):return item.id)==bench.SOURCES)
	check("each prefab supplies several mesh parts",bench.inventory.all(func(item):return item.parts>2))
	var zero: Array=transforms();var draws: Array=bench.sample.draws.duplicate()
	var same:=true
	for pair in zero:
		var right: Transform3D=pair[1];right.origin.x-=bench.SIDE*2
		same=same and pair[0].is_equal_approx(right)
	check("zero puts identical assemblies on both sides",same)
	await shot("zero")
	for amount in [0.25,0.5,0.75,1.0]:
		bench.slider.set_normalized_value(amount);bench.slider.slider_moved.emit(Vector3.ZERO)
		check("physical slider sets amount "+str(amount),is_equal_approx(bench.disorder,amount))
		check("slider uses retained draws "+str(amount),bench.sample.draws==draws)
		check("slider changes the geometry "+str(amount),transforms()!=zero)
		var floor_clear:=true;var rigid:=true;var parts_move:=false
		var item_poses: Dictionary={}
		for part in bench.pieces:
			for view in part.views:
				floor_clear=floor_clear and (view.transform*part.bounds).position.y>=bench.DECK_Y-0.00001
			var pose: Transform3D=part.views[0].transform*part.home.affine_inverse()
			if item_poses.has(part.item): rigid=rigid and pose.is_equal_approx(item_poses[part.item])
			else: item_poses[part.item]=pose
			var right: Transform3D=part.views[1].transform;right.origin.x-=bench.SIDE*2
			parts_move=parts_move or not right.is_equal_approx(part.views[0].transform)
		check("assembled parts share one rigid motion "+str(amount),rigid)
		check("part movement differs from whole movement "+str(amount),parts_move)
		check("no rendered part sinks through the tray "+str(amount),floor_clear)
		if amount==0.5: await shot("parts")
		if amount==0.75: await shot("joining")
	await shot("hybrids")
	var camera: Camera3D=preview.get_node("Camera")
	var camera_home:=camera.transform
	camera.position=Vector3(1.18,2.5,2.1);camera.look_at(Vector3(1.18,1.23,-0.1));camera.fov=47
	for child in preview.get_children():
		if child is CanvasLayer: child.visible=false
	await shot("hybrid-detail")
	for child in preview.get_children():
		if child is CanvasLayer: child.visible=true
	camera.transform=camera_home;camera.fov=44
	var full: Array=transforms()
	press("ORIGINAL");check("ZERO reconstructs exact initial geometry",transforms()==zero and bench.sample.draws==draws)
	preview.amount.value=1.0
	check("desktop slider restores full geometry",transforms()==full)
	press("KEEP")
	check("KEEP creates a disk record",FileAccess.file_exists(bench.saved_path))
	var record=JSON.parse_string(FileAccess.get_file_as_string(bench.saved_path))
	FileAccess.open(DIR+"kept-trial.json",FileAccess.WRITE).store_string(JSON.stringify(record,"  ",true,true))
	press("SEED +1");check("new seed changes hybrid geometry and separation draws",transforms()!=full and bench.sample.draws!=draws and bench.experiment_seed==436)
	var next_record: Dictionary=bench.capture()
	check("seed changes membership, not just pad positions",membership(next_record.hybrids)!=membership(record.hybrids))
	await shot("seed-436");await detail(preview,"seed-436-detail")
	FileAccess.open(DIR+"seed-436.json",FileAccess.WRITE).store_string(JSON.stringify(next_record,"  ",true,true))
	press("SEED +1");await shot("seed-437");await detail(preview,"seed-437-detail")
	press("SEED +1");await shot("seed-438");await detail(preview,"seed-438-detail")
	press("REPLAY");check("REPLAY restores all transforms and retained draws",transforms()==full and bench.sample.draws==draws and bench.experiment_seed==435)
	var fresh: Node3D=load("res://commons/artifacts/prefab_disorder/prefab_disorder.tscn").instantiate();root.add_child(fresh)
	for i in 5: await process_frame
	check("fresh prefab build produces stable source signature",fresh.signature==bench.signature)
	check("fresh scene restores the kept record",fresh.restore(record))
	var exact:=true
	for i in bench.pieces.size():
		for j in 2: exact=exact and fresh.pieces[i].views[j].transform==full[i][j]
	check("fresh reconstruction matches every mesh transform",exact)
	fresh.queue_free()
	var seeded=bench.Seeded.new()
	var rebuilt: Array=seeded.build(bench.pieces,bench.inventory,bench.SIDE,435)
	var same_targets: bool=membership(rebuilt)==membership(bench.hybrids)
	for i in rebuilt.size():
		var identical: bool=bench.Hybrid.unpack(rebuilt[i].pose)==bench.Hybrid.unpack(bench.hybrids[i].pose)
		if not identical: print("Rebuilt target differs at ",i," ",rebuilt[i].pose," / ",bench.hybrids[i].pose)
		same_targets=same_targets and identical
	check("same seed independently reconstructs identical targets",same_targets)
	var all_valid:=true;var signatures: Dictionary={};var reversible:=true;var floor_across_seeds:=true
	var seeds: Array=range(32);seeds.append_array([435,436,437,438,-1,9223372036854775807,-9223372036854775807-1])
	for seed_value in seeds:
		var variant_record: Dictionary=record.duplicate(true)
		variant_record.seed=str(seed_value)
		variant_record.hybrids=seeded.build(bench.pieces,bench.inventory,bench.SIDE,seed_value)
		all_valid=all_valid and bench.restore(variant_record)
		signatures[membership(variant_record.hybrids)]=true
		bench.set_disorder(0.73);var kept_poses: Array=transforms()
		bench.set_disorder(1);bench.set_disorder(0.73)
		reversible=reversible and transforms()==kept_poses
		for part in bench.pieces: floor_across_seeds=floor_across_seeds and (part.views[1].transform*part.bounds).position.y>=bench.DECK_Y-0.00001
	check("39 seed samples retain complete mixed-source bounded assemblies",all_valid)
	check("sampled seeds produce distinct memberships beyond pad permutation",signatures.size()>32)
	check("reversal stays exact across seeded assemblies",reversible)
	check("intermediate parts stay above tray across seeds",floor_across_seeds)
	var edge_record: Dictionary=record.duplicate(true);edge_record.seed="9223372036854775807"
	bench.restore(edge_record);press("SEED +1")
	check("seed increment wraps safely and rebuilds targets",bench.experiment_seed==0 and bench.hybrids==seeded.build(bench.pieces,bench.inventory,bench.SIDE,0))
	bench.restore(record)
	var historical=JSON.parse_string(FileAccess.get_file_as_string("res://doc/book/iterations/2026-10-15-prefab-hybrids/kept-trial.json"))
	check("previous fixed hybrid record still opens",bench.restore(historical))
	var historical_exact:=true
	for i in bench.pieces.size(): historical_exact=historical_exact and bench.pieces[i].views[1].transform==bench.Hybrid.unpack(historical.hybrids[i].pose)
	check("previous fixed hybrid uses its exact saved targets and labels",historical_exact and bench.captions[0].text.begins_with("SCREEN WALKER"))
	press("KEEP")
	var preserved=JSON.parse_string(FileAccess.get_file_as_string(bench.saved_path))
	check("keeping an old hybrid preserves recipe identity",preserved.recipe==historical.recipe and preserved.hybrids==historical.hybrids)
	press("SEED +1")
	check("new seed after old replay switches to seeded grafts",bench.recipe_version==bench.Seeded.VERSION and bench.hybrids!=historical.hybrids)
	check("return to seeded saved form after browsing and legacy replay",bench.restore(record) and transforms()==full)
	for failure in ["source","seed","draw","range","count","recipe","membership","target","scale","duplicate","target_count"]:
		var bad: Dictionary=record.duplicate(true)
		match failure:
			"source":bad.signature="changed"
			"seed":bad.seed="9223372036854775808"
			"draw":bad.draws[0]=INF
			"range":bad.disorder=-0.1
			"count":bad.draws.resize(1)
			"recipe":bad.recipe="unknown"
			"membership":bad.hybrids[0].group=5
			"target":bad.hybrids[0].pose[9]=INF
			"scale":bad.hybrids[0].pose[0]=0;bad.hybrids[0].pose[1]=0;bad.hybrids[0].pose[2]=0
			"duplicate":bad.hybrids[1]=bad.hybrids[0].duplicate(true)
			"target_count":bad.hybrids.resize(1)
		check("reject invalid "+failure+" without changing the scene",not bench.restore(bad) and transforms()==full)
	check("visual copies have no source scripts",bench.pieces.all(func(part):return part.views.all(func(view):return view.get_script()==null)))
	check("display does not label disorder as entropy",bench.readout.text.contains("not an entropy reading"))

	check("receipt contains all fifty unique hybrid assignments",record.hybrids.size()==50 and bench.valid_record(record))
	var donors: Array=[{},{},{},{}]
	for entry in record.hybrids: donors[int(entry.group)][entry.item]=true
	check("each hybrid contains at least three source objects",donors.all(func(d):return d.size()>=3))
	check("original materials and geometry survive hybrid assembly",bench.pieces.all(func(p):return p.views[1].mesh==p.mesh and p.views[1].material_override==p.material))
	var forward: Dictionary={}
	for amount in [0.0,0.2,0.5,0.65,0.85,1.0]:
		bench.set_disorder(amount);forward[amount]=transforms()
	for amount in [1.0,0.85,0.65,0.5,0.2,0.0]:
		bench.set_disorder(amount)
		check("backward slider retraces exact poses at "+str(amount),transforms()==forward[amount])
	bench.set_disorder(0.5);var midpoint: Array=transforms()
	for amount in [0.499999,0.500001]:
		bench.set_disorder(amount);var continuous:=true
		for i in bench.pieces.size():
			var a: Transform3D=bench.pieces[i].views[1].transform
			var b: Transform3D=midpoint[i][1]
			continuous=continuous and a.origin.distance_to(b.origin)<0.0001 and a.basis.x.distance_to(b.basis.x)<0.0001
		check("continuous midpoint transition "+str(amount),continuous)
	var floor_safe:=true
	for step in 101:
		bench.set_disorder(step/100.0)
		for part in bench.pieces:
			for view in part.views: floor_safe=floor_safe and (view.transform*part.bounds).position.y>=bench.DECK_Y-0.00001
	check("no part below tray throughout the full journey",floor_safe)
	# A previous on-disk receipt must keep its original geometric interpretation.
	var old=JSON.parse_string(FileAccess.get_file_as_string("res://doc/book/iterations/2026-10-15-prefab-disorder/kept-trial.json"))
	check("version one receipt still opens",bench.restore(old))
	check("old maximum separation maps to new midpoint",bench.disorder==float(old.disorder)/2.0)
	var legacy_exact:=true
	for part in bench.pieces:
		var item: Dictionary=bench.inventory[part.item]
		var expected: Transform3D=Transform3D(Basis.IDENTITY,item.grid+Vector3(bench.SIDE,0,0))*bench.sample.displaced(part.home,part.bounds,part.draw,float(old.disorder))
		legacy_exact=legacy_exact and expected==part.views[1].transform
	check("legacy replay preserves old separated mesh transforms",legacy_exact)
	old.disorder=0.37
	check("legacy fractional record opens",bench.restore(old))
	legacy_exact=true
	for part in bench.pieces:
		var item: Dictionary=bench.inventory[part.item]
		var left: Transform3D=Transform3D(Basis.IDENTITY,item.grid+Vector3(-bench.SIDE,0,0))*bench.sample.displaced(Transform3D.IDENTITY,item.bounds,part.item*6,0.37)*part.home
		var right: Transform3D=Transform3D(Basis.IDENTITY,item.grid+Vector3(bench.SIDE,0,0))*bench.sample.displaced(part.home,part.bounds,part.draw,0.37)
		legacy_exact=legacy_exact and left==part.views[0].transform and right==part.views[1].transform
	check("legacy fractional record retains both exact arrangements",legacy_exact)
	bench.restore(record)
	bench.set_disorder(0.73);var middle: Array=transforms();press("KEEP")
	press("PARTS");check("PARTS preset reaches midpoint",bench.disorder==0.5)
	press("HYBRIDS");check("HYBRIDS preset reaches new assemblies",bench.disorder==1)
	press("REPLAY");check("disk replay preserves an intermediate graft",transforms()==middle and bench.disorder==0.73)
	check("latest record still restores the verified full hybrids",bench.restore(record) and transforms()==full)


	# Gallery tests use their own index and KEEP files, never the visitor's saves.
	bench.pointer_path="user://hybrid-gallery-acceptance-%d-latest.json" % Time.get_ticks_usec()
	bench.gallery_selected_path=""
	bench.restore(record)
	var saved_poses: Array=[];var saved_records: Array=[];var saved_paths: Array[String]=[]
	for n in 5:
		bench.set_disorder(0.73 if n==2 else 1.0)
		saved_poses.append(transforms());saved_records.append(bench.capture())
		saved_paths.append(bench.keep());press("SEED +1")
	check("five keeps append five distinct entries",bench.gallery_store.paths==saved_paths and saved_paths.size()==5)
	check("gallery index exists on disk",FileAccess.file_exists(bench.gallery_store.index_path))
	var untouched: Array=transforms();var sample_before: Array=bench.sample.draws.duplicate()
	press("GALLERY")
	check("gallery opens without changing experiment or RNG state",bench.gallery_open and transforms()==untouched and bench.sample.draws==sample_before)
	check("latest page exposes the fifth keep and empty slots",bench.gallery.page==1 and bench.gallery.slots[0].path==saved_paths[4] and not bench.gallery.slots[1].valid)
	check("empty slot cannot replace the experiment",not bench.gallery.replay_slot(1) and transforms()==untouched)
	bench.gallery.act("PREVIOUS")
	check("four kept entries appear side by side",bench.gallery.slots.size()==4 and bench.gallery.slots.all(func(slot):return slot.valid and slot.views.size()==50))
	check("gallery labels identify each seed and saved stage",bench.gallery.labels[0].text.contains("435") and bench.gallery.labels[2].text.contains("0.73"))
	var models_match:=true
	for slot in 4:
		for i in bench.pieces.size():
			models_match=models_match and bench.gallery.slots[slot].poses[i]==saved_poses[slot][i][1]
			models_match=models_match and bench.gallery.slots[slot].views[i].transform==bench.gallery.slots[slot].fit*saved_poses[slot][i][1]
	check("gallery miniatures show exact saved intermediate and endpoint poses",models_match)
	check("gallery hides the live experiment controls and their collisions",not bench.console.visible and collisions_off(bench.console))
	for i in 5: await process_frame
	await shot("gallery-four")
	var gallery_camera: Camera3D=preview.get_node("Camera");var previous_camera:=gallery_camera.transform
	gallery_camera.position=Vector3(0,2.6,3.4);gallery_camera.look_at(Vector3(0,1.35,-0.1));gallery_camera.fov=62
	await shot("gallery-close")
	gallery_camera.transform=previous_camera;gallery_camera.fov=44
	var area: Node=bench.gallery.buttons["REPLAY 3"].get_node("InteractableAreaButton")
	area.button_pressed.emit(area)
	check("physical gallery replay restores chosen intermediate arrangement",not bench.gallery_open and transforms()==saved_poses[2] and bench.disorder==0.73)
	check("return hides gallery controls and restores live collision layers",collisions_off(bench.gallery) and not collisions_off(bench.console))
	press("SEED +1");press("REPLAY")
	check("main REPLAY returns to the chosen gallery entry",transforms()==saved_poses[2])
	await shot("gallery-replayed")
	bench.show_gallery(true);bench.gallery.act("NEXT")
	check("next page retains the fifth entry",bench.gallery.slots[0].path==saved_paths[4])
	bench.gallery.replay_slot(0)
	check("replay from the second page restores that exact seed and shape",transforms()==saved_poses[4])
	bench.show_gallery(true);bench.gallery.act("PREVIOUS")
	bench.gallery.replay_slot(0)
	check("older first entry still replays after later keeps",transforms()==saved_poses[0])
	var resumed: Node3D=load("res://commons/artifacts/prefab_disorder/prefab_disorder.tscn").instantiate()
	resumed.pointer_path=bench.pointer_path;root.add_child(resumed)
	for i in 5: await process_frame
	resumed.show_gallery(true)
	check("new scene restores the full saved gallery",resumed.gallery_store.paths==saved_paths)
	resumed.gallery.page=0;resumed.gallery.refresh();resumed.gallery.replay_slot(1)
	var resumed_exact:=true
	for i in bench.pieces.size():
		for side in 2: resumed_exact=resumed_exact and resumed.pieces[i].views[side].transform==saved_poses[1][i][side]
	check("fresh-scene gallery replay reconstructs every transform",resumed_exact)
	resumed.queue_free()
	# Two open stores must retain entries added by either, without stale overwrites.
	var store_a=bench.GalleryStore.new();var store_b=bench.GalleryStore.new()
	store_a.bind(bench.pointer_path);store_b.bind(bench.pointer_path)
	var extra: String=bench.keep()
	check("stale open gallery merges the latest persisted entries",store_b.add(saved_paths[0]) and store_b.paths.size()==6 and store_b.paths.has(extra))
	check("index cannot accept paths outside kept experiment records",not store_b.add("res://project.godot"))
	# A missing record gets a placeholder and cannot mutate the current bench.
	var missing: String="user://prefab-disorder-missing-%d.json" % Time.get_ticks_usec()
	store_a.add(missing);bench.gallery_store.index_path="";bench.show_gallery(true)
	bench.gallery.page=1;bench.gallery.refresh()
	var unchanged: Array=transforms()
	check("unavailable keep remains visible and cannot be replayed",not bench.gallery.slots[2].valid and not bench.gallery.replay_slot(2) and transforms()==unchanged)
	bench.show_gallery(false)
	# Existing single-save pointers migrate into a new gallery without scanning files.
	var migration_pointer: String="user://hybrid-gallery-migration-%d.json" % Time.get_ticks_usec()
	FileAccess.open(migration_pointer,FileAccess.WRITE).store_string(JSON.stringify({"path":saved_paths[0]}))
	var migrated=bench.GalleryStore.new();migrated.bind(migration_pointer)
	check("previous single kept selection is available in the gallery",migrated.paths==[saved_paths[0]])
	check("first append preserves the previously kept selection",migrated.add(saved_paths[1]) and migrated.paths==[saved_paths[0],saved_paths[1]])
	# Malformed index must never be silently replaced by KEEP.
	var broken_pointer: String="user://hybrid-gallery-broken-%d.json" % Time.get_ticks_usec()
	var broken_path:=broken_pointer.get_basename()+"-gallery.json"
	FileAccess.open(broken_path,FileAccess.WRITE).store_string("broken index fixture")
	var broken=bench.GalleryStore.new();broken.bind(broken_pointer)
	check("corrupt gallery index is preserved instead of overwritten",not broken.add(saved_paths[0]) and FileAccess.get_file_as_string(broken_path)=="broken index fixture")
	FileAccess.open(DIR+"gallery-records.json",FileAccess.WRITE).store_string(JSON.stringify(saved_records,"  ",true,true))
	# Finish on the clean four-entry comparison for a review capture.
	bench.gallery_store.paths.assign(saved_paths);bench.gallery.page=0;bench.show_gallery(true)

	var report:={"passed":failures.is_empty(),"checks":checks,"failures":failures,"inventory":bench.inventory.map(func(item):return {"id":item.id,"parts":item.parts,"scale":item.factor}),"signature":bench.signature,"sampled_seeds":seeds.size(),"distinct_memberships":signatures.size(),"scope":"Native Godot geometry, control callbacks and file reconstruction; no heat, thermodynamic entropy or headset claim."}
	FileAccess.open(DIR+"verification.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("PREFAB HYBRIDS ",checks.size()," checks, failures=",failures)
	preview.queue_free()
	for i in 5: await process_frame
	quit(0 if failures.is_empty() else 1)
