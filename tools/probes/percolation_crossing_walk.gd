extends SceneTree
## THE PERCOLATION CROSSING (floor PG_Percolation_Network; the pass, 2026-11-12)
## A field 12 cells across and 10 deep; a cell is floor when its number is under the share that is open. A body goes
## floor to floor across a shared face; a signal also passes where two floor cells touch at a corner.
## Read in the running tower, with its own walker:
##   THE BENCH    at every share from 25 % to 75 % the work says what the bench predicted before it was built
##                (tools/probes/percolation_bench.py --json 11 12 10): whether a body crosses, whether a signal
##                does, how many cells are floor, how many each reaches;
##   OPENING MORE NEVER CLOSES   every cell that is floor at one share is floor at every larger one;
##   THE BODY     at 60 % the walker follows the probe's own face-to-face path and arrives at the far side;
##                at 55 % (a signal crosses, a body does not) it follows the signal's path and is stopped at the
##                first corner, between two blocks that touch;
##   a cell with a body on it does not close, and closes when the body has left;
##   a plate opens more; what a frame costs.
##
##   godot --path <stage> --script res://tools/probes/percolation_crossing_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## crossing.json: checks with what was read. arrival.png, field.png, open_<percent>.png, stopped.png, across.png.
const ID := "percolation-crossing"
## share -> [a body crosses, a signal crosses, floor cells, cells a body reaches, cells a signal reaches]
const BENCH := {"0.25": [false, false, 30, 3, 3], "0.30": [false, false, 33, 4, 22], "0.35": [false, true, 42, 6, 34], "0.40": [false, true, 49, 20, 43],
	"0.45": [false, true, 51, 22, 47], "0.50": [false, true, 53, 22, 49], "0.55": [false, true, 60, 41, 55], "0.60": [true, true, 68, 53, 68],
	"0.65": [true, true, 73, 59, 73], "0.70": [true, true, 82, 75, 82], "0.75": [true, true, 87, 86, 87]}
const COLS := 12
const ROWS := 10
var game: Node3D
var level := 0.0


func _initialize() -> void:
	run.call_deferred()


func _shot(cam: Camera3D, at: Vector3, target: Vector3, path: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	cam.current = true
	for i in 4: await process_frame
	root.get_viewport().get_texture().get_image().save_png(path)
	cam.current = false


func _go(body: CharacterBody3D, target: Vector3, ticks_max: int = 300, speed: float = 0.34) -> float:
	var best := INF
	for i in ticks_max:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		best = minf(best, d)
		if d < 0.1: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -speed)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 12: await physics_frame
	return best


## The probe's own shortest way from the near row to the far row: cells, or nothing. `corners`: a signal's way.
func _way(work: Node, corners: bool) -> Array:
	var came := {}
	var line := []
	for c in COLS:
		if work.is_open(c, 0):
			came[Vector2i(c, 0)] = Vector2i(-1, -1)
			line.append(Vector2i(c, 0))
	var steps := [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)]
	if corners: steps.append_array([Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)])
	var head := 0
	while head < line.size():
		var at: Vector2i = line[head]
		head += 1
		if at.y == ROWS - 1:
			var out := [at]
			while came[out[0]] != Vector2i(-1, -1): out.push_front(came[out[0]])
			return out
		for d: Vector2i in steps:
			var next: Vector2i = at + d
			if work.is_open(next.x, next.y) and not came.has(next):
				came[next] = at
				line.append(next)
	return []


func _settle(work: Node) -> void:
	for i in 400:
		if work.settled(): return
		await physics_frame


