extends RefCounted
## Exercise temporal invariants through production pointer controls and render
## the three comparisons inside the assembled museum from the same eye position.
func run(tree: SceneTree, station: Node3D, camera: Camera3D) -> void:
	var body = station.specimen
	var score = body.score
	station.controls[6].pointer_event(tree.Press.new())
	var before: float = score.left_angle
	for i in 8: await tree.process_frame
	tree.check("pair advances through the production game loop",not is_equal_approx(score.left_angle,before))
	body.set_process(false)
	station.controls[6].pointer_event(tree.Press.new())
	tree.check("reset matches phase and rate",is_zero_approx(score.gap_degrees()) and score.right_ratio==1.0 and not score.paused)
	var left: float = score.left_angle
	var right: float = score.right_angle
	station.controls[0].pointer_event(tree.Press.new())
	tree.check("drift changes rate without jumping either hand",score.left_angle==left and score.right_angle==right and score.right_ratio==score.DRIFT_RATIO)
	for i in 1800: score.advance(1.0/60.0)
	tree.check("four percent difference gains 36 degrees in 30 seconds",absf(score.gap_degrees()-36.0)<0.0001)
	station.controls[1].pointer_event(tree.Press.new())
	var gap: float = score.gap_degrees()
	score.advance(25.0)
	tree.check("same rate preserves the existing gap",absf(score.gap_degrees()-gap)<0.0001)
	left = score.left_angle
	station.controls[2].pointer_event(tree.Press.new())
	tree.check("offset changes only right phase by 45 degrees",score.left_angle==left and absf(score.gap_degrees()-gap-45.0)<0.0001 and score.right_ratio==1.0)
	station.controls[0].pointer_event(tree.Press.new())
	station.controls[3].pointer_event(tree.Press.new())
	tree.check("align preserves left time and unequal rates",score.left_angle==left and is_zero_approx(score.gap_degrees()) and score.right_ratio==score.DRIFT_RATIO)
	score.advance(10.0)
	tree.check("alignment with unequal rates drifts again",absf(score.gap_degrees()-12.0)<0.0001)
	station.controls[4].pointer_event(tree.Press.new())
	left = score.left_angle; right = score.right_angle
	score.advance(30.0)
	tree.check("hold freezes both local angles",score.paused and score.left_angle==left and score.right_angle==right)
	station.controls[4].pointer_event(tree.Press.new())
	score.advance(1.0)
	tree.check("run resumes from retained angles",not score.paused and not is_equal_approx(score.left_angle,left))
	station.controls[5].pointer_event(tree.Press.new()); body.sync_display()
	tree.check("reading reveals the actual state",body.readout.visible and body.readout.text.contains("RIGHT × 1.04"))
	var comparison = load("res://commons/artifacts/spine_studies/paired_time_score.gd").new()
	comparison.drift()
	for i in 4320: comparison.advance(1.0/144.0)
	score.reset(); score.drift()
	for i in 900: score.advance(1.0/30.0)
	tree.check("frame rates agree after equal elapsed time",absf(score.left_angle-comparison.left_angle)<0.0001 and absf(score.right_angle-comparison.right_angle)<0.0001)
	left = score.left_angle
	score.advance(-1.0); score.advance(NAN); score.advance(INF)
	tree.check("invalid time cannot corrupt the pair",score.left_angle==left and is_finite(score.right_angle))
	score.advance(100000.0)
	tree.check("long elapsed interval remains bounded",score.left_angle>=0.0 and score.left_angle<TAU and score.right_angle>=0.0 and score.right_angle<TAU)
	station.controls[6].pointer_event(tree.Press.new()); body.sync_display()
	tree.check("reset also restores hidden readout",not body.reveal and not body.readout.visible and is_zero_approx(score.gap_degrees()))
	camera.global_position=station.to_global(Vector3(3.7,1.7,4.0))
	camera.look_at(station.to_global(Vector3(0,2.3,-3.4)))
	for state in ["together","drift","same-rate"]:
		if state=="drift":
			station.controls[0].pointer_event(tree.Press.new()); score.advance(30.0)
			station.controls[5].pointer_event(tree.Press.new())
		if state=="same-rate":
			station.controls[1].pointer_event(tree.Press.new()); score.advance(12.0)
		body.sync_display()
		for i in 6: await tree.process_frame
		await RenderingServer.frame_post_draw
		tree.check("native paired time capture "+state,tree.root.get_texture().get_image().save_png(tree.OUT+"paired-time-"+state+".png")==OK)
	station.controls[6].pointer_event(tree.Press.new())
	body.set_process(true)
