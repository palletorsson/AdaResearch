extends "res://supplied/sheet_tools.gd"
## The sheet of The look. It needs a window, so run it WITHOUT --headless:
##   godot --path . --xr-mode off --script res://sheet.gd
## It photographs the_look.tscn, the scene look.gd dresses, from the scene's own
## camera, and writes
##   process.png  one still after each state of the lesson, steps/0 to steps/8
##   sheet.png    the four pairs (a body's colour on the ground's colour), as
##                rendered and the same four stills made grey
##   sheet.json   every colour and share the lesson quotes
## A pair is made the way the lesson makes it: the two lines `const GROUND` and
## `const BODY` of look.gd are written again, and the scene runs that script.

const SCENE := "res://the_look.tscn"
const STEPS := [
	["0_engine_grey", "the engine's grey"], ["1_sky", "a sky"], ["2_ambient_only", "ambient only"],
	["3_sun_unturned", "a sun, unturned"], ["4_sun_turned", "the sun turned"], ["5_ground", "the ground"],
	["6_bodies", "the bodies"], ["7_energy", "energy 0.28"], ["8_palette", "the palette by role"],
]
## The axis: the pair. [name, the body's colour, the ground's colour]
const PAIRS := [
	["lime on violet", "c6ff3d", "32188a"],
	["hot pink on violet", "ff2e93", "32188a"],
	["red on green", "ff0000", "009400"],
	["grey on grey", "808080", "4d4d4d"],
]
## The same plain look, asked of supplied/look.gd: the look of every sheet's studio.
const SUPPLIED := """extends Node3D

const Look := preload("res://supplied/look.gd")

func _ready() -> void:
	var world := WorldEnvironment.new()
	world.environment = Look.studio_environment()
	add_child(world)
	add_child(Look.sun())
	$Floor.material_override = Look.paint(Look.GROUND)
	$Box.material_override = Look.paint(Look.BODY)
	$Sphere.material_override = Look.paint(Look.SECOND)
"""
## The look with its filter, as supplied/base_look.gd gives it to a scene that runs.
const FILTERED := """extends Node3D

const Look := preload("res://supplied/look.gd")

func _ready() -> void:
	var world := WorldEnvironment.new()
	world.environment = Look.environment()
	add_child(world)
	var sun := Look.sun()
	sun.shadow_blur = Look.SHADOW_BLUR
	add_child(sun)
	add_child(Look.fill())
	$Floor.material_override = Look.paint(Look.GROUND)
	$Box.material_override = Look.paint(Look.BODY)
	$Sphere.material_override = Look.paint(Look.SECOND)
"""

## Where the colours are read, in the room. A face is given by its four corners.
const FLOOR_SUN := [Vector3(-0.35, 0, 0.75), Vector3(-0.05, 0, 0.75), Vector3(-0.05, 0, 1.05), Vector3(-0.35, 0, 1.05)]
const FLOOR_SHADOW := [Vector3(0.74, 0, -0.47), Vector3(0.84, 0, -0.47), Vector3(0.84, 0, -0.37), Vector3(0.74, 0, -0.37)]
const BOX_TOP := [Vector3(-0.7, 0.6, -0.3), Vector3(-0.1, 0.6, -0.3), Vector3(-0.1, 0.6, 0.3), Vector3(-0.7, 0.6, 0.3)]
const BOX_FRONT := [Vector3(-0.7, 0, 0.3), Vector3(-0.1, 0, 0.3), Vector3(-0.1, 0.6, 0.3), Vector3(-0.7, 0.6, 0.3)]
const BOX_SIDE := [Vector3(-0.1, 0, 0.3), Vector3(-0.1, 0, -0.3), Vector3(-0.1, 0.6, -0.3), Vector3(-0.1, 0.6, 0.3)]
const SPHERE_LIT := Vector3(0.25, 0.505, 0.16)     # the point of the sphere that faces the sun
const SPHERE_SHADE := Vector3(0.64, 0.24, 0.17)    # a point of it the sun does not reach

var scene: Node3D
var camera: Camera3D
var to_linear := PackedFloat32Array()

func run() -> void:
	for i in 256:
		to_linear.append(Color(i / 255.0, 0, 0).srgb_to_linear().r)
	await process_strip()
	await side_runs()
	await pairs_sheet()
	await place()

