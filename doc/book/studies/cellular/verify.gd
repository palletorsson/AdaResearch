extends "res://supplied/verify_tools.gd"
## Headless checks of Rules in time. From this folder:
##   godot --headless --path . --xr-mode off --script res://verify.gd
## Writes verification.json beside this file; the exit code is the number of
## checks that failed. No import step is needed: nothing here has a class_name.
## Add --fixed-fps 60 and it takes a few seconds instead of about a minute,
## with the same result. Headless draws no frames: what the eye gets is
## measured by sheet.gd.

const CheckGuest := preload("res://supplied/check_guest.gd")
const RULES := [30, 90, 110, 250]
const N := 17
const ROWS := 11
const CELL := 0.4
const RISE := 0.15

## The two scripts of the lesson. They are loaded in run() and not preloaded:
## a preloaded script that does not parse stops verify.gd before its first check.
var automaton_script: GDScript
var pool_script: GDScript

func run() -> void:
	project()
	if not the_scripts():
		return
	await the_rule()
	await the_ends()
	await a_saved_value()
	await one_buffer()
	await rows_in_time()
	await a_body()
	await walks()
	await the_pool()
	await the_pool_carries()
	await the_guest()
	await scenes_run()

## ---------------------------------------------------------------- helpers

func world() -> Node3D:
	var base: Node3D = load("res://supplied/base.tscn").instantiate()
	root.add_child(base)
	await frames(2)
	return base

func close(node: Node) -> void:
	node.free()
	await frames(1)

func automaton(rule: int, ring := true, pace := 0.0) -> Node3D:
	var body := Node3D.new()
	body.set_script(automaton_script)
	body.rule = rule
	body.ring = ring
	body.pace = pace
	return body

## The same rule written another way, to check the kit's against: the answers
## are looked up in a list, and the ends are handled by hand.
func expected(rule: int, ring: bool, one_buffer := false) -> Array:
	var answer := []
	for index in 8:
		answer.append(1 if (rule & (1 << index)) != 0 else 0)
	var row := []
	for i in N:
		row.append(1 if i == 8 else 0)
	var out := [row.duplicate()]
	for t in ROWS - 1:
		var fresh := row.duplicate()
		var read: Array = fresh if one_buffer else row
		for i in N:
			var left: int = read[i - 1] if i > 0 else (read[N - 1] if ring else 0)
			var right: int = read[i + 1] if i < N - 1 else (read[0] if ring else 0)
			fresh[i] = answer[left * 4 + read[i] * 2 + right]
		row = fresh
		out.append(row.duplicate())
	return out

## The rows a body printed since line `from` of the output: "3 [0, 1, ...]".
func printed_rows(from: int) -> Array:
	var out := []
	var lines := printed
	for k in range(from, lines.size()):
		var line: String = lines[k]
		var open := line.find("[")
		if open < 1 or not line.ends_with("]") or not line.substr(0, open).strip_edges().is_valid_int():
			continue
		var row := []
		for word in line.substr(open + 1, line.length() - open - 2).split(","):
			row.append(int(word))
		out.append(row)
	return out

## The rows as a body meets them: read back from the colliders.
func collider_rows(body: Node3D) -> Array:
	var out := []
	for row in body.get_children():
		var cells := []
		cells.resize(body.n)
		cells.fill(0)
		for part in row.get_children():
			if part is CollisionShape3D:
				var length := roundi(part.shape.size.x / body.cell)
				var first := roundi((part.position.x - part.shape.size.x / 2.0) / body.cell + body.n / 2.0)
				for i in range(first, first + length):
					cells[i] = 1
		out.append(cells)
	return out

func census(body: Node3D) -> Dictionary:
	var tiles := 0
	var colliders := 0
	var bodies := 0
	for row in body.get_children():
		if row is StaticBody3D:
			bodies += 1
		for part in row.get_children():
			if part is MultiMeshInstance3D:
				tiles += part.multimesh.instance_count
			elif part is CollisionShape3D:
				colliders += 1
	return {"rows": body.get_child_count(), "bodies": bodies, "tiles": tiles, "colliders": colliders}

func live(rows: Array) -> int:
	var count := 0
	for row: Array in rows:
		count += row.count(1)
	return count

func runs(rows: Array) -> int:
	var count := 0
	for row: Array in rows:
		for i in row.size():
			if row[i] == 1 and (i == 0 or row[i - 1] == 0):
				count += 1
	return count

