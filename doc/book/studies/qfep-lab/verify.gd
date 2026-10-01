extends "res://supplied/verify_tools.gd"
## The checks of the QFEP laboratory. From this folder:
##   godot --headless --path . --xr-mode off --script res://verify.gd
## (add --fixed-fps 60 and the walks and glides take seconds instead of a minute).
## It builds the row of 200 symbols and the prediction log from the learner's
## two scripts, reads back what was built, sorts the row four ways, counts its
## entropy each time, plants the lesson's bug, walks the supplied walker along
## the log, and writes verification.json. Every number the lesson quotes about
## a count, an entropy or a walk is in `measured` there. What the bars do on
## the screen is not checked here: headless draws nothing. sheet.gd reads the
## bars back, with a window.

const CheckGuest := preload("res://supplied/check_guest.gd")
const Look := preload("res://supplied/look.gd")
const Row := preload("res://row.gd")
const FCurve := preload("res://f_curve.gd")
const Segment := preload("res://supplied/segment.gd")

const FIRST := [2, 6, 6, 3, 8, 4, 2, 6, 1, 8, 0, 6]                # the row of seed 40 begins so
const COUNTS := [21, 18, 22, 14, 25, 18, 17, 16, 26, 23]          # how often 0 to 9 occur in it
const MET := [2, 6, 3, 8, 4, 1, 0, 5, 7, 9]                       # the order in which the row meets its symbols
const SKIP := "\t\tif c == 0:\n\t\t\tcontinue   # a symbol that never occurs adds nothing\n"
const TIES := "	return a < b   # two equal symbols keep the order they were drawn in"
const GUEST := "res://guests/qfep-lab/"

var lab: Node3D
var expected_errors := 0   # the errors this run provokes on purpose

func run() -> void:
	project()
	await draws()
	arrangements()
	await glide()
	await bug()
	numbers()
	await curve()
	await place()
	await guest()
	steps()
	for file: String in ["qfep_three.json", "qfep_broken.json", "qfep_no_key.json"]:   # the logs this run wrote for its own trials
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://" + file))
	var logged := []
	for line in errors:
		logged.append(line.get_slice(" (gdscript", 0))
	check(errors.size() == expected_errors, "from the first check to the last Godot logged no error but the %d this run provoked on purpose: %s" % [expected_errors, logged])

# ---------------------------------------------------------------- the project

func project() -> void:
	check(ProjectSettings.get_setting("application/config/name") == "The QFEP laboratory" and ProjectSettings.get_setting("application/run/main_scene") == "res://lab.tscn",
		"the project is The QFEP laboratory and starts with lab.tscn")
	var supplied := ["base.tscn", "base_look.gd", "check_guest.gd", "look.gd", "marble.gd", "marble.tscn", "mover.gd", "segment.gd", "sheet_tools.gd", "sweep_sheet.gd", "sweep_sheet.tscn", "trace_strip.gd", "verify_tools.gd", "walker.gd", "walker.tscn"]
	var missing := []
	for file: String in supplied:
		if not FileAccess.file_exists("res://supplied/" + file):
			missing.append(file)
	check(missing.is_empty(), "the 15 supplied files are here: %s" % [missing])
	var spaced := []
	var named := []
	var returns := []
	for path: String in ["res://row.gd", "res://f_curve.gd", "res://verify.gd", "res://sheet.gd", GUEST + "qfep-lab.gd"]:
		var text := FileAccess.get_file_as_string(path)
		if text.contains("\r"):
			returns.append(path)
		for line in text.split("\n"):
			if line.begins_with(" "):
				spaced.append(path)
				break
			if line.begins_with("class_name"):
				named.append(path)
	check(spaced.is_empty() and returns.is_empty(), "the kit's five scripts are indented with tabs and end their lines with LF: %s %s" % [spaced, returns])
	check(named.is_empty(), "none of them declares a class_name: %s" % [named])
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://sketchbook.json"))
	var whole: bool = data is Dictionary and data.get("entries") is Array and data["entries"].size() >= 2
	if whole:
		for entry in data["entries"]:
			whole = whole and entry is Dictionary and entry.get("chapter") is String and entry.get("predicted") is float and entry.get("observed") is float
	check(whole, "sketchbook.json is a log: a list `entries`, each with a chapter, a predicted and an observed number")
	measured["log_entries"] = data["entries"].size() if whole else 0

# ---------------------------------------------------------------- 200 draws

