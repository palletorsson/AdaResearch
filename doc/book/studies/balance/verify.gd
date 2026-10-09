extends "res://supplied/verify_tools.gd"
## The Balance kit's checks. Headless, from this folder:
##   godot --headless --path . --xr-mode off --script res://verify.gd
## It writes verification.json; the exit code is the number of failed checks.
## The bodies fall in real time, so it takes a few minutes; with --fixed-fps 60
## added it takes seconds, with the same checks.

const CheckGuest := preload("res://supplied/check_guest.gd")
const TABLE := preload("res://table.gd")
const GUEST := "res://guests/balance/balance.tscn"
const OFFSETS := [0.0, 0.17, 0.34, 0.51]
const NAMES := ["at its centre", "halfway to the edge", "on the edge", "outside"]

func run() -> void:
	await project()
	await the_table()
	await held_and_let_go()
	await the_axis()
	await the_edge_closely()
	await heavy_or_light()
	await two_and_three_legs()
	await without_the_mode()
	await asleep_in_the_air()
	await the_signal()
	await the_stack()
	await the_walker_weighs_nothing()
	await the_walker_weighs()
	await the_walker_walks()
	await the_main_scene()
	await the_guest()

# ---------------------------------------------------------------- helpers

func base() -> Node3D:
	var scene: Node3D = load("res://supplied/base.tscn").instantiate()
	root.add_child(scene)
	return scene

## A table with the settings given, on its own floor, let go at once unless `hold` is given.
## Every setting is read back: set() with a name the table does not have does nothing, in silence.
func table_in(room: Node, settings: Dictionary) -> Node3D:
	var t: Node3D = TABLE.new()
	t.members = 0
	t.walker_mass = 0.0
	t.hold = 0.0
	for key: String in settings:
		t.set(key, settings[key])
		if t.get(key) != settings[key]:
			check(false, "the table took the setting %s = %s (it has %s)" % [key, settings[key], t.get(key)])
	room.add_child(t)
	return t

## A table on its own floor for `steps` steps of the physics; what it did.
func case(settings: Dictionary, steps := 180, sleepless := false) -> Dictionary:
	var room := base()
	var t := table_in(room, settings)
	await physics_frame
	if sleepless:
		t.plate.can_sleep = false
	var asleep_at := -1
	for i in steps:
		await physics_frame
		if asleep_at < 0 and t.plate.sleeping:
			asleep_at = i + 1
	var out := {"tilt_deg": snappedf(t.tilt(t.plate), 0.01), "plate_y_m": snappedf(t.plate.global_position.y, 0.001),
		"plate_x_m": snappedf(t.plate.global_position.x, 0.001), "sleeping": t.plate.sleeping, "fell_asleep_after_steps": asleep_at,
		"fallen": t.down.map(func(b: RigidBody3D) -> String: return str(b.name))}
	room.free()
	await frames(1)
	return out

func files_in(folder: String, ending: String) -> Array:
	var out := []
	for file in DirAccess.get_files_at(folder):
		if file.ends_with(ending):
			out.append(folder + file)
	for inner in DirAccess.get_directories_at(folder):
		if inner != ".godot" and inner != "stills":
			out.append_array(files_in(folder + inner + "/", ending))
	return out

# ---------------------------------------------------------------- the project

