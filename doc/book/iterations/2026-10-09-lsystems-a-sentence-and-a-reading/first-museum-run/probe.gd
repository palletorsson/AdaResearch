extends "res://tools/probes/transformation_encounters.gd"
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
	var editor=find_scene("/lsystem_editor/lsystem_editor.gd")
	check("Existing editor present",editor!=null)
	if editor==null:return
	var desk=editor.get_node("GrammarLesson");var hand=desk.get_node("GrammarHand")
	var works:Array=[]
	for rec in museum.get("_edit_records"):
		var node=rec.get("node")
		if is_instance_valid(node) and hall.is_ancestor_of(node):works.append(str(rec.get("token","")))
	observations.works=works
	check("Eight authored works retained once",works.size()==8 and works.all(func(t):return works.count(t)==1))
	var approach:Vector3=editor.to_global(Vector3(0,.005,3.35))
	check("Point and controls have a supported clear approach",not floor_at(approach).is_empty() and clear_body(approach))
	check("Hand point within reach from controls",hand.point.global_position.distance_to(approach+Vector3.UP*1.2)<.85)
	await snapshot("arrival",hall.to_global(Vector3(9.5,1.75,1.8)),hall.to_global(Vector3(9.5,2.2,8)),78)
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver);driver.spawn(approach,museum);await create_timer(.2).timeout
	for id in ["NEXT","HOLD","TURN","PRESET","RESET","RULE"]:
		var r:Dictionary=await driver.press(desk.buttons[id],approach)
		check("Nearby button receives pointer "+id,str(r.get("hover","")) not in ["","none","null","nothing"])
	desk.act("RESET");desk.act("NEXT");desk.act("HOLD")
	var kept:Dictionary=desk.reference.duplicate(true);var before_revision:int=editor.rewrite_revision
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=hand.point.global_position;hand.point.pick_up(pickup);await tick();await tick()
	controller.global_position=hand.to_global(Vector3(.525,1.18,2.55));await tick();await tick();await tick()
	check("Hand changes only reading:120 vs held90",hand.point.is_picked_up() and editor.angle_degrees==120 and editor.get_string()==kept.text and desk.reference==kept and editor.rewrite_revision==before_revision)
	origin.hide()
	await snapshot("comparison",editor.to_global(Vector3(0,2.2,6.4)),editor.to_global(Vector3(0,1.9,0)),72)
	await snapshot("hand",editor.to_global(Vector3(1.7,2.1,3.7)),editor.to_global(Vector3(0,1.14,2.2)),70)
	hand.point.action();await tick()
	check("Held trigger rewrites exactly once keeping witness",editor.generations==2 and editor.get_string().length()==49 and desk.reference==kept)
	await snapshot("next",editor.to_global(Vector3(0,2.2,6.4)),editor.to_global(Vector3(0,1.9,0)),72)
	hand.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick()
	check("Release parks point without altering angle",not hand.point.held() and hand.point.position.is_equal_approx(Vector3(.525,1.18,2.55)) and editor.angle_degrees==120)
	desk.act("RESET")
	for i in 7:desk.act("PRESET")
	check("Eighth preset reaches Cantor and names it",editor.preset==7 and desk.readout.text.begins_with("CANTOR"))
	for i in 3:desk.act("NEXT")
	desk.act("HOLD")
	check("Installed Cantor has27 symbols8 intervals",editor.get_string().length()==27 and editor.fitted_lines.size()==16)
	await snapshot("cantor",editor.to_global(Vector3(0,2.2,6.4)),editor.to_global(Vector3(0,1.9,0)),72)
	desk.act("PRESET");check("Preset cycles from Cantor to Koch",editor.preset==0 and editor.generations==0)
	desk.act("NEXT");desk.act("HOLD");desk.act("TURN")
	driver.teardown();origin.queue_free();await tick()
	await snapshot("above",hall.to_global(Vector3(9.5,24,9)),hall.to_global(Vector3(9.5,0,13)),70)
	await snapshot("rear",hall.to_global(Vector3(9.5,2.0,18)),hall.to_global(Vector3(9.5,1.0,25)),78)
	var route_ok:=true;var samples:=0
	# Two bypasses round the primary, then the central rear opening.
	for route in [[Vector3(9.5,0,2),Vector3(4.7,0,4),Vector3(4.7,0,10),Vector3(9.5,0,13),Vector3(9.5,0,18),Vector3(9.5,0,24)], [Vector3(9.5,0,2),Vector3(14.3,0,4),Vector3(14.3,0,10),Vector3(9.5,0,13)]]:
		for j in range(route.size()-1):
			var a:Vector3=route[j];var b:Vector3=route[j+1]
			var steps:=ceili(a.distance_to(b)/.25)
			for k in steps+1:
				var p:Vector3=hall.to_global(a.lerp(b,float(k)/steps)+Vector3.UP*.01)
				route_ok=clear_body(p) and not floor_at(p).is_empty() and route_ok;samples+=1
	check("Both primary bypasses and rear route have support and capsule clearance",route_ok)
	observations.route_samples=samples
	if stream!=null:
		observations.entry=stream.get("_entry");observations.exit=stream.get("_exit")
		check("Entry and onward portals validate",not observations.entry.get("invalid",false) and not observations.exit.get("invalid",false))
	# Run the exact printed learner reconstruction on an empty patch in this hall.
	var study=load("res://doc/book/iterations/2026-10-09-lsystems-a-sentence-and-a-reading/printed/sentence.gd").new()
	study.position=hall.to_global(Vector3(4.8,0,11.5));study.rotation.y=PI;root.add_child(study)
	study.advance();study.keep();study.choose(3)
	await snapshot("student",study.to_global(Vector3(0,1.9,4.2)),study.to_global(Vector3(0,1.85,0)),68)
	check("Printed reconstruction runs inside actual museum",study.sentence=="F+F-F-F+F" and study.drawing.get_child_count()==10 and study.held.angle==90)
	study.queue_free()
	observations.scope="Actual opening hall; supplied desktop rays, real XRTools with supplied poses, capsule route samples. No headset or independent student, no full sequence crossing."
