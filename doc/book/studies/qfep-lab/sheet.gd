extends "res://supplied/sheet_tools.gd"
## The stills of the QFEP laboratory. It needs a window. From this folder:
##   godot --path . --xr-mode off --script res://sheet.gd
## It photographs the same 200 symbols in four arrangements, each row alone in
## the plain studio, from the side and from above; measures every pair; flips
## one still to ask what a mirror image is to the measure; does the same for a
## second seed; reads the rendered colours back; and makes the process strip.
## It writes sheet.png, process.png, sheet.json and the single stills in stills/.

const Row := preload("res://row.gd")
const FCurve := preload("res://f_curve.gd")
const Segment := preload("res://supplied/segment.gd")

const DISTANCE := 4.9455   # metres: at this distance one bar of 0.02 m is 4 pixels wide in a still
const STRIP := ["200 draws as bars", "a colour for each value", "sort_custom by value", "by colour", "the log as plates", "the line of F"]

func run() -> void:
	var names: Array = Row.NAMES
	report["axis"] = "arrangement: how the same 200 symbols stand in the row"
	report["values"] = names
	report["seed"] = 40
	var level := await sweep(40, "level")
	var above := await sweep(40, "above")
	report["entropy_bits"] = level["entropy"]
	report["counts_0_to_9"] = level["counts"]
	report["row_covers_pct_level"] = level["covers"]
	report["row_covers_pct_above"] = above["covers"]
	report["draw_0_read_back_from_the_bars"] = level["draw_0"]
	print("--- from the side")
	report["pairs_level"] = compare_all(names, level["stills"], level["pixels"])
	print("--- from above")
	report["pairs_above"] = compare_all(names, above["stills"], above["pixels"])

	# A mirror image: flip one still left to right and measure the pair again.
	var flipped: Image = level["stills"][3].duplicate()
	flipped.flip_x()
	var flipped_above: Image = above["stills"][3].duplicate()
	flipped_above.flip_x()
	report["mirror"] = {
		"sorted by value vs sorted in reverse, level": report["pairs_level"]["pairs"]["sorted by value vs sorted in reverse"]["differ_pct"],
		"the same pair with the second still flipped left to right, level": differ_pct(level["stills"][1], flipped),
		"sorted by value vs sorted in reverse, above": report["pairs_above"]["pairs"]["sorted by value vs sorted in reverse"]["differ_pct"],
		"the same pair with the second still flipped left to right, above": differ_pct(above["stills"][1], flipped_above),
	}
	print("mirror: ", report["mirror"])

	# Another seed: is the order of the pairs the seed's or the arrangement's?
	var other := await sweep(41, "level")
	print("--- seed 41, from the side")
	var other_pairs := compare_all(names, other["stills"], other["pixels"])
	report["seed_41_level"] = {"entropy_bits": other["entropy"], "pairs": brief(other_pairs), "closest": other_pairs["closest"], "farthest": other_pairs["farthest"]}

	# The colours as rendered: the front face of one bar of each colour.
	report["rendered_front_faces"] = await colours()

	# The glide, read back from the bars: part of the way, and at the end.
	report["glide"] = await glide()

	var tiles: Array[Image] = []
	for still: Image in level["stills"]:
		tiles.append(small(still))
	for still: Image in above["stills"]:
		tiles.append(small(still))
	report["sheet_png"] = await compose(tiles, 4, names, "res://sheet.png")
	report["sheet_rows"] = ["from the side, 4.95 m from the row", "from straight above, the same distance"]

	var steps: Array[Image] = []
	for step in STRIP.size():
		await stand(lab_state(step), true)
		prepare(step)
		look_from(Vector3(0.0, 2.7, 7.8), Vector3(0.0, 0.3, -0.3))
		steps.append(small(await shot("strip_%d" % step)))
	report["strip"] = await strip(steps, STRIP)

## One row for each arrangement, alone in the studio, from one standpoint.
func sweep(seed_value: int, view: String) -> Dictionary:
	var out := {"stills": [], "pixels": [], "entropy": {}, "covers": {}, "counts": [], "draw_0": {}}
	for how in Row.NAMES.size():
		var body := Node3D.new()
		body.set_script(Row)
		body.seed_value = seed_value
		body.arrangement = how
		await stand(body)
		body.readout.hide()   # the words differ from row to row; the still measures the bars
		look(view, DISTANCE)
		var both := await portrait(body, "%s_seed%d_%d" % [view, seed_value, how])
		out["stills"].append(both[0])
		out["pixels"].append(both[1])
		out["entropy"][Row.NAMES[how]] = "%.17f" % body.entropy(body.row())
		out["covers"][Row.NAMES[how]] = share(both[1])
		var first: Transform3D = body.bars.get_instance_transform(0)   # the view, not the script's own list
		out["draw_0"][Row.NAMES[how]] = {"place_asked": body.goes_to[0], "place_of_the_bar": place_of(first.origin.x, body.count), "height_m": snappedf(first.basis.y.length(), 0.001), "symbol": body.values[0]}
		if how == 0:
			var counts: Dictionary = body.tally(body.values)
			for s in Row.ALPHABET:
				out["counts"].append(counts.get(s, 0))
	return out

