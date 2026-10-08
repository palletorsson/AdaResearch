extends RefCounted
const Parts = preload("res://commons/primitives/pipes/part_library.gd")
const Network = preload("res://commons/primitives/pipes/run_network.gd")
class Hand extends Node3D:
	var picked_up_ranged := false

func run(tree: SceneTree, station: Node3D, camera: Camera3D) -> void:
	var body=station.specimen
	body.control(8)
	var old_camera:=camera.global_transform
	camera.global_position=station.to_global(Vector3(2.4,2.25,6.5)); camera.look_at(station.to_global(Vector3(0,2.65,-0.8)))
	var count:=0
	for page in 5:
		body.control(12 if page<4 else 13)
		var originals: Array=body.strokes.duplicate(true)
		var total_ports:=0
		for record in originals:
			count+=1
			var valid: bool=not record.part_meshes.is_empty() and not record.sockets.is_empty()
			for item in record.part_meshes:
				valid=valid and item.pose.is_finite() and item.mesh.get_surface_count()>0
			for socket in record.sockets:
				valid=valid and socket.point.is_finite() and body.PAINT_BOUNDS.has_point(socket.point)
				total_ports+=1
			tree.check("library "+record.part+" has geometry and reachable ports",valid)
		tree.check("every free port has a grip in "+Parts.GROUP_NAMES[page],body.ends.filter(func(e):return e.visible).size()==total_ports)
		# Extend every port of every actual part; compare the untouched inherited mesh.
		var completed:=true
		for handle in body.ends:
			if not handle.visible: continue
			var record: Dictionary=body.strokes[handle.stroke_index]
			var socket: Vector3=record.sockets[handle.port_index].point
			body.begin_extension(handle)
			body.capture_point(socket+Vector3(0,0,0.25))
			body.finish_stroke();body.held_end=null;body.blocked_until_release=false;body.sync_ends()
			completed=completed and body.strokes.size()==originals.size()+1 and body.strokes[-1].points[0].distance_to(socket)<0.001 and body.strokes[-1].get("ports",[]).size()>0
			body.control(4)
			completed=completed and body.strokes==originals
		tree.check("all ports extend and undo without moving parts in "+Parts.GROUP_NAMES[page],completed)
		body.rebuild()
		for i in 5: await tree.process_frame
		await RenderingServer.frame_post_draw
		tree.check("native form library page "+str(page),tree.root.get_texture().get_image().save_png(tree.OUT+"tube-parts-"+str(page)+".png")==OK)
	tree.check("all 16 segment forms and 5 cable arrangements covered",count==21)
	# Actual XR-tools pickup on a four-way branch port.
	body.parts_example(1); body.rebuild(); body.sync_ends()
	var before: Array=body.strokes.duplicate(true)
	var handle=body.ends[20] # Cross: run 2, third port.
	var hand:=Hand.new(); tree.root.add_child(hand); hand.global_transform=handle.global_transform
	handle.pick_up(hand)
	for i in 3: await tree.physics_frame
	body._physics_process(0.016)
	for i in 8:
		hand.position+=station.global_basis*Vector3(-0.12,-0.08,0.04)
		for j in 3: await tree.physics_frame
		body._physics_process(0.016)
	handle.let_go(hand,Vector3.ZERO,Vector3.ZERO);body._physics_process(0.016)
	tree.check("XR pickup can extend a third junction port",body.strokes.size()==before.size()+1 and body.strokes[-1].get("ports",[]).size()>0)
	body.rebuild()
	for i in 5: await tree.process_frame
	await RenderingServer.frame_post_draw
	tree.check("native library port extension capture",tree.root.get_texture().get_image().save_png(tree.OUT+"tube-parts-extended.png")==OK)
	body.control(4)
	tree.check("XR part extension undo restores exact parts",body.strokes==before)
	# Connect two different stock pieces through the same sampled gesture entry.
	var start: Vector3=body.strokes[2].sockets[2].point
	var target: Vector3=body.strokes[1].sockets[-1].point
	body.begin_extension(body.ends[20])
	for i in 25:
		var t:=float(i+1)/25
		body.capture_point(start.lerp(target,t)+Vector3(0,-0.5*sin(PI*t),0.3*sin(PI*t)))
	body.finish_stroke();body.held_end=null;body.sync_ends()
	tree.check("new run connects two stock forms through both named ports",body.strokes.size()==5 and body.strokes[-1].get("ports",[]).size()==2 and Network.connected(body.strokes[2],start) and Network.connected(body.strokes[1],target))
	tree.check("connected stock ports no longer expose free grips",not body.ends[20].visible)
	body.rebuild()
	for i in 5: await tree.process_frame
	await RenderingServer.frame_post_draw
	tree.check("native connected library capture",tree.root.get_texture().get_image().save_png(tree.OUT+"tube-parts-connected.png")==OK)
	body.control(4)
	tree.check("undo restores both stock ports and removes joining run",body.strokes==before)
	hand.queue_free();body.control(8);body.history.clear();camera.global_transform=old_camera