func project() -> void:
	check(ProjectSettings.get_setting("application/config/name") == "Balance", "the project is named Balance")
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://balance.tscn", "its main scene is balance.tscn")
	check(str(ProjectSettings.get_setting("physics/3d/physics_engine")) == "DEFAULT", "the project leaves the physics engine at its default: %s" % ProjectSettings.get_setting("physics/3d/physics_engine"))
	measured["physics_engine"] = "%s (GodotPhysicsServer3D present: %s, JoltPhysicsServer3D present: %s)" % [ProjectSettings.get_setting("physics/3d/physics_engine"), ClassDB.class_exists("GodotPhysicsServer3D"), ClassDB.class_exists("JoltPhysicsServer3D")]
	measured["physics_ticks_per_second"] = Engine.physics_ticks_per_second
	var supplied := []
	for file in DirAccess.get_files_at("res://supplied/"):
		if not file.ends_with(".uid"):
			supplied.append(file)
	check(supplied.size() == 15, "supplied/ holds the base's 15 files: %d" % supplied.size())
	var named := []
	var spaced := []
	for file: String in files_in("res://", ".gd"):
		var text := FileAccess.get_file_as_string(file)
		if RegEx.create_from_string("(?m)^class_name\\s").search(text) != null:
			named.append(file)
		if RegEx.create_from_string("(?m)^ +\\S").search(text) != null:
			spaced.append(file)
	check(named.is_empty(), "no script of the kit declares a class_name: %s" % [named])
	check(spaced.is_empty(), "every script is indented with tabs: %s" % [spaced])
	var leftovers := files_in("res://", ".uid") + files_in("res://", ".import")
	check(leftovers.is_empty(), "no .uid or .import file in the kit: %s" % [leftovers])
	for file: String in ["res://table.gd", "res://counter.gd", "res://balance.tscn", "res://sheet.gd", "res://TUTORIAL.md", "res://README.md",
			"res://FIELD_NOTE.md", "res://guests/balance/balance.tscn", "res://guests/balance/balance.gd"]:
		check(FileAccess.file_exists(file), "%s is in the kit" % file)

# ---------------------------------------------------------------- the table as built

func the_table() -> void:
	var room := base()
	var counts := {}
	for legs: int in [2, 3, 4]:
		var t := table_in(room, {"legs": legs, "hold": 100.0})
		var posts := t.find_children("*", "StaticBody3D", false, false)
		counts[str(legs)] = posts.size()
		var tops := true
		for post: StaticBody3D in posts:
			if not is_equal_approx(post.position.y, 0.15):
				tops = false
		check(posts.size() == legs and tops, "a table of %d legs stands on %d posts 30 cm high" % [legs, posts.size()])
		t.free()
	var t := table_in(room, {"offset": 0.17, "mass": 10.0, "hold": 100.0})
	await physics_frames(2)
	check(t.plate.freeze, "the plate is frozen until it is let go")
	check(is_equal_approx(t.plate.global_position.y - 0.03, 0.31), "its underside is 1 cm above the posts' tops: %.3f m" % (t.plate.global_position.y - 0.03))
	check(t.plate.mass == 10.0, "it weighs 10 kg")
	check(t.plate.center_of_mass_mode == RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM and t.plate.center_of_mass == Vector3(0.17, 0, 0), "its centre of mass is custom, at (0.17, 0, 0)")
	check(t.plate.get_node("Mark").position == Vector3(0.17, 0, 0), "the mark stands at the centre of mass")
	var outline := 0
	for child in t.get_children():
		if str(child.name).begins_with("Outline"):
			outline += 1
	check(outline == 4, "four segments outline the four posts' tops: %d" % outline)
	measured["posts_for_legs"] = counts
	room.free()
	await frames(1)

func held_and_let_go() -> void:
	var room := base()
	var t := table_in(room, {"hold": 1.0})
	var start: Vector3
	await physics_frame
	start = t.plate.global_position
	await physics_frames(50)
	check(near(t.plate.global_position, start, 0.00001) and t.plate.freeze, "held for 1 s, the plate has not moved after 50 steps")
	var asleep_at := -1
	for i in 120:
		await physics_frame
		if asleep_at < 0 and t.plate.sleeping:
			asleep_at = i + 1
	check(not t.plate.freeze, "after 1 s it is let go")
	check(absf(t.plate.global_position.y - 0.324) < 0.002 and t.tilt(t.plate) < 0.1, "it drops onto the posts and stands level at %.3f m, tilt %.2f deg" % [t.plate.global_position.y, t.tilt(t.plate)])
	check(t.plate.sleeping and asleep_at > 0, "and falls asleep, %d steps after we began to watch (it was let go about 10 steps in)" % asleep_at)
	measured["let_go"] = {"rests_at_m": snappedf(t.plate.global_position.y, 0.001), "asleep_after_steps_of_watching": asleep_at}
	room.free()
	await frames(1)

# ---------------------------------------------------------------- the argument

