extends "res://supplied/verify_tools.gd"
## Headless checks of Bodies that learn. From this folder:
##   godot --headless --path . --xr-mode off --script res://verify.gd
## Writes verification.json beside this file; the exit code is the number of
## checks that failed. No import step is needed: nothing here has a class_name.
## Add --fixed-fps 60 and the walks take a second instead of half a minute.
## Headless draws no frames and keeps no texture: what the eye gets, and what the
## planted fault looks like, is measured by sheet.gd. Run WITH a window, this
## file also reads the texture back and checks it against the image.

const CheckGuest := preload("res://supplied/check_guest.gd")
const Look := preload("res://supplied/look.gd")
const NAMES := ["one person", "the class", "a default dataset", "random labels", "you"]
const WHO := ["the builder", "classmate", "nobody", "a coin", "you"]
const PAINT := {"stay": Look.BODY, "pass": Look.SECOND}
const SCRATCH := "user://learning_body_verify.json"   # where the checks save, so the learner's own file is left alone
const NO_FILE := "user://learning_body_no_such_file.json"

## Loaded in run() and not preloaded: a preloaded script that does not parse
## stops verify.gd before its first check.
var learner: GDScript
var data := {}

func run() -> void:
	project()
	if not the_file():
		return
	if not await the_script():
		return
	await who_labelled()
	await neighbours()
	await the_floor()
	await the_fault()
	await the_test()
	await a_line()
	await the_error()
	await the_scene()
	await your_own_labels()
	await downhill()
	await the_guest()
	if FileAccess.file_exists(SCRATCH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH))

## ---------------------------------------------------------------- helpers

func field(labelled_by: int, k := 3, rule := 0, code: GDScript = null, save_file := NO_FILE) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	body.set_script(code if code != null else learner)
	body.labelled_by = labelled_by
	body.k = k
	body.rule = rule
	body.save_file = save_file
	body.position.y = 0.005
	root.add_child(body)
	return body

func scene(rule := 0, labelled_by := 0, save_file := NO_FILE) -> Node3D:
	var made: Node3D = load("res://learning_body.tscn").instantiate()
	made.get_node("Field").rule = rule
	made.get_node("Field").labelled_by = labelled_by
	made.get_node("Field").save_file = save_file
	root.add_child(made)
	return made

func close(node: Node) -> void:
	node.free()
	await frames(1)

func place(cx: int, cz: int) -> Vector2:
	return Vector2((cx + 0.5) * 0.25 - 4.0, (cz + 0.5) * 0.25 - 2.5)

## The neighbours' vote written another way, to check the kit's against: no
## sort; the nearest sample is taken out of a list k times.
func expected(samples: Array, k: int, x: float, z: float) -> Array:
	var left := samples.duplicate()
	var stay := 0
	var took := 0
	var first := ""
	while took < k and not left.is_empty():
		var best := 0
		for i in left.size():
			var d := Vector2(left[i].x - x, left[i].z - z).length()
			var b := Vector2(left[best].x - x, left[best].z - z).length()
			if d < b or (d == b and left[i].label < left[best].label):
				best = i
		if first == "":
			first = left[best].label
		if left[best].label == "stay":
			stay += 1
		left.remove_at(best)
		took += 1
	if took == 0:
		return ["", 0.0]
	var gone := took - stay
	if stay == gone:
		return [first, stay / float(took)]
	return ["stay" if stay > gone else "pass", maxi(stay, gone) / float(took)]

func of(labeller: String) -> Array:
	var out := []
	for sample: Dictionary in data.samples:
		if sample.labelled_by.begins_with(labeller):
			out.append(sample)
	return out

func scripts(folder: String) -> Array:
	var out := []
	for file in DirAccess.get_files_at(folder):
		if file.get_extension() == "gd":
			out.append(folder + file)
	return out

func strays(folder: String) -> Array:
	var out := []
	for file in DirAccess.get_files_at(folder):
		if file.ends_with(".uid") or file.ends_with(".import"):
			out.append(folder + file)
	for inner in DirAccess.get_directories_at(folder):
		if inner == ".godot":
			out.append(folder + inner)
		else:
			out.append_array(strays(folder + inner + "/"))
	return out

## ---------------------------------------------------------------- the project

func project() -> void:
	check(ProjectSettings.get_setting("application/config/name") == "Bodies that learn", "the project is named Bodies that learn")
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://learning_body.tscn", "its main scene is learning_body.tscn")
	check(DirAccess.get_files_at("res://supplied/").size() == 15, "supplied/ holds its 15 files: %d" % DirAccess.get_files_at("res://supplied/").size())
	for action: String in ["move_left", "move_right", "move_forward", "move_backward", "jump", "look", "switch_camera", "drop", "pause"]:
		if not InputMap.has_action(action):
			check(false, "the Input Map has the action %s" % action)
	check(InputMap.has_action("pause") and InputMap.has_action("drop"), "the Input Map has pause (Space) and drop (M), the two keys that label a place")
	var spaced := []
	for path: String in scripts("res://") + scripts("res://guests/learning-body/"):
		for text_line in FileAccess.get_file_as_string(path).split("\n"):
			if text_line.begins_with(" "):
				spaced.append(path)
				break
		if FileAccess.get_file_as_string(path).contains("\r"):
			spaced.append(path + " (CR)")
	check(spaced.is_empty(), "every script is indented with tabs and has LF line ends: %s" % [spaced])
	check(strays("res://").is_empty(), "no .uid, .import or .godot is in the folder: %s" % [strays("res://")])

