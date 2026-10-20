extends "res://tools/probes/void_game_probe.gd"
const HealthModel := preload("res://commons/void/health.gd")
const Crawler := preload("res://commons/void/spider.tscn")

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	if "--capture" in OS.get_cmdline_user_args():
		await images()
	else:
		await model_checks()
		await leg_checks()
		for use_xr in [false,true]: await encounter_checks(use_xr)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({
		"passed":failed.is_empty(),"checks":checks,"failed":failed,
		"scope":"Real Godot geometry, health, attacks and recovery. XRTools synthetic trackers; physical headset appearance/performance still needs playtesting."},"\t"))
	quit(0 if failed.is_empty() else 1)

func model_checks() -> void:
	var health := HealthModel.new()
	root.add_child(health); health.set_physics_process(false)
	health.set_health(90)
	check("Ordinary floor damage does not impair sight",health.sight_impairment==0)
	health.apply_bite_damage(20)
	check("Bite removes 20 health and adds blur",health.health==70 and health.sight_impairment>0)
	health.advance_sight(9.99)
	check("Sight still recovering immediately before ten seconds",health.sight_impairment>0)
	health.advance_sight(.02)
	check("Sight fully clear after ten seconds",health.sight_impairment==0 and health.sight_remaining==0)
	health.reset(); health.apply_bite_damage(20)
	var first := health.sight_impairment
	health.advance_sight(3); health.apply_bite_damage(20)
	check("A second bite after the cooldown increases blur and restarts recovery",health.sight_impairment>first and health.sight_remaining==10)
	health.apply_bite_damage(20); health.apply_bite_damage(20)
	check("Repeated bites cap blur at one",health.sight_impairment==1)
	health.set_health(health.health+1)
	check("Actual healing immediately restores sight",health.sight_impairment==0)
	health.apply_bite_damage(20); health.reset()
	check("Reset clears impairment and restores full health",health.sight_impairment==0 and health.health==100)
	health.suspended=true; health.apply_bite_damage(20)
	check("Suspended health rejects bites and their blur",health.sight_impairment==0 and health.health==100)
	health.suspended=false; health.apply_bite_damage(0); health.apply_bite_damage(-20)
	check("Zero and negative bite amounts cannot damage sight",health.sight_impairment==0 and health.health==100)
	health.set_health(0); health.apply_bite_damage(20)
	check("Dead health rejects new sight damage",health.sight_impairment==0)
	health.queue_free(); await frames(2)

func leg_checks() -> void:
	var spider := Crawler.instantiate()
	root.add_child(spider)
	spider.set_physics_process(false); spider.gait.set_process(false)
	check("Eight mechanical upper legs and eight shins",spider.gait._upper.size()==8 and spider.gait._lower.size()==8)
	check("Human-sized shoulders and a mechanical optical head",is_equal_approx(spider.gait.position.y,1.35) and spider.has_node("TechHead/PowerCore"))
	var clearance := INF
	var sector_ok := true
	var height_ok := true
	for frame in 720:
		spider.position=Vector3(sin(frame*.008)*2,-42 if frame<360 else -48,cos(frame*.008)*2)
		spider.rotation.y=frame*.065
		spider.gait._update_gait(1.0/60.0)
		var segments: Array = []
		for i in 8:
			var end: Vector3=spider.gait.to_local(spider.gait._feet[i].global_position)
			var angle := atan2(end.z,end.x)
			var expected := TAU*(i+.5)/8.0
			sector_ok=sector_ok and absf(wrapf(angle-expected,-PI,PI))<=deg_to_rad(12.01)
			var y: float=spider.gait._feet[i].global_position.y-spider.global_position.y
			height_ok=height_ok and y>=-.001 and y<=.161
			segments.append([[spider.gait.hips[i],spider.gait.knees[i]],[spider.gait.knees[i],end]])
		for i in 8:
			for j in range(i+1,8):
				for a in segments[i]:
					for b in segments[j]:
						var closest := Geometry3D.get_closest_points_between_segments(a[0],a[1],b[0],b[1])
						clearance=minf(clearance,closest[0].distance_to(closest[1]))
	check("Eight leg sectors remain separate through rapid turns and relocation",sector_ok)
	check("Visible leg beams never intersect (including their thickness)",clearance>.042)
	check("Feet stay on the current floor or inside the step arc",height_ok)
	spider.queue_free(); await frames(3)

