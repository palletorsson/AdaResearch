extends RefCounted
## Exercise finish, loss, save/reload and map replacement through the real runner.
static func run(game: Node3D, check: Callable, photograph := Callable()) -> void:
	var tree := game.get_tree()
	var Campaign: GDScript = load("res://commons/museum_runner/campaign.gd")
	var record_path: String = game.save_path
	var legacy := ConfigFile.new()
	legacy.set_value("runner","best",4321)
	legacy.save(record_path)
	var restored: RefCounted = Campaign.new()
	restored.restore(record_path)
	check.call("legacy best score survives migration without granting a level",restored.best==4321 and restored.next_level==0 and restored.banked_score==0)
	legacy.set_value("journey","version",1)
	legacy.set_value("journey","next_map","unknown-map")
	legacy.set_value("journey","score",999)
	legacy.save(record_path)
	restored.restore(record_path)
	check.call("unknown saved map falls back safely while preserving best",restored.next_level==0 and restored.banked_score==0 and restored.best==4321)
	check.call("invalid checkpoint index cannot overwrite the save",restored.store(record_path,99,0,0)==ERR_INVALID_PARAMETER)
	game.campaign = restored
	game.best = restored.best
	game.reset_run(false)
	var checkpoint_origin: Transform3D = game.get_node("XROrigin3D").transform
	var first_layout: Array = game.chunks[0].layout.duplicate(true)
	check.call("first map has a finite finish and one visual family",game.level_index==0 and game.level.length_m()==108.0 and game.chunks.all(func(c): return c.chapter_override==0))
	game.primary_action()
	await frames(tree,3)
	near_finish(game)
	if photograph.is_valid(): await photograph.call("finish-gate.png")
	await frames(tree,3)
	check.call("crossing the finish in real physics wins the first map",game.state==game.State.WON and is_equal_approx(game.distance,108.0))
	var saved := ConfigFile.new()
	saved.load(record_path)
	var bank: int = game.score()
	check.call("win saves the next map and exact earned score",saved.get_value("journey","next_map")=="face_body" and saved.get_value("journey","score")==bank and game.campaign.next_level==1)
	var once := FileAccess.get_file_as_string(record_path)
	game._complete_level()
	check.call("a finish cannot grant the same score twice",game.score()==bank and FileAccess.get_file_as_string(record_path)==once)
	if photograph.is_valid(): await photograph.call("level-complete.png")
	await verify_reload(game,check,1,bank,false)
	var retired: WeakRef = weakref(game.level)
	game.get_node("XROrigin3D/RightHand").button_pressed.emit("ax_button")
	check.call("A/X loads the next map with banked score",game.state==game.State.RUNNING and game.level_index==1 and game.distance==0 and game.score()==bank and game.level.title=="FACE / BODY")
	check.call("changing maps frees the old scene and keeps the XR origin fixed",retired.get_ref()==null and game.get_node("XROrigin3D").transform==checkpoint_origin)
	check.call("next map has its own layout and visual identity",game.chunks[0].layout!=first_layout and game.chunks.all(func(c): return c.chapter_override==1))
	await frames(tree,4)
	clear_hazards(game)
	game.collected = 3
	game.chunks[0].add_hazard("cube",0,-1.1-game.chunks[0].position.z)
	await frames(tree,20)
	check.call("a physical collision fails the current map",game.state==game.State.OVER)
	saved.load(record_path)
	check.call("failed attempt cannot advance or inflate its checkpoint",saved.get_value("journey","next_map")=="face_body" and saved.get_value("journey","score")==bank)
	if photograph.is_valid(): await photograph.call("checkpoint-retry.png")
	var second_layout: Array = game.chunks[0].layout.duplicate(true)
	game.primary_action()
	check.call("retry restores the saved map, score and exact layout",game.level_index==1 and game.distance==0 and game.collected==0 and game.score()==bank and game.chunks[0].layout==second_layout)
	game.collected = 2
	game._save_best()
	await verify_reload(game,check,1,bank,false)
	# A collision on the finish tick must win the race against the success check.
	await frames(tree,4)
	near_finish(game)
	game.chunks[-1].add_hazard("cube",0,-game.chunks[-1].position.z)
	await frames(tree,3)
	check.call("collision at the finish does not unlock the next map",game.state==game.State.OVER and game.campaign.next_level==1)
	game.primary_action()
	await frames(tree,4)
	# A real I/O failure must not silently advertise a saved checkpoint.
	var blocked: String = record_path + ".blocked"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(blocked))
	game.save_path = blocked
	near_finish(game)
	await frames(tree,3)
	check.call("failed checkpoint write blocks advancement and offers retry",game.state==game.State.SAVE_FAILED and game.campaign.next_level==1 and not game.save_error.is_empty())
	game.save_path = record_path
	game.primary_action()
	check.call("retrying the save commits once and unlocks the next map",game.state==game.State.WON and game.campaign.next_level==2)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(blocked + ".tmp"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(blocked))
	for index in [2,3]:
		game.primary_action()
		await frames(tree,4)
		check.call("map %d loads its own finite scene" % (index+1),game.level_index==index and game.chunks.all(func(c): return c.chapter_override==index) and game.chunks.size()<=game.level.sections)
		near_finish(game)
		await frames(tree,3)
		check.call("map %d commits its finish" % (index+1),game.campaign.next_level==index+1 and game.state==(game.State.COMPLETE if index==3 else game.State.WON))
	check.call("last map completes the journey instead of wrapping to map one",game.state==game.State.COMPLETE and game.campaign.next_level==4 and game.action_button.text=="Return to museum")
	if photograph.is_valid(): await photograph.call("journey-complete.png")
	await verify_reload(game,check,3,game.score(),true)

static func near_finish(game: Node3D) -> void:
	game.distance = game.level.length_m()-0.02
	for chunk in game.chunks: chunk.position.z = game.distance-chunk.index*36.0
	game._stream()
	clear_hazards(game)
	game.runner.position = Vector3(0,game.RADIUS+0.015,0)
	game.runner.velocity = Vector3.ZERO
	game.lane = 0

static func clear_hazards(game: Node3D) -> void:
	for chunk in game.chunks:
		for body in chunk.hazards: body.collision_layer = 0

static func frames(tree: SceneTree, count: int) -> void:
	for i in range(count): await tree.physics_frame

static func verify_reload(game: Node3D, check: Callable, expected_map: int, bank: int, complete: bool) -> void:
	var fresh: Node3D = load("res://commons/museum_runner/museum_runner.tscn").instantiate()
	fresh.save_path = game.save_path
	game.get_parent().add_child(fresh)
	await frames(game.get_tree(),3)
	check.call("fresh runner restores map %d and saved score%s" % [expected_map+1," with journey complete" if complete else ""],fresh.level_index==expected_map and fresh.score()==bank and fresh.state==(fresh.State.COMPLETE if complete else fresh.State.READY))
	fresh.free()
	game.camera.make_current()