func new_row(seed_value: int, count: int, script: Script = Row) -> Node3D:
	var row := Node3D.new()
	row.set_script(script)
	row.seed_value = seed_value
	row.count = count
	root.add_child(row)
	return row

func draws() -> void:
	var before := errors.size()
	lab = load("res://lab.tscn").instantiate()
	root.add_child(lab)
	await frames(180)
	check(errors.size() == before, "lab.tscn ran 180 frames and Godot logged no error: %s" % [errors])
	check(lab.has_node("Row") and lab.has_node("Curve") and lab.has_node("Walker") and lab.has_node("Look/Sun") and lab.get_node("Row").get_script() == Row and lab.get_node("Curve").get_script() == FCurve,
		"the scene is the supplied base with three nodes of its own: Row runs row.gd, Curve runs f_curve.gd, Walker is the supplied walker")
	var row: Node3D = lab.get_node("Row")
	var inside := true
	for v in row.values:
		inside = inside and v >= 0 and v <= 9
	check(row.values.size() == 200 and inside, "the row holds 200 symbols, each a whole number from 0 to 9")
	check(Array(row.values.slice(0, 12)) == FIRST, "under seed 40 the row begins %s" % [row.values.slice(0, 12)])
	var line := "as drawn: H = 3.296 bits; the row begins [2, 6, 6, 3, 8, 4, 2, 6, 1, 8, 0, 6]"
	check(printed.has(line), "and the scene printed `%s`" % line)
	check(row.readout.text == "as drawn: H = 3.296 bits", "the label over the row reads `%s`" % row.readout.text)
	var counts: Dictionary = row.tally(row.values)
	var by_symbol := []
	var total := 0
	for s in 10:
		by_symbol.append(counts.get(s, 0))
		total += counts.get(s, 0)
	check(by_symbol == COUNTS and total == 200, "tally() counts 0 to 9 as %s, 200 in all" % [by_symbol])
	check(counts.keys() == MET, "the dictionary keeps its keys in the order the row met them: %s" % [counts.keys()])
	var h: float = row.entropy(row.values)
	var most := log(10.0) / log(2.0)
	check(absf(h - 3.2958408839961857) < 1e-9 and h < most, "entropy() gives %.6f bits, under the most ten symbols can give, %.6f" % [h, most])
	measured["counts_0_to_9"] = by_symbol
	measured["keys_in_the_order_met"] = counts.keys()
	measured["entropy_bits"] = h
	measured["entropy_at_most_bits"] = most
	var twin := new_row(40, 200)
	var other := new_row(41, 200)
	await frames(2)
	var apart := 0
	for i in 200:
		if other.values[i] != row.values[i]:
			apart += 1
	check(twin.values == row.values and apart > 100, "the same seed draws the same row; seed 41 draws another (%d of 200 places differ)" % apart)
	measured["seed_41_entropy_bits"] = other.entropy(other.values)
	twin.free()
	other.free()
	var bars: MultiMesh = row.bars
	var paint: StandardMaterial3D = bars.mesh.material
	check(bars.instance_count == 200 and bars.use_colors and bars.mesh is BoxMesh and bars.mesh.size.is_equal_approx(Vector3(0.02, 1.0, 0.3)) and paint.vertex_color_use_as_albedo,
		"the body is one MultiMesh of 200 boxes of 0.02 x 1 x 0.3 m whose material takes each instance's colour")
	var wall: CollisionShape3D = null
	for child in row.get_children():
		if child is StaticBody3D:
			wall = child.get_child(0)
	check(wall != null and wall.shape is BoxShape3D and wall.shape.size.is_equal_approx(Vector3(4.0, 1.0, 0.3)), "for a body the row is one box of 4 x 1 x 0.3 m")

# ---------------------------------------------------------------- four arrangements

func runs_of(symbols: PackedInt32Array) -> int:
	var runs := 1
	for i in range(1, symbols.size()):
		if symbols[i] != symbols[i - 1]:
			runs += 1
	return runs