## ---------------------------------------------------------------- the file

## Returns false, and the run stops, when the file cannot be read: every later check needs it.
func the_file() -> bool:
	var before := errors.size()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://samples.json"))
	check(parsed is Dictionary, "samples.json parses as JSON, and is a dictionary: %s" % [errors.slice(before)])
	if not parsed is Dictionary:
		return false
	data = parsed
	# the lesson's Try: the same text with the comma after its first sample taken out
	var text := FileAccess.get_file_as_string("res://samples.json")
	var cut := text.find("\"z\": 1.4\n\t\t},")
	before = errors.size()
	var broken: Variant = JSON.parse_string(text.substr(0, cut + 12) + text.substr(cut + 13))
	measured["a_missing_comma_says"] = errors.slice(before)
	check(cut > 0 and broken == null and errors.size() == before + 1 and errors[-1] == "ERROR: Parse JSON failed. Error at line 15: Expected ','", "with one comma taken out the text does not parse, and Godot says where: %s" % [errors.slice(before)])
	check(data.has("about") and data.about.contains("Nobody in this file is a person"), "it says of itself that nobody in it is a person: \"%s\"" % data.get("about", ""))
	check(data.samples.size() == 144, "it holds 144 samples: %d" % data.samples.size())
	var whole := true
	var on_floor := true
	for sample: Dictionary in data.samples:
		if not (sample.has("x") and sample.has("z") and sample.has("label") and sample.has("labelled_by")) or sample.size() != 4:
			whole = false
		elif not (sample.x is float and sample.z is float and (sample.label == "stay" or sample.label == "pass")):
			whole = false
		elif absf(sample.x) > 3.7 or absf(sample.z) > 2.2:
			on_floor = false
	check(whole, "every sample is {x, z, label, labelled_by}; x and z are numbers and the label is stay or pass")
	check(on_floor, "every sample lies on the floor, at most 3.7 m and 2.2 m from its middle")
	var by := {}
	for sample: Dictionary in data.samples:
		by[sample.labelled_by] = by.get(sample.labelled_by, 0) + 1
	check(by == {"the builder": 36, "classmate 1": 12, "classmate 2": 12, "classmate 3": 12, "nobody": 36, "a coin": 36}, "six labellers: %s" % [by])
	check(data.consent == {"the builder": true, "classmate 1": true, "classmate 2": true, "classmate 3": true}, "consent is recorded for the builder and three classmates, and for nobody else: %s" % [data.consent])
	var same := true
	var builder := of("the builder")
	var coin := of("a coin")
	var flipped := 0
	for i in 36:
		if builder[i].x != coin[i].x or builder[i].z != coin[i].z:
			same = false
		if builder[i].label != coin[i].label:
			flipped += 1
	check(same, "the coin labels the builder's own 36 places")
	check(flipped == 17, "and gives 17 of them another label than the builder did: %d" % flipped)
	measured["labels"] = {}
	for who in 4:
		var stay := 0
		for sample: Dictionary in of(WHO[who]):
			if sample.label == "stay":
				stay += 1
		measured["labels"][NAMES[who]] = {"stay": stay, "pass": 36 - stay}
	check(measured["labels"]["one person"] == {"stay": 13, "pass": 23}, "the builder said stay 13 times and pass 23 times: %s" % [measured["labels"]["one person"]])
	return true

## ---------------------------------------------------------------- the script

func the_script() -> bool:
	var before := errors.size()
	learner = load("res://learning_body.gd")
	var good := learner != null and learner.can_instantiate()
	check(good, "learning_body.gd loads and parses: %s" % [errors.slice(before)])
	if not good:
		return false
	var source := learner.source_code
	check(not source.contains("class_name"), "it declares no class_name")
	check(source.contains("JSON.parse_string(") and source.contains("JSON.stringify("), "it reads with JSON.parse_string() and writes with JSON.stringify()")
	check(source.contains("assert(xor_wrong() > 0"), "its _ready() asserts that a line fails XOR")
	check(not FileAccess.file_exists("res://my_samples.json"), "the kit ships no my_samples.json: that file is the learner's own")
	var bare := MeshInstance3D.new()
	bare.set_script(learner)
	check(bare.labelled_by == 0 and bare.k == 3 and bare.rule == 0 and bare.file == "res://samples.json" and bare.save_file == "res://my_samples.json", "as shipped it is set to one person, 3 neighbours, the neighbours' rule and the kit's file: %d, %d, %d, %s" % [bare.labelled_by, bare.k, bare.rule, bare.file])
	bare.free()
	var before_ready := errors.size()
	var whole := field(0)
	await frames(1)
	var ran: bool = whole.get("readout") != null and whole.get("line") != null
	check(ran, "its _ready() runs to its end on the kit's file: %s" % [errors.slice(before_ready)])
	await close(whole)
	return ran

## ---------------------------------------------------------------- who labelled what

