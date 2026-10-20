extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
	root.size=Vector2i(1600,1050)
	museum.call("flush_stamps")
	await create_timer(0.5).timeout
	var bench:=find_scene("/prefab_disorder.gd")
	var accounts:=find_scene("/entropy_compartments.gd")
	check("prefab study and Shannon/Boltzmann instrument both installed",bench!=null and accounts!=null)
	if bench==null: return
	bench.pointer_path="user://hybrid-gallery-museum-%d-latest.json" % Time.get_ticks_usec()
	observations.position=xyz(bench.global_position)
	check("four source objects and fifty mesh parts",bench.inventory.size()==4 and bench.pieces.size()==50)
	check("study faces the entrance",is_equal_approx(fposmod(bench.rotation_degrees.y,360),180))
	for x in [-1.7,0.0,1.7]:
		var p: Vector3=bench.to_global(Vector3(x,0,2.12))
		var hit:=floor_at(p)
		check("supported approach "+str(x),not hit.is_empty() and absf(hit.position.y-p.y)<0.05)
		var shape:=CapsuleShape3D.new();shape.radius=0.22;shape.height=1.6
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1
		query.transform=Transform3D(Basis(),p+Vector3.UP*0.85)
		check("clear standing space "+str(x),bench.get_world_3d().direct_space_state.intersect_shape(query).is_empty())
	var sy: float=bench.slider.global_position.y-bench.global_position.y
	check("slider within standing reach band",sy>=0.7 and sy<=1.4)
	await snapshot("hall-zero",bench.to_global(Vector3(0,2.3,2.12)),bench.to_global(Vector3(0,1.30,-0.10)),74)
	bench.slider.set_normalized_value(0.5);bench.slider.slider_moved.emit(Vector3.ZERO)
	check("real slider callback changes the installed study",is_equal_approx(bench.disorder,0.5))
	await snapshot("hall-half",bench.to_global(Vector3(0,2.3,2.12)),bench.to_global(Vector3(0,1.30,-0.10)),74)
	bench.set_disorder(1)
	await snapshot("hall-full",bench.to_global(Vector3(0,2.3,2.12)),bench.to_global(Vector3(0,1.30,-0.10)),74)
	var targets: Array=[]
	for part in bench.pieces: targets.append(part.views[1].transform)
	bench.keep()
	var previous: Array=bench.hybrids.duplicate(true)
	var seed_button: Node=bench.buttons["SEED +1"].get_node("InteractableAreaButton")
	seed_button.button_pressed.emit(seed_button)
	check("hall seed button changes hybrid membership and targets",bench.experiment_seed==436 and bench.hybrids!=previous)
	await snapshot("hall-seed-436",bench.to_global(Vector3(0,2.3,2.12)),bench.to_global(Vector3(0,1.30,-0.10)),74)
	bench.act("ZERO");bench.replay_saved()
	var exact:=true
	for i in bench.pieces.size(): exact=exact and bench.pieces[i].views[1].transform==targets[i]
	check("hall replay restores every hybrid part",exact)
	check("all four hybrids combine multiple source prefabs",bench.valid_hybrids(bench.capture()))
	for key in ["ORIGINAL","PARTS","HYBRIDS"]:
		var area: Node=bench.buttons[key].get_node("InteractableAreaButton")
		area.button_pressed.emit(area)
		check("hall physical preset "+key,is_equal_approx(bench.disorder,{"ORIGINAL":0.0,"PARTS":0.5,"HYBRIDS":1.0}[key]))
	await snapshot("hall-hybrid-detail",bench.to_global(Vector3(1.18,2.35,1.9)),bench.to_global(Vector3(1.18,1.28,-0.1)),51)
	check("saved slider and offsets reopen in the hall",is_equal_approx(bench.disorder,1) and bench.experiment_seed==435)
	check("Shannon/Boltzmann inventory and readings remain intact",accounts.model.shannon_colour()==1 and accounts.model.multiplicity()==1)
	# Preserve three more variants, then choose an older gallery entry through its physical button.
	for i in 3:
		seed_button.button_pressed.emit(seed_button)
		bench.set_disorder(0.73 if i==1 else 1.0)
		bench.keep()
	var live_before: Dictionary=bench.capture()
	var gallery_button: Node=bench.buttons["GALLERY"].get_node("InteractableAreaButton")
	gallery_button.button_pressed.emit(gallery_button)
	check("physical GALLERY opens four retained sets",bench.gallery_open and bench.gallery.slots.size()==4 and bench.gallery.slots.all(func(slot):return slot.valid))
	check("opening gallery preserves the live experiment",bench.capture()==live_before)
	check("gallery labels expose seed and saved stage",bench.gallery.labels[0].text.contains("435") and bench.gallery.labels[2].text.contains("0.73"))
	check("gallery shows all fifty parts in every saved set",bench.gallery.slots.all(func(slot):return slot.views.size()==50))
	await snapshot("hall-gallery",bench.to_global(Vector3(0,2.55,2.65)),bench.to_global(Vector3(0,1.30,-0.1)),74)
	var replay_button: Node=bench.gallery.buttons["REPLAY 1"].get_node("InteractableAreaButton")
	replay_button.button_pressed.emit(replay_button)
	exact=true
	for i in bench.pieces.size(): exact=exact and bench.pieces[i].views[1].transform==targets[i]
	check("physical gallery replay restores the first kept arrangement",exact and bench.experiment_seed==435 and bench.disorder==1 and not bench.gallery_open)
	await snapshot("hall-gallery-replayed",bench.to_global(Vector3(0,2.3,2.12)),bench.to_global(Vector3(0,1.30,-0.10)),74)
	observations.scope="Actual hall, native controls, approach collision checks and saved replay; no headset trial."