func run() -> void:
	var folder := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	var floor: int = game.checkpoint
	var record: Dictionary = game.building.content.data.floors[floor]
	var checks := []
	var result := {"floor": floor, "map": str(record.map), "checks": checks, "passed": false}
	for i in 1500:
		if game.building.content.exhibits.has(str(floor) + "/" + ID): break
		await physics_frame
	var mount: Node3D = game.building.content.exhibits.get(str(floor) + "/" + ID)
	var work: Node3D = mount.get_node_or_null("Artifact") if mount != null else null
	checks.append({"check": "the floor holds the percolation crossing", "ok": work != null and work.has_method("crosses")})
	if work != null and work.has_method("crosses"):
		for i in 300: await physics_frame
		level = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var body: CharacterBody3D = game.body
		for layer in root.find_children("*", "CanvasLayer", true, false):
			if layer.get_viewport() == root: layer.hide()
		var cam := Camera3D.new()
		cam.fov = 80
		root.add_child(cam)
		var centre: Vector3 = work.global_position
		game.place_player(Vector3(5.5, level + 0.3, 8.6))
		for i in 30: await physics_frame
		await _settle(work)
		await _shot(cam, Vector3(0, level + 1.6, 7.8), centre + Vector3(0, 0.3, -1.0), folder.path_join("arrival.png"))
		await _shot(cam, centre + Vector3(-2.5, 5.0, 6.6), centre + Vector3(0.3, 0.0, -0.6), folder.path_join("field.png"))
		work.apply_grid_config({"flood_cells_per_second": 400.0})

		# 1 the bench, every share; and opening more never closes
		var bench_ok := true
		var rows := []
		var monotone := true
		var before := []
		for share in ["0.25", "0.30", "0.35", "0.40", "0.45", "0.50", "0.55", "0.60", "0.65", "0.70", "0.75"]:
			work.set_open(float(share))
			await _settle(work)
			var now: Dictionary = work.crosses()
			var read := [bool(now["body"]), bool(now["signal"]), int(now["floor"]), int(now["body_reach"]), int(now["signal_reach"])]
			if str(read) != str(BENCH[share]): bench_ok = false
			rows.append({"open": share, "read": read, "bench": BENCH[share]})
			var floor_now := []
			for c in COLS:
				for r in ROWS:
					if work.is_open(c, r): floor_now.append(Vector2i(c, r))
					if work.is_open(c, r) == work.is_solid(c, r): bench_ok = false       # floor is never solid, a block always is
			for cell in before:
				if not cell in floor_now: monotone = false
			before = floor_now
			if share in ["0.30", "0.45", "0.55", "0.60", "0.70"]:
				await _shot(cam, centre + Vector3(0, 5.2, 6.4), centre + Vector3(0, 0.0, -0.4), folder.path_join("open_%s.png" % share.substr(2)))
		checks.append({"check": "at every share from 25 % to 75 % the work says what the bench predicted: who crosses, how many cells are floor, how many each reaches", "ok": bench_ok, "shares": rows})
		checks.append({"check": "opening more never closes a cell", "ok": monotone})

		# 2 the body: across at 60 %
		work.set_open(0.60)
		await _settle(work)
		var by_face: Array = _way(work, false)
		var start: Vector3 = work.cell_centre(by_face[0].x, by_face[0].y) if not by_face.is_empty() else centre
		game.place_player(start + Vector3(0, 0.3, 0.9))
		for i in 40: await physics_frame
		var walked := 0
		for cell: Vector2i in by_face:
			if await _go(body, work.cell_centre(cell.x, cell.y)) > 0.3: break
			walked += 1
		var feet: float = body.global_position.y - level
		checks.append({"check": "60 % open: the walker follows a face-to-face way and stands on the far row", "ok": not by_face.is_empty() and walked == by_face.size() and absf(feet) < 0.2 and int(work.crossed_on_foot()) == 1,
			"cells_on_the_way": by_face.size(), "cells_walked": walked, "feet_m": snappedf(feet, .01), "the_work_counted_a_crossing": int(work.crossed_on_foot())})
		await _shot(cam, body.global_position + Vector3(1.6, 2.6, 3.4), body.global_position + Vector3(-0.4, 0.2, 1.8), folder.path_join("across.png"))

		# 3 the body: stopped at 55 %, where a signal crosses
		# the walker stands on the far row: a block does not come down beside a body, so it steps out of the field first
		game.place_player(Vector3(5.5, level + 0.3, 8.6))
		for i in 30: await physics_frame
		work.set_open(0.55)
		await _settle(work)
		var face_way: Array = _way(work, false)
		var by_corner: Array = _way(work, true)
		var first_corner := -1
		# a diagonal step is a corner only where both cells beside it are blocks; with one of them floor a body goes round
		for i in range(1, by_corner.size()):
			var step: Vector2i = by_corner[i] - by_corner[i - 1]
			if step.x != 0 and step.y != 0 and work.is_solid(by_corner[i - 1].x, by_corner[i].y) and work.is_solid(by_corner[i].x, by_corner[i - 1].y): first_corner = i; break
		start = work.cell_centre(by_corner[0].x, by_corner[0].y) if not by_corner.is_empty() else centre
		game.place_player(start + Vector3(0, 0.3, 0.9))
		for i in 40: await physics_frame
		walked = 0
		for cell: Vector2i in by_corner:
			if await _go(body, work.cell_centre(cell.x, cell.y), 200) > 0.3: break
			walked += 1
		var blocked_by_blocks := false
		if first_corner > 0:
			var a: Vector2i = by_corner[first_corner - 1]
			var b: Vector2i = by_corner[first_corner]
			blocked_by_blocks = work.is_solid(a.x, b.y) and work.is_solid(b.x, a.y)
		checks.append({"check": "55 % open: no face-to-face way exists; the walker follows the signal's way and is stopped at its first corner, between two blocks that touch", "ok": face_way.is_empty() and first_corner > 0 and walked == first_corner and blocked_by_blocks,
			"cells_on_the_signals_way": by_corner.size(), "first_corner_at_step": first_corner, "cells_walked": walked, "two_blocks_touch_there": blocked_by_blocks})
		await _shot(cam, body.global_position + Vector3(1.4, 2.6, 2.6), body.global_position + Vector3(-0.2, 0.3, -0.6), folder.path_join("stopped.png"))

		# 4 a cell with a body on it does not close
		work.set_open(0.75)
		await _settle(work)
		var stays := Vector2i(-1, -1)
		work.set_open(0.75)
		for c in COLS:
			for r in range(1, ROWS - 1):
				if stays.x < 0 and work.is_open(c, r):
					work.set_open(0.25)
					var closes: bool = not work.is_open(c, r)
					work.set_open(0.75)
					if closes: stays = Vector2i(c, r)
		await _settle(work)
		game.place_player(work.cell_centre(stays.x, stays.y) + Vector3(0, 0.3, 0))
		for i in 50: await physics_frame
		var stood: Vector3 = body.global_position
		work.set_open(0.25)
		for i in 90: await physics_frame
		var held: bool = not work.is_solid(stays.x, stays.y) and body.global_position.distance_to(stood) < 0.08
		game.place_player(Vector3(5.5, level + 0.3, 8.6))
		for i in 30: await physics_frame
		var closed: bool = work.is_solid(stays.x, stays.y)
		checks.append({"check": "a cell with a body on it does not close; when the body has left it does", "ok": stays.x >= 0 and held and closed, "cell": [stays.x, stays.y], "held_open": held, "closed_after": closed})

		# 5 a plate; cost
		work.set_open(0.50)
		await _settle(work)
		var plate: Vector3 = work.plate_centre(0)
		game.place_player(plate + Vector3(0, 0.3, 1.0))
		for i in 80: await physics_frame
		await _go(body, plate)
		checks.append({"check": "a body steps on OPEN MORE and 55 % is open", "ok": is_equal_approx(float(work.open), 0.55), "open": float(work.open)})
		work.frame_ms()
		work.set_open(0.75)
		for i in 60: await process_frame
		var changing: float = work.frame_ms()
		await _settle(work)
		work.frame_ms()
		for i in 120: await process_frame
		var resting: float = work.frame_ms()
		checks.append({"check": "a frame costs under 0.5 ms while blocks move and the flood runs, under 0.1 ms at rest", "ok": changing < 0.5 and resting < 0.1, "changing_ms": snappedf(changing, .001), "resting_ms": snappedf(resting, .001)})
		work.apply_grid_config({"flood_cells_per_second": 14.0})
		work.set_open(0.50)
		game.place_player(Vector3(5.5, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("crossing.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[percolation_crossing_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
