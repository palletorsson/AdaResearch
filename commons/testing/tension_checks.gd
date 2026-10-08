extends RefCounted
class TensileTestHand extends Node3D:
	var picked_up_ranged := false

func run(tree: SceneTree, station: Node3D, camera: Camera3D) -> void:
	var body=station.specimen
	var score=body.score
	body.set_physics_process(false)
	station.controls[4].pointer_event(tree.Press.new())
	var original_pins:PackedVector3Array=PackedVector3Array()
	for i in score.pins: original_pins.append(score.points[i])
	var unloaded:Vector3=score.load_position()
	station.controls[2].pointer_event(tree.Press.new())
	for i in 720: score.step()
	var loaded:Vector3=score.load_position()
	tree.check("load changes centre height with same anchors",score.load_kg==1.0 and loaded.y<unloaded.y-0.025)
	station.controls[3].pointer_event(tree.Press.new())
	for i in 720: score.step()
	tree.check("more give settles lower under same load",score.compliance>0.004 and score.load_position().y<loaded.y-0.015)
	var same:=true
	for i in score.pins.size(): same=same and score.points[score.pins[i]].is_equal_approx(original_pins[i])
	tree.check("four anchors remain fixed under load and give",same)
	station.controls[4].pointer_event(tree.Press.new())
	tree.check("reset restores exact initial settled state",score.load_kg==0.0 and score.load_position().is_equal_approx(unloaded))
	station.controls[0].pointer_event(tree.Press.new())
	for i in 240: body._physics_process(score.STEP)
	var held:Vector3=score.points[score.grip_index]
	tree.check("repeatable pull holds the material point",held.distance_to(Vector3(0,2.1,1.75))<0.001)
	station.controls[1].pointer_event(tree.Press.new())
	for i in 720: body._physics_process(score.STEP)
	tree.check("release moves without the visitor",not score.grip_held and score.points[score.grip_index].distance_to(held)>0.3)
	var late:Vector3=score.points[score.grip_index]
	for i in 360: score.step()
	tree.check("released motion damps towards unloaded state",score.points[score.grip_index].distance_to(late)<0.06)
	var grabber:=TensileTestHand.new(); tree.root.add_child(grabber)
	grabber.global_transform=body.handle.global_transform
	body.handle.pick_up(grabber)
	tree.check("XR grab acquires the fabric handle",body.handle.is_picked_up())
	grabber.position+=Vector3(0.4,0.1,0.3)
	for i in 8: await tree.physics_frame
	body._physics_process(0.016)
	tree.check("held XR position drives the membrane",score.grip_held and score.points[score.grip_index].distance_to(score.bounded_target(body.to_local(body.handle.global_position)))<0.001)
	station.controls[4].pointer_event(tree.Press.new())
	tree.check("reset refuses to move a held handle",not body.return_message.is_empty() and body.handle.is_picked_up())
	body.handle.let_go(grabber,Vector3.ZERO,Vector3.ZERO)
	body._physics_process(0.016)
	tree.check("XR release hands motion back to solver",not score.grip_held and body.handle.freeze)
	grabber.queue_free()
	var pointer=load("res://commons/scenes/DesktopInteractionPointer.gd").new(); tree.root.add_child(pointer)
	pointer.set_process(false); pointer._camera=camera
	var eye:=camera.global_transform
	camera.global_position=body.handle.global_position+station.global_basis*Vector3(0,0,1.5)
	camera.look_at(body.handle.global_position)
	for i in 3: await tree.physics_frame
	tree.check("desktop ray finds pink grip",pointer._find_grabbable()==body.handle)
	pointer._grab_held(body.handle); pointer._process(0.016); body._physics_process(0.016)
	tree.check("desktop pickup drives the same material point",body.handle.desktop_held and score.grip_held)
	pointer._drop_held(); body._physics_process(0.016)
	tree.check("desktop release restores solver ownership",not body.handle.desktop_held and not score.grip_held and body.handle.collision_layer==4)
	pointer.queue_free(); camera.global_transform=eye
	score.grip_held=true; score.grip_target=Vector3(100,-100,100)
	for i in 80: score.step()
	var bounded:=true
	for p in score.points: bounded=bounded and p.is_finite() and p.y>=0.119 and p.length()<15
	tree.check("extreme grab remains finite and above floor",bounded)
	station.controls[4].pointer_event(tree.Press.new())
	camera.global_position=station.to_global(Vector3(4.3,1.75,5.6))
	camera.look_at(station.to_global(Vector3(0,1.9,0)))
	for state in ["rest","pull","loaded"]:
		if state=="pull":
			station.controls[0].pointer_event(tree.Press.new())
			for i in 360: body._physics_process(score.STEP)
		if state=="loaded":
			station.controls[1].pointer_event(tree.Press.new())
			station.controls[2].pointer_event(tree.Press.new()); station.controls[2].pointer_event(tree.Press.new())
			for i in 960: body._physics_process(score.STEP)
		for i in 6: await tree.process_frame
		await RenderingServer.frame_post_draw
		tree.check("native membrane capture "+state,tree.root.get_texture().get_image().save_png(tree.OUT+"tension-"+state+".png")==OK)
	station.controls[4].pointer_event(tree.Press.new())
	body.set_physics_process(true)