func unlike_mirror(rows: Array) -> int:
	var count := 0
	for row: Array in rows:
		for i in row.size():
			if row[i] != row[row.size() - 1 - i]:
				count += 1
	return count

func cells_that_differ(a: Array, b: Array) -> int:
	var count := 0
	for t in mini(a.size(), b.size()):
		for i in a[t].size():
			if a[t][i] != b[t][i]:
				count += 1
	return count + absi(a.size() - b.size()) * N

func text_of(path: String) -> String:
	return FileAccess.get_file_as_string(path)

## Wait `seconds` of the scene's time, whatever a frame takes.
func seconds(amount: float) -> void:
	var waited := 0.0
	while waited < amount:
		await process_frame
		waited += root.get_process_delta_time()

func scripts_of(folder: String) -> Array:
	var out := []
	for file in DirAccess.get_files_at(folder):
		if file.get_extension() == "gd":
			out.append(folder + file)
	for inner in DirAccess.get_directories_at(folder):
		if not inner.begins_with("."):
			out.append_array(scripts_of(folder + inner + "/"))
	return out

## ---------------------------------------------------------------- the checks

func project() -> void:
	check(ProjectSettings.get_setting("application/config/name") == "Rules in time", "the project is named Rules in time")
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://cellular.tscn" and ResourceLoader.exists("res://cellular.tscn"), "its main scene is cellular.tscn")
	var named := []
	var spaced := []
	for path: String in scripts_of("res://"):
		var text := text_of(path)
		if RegEx.create_from_string("(?m)^\\s*class_name\\s").search(text) != null:
			named.append(path)
		if RegEx.create_from_string("(?m)^ +\\S").search(text) != null:
			spaced.append(path)
	check(named.is_empty(), "no script of the kit declares a class_name: %s" % [named])
	check(spaced.is_empty(), "every script is indented with tabs: %s" % [spaced])
	check(DirAccess.get_files_at("res://supplied/").size() == 15, "supplied/ holds the base's 15 files: %d" % DirAccess.get_files_at("res://supplied/").size())

## A script that does not parse is one failed check here, with Godot's own
## message in it, and the run ends: nothing after this can be measured.
func the_scripts() -> bool:
	var before := errors.size()
	automaton_script = load("res://cellular.gd")
	pool_script = load("res://diffusion.gd")
	var parsed := automaton_script != null and automaton_script.can_instantiate() and pool_script != null and pool_script.can_instantiate()
	check(parsed, "cellular.gd and diffusion.gd parse: %s" % [errors.slice(before)])
	return parsed

func the_rule() -> void:
	var base := await world()
	var answers := []
	for index in 8:
		answers.append((90 >> index) & 1)
	check(answers == [0, 1, 0, 1, 1, 0, 1, 0], "(90 >> index) & 1 gives rule 90's eight answers, for 000 to 111: %s" % [answers])
	measured["rules"] = {}
	for rule: int in RULES:
		var before := printed.size()
		var body := automaton(rule)
		base.add_child(body)
		await frames(2)
		var want := expected(rule, true)
		var said := printed_rows(before)
		var met := collider_rows(body)
		var count := census(body)
		check(said == want, "rule %d: the %d rows it printed are the rule's rows from one live cell" % [rule, said.size()])
		check(met == want, "rule %d: its colliders cover the same cells, row for row" % rule)
		check(count["rows"] == ROWS and count["tiles"] == live(want), "rule %d: %d rows, and one tile for each of the %d live cells: %d" % [rule, count["rows"], live(want), count["tiles"]])
		measured["rules"][str(rule)] = {"tiles": count["tiles"], "colliders": count["colliders"], "cells_unlike_their_mirror": unlike_mirror(said)}
		if rule == 90:
			check(unlike_mirror(said) == 0, "rule 90 from one cell reads the same from either end: %d cells unlike their mirror" % unlike_mirror(said))
			var kept: PackedByteArray = body.now.duplicate()
			body.next[0] = 1 - body.next[0]
			check(body.now == kept, "now and next are two buffers: writing one leaves the other as it was")
			body.next[0] = 1 - body.next[0]
			var index_of_last: int = body.now.size() - 1
			check(body.cell_at(-1) == body.now[index_of_last] and body.cell_at(N) == body.now[0], "as a ring, the cell before the first is the last and the cell after the last is the first")
		if rule == 30:
			var column := []
			for row: Array in said:
				column.append(row[8])
			measured["rule_30_middle_column"] = column
			var again := automaton(30)
			var mark := printed.size()
			base.add_child(again)
			await frames(2)
			check(printed_rows(mark) == said, "rule 30 run twice gives the same rows: nothing in it is drawn by chance")
			again.free()
		body.free()
		await frames(1)
	await close(base)