# ---------------------------------------------------------------- the scene

func text_of(path: String) -> String:
	return FileAccess.get_file_as_string(path)

## The scene, run with `source` as its script in place of look.gd.
func dress(source: String) -> void:
	if scene != null and is_instance_valid(scene):
		scene.free()
	var script := GDScript.new()
	script.source_code = source
	var problem := script.reload()
	if problem != OK:
		print("sheet.gd: a script did not compile (", problem, "); the sheet is not whole")
		quit(1)
	scene = load(SCENE).instantiate()
	scene.set_script(script)
	root.add_child(scene)
	camera = scene.get_node("Camera3D")
	await process_frame
	await process_frame

## look.gd with two lines of its palette written again.
func with_pair(body: String, ground: String) -> String:
	var lines := text_of("res://look.gd").split("\n")
	for i in lines.size():
		if lines[i].begins_with("const GROUND :="):
			lines[i] = "const GROUND := Color(\"%s\")" % ground
		if lines[i].begins_with("const BODY :="):
			lines[i] = "const BODY := Color(\"%s\")" % body
	return "\n".join(lines)

## A script with one line taken out, or one line put under another.
func without_line(source: String, line: String) -> String:
	var kept := PackedStringArray()
	for each in source.split("\n"):
		if each.strip_edges() != line:
			kept.append(each)
	return "\n".join(kept)

func with_line_under(source: String, under: String, line: String) -> String:
	var out := PackedStringArray()
	for each in source.split("\n"):
		out.append(each)
		if each.strip_edges() == under:
			out.append("\t" + line)
	return "\n".join(out)

func sun_of(node: Node) -> DirectionalLight3D:
	var found := node.find_children("*", "DirectionalLight3D", true, false)
	return found[0] if not found.is_empty() else null

# ---------------------------------------------------------------- measures

func hex(c: Color) -> String:
	return "#" + c.to_html(false)

func luminance(c: Color) -> float:
	var linear := c.srgb_to_linear()
	return 0.2126 * linear.r + 0.7152 * linear.g + 0.0722 * linear.b

func contrast(a: Color, b: Color) -> float:
	var high := maxf(luminance(a), luminance(b))
	var low := minf(luminance(a), luminance(b))
	return snappedf((high + 0.05) / (low + 0.05), 0.01)

## How far two colours are apart: red, green and blue together, of 255 each.
func apart(a: Color, b: Color) -> float:
	return snappedf(Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length() * 255.0, 0.1)

## The mean colour of a still inside a four-cornered face given in the room,
## as the scene's camera sees it, the face shrunk to 0.7 of its size.
func mean(still: Image, corners: Array) -> Color:
	var quad := PackedVector2Array()
	var middle := Vector2.ZERO
	for corner: Vector3 in corners:
		var at := camera.unproject_position(corner) - Vector2(crop.position)
		quad.append(at)
		middle += at / corners.size()
	for i in quad.size():
		quad[i] = middle + (quad[i] - middle) * 0.7
	var low := quad[0]
	var high := quad[0]
	for at in quad:
		low = low.min(at)
		high = high.max(at)
	var sum := Vector3.ZERO
	var count := 0
	for y in range(int(low.y), int(high.y) + 1):
		for x in range(int(low.x), int(high.x) + 1):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), quad):
				var c := still.get_pixel(x, y)
				sum += Vector3(c.r, c.g, c.b)
				count += 1
	return Color(sum.x / count, sum.y / count, sum.z / count) if count > 0 else Color.BLACK

## The mean colour of seven by seven pixels around a point given in the room.
func patch(still: Image, at: Vector3) -> Color:
	var p := camera.unproject_position(at) - Vector2(crop.position)
	var sum := Vector3.ZERO
	var count := 0
	for dy in range(-3, 4):
		for dx in range(-3, 4):
			var c := still.get_pixel(int(p.x) + dx, int(p.y) + dy)
			sum += Vector3(c.r, c.g, c.b)
			count += 1
	return Color(sum.x / count, sum.y / count, sum.z / count)