func arrangements() -> void:
	var row: Node3D = lab.get_node("Row")
	var sorted: PackedInt32Array = row.values.duplicate()
	sorted.sort()
	var reversed := sorted.duplicate()
	reversed.reverse()
	var h := []
	var same_symbols := true
	var whole_orders := true
	var stable := true
	var rows := []
	var moved := {}
	var runs := {}
	for how in 4:
		row.arrange(how, 0.0)
		var now: PackedInt32Array = row.row()
		rows.append(now)
		h.append(row.entropy(now))
		var again := now.duplicate()
		again.sort()
		same_symbols = same_symbols and again == sorted
		var places: Array = row.order.duplicate()
		places.sort()
		whole_orders = whole_orders and places == range(200)
		var changed := 0
		for i in 200:
			whole_orders = whole_orders and row.order[row.goes_to[i]] == i
			if row.goes_to[i] != i:
				changed += 1
			if i > 0 and now[i] == now[i - 1] and row.order[i] < row.order[i - 1]:
				stable = false
		moved[Row.NAMES[how]] = changed
		runs[Row.NAMES[how]] = runs_of(now)
	check(same_symbols, "each of the four arrangements holds the same 200 symbols: sorted again, all four are one list")
	check(whole_orders, "`order` names every draw once, and `goes_to` is the same list read the other way")
	check(rows[0] == row.values, "as drawn, the row is the list of draws")
	check(rows[1] == sorted, "sorted by value, the row is what sort() makes of the draws")
	check(rows[3] == reversed, "sorted in reverse, it is that list backwards")
	var by_colour := true
	for i in range(1, 200):
		var a: int = rows[2][i - 1]
		var b: int = rows[2][i]
		by_colour = by_colour and (a % 4 < b % 4 or (a % 4 == b % 4 and a <= b))
	check(by_colour and rows[2][0] == 0 and rows[2][21] == 4 and rows[2][199] == 7, "sorted by colour, the four colours stand in blocks, and inside a block the values rise: 0, 4, 8, then 1, 5, 9, then 2, 6, then 3, 7")
	check(stable, "two equal symbols keep the order they were drawn in, in all four")
	check(h[0] == h[1] and h[1] == h[2] and h[2] == h[3], "the four rows have the same entropy to the last bit: %.17f" % h[0])
	check(printed.has("sorted in reverse: H = 3.296 bits; the row begins [9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9]"), "arrange() printed the line of the reversed row")
	check(runs["as drawn"] > 150 and runs["sorted by value"] == 10 and runs["sorted by colour"] == 10 and runs["sorted in reverse"] == 10,
		"a count that sees order: places where a symbol differs from its left neighbour, plus one: %s" % [runs])
	measured["entropy_of_each_arrangement"] = {"as drawn": "%.17f" % h[0], "sorted by value": "%.17f" % h[1], "sorted by colour": "%.17f" % h[2], "sorted in reverse": "%.17f" % h[3]}
	measured["draws_that_changed_place"] = moved
	measured["runs"] = runs
	row.arrange(0, 0.0)

# ---------------------------------------------------------------- the glide

func glide() -> void:
	var row: Node3D = lab.get_node("Row")
	await press("pause")
	var running: bool = row.gliding != null and row.gliding.is_running()
	check(row.arrangement == 1 and running and Array(row.came_from) == range(200), "Space asks for the next arrangement: sorted by value, a tween is running, and every bar leaves the place it was drawn at")
	check(row.entropy(row.row()) == measured["entropy_bits"] and row.readout.text == "sorted by value: H = 3.296 bits", "the count is made before the glide ends, and is the same")
	var started := Time.get_ticks_msec()
	await row.gliding.finished
	measured["glide_seconds_by_the_clock"] = snappedf((Time.get_ticks_msec() - started) / 1000.0, 0.01)
	check(not row.gliding.is_running(), "the glide ends by itself (%.2f s by the clock; with --fixed-fps the clock runs fast)" % measured["glide_seconds_by_the_clock"])
	await press("pause")
	await press("pause")
	check(row.arrangement == 3 and row.gliding.is_running(), "Space pressed during a glide stops it and starts the next: sorted in reverse")
	await press("pause")
	await row.gliding.finished
	check(row.arrangement == 0 and row.row() == row.values, "a fourth Space brings the row back as it was drawn")

# ---------------------------------------------------------------- the planted bug

