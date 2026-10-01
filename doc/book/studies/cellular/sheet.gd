extends "res://supplied/sheet_tools.gd"
## The sheet of Rules in time. It needs a window, so run it WITHOUT --headless,
## from this folder:
##   godot --path . --xr-mode off --script res://sheet.gd
## It writes
##   sheet.png    the argument: rule 30, 90, 110 and 250 from one live cell,
##                each alone in the studio, from 9 m above and from 6.5 m in front
##   process.png  the strip: one still after each operation of the lesson
##   pool.png     the diffusing floor after 0, 100, 300 and 1000 steps
##   sheet.json   every pair of rules measured (stills, cells and answers), what
##                each rule's body is made of, what the choice at the ends
##                changes (and whether it or a longer floor changes the closest
##                pair), and how much each step of the strip changed
## and the single stills, in stills/.

const Automaton := preload("res://cellular.gd")
const Pool := preload("res://diffusion.gd")
const RULES := [30, 90, 110, 250]     # the axis
const VIEWS := ["above", "level"]
const DISTANCE := {"above": 9.0, "level": 6.5}   # metres from the eye to the body's middle
const FROM := Vector3(4.6, 3.8, 6.8)  # the strip's one standpoint
const AT := Vector3(0.0, 1.0, 0.0)

func run() -> void:
	await sheet()
	await ends()
	await other_floors()
	await process_strip()
	await pool_strip()

## One automaton with every row laid, its middle row over the studio's middle.
func automaton(rule: int, ring := true, pace := 0.0) -> Node3D:
	var body := Node3D.new()
	body.set_script(Automaton)
	body.rule = rule
	body.ring = ring
	body.pace = pace
	body.position = Vector3(0.0, 0.0, 2.0)
	return body

## What a body meets: the rows of an automaton read back from its colliders.
func rows_of(body: Node3D) -> Array:
	var out := []
	for row in body.get_children():
		var cells := PackedByteArray()
		cells.resize(body.n)
		for part in row.get_children():
			if part is CollisionShape3D:
				var length := roundi(part.shape.size.x / body.cell)
				var first := roundi((part.position.x - part.shape.size.x / 2.0) / body.cell + body.n / 2.0)
				for i in range(first, first + length):
					cells[i] = 1
		out.append(cells)
	return out

## What the eye gets and what a body meets, counted: tiles and colliders.
func census(body: Node3D) -> Dictionary:
	var tiles := 0
	var colliders := 0
	for row in body.get_children():
		for part in row.get_children():
			if part is MultiMeshInstance3D:
				tiles += part.multimesh.instance_count
			elif part is CollisionShape3D:
				colliders += 1
	return {"rows": body.get_child_count(), "tiles": tiles, "colliders": colliders}

func as_text(rows: Array) -> Array:
	var out := []
	for cells: PackedByteArray in rows:
		var line := ""
		for value in cells:
			line += "#" if value == 1 else "."
		out.append(line)
	return out

func cells_that_differ(a: Array, b: Array) -> int:
	var count := 0
	for t in a.size():
		for i in a[t].size():
			if a[t][i] != b[t][i]:
				count += 1
	return count

## The eight answers of a rule, for the neighbourhoods 0 (000) to 7 (111).
func answers(rule: int) -> Array:
	var out := []
	for index in 8:
		out.append((rule >> index) & 1)
	return out

