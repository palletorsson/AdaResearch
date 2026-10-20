extends "res://tools/probes/void_game_probe.gd"

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	for use_xr in [false, true]:
		await start(use_xr)
		var label := "XRTools / " if use_xr else "Desktop / "
		var building: Node3D = game.building
		check(label + "original shaft pads remain", building.landing_pads.size() == 26)
		for destination in range(1, building.floors.size()):
			var slab: StaticBody3D = building.floors[destination].get_node("SlabCliffLanding")
			var plan: Dictionary = building.CliffLandings.landing(building.spec, destination)
			check(label + "floor %02d stays on the south facade" % destination, plan.side == 1.0)
			var centre: Vector3 = slab.to_global(Vector3(0, 0, plan.side * 1.6))
			var hit := ray(centre + Vector3.UP * 0.2, centre + Vector3.DOWN * 0.2)
			check(label + "floor %02d has real flush landing collision" % destination, not hit.is_empty() and hit.collider == slab and absf(hit.position.y - float(building.spec.levels[destination])) < 0.01)
			var bounds := Rect2(plan.outline[0], Vector2.ZERO)
			for point in plan.outline: bounds = bounds.expand(point)
			var corner: Vector3 = slab.to_global(Vector3(bounds.position.x + 0.03, 0, plan.side * (bounds.end.y - 0.03)))
			check(label + "floor %02d clipped corner has no invisible box floor" % destination, ray(corner + Vector3.UP * 0.2, corner + Vector3.DOWN * 0.2).is_empty())
			var upper := centre + Vector3.UP * float(building.spec.storey_height)
			check(label + "floor %02d can be seen and reached from above" % destination, ray(upper + Vector3.UP * 0.2, upper - Vector3.UP * 0.6).is_empty())
		# Both staggered columns, all three profiles, and every actual floor-edge
		# departure. Existing authored artifacts may constrain the approach.
		for destination in range(1, building.floors.size()):
			var plan: Dictionary = building.CliffLandings.landing(building.spec, destination)
			var source_y: float = building.spec.levels[destination - 1]
			game.checkpoint = destination - 1
			game.place_player(Vector3(plan.x, source_y + 0.06, plan.side * 8.35))
			game.health.reset()
			await frames(30)
			var deaths_before: int = game.deaths
			var pads_before: int = game.cushioned_landings
			if destination % 2 == 1: press_jump()
			axes(Vector2(0, plan.side))
			for step in range(100):
				await frames(1)
				if step == 1: release_jump()
				# Release before the landing centre: both rigs decelerate, and the
				# existing Lines enclosure has a rear wall at z=11.14.
				if absf(game.body.global_position.z) > 10.0 or game.recovering: break
			axes(Vector2.ZERO)
			await frames(105)
			print("LANDING ", destination, " ", game.body.global_position, " checkpoint=", game.checkpoint, " health=", game.health.get_health(), " death=", game.last_death)
			check(label + "land on cliff %02d and save its checkpoint" % destination, not game.recovering and game.deaths == deaths_before and game.body.is_on_floor() and game.checkpoint == destination)
			check(label + "concrete landing %02d costs 10 health, not a soft-pad landing" % destination, game.health.get_health() == 90 and game.cushioned_landings == pads_before)
			if game.recovering: await wait_for_recovery(deaths_before)
		# A real lateral jump from the first ledge to the next, without relocating
		# the player back onto the main floor. Test the initial cliff-to-cliff step.
		game.checkpoint = 1
		game.place_player(Vector3(3.4, -5.94, 10.4))
		game.health.reset(); await frames(30)
		var deaths_before: int = game.deaths
		press_jump(); axes(Vector2(1, 0))
		for step in range(100):
			await frames(1)
			if step == 1: release_jump()
			if game.body.global_position.x > 6.8 or game.recovering: break
		axes(Vector2.ZERO); await frames(110)
		check(label + "jump directly from first balcony to the staggered second", not game.recovering and game.deaths == deaths_before and game.body.is_on_floor() and game.checkpoint == 2 and game.health.get_health() == 90)
		game.queue_free(); await frames(15)
		if use_xr:
			for tracker in [head, left, right]: XRServer.remove_tracker(tracker)
	FileAccess.open(out.path_join("cliff-checks.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": failed.is_empty(), "checks": checks, "failed": failed, "scope": "Real Godot/Jolt collision, desktop movement and XRTools with synthetic trackers; no physical headset."}, "\t"))
	quit(0 if failed.is_empty() else 1)