func bug() -> void:
	var text := FileAccess.get_file_as_string("res://row.gd")
	check(text.contains(SKIP), "row.gd skips a symbol that never occurs")
	var fault := GDScript.new()
	fault.source_code = text.replace(SKIP, "")
	var compiled := fault.reload()
	var errors_before := errors.size()
	var warnings_before := warnings.size()
	var short := new_row(40, 12, fault)
	await frames(2)
	var h: float = short.entropy(short.values)
	var line := "as drawn: H = -nan bits; the row begins [2, 6, 6, 3, 8, 4, 2, 6, 1, 8, 0, 6]"
	check(compiled == OK and is_nan(h) and h != h, "the planted bug: without the two lines, a row of 12 symbols has an entropy that is not a number (and it does not equal itself)")
	check(printed.has(line) and short.readout.text == "as drawn: H = -nan bits", "it printed `%s`" % line)
	check(errors.size() == errors_before and warnings.size() == warnings_before, "and Godot logged no error and no warning")
	var absent := []
	var counts: Dictionary = short.tally(short.values)
	for s in 10:
		if not counts.has(s):
			absent.append(s)
	check(absent == [5, 7, 9], "three symbols never occur in the first 12 draws: %s" % [absent])
	short.free()
	var long := new_row(40, 200, fault)
	await frames(2)
	check(absf(long.entropy(long.values) - measured["entropy_bits"]) < 1e-12, "with 200 symbols the same faulty script gives 3.296: every symbol occurs, and the fault does not show")
	long.free()
	var mended := new_row(40, 12)
	await frames(2)
	var h12: float = mended.entropy(mended.values)
	check(absf(h12 - 2.584962500721156) < 1e-9 and mended.readout.text == "as drawn: H = 2.585 bits", "row.gd as shipped counts the 12 symbols as %.6f bits" % h12)
	mended.free()
	var zero := 0.0
	check(log(zero) == -INF and is_nan(zero * log(zero)) and str(zero * log(zero)) == "nan" and "%.3f" % (zero * log(zero)) == "-nan",
		"log(0.0) is -inf, 0.0 * log(0.0) is nan; print() writes it `nan` and \"%.3f\" writes it `-nan`")
	measured["entropy_of_the_first_12_bits"] = h12
	measured["symbols_absent_from_the_first_12"] = absent

	# Two more changes the lesson names. Ties answered `false`: sorted all the same, by Godot's choice.
	var loose := GDScript.new()
	loose.source_code = text.replace(TIES, "	return false")
	var loose_compiled := loose.reload()
	var ours := new_row(40, 200)
	var theirs := new_row(40, 200, loose)
	await frames(2)
	ours.arrange(1, 0.0)
	theirs.arrange(1, 0.0)
	var elsewhere := 0
	for i in 200:
		if ours.goes_to[i] != theirs.goes_to[i]:
			elsewhere += 1
	check(loose_compiled == OK and text.contains(TIES) and ours.row() == theirs.row() and elsewhere > 0,
		"with `return false` for two equal symbols the row sorted by value reads the same, and %d of the 200 draws stand at another place" % elsewhere)
	measured["ties_answered_false_draws_at_another_place"] = elsewhere
	ours.free()
	theirs.free()
	var comma := GDScript.new()
	comma.source_code = text.replace("\"sorted in reverse\") var arrangement", "\"sorted by value, reversed\") var arrangement")
	var before := errors.size()
	var refused := comma.reload()
	var said := "" if errors.size() == before else errors[before].get_slice(" (gdscript", 0)   # without the name Godot gives a script that has no file
	check(refused != OK and said.contains("Argument 4 of annotation \"@export_enum\" contains a comma. Use separate arguments instead."), "a value's name with a comma in it is refused: `%s`" % said)
	measured["error_for_a_comma_in_a_name"] = said
	expected_errors += errors.size() - before

# ---------------------------------------------------------------- numbers the lesson quotes

## The same sum, taken in the order the dictionary met the symbols.
func entropy_as_met(symbols: PackedInt32Array) -> float:
	var counts := {}
	for s in symbols:
		counts[s] = counts.get(s, 0) + 1
	var h := 0.0
	for s in counts:
		var p: float = float(counts[s]) / symbols.size()
		h -= p * log(p) / log(2.0)
	return h

