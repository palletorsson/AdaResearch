extends "res://supplied/verify_tools.gd"
## Headless checks of the kit "A colour has many faces". From this folder:
##   godot --headless --path . --xr-mode off --script res://verify.gd
## Writes verification.json beside this file; the exit code is the number of
## checks that failed. No import step is needed: nothing here has a class_name.
## Headless draws no frames, so what the eye gets (the four walls as stills,
## the steps under the lamp) is measured by sheet.gd, which needs a window.

const Look := preload("res://supplied/look.gd")
const CheckGuest := preload("res://supplied/check_guest.gd")
const Wall := preload("res://wall.gd")
const Oklab := preload("res://oklab.gd")
const GUEST := "res://guests/colour-faces/"
const SPACES := ["rgb", "hsv", "linear", "oklab"]
const SUPPLIED := ["base.tscn", "base_look.gd", "check_guest.gd", "look.gd", "marble.gd", "marble.tscn", "mover.gd", "segment.gd",
	"sheet_tools.gd", "sweep_sheet.gd", "sweep_sheet.tscn", "trace_strip.gd", "verify_tools.gd", "walker.gd", "walker.tscn"]

func hex(c: Color) -> String:
	return c.to_html(false)

## Two colours are the same on a screen when no channel is more than one of 255 apart.
func same(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < 0.0045 and absf(a.g - b.g) < 0.0045 and absf(a.b - b.b) < 0.0045

func text_of(path: String) -> String:
	return FileAccess.get_file_as_string(path)

## A wall in `space`, not yet in the scene.
func wall_of(space: String, first := Look.BODY, second := Look.BODY.inverted()) -> Node3D:
	var wall := Wall.new()
	wall.space = space
	wall.first = first
	wall.second = second
	return wall

## How many of nine steps from a to b have a hue far from red: between yellow and violet.
func far_from_red(colours: Array) -> int:
	var count := 0
	for c: Color in colours:
		if c.h > 0.17 and c.h < 0.83:
			count += 1
	return count

func run() -> void:
	project()
	interpolation()
	hue()
	await wall_class()
	oklab()
	await scene()
	await guest()

func project() -> void:
	check(ProjectSettings.get_setting("application/config/name") == "Colour faces" and ProjectSettings.get_setting("application/run/main_scene") == "res://faces.tscn"
		and ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility",
		"the project is named Colour faces, its main scene is faces.tscn, its renderer Compatibility")
	var named := []
	var supplied := []
	for file in DirAccess.get_files_at("res://supplied"):
		if not file.ends_with(".uid"):
			supplied.append(file)
		if file.ends_with(".gd") and RegEx.create_from_string("(?m)^\\s*class_name\\s").search(text_of("res://supplied/" + file)) != null:
			named.append(file)
	check(supplied == SUPPLIED, "supplied/ holds the base's 15 files: %s" % [supplied])
	check(named.is_empty() and ProjectSettings.get_global_class_list().is_empty(), "no script declares a class_name and the project lists no named class: nothing needs an import")
	var spaced := []
	for folder: String in ["res://", "res://supplied/", GUEST]:
		for file in DirAccess.get_files_at(folder):
			if file.ends_with(".gd") and RegEx.create_from_string("(?m)^ +\\S").search(text_of(folder + file)) != null:
				spaced.append(file)
	check(spaced.is_empty(), "every script is indented with tabs: %s" % [spaced])

## lerp() on numbers and on colours, and the pair the kit mixes.
func interpolation() -> void:
	check(lerp(0.0, 10.0, 0.25) == 2.5 and lerp(0.0, 10.0, 0.5) == 5.0 and lerp(4.0, 8.0, 0.5) == 6.0 and lerpf(4.0, 8.0, 0.5) == 6.0,
		"lerp(0.0, 10.0, 0.25) is 2.5, lerp(0.0, 10.0, 0.5) is 5.0, lerp(4.0, 8.0, 0.5) is 6.0, and lerpf() gives the same")
	var first := Look.BODY
	var second := first.inverted()
	var middle := first.lerp(second, 0.5)
	check(hex(first) == "c6ff3d" and hex(second) == "3900c2", "the pair is BODY, c6ff3d, and BODY.inverted(), %s" % hex(second))
	check(hex(middle) == "808080" and middle.s == 0.0, "half way between them in RGB is %s, a grey: its saturation is %s" % [hex(middle), middle.s])
	check(is_equal_approx(first.h + 0.5, second.h), "the two hues are half a turn apart: %.4f and %.4f" % [first.h, second.h])
	# The lesson's variation: t from a whole-number division.
	var cut := []
	for i in 9:
		@warning_ignore("integer_division")
		cut.append(i / (9 - 1))
	check(cut == [0, 0, 0, 0, 0, 0, 0, 0, 1], "without float() the weight is a whole number: %s, eight steps in the first colour and one in the second" % [cut])
	# The lesson's other variation: plain lerp() where := needs a type.
	var before := errors.size()
	var script := GDScript.new()
	script.source_code = "extends Node\n\nfunc f(a: float, b: float, t: float) -> void:\n\tvar h := lerp(a, b, t)\n\tprint(h)\n"
	var result := script.reload()
	var said := errors.slice(before)
	var message := ""
	for line: String in said:
		if line.contains("inferred from a Variant"):
			message = line.get_slice(" (gdscript://", 0)
	check(result != OK and message.contains("The variable type is being inferred from a Variant value, so it will be typed as Variant. (Warning treated as error.)"),
		"`var h := lerp(a, b, t)` does not compile: %s" % message)
	measured["lerp_with_inferred_type"] = message
	measured["pair"] = {"first": hex(first), "second": hex(second), "first_hsv": [snappedf(first.h, 0.0001), snappedf(first.s, 0.0001), snappedf(first.v, 0.0001)],
		"second_hsv": [snappedf(second.h, 0.0001), snappedf(second.s, 0.0001), snappedf(second.v, 0.0001)], "rgb_middle": hex(middle)}

## The planted bug: a hue is a place on a circle, and lerp() does not know it.
func hue() -> void:
	var pink := Look.SKY
	var orange := Look.THIRD
	check(absf(pink.h - 0.9195) < 0.001 and absf(orange.h - 0.0804) < 0.001, "SKY has hue %.3f and THIRD hue %.3f: 0.161 of a turn apart across red, 0.839 the other way" % [pink.h, orange.h])
	var plain := []
	for i in 9:
		var t := i / 8.0
		plain.append(Color.from_hsv(lerpf(pink.h, orange.h, t), lerpf(pink.s, orange.s, t), lerpf(pink.v, orange.v, t)))
	check(far_from_red(plain) == 7 and hex(plain[4]) == "26ffff", "lerpf() on the two hues goes the long way round: 7 of 9 steps lie between yellow and violet, the middle one is %s, a cyan" % hex(plain[4]))
	var wall := wall_of("hsv", pink, orange)
	var wrapped := []
	for i in 9:
		wrapped.append(wall.mix(i / 8.0))
	check(far_from_red(wrapped) == 0 and same(wrapped[0], pink) and same(wrapped[8], orange), "with the difference wrapped the wall goes across red: none of its 9 steps lies between yellow and violet, the middle one is %s" % hex(wrapped[4]))
	wall.free()
	var listed := []
	for c: Color in plain:
		listed.append(hex(c))
	measured["long_way_round"] = listed
	listed = []
	for c: Color in wrapped:
		listed.append(hex(c))
	measured["across_red"] = listed
	# Complements are exactly half a turn apart: both ways round are equally long.
	var first := Look.BODY
	var second := first.inverted()
	var turn: float = second.h - first.h
	wall = wall_of("hsv")
	var middle: Color = wall.mix(0.5)
	check(turn > 0.5 and turn - 0.5 < 0.000001, "for the complements the difference of the hues is %.8f, more than a half by a rounding error, so the `if` fires" % turn)
	check(hex(middle) == "e11b44" and (middle.h > 0.9 or middle.h < 0.1), "and the HSV wall goes from lime to violet by way of red: its middle is %s, hue %.3f" % [hex(middle), middle.h])
	var other := Color.from_hsv(lerpf(first.h, second.h, 0.5), lerpf(first.s, second.s, 0.5), lerpf(first.v, second.v, 0.5))
	check(other.h > 0.4 and other.h < 0.55, "without the wrap it goes the other way, by cyan: the middle is %s, hue %.3f. Both ways are half a turn" % [hex(other), other.h])
	measured["complement_turn"] = turn
	measured["hsv_middle_by_red"] = hex(middle)
	measured["hsv_middle_by_cyan"] = hex(other)
	wall.free()

## wall.gd: one description, four spaces.
func wall_class() -> void:
	var base: Node3D = load("res://supplied/base.tscn").instantiate()
	root.add_child(base)
	var middles := {}
	var saturation := {}
	var lowest := {}
	var built_ok := true
	var ends_ok := true
	var distinct := true
	for space: String in SPACES:
		var wall := wall_of(space)
		base.add_child(wall)
		await frames(1)
		built_ok = built_ok and wall.boxes.size() == 9 and wall.get_child_count() == 9
		for i in wall.boxes.size():
			var box: MeshInstance3D = wall.boxes[i]
			built_ok = built_ok and is_equal_approx(box.position.x, (i - 4) * 0.4) and is_equal_approx(box.position.y, 0.225)
			built_ok = built_ok and box.get_child_count() == 1 and box.get_child(0) is StaticBody3D
			built_ok = built_ok and same(box.material_override.albedo_color, wall.mix(i / 8.0))
		ends_ok = ends_ok and same(wall.boxes[0].material_override.albedo_color, Look.BODY) and same(wall.boxes[8].material_override.albedo_color, Look.BODY.inverted())
		var seen := {}
		var least := 1.0
		for i in 9:
			var c: Color = wall.mix(i / 8.0)
			seen[hex(c)] = true
			least = minf(least, c.s)
		distinct = distinct and seen.size() == 9
		middles[space] = hex(wall.mix(0.5))
		saturation[space] = snappedf(wall.mix(0.5).s, 0.001)
		lowest[space] = snappedf(least, 0.001)
		wall.free()
	check(built_ok, "a wall builds 9 steps, 0.4 m apart, each a box with a collider under it, each painted mix(t) with t from 0 to 1")
	check(ends_ok, "in all four spaces the first step is BODY and the last its complement: the spaces agree about the ends")
	check(distinct, "and each wall has nine different colours: t is not cut to a whole number")
	check(middles == {"rgb": "808080", "hsv": "e11b44", "linear": "96bc93", "oklab": "6a9ca8"}, "the four middles are four colours: %s" % [middles])
	check(saturation["rgb"] == 0.0 and lowest["rgb"] == 0.0, "the RGB wall reaches grey: saturation 0 at its middle")
	check(lowest["hsv"] > 0.75, "the HSV wall never comes near grey: its least saturated step has %.3f" % lowest["hsv"])
	check(lowest["linear"] > 0.15 and lowest["linear"] < 0.25, "the linear-light wall does not reach grey between these two: its least saturated step has %.3f, its middle %.3f" % [lowest["linear"], saturation["linear"]])
	check(lowest["oklab"] > 0.25, "nor does the OKLab wall: least %.3f, middle %.3f" % [lowest["oklab"], saturation["oklab"]])
	var wall := wall_of("linear")
	var by_hand := (Look.BODY.srgb_to_linear().lerp(Look.BODY.inverted().srgb_to_linear(), 0.5)).linear_to_srgb()
	var forgotten := Look.BODY.srgb_to_linear().lerp(Look.BODY.inverted().srgb_to_linear(), 0.5)
	check(same(wall.mix(0.5), by_hand) and not same(wall.mix(0.5), forgotten), "linear mixes after srgb_to_linear() and comes back with linear_to_srgb(): %s; without the way back it would be %s" % [hex(by_hand), hex(forgotten)])
	wall.free()
	# Red and cyan are complements in every one of the four: the control pair.
	var control := {}
	var control_lowest := {}
	for space: String in SPACES:
		wall = wall_of(space, Color.RED, Color.CYAN)
		var least := 1.0
		for i in 101:
			least = minf(least, wall.mix(i / 100.0).s)
		control[space] = hex(wall.mix(0.5))
		control_lowest[space] = snappedf(least, 0.001)
		wall.free()
	check(control["rgb"] == "808080" and control["linear"] == "bcbcbc" and control_lowest["hsv"] == 1.0, "between red and cyan RGB and linear light both reach a grey, %s and %s, and HSV never leaves full saturation: %s" % [control["rgb"], control["linear"], control])
	# The same question the other way round: take the complement in linear light, not in RGB.
	var lin := Look.BODY.srgb_to_linear()
	var other := Color(1.0 - lin.r, 1.0 - lin.g, 1.0 - lin.b).linear_to_srgb()
	wall = wall_of("linear", Look.BODY, other)
	var linear_middle: Color = wall.mix(0.5)
	wall.space = "rgb"
	var rgb_middle: Color = wall.mix(0.5)
	check(hex(linear_middle) == "bcbcbc" and rgb_middle.s > 0.1, "with the complement taken in linear light (%s) it is the linear wall that reaches grey, %s, and the RGB wall that misses it: %s, saturation %.3f" % [hex(other), hex(linear_middle), hex(rgb_middle), rgb_middle.s])
	measured["complement_in_linear_light"] = {"second": hex(other), "linear_middle": hex(linear_middle), "rgb_middle": hex(rgb_middle), "rgb_middle_saturation": snappedf(rgb_middle.s, 0.001)}
	wall.free()
	# Is a wall's walk even? It depends on the ruler. Each wall's eight gaps, measured two ways:
	# the largest gap divided by the smallest, 1.0 when all eight are the same.
	var even := {}
	for space: String in SPACES:
		wall = wall_of(space)
		var by_rgb := []
		var by_oklab := []
		for i in 8:
			var p: Color = wall.mix(i / 8.0)
			var q: Color = wall.mix((i + 1) / 8.0)
			by_rgb.append(Vector3(p.r - q.r, p.g - q.g, p.b - q.b).length())
			by_oklab.append(Oklab.apart(p, q))
		even[space] = {"rgb_ruler": snappedf(by_rgb.max() / by_rgb.min(), 0.01), "oklab_ruler": snappedf(by_oklab.max() / by_oklab.min(), 0.01)}
		wall.free()
	var best_rgb := ""
	var best_oklab := ""
	for space: String in SPACES:
		if best_rgb == "" or even[space]["rgb_ruler"] < even[best_rgb]["rgb_ruler"]:
			best_rgb = space
		if best_oklab == "" or even[space]["oklab_ruler"] < even[best_oklab]["oklab_ruler"]:
			best_oklab = space
	check(best_rgb == "rgb" and best_oklab == "oklab" and even["rgb"]["rgb_ruler"] < 1.01 and even["oklab"]["oklab_ruler"] < 1.01,
		"each ruler finds its own wall the most even: by distance in RGB the RGB wall (largest gap / smallest %.2f), by distance in OKLab the OKLab wall (%.2f); the others: %s" % [even["rgb"]["rgb_ruler"], even["oklab"]["oklab_ruler"], even])
	measured["largest_gap_over_smallest"] = even
	measured["middles"] = middles
	measured["middle_saturation"] = saturation
	measured["least_saturation"] = lowest
	measured["red_cyan_middles"] = control
	measured["red_cyan_least_saturation"] = control_lowest
	# A name the class does not know.
	var before := errors.size()
	wall = wall_of("hsl")
	base.add_child(wall)
	await frames(1)
	var black := true
	for box: MeshInstance3D in wall.boxes:
		black = black and box.material_override.albedo_color == Color.BLACK
	var said := errors.slice(before)
	check(said.size() == 9 and said[0].contains("wall.gd has no space called hsl") and black, "a space the wall does not know is loud: 9 error lines (%s) and 9 black steps" % [said[0] if not said.is_empty() else ""])
	wall.free()
	wall = wall_of("rgb")
	wall.steps = 1
	base.add_child(wall)
	await frames(1)
	check(wall.steps == 2 and wall.boxes.size() == 2 and hex(wall.boxes[1].material_override.albedo_color) == "3900c2", "asked for 1 step the wall builds 2: there is no way from a colour to another in fewer")
	base.free()
	await frames(1)

## The supplied space.
func oklab() -> void:
	var white := Oklab.from_srgb(Color.WHITE)
	var red := Oklab.from_srgb(Color.RED)
	check(white.distance_to(Vector3(1, 0, 0)) < 0.0005 and red.distance_to(Vector3(0.62796, 0.22486, 0.12585)) < 0.0005,
		"oklab.gd: white is (1, 0, 0) and red is (%.3f, %.3f, %.3f), the published values" % [red.x, red.y, red.z])
	var back_ok := true
	for c: Color in [Look.SKY, Look.GROUND, Look.BODY, Look.SECOND, Look.THIRD, Look.BONE, Look.GHOST, Look.SHADE, Look.BODY.inverted()]:
		back_ok = back_ok and same(Oklab.to_srgb(Oklab.from_srgb(c)), c) and same(Oklab.mix(c, Color.BLACK, 0.0), c) and same(Oklab.mix(Color.BLACK, c, 1.0), c)
	check(back_ok, "oklab.gd: every colour of the palette comes back from OKLab as itself, and mix() gives the two ends at t = 0 and t = 1")
	var cuts := 0
	for i in 101:
		if Oklab.cut(Oklab.from_srgb(Look.BODY).lerp(Oklab.from_srgb(Look.BODY.inverted()), i / 100.0)):
			cuts += 1
	check(cuts == 0, "oklab.gd: between BODY and its complement no colour had to be cut to fit the screen (%d of 101)" % cuts)
	check(Oklab.apart(Look.BODY, Look.BODY) == 0.0 and Oklab.apart(Color.BLACK, Color.WHITE) > 99.9, "oklab.gd: apart() is 0 for a colour and itself and %.1f for black and white" % Oklab.apart(Color.BLACK, Color.WHITE))
	measured["oklab_cut_of_101"] = cuts

## The scene as the learner runs it: four walls, a walker, a lamp, a ray.
func scene() -> void:
	var before := errors.size()
	var lines := printed.size()
	var faces: Node3D = load("res://faces.tscn").instantiate()
	root.add_child(faces)
	await frames(180)
	var said := printed.slice(lines)
	check(errors.size() == before, "faces.tscn ran 180 frames and Godot logged no error: %s" % [errors.slice(before)])
	check(said == ["rgb: the middle is 808080", "hsv: the middle is e11b44", "linear: the middle is 96bc93", "oklab: the middle is 6a9ca8"], "it printed the four middles: %s" % [said])
	var stacked: bool = faces.walls.size() == 4
	for i in faces.walls.size():
		stacked = stacked and faces.walls[i].position.is_equal_approx(Vector3(0, i * 0.45, -1)) and faces.walls[i].space == SPACES[i]
	check(stacked, "four walls stand one on the other at z = -1, the first on the floor: rgb, hsv, linear, oklab")
	var walker: CharacterBody3D = faces.get_node("Walker")
	var lamp: SpotLight3D = faces.lamp
	check(lamp.get_parent() == faces and lamp.light_color == Color.WHITE and near(lamp.position, walker.position + Vector3(0, 0.7, 0), 0.01) and is_equal_approx(lamp.spot_angle, 25.0),
		"the lamp is a SpotLight3D, white, 0.7 m above the walker's feet, with a cone of 25 degrees")
	var how := await walk(walker, [Vector3(0, 0, 1.6)])
	await frames(2)
	check(how == "arrived" and near(lamp.position, walker.position + Vector3(0, 0.7, 0), 0.01) and absf(lamp.position.x) < 0.11,
		"the walker walks along the wall to its middle (\"%s\") and the lamp goes with it: the lamp is at %s" % [how, lamp.position.snappedf(0.01)])
	check(is_zero_approx(lamp.rotation.y) and not is_zero_approx(walker.rotation.y), "the walker turned the way it walked; the lamp did not turn: it points at the wall")
	walker.stand_at(Vector3(-1.0, 0, 1.6))
	walker.rotation.y = 0.0
	await physics_frames(3)
	await hold("move_right", 30)
	await frames(2)
	check(absf(walker.global_position.x) < 0.05 and is_zero_approx(walker.rotation.y) and absf(walker.global_position.z - 1.6) < 0.01 and near(lamp.position, walker.position + Vector3(0, 0.7, 0), 0.01),
		"with the key D held for half a second the walker goes 1 m to the right, still facing the wall, and the lamp with it: x = %.2f" % walker.global_position.x)
	lines = printed.size()
	await press("pause")
	var first_light := lamp.light_color
	await press("pause")
	var second_light := lamp.light_color
	await press("pause")
	check(same(first_light, Look.BODY) and same(second_light, Look.BODY.inverted()) and lamp.light_color == Color.WHITE,
		"Space gives the lamp the next colour: %s, %s, then white again; it printed %s" % [hex(first_light), hex(second_light), printed.slice(lines)])
	# The ray: straight ahead of the lamp, 0.7 m up, is the middle step of the second wall.
	await physics_frames(2)
	var target: MeshInstance3D = faces.walls[1].boxes[4]
	var others := []
	for wall: Node3D in faces.walls:
		for box: MeshInstance3D in wall.boxes:
			if box != target:
				others.append(box.material_override.albedo_color)
	var was: Color = target.material_override.albedo_color
	await press("pause")     # the lamp is lime
	lines = printed.size()
	await press("drop")
	var now: Color = target.material_override.albedo_color
	said = printed.slice(lines)
	var untouched := true
	var k := 0
	for wall: Node3D in faces.walls:
		for box: MeshInstance3D in wall.boxes:
			if box != target:
				untouched = untouched and box.material_override.albedo_color == others[k]
				k += 1
	check(same(now, was.lerp(Look.BODY, 0.5)) and not same(now, was) and untouched,
		"M paints the step the ray meets, the middle of the HSV wall, half way to the lamp's colour: %s became %s; the other 35 steps kept theirs" % [hex(was), hex(now)])
	check(said == ["painted %s to %s" % [hex(was), hex(now)]], "and it printed what it did: %s" % [said])
	await press("drop")
	check(same(target.material_override.albedo_color, now.lerp(Look.BODY, 0.5)), "a second M goes half of what is left: %s" % hex(target.material_override.albedo_color))
	measured["painted"] = [hex(was), hex(now), hex(target.material_override.albedo_color)]
	# A body meets the wall.
	how = await walk(walker, [Vector3(0, 0, -1)])
	check(how == "blocked" and absf(walker.global_position.z - (-0.6)) < 0.06, "walked at the wall the walker is stopped by it (\"%s\"), its middle at z = %.2f, 0.3 m from the wall's face" % [how, walker.global_position.z])
	measured["walker_stopped_at_z"] = snappedf(walker.global_position.z, 0.01)
	await physics_frames(3)
	lines = printed.size()
	await press("drop")
	check(printed.slice(lines).size() == 1 and printed.slice(lines)[0].begins_with("painted "), "with the walker against the wall the ray still meets a step: %s" % [printed.slice(lines)])
	# Turned round, the lamp points at nothing.
	walker.stand_at(Vector3(0, 0, 1.6))
	faces.ray.target_position = Vector3(0, 0, 6)
	await physics_frames(3)
	lines = printed.size()
	await press("drop")
	check(printed.slice(lines) == ["the ray met nothing"], "a ray that meets no step says so: %s" % [printed.slice(lines)])
	var marble: RigidBody3D = load("res://supplied/marble.tscn").instantiate()
	faces.add_child(marble)
	marble.drop(Vector3(0.0, 2.6, -1.0))
	var rest := await settle(marble)
	check(absf(rest.y - 1.9) < 0.01, "a marble dropped over the top wall comes to rest on it, at %.2f m: the wall is a body" % rest.y)
	measured["marble_rests_at_m"] = snappedf(rest.y, 0.01)
	check(errors.size() == before, "and Godot logged no error to the end: %s" % [errors.slice(before)])
	faces.free()
	await frames(1)
	# The lesson's variation: a name the class does not know, in the scene.
	before = errors.size()
	lines = printed.size()
	faces = load("res://faces.tscn").instantiate()
	faces.spaces = "rgb, hsl"
	root.add_child(faces)
	await frames(3)
	var loud := errors.slice(before)
	check(loud.size() == 10 and loud[0] == "ERROR: wall.gd has no space called hsl" and printed.slice(lines).has("hsl: the middle is 000000"),
		"with `rgb, hsl` in spaces the scene logs %d lines `%s` and prints `hsl: the middle is 000000`" % [loud.size(), loud[0] if not loud.is_empty() else ""])
	measured["unknown_space_error_lines"] = loud.size()
	faces.free()
	await frames(1)

## The body handed to the room.
func guest() -> void:
	var needs := CheckGuest.outside(GUEST)
	check(needs.is_empty(), "the guest names nothing outside its folder: %s" % [needs])
	check(CheckGuest.class_names(GUEST).is_empty(), "the guest declares no class_name")
	var palette: Resource = load(GUEST + "palette.tres")
	var has_all: bool = palette != null and palette.get_script() == load(GUEST + "palette.gd")
	for field: String in ["first", "second", "space", "steps", "because"]:
		has_all = has_all and palette != null and palette.get(field) != null
	check(has_all, "palette.tres is a Resource with palette.gd as its script and the fields first, second, space, steps and because")
	if not has_all:
		return
	check(SPACES.has(palette.space) and palette.steps >= 2 and (palette.because as String).length() > 20, "the shipped palette mixes %s and %s in %s, in %d steps, and says why" % [hex(palette.first), hex(palette.second), palette.space, palette.steps])
	# Two implementations of one rule drift: the palette's mix() against the wall's.
	var agree := true
	var copy: Resource = palette.duplicate()
	for pair: Array in [[Look.BODY, Look.BODY.inverted()], [Look.SKY, Look.THIRD], [Color.RED, Color.CYAN], [Look.SECOND, Look.GROUND]]:
		copy.first = pair[0]
		copy.second = pair[1]
		for space: String in SPACES:
			copy.space = space
			var wall := wall_of(space, pair[0], pair[1])
			for i in 33:
				agree = agree and same(copy.mix(i / 32.0), wall.mix(i / 32.0))
			wall.free()
	check(agree, "the guest's palette.gd and the kit's wall.gd give the same colour for 4 pairs, 4 spaces and 33 values of t")
	# The lesson's room task: eight squares in a row, t = column / 7, for our own palette of the trial.
	copy.first = Color(1, 0.1804, 0.5765, 1)
	copy.second = Color(1, 0.5451, 0.1216, 1)
	copy.space = "hsv"
	var squares := []
	for column in 8:
		squares.append(hex(copy.mix(column / 7.0)))
	check(squares[0] == "ff2e93" and squares[1] == "ff2c75" and squares[2] == "ff2a56" and squares[7] == "ff8b1f", "pink and orange in hsv give a row of eight squares from %s to %s: %s" % [squares[0], squares[7], squares])
	measured["room_squares_pink_to_orange_in_hsv"] = squares
	var before := errors.size()
	copy.space = "hsl"
	check(copy.mix(0.5) == Color.BLACK and errors.size() == before + 1, "and a space it does not know is as loud there: %s" % [errors.slice(before)])
	var base: Node3D = load("res://supplied/base.tscn").instantiate()
	root.add_child(base)
	before = errors.size()
	var guest_scene: Node = load(GUEST + "colour-faces.tscn").instantiate()
	base.add_child(guest_scene)
	await frames(3)
	check(guest_scene is Node3D and errors.size() == before, "the guest's first node is a Node3D and it enters a scene with no error")
	var box := AABB()
	var first_box := true
	for part: Node in guest_scene.find_children("*", "MeshInstance3D", true, false):
		var here: AABB = (part as MeshInstance3D).global_transform * (part as MeshInstance3D).get_aabb()
		box = here if first_box else box.merge(here)
		first_box = false
	check(box.size.x <= 1.6 and box.size.z <= 1.6 and absf(box.position.y) < 0.001 and absf(box.get_center().x) < 0.001 and absf(box.get_center().z) < 0.001,
		"it stands on the ground at its own origin and fits the place: %.2f m wide, %.2f m deep, %.2f m high" % [box.size.x, box.size.z, box.size.y])
	var shows: bool = guest_scene.boxes.size() == palette.steps
	for i in guest_scene.boxes.size():
		shows = shows and same(guest_scene.boxes[i].material_override.albedo_color, palette.step(i))
	check(shows, "its %d steps are the palette's: step(0) to step(%d)" % [guest_scene.boxes.size(), guest_scene.boxes.size() - 1])
	var walker: CharacterBody3D = load("res://supplied/walker.tscn").instantiate()
	walker.position = Vector3(0, 0, 2)
	base.add_child(walker)
	await physics_frames(20)
	var how := await walk(walker, [Vector3.ZERO])
	check(how == "blocked" and absf(walker.global_position.z - 0.4) < 0.06, "a walker sent at it is stopped (\"%s\") at z = %.2f, 0.3 m from its face" % [how, walker.global_position.z])
	var marble: RigidBody3D = load("res://supplied/marble.tscn").instantiate()
	base.add_child(marble)
	marble.drop(Vector3(0.3, 2.0, 0.0))
	var rest := await settle(marble)
	check(absf(rest.y - 1.1) < 0.01, "a marble dropped on it rests on its top, at %.2f m" % rest.y)
	measured["guest"] = {"width_m": snappedf(box.size.x, 0.01), "depth_m": snappedf(box.size.z, 0.01), "height_m": snappedf(box.size.y, 0.01), "walker": how, "marble_rests_at_m": snappedf(rest.y, 0.01),
		"palette": {"first": hex(palette.first), "second": hex(palette.second), "space": palette.space, "steps": palette.steps, "because": palette.because}}
	base.free()
	await frames(1)