func who_labelled() -> void:
	for who in 4:
		var from := printed.size()
		var body := field(who)
		await frames(1)
		var want := of(WHO[who])
		var right: bool = body.chosen.size() == 36 and body.balls.size() == 36 and body.samples.size() == 144
		for i in mini(36, body.chosen.size()):
			var ball: MeshInstance3D = body.balls[i]
			if body.chosen[i] != want[i] or not near(ball.position, Vector3(want[i].x, 0.07, want[i].z)):
				right = false
			elif ball.material_override.albedo_color != PAINT[want[i].label]:
				right = false
		check(right, "%s: 36 of 144 samples are chosen, those labelled by \"%s\", and a ball stands on each, lime for stay and cyan for pass" % [NAMES[who], WHO[who]])
		var said := ""
		for text in printed.slice(from):
			if text.begins_with("36 of 144 samples"):
				said = text
		var consent_said := "not recorded" if who > 1 else "true"
		check(said.contains(consent_said) and said.contains(WHO[who]), "%s: it prints who labelled them and their consent: %s" % [NAMES[who], said])
		if who == 0:
			measured["printed_for_one_person"] = said
			var bodies := body.find_children("*", "CollisionObject3D", true, false)
			check(bodies.is_empty(), "the balls and the field have no collider: a walker walks through them")
		await close(body)
	var empty := field(4)
	await frames(1)
	check(empty.chosen.is_empty() and empty.balls.is_empty(), "you: the kit's file holds no label of yours, so nothing is chosen")
	check(empty.says(0.0, 0.0) == ["", 0.0], "and the field then says nothing of a place: %s" % [empty.says(0.0, 0.0)])
	var ground := true
	for cz in 20:
		for cx in 32:
			var got: Color = empty.image.get_pixel(cx, cz)
			if absf(got.r - Look.GROUND.r) + absf(got.g - Look.GROUND.g) + absf(got.b - Look.GROUND.b) > 0.02:
				ground = false
	check(ground, "and every cell is painted GROUND")
	await close(empty)
	# the Inspector's way: a value saved in a scene, on the script whose line says 0
	var holder := Node3D.new()
	var kept := MeshInstance3D.new()
	kept.set_script(learner)
	kept.name = "Field"
	kept.labelled_by = 2
	holder.add_child(kept)
	kept.owner = holder
	var packed := PackedScene.new()
	packed.pack(holder)
	holder.free()
	var made: Node3D = packed.instantiate()
	made.get_node("Field").save_file = NO_FILE
	root.add_child(made)
	await frames(1)
	var saved: MeshInstance3D = made.get_node("Field")
	check(saved.labelled_by == 2 and saved.chosen.size() == 36 and saved.chosen[0].labelled_by == "nobody", "a value saved in a scene wins over the script's line: saved as 2, the line says 0, and the default dataset is chosen")
	await close(made)

## ---------------------------------------------------------------- the neighbours' vote

func neighbours() -> void:
	measured["cells_that_say_stay"] = {}
	for who in 4:
		var counts := {}
		for k: int in [1, 3, 5]:
			var body := field(who, k)
			await frames(1)
			var unlike := 0
			var stay := 0
			var shares := {}
			for cz in 20:
				for cx in 32:
					var at := place(cx, cz)
					var said: Array = body.says(at.x, at.y)
					var want := expected(of(WHO[who]), k, at.x, at.y)
					if said[0] != want[0] or absf(said[1] - want[1]) > 0.0001:
						unlike += 1
					if said[0] == "stay":
						stay += 1
					shares[snappedf(said[1], 0.01)] = true
			counts[str(k)] = stay
			var steps := shares.keys()
			steps.sort()
			check(unlike == 0, "%s, k %d: all 640 cells get the label and the share that the vote written another way gives; %d say stay; the shares are %s" % [NAMES[who], k, stay, steps])
			await close(body)
		measured["cells_that_say_stay"][NAMES[who]] = counts
	check(measured["cells_that_say_stay"]["one person"] == {"1": 205, "3": 222, "5": 214}, "one person's field says stay on 205, 222 and 214 cells with 1, 3 and 5 neighbours: %s" % [measured["cells_that_say_stay"]["one person"]])
	var body := field(0, 3)
	await frames(1)
	var start: Array = body.says(-3.2, 2.0)
	check(start[0] == "stay" and is_equal_approx(start[1], 2.0 / 3.0), "where the walker starts, (-3.2, 2.0), three neighbours say stay with two votes of three: %s" % [start])
	var across: Array = body.says(1.0, 2.0)
	check(across[0] == "pass" and is_equal_approx(across[1], 1.0), "and at (1.0, 2.0) they say pass, all three: %s" % [across])
	await close(body)

## ---------------------------------------------------------------- the floor