func the_ends() -> void:
	var base := await world()
	measured["ends"] = {}
	for rule: int in RULES:
		var before := printed.size()
		var body := automaton(rule, false)
		base.add_child(body)
		await frames(2)
		var said := printed_rows(before)
		var differ := cells_that_differ(said, expected(rule, true))
		measured["ends"][str(rule)] = differ
		check(said == expected(rule, false), "rule %d with ring unticked: beyond an end is dead, and %d cells differ from the ring" % [rule, differ])
		if rule == 90:
			check(differ == 6 and said[8] == expected(90, true)[8] and said[9] != expected(90, true)[9], "rule 90: the two floors agree up to row 8 and part at row 9, on 6 cells in all: %d" % differ)
			check(body.cell_at(-1) == 0 and body.cell_at(N) == 0, "with ring unticked, cell_at() answers 0 outside the row")
		body.free()
		await frames(1)
	await close(base)

## A value set in the Inspector is saved in the scene. Here a scene is packed
## in memory, as the editor packs one to save it, with rule 30 on a script
## whose line says 90, and then made again from what was packed.
func a_saved_value() -> void:
	var base := await world()
	var by_hand := automaton(30)
	var saved := PackedScene.new()
	var packed := saved.pack(by_hand)
	by_hand.free()
	var plain := Node3D.new()
	plain.set_script(automaton_script)
	var line: int = plain.rule
	plain.free()
	var before := printed.size()
	var body: Node3D = saved.instantiate()
	base.add_child(body)
	await frames(2)
	var said := printed_rows(before)
	check(packed == OK and line == 90 and body.rule == 30 and said == expected(30, true), "a rule saved in a scene wins over the script's line: the line says %d, the scene 30, and the rows are rule %d's" % [line, body.rule])
	measured["rule_saved_in_a_scene"] = {"script_line": line, "scene": 30, "rows_are_those_of_rule": 30 if said == expected(30, true) else -1}
	# Not measured here: the same with a scene FILE, run once in a scratch copy on
	# 1 October 2026. cellular.tscn had `rule = 30` on Automaton and the script's
	# line said 110; the rows printed were rule 30's, with no error and no warning.
	measured["rule_saved_in_the_scene_file_recorded_by_hand"] = {"script_line": 110, "scene": 30, "rows_are_those_of_rule": 30}
	await close(base)

## The lesson's planted fault: one buffer read and written in the same pass.
func one_buffer() -> void:
	var base := await world()
	var before := printed.size()
	var body := automaton(90, true, 1000.0)
	base.add_child(body)
	await frames(2)
	body.next = body.now      # two names, one buffer
	for i in ROWS - 1:
		body.step()
		body.lay_row()
	var said := printed_rows(before)
	var want := expected(90, true, true)
	check(said == want, "with one buffer for both names, rule 90 gives the rows of a rule that reads its own new cells")
	check(said[1] == [0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], "its second row is ten cells, from one left of the seed to the right end: %s" % [said[1]])
	check(unlike_mirror(said) > 0 and errors.is_empty(), "the floor leans (%d cells unlike their mirror) and Godot logged nothing: %s" % [unlike_mirror(said), errors])
	measured["one_buffer"] = {"cells_unlike_their_mirror": unlike_mirror(said), "tiles": live(said), "tiles_with_two_buffers": live(expected(90, true))}
	await close(base)

