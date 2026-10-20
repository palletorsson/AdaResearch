extends SceneTree
const DIR="res://doc/book/iterations/2026-10-15-prefab-hybrids/"
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
func run() -> void:
	root.size=Vector2i(1600,1050)
	var preview: Node3D=load(SCENE).instantiate();root.add_child(preview)
	bench=preview.bench;bench.pointer_path="user://prefab-hybrids-test-latest.json"
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
	press("SEED +1");check("new seed changes separation draws but keeps hybrid endpoints",transforms()==full and bench.sample.draws!=draws and bench.experiment_seed==436)
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
			"scale":bad.hybrids[0].pose[0]=0
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
	bench.set_disorder(0.73);var middle: Array=transforms();press("KEEP")
	press("PARTS");check("PARTS preset reaches midpoint",bench.disorder==0.5)
	press("HYBRIDS");check("HYBRIDS preset reaches new assemblies",bench.disorder==1)
	press("REPLAY");check("disk replay preserves an intermediate graft",transforms()==middle and bench.disorder==0.73)
	check("latest record still restores the verified full hybrids",bench.restore(record) and transforms()==full)

	var report:={"passed":failures.is_empty(),"checks":checks,"failures":failures,"inventory":bench.inventory.map(func(item):return {"id":item.id,"parts":item.parts,"scale":item.factor}),"signature":bench.signature,"scope":"Native Godot geometry, control callbacks and file reconstruction; no heat, thermodynamic entropy or headset claim."}
	FileAccess.open(DIR+"verification.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("PREFAB HYBRIDS ",checks.size()," checks, failures=",failures)
	preview.queue_free()
	for i in 5: await process_frame
	quit(0 if failures.is_empty() else 1)
