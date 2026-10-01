extends "res://supplied/sheet_tools.gd"
## The bullet kit's stills and measurements. It needs a window, so run it
## WITHOUT --headless, from this folder:
##   godot --path . --xr-mode off --script res://sheet.gd
## It writes
##   sheet.png    the argument: the same launch at four steps (1/10, 1/30, 1/60
##                and 1/240 s), each alone in the studio from the side; under
##                them the same four with the two lines of step() swapped. The
##                lavender curve in every tile is the formula's: no steps.
##   orbit.png    the field trip: one orbit stepped three ways
##   process.png  the strip: one still after each operation, from one standpoint
##   sheet.json   every number: steps, landing, highest place, the sharpest
##                corner, every pair of the sheet, five flights stepped by the
##                frame, the orbits, the strip
## and the stills, in stills/. The flights are stepped in a loop, so a still
## shows a whole flight; nothing here waits for a bullet to fly.

const RATES := [10, 30, 60, 240]        # the axis: steps per second; dt is 1 / it
const LAUNCH := Vector3(4, 6, 0)
const START := Vector3(0, 0.1, 0)
const G := 9.8
const STANDS := Vector3(-2.45, 0, 0)    # where the bullet's node stands, as in launch.tscn
const CENTRE := Vector3(0, 1.6, 0)

func run() -> void:
	await sheet()
	await by_the_frame()
	await orbits()
	await process_strip()

## A tile of 320 x 240 from a still. The supplied small() takes one pixel in
## three, and a path of dots a few pixels wide comes out in pieces; halving
## first averages every dot into the tile.
func tile(still: Image) -> Image:
	var out: Image = still.duplicate()
	out.shrink_x2()
	out.resize(TILE.x, TILE.y, Image.INTERPOLATE_BILINEAR)
	return out

## Where the formula puts the bullet after `t` seconds, counted from the bullet's node.
func formula(t: float) -> Vector3:
	return START + LAUNCH * t + Vector3(0, -0.5 * G * t * t, 0)

## The formula's curve as a band of GHOST dots, a little behind the bullet's own path.
func formula_curve() -> MeshInstance3D:
	var curve := MeshInstance3D.new()
	var mesh := ImmediateMesh.new()
	var ghost := Look.paint(Look.GHOST)
	ghost.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ghost.use_point_size = true
	ghost.point_size = 3.0
	mesh.surface_begin(Mesh.PRIMITIVE_POINTS, ghost)
	var whole := 2.0 * LAUNCH.y / G
	for i in 801:
		mesh.surface_add_vertex(STANDS + formula(whole * i / 800.0) + Vector3(0, 0, -0.02))
	mesh.surface_end()
	curve.mesh = mesh
	curve.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return curve

func bullet(rate: int) -> Node3D:
	var b: Node3D = load("res://bullet.tscn").instantiate()
	b.steps_per_second = rate
	b.position = STANDS
	return b

## One step in another order, done on the bullet's own fields.
##   "swapped"  the two lines the other way round: the place first, then the velocity
##   "old"      both lines read the state from before the step (explicit Euler)
func other_step(b: Node3D, order: String) -> void:
	if order == "swapped":
		b.at += b.velocity * b.dt
		b.velocity += b.pull() * b.dt
	else:
		var before: Vector3 = b.velocity
		b.velocity += b.pull() * b.dt
		b.at += before * b.dt
	if b.at.y <= 0.1:
		b.at.y = 0.1
		b.flying = false
	b.path.append(b.at)

## A whole flight in a loop, then shown. `count` stops it after that many steps.
func fly(b: Node3D, order := "", count := 100000) -> Dictionary:
	b.set_physics_process(false)
	b.fire()
	var apex := 0.0
	var n := 0
	while b.flying and n < count:
		if order == "":
			b.step()
		else:
			other_step(b, order)
		n += 1
		apex = maxf(apex, b.at.y)
	b.get_node("Ball").position = b.at
	b.draw_path()
	var corner := 0.0     # the sharpest turn between two segments of the path, in degrees
	for i in range(1, b.path.size() - 2):
		corner = maxf(corner, rad_to_deg((b.path[i] - b.path[i - 1]).angle_to(b.path[i + 1] - b.path[i])))
	return {"steps": n, "landed_m": snappedf(b.at.x - b.start.x, 0.0001), "seconds": snappedf(n * b.dt, 0.0001), "apex_m": snappedf(apex, 0.001), "sharpest_corner_deg": snappedf(corner, 0.01)}

