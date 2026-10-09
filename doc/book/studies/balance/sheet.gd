extends "res://supplied/sheet_tools.gd"
## The Balance kit's sheet. It needs a window, so run it WITHOUT --headless, from
## this folder:
##   godot --path . --xr-mode off --script res://sheet.gd
## It writes
##   sheet.png    the plate on four posts, three seconds after it was let go, with
##                its centre of mass at its centre, halfway to the edge of the
##                posts, on the edge and outside: as it looks (first row); with
##                the centre of mass, its plumb line and the outline of the posts
##                drawn (second row); and drawn, with the plate not allowed to
##                fall asleep (third row)
##   process.png  the strip: one still after each step of the making, from one
##                standpoint
##   sheet.json   every pair of values measured for the three rows; for each value
##                the plate's tilt, where it is, whether it sleeps and when it fell
##                asleep, what fell; the strip
## and the single stills, in stills/.

const TABLE := preload("res://table.gd")
const COUNTER := preload("res://counter.gd")
const OFFSETS := [0.0, 0.17, 0.34, 0.51]   # the axis: metres from the plate's middle towards +x
const NAMES := ["at its centre", "halfway to the edge", "on the edge", "outside"]
const EDGE_OF_POSTS := 0.34                # the outer faces of the posts: 0.3 + 0.04

func run() -> void:
	await sheet()
	await process_strip()

## A table as the lesson leaves it, with the settings given, held until we let it go.
func table(settings: Dictionary) -> Node3D:
	var made := Node3D.new()
	made.set_script(TABLE)
	made.name = "Table"
	made.members = 0
	made.walker_mass = 0.0
	made.hold = 1000.0          # we let go ourselves
	for key: String in settings:
		made.set(key, settings[key])
	return made

## The counter of the lesson, beside a table, its label 1.25 m up and 0.35 m to the right
## (in balance.tscn it is 1.5 m up, over the middle), so that a walker does not hide it.
func counter() -> Node3D:
	var made := Node3D.new()
	made.set_script(COUNTER)
	made.name = "Counter"
	made.position = Vector3(0.35, 1.25, 0)
	return made

## The relation drawn by the table (mark, outline, plumb line) shown or hidden.
## Hidden by its render layers, because show_between() sets `visible` again every step.
func relation(made: Node3D, on: bool) -> void:
	made.plate.get_node("Mark").layers = 1 if on else 0
	for child in made.get_children():
		if child.get_script() == preload("res://supplied/segment.gd"):
			child.layers = 1 if on else 0

## Let go, and wait three seconds of the physics; what the plate did.
func after_release(made: Node3D, steps := 180) -> Dictionary:
	made.release()
	var asleep_at := -1
	for i in steps:
		await physics_frame
		if asleep_at < 0 and made.plate.sleeping:
			asleep_at = i + 1
	var at: Vector3 = made.plate.global_position
	return {"tilt_deg": snappedf(made.tilt(made.plate), 0.001), "plate_at_m": [snappedf(at.x, 0.00001), snappedf(at.y, 0.00001), snappedf(at.z, 0.00001)],
		"sleeping": made.plate.sleeping, "fell_asleep_after_steps": asleep_at, "fallen": made.down.map(func(b: RigidBody3D) -> String: return str(b.name))}

## The eye of the sheet: from the front, 1.2 m above and 2.9 m in front of the middle; no shadows.
func _eye() -> void:
	var middle := Vector3(0.5, 0.3, 0.0)
	look_from(middle + Vector3(0, 1.2, 2.9), middle)
	shadows(false)

