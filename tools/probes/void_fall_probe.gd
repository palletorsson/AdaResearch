extends "res://tools/probes/void_game_probe.gd"
var flight_metres := 0.0

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	await falling_contract(false)
	if "--capture" not in OS.get_cmdline_user_args(): await falling_contract(true)
	await frames(120)
	# Fixed physics steps run faster than the real-time audio mixer in headless
	# mode. Let it consume the scene players' queued stop commands before exit.
	OS.delay_msec(150)
	FileAccess.open(out.path_join("capture-checks.json" if "--capture" in OS.get_cmdline_user_args() else "checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Real Jolt movement and XRTools with synthetic trackers. Mobile captures; no physical headset test."},"\t"))
	quit(0 if failed.is_empty() else 1)

func falling_contract(use_xr: bool) -> void:
	await start(use_xr)
	var tag: String="XR / " if use_xr else "Desktop / "
	check(tag+"grunt is loaded as audible own-body feedback",game.soundscape.hurt_voice.stream!=null and game.soundscape.hurt_voice.stream.get_length()>.4 and game.soundscape.hurt_voice.bus=="VoidEffects")
	for jumping in [false,true]:
		await launch(jumping)
		await leave_shaft()
		check(tag+("jump" if jumping else "step")+" down one floor survives",not game.recovering and game.deaths==0 and game.body.is_on_floor() and absf(game.body.global_position.y+42)<.12)
		var expected: float=95.0-(game.charge.metres_travelled-flight_metres)*0.1
		check(tag+"hard landing costs five charge plus movement and saves the new floor",absf(game.charge.get_charge()-expected)<0.03 and game.checkpoint==7)
		check(tag+"landing plays one grunt",game.soundscape.hurt_count==1)
		await frames(80)
		expected=95.0-(game.charge.metres_travelled-flight_metres)*0.1
		check(tag+"remaining on the floor adds no further landing cost",absf(game.charge.get_charge()-expected)<0.03 and game.soundscape.hurt_count==1)
	# A same-floor jump now pays the same five points when it lands.
	game.health.reset()
	if use_xr: game.jump.queued=true
	else: game.body.jump_queued=true
	await frames(110)
	check(tag+"ordinary jump costs five charge",absf(game.charge.get_charge()-95.0)<0.03 and game.body.is_on_floor())
	# Stay in the opening, passing the next floor without touching its slab.
	await launch(false)
	for i in range(200):
		await frames(1)
		if game.recovering: break
	axes(Vector2.ZERO)
	check(tag+"skipping a floor is fatal before a second floor can be reached",game.recovering and game.deaths==1 and game.last_death=="Fell more than one floor" and game.body.global_position.y> -43 and game.checkpoint==6 and game.health.get_health()==0)
	check(tag+"death immediately disables movement and starts the grunt",not game.body.enabled and game.soundscape.hurt_count==1)
	var impact_at: Vector3=game.body.global_position
	await frames(8)
	check(tag+"red fade grows before relocation",game.fade.visible and game.fade_material.albedo_color.a>0 and game.fade_material.albedo_color.a<1 and game.body.global_position.is_equal_approx(impact_at))
	if "--capture" in OS.get_cmdline_user_args(): await picture("red-fade.png")
	await frames(14)
	check(tag+"dark red fully covers the view before restart",game.fade_material.albedo_color.a==1 and game.fade_material.albedo_color.r>game.fade_material.albedo_color.g*5 and game.fade_material.albedo_color.r<.2 and not game.recovery_placed and game.body.global_position.is_equal_approx(impact_at))
	if "--capture" in OS.get_cmdline_user_args(): await picture("dark-red.png")
	for i in range(40):
		await frames(1)
		if game.recovery_placed: break
	check(tag+"checkpoint relocation happens under the opaque fade",game.recovery_placed and game.fade_material.albedo_color.a==1 and absf(game.body.global_position.y+36)<.12)
	await wait_for_recovery(0)
	check(tag+"restart restores last floor health input and vision",game.checkpoint==6 and game.health.get_health()==100 and game.body.enabled and not game.fade.visible and not game.health.suspended)
	# A normal one-floor landing is still fatal when its cost exhausts health.
	await launch(false,5)
	await leave_shaft()
	check(tag+"insufficient health cannot claim the lower checkpoint",game.deaths==2 and game.checkpoint==6)
	await wait_for_recovery(1)
	check(tag+"low-health fall also restores the last saved floor",game.checkpoint==6 and game.health.get_health()==100 and absf(game.body.global_position.y+36)<.12)
	# The zone is editable. Exercise its current placement, not a stale coordinate.
	game.building.content.load_floor(5,true)
	var zone: Node3D=game.building.content.exhibits["5/surfaces"].get_node("Artifact/MeshRevealZone")
	game.place_player(zone.global_position+Vector3.UP*.06);await frames(60)
	check(tag+"Triangle zone is active before testing death",root.debug_draw==Viewport.DEBUG_DRAW_WIREFRAME)
	var before: int=game.deaths
	game.health.set_health(0);await frames(22)
	check(tag+"death fade remains solid inside the wireframe zone",root.debug_draw==Viewport.DEBUG_DRAW_DISABLED and game.fade_material.albedo_color.a==1 and not game.recovery_placed)
	await wait_for_recovery(before)
	check(tag+"return from mesh zone restores normal rendering",root.debug_draw==Viewport.DEBUG_DRAW_DISABLED and game.health.get_health()==100 and not game.fade.visible)
	game.queue_free();await frames(15)
	if use_xr:
		for tracker in [head,left,right]: XRServer.remove_tracker(tracker)

func launch(jumping: bool, initial_health:=100.0) -> void:
	game.health.reset()
	game.health.set_health(initial_health)
	game.soundscape.hurt_voice.stop()
	game.soundscape.hurt_count=0
	game.checkpoint=6
	game.place_player(Vector3(13.3,-35.94,0))
	await frames(30)
	flight_metres=game.charge.metres_travelled
	if jumping:
		if xr: game.jump.queued=true
		else: game.body.jump_queued=true
	axes(Vector2(-1,0))
	for i in range(60):
		await frames(1)
		# Enter just inside the shaft, rather than use the old 3.5 m/s rig's
		# deeper takeoff target. The shared museum rig walks at 3 m/s.
		# Leave enough width for its capsule to clear the upper slab.
		if game.body.global_position.x<=12.1: break
	axes(Vector2.ZERO)

func leave_shaft() -> void:
	# Clear the upper slab with the actual capsule before steering back out.
	for i in range(150):
		await frames(1)
		if game.body.global_position.y< -38.2 or game.recovering: break
	axes(Vector2(1,0))
	for i in range(120):
		await frames(1)
		if game.body.global_position.x>13.3 or game.recovering: break
	axes(Vector2.ZERO)
	for i in range(150):
		await frames(1)
		if game.body.is_on_floor() or game.recovering: break
	await frames(15)

func picture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(filename))
