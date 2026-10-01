extends "res://supplied/sheet_tools.gd"
## The stills and the measures of Bodies that learn. It needs a window:
##   godot --path . --xr-mode off --script res://sheet.gd
## It writes sheet.png (who labelled: four fields by the neighbours' vote and the
## same four by a line), k.png (one person's field as k grows), process.png (the
## strip), sheet.json (every number the lesson quotes that is not in
## verification.json) and the single stills in stills/. Every still is made in
## the plain studio of sheet_tools.gd, not in the running scene.

const NAMES := ["one person", "the class", "a default dataset", "random labels"]
const ABOVE := 8.6        # metres: the eye over the middle of the floor
const LONE := 7           # the builder's sample 7: one "stay" alone at the right edge

var learner: GDScript

func run() -> void:
	learner = load("res://learning_body.gd")
	await who_labelled()
	await a_line()
	await as_k_grows()
	await the_tests()
	await pairs_as_k_grows()
	await the_fault()
	await the_error()
	await the_strip()

## ---------------------------------------------------------------- helpers

func field(labelled_by: int, k := 3, rule := 0, code: GDScript = null) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	body.set_script(code if code != null else learner)
	body.labelled_by = labelled_by
	body.k = k
	body.rule = rule
	body.save_file = "user://no_such_file.json"   # the kit's own samples, whatever the learner has saved
	body.position.y = 0.005
	return body

## What the field says of each of its 640 cells, row after row: [label, share].
func cells(body: Node) -> Array:
	var out := []
	for cz in 20:
		for cx in 32:
			out.append(body.says((cx + 0.5) * 0.25 - 4.0, (cz + 0.5) * 0.25 - 2.5))
	return out

## How many pairs of neighbouring cells carry two labels: the length of the boundary, in cell sides.
func edges(said: Array) -> int:
	var count := 0
	for cz in 20:
		for cx in 32:
			if cx < 31 and said[cz * 32 + cx][0] != said[cz * 32 + cx + 1][0]:
				count += 1
			if cz < 19 and said[cz * 32 + cx][0] != said[(cz + 1) * 32 + cx][0]:
				count += 1
	return count

## The cells joined to cell `start` by sides, all of its label.
func region(said: Array, start: int) -> Array:
	var seen := {start: true}
	var stack := [start]
	while not stack.is_empty():
		var i: int = stack.pop_back()
		for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var cx := i % 32 + step.x
			var cz := i / 32 + step.y
			if cx < 0 or cx > 31 or cz < 0 or cz > 19:
				continue
			var j := cz * 32 + cx
			if not seen.has(j) and said[j][0] == said[i][0]:
				seen[j] = true
				stack.append(j)
	return seen.keys()

func regions(said: Array) -> int:
	var seen := {}
	var count := 0
	for start in 640:
		if not seen.has(start):
			count += 1
			for i: int in region(said, start):
				seen[i] = true
	return count

## Each sample asked of a field of neighbours that never saw it.
func left_out_wrong(body: Node) -> int:
	var all: Array = body.chosen.duplicate()
	var count := 0
	for i in all.size():
		var rest := all.duplicate()
		rest.remove_at(i)
		body.chosen = rest
		if body.neighbours_say(all[i].x, all[i].z)[0] != all[i].label:
			count += 1
	body.chosen = all
	return count

func counts(body: Node) -> Dictionary:
	var said := cells(body)
	var stay := 0
	var sure := 0
	var mean := 0.0
	for one: Array in said:
		if one[0] == "stay":
			stay += 1
		if one[1] > 0.99:
			sure += 1
		mean += one[1]
	return {
		"cells_stay": stay, "cells_sure": sure, "mean_sure": snappedf(mean / 640.0, 0.001),
		"boundary_cell_sides": edges(said), "regions": regions(said),
		"wrong_about_its_own": body.wrong(), "samples": body.chosen.size(),
	}

func cells_differ(a: Array, b: Array) -> int:
	var count := 0
	for i in 640:
		if a[i][0] != b[i][0]:
			count += 1
	return count

func from_above(body: Node3D, name: String) -> Array:
	await stand(body)
	look("above", ABOVE, Vector3.ZERO)
	return await portrait(body, name)

## ---------------------------------------------------------------- the argument

var tiles: Array[Image] = []
var captions := []

