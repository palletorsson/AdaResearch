extends "res://doc/book/iterations/2026-09-28-paint-spray-cans/probe.gd"
var can: Node3D
var grabber: Node3D
var surface: MeshInstance3D
func clear_paint() -> void:
	can.action_release(); surface.reset_canvas()
	for frame in 8: await process_frame
func place(uv: Vector2, distance: float) -> void:
	var hit := surface.to_global(Vector3((uv.x - 0.5) * 4.0, 0, (uv.y - 0.5) * 2.5))
	var origin := hit + surface.global_basis.y.normalized() * distance
	var basis := Basis.looking_at(hit - origin, Vector3.UP)
	grabber.global_transform = Transform3D(basis, origin - basis * Vector3(0, 0.16, -0.03))
func read_image() -> Image:
	for frame in 3: await process_frame
	await RenderingServer.frame_post_draw
	return surface.viewport.get_texture().get_image()
func strip_darkness(im: Image, from_uv: Vector2, to_uv: Vector2) -> float:
	var sum := 0.0; var count := 0
	for y in range(int(from_uv.y * im.get_height()), int(to_uv.y * im.get_height())):
		for x in range(int(from_uv.x * im.get_width()), int(to_uv.x * im.get_width())):
			var c := im.get_pixel(x, y); sum += (3.0 - c.r - c.g - c.b) / 3.0; count += 1
	return sum / maxi(count, 1)
func line_pass(y: float, frames_per_step: int) -> void:
	place(Vector2(0.15, y), 0.4)
	for frame in 3: await physics_frame
	can.action()
	for step in range(1, 16 * frames_per_step + 1):
		place(Vector2(0.15 + 0.70 * step / (16.0 * frames_per_step), y), 0.4)
		await physics_frame
	can.action_release()