func the_floor() -> void:
	var from := printed.size()
	var body := field(0, 3)
	await frames(1)
	var plane := body.mesh as PlaneMesh
	check(plane != null and plane.size == Vector2(8, 5), "the field is a PlaneMesh of 8 m by 5 m")
	check(body.image.get_size() == Vector2i(32, 20) and body.image.get_format() == Image.FORMAT_RGB8, "its image has one pixel for each of 32 by 20 cells")
	var material := body.material_override as StandardMaterial3D
	check(material != null and material.albedo_texture == body.texture and material.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST, "its material shows the texture, each pixel as one sharp cell")
	var unlike := 0
	var colours := {}
	for cz in 20:
		for cx in 32:
			var at := place(cx, cz)
			var want := expected(of("the builder"), 3, at.x, at.y)
			var colour := Look.GROUND.lerp(PAINT[want[0]], want[1] * 0.75)
			var got: Color = body.image.get_pixel(cx, cz)
			colours[got.to_html(false)] = true
			if absf(got.r - colour.r) + absf(got.g - colour.g) + absf(got.b - colour.b) > 0.02:
				unlike += 1
	check(unlike == 0, "every pixel is GROUND turned toward its label's colour by three quarters of the share: %d of 640 are not" % unlike)
	check(colours.size() == 4, "one person's field has four colours, sure and unsure of each label: %s" % [colours.keys()])
	measured["field_colours"] = colours.keys()
	check(printed.slice(from).has("painted 640 cells"), "it prints `painted 640 cells`")
	# the image against the floor: a sample's own cell, asked of one neighbour, has the sample's colour
	var one := field(0, 1)
	await frames(1)
	var own := 0
	for sample: Dictionary in one.chosen:
		var cx := int((sample.x + 4.0) / 0.25)
		var cz := int((sample.z + 2.5) / 0.25)
		if one.says(place(cx, cz).x, place(cx, cz).y)[0] == sample.label:
			own += 1
	measured["samples_whose_own_cell_has_their_label_k1"] = own
	check(own >= 33, "with one neighbour, the cell a sample lies in has that sample's label for %d of 36 (two samples can share a cell)" % own)
	await close(one)
	# the texture: headless keeps none, so the line is checked as text; with a window it is read back
	var source := learner.source_code
	var body_of := source.substr(source.find("func paint_field()"))
	body_of = body_of.substr(0, body_of.find("\nfunc ", 1))
	check(body_of.contains("\ttexture.update(image)\n"), "paint_field() hands the painted image to the texture: texture.update(image)")
	if DisplayServer.get_name() == "headless":
		var first := Image.create(2, 2, false, Image.FORMAT_RGB8)
		first.fill(Color.RED)
		var kept := ImageTexture.create_from_image(first)
		first.fill(Color.GREEN)
		kept.update(first)
		measured["headless_texture_after_update"] = "#" + kept.get_image().get_pixel(0, 0).to_html(false)
		check(kept.get_image().get_pixel(0, 0) == Color.RED, "why that check reads text: without a window a texture made red, and updated with a green image, reads back #%s" % kept.get_image().get_pixel(0, 0).to_html(false))
	else:
		var shown: Image = body.texture.get_image()
		var same := 0
		for cz in 20:
			for cx in 32:
				if shown.get_pixel(cx, cz).is_equal_approx(body.image.get_pixel(cx, cz)):
					same += 1
		check(same == 640, "with a window: the texture read back holds the image's own 640 pixels: %d" % same)
	await close(body)

## The lesson's planted fault: paint_field() without texture.update(image).
func the_fault() -> void:
	var source := learner.source_code
	var faulty := GDScript.new()
	faulty.source_code = source.replace("\ttexture.update(image)\n", "")
	var made := source.count("\ttexture.update(image)\n") == 1 and faulty.reload() == OK
	check(made, "the planted fault can be made: the script has that line once, and parses without it")
	if not made:
		return
	var before_errors := errors.size()
	var before_warnings := warnings.size()
	var from := printed.size()
	var body := field(0, 3, 0, faulty)
	await frames(3)
	var painted := 0
	for cz in 20:
		for cx in 32:
			if body.image.get_pixel(cx, cz) != Color.BLACK:
				painted += 1
	check(painted == 640 and printed.slice(from).has("painted 640 cells"), "without the line the image is still painted, all %d cells, and `painted 640 cells` is printed" % painted)
	check(errors.size() == before_errors and warnings.size() == before_warnings, "and Godot logs no error and no warning: the fault is silent")
	if DisplayServer.get_name() != "headless":
		var shown: Image = body.texture.get_image()
		var black := 0
		for cz in 20:
			for cx in 32:
				if shown.get_pixel(cx, cz) == Color.BLACK:
					black += 1
		check(black == 640, "with a window: the texture read back is black on all 640 cells: %d" % black)
	await close(body)

## ---------------------------------------------------------------- the test

