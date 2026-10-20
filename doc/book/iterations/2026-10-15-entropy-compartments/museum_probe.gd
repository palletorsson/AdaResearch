extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	root.size=Vector2i(1440,1000)
	museum.call("flush_stamps")
	await create_timer(0.5).timeout
	var bench := find_scene("/entropy_compartments.gd")
	var jar := find_scene("/entropy_jar.gd")
	check("compartments and corrected jar instantiated in actual hall",bench!=null and jar!=null)
	if bench==null or jar==null: return
	bench.pointer_path="user://entropy-compartments-museum-test-latest.json"
	observations.bench_world=xyz(bench.global_position)
	observations.jar_readout=jar._stats_label.text
	for x in [-1.7,0.0,1.7]:
		var p: Vector3=bench.to_global(Vector3(x,0,1.35))
		var hit:=floor_at(p)
		check("supported approach at x="+str(x),not hit.is_empty() and absf(hit.position.y-p.y)<0.05)
		var shape:=CapsuleShape3D.new();shape.radius=0.22;shape.height=1.6
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape
		query.collision_mask=1;query.transform=Transform3D(Basis(),p+Vector3.UP*0.85)
		var collisions:=bench.get_world_3d().direct_space_state.intersect_shape(query)
		check("clear standing space at x="+str(x),collisions.is_empty())
	check("control heights reachable",bench.buttons["KEEP"].global_position.y-bench.global_position.y>0.9 and bench.buttons["KEEP"].global_position.y-bench.global_position.y<1.2)
	await snapshot("bench-separated",bench.to_global(Vector3(0,2.0,2.85)),bench.to_global(Vector3(0,1.44,0)),53)
	for i in 4:
		var area: Node=bench.buttons["A LEFT -"].get_node("InteractableAreaButton")
		area.button_pressed.emit(area)
	check("placed control changes k while retaining one-bit reading",bench.model.a_left()==4 and bench.model.shannon_colour()==1 and bench.model.multiplicity()==4900)
	await snapshot("bench-balanced",bench.to_global(Vector3(0,2.0,2.85)),bench.to_global(Vector3(0,1.44,0)),53)
	bench.keep();bench.reset();bench.replay_saved()
	while bench.replaying: bench.replay_step()
	check("placed apparatus reopens and replays saved trial",bench.model.a_left()==4 and bench.model.multiplicity()==4900)
	check("jar labels disclose six-band conditional measure",jar._entropy_label.text.contains("H(C|Y)") and jar._stats_label.text.contains("6 height bands"))
	await snapshot("jar-labels",jar.to_global(Vector3(0,1.4,2.5)),jar.to_global(Vector3(0,0.8,0)),50)
	# Detail within the same capture/check: preserve the complete label text.
	var panel: Node3D=jar._entropy_label.get_parent()
	camera.global_position=panel.to_global(Vector3(0,0.02,0.65))
	camera.look_at(panel.global_position);camera.fov=38
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+"jar-readout-detail.png"))
	await snapshot("entrance-comparison",bench.to_global(Vector3(-3.0,3.7,5.8)),bench.to_global(Vector3(0,0.9,-1.5)),70)
	observations.scope="Scripted native hall: floor, standing space, callbacks, saved states, rendered labels. No headset or human learning evidence."