func numbers() -> void:
	var row: Node3D = lab.get_node("Row")
	var as_met := {}
	var values := []
	for how in 4:
		row.arrange(how, 0.0)
		values.append(entropy_as_met(row.row()))
		as_met[Row.NAMES[how]] = "%.17f" % values[how]
	row.arrange(0, 0.0)
	var spread: float = values.max() - values.min()
	check(spread < 1e-12, "summed in the order the row meets its symbols, the four entropies lie within %.19f of each other" % spread)
	measured["entropy_summed_in_the_order_met"] = as_met
	measured["entropy_summed_in_the_order_met_all_equal"] = spread == 0.0
	measured["entropy_summed_in_the_order_met_spread"] = spread
	var colours := PackedInt32Array()
	for v in row.values:
		colours.append(v % 4)
	var h_colours: float = row.entropy(colours)
	check(h_colours > 1.9 and h_colours < 2.0, "the same row counted by colour, four symbols, has %.3f bits of at most 2" % h_colours)
	measured["entropy_counted_by_colour_bits"] = h_colours
	var least := INF
	var most := -INF
	var sum := 0.0
	var rng := RandomNumberGenerator.new()
	for seed_value in range(1, 101):
		rng.seed = seed_value
		var drawn := PackedInt32Array()
		for i in 200:
			drawn.append(rng.randi_range(0, 9))
		var h: float = row.entropy(drawn)
		least = minf(least, h)
		most = maxf(most, h)
		sum += h
	check(most < log(10.0) / log(2.0), "of the rows of seeds 1 to 100 none reaches 3.322 bits: they lie between %.3f and %.3f, %.3f on average" % [least, most, sum / 100.0])
	measured["entropy_of_seeds_1_to_100"] = {"least": least, "most": most, "mean": sum / 100.0}

# ---------------------------------------------------------------- the log as a body

func plates_of(curve: Node3D) -> Array:
	var out := []
	for child in curve.get_children():
		if child is MeshInstance3D and child.get_script() != Segment:
			out.append(child)
	return out

func new_curve(path: String, rise := 0.03) -> Node3D:
	var curve := Node3D.new()
	curve.set_script(FCurve)
	curve.log_file = path
	curve.rise = rise
	root.add_child(curve)
	return curve

func write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()

func curve() -> void:
	var curve: Node3D = lab.get_node("Curve")
	var entries: Array = curve.entries
	var right := entries.size() == 16
	var zeros := 0
	for entry: Dictionary in entries:
		right = right and is_equal_approx(entry["f"], absf(entry["predicted"] - entry["observed"]))
		if entry["f"] == 0.0:
			zeros += 1
	check(right, "the curve read 16 chapters from sketchbook.json and gave each its F, the distance between predicted and observed")
	var first := []
	for i in 4:
		first.append("%s %.2f" % [curve.ranked[i]["chapter"], curve.ranked[i]["f"]])
	check(first == ["extrude 8.97", "genome 5.49", "family-editor 3.15", "chessboard 3.14"] and printed.has("16 chapters; most wrong: extrude, F = 8.97"),
		"sort_custom ranks them, the most wrong first: %s; and the scene printed the first" % [first])
	check(zeros == 9, "%d of the 16 have F = 0: the pair named was the closest pair" % zeros)
	measured["ranked"] = first
	measured["chapters_with_f_0"] = zeros
	var plates := plates_of(curve)
	var built := plates.size() == 16
	var solid := true
	for i in plates.size():
		var plate: MeshInstance3D = plates[i]
		var height: float = 0.05 + 0.03 * entries[i]["f"]
		built = built and plate.mesh.size.is_equal_approx(Vector3(0.4, height, 0.8)) and plate.position.is_equal_approx(Vector3((i - 7.5) * 0.4, height / 2.0, 0.0))
		built = built and plate.material_override.albedo_color == Look.BODY and curve.top_of(i).is_equal_approx(Vector3((i - 7.5) * 0.4, height, 0.0))
		solid = solid and plate.get_child_count() == 1 and plate.get_child(0) is StaticBody3D and plate.get_child(0).get_child(0).shape is ConvexPolygonShape3D
	check(built, "16 plates of 0.4 x 0.8 m in BODY stand side by side on the ground, each 0.05 m high and 0.03 m more for every point of F")
	check(solid, "every plate has a StaticBody3D with a convex shape")
	var lines := []
	var labels := []
	for child in curve.get_children():
		if child.get_script() == Segment:
			lines.append(child)
		if child is Label3D:
			labels.append(child.text)
	var joined := lines.size() == 15
	for i in lines.size():
		var a: Vector3 = curve.top_of(i)
		var b: Vector3 = curve.top_of(i + 1)
		joined = joined and lines[i].position.is_equal_approx((a + b) / 2.0) and is_equal_approx(lines[i].mesh.height, a.distance_to(b))
	check(joined, "15 segments in LINE join the middles of the plates' tops: the line of F")
	check(labels.size() == 16 and labels[4] == "extrude  8.97" and labels[0] == "organism  0.67", "each plate has its chapter and its F on the floor in front of it")
	measured["highest_plate_m"] = curve.top_of(4).y

	write("user://qfep_three.json", JSON.stringify({"entries": [{"chapter": "one", "predicted": 2.0, "observed": 2.0}, {"chapter": "two", "predicted": 1.0, "observed": 7.5}, {"chapter": "three", "predicted": 4.0, "observed": 3.0}]}))
	var three := new_curve("user://qfep_three.json")
	await frames(2)
	check(plates_of(three).size() == 3 and three.ranked[0]["chapter"] == "two" and is_equal_approx(three.ranked[0]["f"], 6.5), "another log, another body: three chapters, three plates, most wrong `two` with F = 6.5")
	three.free()

	var before := errors.size()
	var none := new_curve("res://no_such.json")
	await frames(2)
	check(none.get_child_count() == 0 and printed.has("no log to read at res://no_such.json") and errors.size() == before + 1, "a log that is not there: one error from Godot, our line `no log to read at res://no_such.json`, and nothing built")
	measured["error_for_a_missing_log"] = errors[-1]
	none.free()
	var text := FileAccess.get_file_as_string("res://sketchbook.json")
	var comma := text.find("},\n")
	write("user://qfep_broken.json", text.substr(0, comma + 1) + text.substr(comma + 2))
	var broken := new_curve("user://qfep_broken.json")
	await frames(2)
	check(comma > 0 and broken.get_child_count() == 0 and errors.size() == before + 2 and errors[-1].contains("Parse JSON failed"), "the log with one comma taken out: `%s`, and nothing built" % errors[-1])
	measured["error_for_a_missing_comma"] = errors[-1]
	broken.free()
	write("user://qfep_no_key.json", "{\"entries\": [{\"chapter\": \"one\", \"predicted\": 2.0}]}")
	var keyless := new_curve("user://qfep_no_key.json")
	await frames(2)
	check(errors.size() == before + 3 and errors[-1].contains("'observed'"), "an entry with no `observed`: `%s`" % errors[-1])
	measured["error_for_a_missing_key"] = errors[-1]
	keyless.free()
	expected_errors += 3

