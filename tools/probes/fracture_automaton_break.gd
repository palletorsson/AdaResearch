extends SceneTree
## THE FRACTURE AUTOMATON (floor CA_SoftRules; Palle, 2026-11-12: "Can we use cellular automata to fracture
## objects?")
## A block of 720 cells; a bond is the face two cells share, with a strength and a load; a bond breaks when its load
## is more than its strength and hands the excess to the bonds ahead in its own plane; the pieces are the cells still
## joined, and each gets a rigid body. Read in the running tower, with its own walker:
##   THE RULE     six blows on each of the five grains, on the lattice alone, give exactly what the bench predicted
##                before the work was built (tools/probes/fracture_bench.py 90 --json): bonds broken, pieces, the largest
##                pieces, the steps the rule took;
##   THE STONE    in the tower the first stone lands on the predicted point and breaks exactly what the bench says;
##   THE PIECES   after every blow the bodies are the partition of the cells by the unbroken bonds: 720 cells, every
##                piece one joined body, no unbroken bond between two pieces;
##   GRAVITY      after six blows pieces have moved, and none has left the pool;
##   MENDING      the pieces go back, the block is whole, the next grain begins;
##   THE BODY     a walker climbs the kit's ramp to the deck and walks up to the STRIKE post: a stone is thrown; it
##                walks down the pool's own ramp to the block's face;
##   what a physics tick costs, mean and worst.
##
##   godot --path <stage> --script res://tools/probes/fracture_automaton_break.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## fracture.json: checks with what was read. arrival.png, whole.png, blow_1.png, rubble.png, above.png, mended.png,
## still_<grain>.png (six blows by the rule alone, the pieces held apart).
const ID := "fracture-quarry"
const SCRIPT := "res://algorithms/cellularautomata/fracture_automaton/fracture_automaton.gd"
const POWER := 90.0
## [bonds broken by this blow, pieces after it, the largest pieces, steps so far]
const PREDICTED := {
	"even": [[109, 3, [711, 5, 4], 7], [115, 6, [675, 23, 12, 5], 14], [125, 12, [657, 12, 11, 9], 28], [123, 26, [631, 12, 11, 6], 39], [129, 41, [490, 70, 30, 12], 64], [112, 61, [440, 70, 47, 12], 82]],
	"layered": [[70, 1, [720], 7], [128, 4, [432, 285, 2, 1], 20], [71, 8, [420, 282, 6, 5], 26], [127, 14, [282, 216, 198, 5], 39], [80, 30, [282, 192, 189, 6], 52], [83, 39, [282, 189, 105, 84], 62]],
	"columnar": [[111, 3, [540, 171, 9], 12], [118, 4, [360, 180, 171, 9], 22], [124, 8, [180, 174, 171, 171], 32], [80, 18, [180, 171, 171, 157], 43], [75, 39, [171, 161, 161, 157], 53], [66, 51, [171, 161, 161, 157], 61]],
	"glass": [[224, 7, [540, 126, 45, 4], 17], [240, 26, [180, 105, 90, 90], 34], [209, 49, [60, 60, 60, 60], 46], [217, 95, [60, 45, 45, 45], 62], [0, 95, [60, 45, 45, 45], 62], [151, 145, [60, 45, 45, 45], 77]],
	"knotted": [[101, 1, [720], 11], [58, 3, [702, 17, 1], 19], [69, 5, [693, 17, 6, 3], 30], [75, 11, [676, 17, 6, 6], 37], [59, 18, [664, 17, 6, 6], 47], [62, 24, [664, 17, 6, 6], 54]]}
const TARGETS := [Vector2i(9, 7), Vector2i(3, 6), Vector2i(6, 4), Vector2i(8, 3), Vector2i(3, 3), Vector2i(7, 2)]
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


func _go(body: CharacterBody3D, target: Vector3, ticks_max: int = 700, speed: float = 0.5) -> float:
	var best := INF
	for i in ticks_max:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		best = minf(best, d)
		if d < 0.15: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -speed)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 25: await physics_frame
	return best