## What the eye gets of the scene, place by place.
func read(still: Image) -> Dictionary:
	return {
		"sky": hex(still.get_pixel(20, 20)),
		"floor_in_the_sun": hex(mean(still, FLOOR_SUN)), "floor_in_the_sphere's_shadow": hex(mean(still, FLOOR_SHADOW)),
		"box_top": hex(mean(still, BOX_TOP)), "box_front": hex(mean(still, BOX_FRONT)), "box_side": hex(mean(still, BOX_SIDE)),
		"sphere_to_the_sun": hex(patch(still, SPHERE_LIT)), "sphere_away_from_it": hex(patch(still, SPHERE_SHADE)),
	}

## The still with its colour taken out: each pixel becomes the grey that has
## its luminance, 0.2126 R + 0.7152 G + 0.0722 B of the linear values.
func grey(still: Image) -> Image:
	var data := still.get_data()
	var out := PackedByteArray()
	out.resize(data.size())
	for i in data.size() / 3:
		var k := i * 3
		var y := 0.2126 * to_linear[data[k]] + 0.7152 * to_linear[data[k + 1]] + 0.0722 * to_linear[data[k + 2]]
		var encoded := 12.92 * y if y <= 0.0031308 else 1.055 * pow(y, 1.0 / 2.4) - 0.055
		var level := clampi(roundi(encoded * 255.0), 0, 255)
		out[k] = level
		out[k + 1] = level
		out[k + 2] = level
	return Image.create_from_data(still.get_width(), still.get_height(), false, Image.FORMAT_RGB8, out)

## Inside `pixels`: on how much of them two stills differ (percent of those
## pixels), and how far apart they are on average, the three channels added, of 765.
func inside(a: Image, b: Image, pixels: PackedByteArray) -> Dictionary:
	var p := a.get_data()
	var q := b.get_data()
	var differ := 0
	var total := 0
	var sum := 0
	for i in pixels.size():
		if pixels[i] == 0:
			continue
		var k := i * 3
		var d := absi(p[k] - q[k]) + absi(p[k + 1] - q[k + 1]) + absi(p[k + 2] - q[k + 2])
		total += 1
		sum += d
		if d > THRESHOLD:
			differ += 1
	return {"seen_pct": snappedf(100.0 * differ / maxi(total, 1), 0.01), "apart_of_765": snappedf(sum / float(maxi(total, 1)), 0.1)}

## The grey level, of 255, of a grey still at a point given in the room.
func level(still: Image, at: Vector3) -> int:
	return still.get_pixelv(Vector2i(camera.unproject_position(at) - Vector2(crop.position))).r8

## Outside `pixels`: on how much of the whole still two stills differ.
func outside_pct(a: Image, b: Image, pixels: PackedByteArray) -> float:
	var d := differs(a, b)
	var count := 0
	for i in d.size():
		if d[i] == 1 and pixels[i] == 0:
			count += 1
	return snappedf(100.0 * count / float(d.size()), 0.01)

# ---------------------------------------------------------------- the strip

func process_strip() -> void:
	var tiles: Array[Image] = []
	var names := []
	var stages := {}
	var stills := []
	for step: Array in STEPS:
		await dress(text_of("res://steps/%s.gd" % step[0]))
		var still := await shot("step_" + step[0])
		stills.append(still)
		tiles.append(small(still))
		names.append(step[1])
		stages[step[1]] = read(still)
		print("%-22s %s" % [step[1], stages[step[1]]])
	report["strip"] = await strip(tiles, names)
	report["strip"]["the palette by role is the still before it, pixel for pixel"] = (stills[8] as Image).get_data() == (stills[7] as Image).get_data()
	report["stages"] = stages

# ---------------------------------------------------------------- one line more, one line less