func landing_checks() -> void:
	root.size = Vector2i(1440, 960)
	var grid: Node3D = hall.get_node_or_null("SimGrid_Color_Paint")
	check("authored grid exists", grid != null)
	if grid == null: return
	for frame in 3600:
		if grid.has_meta("stage_grid_ready"): break
		await process_frame
	painter = find_scene("/ball_painting_automation.gd")
	check("production spray installation exists", painter != null)
	if painter == null: return
	painter.set_process(false); surface = painter.surface
	can = painter.get_node("PaintBalls").get_child(23)
	grabber = SuppliedGrabber.new(); root.add_child(grabber); grabber.global_transform = can.global_transform
	can.pick_up(grabber)
	await clear_paint()
	# Two sweeps with identical path and nozzle distance, different time budgets.
	await line_pass(0.25, 1)
	var fast := await read_image()
	var fast_dark := strip_darkness(fast, Vector2(0.2, 0.24), Vector2(0.8, 0.26))
	fast.save_png(folder + "fast-pass-texture.png")
	await line_pass(0.44, 4)
	var slow := await read_image()
	var slow_dark := strip_darkness(slow, Vector2(0.2, 0.43), Vector2(0.8, 0.45))
	check("slower sweep lays down more pigment", slow_dark > fast_dark * 1.5 and fast_dark > 0.006)
	var gaps := 0
	for x in range(310, 1150, 12):
		if strip_darkness(fast, Vector2(float(x)/1440.0, 0.24), Vector2(float(x+5)/1440.0, 0.26)) < 0.003: gaps += 1
	check("fast stroke remains continuous between physics samples", gaps < 3)
	check("ordinary moving passes do not start runs", surface.aerosol.runs_started == 0)
	observations["sweep"] = {"fast": fast_dark, "slow": slow_dark, "gaps": gaps}
	await frame_photo("speed-and-coverage")
	# A short distant burst should expose separate droplets in its outer annulus.
	place(Vector2(0.74, 0.72), 1.2)
	for frame in 3: await physics_frame
	can.action()
	for frame in 5: await physics_frame
	can.action_release()
	var overspray := await read_image()
	var speckles := 0; var holes := 0
	var centre: Vector2 = can.paper_surface.get_uv_from_world_pos(surface.to_global(Vector3(0.96,0,0.55))) * Vector2(surface.texture_size)
	for y in range(int(centre.y)-60, int(centre.y)+60):
		for x in range(int(centre.x)-60, int(centre.x)+60):
			var delta_px := Vector2(x,y) - centre
			var radius := Vector2(delta_px.x/57.0, delta_px.y/64.0).length()
			if radius < 0.60 or radius > 0.90: continue
			var c := overspray.get_pixel(x,y)
			var dark := (3.0-c.r-c.g-c.b)/3.0
			if dark > 0.035: speckles += 1
			if dark < 0.012: holes += 1
	check("overspray includes visible pigment specks and uncovered gaps", speckles > 10 and holes > 10)
	observations["overspray"] = {"speck_pixels": speckles, "gap_pixels": holes}
	await frame_photo("aerosol-edge")
	# Stationary excess should drip below, never above the applied mark.
	await clear_paint()
	var target := Vector2(38.5/96.0, 25.5/60.0)
	place(target, 0.25)
	for frame in 3: await physics_frame
	can.action()
	for frame in 115: await physics_frame
	check("stationary close spray overloads the local paint reservoir", surface.aerosol.runs_started > 0)
	check("held valve depresses and produces local hiss", can.hiss.playing and can.get_node("NozzleButton").position.y < 0.16)
	can.action_release()
	var created: int = surface.aerosol.runs_started
	for frame in 75: await physics_frame
	var drip := await read_image()
	var below := strip_darkness(drip, Vector2(target.x-0.005,target.y+0.028), Vector2(target.x+0.005,target.y+0.095))
	var above := strip_darkness(drip, Vector2(target.x-0.005,target.y-0.095), Vector2(target.x+0.005,target.y-0.028))
	check("run pigment extends downward beyond the spray footprint", below > 0.01 and below > above * 3.0)
	check("release stops new deposits and hiss while existing paint can run", not can.is_spraying and not can.hiss.playing and surface.aerosol.runs_started == created)
	await frame_photo("held-too-long")
	for frame in 105: await physics_frame
	check("runs come to rest rather than falling forever", surface.aerosol.runs.is_empty())
	observations["run"] = {"started": created, "below": below, "above": above}
	# Paint cannot bridge a release; the nozzle continues to work in empty space.
	await clear_paint()
	place(Vector2(0.18,0.5),0.4)
	for frame in 3: await physics_frame
	can.action()
	for frame in 10: await physics_frame
	can.action_release()
	place(Vector2(0.82,0.5),0.4)
	for frame in 3: await physics_frame
	can.action()
	for frame in 10: await physics_frame
	can.action_release()
	var separated := await read_image()
	check("release leaves the space between separate gestures clean", strip_darkness(separated, Vector2(0.35,0.48), Vector2(0.65,0.52)) < 0.001)
	grabber.rotate_y(PI); can.action(); var count: int = can.painted_samples
	for frame in 8: await physics_frame
	check("empty-space spray emits and hisses without painting", can.is_spraying and can.mist.emitting and can.hiss.playing and not can.is_painting and can.painted_samples == count)
	can.action_release()
	check("release closes the valve in empty space", not can.is_spraying and not can.mist.emitting and not can.hiss.playing and is_equal_approx(can.get_node("NozzleButton").position.y,0.16))
	await clear_paint()
	check("reset clears wet-load history as well as pigment", surface.aerosol.wet_cells.is_empty() and surface.aerosol.runs.is_empty())
	# Sweep across a thin physical occluder between two valid endpoint rays.
	var blocker := StaticBody3D.new(); var shape := CollisionShape3D.new(); var box := BoxShape3D.new()
	box.size = Vector3(0.065,0.5,0.06); shape.shape = box; blocker.add_child(shape); root.add_child(blocker)
	blocker.global_transform = Transform3D(painter.global_basis, surface.global_position + surface.global_basis.y.normalized()*0.17)
	for frame in 3: await physics_frame
	place(Vector2(0.445,0.5),0.4)
	for frame in 3: await physics_frame
	can.action()
	for frame in 5: await physics_frame
	place(Vector2(0.555,0.5),0.4)
	for frame in 1: await physics_frame
	can.action_release()
	var masked := await read_image()
	check("interpolated rays respect the intervening obstacle", strip_darkness(masked, Vector2(0.496,0.494), Vector2(0.504,0.506)) < 0.02)
	blocker.queue_free()
	# Final museum photograph: manual marks meet the continuing automatic painter.
	await clear_paint()
	painter.set_process(true)
	await line_pass(0.18, 2)
	await line_pass(0.34, 4)
	place(Vector2(0.67,0.52),0.25)
	for frame in 3: await physics_frame
	can.action()
	for frame in 105: await physics_frame
	can.action_release()
	place(Vector2(0.23,0.52),1.1)
	for frame in 3: await physics_frame
	can.action()
	for frame in 14: await physics_frame
	can.action_release()
	for frame in 45: await physics_frame
	await frame_photo("shared-aerosol")
	await snapshot("spray-close-up",painter.to_global(Vector3(-0.3,1.35,2.1)),painter.to_global(Vector3(0,1.3,-0.5)),57)
	check("render stamp pool stays bounded", surface.brush_layer.spray_pool.size() <= 64)
	check("wet-load grid and runs stay bounded", surface.aerosol.wet_cells.size() <= 96*60 and surface.aerosol.runs.size() <= 24)
	can.let_go(grabber,Vector3.ZERO,Vector3.ZERO)
	completed = true
func finish() -> void:
	check("aerosol experiment completed",completed)
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Native museum, actual GPU pigment and can raycasts with supplied hand inputs. Desktop carry regression checked separately. Tracked trigger pressure, headset performance and perceived sound remain unverified."},"  "))
	print("AEROSOL ", checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