func rows_in_time() -> void:
	var scene: Node3D = load("res://cellular.tscn").instantiate()
	root.add_child(scene)
	var body: Node3D = scene.get_node("Automaton")
	await frames(1)
	check(body.made == 1 and body.pace == 0.25, "cellular.tscn starts with one row laid, and a pace of 0.25 s: %d rows" % body.made)
	check(body.rule == 90 and body.ring and body.n == N and body.rows == ROWS and is_equal_approx(body.cell, CELL) and is_equal_approx(body.rise, RISE), "as shipped it is rule 90 on a ring: 17 cells, 11 rows, cells of 0.4 m, a rise of 0.15 m")
	var jumped := false
	var last: int = body.made
	var waited := 0.0
	var at_one_second := -1
	while body.made < ROWS and waited < 6.0:
		await process_frame
		waited += root.get_process_delta_time()
		if body.made - last > 1:
			jumped = true
		last = body.made
		if at_one_second < 0 and waited >= 1.0:
			at_one_second = body.made
	check(body.made == ROWS and not jumped, "the rows arrive one at a time: all %d after %.2f s of the scene's time" % [body.made, waited])
	check(at_one_second >= 3 and at_one_second <= 6, "after one second about five rows are laid: %d" % at_one_second)
	await seconds(1.0)
	check(body.made == ROWS and body.get_child_count() == ROWS, "and then it stops: still %d rows a second later" % body.get_child_count())
	var placed := true
	for t in ROWS:
		var row: Node3D = body.get_child(t)
		if not near(row.position, Vector3(0.0, t * RISE, -t * CELL)):
			placed = false
	check(placed, "row t stands t x 0.15 m up and t x 0.4 m back")
	measured["seconds_to_lay_all_rows"] = snappedf(waited, 0.01)
	await close(scene)

func a_body() -> void:
	var base := await world()
	var body := automaton(90)
	body.position = Vector3(0.0, 0.0, 1.7)
	base.add_child(body)
	await frames(2)
	var count := census(body)
	check(count["bodies"] == ROWS, "each row is one StaticBody3D: %d" % count["bodies"])
	check(count["colliders"] == runs(expected(90, true)) and count["colliders"] == 33 and count["tiles"] == 37, "rule 90: one box for each run of live cells, %d boxes for %d tiles" % [count["colliders"], count["tiles"]])
	var sized := true
	for row in body.get_children():
		for part in row.get_children():
			if part is CollisionShape3D and not (is_equal_approx(part.shape.size.y, RISE) and is_equal_approx(part.shape.size.z, CELL) and is_equal_approx(part.position.y, RISE / 2.0)):
				sized = false
	check(sized, "every box is one cell deep and as thick as a tile")
	var marble: RigidBody3D = load("res://supplied/marble.tscn").instantiate()
	base.add_child(marble)
	marble.drop(Vector3(0.0, 1.2, 1.7))
	var rest := await settle(marble)
	check(absf(rest.y - 0.25) < 0.01, "a marble dropped on the seed rests on it, its middle at 0.25 m: %.3f" % rest.y)
	marble.drop(Vector3(0.0, 2.0, 1.7 - 4 * CELL))
	rest = await settle(marble)
	check(absf(rest.y - 0.10) < 0.01, "dropped over the middle of row 4, where rule 90 has no cell, it falls to the ground: %.3f" % rest.y)
	var checker := automaton(250)
	checker.position = Vector3(0.0, 0.0, 1.7)
	body.free()
	base.add_child(checker)
	await frames(2)
	marble.drop(Vector3(0.0, 2.0, 1.7 - 4 * CELL))
	var on_checker := await settle(marble)
	check(absf(on_checker.y - 0.85) < 0.01, "the same drop on rule 250, which has a cell there: it rests on the tile, its middle at 0.85 m: %.3f" % on_checker.y)
	measured["marble_over_row_4_m"] = {"rule 90": snappedf(rest.y, 0.01), "rule 250": snappedf(on_checker.y, 0.01)}
	await close(base)