# ---------------------------------------------------------------- a body walks the log

func place() -> void:
	var walker: CharacterBody3D = lab.get_node("Walker")
	var curve: Node3D = lab.get_node("Curve")
	var row: Node3D = lab.get_node("Row")
	check(walker.global_position.distance_to(Vector3(-3.7, 0.0, 0.4)) < 0.05, "the walker stands on the floor at the left end of the log")
	var feet := {}
	var arrived := 0
	var on_its_own := []
	var held_up := []
	for i in curve.entries.size():
		var top: Vector3 = curve.to_global(curve.top_of(i))
		var how := await walk(walker, [top])
		if how == "arrived":
			arrived += 1
		var chapter: String = curve.entries[i]["chapter"]
		feet[chapter] = {"plate_m": snappedf(top.y, 0.001), "feet_m": snappedf(walker.global_position.y, 0.001)}
		if walker.global_position.y > top.y + 0.02:
			held_up.append(chapter)
		else:
			on_its_own.append(chapter)
	check(arrived == 16, "sent from plate to plate along the log, the walker arrived %d times of 16" % arrived)
	check(absf(feet["extrude"]["feet_m"] - feet["extrude"]["plate_m"]) < 0.01 and feet["extrude"]["plate_m"] > 0.31,
		"on the highest plate, extrude, its feet are at %.3f m; the plate's top is at %.3f m" % [feet["extrude"]["feet_m"], feet["extrude"]["plate_m"]])
	check(held_up.size() > 0 and held_up.has("collage") and feet["collage"]["feet_m"] > 0.25,
		"it is 0.6 m wide and a plate 0.4 m: on %d plates its feet are more than 2 cm above the plate, held by a higher one beside it: %s" % [held_up.size(), held_up])
	measured["walk_plate_by_plate"] = feet
	measured["plates_where_the_feet_are_on_the_plate"] = on_its_own
	measured["plates_where_a_neighbour_holds_the_walker"] = held_up
	var how_end := await walk(walker, [Vector3(3.7, 0.0, 0.4)])
	check(how_end == "arrived" and walker.global_position.y < 0.01, "it steps off the last plate onto the floor: \"%s\"" % how_end)
	var how_row := await walk(walker, [Vector3(3.7, 0.0, 0.0), Vector3(1.0, 0.0, 0.0), Vector3(1.0, 0.0, -1.4)])
	var gap: float = walker.global_position.z - (row.global_position.z + 0.15)
	check(how_row == "blocked" and gap > 0.25 and gap < 0.4, "sent at the row from in front, it is stopped: \"%s\", its middle %.2f m from the row's face" % [how_row, gap])
	measured["sent_at_the_row"] = {"walk_ended": how_row, "metres_from_the_face": snappedf(gap, 0.01)}
	row.arrange(1, 0.0)
	var marble: RigidBody3D = load("res://supplied/marble.tscn").instantiate()
	marble.position = Vector3(3.0, 0.1, 2.0)
	lab.add_child(marble)
	await frames(2)
	marble.drop(row.to_global(Vector3(-1.9, 2.0, 0.0)))
	var rest := await settle(marble)
	check(absf(rest.y - 1.1) < 0.02, "a marble dropped over the zeros, bars 0.1 m high, rests at %.2f m: on the row's box, 0.9 m above the bars it is over" % rest.y)
	measured["marble_over_the_zeros_rests_at_m"] = snappedf(rest.y, 0.01)
	row.arrange(0, 0.0)

	var steep: Node3D = load("res://lab.tscn").instantiate()
	steep.get_node("Curve").rise = 0.1
	steep.position = Vector3(0.0, 0.0, 40.0)
	root.add_child(steep)
	await frames(3)
	var second: CharacterBody3D = steep.get_node("Walker")
	var steep_curve: Node3D = steep.get_node("Curve")
	var stopped_at := ""
	var how_steep := ""
	var reached := 0
	var short := 0.0
	for i in steep_curve.entries.size():
		var top: Vector3 = steep_curve.to_global(steep_curve.top_of(i))
		how_steep = await walk(second, [top])
		if how_steep != "arrived":
			stopped_at = steep_curve.entries[i]["chapter"]
			short = top.x - second.global_position.x
			break
		reached += 1
	check(how_steep == "blocked" and stopped_at == "collage" and reached == 3 and short > 0.05 and short < 0.15,
		"with `rise` at 0.1 the plate of extrude is %.2f m high, a wall: the walk ends \"%s\" on collage, the plate before it, %.2f m short of its middle, after %d plates" % [steep_curve.top_of(4).y, how_steep, short, reached])
	measured["rise_0_1"] = {"stopped_on": stopped_at, "walk_ended": how_steep, "plates_reached": reached, "extrude_plate_m": snappedf(steep_curve.top_of(4).y, 0.001), "feet_m": snappedf(second.global_position.y, 0.001), "metres_short_of_the_middle": snappedf(short, 0.01)}
	steep.free()

