extends "res://supplied/sheet_tools.gd"
## The Spiral stair kit's sheet. It needs a window, so run it WITHOUT --headless,
## from this folder:
##   godot --path . --xr-mode off --script res://sheet.gd
## It writes
##   sheet.png    the argument: the stair at four rises, in four rows. From the
##                side; in plan (from straight above, with no perspective);
##                with the walker where its walk ended; and the ramp of the
##                same spiral with the walker where its walk ended
##   process.png  the strip: one still after each step of the lesson
##   well.png     what the walker's eyes get at the top, looking down the well
##   sheet.json   the measurements: every pair of rises from the side and in
##                plan, the plan pairs again with no threshold, three pairs
##                that are 0.08 m apart, how each walk ended and how high the
##                feet were, and what each step changed
## and the stills, in stills/.

const Stair := preload("res://stair.gd")
const WALKER := "res://supplied/walker.tscn"
const RISES := [0.10, 0.18, 0.30, 0.60]
const START := Vector3(2.7, 0.0, 0.0)      # where spiral_stair.tscn puts the walker
const SIDE_MIDDLE := Vector3(0.0, 2.7, 0.0)
const SIDE_DISTANCE := 9.0                 # metres: far enough for the stair of 0.60, 5.4 m high

func stair(rise: float, ramp := false) -> Node3D:
	var body: Node3D = Stair.new()
	body.rise = rise
	body.ramp = ramp
	return body

func run() -> void:
	await sheet()
	await process_strip()

## A stair and a walker in the studio; the walker is sent up, and the still is
## taken where its walk ended. Returns [still, how, feet in metres, the group].
func walked(body: Node3D, name: String, steps_up := true) -> Array:
	var group := Node3D.new()
	group.add_child(body)
	var walker: CharacterBody3D = load(WALKER).instantiate()
	walker.position = START    # before add_child: a body is in the room from the step it is added
	if not steps_up:
		walker.step_height = 0.0
	group.add_child(walker)
	await stand(group, false)  # not held: the walker has to walk
	for i in 20:
		await physics_frame
	walker.walk_to(body.route())
	var how: String = await walker.walk_ended
	await process_frame
	for i in 20:
		await physics_frame
	var still := await shot(name)
	return [still, how, snappedf(walker.global_position.y, 0.01), group]

## Two stills compared with no threshold: how many pixels are not the same
## bytes, and the largest difference found, the three channels added (of 765).
func to_the_pixel(a: Image, b: Image) -> Dictionary:
	var p := a.get_data()
	var q := b.get_data()
	var unequal := 0
	var largest := 0
	for k in range(0, p.size(), 3):
		var apart := absi(p[k] - q[k]) + absi(p[k + 1] - q[k + 1]) + absi(p[k + 2] - q[k + 2])
		if apart > 0:
			unequal += 1
			largest = maxi(largest, apart)
	@warning_ignore("integer_division")
	return {"pixels_not_the_same": unequal, "of": p.size() / 3, "largest_difference_of_765": largest}

## The comparison sheet: four rises, four rows.
func sheet() -> void:
	var tiles: Array[Image] = []
	var captions := []
	var names := []
	for rise: float in RISES:
		names.append("%.2f" % rise)
	# Row 1: each stair alone, from the side. Every pair measured.
	var stills := []
	var pixels := []
	var covers := {}
	for rise: float in RISES:
		await stand(stair(rise))
		look("level", SIDE_DISTANCE, SIDE_MIDDLE)
		var taken: Array = await portrait(subject, "side_%.2f" % rise)
		stills.append(taken[0])
		pixels.append(taken[1])
		tiles.append(small(taken[0]))
		captions.append("rise %.2f m: top at %.2f m" % [rise, subject.top()])
		covers["side %.2f" % rise] = share(taken[1])
		print("side, rise %.2f: the stair covers %.2f%% of the still" % [rise, share(taken[1])])
	report["pairs_side"] = compare_all(names, stills, pixels)
	# Another cause: 0.10 and 0.18 are also the two nearest numbers. Three pairs, each 0.08 m apart.
	var steps := {}
	for pair: Array in [[0.10, 0.18], [0.22, 0.30], [0.52, 0.60]]:
		var two := []
		for rise: float in pair:
			await stand(stair(rise))
			look("level", SIDE_DISTANCE, SIDE_MIDDLE)
			two.append(await shot(""))
		steps["%.2f vs %.2f" % pair] = differ_pct(two[0], two[1])
		print("side, %.2f vs %.2f, 0.08 m apart: they differ on %.2f%% of the still" % [pair[0], pair[1], steps["%.2f vs %.2f" % pair]])
	report["pairs_side_0.08_apart"] = steps
	# Row 2: the plan. From straight above with no perspective, so that height is not in the picture.
	stills = []
	pixels = []
	for rise: float in RISES:
		await stand(stair(rise))
		look("above", 20.0, Vector3.ZERO)
		eye.projection = Camera3D.PROJECTION_ORTHOGONAL
		eye.size = 4.4
		var taken: Array = await portrait(subject, "plan_%.2f" % rise)
		stills.append(taken[0])
		pixels.append(taken[1])
		tiles.append(small(taken[0]))
		captions.append("rise %.2f m, in plan" % rise)
		covers["plan %.2f" % rise] = share(taken[1])
		print("plan, rise %.2f: the stair covers %.2f%% of the still" % [rise, share(taken[1])])
	report["pairs_plan"] = compare_all(names, stills, pixels)
	# That measure counts a pixel only when its channels are more than 25 of 255 apart. Count again with no threshold.
	var exact := {}
	for i in stills.size():
		for j in range(i + 1, stills.size()):
			exact["%s vs %s" % [names[i], names[j]]] = to_the_pixel(stills[i], stills[j])
			print("plan, %s vs %s, with no threshold: %d of %d pixels are not the same; the largest difference is %d of 765" % [names[i], names[j],
				exact["%s vs %s" % [names[i], names[j]]]["pixels_not_the_same"], exact["%s vs %s" % [names[i], names[j]]]["of"], exact["%s vs %s" % [names[i], names[j]]]["largest_difference_of_765"]])
	report["pairs_plan_to_the_pixel"] = exact
	report["the_stair_covers_pct_of_the_still"] = covers
	report["standpoints"] = {"side": {"metres_from_the_middle": SIDE_DISTANCE, "looking_at_height_m": SIDE_MIDDLE.y, "projection": "perspective"},
		"plan": {"from": "straight above", "projection": "orthogonal", "metres_across_the_still": 4.4}}
	eye.projection = Camera3D.PROJECTION_PERSPECTIVE
	eye.fov = FOV
	# Rows 3 and 4: the walker where its walk ended, on the stair and on the ramp.
	var walks := {}
	for ramp: bool in [false, true]:
		for rise: float in RISES:
			var kind := "ramp" if ramp else "stair"
			look("level", SIDE_DISTANCE, SIDE_MIDDLE)
			var body := stair(rise, ramp)
			var out: Array = await walked(body, "%s_walk_%.2f" % [kind, rise])
			tiles.append(small(out[0]))
			captions.append("%s %.2f m: %s, feet at %.2f m" % [kind, rise, out[1], out[2]])
			walks["%s %.2f" % [kind, rise]] = {"walk_ended": out[1], "feet_at_m": out[2], "top_m": snappedf(body.top(), 0.01)}
			print("%s, rise %.2f: the walk ended \"%s\" with the feet at %.2f m" % [kind, rise, out[1], out[2]])
	report["walks"] = walks
	report["sheet_png"] = await compose(tiles, RISES.size(), captions, "res://sheet.png")