## A walker on each rule's floor, straight up the middle; then two other walks.
func walks() -> void:
	measured["walks"] = {}
	for rule: int in RULES:
		var scene: Node3D = load("res://cellular.tscn").instantiate()
		var body: Node3D = scene.get_node("Automaton")
		body.rule = rule
		body.pace = 0.0
		var walker: CharacterBody3D = scene.get_node("Walker")
		walker.position = Vector3(0.0, 0.0, 2.25)   # in front of the seed
		root.add_child(scene)
		await physics_frames(20)
		walker.walk_to([Vector3(0.0, 0.0, 1.7 - (ROWS - 1) * CELL)])
		var highest := 0.0
		while walker.walking:
			await physics_frame
			highest = maxf(highest, walker.global_position.y)
		await frames(2)
		var how: String = walker.ended
		var at := walker.global_position
		var over_row := roundi((1.7 - at.z) / CELL)
		measured["walks"]["rule %d, up the middle" % rule] = {"ended": how, "feet_at_m": snappedf(at.y, 0.01), "over_row": over_row, "highest_m": snappedf(highest, 0.01)}
		if rule == 90 or rule == 250:
			check(how == "blocked" and absf(at.y - RISE) < 0.02 and over_row == 0, "rule %d, up the middle: stopped on the seed, \"%s\", its feet at %.2f m over row %d" % [rule, how, at.y, over_row])
		elif rule == 30:
			check(how == "blocked" and at.y < 0.02 and over_row >= 5 and absf(highest - 6 * RISE) < 0.03, "rule 30, up the middle: it climbed to %.2f m, the top of row 5, fell through to the ground under row %d and was stopped there, \"%s\", its feet at %.2f m" % [highest, over_row, how, at.y])
		else:
			check(how == "arrived" and absf(at.y - ROWS * RISE) < 0.02, "rule 110, up the middle: \"%s\" on the last row, its feet at %.2f m" % [how, at.y])
		await close(scene)
	# The lesson's own way in, by the keys: D to the seed, then W.
	var keyed: Node3D = load("res://cellular.tscn").instantiate()
	keyed.get_node("Automaton").pace = 0.0
	var hand: CharacterBody3D = keyed.get_node("Walker")
	root.add_child(keyed)
	await physics_frames(20)
	var began := hand.global_position
	await hold("move_right", 36)
	var beside := hand.global_position
	await hold("move_forward", 60)
	await physics_frames(10)
	check(near(began, Vector3(-1.2, 0.0, 2.25), 0.01) and absf(beside.x) < 0.05 and absf(hand.global_position.y - RISE) < 0.02, "by the keys, from the front left: D for 36 steps brings it before the seed (x %.2f), then W puts it on the seed and no further: its feet at %.2f m, z %.2f" % [beside.x, hand.global_position.y, hand.global_position.z])
	measured["walks"]["rule 90, by the keys"] = {"feet_at_m": snappedf(hand.global_position.y, 0.01), "z": snappedf(hand.global_position.z, 0.01)}
	await close(keyed)
	# Rule 90 by its left edge: one cell to the left for each row up.
	var edge: Node3D = load("res://cellular.tscn").instantiate()
	edge.get_node("Automaton").pace = 0.0
	var climber: CharacterBody3D = edge.get_node("Walker")
	climber.position = Vector3(0.0, 0.0, 2.25)
	root.add_child(edge)
	await physics_frames(20)
	var route := []
	for t in 9:
		route.append(Vector3(-t * CELL, 0.0, 1.7 - t * CELL))
	var ended := await walk(climber, route)
	check(ended == "arrived" and climber.global_position.y > 9 * RISE - 0.02, "rule 90 by its left edge, a cell to the left for each row: \"%s\" on row 8, its feet at %.2f m" % [ended, climber.global_position.y])
	measured["walks"]["rule 90, the left edge"] = {"ended": ended, "feet_at_m": snappedf(climber.global_position.y, 0.01)}
	await close(edge)
	# The same floor with its colliders taken away: tiles for the eye only.
	var ghost: Node3D = load("res://cellular.tscn").instantiate()
	ghost.get_node("Automaton").pace = 0.0
	var through: CharacterBody3D = ghost.get_node("Walker")
	through.position = Vector3(0.0, 0.0, 2.25)
	root.add_child(ghost)
	await frames(2)
	for row in ghost.get_node("Automaton").get_children():
		for part in row.get_children():
			if part is CollisionShape3D:
				part.free()
	await physics_frames(20)
	ended = await walk(through, [Vector3(0.0, 0.0, 1.7 - (ROWS - 1) * CELL)])
	check(ended == "arrived" and through.global_position.y < 0.02, "rule 90 with its colliders taken away: the walker goes through every tile on the ground, \"%s\", its feet at %.2f m" % [ended, through.global_position.y])
	measured["walks"]["rule 90, no colliders"] = {"ended": ended, "feet_at_m": snappedf(through.global_position.y, 0.01)}
	await close(ghost)

func new_pool() -> Node3D:
	var pool := Node3D.new()
	pool.set_script(pool_script)
	pool.pace = 0
	return pool

