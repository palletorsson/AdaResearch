extends "res://supplied/sheet_tools.gd"
## The sheet of Disturbed order. It needs a window, so run it WITHOUT --headless:
##   godot --path . --xr-mode off --script res://sheet.gd
## It writes
##   sheet.png    the Schotter floor at amplitude 0, 5, 20 and 90 degrees, seed
##                1968, each alone in the studio: in plan (from straight above,
##                with no perspective, as a plotter would draw it) and from a
##                raised standpoint in front of it, in perspective
##   process.png  the strip: one still after each step of the making
##   maze.png     the 10 PRINT maze in plan, at seed 1982 and at seed 2010
##   sheet.json   every pair of the four values, measured from both standpoints;
##                how much of the grid's lines is still clear floor in each plan;
##                a longer series against the floor in order; what another seed
##                changes at the same amplitude; the same disorder on a floor
##                with no gaps; and how much each step of the strip changed
## and the single stills, in stills/.

const Schotter := preload("res://schotter.gd")
const Maze := preload("res://maze.gd")

const VALUES := [0.0, 5.0, 20.0, 90.0]            # the axis: amplitude, in degrees
const SERIES := [1.0, 2.0, 5.0, 7.0, 10.0, 15.0, 20.0, 45.0, 90.0]
const PLAN_HEIGHT := 6.0                           # metres of floor from the top of a plan to its bottom: 120 pixels a metre
const RAISED := Vector3(0.0, 7.6, 5.4)             # the raised standpoint, and the strip's: 9.1 m from the floor's middle
const RAISED_AT := Vector3(0.0, 0.3, 0.0)

func run() -> void:
	await sheet()
	await series()
	await seeds()
	await no_gaps()
	await process_strip()
	await maze_plans()

## A floor made by schotter.gd, its middle over the studio's middle.
func floor_of(amplitude: float, seed_value := 1968, spacing := 0.6) -> Node3D:
	var made = Schotter.new()
	made.amplitude = amplitude
	made.seed_value = seed_value
	made.spacing = spacing
	made.position = Vector3(-(made.columns - 1) * spacing / 2.0, 0.0, -(made.rows - 1) * spacing / 2.0)
	return made

## [still, pixels] of a body in plan: from straight above, without perspective
## and without its shadow. One metre of floor is 120 pixels everywhere in it.
func plan(body: Node3D, name: String) -> Array:
	await stand(body)
	look("above", 9.0)
	eye.projection = Camera3D.PROJECTION_ORTHOGONAL
	eye.size = PLAN_HEIGHT
	return await portrait(body, name)

## [still, pixels] of a body from the raised standpoint, with no shadow.
func raised(body: Node3D, name: String) -> Array:
	await stand(body)
	eye.projection = Camera3D.PROJECTION_PERSPECTIVE
	look_from(RAISED, RAISED_AT)
	shadows(false)
	return await portrait(body, name)

## How much of the grid's lines is still clear floor in a plan. A line is the
## middle of a gap: 11 run between the columns and 4 between the rows. A pixel
## of a line is clear when no cube covers it. Returns the share of all of them
## in percent, the share of each line between two columns, left to right, and
## for comparison how much of the whole rectangle the floor in order takes up
## is clear: where the lines are no clearer than that, no grid is left to see.
func lines_clear(pixels: PackedByteArray, spacing := 0.6) -> Dictionary:
	var per_metre := crop.size.y / PLAN_HEIGHT
	var middle := Vector2(crop.size) / 2.0
	var clear := 0
	var all := 0
	var between_columns := []
	for i in 11:
		var px := roundi(middle.x + (i - 5) * spacing * per_metre)
		var here := 0
		var count := 0
		for py in range(roundi(middle.y - (2.0 * spacing + 0.25) * per_metre), roundi(middle.y + (2.0 * spacing + 0.25) * per_metre)):
			count += 1
			if pixels[py * crop.size.x + px] == 0:
				here += 1
		between_columns.append(snappedf(100.0 * here / count, 0.1))
		clear += here
		all += count
	for j in 4:
		var py := roundi(middle.y + (j - 1.5) * spacing * per_metre)
		for px in range(roundi(middle.x - (5.5 * spacing + 0.25) * per_metre), roundi(middle.x + (5.5 * spacing + 0.25) * per_metre)):
			all += 1
			if pixels[py * crop.size.x + px] == 0:
				clear += 1
	var open := 0
	var whole := 0
	for py in range(roundi(middle.y - (2.0 * spacing + 0.25) * per_metre), roundi(middle.y + (2.0 * spacing + 0.25) * per_metre)):
		for px in range(roundi(middle.x - (5.5 * spacing + 0.25) * per_metre), roundi(middle.x + (5.5 * spacing + 0.25) * per_metre)):
			whole += 1
			if pixels[py * crop.size.x + px] == 0:
				open += 1
	return {"clear_pct": snappedf(100.0 * clear / all, 0.1), "between_columns_pct": between_columns, "whole_rectangle_clear_pct": snappedf(100.0 * open / whole, 0.1)}