func the_axis() -> void:
	measured["axis"] = {}
	var results := []
	for k in OFFSETS.size():
		var did := await case({"offset": OFFSETS[k]})
		var sleepless := await case({"offset": OFFSETS[k]}, 180, true)
		measured["axis"][NAMES[k]] = {"offset_m": OFFSETS[k], "three_seconds": did, "three_seconds_never_asleep": sleepless}
		results.append([did, sleepless])
	check(results[0][0]["tilt_deg"] < 0.05 and results[0][0]["fallen"].is_empty(), "at its centre the plate stands level: %.2f deg" % results[0][0]["tilt_deg"])
	check(results[1][0]["tilt_deg"] < 0.05 and results[1][0]["fallen"].is_empty(), "halfway to the edge it stands level too: %.2f deg" % results[1][0]["tilt_deg"])
	check(results[2][0]["fallen"].is_empty() and results[2][0]["sleeping"], "on the edge it stands, asleep, %.2f deg off level" % results[2][0]["tilt_deg"])
	check(results[3][0]["fallen"] == ["Plate"] and results[3][0]["plate_y_m"] < 0.1, "outside it has fallen to the floor: %.2f deg" % results[3][0]["tilt_deg"])
	check(results[2][1]["tilt_deg"] > 5.0 and results[2][1]["fallen"].is_empty(), "on the edge, never allowed to sleep, it is %.2f deg down after 3 s and still going" % results[2][1]["tilt_deg"])
	check(results[0][1]["tilt_deg"] < 0.05 and results[1][1]["tilt_deg"] < 0.05 and results[3][1]["fallen"] == ["Plate"], "the other three do what they did asleep")
	var later := await case({"offset": 0.34}, 360, true)
	measured["axis"]["on the edge"]["six_seconds_never_asleep"] = later
	check(later["fallen"] == ["Plate"], "never allowed to sleep, the plate on the edge has fallen 6 s after it was let go: %.2f deg" % later["tilt_deg"])

## Where between 0.33 and 0.36 the plate stops standing, asleep and never asleep.
func the_edge_closely() -> void:
	var last_asleep := 0.0
	var last_awake := 0.0
	var rows := {}
	for offset: float in [0.33, 0.335, 0.34, 0.343, 0.345, 0.348, 0.35, 0.355, 0.36]:
		var did := await case({"offset": offset})
		var awake := await case({"offset": offset}, 360, true)
		rows[str(offset)] = [did["tilt_deg"], awake["tilt_deg"]]
		if did["fallen"].is_empty():
			last_asleep = offset
		if awake["fallen"].is_empty():
			last_awake = offset
	measured["edge_tilt_after_3_s_and_after_6_s_never_asleep"] = rows
	measured["last_offset_that_stood_m"] = last_asleep
	measured["last_offset_that_stood_never_asleep_m"] = last_awake
	check(last_awake >= 0.33 and last_awake < 0.34, "never allowed to sleep, the plate stops standing at the posts' outer faces: the last offset that stood was %.3f m, the faces are at 0.34 m" % last_awake)
	check(last_asleep > last_awake, "allowed to sleep, it stood further out: the last offset that stood was %.3f m" % last_asleep)

func heavy_or_light() -> void:
	var same := true
	var rows := {}
	for offset: float in OFFSETS:
		var tilts := []
		var fallen := []
		for mass: float in [1.0, 10.0, 100.0]:
			var did := await case({"offset": offset, "mass": mass})
			tilts.append(did["tilt_deg"])
			fallen.append(did["fallen"].size())
		rows[str(offset)] = tilts
		if absf(tilts[0] - tilts[1]) > 0.01 or absf(tilts[2] - tilts[1]) > 0.01 or fallen[0] != fallen[1] or fallen[2] != fallen[1]:
			same = false
	measured["tilt_for_1_10_100_kg"] = rows
	check(same, "a plate of 1, 10 or 100 kg tilts the same, to a hundredth of a degree, at all four offsets: %s" % [rows])

func two_and_three_legs() -> void:
	var rows := {}
	for legs: int in [2, 3]:
		for offset: float in [0.0, 0.1, 0.17, 0.34, 0.51, -0.34]:
			rows["%d legs, %.2f" % [legs, offset]] = await case({"legs": legs, "offset": offset})
	measured["two_and_three_legs"] = rows
	check(rows["2 legs, 0.00"]["fallen"].is_empty(), "on two posts across the corners the plate stands with its centre of mass at its centre: %.2f deg" % rows["2 legs, 0.00"]["tilt_deg"])
	check(rows["2 legs, 0.17"]["fallen"] == ["Plate"], "and falls with it halfway to the edge: %.2f deg" % rows["2 legs, 0.17"]["tilt_deg"])
	check(rows["3 legs, 0.17"]["fallen"].is_empty() and rows["3 legs, 0.51"]["fallen"] == ["Plate"], "on three posts it stands halfway and falls outside")

