extends SceneTree
const OUT := "res://doc/book/iterations/2026-10-18-runner-levels/"
const GAME := "res://commons/museum_runner/museum_runner.tscn"
var game: Node3D
var checks: Array[Dictionary] = []
var failures: Array[String] = []
var finished := false
var max_chunks := 0

class Host extends Node3D:
	var requested := ""
	var returned := false
	func load_scene(path: String) -> void: requested = path
	func return_to_main_menu() -> void: returned = true

func _initialize() -> void: run.call_deferred()
func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"passed":passed})
	if not passed: failures.append(label)
	print("[runner-test] ","PASS " if passed else "FAIL ",label)
func ticks(count := 3) -> void:
	for i in range(count): await physics_frame

func run() -> void:
	create_timer(100).timeout.connect(func(): check("bounded verification finishes",false); finish())
	var Course: GDScript = load("res://commons/museum_runner/course.gd")
	var valid := true
	var choices := {}
	for seed_value in range(1,21):
		for index in range(100):
			var rows: Array = Course.rows(seed_value,index)
			for row in rows:
				valid = valid and row.clear >= -1 and row.clear <= 1 and row.hazards.size() <= 2
				for obstacle in row.hazards: valid = valid and obstacle.lane != row.clear
				choices[row.clear] = true
			valid = valid and abs(rows[1].clear-rows[0].clear)<=1 and abs(rows[2].clear-rows[1].clear)<=1
	check("6000 generated rows retain an adjacent clear lane",valid and choices.size()==3)
	check("same seed and section reproduce exact obstacles",Course.rows(17,8)==Course.rows(17,8))
	check("another seed changes the course",Course.rows(17,8)!=Course.rows(18,8))
	check("four distinct runner map scenes are packaged",load("res://commons/museum_runner/campaign.gd").MAPS.size()==4)
	check("maximum speed leaves time for two lane changes",9.0/10.0 > 2*Course.LANE_WIDTH/10.0+0.25)
	var inherited_hand := XRController3D.new()
	root.add_child(inherited_hand)
	var mushroom := root.get_node("MushroomHand")
	var legacy_callback := Callable(mushroom,"_on_vr_button").bind(inherited_hand)
	inherited_hand.button_pressed.connect(legacy_callback)
	var old_mushroom_mode: int = mushroom.process_mode
	game = load(GAME).instantiate()
	game.save_path = "res://ada_run/museum-runner-test/best.cfg"
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	var host := Host.new()
	root.add_child(host)
	host.add_child(game)
	current_scene = host
	await ticks(12)
	if "--xr-input-only" in OS.get_cmdline_user_args() or "--levels-only" in OS.get_cmdline_user_args():
		if "--levels-only" in OS.get_cmdline_user_args():
			await load("res://tools/probes/museum_runner_levels.gd").run(game,check,photograph)
		else:
			await load("res://tools/probes/museum_runner_xr_input.gd").run(game,check)
		game.queue_free()
		await ticks(2)
		inherited_hand.queue_free()
		finish()
		return
	check("ready screen waits for a deliberate start",game.state==game.State.READY and game.distance==0)
	check("sphere stands on a real physics floor",game.runner.is_on_floor())
	check("camera belongs to the runner scene",root.get_camera_3d()==game.camera and game.camera.environment==game.environment)
	check("clicking HUD buttons cannot capture lane keys",game.action_button.focus_mode==Control.FOCUS_NONE)
	check("global mushroom input is suspended for this mode",game.mushroom_hand.process_mode==Node.PROCESS_MODE_DISABLED)
	check("previously wired throwing trigger is disconnected",not inherited_hand.button_pressed.is_connected(legacy_callback))
	check("sphere shape comes from the earlier point lesson",is_equal_approx(game.skin.mesh.radius,0.14))
	check("museum profile columns are present",game.chunks[0].find_children("*","Node3D",true,false).any(func(n): return n.get_meta("radial_segments",0)==4))
	await photograph("arrival.png")
	key(KEY_SPACE)
	for i in range(30):
		await physics_frame
		if game.state==game.State.RUNNING and game.distance>0: break
	check("keyboard starts the runner",game.state==game.State.RUNNING and game.distance>0)
	key(KEY_LEFT)
	for i in range(60):
		await physics_frame
		if game.lane==-1 and absf(game.runner.position.x+Course.LANE_WIDTH)<0.05: break
	check("keyboard moves sphere into the left lane",game.lane==-1 and absf(game.runner.position.x+Course.LANE_WIDTH)<0.05)
	game.shift(-1)
	check("lane bounds prevent leaving the course",game.lane==-1)
	game.toggle_pause()
	var before: float = game.distance
	var before_position: Vector3 = game.runner.position
	await ticks(10)
	check("pause freezes movement and distance",game.distance==before and game.runner.position==before_position)
	game.primary_action()
	check("primary action resumes pause",game.state==game.State.RUNNING)
	game.reset_run()
	await ticks(4)
	disable_hazards()
	var column: Node3D = game.chunks[0].add_hazard("cube",0,-1.3)
	await ticks(24)
	check("real cube collider stops a grounded runner",game.state==game.State.OVER and not game.last_hit.is_empty())
	var collision_record := ConfigFile.new()
	var loaded := collision_record.load(game.save_path)==OK
	check("collision saves the maximum earned score",loaded and game.best>=game.score() and int(collision_record.get_value("runner","best",-1))==game.best)
	var layout: Array = game.chunks[0].layout.duplicate(true)
	game.primary_action()
	check("retry resets distance and retains seed/layout",game.distance==0 and game.collected==0 and game.seed_value==17 and game.chunks[0].layout==layout)
	await ticks(4)
	disable_hazards()
	column = game.chunks[0].add_hazard("beam",0,-2.2)
	await ticks(2)
	check("jump is available from the floor",game.jump())
	check("jump cannot be repeated in the same grounded tick",not game.jump())
	var peak := 0.0
	for i in range(65):
		await physics_frame
		peak = maxf(peak,game.runner.position.y)
		if i==18: await photograph("jump.png")
	check("jump clears the physical low beam",game.state==game.State.RUNNING and peak>1.4 and column.position.z+game.chunks[0].position.z>1)
	check("gravity returns sphere to the floor",game.runner.is_on_floor())
	game.reset_run()
	await ticks(4)
	disable_hazards()
	game.chunks[0].add_hazard("beam",0,-1.1)
	await ticks(18)
	check("same beam stops a runner who does not jump",game.state==game.State.OVER)
	game.reset_run()
	await ticks(4)
	disable_hazards()
	var pickup: Area3D = game.chunks[0].pickups[0]
	pickup.position = Vector3(0,0.72,-1.2)
	await ticks(25)
	check("swept physics query collects a gold cube once",game.collected==1 and pickup.collision_layer==0 and not pickup.visible)
	check("pickup contributes exactly 25 points",game.score()==int(game.distance)+25)
	# A distant thin beam must be detected even in a one-metre relative sweep.
	game.chunks[0].add_hazard("beam",0,-2-game.chunks[0].position.z)
	await ticks(2)
	check("swept collision catches thin shapes between endpoints",not game._sweep(2,Vector3(0,0.38,0),Vector3(0,0.38,0),3.0,false).is_empty())
	game.reset_run()
	await ticks(3)
	# Run the real movement/update loop. This pilot chooses each authored safe lane.
	for i in range(800):
		var nearest := -1000.0
		var target := 0
		for chunk in game.chunks:
			for row in chunk.layout:
				var z: float = chunk.position.z+row.z
				# Keep the current row's lane until the complete obstacle has passed.
				if z < 1.2 and z > nearest:
					nearest = z
					target = row.clear
		if nearest > -10: game.shift(target-game.lane)
		await physics_frame
		max_chunks = maxi(max_chunks,game.chunks.size())
		if game.state==game.State.OVER: break
	check("safe-lane pilot survives a live generated run",game.state==game.State.RUNNING and game.distance>65)
	print("[runner-pilot] distance=",game.distance," state=",game.state," cubes=",game.collected)
	check("live streaming and trace stay bounded",max_chunks<=7 and game.trail.size()<=32)
	game.toggle_pause()
	game._save_best()
	await photograph("running.png")
	# A finite map cannot stream new sections after its finish.
	game.distance += Course.LENGTH*200
	for chunk in game.chunks: chunk.position.z = game.distance-chunk.index*Course.LENGTH
	game._stream()
	check("streaming stops at the current map's last section",game.next_chunk==game.level.sections and game.chunks.is_empty())
	game.state = game.State.READY
	for phase in range(4):
		game._load_level(phase,false)
		await ticks(2)
		await photograph("chapter-%d.png" % phase)
	game.reset_run(false)
	check("checkpoint button returns to the saved map and waits for start",game.level_index==0 and game.seed_value==17 and game.state==game.State.READY)
	game._vr_button("ax_button")
	check("XR A/X adapter starts the same game",game.state==game.State.RUNNING)
	game._vr_button("by_button")
	check("XR B/Y adapter pauses",game.state==game.State.PAUSED)
	await test_shooting()
	await load("res://tools/probes/museum_runner_xr_input.gd").run(game,check)
	await load("res://tools/probes/museum_runner_levels.gd").run(game,check,photograph)
	var menu: Node3D = load("res://commons/scenes/main_menu/MainMenu3D.tscn").instantiate()
	host.add_child(menu)
	menu.hide()
	menu.get_node("Buttons/MuseumRunnerButton").clicked.emit()
	check("real main menu button requests the runner scene",host.requested==GAME)
	game.return_to_menu()
	check("runner returns through its existing staging host",host.returned)
	var config := ConfigFile.new()
	config.load(game.save_path)
	check("best remains after a shorter run",int(config.get_value("runner","best",0))==game.best and game.best>0)
	# Release the menu before renderer teardown; it owns procedural materials.
	menu.queue_free()
	await ticks(4)
	game.queue_free()
	await ticks(2)
	check("leaving restores the previous throwing controls",mushroom.process_mode==old_mushroom_mode and inherited_hand.button_pressed.is_connected(legacy_callback))
	inherited_hand.queue_free()
	finish()

