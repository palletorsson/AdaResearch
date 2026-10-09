extends "res://tools/probes/transformation_encounters.gd"

class SuppliedGrabber extends Node3D:
	var picked_up_ranged := false

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(1.0).timeout
	if map_id=="Point_Trace":await ball_checks()
	else:await triangle_checks()

func ball_checks() -> void:
	var ramp := find_scene("/trace_ball_ramp.gd")
	check("ball, plinth and ramp are placed",ramp!=null)
	if ramp==null:return
	check("black point has production pickup and gravity release",ramp.ball is RigidBody3D and ramp.ball.has_method("pick_up") and ramp.ball.release_mode==0)
	check("ball starts on its one metre plinth",ramp.ball.position.distance_to(ramp.HOME)<0.01)
	check("point waits without drawing",ramp.samples.is_empty())
	observations["ramp_world"]=xyz(ramp.global_position)
	await snapshot("ball-on-plinth",ramp.to_global(Vector3(-3.1,1.7,3.7)),ramp.to_global(Vector3(0,0.65,1.6)),64)
	var grabber := SuppliedGrabber.new();root.add_child(grabber)
	grabber.global_transform=ramp.ball.global_transform
	ramp.ball.pick_up(grabber)
	check("production pickup suspends recording",ramp.held and not ramp.recording)
	grabber.global_position=ramp.to_global(Vector3(0,1.14,0.88))
	await create_timer(0.3).timeout
	check("held ball follows the supplied hand onto plank",ramp.ball.global_position.distance_to(grabber.global_position)<0.1)
	ramp.ball.let_go(grabber,Vector3.ZERO,Vector3.ZERO)
	var released: Vector3=ramp.ball.global_position
	await create_timer(1.5).timeout
	var rolling: Vector3=ramp.to_local(ramp.ball.global_position)
	check("zero-impulse release rolls downhill under gravity",rolling.z>1.4 and ramp.ball.global_position.y<released.y)
	check("actual motion grows a trace",ramp.samples.size()>15)
	await snapshot("ball-rolling",ramp.to_global(Vector3(-2.5,1.7,3.9)),ramp.to_global(Vector3(0,0.65,2.2)),67)
	await create_timer(6.0).timeout
	var landed: Vector3=ramp.to_local(ramp.ball.global_position)
	observations["landed_local"]=xyz(landed)
	observations["samples"]=ramp.samples.size()
	check("ball remains supported in the landing tray",landed.z>3.75 and landed.z<5.4 and landed.y>0.14 and landed.y<0.23)
	check("trace follows measured centres",ramp.samples[-1].distance_to(landed)<0.04)
	var count: int=ramp.samples.size()
	await create_timer(1.5).timeout
	check("rest does not accumulate points",ramp.samples.size()==count)
	await snapshot("ball-path",ramp.to_global(Vector3(-3.8,1.7,3.5)),ramp.to_global(Vector3(0,0.65,2.6)),70)
	grabber.global_transform=ramp.ball.global_transform
	ramp.ball.pick_up(grabber)
	grabber.global_position=ramp.to_global(ramp.HOME)
	await create_timer(0.2).timeout
	check("the ball can be carried back",ramp.to_local(ramp.ball.global_position).distance_to(ramp.HOME)<0.1)
	ramp.ball.let_go(grabber,Vector3.ZERO,Vector3.ZERO)
	await create_timer(0.3).timeout
	check("next release starts a new bounded trace",ramp.samples.size()<count and ramp.segment_count<=ramp.CAPACITY)
	grabber.queue_free()
	var walker:=CharacterBody3D.new();walker.collision_layer=0;walker.collision_mask=1
	var collision:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new();capsule.radius=0.28;capsule.height=1.6
	collision.shape=capsule;collision.position.y=0.8;walker.add_child(collision);root.add_child(walker)
	walker.global_position=ramp.to_global(Vector3(-4.1,0.025,2.1))
	await physics_frame
	check("side bay has an open walking approach",walker.move_and_collide(Vector3(2.7,0,0))==null)
	walker.queue_free()