## The planted silence: without center_of_mass_mode the centre of mass is not used.
func without_the_mode() -> void:
	var room := base()
	var t: Node3D = TABLE.new()
	t.members = 0
	t.walker_mass = 0.0
	t.hold = 100.0
	t.offset = 0.51
	room.add_child(t)
	t.plate.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_AUTO
	t.plate.center_of_mass = Vector3(0.51, 0, 0)
	var before := errors.size()
	t.release()
	await physics_frames(180)
	check(t.down.is_empty() and t.tilt(t.plate) < 0.05, "with the mode left at AUTO, a centre of mass at 0.51 m is not used: the plate stands level, %.2f deg" % t.tilt(t.plate))
	check(errors.size() == before and t.plate.center_of_mass == Vector3(0.51, 0, 0), "and Godot says nothing: the property reads back 0.51 m and no error was logged")
	room.free()
	await frames(1)

func asleep_in_the_air() -> void:
	var room := base()
	var t := table_in(room, {"offset": 0.51})
	await physics_frame
	t.plate.sleeping = true
	await physics_frames(600)
	check(t.down.is_empty() and t.plate.global_position.y > 0.33, "let go with its centre of mass outside and put to sleep in the same step, the plate still hangs above its posts 10 s later, at %.3f m" % t.plate.global_position.y)
	measured["asleep_in_the_air_y_m"] = snappedf(t.plate.global_position.y, 0.001)
	room.free()
	await frames(1)

# ---------------------------------------------------------------- the signal

var heard := []

func listen(body: RigidBody3D) -> void:
	heard.append(str(body.name))

func the_signal() -> void:
	var room := base()
	var t := table_in(room, {"offset": 0.51, "members": 3})
	t.fallen.connect(listen)
	heard.clear()
	await physics_frames(240)
	check(heard.size() == 4 and heard.size() == t.down.size(), "with its centre of mass outside and three members on it, `fallen` is emitted once for each of the four bodies: %s" % [heard])
	room.free()
	await frames(1)
	# The planted bug: a counter whose count() takes no argument.
	var source := FileAccess.get_file_as_string("res://counter.gd")
	var deaf_source := source.replace("func count(body: RigidBody3D) -> void:", "func count() -> void:").replace("words.text = \"fallen: %d, the last %s\" % [falls, body.name]", "words.text = \"fallen: %d\" % falls")
	check(deaf_source != source, "the counter's count() can be written without its parameter, as the lesson first writes it")
	var deaf := GDScript.new()
	deaf.source_code = deaf_source
	deaf.reload()
	var scene: Node3D = load("res://balance.tscn").instantiate()
	scene.get_node("Table").offset = 0.51
	scene.get_node("Table").members = 3
	scene.get_node("Walker").keys = false
	scene.get_node("Counter").set_script(deaf)
	var before := errors.size()
	root.add_child(scene)
	await physics_frames(300)
	var said := errors.slice(before)
	var refused := said.filter(func(e: String) -> bool: return e.contains("Error calling from signal 'fallen' to callable:") and e.contains("Method expected 0 argument(s), but called with 1."))
	check(scene.get_node("Counter").falls == 0 and scene.get_node("Counter").words.text == "fallen: 0", "a count() with no parameter never counts: the label still says \"%s\" after four bodies fell" % scene.get_node("Counter").words.text)
	check(refused.size() == 4 and said.size() == 4, "Godot refuses the call at every emit, four times, with one line each: %s" % [said.slice(0, 1)])
	measured["planted_bug_message"] = said[0] if not said.is_empty() else ""
	scene.free()
	await frames(2)
	# The counter as shipped.
	scene = load("res://balance.tscn").instantiate()
	scene.get_node("Table").offset = 0.51
	scene.get_node("Walker").keys = false
	before = errors.size()
	root.add_child(scene)
	await physics_frames(300)
	var label: String = scene.get_node("Counter").words.text
	check(scene.get_node("Counter").falls == 4 and label.begins_with("fallen: 4, the last "), "the shipped counter counts every body that falls: \"%s\"" % label)
	check(errors.size() == before, "and no error is logged: %s" % [errors.slice(before)])
	scene.free()
	await frames(2)

