extends "res://tools/probes/transformation_encounters.gd"
var source_origin: Vector3
func at(p: Vector3) -> Vector3: return source_origin + hall.global_basis*p
func landing_checks() -> void:
	museum.call("flush_stamps");await create_timer(.7).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var wardrobe=museum.get("_wardrobe")
	if wardrobe!=null and is_instance_valid(wardrobe.get("costume")):wardrobe.get("costume").hide()
	for child in museum.get_children():
		if child is Node3D and child.has_meta("em_map") and child!=hall:child.hide()
	var records: Array = []
	for rec in museum.get("_edit_records"):
		var node=rec.get("node")
		if is_instance_valid(node) and hall.is_ancestor_of(node):
			records.append({"key":rec.get("token",""),"position":xyz(hall.to_local(node.global_position))})
			if str(rec.get("token","")) == "randompoint":source_origin=node.global_position-hall.global_basis*Vector3(3.5,1.25,2.5)
	observations.inventory=records
	observations.source_origin=xyz(source_origin)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=38
	camera.global_position=at(Vector3(6.5,38,14));camera.look_at(at(Vector3(6.5,0,14)),Vector3.FORWARD);camera.current=true
	await create_timer(.4).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+"overhead.png"))
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	await snapshot("raised",at(Vector3(19,22,2)),at(Vector3(6.5,.8,13)),68)
	await snapshot("bay",at(Vector3(6.5,1.7,7.4)),at(Vector3(6.5,1.35,11.5)),82)
	var work:=find_scene("/geometry_noise/GeometryNoiseTest.gd")
	if work!=null:
		observations.artifact=xyz(hall.to_local(work.global_position))
		observations.measurements=work.log_entries.duplicate(true)
		await snapshot("comparison",work.to_global(Vector3(0,2.45,3.7)),work.to_global(Vector3(0,1.5,-.1)),80)
		work.set_noise_strength(.7);await tick()
		await snapshot("strong",work.to_global(Vector3(0,2.45,3.7)),work.to_global(Vector3(0,1.5,-.1)),80)
		work.reset_experiment()
		await interactions(work)
	observations.scope="Actual museum rendered on desktop. No headset validation."

func interactions(work:Node3D) -> void:
	var approach:Vector3=work.to_global(Vector3(0,0,2.7))
	var clearance:=true;var samples:=0
	var shape:=CapsuleShape3D.new();shape.radius=.28;shape.height=1.7
	for path in [[Vector3(11,0,9.6),Vector3(11,0,16)], [Vector3(11,0,11.5),Vector3(6.2,0,11.5)]]:
		var a:Vector3=path[0];var b:Vector3=path[1];var n:=ceili(a.distance_to(b)/.15)
		for i in range(n+1):
			var foot:=at(a.lerp(b,float(i)/n));var q:=PhysicsShapeQueryParameters3D.new()
			q.shape=shape;q.collision_mask=1|4;q.transform.origin=foot+Vector3.UP*.88
			var hits:=hall.get_world_3d().direct_space_state.intersect_shape(q,4)
			var floor:=floor_at(foot)
			clearance=clearance and hits.is_empty() and not floor.is_empty() and absf(floor.position.y-foot.y)<.03
			if not hits.is_empty():observations["blocked_"+str(foot)]=str(hits[0].collider.get_path())
			samples+=1
	check("Comparison approach and onward bypass have capsule clearance and floor",clearance)
	observations.route_samples=samples
	check("Controls within hand height",work.slider.global_position.y>0.8 and work.slider.global_position.y<1.5)
	var original:PackedVector3Array=work.sample.base.duplicate()
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver);driver.spawn(approach,museum);await create_timer(.2).timeout
	var expected_seed:int=work.experiment_seed
	for id in ["NEXT SEED","ZERO","RESET","EDGES"]:
		var response:Dictionary=await driver.press(work.buttons[id],approach)
		var result:=false
		match id:
			"NEXT SEED":result=work.experiment_seed==expected_seed+1
			"ZERO":result=work.normalized_strength==0
			"RESET":result=work.experiment_seed==1847 and is_equal_approx(work.normalized_strength,.18)
			"EDGES":result=not work.wire_visible
		check("Desktop pointer operates "+id,result)
		observations["pointer_"+id]=response
	driver.teardown();driver.queue_free();await tick()
	work.reset_experiment()
	# The supplied XR Tools joint/handle runs the real pickup constraint.
	var joint:Node3D=work.slider.get_node("SliderOrigin/InteractableSlider")
	var handle=joint.get_node("HandleOrigin/InteractableHandle")
	var origin:=XROrigin3D.new();root.add_child(origin)
	var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_transform=handle.global_transform;handle.pick_up(pickup);await tick();await tick()
	var start:Vector3=controller.global_position
	controller.global_position=start+joint.global_basis.x*.12
	for i in 8:await tick()
	check("XR Tools held slider changes strength on rotated museum mount",handle.is_picked_up() and work.normalized_strength>.4)
	check("Held control keeps original vertices and saved samples",work.sample.base==original and work.experiment_seed==1847)
	handle.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick()
	check("Slider releases normally",not handle.is_picked_up())
	origin.queue_free();await tick()
	work.reset_experiment()
	await snapshot("controls",work.to_global(Vector3(0,1.65,2.9)),work.to_global(Vector3(0,1.04,1.8)),76)
	await snapshot("eye-height",work.to_global(Vector3(.8,1.65,3.8)),work.to_global(Vector3(0,1.5,0)),90)
	observations.final_measurements=work.log_entries[-1]
