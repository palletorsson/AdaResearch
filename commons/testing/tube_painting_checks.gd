extends RefCounted
class Hand extends Node3D:
	var picked_up_ranged := false

func run(tree: SceneTree, station: Node3D, camera: Camera3D) -> void:
	var body = station.specimen
	var surface = load("res://commons/artifacts/spine_studies/tube_surface.gd")
	var points := PackedVector3Array([Vector3.ZERO,Vector3(0,1,0),Vector3(0,2,0)])
	var built: Dictionary = surface.build(points,0.1,12)
	tree.check("tube topology has rings, caps and bounded indices",built.vertices.size()==62 and built.indices.size()==216)
	var valid := true; var radial := true
	for i in built.indices: valid = valid and i>=0 and i<built.vertices.size()
	for v in built.vertices: valid = valid and v.is_finite()
	for n in built.normals: valid = valid and absf(n.length()-1.0)<0.001
	for i in built.rings.size(): radial = radial and absf(built.rings[i].distance_to(points[i/12])-0.1)<0.0001
	tree.check("vertical transport has finite unit normals",valid)
	tree.check("each ring retains its centre and radius",radial)
	var clockwise := true
	for i in range(0,built.indices.size(),3):
		var a: int = built.indices[i]; var b: int = built.indices[i+1]; var c: int = built.indices[i+2]
		clockwise = clockwise and (built.vertices[b]-built.vertices[a]).cross(built.vertices[c]-built.vertices[a]).dot(built.normals[a]) < 0.0
	tree.check("side and cap faces use Godot clockwise fronts",clockwise)
	var fewer: Dictionary = surface.build(points,0.1,8)
	tree.check("ring resolution changes mesh without changing path",fewer.points==built.points and fewer.indices.size()==144)
	var folded: Dictionary = surface.build(PackedVector3Array([Vector3.ZERO,Vector3.ZERO,Vector3.UP,Vector3.ZERO]),0.1,12)
	valid = folded.points.size()==3
	for n in folded.normals: valid = valid and n.is_finite() and n.length()>0.99
	tree.check("duplicate and reversed path remains finite",valid)
	tree.check("one point has no surface",surface.build(PackedVector3Array([Vector3.ONE]),0.1,12).is_empty())
	body.set_physics_process(false)
	body.control(8)
	tree.check("three begun strokes with six accessible ends",body.strokes.size()==3 and body.ends.filter(func(e): return e.visible).size()==6)
	var original: PackedVector3Array = body.strokes[0].points.duplicate()
	var handle = body.ends[1]
	var hand := Hand.new(); tree.root.add_child(hand); hand.global_transform=handle.global_transform
	handle.pick_up(hand)
	for i in 5: await tree.physics_frame
	body._physics_process(0.016)
	tree.check("XR pickup selects an existing end",body.held_end==handle and body.editing==0)
	for i in 8:
		hand.position += station.global_basis * Vector3(0.09,0,0.06)
		for j in 3: await tree.physics_frame
		body._physics_process(0.016)
	tree.check("grabbing extends rather than moving inherited path",body.active.size()>original.size() and body.active.slice(0,original.size())==original)
	body.control(5)
	tree.check("clear refuses while an end is held",body.strokes.size()==3 and not body.return_message.is_empty())
	handle.let_go(hand,Vector3.ZERO,Vector3.ZERO)
	body._physics_process(0.016)
	tree.check("release leaves extension suspended",body.strokes[0].points.size()>original.size() and handle.freeze and body.held_end==null)
	body.control(4)
	tree.check("undo restores pre-gesture work",body.strokes[0].points==original and body.strokes.size()==3)
	# The opposite endpoint reverses construction order without losing the inherited path.
	handle=body.ends[0]; hand.global_transform=handle.global_transform; handle.pick_up(hand)
	for i in 4: await tree.physics_frame
	body._physics_process(0.016)
	var reversed := original.duplicate(); reversed.reverse()
	tree.check("either endpoint can be continued",body.active==reversed)
	body.capture_point(body.active[-1]+Vector3(-0.1,-0.1,0.1))
	handle.let_go(hand,Vector3.ZERO,Vector3.ZERO); body._physics_process(0.016)
	body.control(4)
	# Wall attachment keeps the already drawn length and ends exactly at the wall.
	body.begin_extension(body.ends[1])
	while body.active[-1].z > -2.79:
		body.capture_point(body.active[-1]+Vector3(0,0,-0.12))
		if body.blocked_until_release: break
	tree.check("wall attachment stops at the receiving surface",body.wall_attached and is_equal_approx(body.active[-1].z,body.WALL_Z))
	body.finish_stroke(); body.held_end=null; body.blocked_until_release=false; body.sync_ends()
	tree.check("attachment retains old points",body.strokes[0].points.slice(0,original.size())==original and body.strokes[0].attached)
	body.control(4)
	# Real desktop pickup and trigger route, driving the production pen nib.
	var pointer=load("res://commons/scenes/DesktopInteractionPointer.gd").new(); tree.root.add_child(pointer)
	pointer.set_process(false); pointer._camera=camera
	var eye := camera.global_transform
	camera.global_position=body.pen.global_position+station.global_basis*Vector3(0,0,1.5)
	camera.look_at(body.pen.to_global(Vector3(0,0,-0.04)))
	for i in 4: await tree.physics_frame
	tree.check("desktop ray finds supplied pen",pointer._find_grabbable()==body.pen)
	pointer._grab_held(body.pen); pointer._process(0.016)
	tree.check("held desktop trigger dispatches",pointer._try_held_action(true) and body.pen.painting)
	for i in 9:
		camera.position += station.global_basis*Vector3(0.085,0.04,-0.06)
		pointer._process(0.016); body._physics_process(0.016)
	pointer._try_held_action(false); body._physics_process(0.016)
	tree.check("pen release keeps a separate actual nib path",body.strokes.size()==4 and body.strokes[-1].points.size()>2)
	body.control(7)
	tree.check("pen home refuses a held pen",body.pen.desktop_held and not body.return_message.is_empty())
	pointer._drop_held(); body._physics_process(0.016)
	tree.check("dropping ends drawing without falling",not body.pen.painting and body.pen.freeze)
	pointer.queue_free(); hand.queue_free(); camera.global_transform=eye
	body.control(4)
	tree.check("undo removes only the new stroke",body.strokes.size()==3 and body.strokes[0].points==original)
	var before: Array=body.strokes.duplicate(true)
	for i in 3: body.control(3)
	tree.check("path rings and tube share one record",body.strokes==before)
	body.control(0)
	tree.check("thickness edits only the last radius",body.strokes[0]==before[0] and body.strokes[-1].points==before[-1].points and body.strokes[-1].radius!=before[-1].radius and body.strokes[-1].colour==before[-1].colour)
	body.control(4); body.control(5)
	body.capture_point(Vector3(0,1,0)); body.capture_point(Vector3(0.01,1,0))
	tree.check("near stationary nib does not pile up rings",body.active.size()==1)
	body.capture_point(Vector3(0.1,1,0)); body.capture_point(Vector3(3,1,0))
	tree.check("sudden jump cannot make a long bridge",body.active.size()==2 and body.blocked_until_release)
	body.finish_stroke(); body.blocked_until_release=false; body.control(5)
	for i in 280:
		var angle := i*0.08
		body.capture_point(Vector3(cos(angle),1+0.2*sin(angle*0.5),sin(angle)))
	tree.check("stroke budget stops at 256 retained samples",body.active.size()==256 and body.blocked_until_release)
	body.finish_stroke(); body.blocked_until_release=false
	for j in 7:
		body.capture_point(Vector3(0,1,0)); body.capture_point(Vector3(0.1,1,0)); body.finish_stroke()
	body.capture_point(Vector3(0,1,0))
	tree.check("eight stroke budget retains existing work",body.strokes.size()==8 and body.active.is_empty() and body.blocked_until_release)
	body.blocked_until_release=false
	body.capture_point(Vector3(INF,0,0)); body.capture_point(Vector3(100,1,0))
	tree.check("invalid outside positions cannot enter the mesh",body.active.is_empty())
	body.control(8)
	camera.global_position=station.to_global(Vector3(3.6,1.8,5.0)); camera.look_at(station.to_global(Vector3(0,2.15,-1.2)))
	for state in ["path","rings","skin","continued"]:
		if state=="path": body.view_mode=0
		if state=="rings": body.view_mode=1
		if state=="skin": body.view_mode=2
		if state=="continued":
			# Deterministic replay through the same sampled-position entry as either pickup.
			body.begin_extension(body.ends[1])
			var start: Vector3=body.active[-1]
			for i in 31:
				var t := float(i)/30
				body.capture_point(start+Vector3(1.35*sin(PI*t),0.6*sin(TAU*t),-2.5*t))
			body.finish_stroke(); body.held_end=null; body.blocked_until_release=false; body.sync_ends()
		body.rebuild()
		for i in 6: await tree.process_frame
		await RenderingServer.frame_post_draw
		tree.check("native tube capture "+state,tree.root.get_texture().get_image().save_png(tree.OUT+"tube-"+state+".png")==OK)
	await load("res://commons/testing/run_network_checks.gd").new().run(tree,station,camera)
	await load("res://commons/testing/part_library_checks.gd").new().run(tree,station,camera)
	await load("res://commons/testing/patch_motion_checks.gd").new().run(tree,station,camera)
	await load("res://commons/testing/pipe_ceiling_checks.gd").new().run(tree,station,camera)
	body.control(8); body.history.clear(); body.set_physics_process(true)
