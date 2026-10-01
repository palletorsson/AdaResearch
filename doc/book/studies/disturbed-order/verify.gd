extends "res://supplied/verify_tools.gd"
## The checks of Disturbed order. From this folder:
##   godot --headless --path . --xr-mode off --script res://verify.gd
## (add --fixed-fps 60 and the walks take seconds instead of a minute).
## It builds the Schotter floor and the 10 PRINT maze from the learner's two
## scripts, reads back what was built, walks the supplied walker over both,
## and writes verification.json. Every number the lesson quotes about a floor,
## a walk or a corridor is in `measured` there.

const CheckGuest := preload("res://supplied/check_guest.gd")
const Look := preload("res://supplied/look.gd")
const Schotter := preload("res://schotter.gd")
const Maze := preload("res://maze.gd")

const VALUES := [0.0, 5.0, 20.0, 90.0]   # the argument's axis: amplitude, in degrees
const WEST := 0
const NORTH := 1
const EAST := 2
const SOUTH := 3
const SIDES := ["west", "north", "east", "south"]
const STEPS := ["01-order.gd", "02-chance.gd", "03-more-with-every-column.gd", "04-seed.gd", "05-next-seed.gd"]

func run() -> void:
	project()
	await schotter()
	await chance()
	await argument()
	await place()
	await maze()
	await guest()
	await steps()
	check(errors.is_empty(), "from the first check to the last Godot logged no error: %s" % [errors])

# ---------------------------------------------------------------- the project

func project() -> void:
	check(ProjectSettings.get_setting("application/config/name") == "Disturbed order" and ProjectSettings.get_setting("application/run/main_scene") == "res://schotter.tscn",
		"the project is Disturbed order and starts with schotter.tscn")
	var supplied := ["base.tscn", "base_look.gd", "check_guest.gd", "look.gd", "marble.gd", "marble.tscn", "mover.gd", "segment.gd", "sheet_tools.gd", "sweep_sheet.gd", "sweep_sheet.tscn", "trace_strip.gd", "verify_tools.gd", "walker.gd", "walker.tscn"]
	var missing := []
	for file: String in supplied:
		if not FileAccess.file_exists("res://supplied/" + file):
			missing.append(file)
	check(missing.is_empty(), "supplied/ holds the kit base's 15 parts: %s" % [missing])
	var own := ["res://schotter.gd", "res://maze.gd", "res://verify.gd", "res://sheet.gd", "res://guests/disturbed-order/disturbed-order.gd"]
	for file: String in STEPS:
		own.append("res://steps/" + file)
	var spaces := []
	var named := []
	for path: String in own:
		var text := FileAccess.get_file_as_string(path)
		for line in text.split("\n"):
			if line.begins_with(" "):
				spaces.append(path)
				break
		if RegEx.create_from_string("(?m)^class_name\\s").search(text) != null:
			named.append(path)
	check(spaces.is_empty(), "every script of the kit is indented with tabs: %s" % [spaces])
	check(named.is_empty(), "no script of the kit declares a class_name, so a fresh copy needs no import: %s" % [named])
	var part: Node = load("res://borrowed/cube_part.tscn").instantiate()
	var shape: Shape3D = part.get_node("Body/CollisionShape3D").shape
	check(part is MeshInstance3D and part.mesh is BoxMesh and part.mesh.size == Vector3(0.5, 0.5, 0.5) and shape is BoxShape3D and shape.size == Vector3(0.5, 0.5, 0.5) and part.material_override == null and part.mesh.material == null,
		"the borrowed cube part is a box of 0.5 m with a box collider of 0.5 m and no colour of its own")
	part.free()

# ---------------------------------------------------------------- the floor

## A floor made by schotter.gd, alone, not yet in the scene.
func floor_of(amplitude: float, seed_value: int, spacing := 0.6) -> Node3D:
	var made = Schotter.new()
	made.amplitude = amplitude
	made.seed_value = seed_value
	made.spacing = spacing
	return made

## The same floor, built: in the scene, one frame later.
func built(amplitude: float, seed_value: int, spacing := 0.6) -> Node3D:
	var made := floor_of(amplitude, seed_value, spacing)
	root.add_child(made)
	await process_frame
	return made

func transforms_of(body: Node3D) -> Array:
	var out := []
	for child: Node3D in body.get_children():
		out.append(child.transform)
	return out