func side_runs() -> void:
	var record := {}
	# A sky with its background colour set and the line that asks for a plain colour left out.
	await dress(without_line(text_of("res://steps/1_sky.gd"), "sky.background_mode = Environment.BG_COLOR"))
	record["a sky, without the background_mode line"] = read(await shot("side_no_background_mode"))
	# Ambient light alone, with the energy line left out: the energy is then 1.
	await dress(without_line(text_of("res://steps/2_ambient_only.gd"), "sky.ambient_light_energy = 0.25"))
	record["ambient only, without the energy line"] = read(await shot("side_ambient_energy_1"))
	# The sun turned, with and without the line that gives it shadows.
	var turned := text_of("res://steps/4_sun_turned.gd")
	await dress(without_line(turned, "sun.shadow_enabled = true"))
	record["the sun turned, without the shadow line"] = read(await shot("side_no_shadow_line"))
	# The finished look with the hall's switch: the sun is there and is not shown.
	var finished := text_of("res://look.gd")
	await dress(with_line_under(finished, "add_child(sun)", "sun.visible = false"))
	var switched := await shot("side_switch")
	record["the finished look with sun.visible = false"] = read(switched)
	# The finished look, and the same look asked of supplied/look.gd.
	await dress(finished)
	var own := await shot("side_own")
	record["the finished look"] = read(own)
	var body: Color = Look.BODY
	var ground: Color = Look.GROUND
	var faces := {}
	for face: Array in [["top, to the sun", BOX_TOP], ["front", BOX_FRONT], ["side, away from the sun", BOX_SIDE]]:
		var seen := mean(own, face[1])
		var unlit := mean(switched, face[1])
		faces[face[0]] = {"rendered": hex(seen), "off_by": apart(seen, body), "with_the_sun_switched_off": hex(unlit), "then_off_by": apart(unlit, body)}
	record["BODY c6ff3d as rendered"] = faces
	var floor_seen := mean(own, FLOOR_SUN)
	var floor_dark := mean(own, FLOOR_SHADOW)
	record["GROUND 32188a as rendered"] = {"in_the_sun": hex(floor_seen), "off_by": apart(floor_seen, ground), "in_the_sphere's_shadow": hex(floor_dark), "shadow_off_by": apart(floor_dark, ground),
		"sun_against_shadow_contrast": contrast(floor_seen, floor_dark)}
	record["box_top_against_floor_contrast"] = contrast(mean(own, BOX_TOP), floor_seen)
	await dress(SUPPLIED)
	var supplied := await shot("side_supplied")
	record["the same look asked of supplied/look.gd differs on pct of the still"] = differ_pct(own, supplied)
	record["the same look asked of supplied/look.gd is our still, pixel for pixel"] = own.get_data() == supplied.get_data()
	# The filter a running scene of every later kit wears over this look.
	await dress(FILTERED)
	var filtered := await shot("side_filtered")
	var with_filter := read(filtered)
	with_filter["sky_at_the_top"] = hex(filtered.get_pixel(480, 4))
	with_filter["sky_at_the_horizon"] = hex(patch(filtered, Vector3(0.0, 0.25, -30.0)))
	with_filter["differs_from_the_plain_look_on_pct_of_the_still"] = differ_pct(own, filtered)
	var filtered_faces := {}
	for face: Array in [["top, to the sun", BOX_TOP], ["front", BOX_FRONT], ["side, away from the sun", BOX_SIDE]]:
		var seen := mean(filtered, face[1])
		filtered_faces[face[0]] = {"rendered": hex(seen), "off_by": apart(seen, body)}
	with_filter["BODY c6ff3d as rendered"] = filtered_faces
	record["the look with its filter"] = with_filter
	sun_of(scene).visible = false
	record["the look with its filter and the sun switched off"] = read(await shot("side_filtered_switch"))
	# Roughness: the sphere's brightest pixel, matt and polished.
	var polish := {}
	var polished := {}
	for value: String in ["1.0", "0.8", "0.2"]:
		await dress(finished.replace("second_paint.roughness = 0.8", "second_paint.roughness = " + value))
		var taken: Array = await portrait(scene.get_node("Sphere"), "side_roughness_" + value)
		var brightest := Color.BLACK
		var data: PackedByteArray = (taken[0] as Image).get_data()
		var whitish := 0
		for i in (taken[1] as PackedByteArray).size():
			if taken[1][i] == 1:
				var c := Color8(data[i * 3], data[i * 3 + 1], data[i * 3 + 2])
				if luminance(c) > luminance(brightest):
					brightest = c
				if data[i * 3] > 150:
					whitish += 1
		polish[value] = {"brightest_pixel": hex(brightest), "pixels_with_red_above_150": whitish, "sphere_pixels": (taken[1] as PackedByteArray).count(1)}
		polished[value] = taken[0]
	polish["0.8 and 1.0 differ on pct of the still"] = differ_pct(polished["0.8"], polished["1.0"])
	polish["0.8 and 0.2 differ on pct of the still"] = differ_pct(polished["0.8"], polished["0.2"])
	record["roughness of the sphere"] = polish
	print(JSON.stringify(record, "  "))
	report["one line more, one line less"] = record