func who_labelled() -> void:
	var stills := []
	var pixels := []
	var said := []
	var values := {}
	for who in 4:
		var body := field(who)
		var got := await from_above(body, "who_%d" % who)
		stills.append(got[0])
		pixels.append(got[1])
		said.append(cells(body))
		values[NAMES[who]] = counts(body)
		values[NAMES[who]]["left_out_wrong"] = left_out_wrong(body)
		values[NAMES[who]]["field_covers_pct"] = share(got[1])
		tiles.append(small(got[0]))
		captions.append("%s: 3 neighbours" % NAMES[who])
		print(NAMES[who], ": ", values[NAMES[who]])
	var compared := compare_all(NAMES, stills, pixels)
	var closest_cells := ""
	for a in 4:
		for b in range(a + 1, 4):
			var key := "%s vs %s" % [NAMES[a], NAMES[b]]
			compared["pairs"][key]["cells_differ_in_label_of_640"] = cells_differ(said[a], said[b])
			if closest_cells == "" or compared["pairs"][key]["cells_differ_in_label_of_640"] < compared["pairs"][closest_cells]["cells_differ_in_label_of_640"]:
				closest_cells = key
			print(key, ": ", compared["pairs"][key]["cells_differ_in_label_of_640"], " of 640 cells differ in label")
	compared["closest_by_cells"] = closest_cells
	report["who_labelled"] = {"k": 3, "eye": "%.1f m above the middle of the floor" % ABOVE, "values": values, "compared": compared}

func a_line() -> void:
	var stills := []
	var pixels := []
	var values := {}
	for who in 4:
		var body := field(who, 3, 1)
		var got := await from_above(body, "line_%d" % who)
		stills.append(got[0])
		pixels.append(got[1])
		var one := counts(body)
		one["weights"] = [snappedf(body.weights.x, 0.001), snappedf(body.weights.y, 0.001)]
		one["bias"] = snappedf(body.bias, 0.001)
		var by_rounds := {}
		for rounds in [99, 100, 101, 102, 1000]:
			body.train(rounds)
			by_rounds[str(rounds)] = body.wrong()
		one["wrong_after_rounds"] = by_rounds
		body.train()
		values[NAMES[who]] = one
		tiles.append(small(got[0]))
		captions.append("%s: a line, %d of 36 wrong" % [NAMES[who], one["wrong_about_its_own"]])
		print(NAMES[who], " by a line: ", one)
	var xor: MeshInstance3D = field(0, 3, 1)
	await stand(xor)
	report["a_line"] = {"values": values, "compared": compare_all(NAMES, stills, pixels), "xor_wrong_of_4": xor.xor_wrong()}
	report["sheet"] = await compose(tiles, 4, captions, "res://sheet.png")

## One person's field as more neighbours vote, and what becomes of the lone sample.
func as_k_grows() -> void:
	var k_tiles: Array[Image] = []
	var names := []
	var values := {}
	for k in [1, 3, 5, 9]:
		var body := field(0, k)
		var got := await from_above(body, "k_%d" % k)
		var said := cells(body)
		var one := counts(body)
		one["left_out_wrong"] = left_out_wrong(body)
		var lone: Dictionary = body.chosen[LONE]
		var cell := int((lone.z + 2.5) / 0.25) * 32 + int((lone.x + 4.0) / 0.25)
		one["lone_sample"] = {"x": lone.x, "z": lone.z, "label": lone.label, "its_cell_says": said[cell][0]}
		one["lone_sample"]["cells_of_its_region"] = region(said, cell).size() if said[cell][0] == lone.label else 0
		values[str(k)] = one
		k_tiles.append(small(got[0]))
		names.append("k = %d" % k)
		print("k ", k, ": ", one)
	report["as_k_grows"] = {"labelled_by": NAMES[0], "values": values, "png": await compose(k_tiles, 4, names, "res://k.png")}

## The two tests on every labeller's field, with one neighbour and with three.
func the_tests() -> void:
	var values := {}
	for who in 4:
		var one := {}
		for k: int in [1, 3]:
			var body := field(who, k)
			await stand(body)
			one["k %d" % k] = {"wrong_about_its_own": body.wrong(), "left_out_wrong": left_out_wrong(body)}
		values[NAMES[who]] = one
		print(NAMES[who], " tests: ", one)
	report["the_tests"] = values

## Does the closest pair depend on k? Every pair's cells with another label, for four values of k.
func pairs_as_k_grows() -> void:
	var values := {}
	for k: int in [1, 3, 5, 9]:
		var said := []
		for who in 4:
			var body := field(who, k)
			await stand(body)
			said.append(cells(body))
		var pairs := {}
		var closest := ""
		for a in 4:
			for b in range(a + 1, 4):
				var key := "%s vs %s" % [NAMES[a], NAMES[b]]
				pairs[key] = cells_differ(said[a], said[b])
				if closest == "" or pairs[key] < pairs[closest]:
					closest = key
		values["k %d" % k] = {"cells_differ_in_label_of_640": pairs, "closest": closest}
		print("k ", k, ": closest by cells ", closest, " ", pairs)
	report["pairs_as_k_grows"] = values

## ---------------------------------------------------------------- the planted fault

## The learner script as the lesson first writes paint_field(): the image is
## painted and the texture is not told. Made from the shipped script by taking
## that one line out.
func without_update() -> GDScript:
	var source: String = learner.source_code
	var line := "\ttexture.update(image)\n"
	var faulty := GDScript.new()
	faulty.source_code = source.replace(line, "")
	if source.count(line) != 1 or faulty.reload() != OK:
		return null
	return faulty

var fault_tile: Image