func same(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if not a[i].is_equal_approx(b[i]):
			return false
	return true

## The place cube (x, z) has in the floor in order.
func home_of(made: Node3D, index: int) -> Vector3:
	@warning_ignore("integer_division")
	return Vector3((index / made.rows) * made.spacing, 0.25, (index % made.rows) * made.spacing)

## For each column: how many of its cubes have a corner over the middle of a
## gap, seen from above: outside their own cell (the square of `spacing` round
## the cube's place) on a side where a neighbour stands. The floor's outer edge
## is no gap and does not count.
func left_cell(made: Node3D) -> Array:
	var counts := []
	for x in made.columns:
		var gone := 0
		for z in made.rows:
			var cube: Node3D = made.get_child(x * made.rows + z)
			var home := home_of(made, x * made.rows + z)
			var out := false
			var half: float = made.spacing / 2.0
			for corner: Vector3 in corners_of(cube.transform, 0.25):
				var dx := corner.x - home.x
				var dz := corner.z - home.z
				if (dx > half and x < made.columns - 1) or (dx < -half and x > 0) or (dz > half and z < made.rows - 1) or (dz < -half and z > 0):
					out = true
			if out:
				gone += 1
		counts.append(gone)
	return counts

func corners_of(place: Transform3D, half: float) -> Array:
	var out := []
	for sx: float in [-half, half]:
		for sy: float in [-half, half]:
			for sz: float in [-half, half]:
				out.append(place * Vector3(sx, sy, sz))
	return out

## The farthest any corner of any cube is from where it is in the floor in order.
func corner_moved(made: Node3D) -> float:
	var far := 0.0
	for i in made.get_child_count():
		var now := corners_of(made.get_child(i).transform, 0.25)
		var before := corners_of(Transform3D(Basis(), home_of(made, i)), 0.25)
		for k in 8:
			far = maxf(far, (now[k] - before[k]).length())
	return far

func total(counts: Array) -> int:
	var sum := 0
	for count: int in counts:
		sum += count
	return sum

func first_column(counts: Array) -> int:
	for x in counts.size():
		if counts[x] > 0:
			return x
	return -1

func schotter() -> void:
	var before := printed.size()
	var a := await built(20.0, 1968)
	check(a.get_child_count() == 60 and a.columns == 12 and a.rows == 5, "schotter.gd builds 60 cubes: 12 columns of 5")
	var whole := true
	for cube in a.get_children():
		if not cube is MeshInstance3D or not cube.get_node_or_null("Body") is StaticBody3D or not cube.get_node("Body/CollisionShape3D").shape is BoxShape3D:
			whole = false
	check(whole, "every cube is the borrowed part: a mesh with a StaticBody3D and a box shape")
	var first: MeshInstance3D = a.get_child(0)
	var one_paint := true
	for cube: MeshInstance3D in a.get_children():
		if cube.material_override != first.material_override:
			one_paint = false
	check(one_paint and first.material_override.albedo_color == Look.BODY, "all 60 share one material, in BODY")
	check(a.rng.seed == 1968, "after the build the generator still holds the seed it was given: %d" % a.rng.seed)
	var line := "seed 1968, amplitude 20.0: the last cube turned (-5.9, 19.9, 17.2)"
	check(printed.slice(before).has(line), "it printed `%s`: %s" % [line, printed.slice(before)])
	measured["printed_line"] = line
	# In order where the amount is 0.
	var in_order := true
	for z in 5:
		var cube: Node3D = a.get_child(z)
		if not cube.transform.is_equal_approx(Transform3D(Basis(), Vector3(0.0, 0.25, z * 0.6))):
			in_order = false
	check(in_order, "the first column is in order at amplitude 20: its amount is 0")
	# Inside the limits everywhere, and disturbed in the middle of the floor.
	var inside := true
	var middle := 0.0
	for i in 60:
		var cube: Node3D = a.get_child(i)
		@warning_ignore("integer_division")
		var amount := float(i / 5) / 11.0
		var turn := deg_to_rad(20.0) * amount + 0.00001
		var slide := 0.25 * 20.0 / 90.0 * amount + 0.00001
		var home := home_of(a, i)
		if absf(cube.rotation.x) > turn or absf(cube.rotation.y) > turn or absf(cube.rotation.z) > turn:
			inside = false
		if absf(cube.position.x - home.x) > slide or absf(cube.position.z - home.z) > slide or not is_equal_approx(cube.position.y, 0.25):
			inside = false
		@warning_ignore("integer_division")
		if i / 5 == 6:
			middle = maxf(middle, absf(cube.rotation_degrees.y))
	check(inside, "no cube turns or slides further than its column allows, and every middle stays at 0.25 m")
	check(middle > 1.0 and middle <= 20.0 * 6.0 / 11.0 + 0.001, "column 6 is disturbed, and by less than the last: the amount grows with every column (its largest turn about y: %.1f degrees of %.1f allowed)" % [middle, 20.0 * 6.0 / 11.0])
	var last := []
	for z in 5:
		last.append(a.get_child(55 + z).rotation.snappedf(0.0001))
	var different := true
	for i in 5:
		for j in range(i + 1, 5):
			if last[i] == last[j]:
				different = false
	check(different, "the five cubes of the last column are turned five different ways: each cube has draws of its own")
	var follow := true
	for cube: Node3D in a.get_children():
		if not cube.get_node("Body").global_transform.is_equal_approx(cube.global_transform):
			follow = false
	check(follow, "the colliders follow the cubes: every Body stands and is turned exactly as its mesh")
	# The seed.
	var b := await built(20.0, 1968)
	check(same(transforms_of(a), transforms_of(b)), "the same seed returns the same floor: 60 of 60 cubes stand alike in two builds")
	var c := await built(20.0, 1969)
	check(not same(transforms_of(a), transforms_of(c)), "seed 1969 is another floor")
	var kept := transforms_of(a)
	a.build()
	check(a.get_child_count() == 60 and same(kept, transforms_of(a)), "build() called again leaves 60 cubes, the same 60: the old ones are freed first")
	# The amplitude only scales what the seed drew.
	var five := await built(5.0, 1968)
	var scaled := true
	var worst := 0.0
	for i in 60:
		var small: Vector3 = five.get_child(i).rotation
		var large: Vector3 = a.get_child(i).rotation
		worst = maxf(worst, (large - small * 4.0).length())
		if (large - small * 4.0).length() > 0.0001:
			scaled = false
	check(scaled, "at one seed, amplitude 20 turns every cube exactly four times as far as amplitude 5, the same way (largest miss: %.6f radians)" % worst)
	var zero := await built(0.0, 1968)
	var flat := true
	for i in 60:
		if not zero.get_child(i).transform.is_equal_approx(Transform3D(Basis(), home_of(zero, i))):
			flat = false
	check(flat, "amplitude 0 is the floor in order, whatever the seed")
	for made: Node3D in [a, b, c, five, zero]:
		made.free()
	# Space: the next seed.
	var scene: Node3D = load("res://schotter.tscn").instantiate()
	root.add_child(scene)
	var mark := errors.size()
	await frames(180)
	var running: Node3D = scene.get_node("Schotter")
	check(errors.size() == mark and running.get_child_count() == 60, "schotter.tscn ran 180 frames with no error, 60 cubes on the floor")
	check(scene.get_node("Look/Sky").environment.background_color == Look.SKY and scene.get_node("Floor").material_override.albedo_color == Look.GROUND and scene.get_node_or_null("Look/Sun") != null,
		"the scene wears the look: SKY, GROUND and the sun")
	var walker: CharacterBody3D = scene.get_node("Walker")
	check(absf(walker.global_position.y - 0.5) < 0.01 and absf(walker.global_position.x + 3.3) < 0.01, "the walker stands on the first column, its feet at %.2f m" % walker.global_position.y)
	var was := transforms_of(running)
	before = printed.size()
	await press("pause")
	await frames(2)
	var said := printed.slice(before)
	measured["space_printed"] = said
	var next := await built(20.0, 1969)
	check(running.seed_value == 1969 and running.get_child_count() == 60 and not same(was, transforms_of(running)) and same(transforms_of(running), transforms_of(next))
			and said == ["seed 1969, amplitude 20.0: the last cube turned (-8.8, -2.6, -13.8)"],
		"Space makes the next floor: seed 1969, 60 cubes, the same floor a fresh build of 1969 gives, and it printed %s" % [said])
	check(absf(walker.global_position.y - 0.5) < 0.01, "and the walker still stands on the first column, which is in order under every seed")
	next.free()
	scene.free()
	await frames(2)

# ---------------------------------------------------------------- chance, the planted bug, three silent faults

## schotter.gd with something changed in its text, compiled here and not saved.
## Each change is [what stands in the file, what stands there instead].
func variant(changes: Array) -> GDScript:
	var source := FileAccess.get_file_as_string("res://schotter.gd")
	for change: Array in changes:
		if source.count(change[0]) != 1:
			return null
		source = source.replace(change[0], change[1])
	var script := GDScript.new()
	script.source_code = source
	if script.reload() != OK:
		return null
	return script

func build_of(script: GDScript) -> Node3D:
	var made: Node3D = script.new()
	root.add_child(made)
	await process_frame
	return made

func chance() -> void:
	# Without a seed: the lesson's second step, built twice.
	var before := printed.size()
	var a := await build_of(load("res://steps/02-chance.gd"))
	var b := await build_of(load("res://steps/02-chance.gd"))
	var lines := printed.slice(before)
	measured["two_builds_without_a_seed"] = lines
	check(lines.size() == 2 and lines[0] != lines[1] and not same(transforms_of(a), transforms_of(b)), "without a seed two builds are two floors, with nothing in the script that asks for it: %s" % [lines])
	a.free()
	b.free()
	# The planted bug: randomize() under the seed line.
	var errors_before := errors.size()
	var warnings_before := warnings.size()
	var seed_line := "	rng.seed = seed_value
"
	var bug := variant([[seed_line, seed_line + "	rng.randomize()
"]])
	check(bug != null, "the planted bug compiles: schotter.gd with rng.randomize() under its seed line")
	if bug != null:
		before = printed.size()
		var c := await build_of(bug)
		var d := await build_of(bug)
		lines = printed.slice(before)
		measured["two_builds_with_randomize_under_the_seed_line"] = {"printed": lines, "seed_value_reads": [c.seed_value, d.seed_value], "note": "these two lines are different in every run of verify.gd: that is the fault"}
		check(c.rng.seed != 1968 and d.rng.seed != 1968 and c.seed_value == 1968 and d.seed_value == 1968 and not same(transforms_of(c), transforms_of(d)),
			"the planted bug: the generator no longer holds 1968 while seed_value still reads 1968, and two builds are two floors: %s" % [lines])
		check(errors.size() == errors_before and warnings.size() == warnings_before, "and Godot logged no error and no warning about it")
		c.free()
		d.free()
	# The seed line moved into the inner loop.
	var part_line := "			var cube: MeshInstance3D = part.instantiate()
"
	var looped := variant([[seed_line, ""], [part_line, "			rng.seed = seed_value
" + part_line]])
	var said := ""
	var alike := false
	if looped != null:
		before = printed.size()
		var e := await build_of(looped)
		said = printed.slice(before)[0]
		alike = true
		for z in 5:
			if not e.get_child(55 + z).basis.is_equal_approx(e.get_child(55).basis):
				alike = false
		e.free()
	measured["seed_line_in_the_inner_loop"] = said
	check(alike and said == "seed 1968, amplitude 20.0: the last cube turned (-1.3, -5.8, -10.5)", "with the seed line in the inner loop the five cubes of a column are turned exactly alike: `%s`" % said)
	# One draw nobody uses.
	var extra := variant([[seed_line, seed_line + "	rng.randf()
"]])
	said = ""
	if extra != null:
		before = printed.size()
		var f := await build_of(extra)
		said = printed.slice(before)[0]
		f.free()
	measured["one_unused_draw"] = said
	check(said == "seed 1968, amplitude 20.0: the last cube turned (19.9, 17.2, 4.8)", "one unused draw under the seed line and the same seed is another floor, every number moved one place along: `%s`" % said)
	# float() taken away.
	warnings_before = warnings.size()
	var whole := variant([["var amount := float(x) / (columns - 1)", "var amount := x / (columns - 1)"]])
	said = ""
	var orderly := 0
	if whole != null:
		before = printed.size()
		var g := await build_of(whole)
		said = printed.slice(before)[0]
		for x in 12:
			var still := true
			for z in 5:
				if not g.get_child(x * 5 + z).transform.is_equal_approx(Transform3D(Basis(), home_of(g, x * 5 + z))):
					still = false
			if still:
				orderly += 1
		g.free()
	measured["without_float"] = {"printed": said, "columns_in_order": orderly, "warnings_logged": warnings.slice(warnings_before)}
	check(orderly == 11 and said == measured["printed_line"], "without float() eleven columns stand in order and the printed line is the same as the right one: `%s`" % said)

# ---------------------------------------------------------------- the argument, as geometry

func argument() -> void:
	var rows := {}
	for value: float in VALUES:
		var made := await built(value, 1968)
		var counts := left_cell(made)
		rows["%d" % value] = {
			"cubes_out_of_their_cell": total(counts), "first_column_with_one": first_column(counts), "by_column": counts,
			"a_corner_moved_at_most_m": snappedf(corner_moved(made), 0.001),
		}
		made.free()
	measured["amplitudes"] = rows
	check(rows["0"]["cubes_out_of_their_cell"] == 0 and rows["5"]["cubes_out_of_their_cell"] == 0,
		"seen from above, at 0 and at 5 degrees no cube has a corner over the middle of a gap (at 5 degrees a corner moved at most %.3f m; the gap is 0.1 m)" % rows["5"]["a_corner_moved_at_most_m"])
	check(rows["20"]["cubes_out_of_their_cell"] > 0 and rows["90"]["cubes_out_of_their_cell"] > rows["20"]["cubes_out_of_their_cell"],
		"at 20 degrees %d of 60 cubes have a corner over the middle of a gap, the first in column %d; at 90 degrees %d, the first in column %d" % [
			rows["20"]["cubes_out_of_their_cell"], rows["20"]["first_column_with_one"], rows["90"]["cubes_out_of_their_cell"], rows["90"]["first_column_with_one"]])
	# For ten seeds: the smallest whole amplitude at which a cube leaves its cell.
	var firsts := []
	for seed_value in range(1968, 1978):
		var found := -1
		for degrees in range(1, 91):
			var made := await built(float(degrees), seed_value)
			var out := total(left_cell(made))
			made.free()
			if out > 0:
				found = degrees
				break
		firsts.append(found)
	var sorted := firsts.duplicate()
	sorted.sort()
	measured["first_cube_leaves_its_cell_at_degrees"] = {"seeds": "1968 to 1977", "each": firsts, "lowest": sorted[0], "highest": sorted[-1]}
	check(sorted[0] >= 5 and sorted[-1] <= 7, "with ten seeds, 1968 to 1977, the first cube puts a corner over the middle of a gap at an amplitude of %d to %d degrees, counted in whole degrees: %s" % [sorted[0], sorted[-1], firsts])

# ---------------------------------------------------------------- place: a body on the floor

## Sends the walker down the middle row of a floor and says what happened.
func cross(amplitude: float, seed_value: int, step_height := 0.35, spacing := 0.6) -> Dictionary:
	var scene: Node3D = load("res://schotter.tscn").instantiate()
	var made: Node3D = scene.get_node("Schotter")
	made.amplitude = amplitude
	made.seed_value = seed_value
	made.spacing = spacing
	var walker: CharacterBody3D = scene.get_node("Walker")
	walker.step_height = step_height
	walker.position = Vector3(-3.3, 0.5, -1.2 + 2.0 * spacing)   # on the first column, in the middle row
	root.add_child(scene)
	await physics_frames(10)
	var low := walker.global_position.y
	var high := low
	walker.walk_to([Vector3(-3.3 + 11.0 * spacing, 0.0, -1.2 + 2.0 * spacing)])
	var steps := 0
	while walker.walking:
		await physics_frame
		steps += 1
		low = minf(low, walker.global_position.y)
		high = maxf(high, walker.global_position.y)
	await process_frame
	var at := walker.global_position
	var result := {
		"amplitude": amplitude, "seed": seed_value, "step_height": step_height, "spacing": spacing, "walk_ended": walker.ended,
		"at_column": snappedf((at.x + 3.3) / spacing, 0.1), "feet_lowest_m": snappedf(low, 0.01), "feet_highest_m": snappedf(high, 0.01), "physics_steps": steps,
	}
	scene.queue_free()
	await frames(2)
	return result

func told(walk: Dictionary) -> String:
	return "\"%s\" at column %.1f, its feet between %.2f and %.2f m" % [walk["walk_ended"], walk["at_column"], walk["feet_lowest_m"], walk["feet_highest_m"]]

func place() -> void:
	var walks := []
	var arrived := 0
	for value: float in VALUES:
		var walk := await cross(value, 1968)
		walks.append(walk)
		if walk["walk_ended"] == "arrived":
			arrived += 1
		if value == 0.0:
			check(walk["walk_ended"] == "arrived" and walk["feet_lowest_m"] == 0.5 and walk["feet_highest_m"] == 0.5, "the walker crosses the floor in order on the cubes' tops: %s" % told(walk))
		else:
			check(walk["walk_ended"] == "arrived" and walk["feet_highest_m"] > 0.5, "at %d degrees the walker crosses too, and the cubes under it are not level: %s" % [value, told(walk)])
	for seed_value in range(1969, 1973):
		var walk := await cross(90.0, seed_value)
		walks.append(walk)
		if walk["walk_ended"] == "arrived":
			arrived += 1
	check(arrived == 8, "8 of 8 walks arrived: the four amplitudes at seed 1968, and 90 degrees at seeds 1969 to 1972. No amplitude made this floor unwalkable for this walker (%d arrived)" % arrived)
	measured["walks"] = walks
	# What does stop a body: gaps, and a body that cannot step.
	var wide := []
	for value: float in [0.0, 20.0, 90.0]:
		wide.append(await cross(value, 1968, 0.35, 0.8))
	var wide_stopped := 1 if wide[2]["walk_ended"] == "blocked" else 0
	for seed_value in range(1969, 1973):
		var walk := await cross(90.0, seed_value, 0.35, 0.8)
		wide.append(walk)
		if walk["walk_ended"] == "blocked":
			wide_stopped += 1
	measured["walks_with_spacing_0.8"] = wide
	check(wide[0]["walk_ended"] == "arrived" and wide[2]["walk_ended"] == "blocked",
		"with the spacing at 0.8 m, gaps of 0.3 m, the walker crosses the floor in order (%s) and is stopped at 90 degrees (%s); at 20 degrees: %s" % [told(wide[0]), told(wide[2]), told(wide[1])])
	check(wide_stopped > 0 and wide_stopped < 5, "with those gaps, 90 degrees stops the walker under %d of the 5 seeds 1968 to 1972 and lets it cross under the others: the seed decides" % wide_stopped)
	var bare := []
	var stopped := 0
	for seed_value in range(1968, 1973):
		var walk := await cross(90.0, seed_value, 0.0)
		bare.append(walk)
		if walk["walk_ended"] == "blocked":
			stopped += 1
	var bare_low := await cross(20.0, 1968, 0.0)
	bare.append(bare_low)
	measured["walks_without_a_step"] = bare
	check(stopped > 0 and stopped < 5 and bare_low["walk_ended"] == "arrived",
		"a walker that cannot step up (step_height 0) is stopped at 90 degrees under %d of the 5 seeds 1968 to 1972 and crosses under the others; at 20 degrees, seed 1968: %s" % [stopped, told(bare_low)])

# ---------------------------------------------------------------- the maze

func maze_of(seed_value: int) -> Node3D:
	var made = Maze.new()
	made.seed_value = seed_value
	root.add_child(made)
	await process_frame
	return made

## A wall leans 1 ("/" seen from above, north at the top): it shuts west and
## north from east and south. A wall that leans -1 ("\") shuts west and south
## from north and east. So a body that comes into a cell through one side
## leaves it through exactly one other.
func way_out(lean: int, side: int) -> int:
	if lean == 1:
		return [NORTH, WEST, SOUTH, EAST][side]
	return [SOUTH, EAST, NORTH, WEST][side]

func middle_of(made: Node3D, x: int, z: int, side: int, beyond := 0.0) -> Vector3:
	var half: float = made.cell / 2.0 + beyond
	var local := Vector3((x + 0.5) * made.cell, 0.0, (z + 0.5) * made.cell)
	local += [Vector3(-half, 0, 0), Vector3(0, 0, -half), Vector3(half, 0, 0), Vector3(0, 0, half)][side]
	return made.to_global(local)

## The corridor that begins at side `side` of cell (x, z), on the maze's edge:
## how many cells it runs through, where it leaves the maze, and the points to walk.
func corridor(made: Node3D, x: int, z: int, side: int) -> Dictionary:
	var points := [middle_of(made, x, z, side, 0.25), middle_of(made, x, z, side)]
	var cells := 0
	while true:
		cells += 1
		var out := way_out(made.leans[z * made.columns + x], side)
		points.append(middle_of(made, x, z, out))
		var nx: int = x + [-1, 0, 1, 0][out]
		var nz: int = z + [0, -1, 0, 1][out]
		if nx < 0 or nx >= made.columns or nz < 0 or nz >= made.rows:
			points.append(middle_of(made, x, z, out, 0.25))
			return {"cells": cells, "out_side": out, "out": "%s of cell (%d, %d)" % [SIDES[out], x, z], "points": points}
		x = nx
		z = nz
		side = [EAST, SOUTH, WEST, NORTH][out]
	return {}

## Every opening on the maze's edge, as [x, z, side].
func openings(made: Node3D) -> Array:
	var out := []
	for z in made.rows:
		out.append([0, z, WEST])
		out.append([made.columns - 1, z, EAST])
	for x in made.columns:
		out.append([x, 0, NORTH])
		out.append([x, made.rows - 1, SOUTH])
	return out

## How many corridors of a maze lead from its west side to its east side.
func crossings(made: Node3D) -> int:
	var count := 0
	for z in made.rows:
		if corridor(made, 0, z, WEST)["out_side"] == EAST:
			count += 1
	return count

func drawn(made: Node3D) -> Array:
	var lines := []
	for z in made.rows:
		var line := ""
		for x in made.columns:
			line += "/" if made.leans[z * made.columns + x] == 1 else "\\"
		lines.append(line)
	return lines

func maze() -> void:
	var before := printed.size()
	var a := await maze_of(1982)
	check(a.get_child_count() == 24 and a.leans.size() == 24 and a.leans.count(1) + a.leans.count(-1) == 24, "maze.gd builds 24 walls, 6 by 4 cells, and keeps how each leans")
	var turned := true
	var solid := true
	for i in 24:
		var wall: MeshInstance3D = a.get_child(i)
		if not is_equal_approx(wall.rotation_degrees.y, 45.0 * a.leans[i]) or not is_equal_approx(wall.position.y, 1.0):
			turned = false
		if wall.find_children("*", "StaticBody3D", true, false).is_empty():
			solid = false
	check(turned, "every wall is turned by one of two angles, 45 or -45 degrees, as its entry in `leans` says")
	check(solid, "every wall has a StaticBody3D")
	var picture := drawn(a)
	measured["maze_1982"] = picture
	var line := "seed 1982: 9 walls lean one way, 15 the other"
	check(printed.slice(before).has(line) and picture == ["/\\\\\\\\/", "\\\\/\\//", "//\\/\\\\", "/\\\\\\\\\\"], "seed 1982 is this maze, and it printed `%s`: %s" % [line, picture])
	var b := await maze_of(1982)
	var c := await maze_of(1983)
	check(a.leans == b.leans and a.leans != c.leans, "the same seed returns the same maze; seed 1983 is another")
	b.free()
	c.free()
	# The corridors, by rule.
	var found := []
	var inside := 0
	var longest := {}
	for opening: Array in openings(a):
		var run := corridor(a, opening[0], opening[1], opening[2])
		inside += run["cells"]
		if longest.is_empty() or run["cells"] > longest["cells"]:
			longest = run
			longest["in"] = "%s of cell (%d, %d)" % [SIDES[opening[2]], opening[0], opening[1]]
		found.append("%s of (%d, %d) -> %d cells -> %s" % [SIDES[opening[2]], opening[0], opening[1], run["cells"], run["out"]])
	@warning_ignore("integer_division")
	var corridors: int = found.size() / 2      # each corridor was followed from both its ends
	@warning_ignore("integer_division")
	var shut: int = 48 - inside / 2            # triangles of floor that no corridor reaches
	measured["maze_1982_corridors"] = {"openings": found.size(), "corridors": corridors, "west_to_east": crossings(a), "triangles_no_corridor_reaches": shut, "each": found,
		"longest": {"in": longest["in"], "cells": longest["cells"], "out": longest["out"]}}
	check(found.size() == 20 and corridors == 10 and crossings(a) == 0, "seed 1982 has 20 openings and 10 corridors, and none of them leads from the west side to the east side")
	check(shut == 4, "4 of its 48 triangles of floor are reached by no corridor: one room with no door")
	# A body in it.
	var scene: Node3D = load("res://maze.tscn").instantiate()
	root.add_child(scene)
	var mark := errors.size()
	await frames(180)
	var running: Node3D = scene.get_node("Maze")
	check(errors.size() == mark and running.leans == a.leans, "maze.tscn ran 180 frames with no error and shows the maze of seed 1982")
	var walker: CharacterBody3D = scene.get_node("Walker")
	var from := walker.global_position
	var how := await walk(walker, [Vector3(3.65, 0.0, from.z)])
	measured["maze_straight_walk"] = {"walk_ended": how, "metres_walked": snappedf(walker.global_position.x - from.x, 0.01)}
	check(how == "blocked" and walker.global_position.x < -2.0, "sent straight across, the walker is stopped by the first wall, %.2f m from where it started" % (walker.global_position.x - from.x))
	var run := corridor(running, 0, 3, WEST)
	walker.stand_at(run["points"][0])
	await physics_frames(5)
	how = await walk(walker, run["points"])
	var end: Vector3 = run["points"][-1]
	var miss := Vector2(walker.global_position.x - end.x, walker.global_position.z - end.z).length()
	measured["maze_corridor_walk"] = {"in": "west of cell (0, 3)", "cells": run["cells"], "out": run["out"], "walk_ended": how, "metres_from_the_way_out": snappedf(miss, 0.01)}
	check(how == "arrived" and miss < 0.15 and run["cells"] == 11 and run["out"] == "north of cell (1, 0)", "led along the longest corridor, in at the west of row 3, the walker comes out at the north of column 1 after 11 cells: \"%s\"" % how)
	scene.free()
	a.free()
	await frames(2)
	# Which seeds can be crossed?
	var crossable := []
	for seed_value in range(1982, 2082):
		var made := await maze_of(seed_value)
		if crossings(made) > 0:
			crossable.append(seed_value)
		made.free()
	measured["mazes_with_a_way_from_west_to_east"] = {"seeds": "1982 to 2081", "count": crossable.size(), "first": crossable[0] if not crossable.is_empty() else -1, "which": crossable}
	check(not crossable.is_empty() and crossable.size() < 100, "of the 100 seeds 1982 to 2081, %d give a maze with a corridor from the west side to the east side; the first is %d" % [crossable.size(), crossable[0] if not crossable.is_empty() else -1])
	if crossable.is_empty():
		return
	scene = load("res://maze.tscn").instantiate()
	scene.get_node("Maze").seed_value = crossable[0]
	root.add_child(scene)
	await frames(5)
	running = scene.get_node("Maze")
	walker = scene.get_node("Walker")
	for z in running.rows:
		run = corridor(running, 0, z, WEST)
		if run["out_side"] == EAST:
			walker.stand_at(run["points"][0])
			await physics_frames(5)
			how = await walk(walker, run["points"])
			measured["maze_crossing_walk"] = {"seed": crossable[0], "corridors_from_west_to_east": crossings(running), "in": "west of cell (0, %d)" % z, "cells": run["cells"], "out": run["out"], "walk_ended": how}
			check(how == "arrived" and walker.global_position.x > 3.3 and crossings(running) == 1, "the maze of seed %d has one corridor from the west side to the east side, and the walker walks it, %d cells, without one choice to make: \"%s\"" % [crossable[0], run["cells"], how])
			break
	scene.free()
	await frames(2)

# ---------------------------------------------------------------- the guest

func guest() -> void:
	var folder := "res://guests/disturbed-order/"
	var needs := CheckGuest.outside(folder)
	check(needs.is_empty(), "the guest names nothing outside its folder: %s" % [needs])
	check(CheckGuest.class_names(folder).is_empty(), "the guest declares no class_name")
	var scene: PackedScene = load(folder + "disturbed-order.tscn")
	var before := printed.size()
	var a: Node3D = scene.instantiate()
	root.add_child(a)
	await process_frame
	check(a.get_child_count() == 25 and printed.slice(before).has("Disturbed order: seed 1968, amplitude 45.0"), "the guest is 25 cubes and says which: `Disturbed order: seed 1968, amplitude 45.0`")
	var wild: Node3D = scene.instantiate()
	wild.amplitude = 90.0
	root.add_child(wild)
	await process_frame
	var reach := 0.0
	var lowest := 0.0
	for made: Node3D in [a, wild]:
		for cube: Node3D in made.get_children():
			for corner: Vector3 in corners_of(cube.transform, 0.1):
				reach = maxf(reach, maxf(absf(corner.x), absf(corner.z)))
				lowest = minf(lowest, corner.y)
	measured["guest"] = {"reaches_from_its_middle_m": snappedf(reach, 0.001), "lowest_corner_m": snappedf(lowest, 0.001)}
	check(reach <= 0.8, "it fits in a box 1.6 m wide and deep, at amplitude 45 and at 90: no corner is further than %.3f m from its middle" % reach)
	var first: Node3D = a.get_child(0)
	check(is_equal_approx(first.position.y, 0.1) and first.rotation == Vector3.ZERO, "its first column stands in order on the ground; a turned cube dips under it, by %.3f m at most" % -lowest)
	var b: Node3D = scene.instantiate()
	root.add_child(b)
	await process_frame
	check(same(transforms_of(a), transforms_of(b)), "the same seed returns the same patch")
	# The room's task: another seed, typed into the guest's own script.
	var other: Node3D = scene.instantiate()
	other.seed_value = 2026
	before = printed.size()
	root.add_child(other)
	await process_frame
	var told_seed := printed.slice(before)
	measured["guest"]["at_seed_2026_printed"] = told_seed
	check(other.get_child_count() == 25 and not same(transforms_of(a), transforms_of(other)) and told_seed == ["Disturbed order: seed 2026, amplitude 45.0"],
		"seed 2026 is another patch of 25 cubes, and it says so: %s" % [told_seed])
	other.free()
	b.free()
	wild.free()
	a.free()
	# A body meets it.
	var room: Node3D = load("res://supplied/base.tscn").instantiate()
	var met: Node3D = scene.instantiate()
	room.add_child(met)
	var walker: CharacterBody3D = load("res://supplied/walker.tscn").instantiate()
	walker.position = Vector3(0.0, 0.0, 2.0)
	room.add_child(walker)
	root.add_child(room)
	await physics_frames(10)
	var how := await walk(walker, [Vector3.ZERO])
	measured["guest"]["walker_sent_to_its_middle"] = {"walk_ended": how, "feet_at_m": snappedf(walker.global_position.y, 0.01), "metres_from_the_middle": snappedf(Vector2(walker.global_position.x, walker.global_position.z).length(), 0.01)}
	check(how == "arrived" and walker.global_position.y > 0.15, "a walker sent to its middle steps onto it: \"%s\", its feet at %.2f m" % [how, walker.global_position.y])
	room.free()
	await frames(2)

# ---------------------------------------------------------------- the recovery points

func steps() -> void:
	var loaded := 0
	for file: String in STEPS:
		var script: Resource = load("res://steps/" + file)
		if script is GDScript and script.can_instantiate():
			var made: Node3D = script.new()
			root.add_child(made)
			await process_frame
			if made.get_child_count() == 60:
				loaded += 1
			made.free()
	check(loaded == STEPS.size(), "the %d recovery points in steps/ each build a floor of 60 cubes (%d did)" % [STEPS.size(), loaded])
	check(FileAccess.get_file_as_string("res://steps/" + STEPS[-1]) == FileAccess.get_file_as_string("res://schotter.gd"), "the last recovery point is schotter.gd, byte for byte")