# ---------------------------------------------------------------- the argument

func pairs_sheet() -> void:
	var tiles: Array[Image] = []
	var greys: Array[Image] = []
	var names := []
	var grey_names := []
	var stills := []
	var masks := []
	var record := {}
	var least := ""
	for pair: Array in PAIRS:
		var body := Color(pair[1])
		var ground := Color(pair[2])
		var row := {"body": "#" + pair[1], "ground": "#" + pair[2],
			"body_luminance": snappedf(luminance(body), 0.0001), "ground_luminance": snappedf(luminance(ground), 0.0001),
			"contrast_of_the_two_values": contrast(body, ground)}
		if body.s > 0.0 and ground.s > 0.0:
			var turn := absf(body.h - ground.h) * 360.0
			row["hues_apart_deg"] = snappedf(minf(turn, 360.0 - turn), 0.1)
		else:
			row["hues_apart_deg"] = null   # a grey has no hue
		for sun_on: bool in [true, false]:
			await dress(with_pair(pair[1], pair[2]))
			sun_of(scene).visible = sun_on
			var box: MeshInstance3D = scene.get_node("Box")
			var slug: String = pair[0].replace(" ", "_") + ("" if sun_on else "_no_sun")
			var taken: Array = await portrait(box, "pair_" + slug)
			var still: Image = taken[0]
			var pixels: PackedByteArray = taken[1]
			box.visible = false
			var bare := await shot("")      # the same ground with the box away
			box.visible = true
			var still_grey := grey(still)
			var bare_grey := grey(bare)
			var as_rendered := inside(still, bare, pixels)
			var in_grey := inside(still_grey, bare_grey, pixels)
			var measured := {
				"box_pct_of_the_still": share(pixels),
				"box_seen_pct": as_rendered["seen_pct"], "box_apart_of_765": as_rendered["apart_of_765"],
				"box_seen_in_grey_pct": in_grey["seen_pct"], "box_apart_in_grey_of_765": in_grey["apart_of_765"],
				"its_shadow_pct_of_the_still": outside_pct(still, bare, pixels), "its_shadow_in_grey_pct_of_the_still": outside_pct(still_grey, bare_grey, pixels),
				"rendered": {"box_top": hex(mean(still, BOX_TOP)), "box_front": hex(mean(still, BOX_FRONT)), "box_side": hex(mean(still, BOX_SIDE)), "floor_in_the_sun": hex(mean(still, FLOOR_SUN))},
				"grey_levels": {"box_top": level(still_grey, Vector3(-0.4, 0.6, 0.0)), "box_front": level(still_grey, Vector3(-0.4, 0.3, 0.3)),
					"box_side": level(still_grey, Vector3(-0.1, 0.3, 0.0)), "floor_in_the_sun": level(still_grey, Vector3(-0.2, 0.0, 0.9))},
			}
			if sun_on:
				row["in_the_look"] = measured
				tiles.append(small(still))
				greys.append(small(still_grey))
				names.append(pair[0])
				grey_names.append(pair[0] + ", made grey")
				stills.append(still)
				masks.append(pixels)
				still_grey.save_png("res://stills/pair_%s_grey.png" % slug)
				if least == "" or measured["box_apart_in_grey_of_765"] < record[least]["in_the_look"]["box_apart_in_grey_of_765"]:
					least = pair[0]
			else:
				row["with_the_sun_switched_off"] = measured
			print("%-20s sun %-5s box seen %6.2f%% (%5.1f of 765)   in grey %6.2f%% (%5.1f of 765)   shadow %5.2f%% / grey %5.2f%%" % [
				pair[0], sun_on, measured["box_seen_pct"], measured["box_apart_of_765"], measured["box_seen_in_grey_pct"], measured["box_apart_in_grey_of_765"],
				measured["its_shadow_pct_of_the_still"], measured["its_shadow_in_grey_pct_of_the_still"]])
		record[pair[0]] = row
	record["hardest_to_read_in_grey"] = least
	record["how"] = "each pair is look.gd with its two lines const GROUND and const BODY written again; the box's pixels are found by a second still with the box in one flat colour; `seen` is the share of those pixels where the still differs from a still of the same scene with the box away, by more than 25 of 255 over the three channels; `apart` is the mean of that difference; grey is each pixel's luminance, 0.2126 R + 0.7152 G + 0.0722 B of the linear values, written back as a grey"
	record["between_the_stills"] = compare_all(names, stills, masks)
	tiles.append_array(greys)
	names.append_array(grey_names)
	report["pairs"] = record
	report["sheet_png"] = await compose(tiles, PAIRS.size(), names, "res://sheet.png")