## The process strip: one still after each step of the lesson, from one standpoint.
func process_strip() -> void:
	var names := ["1 one tread on the circle", "2 nine by the function", "3 the walker, sent: through", "4 a collider each: at the top", "5 degrees read as radians", "6 the ramp: one surface"]
	var tiles: Array[Image] = []
	var from := Vector3(3.4, 3.4, 5.6)
	var at := Vector3(0.0, 1.0, 0.0)
	var facts := []
	# 1. One tread at angle 0.
	var one: Node3D = stair(0.18)
	one.treads = 1
	one.turn_deg = 0.0
	await stand(one)
	look_from(from, at)
	tiles.append(small(await shot("strip_1")))
	facts.append({"treads": 1})
	# 2. Nine treads by the function, as meshes: nobody walks yet.
	await stand(stair(0.18))
	look_from(from, at)
	tiles.append(small(await shot("strip_2")))
	facts.append({"treads": 9})
	# 3. The walker is sent, and the treads have no colliders yet: it walks through them.
	var ghost: Node3D = stair(0.18)
	ghost.ready.connect(func() -> void:
		for shape: CollisionShape3D in ghost.find_children("*", "CollisionShape3D", true, false):
			shape.disabled = true)
	look_from(from, at)
	var out: Array = await walked(ghost, "strip_3")
	tiles.append(small(out[0]))
	facts.append({"walk_ended": out[1], "feet_at_m": out[2]})
	# 4. A collider for each tread: the walker climbs.
	look_from(from, at)
	out = await walked(stair(0.18), "strip_4")
	tiles.append(small(out[0]))
	facts.append({"walk_ended": out[1], "feet_at_m": out[2]})
	await well(out[3].get_child(1))
	# 5. The planted bug. 30 handed to cos() as radians is a turn of rad_to_deg(30) degrees.
	var bug: Node3D = stair(0.18)
	bug.turn_deg = rad_to_deg(30.0)
	look_from(from, at)
	out = await walked(bug, "strip_5")
	tiles.append(small(out[0]))
	facts.append({"walk_ended": out[1], "feet_at_m": out[2]})
	# 6. The ramp.
	look_from(from, at)
	out = await walked(stair(0.18, true), "strip_6")
	tiles.append(small(out[0]))
	facts.append({"walk_ended": out[1], "feet_at_m": out[2]})
	report["strip"] = await strip(tiles, names)
	for i in facts.size():
		report["strip"]["steps"][i].merge(facts[i])

## What the walker's eyes get at the top, looking down the well: a still of its own.
func well(walker: Node3D) -> void:
	var eyes := walker.global_position + Vector3(0.0, 1.6, 0.0)
	look_from(eyes, Vector3(0.3, 0.0, 0.2))
	var still := await shot("well")
	still.save_png("res://well.png")
	report["well"] = {"eyes_at": [snappedf(eyes.x, 0.01), snappedf(eyes.y, 0.01), snappedf(eyes.z, 0.01)], "looking_at": [0.3, 0.0, 0.2],
		"bytes": FileAccess.get_file_as_bytes("res://well.png").size()}