func the_test() -> void:
	measured["wrong_about_its_own"] = {}
	for who in 4:
		var counts := {}
		for k: int in [1, 3, 5, 9]:
			var body := field(who, k)
			await frames(1)
			var want := 0
			for sample: Dictionary in of(WHO[who]):
				if expected(of(WHO[who]), k, sample.x, sample.z)[0] != sample.label:
					want += 1
			counts[str(k)] = body.wrong()
			if body.wrong() != want:
				check(false, "%s, k %d: wrong() counts %d, the vote written another way %d" % [NAMES[who], k, body.wrong(), want])
			await close(body)
		measured["wrong_about_its_own"][NAMES[who]] = counts
	var got: Dictionary = measured["wrong_about_its_own"]
	check(got["one person"]["1"] == 0 and got["the class"]["1"] == 0 and got["a default dataset"]["1"] == 0 and got["random labels"]["1"] == 0, "with one neighbour the field is wrong about none of its own samples, whoever labelled them, the coin too")
	check(got["one person"] == {"1": 0, "3": 2, "5": 7, "9": 6}, "one person, k 1, 3, 5, 9: wrong about %s of 36" % [got["one person"]])
	check(got["the class"]["3"] == 5 and got["a default dataset"]["3"] == 0 and got["random labels"]["3"] == 11, "with three: the class 5, the default dataset 0, random labels 11: %s" % [got])
	var from := printed.size()
	var body := field(0, 3)
	await frames(1)
	check(printed.slice(from).has("wrong about its own samples: 2 of 36"), "the script prints `wrong about its own samples: 2 of 36`")
	var which := []
	for i in 36:
		if body.says(body.chosen[i].x, body.chosen[i].z)[0] != body.chosen[i].label:
			which.append(i)
	measured["one_person_k3_wrong_samples"] = which
	check(which == [7, 21], "the two are sample 7, a stay alone among passes, and sample 21, a pass alone among stays: %s" % [which])
	await close(body)

## ---------------------------------------------------------------- a line

func a_line() -> void:
	measured["a_line_wrong"] = {}
	for who in 4:
		var body := field(who, 3, 1)
		await frames(1)
		var first: Vector3 = Vector3(body.weights.x, body.weights.y, body.bias)
		var wrong: int = body.wrong()
		body.train()
		var again := Vector3(body.weights.x, body.weights.y, body.bias)
		var by_rounds := {}
		for rounds: int in [99, 100, 101, 102]:
			body.train(rounds)
			by_rounds[str(rounds)] = body.wrong()
		measured["a_line_wrong"][NAMES[who]] = by_rounds
		if who == 0:
			check(first == again, "the line trained twice is the same line: weights and bias %s" % [first])
			var sure := true
			var by_side := true
			body.train()
			for cz in 20:
				for cx in 32:
					var said: Array = body.says(place(cx, cz).x, place(cx, cz).y)
					var sum: float = body.weights.x * place(cx, cz).x + body.weights.y * place(cx, cz).y + body.bias
					if said[1] != 1.0:
						sure = false
					if (said[0] == "stay") != (sum > 0.0):
						by_side = false
			check(sure and by_side, "the line answers every cell by its side, and is always sure")
			check(wrong == 21, "after 100 rounds one person's line is wrong about 21 of 36: %d" % wrong)
			check(by_rounds == {"99": 22, "100": 21, "101": 12, "102": 22}, "and it does not settle: after 99, 100, 101 and 102 rounds it is wrong about %s" % [by_rounds])
		if who == 2:
			check(by_rounds == {"99": 0, "100": 0, "101": 0, "102": 0}, "the default dataset's line is wrong about none, at every one of those rounds: %s" % [by_rounds])
		await close(body)
	check(measured["a_line_wrong"]["random labels"]["100"] == 21 and measured["a_line_wrong"]["the class"]["100"] == 15, "the class 15 and random labels 21 after 100 rounds: %s" % [measured["a_line_wrong"]])
	# XOR
	var body := field(0, 3, 0)
	await frames(1)
	var chosen_before: Array = body.chosen
	var missed: int = body.xor_wrong()
	measured["xor_wrong_of_4"] = missed
	check(missed == 2, "the line trained 1000 rounds on XOR is wrong about %d of 4" % missed)
	check(body.rule == 0 and body.chosen == chosen_before and body.chosen.size() == 36, "xor_wrong() puts the rule and the chosen samples back")
	# no line at all: every direction, every offset
	var xor := [[-1.0, -1.0, true], [1.0, 1.0, true], [-1.0, 1.0, false], [1.0, -1.0, false]]
	var fewest := 4
	for turn in 360:
		for step in 61:
			var normal := Vector2.from_angle(deg_to_rad(turn))
			var offset := (step - 30) * 0.1
			var count := 0
			for one: Array in xor:
				if (normal.x * one[0] + normal.y * one[1] + offset > 0.0) != one[2]:
					count += 1
			fewest = mini(fewest, count)
	check(fewest == 1, "of 360 directions and 61 offsets no line gets all four right; the best is wrong about %d" % fewest)
	await close(body)
	# the assert: a script whose test is turned round stops in _ready()
	var turned := GDScript.new()
	turned.source_code = learner.source_code.replace("assert(xor_wrong() > 0", "assert(xor_wrong() == 0")
	if turned.reload() == OK:
		var before := errors.size()
		var broken := field(0, 3, 0, turned)
		await frames(1)
		var said := ""
		for text in errors.slice(before):
			if text.contains("Assertion failed"):
				said = text
		measured["a_failed_assert_says"] = said
		check(said.contains("a line split XOR"), "with the assert turned round Godot says: %s" % said)
		check(broken.samples.is_empty(), "and the rest of _ready() is not run: no sample was loaded")
		await close(broken)
		# the same in the running scene, where a walker is there for _process() to ask
		var made: Node3D = load("res://learning_body.tscn").instantiate()
		made.get_node("Field").set_script(turned)
		made.get_node("Field").save_file = NO_FILE
		before = errors.size()
		root.add_child(made)
		await frames(30)
		measured["errors_in_30_frames_after_a_failed_assert"] = errors.size() - before
		check(errors.size() - before == 1, "in the running scene that is the only error in 30 frames: _process() waits for a text that was never made: %d" % (errors.size() - before))
		await close(made)
	else:
		check(false, "the script with its assert turned round parses")