func test_shooting() -> void:
	game.reset_run()
	await ticks(4)
	disable_hazards()
	game.steer_axis(0.2,0.1)
	check("VR joystick deadzone keeps the lane",game.lane==0)
	game.steer_axis(0.8,0.01)
	check("VR joystick moves right on first tilt",game.lane==1)
	game.steer_axis(-0.8,0.01)
	check("VR joystick reversal responds immediately",game.lane==0)
	game.steer_axis(-0.8,0.27)
	check("holding VR joystick continues across lanes",game.lane==-1)
	game.steer_axis(-0.8,0.27)
	check("held VR joystick respects lane bounds",game.lane==-1)
	game.steer_axis(0.0,0.01)
	check("centred VR joystick rearms",game.axis_armed)
	game.reset_run()
	await ticks(4)
	disable_hazards()
	var hand: XRController3D = game.get_node("XROrigin3D/RightHand")
	var target: Node3D = game.chunks[0].add_hazard("cube",0,-8)
	hand.global_position = Vector3(1.5,2.3,3)
	hand.look_at(target.global_position,Vector3.UP)
	await ticks(2)
	# Freeze only the simulation clock while native frames are captured.
	game.set_physics_process(false)
	game.blaster.update_sights(true)
	await photograph("aiming.png")
	game.set_physics_process(true)
	var initial_y: float = game.runner.position.y
	hand.button_pressed.emit("trigger_click")
	await ticks(2)
	check("real right-hand trigger destroys the aimed cube",target.destroyed and game.blaster.broken==1)
	check("shot removes visibility and collision immediately",not target.visible and target.collision_layer==0)
	check("trigger firing does not jump",game.runner.is_on_floor() and absf(game.runner.position.y-initial_y)<0.02)
	check("destroyed body cannot be broken twice",not target.hit_by_runner_shot() and game.blaster.broken==1)
	check("shot creates bounded visible feedback",game.blaster.effects.size()>=2 and game.blaster.effects.size()<=game.blaster.MAX_EFFECTS)
	game.set_physics_process(false)
	await photograph("shooting.png")
	game.set_physics_process(true)
	var shots: int = game.blaster.shots
	await ticks(2)
	check("fire-rate limit blocks repeated immediate shots",game.blaster.shots==shots)
	await ticks(17)
	check("held trigger repeats fire at the capped rate",game.blaster.shots>shots)
	hand.button_released.emit("trigger_click")
	shots = game.blaster.shots
	await ticks(17)
	check("trigger release stops firing",game.blaster.shots==shots)
	var left: XRController3D = game.get_node("XROrigin3D/LeftHand")
	left.global_transform = hand.global_transform
	left.button_pressed.emit("trigger_click")
	await ticks(2)
	left.button_released.emit("trigger_click")
	check("left-hand trigger also fires through its connected signal",game.blaster.shots>shots)
	# A release must be seen before a GUI control can consume it.
	game.mouse_firing = true
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	game._input(release)
	check("mouse release over the HUD clears held fire",not game.mouse_firing)
	# First-hit obstruction: an unmarked pink beam protects a cube behind it.
	var beam: Node3D = game.chunks[0].add_hazard("beam",4,-10-game.chunks[0].position.z)
	var behind: Node3D = game.chunks[0].add_hazard("cube",4,-14-game.chunks[0].position.z)
	await ticks(1)
	game.blaster.cooldowns.clear()
	game.blaster.fire_from(Vector3(4,0.16,1),Vector3.FORWARD,0)
	check("unmarked beam blocks fire and protects a target behind",beam.visible and beam.collision_layer==2 and not behind.destroyed)
	# A shot can clear an imminent lane collision, leaving the safe route playable.
	game.reset_run()
	await ticks(4)
	disable_hazards()
	target = game.chunks[0].add_hazard("cube",0,-2)
	await ticks(1)
	game.blaster.fire_from(Vector3(0,1.3,1),(target.global_position-Vector3(0,1.3,1)).normalized())
	await ticks(35)
	check("runner passes through a shot-cleared obstacle",target.destroyed and game.state==game.State.RUNNING)
	# Other selected objects use the same target class and exact face collider.
	var Chunk: GDScript = load("res://commons/museum_runner/chunk.gd")
	var display: Node3D = Chunk.new()
	display.index = 3
	display.position.z = -20
	game.add_child(display)
	await ticks(1)
	var tetra: Node3D
	for body in display.get_children():
		if body is StaticBody3D and body.collision_layer==16: tetra = body; break
	game.blaster.cooldowns.clear()
	var origin := Vector3(tetra.global_position.x,1.0,tetra.global_position.z+4)
	game.blaster.fire_from(origin,Vector3.FORWARD)
	check("marked tetrahedron can be destroyed",tetra.destroyed)
	display.free()
	game.toggle_pause()
	shots = game.blaster.shots
	game.blaster.cooldowns.clear()
	check("pause rejects shooting",not game.blaster.fire_from(Vector3(0,2,0),Vector3.FORWARD) and game.blaster.shots==shots)
	var before_lane: int = game.lane
	game.steer_axis(0.9,1.0)
	check("pause rejects joystick movement",game.lane==before_lane)
	game.primary_action()
	# Every burst remains cheap, even if both controllers fire continually.
	for i in range(50): game.blaster.burst(Vector3(0,1,-5),Color.WHITE)
	check("rapid fire cannot retain unlimited effects",game.blaster.effects.size()==game.blaster.MAX_EFFECTS)
	game.reset_run(false)
	check("retry clears shots, breaks and effects",game.blaster.shots==0 and game.blaster.broken==0 and game.blaster.effects.is_empty() and game.firing_hands.is_empty())
	game._vr_button("trigger_click",hand)
	check("trigger cannot start or shoot from the ready screen",game.state==game.State.READY and game.firing_hands.is_empty())
	game.primary_action()
	await ticks(3)
	hand.button_pressed.emit("ax_button")
	check("A/X still jumps independently of shooting",game.runner.velocity.y>0)
	game.reset_run(false)

func disable_hazards() -> void:
	for chunk in game.chunks:
		for body in chunk.hazards: body.collision_layer = 0

func key(code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)

func photograph(filename: String) -> void:
	if DisplayServer.get_name()=="headless": return
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+filename)

func finish() -> void:
	if finished: return
	finished = true
	var output := FileAccess.open(OUT+"checks.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"max_chunks":max_chunks,"scope":"Native physics and synthetic input. Physical headset and human play not tested."},"\t"))
	output.close()
	print("[runner-test] ",checks.size()-failures.size(),"/",checks.size()," passed")
	quit(0 if failures.is_empty() else 1)