## The argument's sheet: every rule from two standpoints, every pair measured.
func sheet() -> void:
	var tiles: Array[Image] = []
	var names := []
	var histories := {}
	report["rules"] = {}
	for rule: int in RULES:
		names.append("rule %d" % rule)
	for view: String in VIEWS:
		var stills := []
		var pixels := []
		for rule: int in RULES:
			var body := automaton(rule)
			await stand(body)
			look(view, DISTANCE[view], Vector3(0.0, 0.8, 0.0))
			var taken: Array = await portrait(body, "rule_%d_%s" % [rule, view])
			stills.append(taken[0])
			pixels.append(taken[1])
			tiles.append(small(taken[0]))
			if view == "above":
				var rows := rows_of(body)
				histories[rule] = rows
				var record := census(body)
				var unlike := 0
				var left := 0
				var right := 0
				for cells: PackedByteArray in rows:
					for i in cells.size():
						if cells[i] != cells[cells.size() - 1 - i]:
							unlike += 1
						if cells[i] == 1 and i < cells.size() / 2:
							left += 1
						elif cells[i] == 1 and i > cells.size() / 2:
							right += 1
				record["answers_for_000_to_111"] = answers(rule)
				record["cells_unlike_their_mirror"] = unlike
				record["tiles_left_of_the_middle"] = left
				record["tiles_right_of_the_middle"] = right
				record["rows_first_to_last"] = as_text(rows)
				report["rules"][str(rule)] = record
				print("rule %d: %d tiles, %d colliders, %d cells unlike their mirror, %d left and %d right of the middle" % [rule, record["tiles"], record["colliders"], unlike, left, right])
			report["rules"][str(rule)]["covers_pct_" + view] = share(taken[1])
		report["pairs_" + view] = compare_all(names, stills, pixels)
	var cells := {}
	for i in RULES.size():
		for j in range(i + 1, RULES.size()):
			var differ := cells_that_differ(histories[RULES[i]], histories[RULES[j]])
			var a := answers(RULES[i])
			var b := answers(RULES[j])
			var bits := 0
			for k in 8:
				if a[k] != b[k]:
					bits += 1
			cells["rule %d vs rule %d" % [RULES[i], RULES[j]]] = {"cells_that_differ": differ, "of_cells": 17 * 11, "answers_that_differ_of_8": bits}
			print("rule %d vs rule %d: %d of 187 cells differ, %d of 8 answers differ" % [RULES[i], RULES[j], differ, bits])
	report["pairs_cells"] = cells
	report["sheet_png"] = await compose(tiles, RULES.size(), names, "res://sheet.png")

## The choice at the ends: each rule as a ring and with dead ends, from above.
func ends() -> void:
	var record := {}
	for rule: int in RULES:
		var ring := automaton(rule, true)
		await stand(ring)
		look("above", 9.0, Vector3(0.0, 0.8, 0.0))
		var ring_rows := rows_of(ring)
		var ring_still := await shot("")
		var dead := automaton(rule, false)
		await stand(dead)
		look("above", 9.0, Vector3(0.0, 0.8, 0.0))
		var dead_rows := rows_of(dead)
		var dead_still := await shot("rule_%d_dead_ends" % rule)
		var first := -1
		for t in ring_rows.size():
			if first < 0 and ring_rows[t] != dead_rows[t]:
				first = t
		record[str(rule)] = {
			"cells_that_differ": cells_that_differ(ring_rows, dead_rows), "first_row_that_differs": first,
			"stills_differ_pct": differ_pct(ring_still, dead_still), "tiles_with_dead_ends": census(dead)["tiles"],
			"rows_with_dead_ends": as_text(dead_rows),
		}
		print("rule %d, a ring against dead ends: %d cells differ, from row %d; the stills differ on %.2f%%" % [rule, record[str(rule)]["cells_that_differ"], first, record[str(rule)]["stills_differ_pct"]])
	report["ends"] = record

## Another cause for the closest pair: the ring, or the floor's size. The four
## rules again with dead ends, and on a floor of 33 cells and 17 rows; counted
## from the colliders, not photographed.
func other_floors() -> void:
	var record := {}
	for floor: Array in [["dead ends, 17 cells, 11 rows", false, 17, 11], ["a ring, 33 cells, 17 rows", true, 33, 17]]:
		var histories := {}
		for rule: int in RULES:
			var body := automaton(rule, floor[1])
			body.n = floor[2]
			body.rows = floor[3]
			await stand(body)
			histories[rule] = rows_of(body)
		var pairs := {}
		var closest := ""
		for i in RULES.size():
			for j in range(i + 1, RULES.size()):
				var key := "rule %d vs rule %d" % [RULES[i], RULES[j]]
				pairs[key] = cells_that_differ(histories[RULES[i]], histories[RULES[j]])
				if closest == "" or pairs[key] < pairs[closest]:
					closest = key
		record[floor[0]] = {"cells": floor[2] * floor[3], "cells_that_differ": pairs, "closest": closest}
		print("%s: the closest pair is %s, %d of %d cells; all pairs %s" % [floor[0], closest, pairs[closest], floor[2] * floor[3], pairs])
	report["other_floors"] = record

func flatten(body: Node3D) -> void:
	for row: Node3D in body.get_children():
		row.position.y = 0.0

func strip_colliders(body: Node3D) -> void:
	for row in body.get_children():
		for part in row.get_children():
			if part is CollisionShape3D:
				part.free()