func title(value: float) -> String:
	return "%d degrees" % value

## The comparison sheet: every value from two standpoints, every pair measured.
func sheet() -> void:
	var tiles: Array[Image] = []
	var names := []
	for value: float in VALUES:
		names.append(title(value))
	var covers := {}
	var lines := {}
	for view: String in ["plan", "raised"]:
		var stills := []
		var pixels := []
		for value: float in VALUES:
			var taken: Array
			if view == "plan":
				taken = await plan(floor_of(value), "amplitude_%d_plan" % value)
				lines[title(value)] = lines_clear(taken[1])
				print("plan, %s: %.1f%% of the grid's lines are clear floor (%.1f%% of the whole rectangle is); between the columns, left to right: %s" % [title(value), lines[title(value)]["clear_pct"], lines[title(value)]["whole_rectangle_clear_pct"], lines[title(value)]["between_columns_pct"]])
			else:
				taken = await raised(floor_of(value), "amplitude_%d_raised" % value)
			stills.append(taken[0])
			pixels.append(taken[1])
			tiles.append(small(taken[0]))
			covers["%s, %s" % [view, title(value)]] = share(taken[1])
			print("%s, %s: the floor covers %.2f%% of the still" % [view, title(value), share(taken[1])])
		report["pairs_" + view] = compare_all(names, stills, pixels)
	report["floor_covers_pct"] = covers
	report["standpoints"] = {
		"plan": "from straight above, without perspective: %d pixels to a metre, the still %.1f m by %.1f m" % [crop.size.y / PLAN_HEIGHT, PLAN_HEIGHT * crop.size.x / crop.size.y, PLAN_HEIGHT],
		"raised": "in perspective, the eye at (0, 7.6, 5.4), %.1f m from the floor's middle" % RAISED.distance_to(Vector3(0.0, 0.25, 0.0)),
	}
	report["grid_lines_clear_in_plan"] = lines
	report["sheet_png"] = await compose(tiles, VALUES.size(), names, "res://sheet.png")

## A longer series in plan, each against the floor in order.
func series() -> void:
	var order: Array = await plan(floor_of(0.0), "")
	var rows := {}
	for value: float in SERIES:
		var taken: Array = await plan(floor_of(value), "")
		var pair := compare(order[0], order[1], taken[0], taken[1])
		rows[title(value)] = {"differs_from_0_pct": pair["differ_pct"], "grid_lines_clear_pct": lines_clear(taken[1])["clear_pct"]}
		print("0 against %s, in plan: differ on %.2f%% of the still; %.1f%% of the grid's lines are clear" % [title(value), pair["differ_pct"], rows[title(value)]["grid_lines_clear_pct"]])
	report["series_in_plan"] = rows

