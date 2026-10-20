extends "res://tools/probes/snapshot_examples.gd"
func landing_checks() -> void:
	await super.landing_checks()
	completed=false
	var gallery=find_scene("/soft_snapshot_gallery/sampled_gallery.gd")
	check("Source gallery installed in the actual hall",gallery!=null)
	if gallery==null:return
	check("Six source configurations available",gallery.samples.size()==6)
	var ids: Array=[]
	for sample in gallery.samples:
		ids.append(sample.id)
		var finite:=true
		for v in gallery.decode(sample.kept):finite=finite and v.is_finite()
		check(sample.id+" has changed, finite saved geometry",sample.initial!=sample.kept and gallery.decode(sample.kept).size()==sample.initial.size() and finite)
	check("Gallery includes cloth, lattice, branch, CA and moulds",ids==["sb01_cloth_drape_corners","sb06_jelly_grid_settle","sb_ls01_plant_skeleton","sb_ca02_life_without_death_cloth","gm03_box_in_cube_mould","gm04_pressed_onto_sphere"])
	var approach:Vector3=gallery.to_global(Vector3(-3.7,.01,3.4))
	check("Gallery controls have supported clear approach",hits(approach).is_empty() and not floor_at(approach).is_empty())
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver);driver.spawn(approach,museum)
	await snapshot("gallery-kept",gallery.to_global(Vector3(4.3,3,8.5)),gallery.to_global(Vector3(0,1.5,0)),57)
	var frames: Array=[]
	for n in gallery.display.get_children():
		if n.get_class()=="Node3D":frames.append(n.transform)
	var result:Dictionary=await driver.press(gallery.buttons.POSE,approach);await tick()
	check("Real POSE button selects exact starting positions",not gallery.kept and gallery.displayed_positions[0]==gallery.decode(gallery.samples[0].initial))
	var other_frames:Array=[]
	for n in gallery.display.get_children():
		if n.get_class()=="Node3D":other_frames.append(n.transform)
	check("Start and kept use identical display frame and scale",frames==other_frames)
	await snapshot("gallery-start",gallery.to_global(Vector3(4.3,3,8.5)),gallery.to_global(Vector3(0,1.5,0)),57)
	result=await driver.press(gallery.buttons.NEXT,approach);await tick()
	check("Real NEXT button selects second source set",gallery.bank==1 and gallery.visible_ids==["sb_ca02_life_without_death_cloth","gm03_box_in_cube_mould","gm04_pressed_onto_sphere"])
	result=await driver.press(gallery.buttons.POSE,approach);await tick()
	check("Second set matches source snapshot data",gallery.kept and gallery.displayed_positions[1]==gallery.decode(gallery.samples[4].kept))
	await snapshot("gallery-moulds",gallery.to_global(Vector3(4.3,3,8.5)),gallery.to_global(Vector3(0,1.5,0)),57)
	await driver.teardown();driver.queue_free();await tick()
	var origin:=XROrigin3D.new();root.add_child(origin);var hand:=XRController3D.new();origin.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	hand.global_position=gallery.point.global_position;gallery.point.pick_up(pickup);await tick();gallery.point.action();await tick()
	check("Inherited PointBody trigger switches to starting form",gallery.point.is_picked_up() and not gallery.kept)
	gallery.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick()
	check("Gallery point returns within reach after release",gallery.point.position.is_equal_approx(gallery.home))
	origin.queue_free();gallery.act("NEXT");gallery.act("POSE");await tick()
	observations.gallery_ids=ids
	observations.gallery_scope="Six frozen source-gallery results, three shown at a time. Display triangles added to cloth and sphere grids; spring network preserved. No running cloth interaction or glass-fluid simulation claimed."
	completed=true