func the_fault() -> void:
	var faulty := without_update()
	if faulty == null:
		report["the_fault"] = {"made": false}
		return
	var mended := field(0)
	var good := await from_above(mended, "mended")
	var body := field(0, 3, 0, faulty)
	var bad := await from_above(body, "not_updated")
	var shown: Image = body.texture.get_image()
	var painted := 0
	var shown_painted := 0
	for cz in 20:
		for cx in 32:
			if body.image.get_pixel(cx, cz) != Color.BLACK:
				painted += 1
			if shown.get_pixel(cx, cz) != Color.BLACK:
				shown_painted += 1
	var middle: Color = bad[0].get_pixel(bad[0].get_width() / 2 + 7, bad[0].get_height() / 2 + 7)
	fault_tile = bad[0]
	report["the_fault"] = {
		"made": true, "cells_of_the_image_painted": painted, "cells_of_the_texture_painted": shown_painted,
		"the_floor_in_the_still": "#" + middle.to_html(false),
		"differs_from_the_mended_field_pct": differ_pct(good[0], bad[0]),
	}
	print("the fault: ", report["the_fault"])

## ---------------------------------------------------------------- the error

func the_error() -> void:
	var values := {}
	for who in 4:
		var body := field(who, 3, 2)
		await stand(body)
		var lowest := INF
		var highest := 0.0
		var at := Vector2.ZERO
		var fewest := 99
		var fewest_at := Vector2.ZERO
		for cz in 20:
			for cx in 32:
				var place := Vector2((cx + 0.5) * 0.25 - 4.0, (cz + 0.5) * 0.25 - 2.5)
				var error: float = body.error_at(place.x, place.y)
				if error < lowest:
					lowest = error
					at = place
				highest = maxf(highest, error)
				body.weights = place * 0.25
				body.bias = 0.0
				if body.wrong() < fewest:
					fewest = body.wrong()
					fewest_at = place
		var path: Array = body.walk_down(Vector3(-3.2, 0, 2.0))
		var end: Vector3 = path[-1]
		body.weights = Vector2(end.x, end.z) * 0.25
		values[NAMES[who]] = {
			"lowest_error_of_a_cell": snappedf(lowest, 0.001), "at": [at.x, at.y], "highest": snappedf(highest, 0.001),
			"error_in_the_middle": snappedf(body.error_at(0.0, 0.0), 0.001),
			"error_where_the_walker_starts": snappedf(body.error_at(-3.2, 2.0), 0.001),
			"walk_down_steps": path.size(), "walk_down_ends": [snappedf(end.x, 0.01), snappedf(end.z, 0.01)],
			"error_there": snappedf(body.error_at(end.x, end.z), 0.001), "wrong_there": body.wrong(),
			"fewest_wrong_of_any_cell": fewest, "fewest_wrong_at": [fewest_at.x, fewest_at.y],
		}
		print(NAMES[who], " error: ", values[NAMES[who]])
	report["the_error"] = values

## ---------------------------------------------------------------- the strip

func the_strip() -> void:
	var from := Vector3(0.0, 8.4, 7.0)
	var at := Vector3(0.0, 0.0, 0.1)
	var strip_tiles: Array[Image] = []
	var names := ["samples from a file", "painted, not handed on", "texture.update()", "a line", "the error", "walked downhill"]
	# 1. the samples, before there is a field: the balls on the bare floor
	var body := field(0)
	await stand(body)
	body.mesh = null
	look_from(from, at)
	strip_tiles.append(small(await shot("strip_1")))
	# 2. the planted fault
	var faulty := without_update()
	body = field(0, 3, 0, faulty)
	await stand(body)
	look_from(from, at)
	strip_tiles.append(small(await shot("strip_2")))
	# 3 to 5. the mended field, the line, the error
	for rule in 3:
		body = field(0, 3, rule)
		await stand(body)
		look_from(from, at)
		strip_tiles.append(small(await shot("strip_%d" % (3 + rule))))
	# 6. a walker sent downhill by the field itself
	var holder := Node3D.new()
	var floor_field := field(0, 3, 2)
	floor_field.name = "Field"
	holder.add_child(floor_field)
	var walker: CharacterBody3D = load("res://supplied/walker.tscn").instantiate()
	walker.name = "Walker"
	walker.position = Vector3(-3.2, 0.0, 2.0)
	holder.add_child(walker)
	await stand(holder, false)
	look_from(from, at)
	var waited := 0
	while walker.walking and waited < 1200:
		await process_frame
		waited += 1
	for i in 5:
		await process_frame
	strip_tiles.append(small(await shot("strip_6")))
	report["process"] = await strip(strip_tiles, names)
	report["process"]["the_walk"] = {
		"ended": walker.ended, "at": [snappedf(walker.position.x, 0.01), snappedf(walker.position.z, 0.01)],
		"feet_at_m": snappedf(walker.position.y, 0.01), "readout": floor_field.readout.text,
	}
	print("the walk: ", report["process"]["the_walk"])