func the_pool() -> void:
	var base := await world()
	var pool := new_pool()
	base.add_child(pool)
	await frames(2)
	var cells: int = pool.g * pool.g
	check(pool.a.size() == cells and pool.b.size() == cells and pool.a_next.size() == cells and pool.b_next.size() == cells, "the pool has four buffers of %d numbers" % cells)
	check(pool.a.count(1.0) == cells and pool.b.count(1.0) == 16 and pool.b.count(0.0) == cells - 16, "it starts full of A, with B in 16 cells in the middle")
	check(pool.steps == 0, "with pace 0 it waits: no step taken")
	pool.step()
	var first_most := 0.0
	for value in pool.b:
		first_most = maxf(first_most, value)
	measured["pool_most_b_after_one_step"] = snappedf(first_most, 0.001)
	var kept: PackedFloat32Array = pool.a.duplicate()
	pool.a_next[0] = 5.0
	check(pool.steps == 1 and pool.a == kept, "step() reads a and b and writes a_next and b_next: writing a_next leaves a as it was")
	while pool.steps < 1000:
		pool.step()
	pool.show_b()
	var most := 0.0
	var least := 1.0
	var shown := 0
	var total := 0.0
	for value in pool.b:
		most = maxf(most, value)
		least = minf(least, value)
		total += value
		if value >= 0.1:
			shown += 1
	measured["pool_after_1000_steps"] = {"most_b": snappedf(most, 0.001), "mean_b": snappedf(total / cells, 0.0001), "cells_shown": shown, "highest_m": snappedf(most * pool.high, 0.01)}
	check(absf(most - 0.420) < 0.005 and shown == 360 and least >= 0.0, "after 1000 steps the most B in a cell is %.3f, and %d of %d cells hold a tenth or more" % [most, shown, cells])
	var heights: PackedFloat32Array = pool.ground.map_data
	var fits := heights.size() == cells
	for i in cells:
		var want: float = pool.b[i] * pool.high / pool.cell if pool.b[i] >= 0.1 else 0.0
		if fits and absf(heights[i] - want) > 0.0001:
			fits = false
	check(fits and pool.tiles.instance_count == cells, "show_b() hands the collider one height for each cell: B x 0.6 m, and nothing under a tenth")
	var twin := new_pool()
	base.add_child(twin)
	await frames(2)
	for i in 1000:
		twin.step()
	check(twin.b == pool.b, "a second pool, 1000 steps on, holds the same numbers: nothing in it is drawn by chance")
	await close(base)

func the_pool_carries() -> void:
	var scene: Node3D = load("res://diffusion.tscn").instantiate()
	root.add_child(scene)
	var pool: Node3D = scene.get_node("Pool")
	var walker: CharacterBody3D = scene.get_node("Walker")
	var start := walker.global_position
	var top := [start.y]     # the highest the walker's feet were, read at every physics step
	var watch := func() -> void: top[0] = maxf(top[0], walker.global_position.y)
	physics_frame.connect(watch)
	var waited := 0
	while pool.steps < 600 and waited < 4000:    # the pool steps in _process, so its steps are counted there
		await process_frame
		waited += 1
	pool.pace = 0
	physics_frame.disconnect(watch)
	var highest: float = top[0]
	var after := walker.global_position
	measured["standing_on_the_pool"] = {"feet_at_start_m": snappedf(start.y, 0.01), "highest_m": snappedf(highest, 0.01), "feet_after_600_steps_m": snappedf(after.y, 0.01), "moved_sideways_m": snappedf(Vector2(after.x - start.x, after.z - start.z).length(), 0.01)}
	check(is_equal_approx(start.y, 0.6) and after.y < 0.02 and not walker.walking, "a walker standing on the seed, 0.60 m up, is on the ground %d steps later without having walked: its feet at %.2f m, %.2f m at the highest" % [pool.steps, after.y, highest])
	walker.walk_to([Vector3(-2.0, 0.0, 0.0)])
	highest = 0.0
	while walker.walking:
		await physics_frame
		highest = maxf(highest, walker.global_position.y)
	await frames(2)
	measured["walking_out_of_the_pool"] = {"ended": walker.ended, "highest_m": snappedf(highest, 0.01)}
	check(walker.ended == "arrived" and highest > 0.1, "then it walks out over the wall the pool has grown: \"%s\", its feet %.2f m up on the way" % [walker.ended, highest])
	await close(scene)