# ---------------------------------------------------------------- the family on the plate

func the_stack() -> void:
	var rows := {}
	for lean: float in [0.0, 0.04, 0.06, 0.065, 0.07, 0.075, 0.08, 0.1]:
		var room := base()
		var t := table_in(room, {"members": 3, "lean": lean})
		await physics_frames(240)
		var tops := []
		for body in t.bodies:
			tops.append([str(body.name), snappedf(body.global_position.x, 0.001), snappedf(body.global_position.y, 0.001), snappedf(t.tilt(body), 0.1)])
		rows[str(lean)] = {"fallen": t.down.map(func(b: RigidBody3D) -> String: return str(b.name)), "bodies": tops}
		room.free()
		await frames(1)
	measured["stack_of_three"] = rows
	measured["stack_statics_says_the_top_two_fall_above_lean_m"] = 0.08
	check(rows["0.0"]["fallen"].is_empty() and rows["0.04"]["fallen"].is_empty() and rows["0.065"]["fallen"].is_empty(), "three members stand at a lean of 0, 0.04 and 0.065 m")
	check(rows["0.07"]["fallen"] == ["Member2", "Member3"] or rows["0.07"]["fallen"] == ["Member3", "Member2"], "at 0.07 m the top two fall, though the lever arithmetic says they stand up to 0.08: %s" % [rows["0.07"]["fallen"]])
	check(not rows["0.1"]["fallen"].is_empty() and rows["0.1"]["fallen"].size() == 2, "at 0.1 m two fall too")

# ---------------------------------------------------------------- the walker

## The walker stood on the plate at `x` metres from its middle, three seconds; what the plate did.
func stand_on(x: float, weight: float, members := 0) -> Dictionary:
	var room := base()
	var t := table_in(room, {"walker_mass": weight, "members": members})
	await physics_frames(60)
	var walker: CharacterBody3D = load("res://supplied/walker.tscn").instantiate()
	walker.keys = false
	walker.position = Vector3(x, 0.36, 0)
	room.add_child(walker)
	await physics_frames(10)
	var felt := t.standing.size()
	await physics_frames(170)
	var out := {"tilt_deg": snappedf(t.tilt(t.plate), 0.01), "fallen": t.down.map(func(b: RigidBody3D) -> String: return str(b.name)), "felt": felt,
		"walker_at_m": [snappedf(walker.global_position.x, 0.01), snappedf(walker.global_position.y, 0.01)]}
	room.free()
	await frames(1)
	return out

func the_walker_weighs_nothing() -> void:
	var rows := {}
	for x: float in [0.0, 0.3, 0.45, 0.55, -0.55]:
		rows[str(x)] = await stand_on(x, 0.0)
	measured["walker_of_no_weight"] = rows
	var none := true
	for key: String in rows:
		if rows[key]["tilt_deg"] > 0.05 or not rows[key]["fallen"].is_empty() or rows[key]["felt"] != 1:
			none = false
	check(none, "with walker_mass 0 the walker stands anywhere on the plate, 0.55 m from its middle too, and the plate does not move; its top felt the walker every time")