## The comparison sheet: the four steps, and the four with the lines swapped.
func sheet() -> void:
	await stand(null)
	var curve := formula_curve()
	studio.add_child(curve)
	look("level", 6.6, Vector3(0.35, 1.0, 0))
	var empty := await shot("empty")
	var tiles: Array[Image] = []
	var names := []
	var record := {"formula": {"landed_m": snappedf(2.0 * LAUNCH.x * LAUNCH.y / G, 0.0001), "seconds": snappedf(2.0 * LAUNCH.y / G, 0.0001), "apex_m": snappedf(START.y + LAUNCH.y * LAUNCH.y / (2.0 * G), 0.001)}}
	for order: String in ["", "swapped"]:
		var stills := []
		var flights := {}
		var row_names := []
		for rate: int in RATES:
			var b := bullet(rate)
			await stand(b)
			var flight := fly(b, order)
			look("level", 6.6, Vector3(0.35, 1.0, 0))
			var still := await shot("dt_1_%d%s" % [rate, "_swapped" if order != "" else ""])
			flight["covers_pct"] = differ_pct(still, empty)
			if rate == 10 and order == "":
				# One material for both surfaces: is a line strip drawn as a line when use_point_size is on?
				b.line = b.dots
				b.draw_path()
				var one := await shot("dt_1_10_one_material")
				record["line_strip_with_the_dots_material"] = {"covers_pct": differ_pct(one, empty), "differs_from_two_materials_pct": differ_pct(one, still)}
				print("1/10 s with the dots' material on the line strip too: covers %.2f%% of the still; with two materials %.2f%%" % [record["line_strip_with_the_dots_material"]["covers_pct"], flight["covers_pct"]])
			flights["1/%d s" % rate] = flight
			stills.append(still)
			tiles.append(tile(still))
			row_names.append("1/%d s%s" % [rate, ", lines swapped" if order != "" else ""])
			print("%s: %d steps, landed %.4f m, highest %.3f m, sharpest corner %.2f deg, covers %.2f%% of the still" % [row_names[-1], flight["steps"], flight["landed_m"], flight["apex_m"], flight["sharpest_corner_deg"], flight["covers_pct"]])
		names.append_array(row_names)
		var pairs := {}
		var closest := ""
		var farthest := ""
		for i in RATES.size():
			for j in range(i + 1, RATES.size()):
				var key := "1/%d s vs 1/%d s" % [RATES[i], RATES[j]]
				var a: Dictionary = flights["1/%d s" % RATES[i]]
				var c: Dictionary = flights["1/%d s" % RATES[j]]
				pairs[key] = {"differ_pct": differ_pct(stills[i], stills[j]), "landings_apart_cm": snappedf(absf(a["landed_m"] - c["landed_m"]) * 100.0, 0.01), "highest_places_apart_cm": snappedf(absf(a["apex_m"] - c["apex_m"]) * 100.0, 0.1)}
				if closest == "" or pairs[key]["differ_pct"] < pairs[closest]["differ_pct"]:
					closest = key
				if farthest == "" or pairs[key]["differ_pct"] > pairs[farthest]["differ_pct"]:
					farthest = key
				print("%s%s differ on %5.2f%% of the still; landings %.2f cm apart, highest places %.1f cm apart" % [key, " (swapped)" if order != "" else "", pairs[key]["differ_pct"], pairs[key]["landings_apart_cm"], pairs[key]["highest_places_apart_cm"]])
		record["velocity_first" if order == "" else "lines_swapped"] = {"flights": flights, "pairs": pairs, "closest": closest, "farthest": farthest}
	record["how"] = "each flight alone in the studio, seen level from 6.6 m; covers_pct is the share of the still that differs from the studio with only the formula's curve in it"
	report["sheet"] = record
	report["sheet_png"] = await compose(tiles, RATES.size(), names, "res://sheet.png")
	curve.free()

## Five flights stepped once for each drawn frame, with that frame's own
## length as dt: what the lesson's `_process(delta)` version does.
func by_the_frame() -> void:
	var flights := []
	for launch in 5:
		var b := bullet(60)
		await stand(b, false)
		b.set_physics_process(false)
		b.fire()
		var shortest := INF
		var longest := 0.0
		while b.flying:
			await process_frame
			b.dt = root.get_process_delta_time()
			shortest = minf(shortest, b.dt)
			longest = maxf(longest, b.dt)
			b.step()
		_last_sign = Time.get_ticks_msec()
		flights.append({"steps": b.path.size() - 1, "landed_m": snappedf(b.at.x - b.start.x, 0.0001), "shortest_frame_s": snappedf(shortest, 0.00001), "longest_frame_s": snappedf(longest, 0.00001)})
		print("by the frame, flight %d: %d steps, landed %.4f m; frames from %.5f to %.5f s" % [launch + 1, flights[-1]["steps"], flights[-1]["landed_m"], shortest, longest])
	report["by_the_frame"] = {"flights": flights, "screen_refresh_hz": snappedf(DisplayServer.screen_get_refresh_rate(), 0.01),
		"how": "the bullet of bullet.tscn, its own clock off, stepped once after each drawn frame with dt set to that frame's delta"}