func the_guest() -> void:
	var folder := "res://guests/cellular/"
	var needs := CheckGuest.outside(folder)
	check(needs.is_empty(), "the guest names nothing outside its folder: %s" % [needs])
	check(CheckGuest.class_names(folder).is_empty(), "the guest declares no class_name")
	var ours := text_of("res://cellular.gd")
	ours = ours.replace("const Look := preload(\"res://supplied/look.gd\")\n", "const BODY := Color(\"c6ff3d\")   # the kit's BODY colour, written out: a guest names nothing outside its folder\n")
	ours = ours.replace("\ttile.material = Look.paint(Look.BODY)\n", "\tvar paint := StandardMaterial3D.new()\n\tpaint.albedo_color = BODY\n\tpaint.roughness = 0.8\n\ttile.material = paint\n")
	check(ours == text_of(folder + "cellular.gd"), "the guest's script is cellular.gd with its one colour written out, and nothing else changed")
	var base := await world()
	var guest: Node3D = load(folder + "cellular.tscn").instantiate()
	var body: Node3D = guest.get_node("Automaton")
	check(body.rule == 90 and body.rows == 17 and is_equal_approx(body.cell, 0.09) and is_equal_approx(body.pace, 0.8), "the guest is rule 90, 17 rows of cells 0.09 m wide, a row every 0.8 s")
	base.add_child(guest)
	await frames(2)
	check(body.made == 1, "in the room it starts with one row: %d" % body.made)
	await seconds(2.0)
	check(body.made >= 3 and body.made <= 4, "and grows over time: %d rows after two seconds" % body.made)
	guest.free()
	guest = load(folder + "cellular.tscn").instantiate()
	body = guest.get_node("Automaton")
	body.pace = 0.0
	base.add_child(guest)
	await frames(2)
	var low := Vector3(INF, INF, INF)
	var high := Vector3(-INF, -INF, -INF)
	for row: Node3D in body.get_children():
		for part in row.get_children():
			if part is CollisionShape3D:
				var middle: Vector3 = guest.to_local(part.global_position)
				low = low.min(middle - part.shape.size / 2.0)
				high = high.max(middle + part.shape.size / 2.0)
	measured["guest_box_m"] = [snappedf(high.x - low.x, 0.01), snappedf(high.y - low.y, 0.01), snappedf(high.z - low.z, 0.01)]
	check(low.x >= -0.8 and high.x <= 0.8 and low.z >= -0.8 and high.z <= 0.8 and absf(low.y) < 0.001, "full grown it stands on the ground and fits the place: %.2f m wide, %.2f m deep, %.2f m high" % [high.x - low.x, high.z - low.z, high.y - low.y])
	var walker: CharacterBody3D = load("res://supplied/walker.tscn").instantiate()
	walker.position = Vector3(0.0, 0.0, 2.0)
	base.add_child(walker)
	await physics_frames(20)
	var how := await walk(walker, [Vector3.ZERO])
	measured["walker_at_the_guest"] = {"ended": how, "feet_at_m": snappedf(walker.global_position.y, 0.01)}
	check(how == "arrived" or how == "blocked", "a walker sent to its middle: \"%s\", its feet at %.2f m" % [how, walker.global_position.y])
	# Not measured here: the room's own trial of this guest, run once in a scratch
	# copy of my-room on 1 October 2026 (guest_trial.gd, 8 checks of 8), written
	# down so that the numbers the lesson quotes are on record beside the others.
	measured["room_trial_recorded_by_hand"] = {
		"rule 90": {"place": 2, "walk_ended": "arrived", "metres_from_the_middle_of_the_place": 0.08, "feet_at_m": 0.32},
		"rule 30": {"place": 2, "walk_ended": "arrived", "metres_from_the_middle_of_the_place": 0.08, "feet_at_m": 0.32},
	}
	await close(base)

func scenes_run() -> void:
	for path: String in ["res://cellular.tscn", "res://diffusion.tscn"]:
		var before := errors.size()
		var scene: Node = load(path).instantiate()
		root.add_child(scene)
		await frames(180)
		check(errors.size() == before, "%s ran 180 frames and Godot logged no error: %s" % [path.get_file(), errors.slice(before)])
		await close(scene)
	check(errors.is_empty() and warnings.is_empty(), "the whole run logged no error and no warning: %s %s" % [errors, warnings])