## ---------------------------------------------------------------- the error

func the_error() -> void:
	var body := field(0, 3, 2)
	await frames(1)
	check(is_equal_approx(body.error_at(0.0, 0.0), 1.0), "in the middle of the floor both weights are 0 and the error is 1: %.3f" % body.error_at(0.0, 0.0))
	var want := 0.0
	for sample: Dictionary in of("the builder"):
		var target := 1.0 if sample.label == "stay" else -1.0
		want += pow(0.25 * -3.2 * sample.x + 0.25 * 2.0 * sample.z - target, 2) / 36.0
	check(absf(body.error_at(-3.2, 2.0) - want) < 0.0001, "where the walker starts it is %.2f, as the sum written out gives" % want)
	var path: Array = body.walk_down(Vector3(-3.2, 0, 2.0))
	var falling := true
	var before: float = body.error_at(-3.2, 2.0)
	for point: Vector3 in path:
		if body.error_at(point.x, point.z) >= before:
			falling = false
		before = body.error_at(point.x, point.z)
	var end: Vector3 = path[-1]
	var lower := 0
	for step: Vector3 in [Vector3(0.25, 0, 0), Vector3(-0.25, 0, 0), Vector3(0, 0, 0.25), Vector3(0, 0, -0.25)]:
		if body.error_at(end.x + step.x, end.z + step.z) < before:
			lower += 1
	measured["walk_down"] = {"steps": path.size(), "ends": [snappedf(end.x, 0.01), snappedf(end.z, 0.01)], "error_there": snappedf(before, 0.001)}
	check(falling and lower == 0, "walk_down() goes down at every one of its %d steps and ends where none of the four cells around is lower: (%.2f, %.2f), error %.3f" % [path.size(), end.x, end.z, before])
	check(path.size() == 17 and near(end, Vector3(-0.2, 0, 0.75), 0.001), "one person's: 17 steps to (-0.2, 0.75)")
	var unlike := 0
	for cz in 20:
		for cx in 32:
			var colour := Look.GROUND.lerp(Look.THIRD, minf(1.0, body.error_at(place(cx, cz).x, place(cx, cz).y) / 8.0))
			var got: Color = body.image.get_pixel(cx, cz)
			if absf(got.r - colour.r) + absf(got.g - colour.g) + absf(got.b - colour.b) > 0.02:
				unlike += 1
	check(unlike == 0, "with the rule at `the error` every pixel is GROUND turned toward THIRD by an eighth of the error there: %d of 640 are not" % unlike)
	await close(body)

## ---------------------------------------------------------------- the scene: stand on it, walk across

func the_scene() -> void:
	var before_errors := errors.size()
	var before_warnings := warnings.size()
	var made := scene()
	await frames(5)
	var learning: MeshInstance3D = made.get_node("Field")
	var walker: CharacterBody3D = made.get_node("Walker")
	check(made.get_node("Look/Sky") != null and made.get_node("Floor").material_override.albedo_color == Look.GROUND, "the scene stands on the supplied base: its sky, and the floor in GROUND")
	check(near(made.get_node("Camera3D").position, Vector3(0, 3.2, 7.6)), "its camera is moved back and up, to (0, 3.2, 7.6)")
	check(learning.readout.text == "you stand on stay, sure to 67%", "the walker starts on stay: the readout says \"%s\"" % learning.readout.text)
	await physics_frames(30)
	check(absf(walker.position.y) < 0.01, "it stands on the floor, its feet at %.2f m" % walker.position.y)
	# across the boundary, through three balls' places
	var seen := [learning.readout.text]
	walker.walk_to([Vector3(1.0, 0, 2.0)])
	while walker.walking:
		await process_frame
		if learning.readout.text != seen[-1]:
			seen.append(learning.readout.text)
	await frames(2)
	measured["across_the_boundary"] = {"ended": walker.ended, "readouts": seen, "at": [snappedf(walker.position.x, 0.01), snappedf(walker.position.z, 0.01)], "feet_at_m": snappedf(walker.position.y, 0.01)}
	check(walker.ended == "arrived" and absf(walker.position.y) < 0.01, "sent 4.2 m to the right, to (1.0, 2.0), it arrived with its feet at %.2f m: nothing on the field stops a body" % walker.position.y)
	check(seen[-1] == "you stand on pass, sure to 100%", "there the readout says \"%s\"" % seen[-1])
	check(seen.size() >= 3, "on the way the readout changed %d times: %s" % [seen.size() - 1, seen])
	# through a ball: the builder's sample 20 at (-2.25, 1.89)
	walker.stand_at(Vector3(-3.2, 0, 1.89))
	var how := await walk(walker, [Vector3(-1.4, 0, 1.89)])
	check(how == "arrived", "walked along z 1.89 through the ball at (-2.25, 1.89), it \"%s\": a ball has no collider" % how)
	await frames(120)
	check(errors.size() == before_errors and warnings.size() == before_warnings, "the scene ran more than 180 frames and Godot logged no error and no warning: %s %s" % [errors.slice(before_errors), warnings.slice(before_warnings)])
	await close(made)