## The field trip: orbit.tscn's bullet and centre, stepped three ways.
func orbits() -> void:
	var tiles: Array[Image] = []
	var names := ["velocity first, 60 s", "the two lines swapped, 60 s", "both from the old state"]
	var orders := ["", "swapped", "old"]
	var record := {}
	for k in 3:
		var group := Node3D.new()
		var centre := MeshInstance3D.new()
		centre.name = "Centre"
		var ball := SphereMesh.new()
		ball.radius = 0.15
		ball.height = 0.3
		centre.mesh = ball
		centre.position = CENTRE
		group.add_child(centre)
		var o: Node3D = load("res://bullet.tscn").instantiate()
		o.set_script(load("res://orbit.gd"))
		o.name = "Orbit"
		o.start = Vector3(1, 1.6, 0)
		o.launch = Vector3(0, 2, 0)
		group.add_child(o)
		await stand(group)
		var flight := fly(o, orders[k], 3600)
		var low := INF
		var high := 0.0
		for place: Vector3 in o.path:
			low = minf(low, (place - CENTRE).length())
			high = maxf(high, (place - CENTRE).length())
		look("level", 6.4, Vector3(0, 1.5, 0))
		tiles.append(tile(await shot("orbit_%d" % (k + 1))))
		record[names[k]] = {"steps": flight["steps"], "seconds": flight["seconds"], "landed": not o.flying, "nearest_m": snappedf(low, 0.001), "farthest_m": snappedf(high, 0.001)}
		print("orbit, %s: %d steps, %.2f s, landed %s, between %.3f and %.3f m from the centre" % [names[k], flight["steps"], flight["seconds"], not o.flying, low, high])
	record["png"] = await compose(tiles, 3, names, "res://orbit.png")
	report["orbits"] = record

## The process strip: one still after each operation, from one standpoint.
func process_strip() -> void:
	var names := ["1 the two lines, three times", "2 a loop until it lands", "3 the path drawn", "4 a step for every tick", "5 our own clock: 1/240 s", "6 the two lines swapped", "7 a body where it lands"]
	var tiles: Array[Image] = []
	var counts := []
	var group := Node3D.new()
	await stand(group, false)
	look_from(Vector3(0.35, 1.5, 6.6), Vector3(0.35, 1.0, 0.0))
	var b := bullet(10)
	group.add_child(b)
	await process_frame
	var flight := fly(b, "", 3)
	(b.get_node("Path").mesh as ImmediateMesh).clear_surfaces()
	tiles.append(tile(await shot("strip_1")))
	counts.append({"bullet_steps": 3, "places_drawn": 0})
	flight = fly(b)
	(b.get_node("Path").mesh as ImmediateMesh).clear_surfaces()
	tiles.append(tile(await shot("strip_2")))
	counts.append({"bullet_steps": flight["steps"], "places_drawn": 0, "landed_m": flight["landed_m"]})
	b.draw_path()
	tiles.append(tile(await shot("strip_3")))
	counts.append({"bullet_steps": flight["steps"], "places_drawn": b.path.size(), "landed_m": flight["landed_m"]})
	b.steps_per_second = 60
	flight = fly(b)
	tiles.append(tile(await shot("strip_4")))
	counts.append({"bullet_steps": flight["steps"], "places_drawn": b.path.size(), "landed_m": flight["landed_m"]})
	b.steps_per_second = 240
	flight = fly(b)
	tiles.append(tile(await shot("strip_5")))
	counts.append({"bullet_steps": flight["steps"], "places_drawn": b.path.size(), "landed_m": flight["landed_m"]})
	b.steps_per_second = 10
	flight = fly(b, "swapped")
	tiles.append(tile(await shot("strip_6")))
	counts.append({"bullet_steps": flight["steps"], "places_drawn": b.path.size(), "landed_m": flight["landed_m"]})
	var walker: CharacterBody3D = load("res://supplied/walker.tscn").instantiate()
	walker.position = STANDS + Vector3(2.0 * LAUNCH.x * LAUNCH.y / G, 0, 0)   # before add_child
	walker.keys = false
	group.add_child(walker)
	b.walker = walker
	b.steps_per_second = 60
	for i in 20:
		await physics_frame
	flight = fly(b)
	tiles.append(tile(await shot("strip_7")))
	counts.append({"bullet_steps": flight["steps"], "places_drawn": b.path.size(), "landed_m": flight["landed_m"], "hit": b.hit})
	report["strip"] = await strip(tiles, names)
	for i in counts.size():
		report["strip"]["steps"][i].merge(counts[i])
