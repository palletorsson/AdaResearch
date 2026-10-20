extends "res://tools/probes/transformation_encounters.gd"
var source_origin: Vector3
func map_at(p: Vector3) -> Vector3:return source_origin+hall.global_basis*p
func clear_body(at:Vector3) -> bool:
	var capsule:=CapsuleShape3D.new();capsule.radius=.28;capsule.height=1.7
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.transform.origin=at+Vector3.UP*.88;query.collision_mask=1|4
	var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query)
	if not hits.is_empty():observations["hits_"+str(at)]=hits.map(func(h):return str(h.collider.get_path()))
	return hits.is_empty()
func landing_checks() -> void:
	museum.call("flush_stamps");await create_timer(1.0).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var wardrobe=museum.get("_wardrobe")
	if wardrobe!=null and is_instance_valid(wardrobe.get("costume")):wardrobe.get("costume").hide()
	var source=find_scene("/parametric_lsystem/parametric_lsystem.gd")
	check("Existing Growth interpreter present",source!=null)
	if source==null:return
	var desk=source.get_node("GrowthLesson");var hand=desk.get_node("GrowthHand")
	source_origin=source.global_position-hall.global_basis*Vector3(9.5,0,7.5)
	var works:Array=[]
	for rec in museum.get("_edit_records"):
		var node=rec.get("node")
		if is_instance_valid(node) and hall.is_ancestor_of(node):works.append(str(rec.get("token","")))
	observations.works=works
	var authored:=["parametric_lsystem","ContextSensitiveTree","AnimatedTree","lsystem_tree","modulor_cypress"]
	check("Five authored artifacts retained once",authored.all(func(t):return works.count(t)==1))
	var approach:Vector3=source.to_global(Vector3(0,.005,3.35))
	check("Controls have supported clear approach",not floor_at(approach).is_empty() and clear_body(approach))
	check("Carried point within reach of control position",hand.point.global_position.distance_to(approach+Vector3.UP*1.2)<.85)
	await snapshot("arrival",map_at(Vector3(9.5,1.75,2.2)),source.to_global(Vector3(0,2,0)),76)
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver);driver.spawn(approach,museum);await create_timer(.2).timeout
	for id in ["STEP","RATIO","HOLD","TREE","RESET","RULE"]:
		var r:Dictionary=await driver.press(desk.buttons[id],approach)
		check("Nearby pointer reaches "+id,str(r.get("hover","")) not in ["","none","null","nothing"])
	# The supplied desktop rig brings its own environment. Remove it after the
	# pointer checks so the photographs use the museum's actual environment.
	await driver.teardown()
	driver.queue_free()
	await tick()
	desk.act("RESET")
	for i in 3:desk.act("STEP")
	desk.act("HOLD");var kept:Dictionary=desk.reference.duplicate(true)
	check("Branch held at prefix4 with two segments",kept.cursor==4 and kept.segments.size()==2 and kept.frame.stack_depth==1)
	await snapshot("branch",source.to_global(Vector3(0,2.1,6.6)),source.to_global(Vector3(0,1.5,0)),72)
	desk.act("STEP")
	check("Actual interpreter returns without erasing branch",desk.cursor==5 and desk._snapshot().frame.pos.is_equal_approx(Vector3.UP*.8) and desk._snapshot().segments==kept.segments and desk.reference==kept)
	await snapshot("return",source.to_global(Vector3(0,2.1,6.6)),source.to_global(Vector3(0,1.5,0)),72)
	var before_text:String=source._current_string
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=hand.point.global_position;hand.point.pick_up(pickup);await tick();await tick()
	controller.global_position=hand.to_global(Vector3(.525,1.18,2.55));await tick();await tick();await tick()
	check("Hand changes ratio only; sentence cursor and witness kept",hand.point.is_picked_up() and is_equal_approx(source.length_decay,1.15) and source._current_string==before_text and desk.cursor==5 and desk.reference==kept)
	origin.hide()
	await snapshot("hand",source.to_global(Vector3(1.7,2.1,3.7)),source.to_global(Vector3(0,1.14,2.2)),70)
	hand.point.action();await tick()
	check("Held trigger advances one frame, not a generation",desk.cursor==6 and source.effective_iterations==1)
	hand.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick()
	check("Release parks point at selected ratio",not hand.point.held() and hand.point.position.is_equal_approx(Vector3(.525,1.18,2.55)))
	desk.act("RESET");desk.cursor=11;desk.act("HOLD");desk.act("TREE")
	check("Second generation retains first in metre units",source.tree_segments.size()==25 and source._current_string.length()==61 and desk.reference.segments.size()==5 and desk.live_view.scale==Vector3.ONE and desk.held_view.scale==Vector3.ONE)
	var mesh:MultiMesh=desk.live_view.get_child(0).multimesh
	var rods_match:=true
	for i in source.tree_segments.size():
		var pose:=mesh.get_instance_transform(i)
		rods_match=rods_match and (pose*Vector3(0,-.5,0)).is_equal_approx(source.tree_segments[i][0]) and (pose*Vector3(0,.5,0)).is_equal_approx(source.tree_segments[i][1])
	check("Every rendered cylinder reaches both recorded endpoints",rods_match)
	await snapshot("tree",map_at(Vector3(9.5,4.5,1.2)),source.to_global(Vector3(0,4.0,0)),82)
	await snapshot("above",map_at(Vector3(9.5,25,8)),map_at(Vector3(9.5,0,14)),74)
	await snapshot("rear",map_at(Vector3(9.5,2,23)),map_at(Vector3(9.5,1,27)),78)
	origin.queue_free();await tick()
	var route_ok:=true;var samples:=0
	for route in [[Vector3(9.5,0,2),Vector3(4.4,0,4),Vector3(4.4,0,10),Vector3(9.5,0,13),Vector3(9.5,0,17.5),Vector3(14.2,0,17.5),Vector3(14.2,0,24.5),Vector3(9.5,0,24.5),Vector3(9.5,0,26)], [Vector3(9.5,0,2),Vector3(14.6,0,4),Vector3(14.6,0,10),Vector3(9.5,0,13)]]:
		for j in range(route.size()-1):
			var a:Vector3=route[j];var b:Vector3=route[j+1];var steps:=ceili(a.distance_to(b)/.25)
			for k in steps+1:
				var p:Vector3=map_at(a.lerp(b,float(k)/steps)+Vector3.UP*.01)
				route_ok=clear_body(p) and not floor_at(p).is_empty() and route_ok;samples+=1
	check("Primary bypasses and rear passage have supported capsule route",route_ok)
	observations.route_samples=samples
	if stream!=null:
		observations.entry=stream.get("_entry");observations.exit=stream.get("_exit")
		check("Nonempty entry and onward portal validate",not observations.entry.is_empty() and not observations.exit.is_empty() and not observations.entry.get("invalid",false) and not observations.exit.get("invalid",false))
	# Temporarily run the printed reconstruction on the empty middle floor.
	var study=load("res://doc/book/iterations/2026-10-09-growth-what-a-branch-keeps/printed/growth.gd").new()
	study.position=map_at(Vector3(9.5,0,12));study.rotation.y=PI;root.add_child(study)
	for i in 3:study.step()
	study.keep();study.step()
	source.hide() # Only for this temporary learner photograph: avoid duplicate labels.
	await snapshot("student",study.to_global(Vector3(0,2.1,6.6)),study.to_global(Vector3(0,1.5,0)),72)
	check("Printed reconstruction runs inside museum with preserved branch",study.cursor==5 and study.held.cursor==4 and study.drawing.get_child_count()==6)
	study.queue_free()
	source.show()
	observations.scope="Actual Growth hall; supplied desktop rays, real XRTools with supplied poses, supported capsule samples, native images. No physical headset or independent student; no complete portal traversal."