## ---------------------------------------------------------------- your own labels

func your_own_labels() -> void:
	if FileAccess.file_exists(SCRATCH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH))
	var made := scene(0, 4, SCRATCH)
	await frames(5)
	var learning: MeshInstance3D = made.get_node("Field")
	var walker: CharacterBody3D = made.get_node("Walker")
	check(learning.chosen.is_empty() and learning.samples.size() == 144, "set to `you`, with no saved file: 144 samples, none of them chosen")
	measured["readout_with_no_label"] = learning.readout.text
	await press("pause")
	await frames(2)
	check(learning.samples.size() == 145 and learning.samples[-1] == {"x": -3.2, "z": 2.0, "label": "stay", "labelled_by": "you"}, "Space (the action pause) adds a sample where the walker stands, labelled stay by you: %s" % [learning.samples[-1]])
	check(learning.chosen.size() == 1 and learning.balls.size() == 1, "it is chosen at once, and a ball stands on it")
	var all_stay := true
	for cz in 20:
		for cx in 32:
			var got: Color = learning.image.get_pixel(cx, cz)
			var colour := Look.GROUND.lerp(Look.BODY, 0.75)
			if absf(got.r - colour.r) + absf(got.g - colour.g) + absf(got.b - colour.b) > 0.02:
				all_stay = false
	check(all_stay, "one label, and every one of the 640 cells says stay, sure to 100%")
	check(learning.readout.text == "you stand on stay, sure to 100%", "the readout: \"%s\"" % learning.readout.text)
	var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(SCRATCH))
	var good: bool = saved is Dictionary and saved.samples.size() == 145 and saved.samples[-1] == learning.samples[-1] and saved.consent.get("you") == true
	check(good, "the file is saved at once: 145 samples, the last one yours, and `you: true` under consent")
	check(FileAccess.get_file_as_string(SCRATCH).contains("\n\t\"consent\": {"), "it is written with JSON.stringify() and a tab, one field to a line")
	walker.stand_at(Vector3(2.0, 0, -1.0))
	await physics_frames(3)
	await press("drop")
	await frames(2)
	check(learning.samples.size() == 146 and learning.samples[-1] == {"x": 2.0, "z": -1.0, "label": "pass", "labelled_by": "you"}, "M (the action drop) adds one labelled pass: %s" % [learning.samples[-1]])
	var near_first: Array = learning.says(-3.0, 2.0)
	var near_second: Array = learning.says(2.0, -0.8)
	check(near_first[0] == "stay" and near_second[0] == "pass" and near_first[1] == 0.5, "two labels: each place takes the nearer one's, and no place is sure of it by more than a half: %s %s" % [near_first, near_second])
	await close(made)
	# the next start reads the saved file
	var from := printed.size()
	var again := field(4, 3, 0, null, SCRATCH)
	await frames(1)
	check(again.file == SCRATCH and again.samples.size() == 146 and again.chosen.size() == 2, "started again, the script finds the saved file and reads it: 146 samples, 2 chosen")
	var said := ""
	for text in printed.slice(from):
		if text.begins_with("2 of 146 samples"):
			said = text
	measured["printed_for_you"] = said
	check(said.contains("\"you\": true"), "and prints your consent: %s" % said)
	await close(again)
	var others := field(0, 3, 0, null, SCRATCH)
	await frames(1)
	check(others.chosen.size() == 36 and others.wrong() == 2, "the other four values still train on their own 36: one person is wrong about 2 as before")
	await close(others)

## ---------------------------------------------------------------- downhill

func downhill() -> void:
	var before_errors := errors.size()
	var made := scene(2)
	var learning: MeshInstance3D = made.get_node("Field")
	var walker: CharacterBody3D = made.get_node("Walker")
	await frames(2)
	check(walker.walking, "with the rule at `the error` the field sends the walker downhill as the scene starts")
	if not walker.walking:
		await close(made)
		return
	var how: String = await walker.walk_ended
	await frames(3)
	var at := walker.position
	measured["downhill"] = {"ended": how, "at": [snappedf(at.x, 0.01), snappedf(at.z, 0.01)], "feet_at_m": snappedf(at.y, 0.01), "readout": learning.readout.text}
	check(how == "arrived" and Vector2(at.x + 0.2, at.z - 0.75).length() < 0.11, "it \"%s\" within a step's slack of (-0.2, 0.75): (%.2f, %.2f)" % [how, at.x, at.z])
	check(learning.readout.text.begins_with("error 0.9") and learning.readout.text.ends_with("gets 15 of 36 wrong"), "the readout there: \"%s\"" % learning.readout.text)
	var laid: MeshInstance3D = learning.line
	var along := laid.global_basis.y
	var weights: Vector2 = learning.weights
	check(laid.visible and laid.mesh is CylinderMesh and absf((laid.mesh as CylinderMesh).height - 4.8) < 0.001, "the line of the weights lies on the floor, 4.8 m long")
	check(absf(along.x * weights.x + along.z * weights.y) < 0.001 and weights.is_equal_approx(Vector2(at.x, at.z) * 0.25), "at right angles to the walker's place, whose x and z, a quarter each, are the two weights: %s" % [weights])
	check(errors.size() == before_errors, "Godot logged no error: %s" % [errors.slice(before_errors)])
	await close(made)