## The process strip: one still after each operation, from one standpoint.
func process_strip() -> void:
	var names := ["1 one row", "2 the rule, one buffer", "3 two buffers, swapped", "4 each row a step up", "5 a collider for each row", "6 a walker on the rows", "7 the same step, diffusing"]
	var tiles: Array[Image] = []
	var counts := []
	# 1: the seed alone
	var body := automaton(90)
	body.rows = 1
	await stand(body)
	strip_colliders(body)
	look_from(FROM, AT)
	counts.append(census(body))
	tiles.append(small(await shot("strip_1")))
	# 2: the lesson's first step(): it reads and writes one buffer. Here the two
	# names are given one buffer, which is the same fault.
	body = automaton(90, true, 1000.0)
	await stand(body)
	body.next = body.now
	for i in 10:
		body.step()
		body.lay_row()
	report["one_buffer_rows"] = as_text(rows_of(body))
	strip_colliders(body)
	flatten(body)
	look_from(FROM, AT)
	counts.append(census(body))
	tiles.append(small(await shot("strip_2")))
	# 3: two buffers, the rows still on the ground
	body = automaton(90)
	await stand(body)
	strip_colliders(body)
	flatten(body)
	look_from(FROM, AT)
	counts.append(census(body))
	tiles.append(small(await shot("strip_3")))
	# 4: each row a step higher, and no collider yet
	body = automaton(90)
	await stand(body)
	strip_colliders(body)
	look_from(FROM, AT)
	counts.append(census(body))
	tiles.append(small(await shot("strip_4")))
	# 5: the finished body
	body = automaton(90)
	await stand(body)
	look_from(FROM, AT)
	counts.append(census(body))
	tiles.append(small(await shot("strip_5")))
	# 6: a walker goes up the left edge
	var group := Node3D.new()
	body = automaton(90)
	group.add_child(body)
	var walker: CharacterBody3D = load("res://supplied/walker.tscn").instantiate()
	walker.position = Vector3(-1.2, 0.0, 2.2)
	group.add_child(walker)
	await stand(group, false)
	look_from(FROM, AT)
	var route := [Vector3(0.0, 0.0, 2.45)]   # in front of the seed first: it steps up from straight ahead
	for t in 9:
		route.append(Vector3(-t * 0.4, 0.0, 2.0 - t * 0.4))
	walker.walk_to(route)
	while walker.walking:
		await physics_frame
	for i in 10:
		await physics_frame
	report["strip_walker"] = {"walk_ended": walker.ended, "feet_at_m": snappedf(walker.global_position.y, 0.01)}
	print("strip: the walker %s, its feet at %.2f m" % [walker.ended, walker.global_position.y])
	counts.append(census(body))
	tiles.append(small(await shot("strip_6")))
	# 7: the other rule on the same step
	var pool := Node3D.new()
	pool.set_script(Pool)
	pool.pace = 0
	await stand(pool)
	for i in 1000:
		pool.step()
	pool.show_b()
	look_from(FROM, AT)
	counts.append({"rows": 0, "tiles": 0, "colliders": 1})
	tiles.append(small(await shot("strip_7")))
	report["strip"] = await strip(tiles, names)
	report["strip"]["counts"] = counts

## The diffusing floor at four moments, from one standpoint.
func pool_strip() -> void:
	var stops := [0, 100, 300, 1000]
	var names := []
	var tiles: Array[Image] = []
	var record := []
	var pool := Node3D.new()
	pool.set_script(Pool)
	pool.pace = 0
	await stand(pool)
	look_from(Vector3(0.0, 3.2, 3.4), Vector3(0.0, 0.0, 0.1))
	for stop: int in stops:
		while pool.steps < stop:
			pool.step()
		pool.show_b()
		var most := 0.0
		var shown := 0
		for value in pool.b:
			most = maxf(most, value)
			if value >= 0.1:
				shown += 1
		names.append("after %d steps" % stop)
		tiles.append(small(await shot("pool_%d" % stop)))
		record.append({"steps": stop, "most_b": snappedf(most, 0.001), "cells_shown": shown, "highest_m": snappedf(most * pool.high, 0.01)})
		print("pool after %d steps: the most B in a cell is %.3f, %d of %d cells are shown, the highest stands %.2f m" % [stop, most, shown, pool.b.size(), most * pool.high])
	report["pool"] = record
	report["pool_png"] = await compose(tiles, stops.size(), names, "res://pool.png")