## Another cause: the seed. The same amplitude under two seeds, in plan.
func seeds() -> void:
	var rows := {}
	for value: float in [5.0, 20.0, 90.0]:
		var a: Array = await plan(floor_of(value, 1968), "")
		var b: Array = await plan(floor_of(value, 1969), "seed_1969_amplitude_%d_plan" % value)
		var pair := compare(a[0], a[1], b[0], b[1])
		rows[title(value)] = {"differ_pct": pair["differ_pct"], "grid_lines_clear_pct_seed_1968": lines_clear(a[1])["clear_pct"], "grid_lines_clear_pct_seed_1969": lines_clear(b[1])["clear_pct"]}
		print("seed 1968 against seed 1969 at %s, in plan: differ on %.2f%% of the still; the grid's lines are clear on %.1f%% and %.1f%%" % [title(value), pair["differ_pct"], rows[title(value)]["grid_lines_clear_pct_seed_1968"], rows[title(value)]["grid_lines_clear_pct_seed_1969"]])
	report["seed_1968_against_1969_in_plan"] = rows

## The claim's control: the same disorder on a floor with no gaps to disturb
## (spacing 0.5 m, the cubes touching), beside the floor of the lesson
## (spacing 0.6 m). Each difference is also given as a share of the floor's own
## pixels: the sixty cubes cover the same share of the plan with gaps and without.
func no_gaps() -> void:
	var rows := {}
	for spacing: float in [0.6, 0.5]:
		var order: Array = await plan(floor_of(0.0, 1968, spacing), "spacing_%.1f_amplitude_0_plan" % spacing)
		var row := {"floor_covers_pct": share(order[1])}
		for value: float in [5.0, 20.0]:
			var taken: Array = await plan(floor_of(value, 1968, spacing), "spacing_%.1f_amplitude_%d_plan" % [spacing, value])
			var pair := compare(order[0], order[1], taken[0], taken[1])
			row["0 against %s" % title(value)] = {"differ_pct": pair["differ_pct"], "of_the_floor_pct": snappedf(100.0 * pair["differ_pct"] / share(order[1]), 0.01)}
			print("spacing %.1f m, 0 against %s, in plan: differ on %.2f%% of the still, %.2f%% of the floor" % [spacing, title(value), pair["differ_pct"], 100.0 * pair["differ_pct"] / share(order[1])])
		rows["spacing %.1f m" % spacing] = row
	report["gaps_against_no_gaps_in_plan"] = rows

## The process strip: one still after each step, from one standpoint, shadows on.
## Steps 2 and 3 draw without a seed in the lesson, so every run is another
## floor. Here their generator is given seed 1 from outside, so that the strip
## can be made again; step 4 is the floor of seed 1968.
func process_strip() -> void:
	var names := ["1 a grid of cubes", "2 chance turns every cube", "3 more with every column", "4 a seed names the floor", "5 one of two turns: 10 PRINT"]
	var files := ["res://steps/01-order.gd", "res://steps/02-chance.gd", "res://steps/03-more-with-every-column.gd", "res://steps/04-seed.gd"]
	var tiles: Array[Image] = []
	for i in files.size():
		var made: Node3D = load(files[i]).new()
		if i == 1 or i == 2:
			made.rng.seed = 1
		made.position = Vector3(-3.3, 0.0, -1.2)
		await stand(made)
		eye.projection = Camera3D.PROJECTION_PERSPECTIVE
		look_from(RAISED, RAISED_AT)
		tiles.append(small(await shot("strip_%d" % (i + 1))))
	var maze: Node3D = Maze.new()
	maze.position = Vector3(-3.3, 0.0, -2.2)
	await stand(maze)
	look_from(RAISED, RAISED_AT)
	tiles.append(small(await shot("strip_5")))
	report["strip"] = await strip(tiles, names)

## The maze in plan, at the seed of the lesson and at the first seed whose maze
## can be crossed from west to east (verify.gd finds it and walks it).
func maze_plans() -> void:
	var tiles: Array[Image] = []
	for seed_value: int in [1982, 2010]:
		var made = Maze.new()
		made.seed_value = seed_value
		made.position = Vector3(-3.3, 0.0, -2.2)
		await stand(made)
		look("above", 9.0)
		eye.projection = Camera3D.PROJECTION_ORTHOGONAL
		eye.size = PLAN_HEIGHT
		tiles.append(small(await shot("maze_%d_plan" % seed_value)))
	eye.projection = Camera3D.PROJECTION_PERSPECTIVE
	report["maze_png"] = await compose(tiles, 2, ["seed 1982: no way from west to east", "seed 2010: one way across"], "res://maze.png")