func the_walker_weighs() -> void:
	var rows := {}
	var last := 0.0
	for x: float in [0.3, 0.38, 0.39, 0.4, 0.405, 0.41, 0.45, 0.5]:
		rows[str(x)] = await stand_on(x, 60.0)
		if rows[str(x)]["fallen"].is_empty():
			last = x
	measured["walker_of_60_kg"] = rows
	measured["walker_of_60_kg_last_place_that_held_m"] = last
	measured["walker_of_60_kg_arithmetic_m"] = snappedf(0.34 * 70.0 / 60.0, 0.001)
	check(rows["0.3"]["fallen"].is_empty() and rows["0.4"]["fallen"].is_empty(), "a walker of 60 kg stands 0.3 and 0.4 m from the middle and the plate holds")
	check(rows["0.405"]["fallen"] == ["Plate"] and rows["0.5"]["fallen"] == ["Plate"], "at 0.405 m and beyond it tips: the last place that held was %.3f m; the arithmetic of 10 kg at 0 and 60 kg at x over the faces at 0.34 m says %.3f" % [last, 0.34 * 70.0 / 60.0])
	var left := await stand_on(-0.5, 60.0)
	check(left["fallen"] == ["Plate"], "0.5 m to the left it tips the other way: %.1f deg" % left["tilt_deg"])
	var family := await stand_on(-0.43, 60.0, 3)
	var family_far := await stand_on(-0.47, 60.0, 3)
	measured["walker_of_60_kg_with_three_members"] = {"-0.43": family, "-0.47": family_far}
	check(family["fallen"].is_empty() and not family_far["fallen"].is_empty(), "with the three members on the plate it holds the walker 0.43 m to the left and tips at 0.47: the family weighs on the other side")

func the_walker_walks() -> void:
	var room := base()
	var t := table_in(room, {"walker_mass": 60.0})
	await physics_frames(60)
	var walker: CharacterBody3D = load("res://supplied/walker.tscn").instantiate()
	walker.keys = false
	walker.position = Vector3(-2.0, 0, 0)
	room.add_child(walker)
	await physics_frames(10)
	var how := await walk(walker, [Vector3(1.5, 0, 0)])
	check(how == "blocked" and absf(walker.global_position.x + 0.9) < 0.05 and t.down.is_empty(), "the autopilot walks the walker at the plate: \"%s\" at x = %.2f, its side against the plate's edge; it does not step onto a RigidBody3D" % [how, walker.global_position.x])
	room.free()
	await frames(1)
	# By the keys: the walker put on the plate, W held, in the lesson's scene with no members.
	measured["walk_across_by_keys"] = {}
	for weight: float in [60.0, 0.0]:
		var scene: Node3D = load("res://balance.tscn").instantiate()
		scene.get_node("Table").members = 0
		scene.get_node("Table").walker_mass = weight
		var w: CharacterBody3D = scene.get_node("Walker")
		w.position = Vector3(-0.2, 0.36, 0)
		root.add_child(scene)
		var table: Node3D = scene.get_node("Table")
		await physics_frames(120)
		var tipped_at := INF
		Input.action_press("move_forward")
		for i in 90:
			await physics_frame
			if tipped_at == INF and table.tilt(table.plate) > 5.0:
				tipped_at = w.global_position.x
		Input.action_release("move_forward")
		await physics_frames(120)
		measured["walk_across_by_keys"][str(weight)] = {"plate_passed_5_deg_with_walker_at_x_m": tipped_at if tipped_at != INF else "never", "plate_tilt_deg": snappedf(table.tilt(table.plate), 0.1), "walker_ends_x_m": snappedf(w.global_position.x, 0.01)}
		if weight > 0.0:
			check(tipped_at > 0.38 and tipped_at < 0.6 and not table.down.is_empty(), "put on the plate and walked to the right with W, the walker of 60 kg tips it as it passes x = %.2f m" % tipped_at)
		else:
			check(tipped_at == INF and table.down.is_empty() and w.global_position.x > 0.7, "with walker_mass 0 it walks off the far edge and the plate stays level")
		scene.free()
		await frames(2)

# ---------------------------------------------------------------- the main scene

func the_main_scene() -> void:
	var before := errors.size()
	var scene: Node3D = load("res://balance.tscn").instantiate()
	scene.get_node("Walker").keys = false
	root.add_child(scene)
	await frames(180)
	await physics_frames(60)
	var table: Node3D = scene.get_node("Table")
	check(errors.size() == before, "balance.tscn runs 180 frames with no error: %s" % [errors.slice(before)])
	check(table.bodies.size() == 4 and table.down.is_empty(), "its table stands with its three members on it")
	check(scene.get_node("Counter").words.text == "fallen: 0", "its counter says \"%s\"" % scene.get_node("Counter").words.text)
	check(scene.get_node("Look/Sky").environment.background_mode == Environment.BG_SKY, "it runs in the look with its filter: the gradient sky")
	var walker: CharacterBody3D = scene.get_node("Walker")
	check(walker.is_on_floor() and near(walker.global_position, Vector3(-1.6, 0, 0), 0.01), "the walker stands on the floor at the left of the plate, facing it")
	scene.free()
	await frames(2)