# ---------------------------------------------------------------- the guest

func guest() -> void:
	var needs := CheckGuest.outside(GUEST)
	check(needs.is_empty(), "the guest names nothing outside its folder: %s" % [needs])
	check(CheckGuest.class_names(GUEST).is_empty(), "the guest declares no class_name")
	check(FileAccess.get_file_as_bytes(GUEST + "sketchbook.json") == FileAccess.get_file_as_bytes("res://sketchbook.json"), "the guest's own sketchbook.json is the kit's log, byte for byte")
	var before := errors.size()
	var body: Node = load(GUEST + "qfep-lab.tscn").instantiate()
	body.position = Vector3(20.0, 0.0, 0.0)
	root.add_child(body)
	await frames(3)
	check(body is Node3D and errors.size() == before and printed.has("QFEP lab: 16 chapters; most wrong: extrude, F = 8.97"), "it loads, its first node is a Node3D, and it printed `QFEP lab: 16 chapters; most wrong: extrude, F = 8.97`")
	var box := AABB()
	var plates := []
	var label: Label3D = null
	for child in body.get_children():
		if child is MeshInstance3D:
			var here: AABB = child.transform * child.get_aabb()
			box = here if plates.is_empty() else box.merge(here)
			plates.append(child)
		if child is Label3D:
			label = child
	check(plates.size() == 16 and absf(box.position.y) < 0.001 and box.size.x <= 1.6 and box.size.z <= 1.6 and absf(box.get_center().x) < 0.001 and absf(box.get_center().z) < 0.001,
		"16 plates stand on the ground round its origin in a box of %.2f x %.2f m, %.2f m high" % [box.size.x, box.size.z, box.size.y])
	var solid := true
	var cyan := []
	for i in plates.size():
		var plate: MeshInstance3D = plates[i]
		solid = solid and plate.get_child(0) is StaticBody3D and plate.get_child(0).get_child(0).shape is BoxShape3D and plate.get_child(0).get_child(0).shape.size == plate.mesh.size
		if plate.material_override.albedo_color == Look.SECOND:
			cyan.append(i)
		else:
			solid = solid and plate.material_override.albedo_color == Look.BODY
	check(solid, "every plate has a box collider of its own size, and its colour is the look's BODY, written out")
	check(cyan == [4] and is_equal_approx(plates[4].mesh.size.y, 0.3) and label != null and label.text == "extrude  F 8.97", "the plate of the largest F, extrude, is 0.3 m high and SECOND, and the label over the body reads `extrude  F 8.97`")
	measured["guest_box_m"] = [snappedf(box.size.x, 0.01), snappedf(box.size.y, 0.01), snappedf(box.size.z, 0.01)]
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	floor_shape.shape = BoxShape3D.new()
	floor_shape.shape.size = Vector3(6.0, 0.1, 6.0)
	floor_body.add_child(floor_shape)
	floor_body.position = Vector3(20.0, -0.05, 0.0)
	root.add_child(floor_body)
	var walker: CharacterBody3D = load("res://supplied/walker.tscn").instantiate()
	walker.position = Vector3(20.0, 0.0, 2.0)
	root.add_child(walker)
	await physics_frames(10)
	var how := await walk(walker, [Vector3(20.0, 0.0, 0.0)])
	var feet: float = walker.global_position.y
	var from_middle: float = walker.global_position.z
	check(how == "blocked" and feet < 0.01 and from_middle > 0.4 and from_middle < 0.7, "a walker sent at it from the front is stopped by it: \"%s\", %.2f m from the guest's middle, its feet at %.2f m" % [how, from_middle, feet])
	measured["walker_at_the_guest"] = {"walk_ended": how, "feet_m": snappedf(feet, 0.01), "metres_from_the_middle": snappedf(from_middle, 0.01)}
	walker.free()
	floor_body.free()
	body.free()
	var other: Node3D = load(GUEST + "qfep-lab.tscn").instantiate()
	other.log_file = "user://qfep_three.json"
	root.add_child(other)
	await frames(2)
	check(printed.has("QFEP lab: 3 chapters; most wrong: two, F = 6.50") and other.get_child_count() == 4, "with another log in its place the guest is another body: three plates, and `QFEP lab: 3 chapters; most wrong: two, F = 6.50`")
	var ground := StaticBody3D.new()
	var ground_shape := CollisionShape3D.new()
	ground_shape.shape = BoxShape3D.new()
	ground_shape.shape.size = Vector3(6.0, 0.1, 6.0)
	ground.add_child(ground_shape)
	ground.position = Vector3(0.0, -0.05, -20.0)
	root.add_child(ground)
	other.position = Vector3(0.0, 0.0, -20.0)
	var second: CharacterBody3D = load("res://supplied/walker.tscn").instantiate()
	second.position = Vector3(0.0, 0.0, -18.0)
	root.add_child(second)
	await physics_frames(10)
	var how_three := await walk(second, [Vector3(0.0, 0.0, -20.0)])
	check(how_three == "arrived" and absf(second.global_position.y - 0.3) < 0.01, "three plates are 0.5 m wide each, and the walker steps onto the highest: \"%s\", its feet at %.2f m" % [how_three, second.global_position.y])
	measured["walker_at_the_guest_of_three_chapters"] = {"walk_ended": how_three, "feet_m": snappedf(second.global_position.y, 0.01)}
	second.free()
	ground.free()
	other.free()
	var empty: Node3D = load(GUEST + "qfep-lab.tscn").instantiate()
	empty.log_file = "user://qfep_no_such.json"
	root.add_child(empty)
	await frames(2)
	check(empty.get_child_count() == 0 and errors.size() == before and printed.has("QFEP lab: no log to read at user://qfep_no_such.json: nothing stands here"), "with no log it prints one line, builds nothing and logs no error")
	empty.free()

# ---------------------------------------------------------------- the recovery points

func steps() -> void:
	var files := DirAccess.get_files_at("res://steps")
	var rows := []
	var curves := []
	for file in files:
		if file.begins_with("row-"):
			rows.append(file)
		if file.begins_with("f_curve-"):
			curves.append(file)
	rows.sort()
	curves.sort()
	var same := not rows.is_empty() and not curves.is_empty()
	if same:
		same = FileAccess.get_file_as_string("res://steps/" + rows[-1]) == FileAccess.get_file_as_string("res://row.gd")
		same = same and FileAccess.get_file_as_string("res://steps/" + curves[-1]) == FileAccess.get_file_as_string("res://f_curve.gd")
	check(same, "steps/ holds the two scripts as they are after each step of the lesson (%d and %d files); the last of each is the script as shipped" % [rows.size(), curves.size()])