## The comparison sheet: four values, three ways, every pair measured.
func sheet() -> void:
	var rows := {"as_it_looks": [[], []], "relation_drawn": [[], []], "relation_drawn_cannot_sleep": [[], []]}
	var plates := {}
	for row: String in rows:
		plates[row] = {}
		for k in OFFSETS.size():
			var made := table({"offset": OFFSETS[k]})
			await stand(made, false)
			if row == "relation_drawn_cannot_sleep":
				made.plate.can_sleep = false
			var did := await after_release(made)
			did["offset_m"] = OFFSETS[k]
			did["offset_of_the_edge"] = snappedf(OFFSETS[k] / EDGE_OF_POSTS, 0.01)
			plates[row][NAMES[k]] = did
			made.process_mode = Node.PROCESS_MODE_DISABLED
			relation(made, row != "as_it_looks")
			_eye()
			var taken: Array = await portrait(made, "%s_%d" % [row, k])
			rows[row][0].append(taken[0])
			rows[row][1].append(taken[1])
			print("%s, %s: tilt %.2f deg, sleeping %s, fallen %s; the table covers %.2f%% of the still" % [row, NAMES[k], did["tilt_deg"], did["sleeping"], did["fallen"], share(taken[1])])
	report["axis"] = "offset: the plate's centre of mass, metres from its middle towards +x; the outer faces of the posts are at 0.34"
	report["values"] = OFFSETS
	report["names"] = NAMES
	report["three_seconds_after_release"] = plates
	var tiles: Array[Image] = []
	for row: String in rows:
		print("--- ", row)
		report["pairs_" + row] = compare_all(NAMES, rows[row][0], rows[row][1])
		for still: Image in rows[row][0]:
			tiles.append(small(still))
	report["sheet_rows"] = ["as it looks", "with the centre of mass, its plumb line and the outline of the posts drawn", "drawn, and the plate may not fall asleep"]
	report["sheet_png"] = await compose(tiles, OFFSETS.size(), NAMES, "res://sheet.png")

## The process strip: one still after each step of the making, from one standpoint.
func process_strip() -> void:
	var names := ["1 posts, a plate held", "2 let go: it stands", "3 centre of mass outside", "4 the relation drawn",
		"5 two legs", "6 the counter listens", "7 three members stacked", "8 a walker's weight"]
	var tiles: Array[Image] = []
	var from := Vector3(1.75, 1.6, 2.9)
	var at := Vector3(0.3, 0.5, 0.0)
	var record := {}
	# 1 and 2: the plate on four posts, held, then let go
	var made := table({})
	await stand(made, false)
	relation(made, false)
	look_from(from, at)
	tiles.append(small(await shot("strip_1")))
	record["2_let_go"] = await after_release(made, 120)
	tiles.append(small(await shot("strip_2")))
	# 3 and 4: the centre of mass outside; then the relation drawn on what happened
	made = table({"offset": 0.51})
	await stand(made, false)
	relation(made, false)
	look_from(from, at)
	record["3_outside"] = await after_release(made)
	tiles.append(small(await shot("strip_3")))
	relation(made, true)
	tiles.append(small(await shot("strip_4")))
	# 5: two legs, the centre of mass at the centre
	made = table({"legs": 2})
	await stand(made, false)
	look_from(from, at)
	record["5_two_legs"] = await after_release(made)
	tiles.append(small(await shot("strip_5")))
	# 6: the counter listens to a plate whose centre of mass is outside
	var group := Node3D.new()
	made = table({"offset": 0.51})
	group.add_child(made)
	var heard := counter()
	group.add_child(heard)
	await stand(group, false)
	look_from(from, at)
	record["6_counter"] = await after_release(made)
	record["6_counter"]["label"] = heard.words.text
	tiles.append(small(await shot("strip_6")))
	# 7: three members of the family on the plate, as the lesson's table has them
	group = Node3D.new()
	made = table({"members": 3, "lean": 0.04})
	group.add_child(made)
	heard = counter()
	group.add_child(heard)
	await stand(group, false)
	look_from(from, at)
	record["7_members"] = await after_release(made)
	record["7_members"]["label"] = heard.words.text
	tiles.append(small(await shot("strip_7")))
	# 8: a walker of 60 kg stands on the plate, 0.5 m left of its middle
	var walker: CharacterBody3D = load("res://supplied/walker.tscn").instantiate()
	walker.keys = false
	walker.position = Vector3(-0.5, 0.36, 0)
	made.walker_mass = 60.0
	group.add_child(walker)
	for i in 180:
		await physics_frame
	record["8_walker"] = {"tilt_deg": snappedf(made.tilt(made.plate), 0.01), "fallen": made.down.map(func(b: RigidBody3D) -> String: return str(b.name)),
		"label": heard.words.text, "walker_at_m": [snappedf(walker.global_position.x, 0.01), snappedf(walker.global_position.y, 0.01)]}
	group.process_mode = Node.PROCESS_MODE_DISABLED
	tiles.append(small(await shot("strip_8")))
	report["strip"] = await strip(tiles, names)
	report["strip"]["what_each_step_did"] = record