# ---------------------------------------------------------------- the place

func place() -> void:
	if scene != null and is_instance_valid(scene):
		scene.free()
	var room: Node3D = load("res://place.tscn").instantiate()
	root.add_child(room)
	var above := Camera3D.new()     # straight down on the floor behind the bodies
	above.fov = FOV
	room.add_child(above)
	above.look_at_from_position(Vector3(0.6, 5.0, -0.7), Vector3(0.6, 0.0, -0.7), Vector3(0.0, 0.0, -1.0))
	above.make_current()
	await process_frame
	var marble: RigidBody3D = room.get_node("Marble")
	var walker: CharacterBody3D = room.get_node("Walker")
	var record := {}
	# The marble from above, where the sun reaches the floor and where the box's shadow lies.
	var spots := {"in the sun": Vector3(1.3, 1.0, -1.0), "in the box's shadow": Vector3(0.05, 1.0, -0.45)}
	for spot: String in spots:
		marble.drop(spots[spot])
		for i in 150:
			await physics_frame
		var taken: Array = await portrait(marble, "place_marble_" + spot.replace(" ", "_").replace("'", ""))
		var data: PackedByteArray = (taken[0] as Image).get_data()
		var sum := Vector3.ZERO
		var count := 0
		for i in (taken[1] as PackedByteArray).size():
			if taken[1][i] == 1:
				sum += Vector3(data[i * 3], data[i * 3 + 1], data[i * 3 + 2])
				count += 1
		var seen := Color8(roundi(sum.x / maxi(count, 1)), roundi(sum.y / maxi(count, 1)), roundi(sum.z / maxi(count, 1)))
		record["the marble " + spot + ", from above"] = {"rests_at": [snappedf(marble.global_position.x, 0.01), snappedf(marble.global_position.y, 0.01), snappedf(marble.global_position.z, 0.01)],
			"mean_colour": hex(seen), "off_BONE_by": apart(seen, Look.BONE), "pixels": count}
	# Through the walker's eyes, from behind the bodies: the side the shadows point to.
	marble.drop(Vector3(-3.0, 0.3, 2.0))
	walker.stand_at(Vector3(1.2, 0.0, -2.0))
	walker.rotation.y = atan2(1.2, -2.0)          # facing the two bodies
	var eyes: Camera3D = walker.get_node("Eyes")
	eyes.rotation.x = -0.45                       # looking down at them, as the mouse would
	eyes.make_current()
	camera = eyes
	for i in 30:
		await physics_frame
	var behind := await shot("place_eyes_from_behind")
	var box_back := [Vector3(-0.7, 0, -0.3), Vector3(-0.1, 0, -0.3), Vector3(-0.1, 0.6, -0.3), Vector3(-0.7, 0.6, -0.3)]
	record["through the walker's eyes, from behind"] = {"stands_at": [snappedf(walker.global_position.x, 0.01), snappedf(walker.global_position.y, 0.01), snappedf(walker.global_position.z, 0.01)],
		"box_back": hex(mean(behind, box_back)), "box_side": hex(mean(behind, BOX_SIDE)), "box_top": hex(mean(behind, BOX_TOP)),
		"sphere_towards_the_walker": hex(patch(behind, Vector3(0.52, 0.36, -0.27)))}
	print(JSON.stringify(record, "  "))
	report["place"] = record
	room.free()