# ---------------------------------------------------------------- the guest

func the_guest() -> void:
	var needs := CheckGuest.outside("res://guests/balance/")
	check(needs.is_empty(), "the guest names nothing outside its folder: %s" % [needs])
	check(CheckGuest.class_names("res://guests/balance/").is_empty(), "the guest declares no class_name")
	var room := base()
	var before := errors.size()
	var guest: Node3D = load(GUEST).instantiate()
	guest.position = Vector3(0, 0, -1.0)
	room.add_child(guest)
	await physics_frames(240)
	var box := AABB()
	var first := true
	for part: MeshInstance3D in guest.find_children("*", "MeshInstance3D", true, false):
		var here: AABB = part.global_transform * part.get_aabb()
		box = here if first else box.merge(here)
		first = false
	box.position -= guest.global_position
	check(guest.down.is_empty() and guest.words.text == "fallen: 0", "the guest stands with its three members, its label says \"%s\"" % guest.words.text)
	check(box.position.x >= -0.8 and box.end.x <= 0.8 and box.position.z >= -0.8 and box.end.z <= 0.8, "it fits in 1.6 m: x %.2f to %.2f, z %.2f to %.2f" % [box.position.x, box.end.x, box.position.z, box.end.z])
	check(absf(box.position.y) < 0.002, "its lowest point is on the ground at its origin: %.3f m" % box.position.y)
	check(errors.size() == before, "and Godot logged no error: %s" % [errors.slice(before)])
	var walker: CharacterBody3D = load("res://supplied/walker.tscn").instantiate()
	walker.keys = false
	walker.position = Vector3(0, 0, 1.5)
	room.add_child(walker)
	await physics_frames(10)
	var how := await walk(walker, [Vector3(0, 0, -1.0)])
	check(how == "blocked" and guest.down.is_empty(), "a walker walked at it is stopped by it (\"%s\", %.2f m from its middle) and nothing falls" % [how, Vector2(walker.global_position.x, walker.global_position.z + 1.0).length()])
	room.free()
	await frames(1)
	# its own signal, its legs, and a rider
	room = base()
	var tipped: Node3D = load(GUEST).instantiate()
	tipped.offset = 0.51
	room.add_child(tipped)
	await physics_frames(240)
	check(tipped.falls == 4 and tipped.words.text.begins_with("fallen: 4"), "with its centre of mass outside its label counts the four that fall: \"%s\"" % tipped.words.text)
	room.free()
	await frames(1)
	var thing := Node3D.new()
	var skin := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = Vector3(0.3, 0.3, 0.3)
	skin.mesh = cube
	skin.position.y = 0.15
	thing.add_child(skin)
	skin.owner = thing
	var solid := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	(shape.shape as BoxShape3D).size = cube.size
	solid.add_child(shape)
	skin.add_child(solid)
	solid.owner = thing
	shape.owner = thing
	var packed := PackedScene.new()
	packed.pack(thing)
	thing.free()
	measured["guest_with_a_rider"] = {}
	for legs: int in [4, 2]:
		room = base()
		var carrying: Node3D = load(GUEST).instantiate()
		carrying.rider = packed
		carrying.legs = legs
		before = errors.size()
		room.add_child(carrying)
		await physics_frames(240)
		var rider: RigidBody3D = carrying.get_node("Rider")
		var bottom: float = rider.global_position.y
		measured["guest_with_a_rider"]["%d legs" % legs] = {"fallen": carrying.down.map(func(b: RigidBody3D) -> String: return str(b.name)), "rider_bottom_m": snappedf(bottom, 0.001)}
		if legs == 4:
			check(carrying.down.is_empty() and absf(bottom - (0.354 + 0.72)) < 0.01, "with a 30 cm box of its own as `rider`, the guest stands it on top of the stack: its bottom at %.3f m" % bottom)
			check(errors.size() == before, "and Godot logged no error: %s" % [errors.slice(before)])
		else:
			check(true, "on two legs, with the rider, what fell was: %s" % [carrying.down.map(func(b: RigidBody3D) -> String: return str(b.name))])
		room.free()
		await frames(1)