## ---------------------------------------------------------------- the guest

func the_guest() -> void:
	var needs := CheckGuest.outside("res://guests/learning-body/")
	check(needs.is_empty(), "the guest names nothing outside its folder: %s" % [needs])
	check(CheckGuest.class_names("res://guests/learning-body/").is_empty(), "the guest declares no class_name")
	var files := DirAccess.get_files_at("res://guests/learning-body/")
	var names := Array(files)
	names.sort()
	check(names == ["learning-body.tscn", "portrait.gd", "samples.json"], "its folder holds three files: %s" % [names])
	var own: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://guests/learning-body/samples.json"))
	check(own is Dictionary and own.samples == of("the builder") and own.consent == {"the builder": true}, "its samples.json is the builder's 36 samples of the kit's file, in the floor's own metres, with the builder's consent")
	var base: Node3D = load("res://supplied/base.tscn").instantiate()
	root.add_child(base)
	var before := errors.size()
	var from := printed.size()
	var guest: Node3D = load("res://guests/learning-body/learning-body.tscn").instantiate()
	base.add_child(guest)
	await frames(3)
	var box := AABB()
	var first := true
	for part: GeometryInstance3D in guest.find_children("*", "GeometryInstance3D", true, false):
		var here: AABB = part.global_transform * part.get_aabb()
		box = here if first else box.merge(here)
		first = false
	measured["guest_box"] = {"wide": snappedf(box.size.x, 0.01), "deep": snappedf(box.size.z, 0.01), "high": snappedf(box.end.y, 0.01), "lowest": snappedf(box.position.y, 0.01)}
	check(box.size.x <= 1.6 and box.size.z <= 1.6 and absf(box.position.y) < 0.001, "it stands on the ground and fits the place, its words too: %.2f m wide, %.2f m deep, %.2f m high" % [box.size.x, box.size.z, box.end.y])
	check(guest.chosen.size() == 36 and guest.wrong() == 2 and guest.left_out_wrong() == 8, "trained on 36 labels: wrong about %d of its own and %d when each is left out" % [guest.wrong(), guest.left_out_wrong()])
	check(printed.slice(from).has("36 labels by the builder; consent recorded; wrong about 2 of its own; and 8 when each is left out"), "it prints what it says of itself")
	var kit := field(0, 3)
	await frames(1)
	var unlike := 0
	for cz in 20:
		for cx in 32:
			if guest.says(place(cx, cz).x, place(cx, cz).y) != kit.says(place(cx, cz).x, place(cx, cz).y):
				unlike += 1
	check(unlike == 0, "its vote is the kit's: all 640 cells get the same label and share from both")
	await close(kit)
	var marble: RigidBody3D = load("res://supplied/marble.tscn").instantiate()
	base.add_child(marble)
	marble.drop(Vector3(0.3, 1.0, 0.1))
	var rest := await settle(marble)
	check(absf(rest.y - 0.2) < 0.01, "a marble dropped on it rests on the slab, its middle at %.2f m" % rest.y)
	marble.free()
	var walker: CharacterBody3D = load("res://supplied/walker.tscn").instantiate()
	walker.position = Vector3(-0.3, 0, 2.0)
	base.add_child(walker)
	await frames(2)
	check(guest.readout.text == guest.about, "with nobody on it, it says what it was trained on")
	var how := await walk(walker, [Vector3(-0.3, 0, 0.2)])
	await physics_frames(3)
	await frames(2)
	var want: Array = guest.says(walker.position.x / 0.19, walker.position.z / 0.19)
	measured["on_the_guest"] = {"ended": how, "feet_at_m": snappedf(walker.position.y, 0.01), "readout": guest.readout.text.get_slice("\n", 0)}
	check(how == "arrived" and absf(walker.position.y - 0.1) < 0.01, "the walker, sent onto it, \"%s\" with its feet at %.2f m: it stepped up onto the slab" % [how, walker.position.y])
	check(guest.readout.text.begins_with("you stand on %s, sure to %d%%" % [want[0], roundi(want[1] * 100)]), "and is told what it stands on: \"%s\"" % guest.readout.text.get_slice("\n", 0))
	var words: AABB = guest.readout.get_aabb()
	measured["guest_box"]["words_wide_with_a_walker_on_it"] = snappedf(words.size.x, 0.01)
	check(words.size.x <= 1.6, "its words, one line longer now, are %.2f m wide: still inside the place" % words.size.x)
	how = await walk(walker, [Vector3(0.5, 0, 0.2)])
	await frames(2)
	measured["on_the_guest"]["after_a_step_to_the_right"] = guest.readout.text.get_slice("\n", 0)
	check(guest.readout.text.begins_with("you stand on pass"), "0.8 m to the right on the slab it stands on the other label: \"%s\"" % guest.readout.text.get_slice("\n", 0))
	check(errors.size() == before, "the guest ran with a marble and a walker on it and Godot logged no error: %s" % [errors.slice(before)])
	await close(base)