func encounter_checks(use_xr: bool) -> void:
	await start(use_xr)
	var tag := "XRTools / " if use_xr else "Desktop / "
	game.place_player(Vector3(-5,-41.94,-1.3)); await frames(40)
	var spider: CharacterBody3D=game.building.content.exhibits["7/catalyst-spider"].get_node("Artifact")
	game.place_player(spider.global_position+Vector3(0,.06,1))
	for i in 100:
		await frames(1)
		if spider.attacks>0: break
	check(tag+"real crawler bite damages health and drives the sight adapter",spider.attacks==1 and game.health.health==80 and game.sight.amount>.35)
	check(tag+"head grippers animate at the bite",spider.tech_head.bite_left>0)
	var first: float=game.health.sight_impairment
	for i in 260:
		await frames(1)
		if spider.attacks>=2: break
	check(tag+"cooldown bite strengthens blur",spider.attacks==2 and game.health.health==60 and game.sight.amount>first)
	spider.hit_by_catalyst_mode(Color.GREEN,"primitives")
	await frames(135)
	check(tag+"calmed crawler healing restores health and clear sight",game.health.health==70 and game.sight.amount==0)
	game.health.apply_bite_damage(20)
	game.place_player(game.spawn_for(7))
	await frames(610)
	check(tag+"ten safe seconds clear the real camera effect",game.health.sight_impairment==0 and game.sight.amount==0)
	game.health.apply_bite_damage(100)
	check(tag+"lethal bite enters the existing death sequence",game.recovering and game.health.health==0)
	await frames(90)
	check(tag+"respawn clears sight at the saved floor",not game.recovering and game.health.health==100 and game.sight.amount==0 and game.checkpoint==7)
	game.queue_free(); await frames(10)
	if use_xr:
		for tracker in [head,left,right]: XRServer.remove_tracker(tracker)

func images() -> void:
	await start(false)
	game.place_player(Vector3(-5,-41.94,-1.3)); await frames(40)
	game._set_enabled(false)
	game.atmosphere.animate_sky=false; game.atmosphere.set_sky_time(180)
	var spider: CharacterBody3D=game.building.content.exhibits["7/catalyst-spider"].get_node("Artifact")
	spider.set_physics_process(false); spider.gait.set_process(false)
	spider.global_rotation.y=PI
	spider.gait._update_gait(0.0)
	game.camera.global_position=spider.global_position+Vector3(2.5,2.0,3.0)
	game.camera.look_at(spider.global_position+Vector3(0,1,0))
	await photo("crawler.png")
	game.camera.global_position=spider.global_position+Vector3(.01,4.8,.1)
	game.camera.look_at(spider.global_position)
	await photo("legs.png")
	game.camera.global_position=spider.global_position+Vector3(.65,1.65,2.7)
	game.camera.look_at(spider.global_position+Vector3(0,1.1,0))
	game.health.set_physics_process(false)
	await photo("clear.png")
	game.health.apply_bite_damage(20)
	await photo("bite.png")
	game.health.apply_bite_damage(20); game.health.apply_bite_damage(20)
	await photo("repeated-bites.png")
	game.health.set_health(50)
	await photo("healed.png")
	check("Rendered camera is clear after actual healing",game.sight.amount==0)
	game.queue_free(); await frames(12)

func photo(filename: String) -> void:
	game.notice_time=-1; game.status.hide(); game.hurt_time=0
	# Keep the Compatibility post-process layer; hide only desktop instructions.
	if game.desktop_help!=null: game.desktop_help.hide()
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(filename))