func _until(work: Node, phases: Array, ticks_max: int = 900) -> bool:
	for i in ticks_max:
		if str(work.state().phase) in phases: return true
		await physics_frame
	return false


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

	# 1 the rule alone, against the bench
	var Lat = load(SCRIPT).Lattice
	var rule_rows := {}
	var rule_ok := true
	for g: String in PREDICTED:
		var lat = Lat.new(g, Vector3i(12, 10, 6), 7)
		var rows := []
		for t: Vector2i in TARGETS:
			lat.load_point(Vector3i(t.x, t.y, 5), POWER)
			var broke: int = lat.run()
			var sizes := []
			for comp in lat.components(): sizes.append(comp.size())
			sizes.sort(); sizes.reverse()
			rows.append([broke, sizes.size(), sizes.slice(0, 4), int(lat.steps)])
		rule_rows[g] = rows
		if str(rows) != str(PREDICTED[g]): rule_ok = false
	checks.append({"check": "the rule alone: six blows on each of five grains break exactly what the bench predicted (bonds, pieces, largest pieces, steps)", "ok": rule_ok,
		"read": rule_rows if not rule_ok else {"even": rule_rows["even"]}})

	var key := str(floor) + "/" + ID
	for i in 1500:
		if game.building.content.exhibits.has(key): break
		await physics_frame
	var mount: Node3D = game.building.content.exhibits.get(key)
	var work: Node3D = null
	if mount != null:
		for i in 900:
			for n in mount.find_children("*", "Node3D", true, false):
				if n.has_method("piece_rows"): work = n; break
			if work != null: break
			await physics_frame
	checks.append({"check": "the floor holds a kit pool whose activity is the fracture automaton", "ok": work != null})
	if work != null:
		for i in 240: await physics_frame
		level = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var body: CharacterBody3D = game.body
		for layer in root.find_children("*", "CanvasLayer", true, false):
			if layer.get_viewport() == root: layer.hide()
		var cam := Camera3D.new()
		cam.fov = 80
		root.add_child(cam)
		var hall := mount.global_position
		var middle: Vector3 = work.block_centre()
		work.apply_grid_config({"always": true, "cycle": false, "loudness_db": -50.0, "grain": "even", "preblows": 0, "exploded": 0.0})
		for i in 60: await physics_frame
		game.place_player(Vector3(3.0, level + 0.3, 8.6))
		for i in 30: await physics_frame
		var began: Dictionary = work.state()
		var first_rows: Array = work.piece_rows()
		checks.append({"check": "the block stands whole on the pool floor: one piece of 720 cells, at rest", "ok": int(began.pieces) == 1 and first_rows.size() == 1 and int(first_rows[0].cells) == 720 and float(first_rows[0].moved_m) < 0.02 and absf(middle.y - level - 1.25) < 0.2,
			"state": began, "centre_above_floor_m": snappedf(middle.y - level, .01)})
		await _shot(cam, Vector3(0, level + 1.6, 7.8), Vector3(hall.x, level + 1.3, 0.5), folder.path_join("arrival.png"))
		await _shot(cam, Vector3(hall.x + 1.8, level + 2.7, 5.2), middle + Vector3(0, -0.1, 0.2), folder.path_join("whole.png"))
		await _shot(cam, Vector3(hall.x + 1.0, level + 1.6, 8.8), Vector3(hall.x + 1.0, level + 1.8, 6.3), folder.path_join("board.png"))

		# 2 the first stone, live
		work.frame_ms()
		work.strike()
		var landed := await _until(work, ["fallen", "rubble"])
		var blow: Dictionary = work.last_blow()
		var after_one: Dictionary = work.state()
		var want: Array = PREDICTED["even"][0]
		checks.append({"check": "the first stone lands on lattice point (9, 7, 5), loads twelve bonds and breaks exactly what the bench says", "ok": landed and bool(blow.get("hit", false)) and blow.get("vertex", []) == [9, 7, 5] and int(blow.get("loaded", 0)) == 12
			and int(blow.get("broke", -1)) == int(want[0]) and int(after_one.pieces) + int(after_one.dust) == int(want[1]) and int(after_one.steps) == int(want[3]),
			"blow": blow, "state": after_one, "bench": want})
		var parts: Dictionary = work.partition()
		var partitions := [parts]
		for i in 50: await physics_frame
		await _shot(cam, Vector3(hall.x + 1.8, level + 2.7, 5.2), middle + Vector3(0, -0.1, 0.2), folder.path_join("blow_1.png"))

		# 3 five more stones
		var broken_run := [int(after_one.broken)]
		var all_landed := landed
		for n in 5:
			work.strike()
			if not await _until(work, ["throw", "cracking"], 200): all_landed = false
			if not await _until(work, ["fallen", "rubble"]): all_landed = false
			partitions.append(work.partition())
			broken_run.append(int(work.state().broken))
			for i in 110: await physics_frame
		var good_parts := partitions.all(func(p): return int(p.cells) == 720 and int(p.torn) == 0 and int(p.joined_across) == 0)
		checks.append({"check": "after every blow the bodies are the partition of the cells by the unbroken bonds: 720 cells, no torn piece, no unbroken bond across two pieces", "ok": good_parts and partitions.size() == 6, "after_each_blow": partitions})
		var rising := true
		for i in range(1, broken_run.size()):
			if broken_run[i] < broken_run[i - 1]: rising = false
		for i in 240: await physics_frame
		var rubble: Dictionary = work.state()
		var rows: Array = work.piece_rows()
		var moved := 0
		var outside := 0
		var furthest := 0.0
		for r in rows:
			if float(r.moved_m) > 0.3: moved += 1
			furthest = maxf(furthest, float(r.moved_m))
			var at: Vector3 = r.at
			if absf(at.x) > 3.05 or absf(at.z) > 3.05 or at.y < -0.4: outside += 1
		checks.append({"check": "six stones have landed, the breaking only grows, pieces have come away, and none has left the pool", "ok": all_landed and str(rubble.phase) == "rubble" and int(rubble.blows) == 6 and rising and moved >= 4 and outside == 0,
			"state": rubble, "bonds_broken_after_each": broken_run, "pieces_moved_over_30_cm": moved, "furthest_m": snappedf(furthest, .01), "pieces_outside_the_pool": outside})
		var cost: Dictionary = work.frame_ms()
		await _shot(cam, Vector3(hall.x + 1.8, level + 2.7, 5.2), middle + Vector3(0, -0.5, 0.4), folder.path_join("rubble.png"))
		await _shot(cam, Vector3(hall.x, level + 5.2, 3.6), Vector3(hall.x, level + 0.2, -0.3), folder.path_join("above.png"))
		await _shot(cam, Vector3(hall.x - 2.6, level + 1.5, 2.6), middle + Vector3(0.3, -0.6, 0.3), folder.path_join("in_the_pool.png"))

		# 4 mending
		work.next_grain()
		var mending := await _until(work, ["mending"], 120)
		for i in 70: await physics_frame
		await _shot(cam, Vector3(hall.x + 1.8, level + 2.7, 5.2), middle + Vector3(0, -0.1, 0.2), folder.path_join("mending.png"))
		var whole := await _until(work, ["whole"], 600)
		for i in 40: await physics_frame
		var mended: Dictionary = work.state()
		var mended_rows: Array = work.piece_rows()
		checks.append({"check": "the pieces go back: one whole block of 720 cells, no bond broken, and the next grain", "ok": mending and whole and int(mended.pieces) == 1 and int(mended.broken) == 0 and int(mended.dust) == 0 and str(mended.grain) == "layered"
			and mended_rows.size() == 1 and int(mended_rows[0].cells) == 720 and float(mended_rows[0].moved_m) < 0.02, "state": mended})
		await _shot(cam, Vector3(hall.x + 1.8, level + 2.7, 5.2), middle + Vector3(0, -0.1, 0.2), folder.path_join("mended.png"))

		# 5 the body: the ramp, the deck, the post, the pool
		var post: Vector3 = work.post_point(0)
		game.place_player(Vector3(hall.x - 5.9, level + 0.3, 7.9))      # west of the tower column that stands south of the ramp's foot
		for i in 40: await physics_frame
		await _go(body, Vector3(hall.x - 5.9, level, 5.0))
		var blows_before: int = int(work.state().blows)
		var landing := await _go(body, Vector3(hall.x - 0.2, level, 5.0), 900)
		var deck_feet: float = body.global_position.y - level
		var no_stone_yet: bool = int(work.state().blows) == blows_before and str(work.state().phase) == "whole"
		var at_post := await _go(body, post + Vector3(-0.45, 0, 0), 500)
		var thrown := await _until(work, ["throw", "cracking", "fallen"], 200)
		await _until(work, ["fallen"], 600)
		checks.append({"check": "a body climbs the kit's ramp to the deck, walks up to the STRIKE post, and a stone is thrown", "ok": landing < 0.4 and absf(deck_feet - 1.0) < 0.25 and no_stone_yet and at_post < 0.5 and thrown and int(work.state().blows) == blows_before + 1,
			"reached_the_landing_within_m": snappedf(landing, .01), "feet_on_the_deck_m": snappedf(deck_feet, .01), "blows": int(work.state().blows), "floor": int(game.checkpoint)})
		await _go(body, Vector3(hall.x, level, 5.0), 400)
		var down := await _go(body, Vector3(hall.x, level, 0.9), 900)
		var pool_feet: float = body.global_position.y - level
		checks.append({"check": "the body walks down the pool's own ramp to the block's face", "ok": down < 0.5 and pool_feet < 0.35 and pool_feet > -0.2, "reached_within_m": snappedf(down, .01), "feet_m": snappedf(pool_feet, .01)})
		await _shot(cam, body.global_position + Vector3(0.2, 1.6, 0.4), middle + Vector3(0, 0.2, 0), folder.path_join("at_the_face.png"))
		game.place_player(Vector3(3.0, level + 0.3, 8.6))
		for i in 30: await physics_frame

		# 6 six blows by the rule alone on every grain, the pieces held apart: the stills, and the counts
		var stills := {}
		var stills_ok := true
		for g: String in PREDICTED:
			work.apply_grid_config({"grain": g, "preblows": 6, "exploded": 0.5})
			for i in 20: await physics_frame
			var st: Dictionary = work.state()
			var total := 0
			for row in PREDICTED[g]: total += int(row[0])
			var pieces: int = int(st.pieces) + int(st.dust)
			stills[g] = {"pieces": pieces, "bodies": int(st.pieces), "bonds_broken": int(st.broken), "bench": [int(PREDICTED[g][5][1]), total]}
			if pieces != int(PREDICTED[g][5][1]) or int(st.broken) != total: stills_ok = false
			await _shot(cam, Vector3(hall.x + 3.3, level + 3.3, 4.9), middle + Vector3(0, 0.0, 0.1), folder.path_join("still_%s.png" % g))
		checks.append({"check": "the work's own block after six blows by the rule alone has the bench's pieces and broken bonds, for every grain", "ok": stills_ok, "grains": stills})
		checks.append({"check": "a physics tick costs under 0.5 ms on average through six blows; the worst tick is reported", "ok": float(cost.mean) < 0.5, "mean_ms": snappedf(float(cost.mean), .001), "worst_ms": snappedf(float(cost.worst), .01)})
		work.apply_grid_config({"grain": "even", "preblows": 0, "exploded": 0.0, "always": false, "cycle": true, "loudness_db": -14.0})
		result["passed"] = checks.all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("fracture.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[fracture_automaton_break] ", "PASSED" if result.passed else "FAILED")
	quit()