func place_of(x: float, count: int) -> float:
	return snappedf(x / Row.PITCH + (count - 1) / 2.0, 0.001)

## The glide, read back from the bars and not from the script's own lists.
## First by hand: slide(0.37) puts every bar 37% of the way from the place it
## was drawn at to its place sorted by value. Then by the tween: 0.6 seconds,
## looked at after 0.3 and again 0.5 seconds later.
func glide() -> Dictionary:
	var body := Node3D.new()
	body.set_script(Row)
	await stand(body, false)
	body.readout.hide()
	look("level", DISTANCE)
	body.arrange(1, 0.0)
	body.arrange(0, 0.0)
	body.arrange(1, 0.0)   # came_from is now as drawn, goes_to sorted by value
	body.slide(0.37)
	var between := astray(body, true)
	await shot("glide_at_0_37")
	body.arrange(0, 0.0)
	body.arrange(1, 0.6)
	await create_timer(0.3).timeout
	var under_way := astray(body, false) > 0
	await create_timer(0.5).timeout
	var out := {"bars": body.count, "between_two_places_at_0_37_of_the_way": between, "tween_under_way_after_0_3_s": under_way, "not_on_their_place_0_5_s_later": astray(body, false), "h_at_the_end": "%.17f" % body.entropy(body.row())}
	print("glide: ", out)
	return out

## How many bars do not stand on a whole place (`whole`), or not on the place they go to.
func astray(body: Node3D, whole: bool) -> int:
	var found := 0
	for i in body.count:
		var place := place_of(body.bars.get_instance_transform(i).origin.x, body.count)
		if (whole and absf(place - roundf(place)) > 0.01) or (not whole and not is_equal_approx(place, float(body.goes_to[i]))):
			found += 1
	return found

func brief(result: Dictionary) -> Dictionary:
	var out := {}
	for key: String in result["pairs"]:
		out[key] = result["pairs"][key]["differ_pct"]
	return out

## The row sorted by colour, from the side: the pixel in the middle of each
## colour's block, 5 cm above the floor, on the bars' front faces.
func colours() -> Dictionary:
	var body := Node3D.new()
	body.set_script(Row)
	body.arrangement = 2
	await stand(body)
	body.readout.hide()
	look("level", DISTANCE)
	var still := await shot("")
	var counts: Dictionary = body.tally(body.values)
	var out := {}
	var place := 0
	var roles := ["BODY", "SECOND", "THIRD", "BONE"]
	for colour in 4:
		var bars := 0
		for s in Row.ALPHABET:
			if s % 4 == colour:
				bars += counts.get(s, 0)
		var x: float = (place + bars / 2.0 - body.count / 2.0) * Row.PITCH
		var at := eye.unproject_position(Vector3(x, 0.05, 0.15)) - Vector2(crop.position)
		var seen := still.get_pixel(int(at.x), int(at.y))
		var asked: Color = Look.BODIES[colour]
		var off := (absf(seen.r - asked.r) + absf(seen.g - asked.g) + absf(seen.b - asked.b)) * 255.0
		out[roles[colour]] = {"palette": "#" + asked.to_html(false), "front_face": "#" + seen.to_html(false), "off_by_of_765": snappedf(off, 0.1), "bars": bars}
		place += bars
	print("rendered: ", out)
	return out

## The lab as it is after each step of the strip: the row, then the log beside it.
func lab_state(step: int) -> Node3D:
	var lab := Node3D.new()
	var row := Node3D.new()
	row.name = "Row"
	row.set_script(Row)
	row.arrangement = [0, 0, 1, 2, 2, 2][step]
	row.position = Vector3(0.0, 0.0, -1.4)
	lab.add_child(row)
	if step >= 4:
		var curve := Node3D.new()
		curve.name = "Curve"
		curve.set_script(FCurve)
		curve.position = Vector3(0.0, 0.0, 0.4)
		lab.add_child(curve)
	return lab

## What a step has not got yet is taken away again.
func prepare(step: int) -> void:
	var row: Node3D = subject.get_node("Row")
	if step == 0:
		for i in row.count:
			row.bars.set_instance_color(i, Look.BODY)
	if step == 4:
		for child in subject.get_node("Curve").get_children():
			if child.get_script() == Segment:
				child.free()