func triangle_checks() -> void:
	var twin:=find_scene("/triangle_live_twin.gd")
	check("central live twin is placed",twin!=null and twin.source!=null)
	if twin==null or twin.source==null:return
	var source: Node3D=twin.source
	check("small creator starts with an editable triangle",source.placed_points.size()==3 and source.completed_triangles.size()==1)
	check("same three points appear at both scales",twin.large_points.size()==3 and twin.triangle_count==1)
	check("white fill and black physical outlines",source.completed_triangles[0].mesh.material_override==twin.white and twin.edge_pairs.size()==3)
	check("small black outlines share the world-coordinate vertices",twin.small_edges.global_transform.is_equal_approx(Transform3D.IDENTITY))
	observations["source_world"]=xyz(source.global_position);observations["twin_world"]=xyz(twin.global_position)
	await snapshot("triangle-in-the-hall",twin.to_global(Vector3(-2.1,1.7,-4.2)),twin.to_global(Vector3(-0.6,1.9,-0.7)),63)
	await snapshot("triangle-small",source.to_global(Vector3(0,0.40,-1.8)),source.global_position+Vector3.UP*0.1,54)
	var handle: RigidBody3D=source.point_indicators[2]
	var original: Vector3=handle.global_position
	var before: Vector3=twin.large_points[2]
	var grabber:=SuppliedGrabber.new();root.add_child(grabber);grabber.global_transform=handle.global_transform
	handle.pick_up(grabber)
	grabber.global_position+=Vector3(0.2,0.1,0.2)
	await create_timer(0.35).timeout
	check("a held corner changes the large twin immediately",twin.large_points[2].distance_to(before)>0.5)
	var expected: Vector3=twin.CENTRE+source.to_local(handle.global_position)*twin.ENLARGEMENT
	check("enlargement preserves the exact vertex relation",twin.large_points[2].distance_to(expected)<0.01)
	handle.let_go(grabber,Vector3.ZERO,Vector3.ZERO)
	await create_timer(0.2).timeout
	source.toggle_fill_visibility();await create_timer(0.1).timeout
	check("fill toggle affects both scales and retains edges",not twin.faces.visible and not source.completed_triangles[0].mesh.visible and twin.edge_pairs.size()==3)
	source.toggle_fill_visibility()
	# Draw a folded quadrilateral through the actual creator's point/closure methods.
	source.clear_all()
	for p in [Vector3(-0.58,-0.24,0),Vector3(0.58,-0.24,0),Vector3(0.35,0.5,0.15),Vector3(-0.5,0.4,0.38)]:source._create_new_point(source.to_global(p))
	source._handle_snap_to_point(0);source._rebuild_lines()
	await create_timer(0.15).timeout
	check("four corners create two faces and one visible diagonal",twin.triangle_count==2 and twin.edge_pairs.size()==5)
	var previous: Array=twin.edge_pairs.duplicate(true)
	check("existing SHIFT START accepts the completed drawing",source.shift_start())
	await create_timer(0.15).timeout
	check("SHIFT START changes the displayed internal diagonal",twin.edge_pairs!=previous and twin.triangle_count==2)
	await snapshot("triangle-folded",twin.to_global(Vector3(-2.6,1.7,-3.9)),twin.to_global(Vector3(-0.15,1.9,0.2)),57)
	# A carried outline must be on this plinth, never at the world origin.
	var carried: Array=source._carry_flatten([Vector3(200,10,200),Vector3(201,11,201),Vector3(202,12,200)])
	check("carried points are transformed into the moved creator's world space",carried[0].distance_to(source.global_position)<1.2 and carried[2].distance_to(source.global_position)<1.2)
	source.clear_all();await create_timer(0.12).timeout
	check("clear removes both copies without reseeding",twin.large_points.is_empty() and twin.faces.mesh==null and twin.large_edges.multimesh.instance_count==0)
	# Restore the real editable starting triangle for the final view.
	for p in [Vector3(-0.58,-0.24,0),Vector3(0.58,-0.24,0),Vector3(-0.12,0.56,0)]:source._create_new_point(source.to_global(p))
	source._handle_snap_to_point(0);source._rebuild_lines();await create_timer(0.12).timeout
	await snapshot("triangle-two-scales",twin.to_global(Vector3(-3.5,1.7,-3.6)),twin.to_global(Vector3(-1,1.7,-0.6)),72)
	grabber.queue_free()

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"map":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Native museum physics, production pickup with supplied grabber, shared vertices and real renders. Headset feel untested."},"  "))
	quit(0 if failures.is_empty() else 1)
