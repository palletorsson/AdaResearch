extends "res://supplied/sheet_tools.gd"
## The sheet of The look. It needs a window, so run it WITHOUT --headless:
##   godot --path . --xr-mode off --script res://sheet.gd
## It photographs the_look.tscn, the scene look.gd dresses, from the scene's own
## camera, and writes
##   process.png  one still after each state of the lesson, steps/0 to steps/14:
##                stills of the scene as it RUNS, because the steps change the
##                scene's own sky and light
##   sheet.png    the four pairs (a body's colour on the ground's colour), as
##                rendered and the same four stills made grey, in the PLAIN look
##   sheet.json   every colour and share the lesson quotes
## A pair is made the way the lesson makes it: the two lines `const GROUND` and
## `const BODY` are written again, and the scene runs that script. The pairs of
## the sheet are measured in the plain look, the script as it stood at the
## palette step (steps/8_palette.gd), which is the sheet's studio of every kit:
## a still measures the body and not the filter. look.gd, the finished script,
## wears the filter; the same four pairs under it are in sheet.json too.

const SCENE := "res://the_look.tscn"
const STEPS := [
	["0_engine_grey", "the engine's grey"], ["1_sky", "a sky"], ["2_ambient_only", "ambient only"],
	["3_sun_unturned", "a sun, unturned"], ["4_sun_turned", "the sun turned"], ["5_ground", "the ground"],
	["6_bodies", "the bodies"], ["7_energy", "energy 0.28"], ["8_palette", "the palette by role"],
	["9_sky_ground_unsaid", "a sky's top, its ground unsaid"], ["10_gradient_sky", "the gradient sky"],
	["11_second_light", "a second light"], ["12_tinted_ambient", "a tinted ambient"],
	["13_shadow_blur", "shadow blur 2"], ["14_saturation_contrast", "saturation, contrast"],
]
const PLAIN := "res://steps/8_palette.gd"      # the look before its filter: the sheet's studio
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
const SHADOW_EDGE := [Vector3(0.79, 0.0, -0.42), Vector3(1.6, 0.0, -0.42)]   # a line on the floor, out of the sphere's shadow

var scene: Node3D
var camera: Camera3D
var to_linear := PackedFloat32Array()

func run() -> void:
	for i in 256:
		to_linear.append(Color(i / 255.0, 0, 0).srgb_to_linear().r)
	await process_strip()
	await side_runs()
	await filter_runs()
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

## A script of the lesson with two lines of its palette written again.
func with_pair(source: String, body: String, ground: String) -> String:
	var lines := source.split("\n")
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

## What the eye gets of the scene, place by place. `sky` is the upper left
## corner of the picture: the flat sky of the plain look, and under a gradient
## sky the ground beyond the floor, because the scene's camera looks down.
func read(still: Image) -> Dictionary:
	return {
		"sky": hex(still.get_pixel(20, 20)),
		"top_edge_of_the_picture": hex(still.get_pixel(480, 2)), "just_above_the_floor's_far_edge": hex(still.get_pixel(480, 205)),
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

## How many bytes of two stills are not alike, and the largest step of one channel, of 255.
func bytes_unlike(a: Image, b: Image) -> Array:
	var p := a.get_data()
	var q := b.get_data()
	var count := 0
	var worst := 0
	for i in p.size():
		if p[i] != q[i]:
			count += 1
			worst = maxi(worst, absi(p[i] - q[i]))
	return [count, worst]

## The mean colour of seven by seven pixels in the middle of a still.
func middle_of(still: Image) -> Color:
	var sum := Vector3.ZERO
	for dy in range(-3, 4):
		for dx in range(-3, 4):
			var c := still.get_pixel(still.get_width() / 2 + dx, still.get_height() / 2 + dy)
			sum += Vector3(c.r, c.g, c.b)
	return Color(sum.x / 49.0, sum.y / 49.0, sum.z / 49.0)

## How wide the edge of the sphere's shadow is: along a line on the floor from
## inside the shadow out into the sun, the pixels whose luminance lies between
## the darkest and the lightest on the line, a tenth of the way in from each.
func edge(still: Image) -> Dictionary:
	var a := camera.unproject_position(SHADOW_EDGE[0]) - Vector2(crop.position)
	var b := camera.unproject_position(SHADOW_EDGE[1]) - Vector2(crop.position)
	var levels := []
	var n := int(a.distance_to(b))
	for i in n:
		levels.append(luminance(still.get_pixelv(Vector2i(a.lerp(b, i / float(n))))))
	var low: float = levels.min()
	var high: float = levels.max()
	var band := 0
	for l: float in levels:
		if l > low + 0.1 * (high - low) and l < high - 0.1 * (high - low):
			band += 1
	return {"pixels_on_the_line": n, "edge_band_px": band}

## The background by degrees above the horizon: a camera of our own, 1.6 m up,
## turned up or down by each angle; the colour in the middle of its picture.
func sky_seen(degrees_up: Array) -> Dictionary:
	var own := Camera3D.new()
	own.fov = 48.0
	own.position = Vector3(0.0, 1.6, 2.4)
	scene.add_child(own)
	own.make_current()
	var out := {}
	for up: float in degrees_up:
		own.rotation = Vector3(deg_to_rad(up), 0.0, 0.0)
		out["%d" % int(up)] = hex(middle_of(await shot("")))
	camera.make_current()
	own.free()
	return out

## The colour of the sky where a light comes from: a camera of our own turned to face it.
func towards(light: DirectionalLight3D, name: String) -> Color:
	var own := Camera3D.new()
	own.fov = 48.0
	own.position = Vector3(0.0, 1.6, 2.4)
	scene.add_child(own)
	own.look_at(own.position + light.global_basis.z * 10.0)
	own.make_current()
	var seen := middle_of(await shot(name))
	camera.make_current()
	own.free()
	return seen

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
		print("%-34s %s" % [step[1], stages[step[1]]])
	# strip() measures each step against the one before and writes one row; the
	# shipped picture is the same fifteen tiles in three rows of five, which a page can show.
	report["strip"] = await strip(tiles, names, "res://stills/process_one_row.png")
	report["strip"]["png"] = await compose(tiles, 5, names, "res://process.png")
	report["strip"]["the palette by role is the still before it, pixel for pixel"] = (stills[8] as Image).get_data() == (stills[7] as Image).get_data()
	report["strip"]["shadow blur 2 is the still before it, pixel for pixel"] = (stills[13] as Image).get_data() == (stills[12] as Image).get_data()
	report["strip"]["a second light: bytes unlike the still before it, and the largest step of one channel"] = bytes_unlike(stills[10], stills[11])
	report["strip"]["a second light differs from the still before it on pct of the still"] = differ_pct(stills[10], stills[11])
	report["strip"]["the finished look differs from the plain look on pct of the still"] = differ_pct(stills[8], stills[14])
	report["stages"] = stages

# ---------------------------------------------------------------- one line more, one line less

## The three faces of the box in a still: what the eye gets of BODY, and how far that is from it.
func faces_of(still: Image) -> Dictionary:
	var faces := {}
	for face: Array in [["top, to the sun", BOX_TOP], ["front", BOX_FRONT], ["side, away from the sun", BOX_SIDE]]:
		var seen := mean(still, face[1])
		faces[face[0]] = {"rendered": hex(seen), "off_by": apart(seen, Look.BODY)}
	return faces

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
	# The plain look, the script as it stood at the palette step, with the hall's
	# switch: the sun is there and is not shown.
	var plain := text_of(PLAIN)
	await dress(with_line_under(plain, "add_child(sun)", "sun.visible = false"))
	var switched := await shot("side_switch")
	record["the plain look with sun.visible = false"] = read(switched)
	# The plain look, and the same look asked of supplied/look.gd.
	await dress(plain)
	var own := await shot("side_own")
	record["the plain look"] = read(own)
	var body: Color = Look.BODY
	var ground: Color = Look.GROUND
	var faces := {}
	for face: Array in [["top, to the sun", BOX_TOP], ["front", BOX_FRONT], ["side, away from the sun", BOX_SIDE]]:
		var seen := mean(own, face[1])
		var unlit := mean(switched, face[1])
		faces[face[0]] = {"rendered": hex(seen), "off_by": apart(seen, body), "with_the_sun_switched_off": hex(unlit), "then_off_by": apart(unlit, body)}
	record["BODY c6ff3d as rendered in the plain look"] = faces
	var floor_seen := mean(own, FLOOR_SUN)
	var floor_dark := mean(own, FLOOR_SHADOW)
	record["GROUND 32188a as rendered in the plain look"] = {"in_the_sun": hex(floor_seen), "off_by": apart(floor_seen, ground), "in_the_sphere's_shadow": hex(floor_dark), "shadow_off_by": apart(floor_dark, ground),
		"sun_against_shadow_contrast": contrast(floor_seen, floor_dark)}
	record["box_top_against_floor_contrast"] = contrast(mean(own, BOX_TOP), floor_seen)
	await dress(SUPPLIED)
	var supplied := await shot("side_supplied")
	record["the plain look asked of supplied/look.gd differs on pct of the still"] = differ_pct(own, supplied)
	record["the plain look asked of supplied/look.gd is our still, pixel for pixel"] = own.get_data() == supplied.get_data()
	# Roughness, in the plain look: the sphere's brightest pixel, matt and polished.
	var polish := {}
	var polished := {}
	for value: String in ["1.0", "0.8", "0.2"]:
		await dress(plain.replace("second_paint.roughness = 0.8", "second_paint.roughness = " + value))
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
	record["roughness of the sphere, in the plain look"] = polish
	print(JSON.stringify(record, "  "))
	report["one line more, one line less"] = record

# ---------------------------------------------------------------- the filter, line by line

func filter_runs() -> void:
	var record := {}
	var body: Color = Look.BODY
	var finished := text_of("res://look.gd")
	await dress(finished)
	var own := await shot("filter_own")
	var worn := read(own)
	worn["BODY c6ff3d as rendered"] = faces_of(own)
	var floor_seen := mean(own, FLOOR_SUN)
	worn["GROUND 32188a in the sun, off by"] = apart(floor_seen, Look.GROUND)
	worn["shadow_edge"] = edge(own)
	record["the finished look"] = worn
	# The same look asked of supplied/look.gd, as base_look.gd gives it to a later kit's scene.
	await dress(FILTERED)
	var supplied := await shot("filter_supplied")
	record["the finished look asked of supplied/look.gd is our still, pixel for pixel"] = own.get_data() == supplied.get_data()
	record["the finished look asked of supplied/look.gd: bytes unlike, and the largest step of one channel"] = bytes_unlike(own, supplied)
	# The sky. A gradient sky is a ball round the scene; the scene's camera looks
	# down and shows only what is under the horizon. A level camera of our own reads it.
	var ups := [-10.0, -5.0, -1.0, 0.0, 5.0, 10.0, 20.0, 30.0, 45.0, 60.0, 89.0]
	var skies := {}
	await dress(text_of("res://steps/9_sky_ground_unsaid.gd"))
	skies["its ground unsaid, the curve as it comes (0.15)"] = await sky_seen(ups)
	var disc := {}
	for light: DirectionalLight3D in scene.find_children("*", "DirectionalLight3D", true, false):
		disc["the sun's disc, its middle"] = hex(await towards(light, "filter_disc_sun"))
	await dress(text_of("res://steps/10_gradient_sky.gd"))
	skies["the gradient sky"] = await sky_seen(ups)
	disc["the same place in the sky with sun_angle_max = 0"] = hex(await towards(sun_of(scene), "filter_no_disc"))
	await dress(finished)
	skies["the finished look"] = await sky_seen(ups)
	await dress(without_line(without_line(finished, "gradient.sun_angle_max = 0.0"), "gradient.sun_curve = 0.0"))
	for light: DirectionalLight3D in scene.find_children("*", "DirectionalLight3D", true, false):
		disc["finished look without the two sun lines: the disc of the %s" % ("sun" if light.shadow_enabled else "second light")] = hex(await towards(light, "filter_disc_%s" % ("sun" if light.shadow_enabled else "fill")))
	record["the sky by degrees above the horizon, from a level camera"] = skies
	record["the disc this sky draws for a light"] = disc
	# Lines that change no pixel.
	var silent := {}
	for line: String in ["sky.background_color = SKY", "gradient.sun_curve = 0.0"]:
		await dress(without_line(finished, line))
		silent["without `%s`: the same still, pixel for pixel" % line] = (await shot("")).get_data() == own.get_data()
	await dress(with_line_under(finished, "gradient.ground_bottom_color = GROUND", "gradient.ground_curve = 0.02"))
	silent["with `gradient.ground_curve = 0.02` added: the same still, pixel for pixel"] = (await shot("")).get_data() == own.get_data()
	var blurs := {}
	for value: String in ["0.0", "1.0", "6.0", "20.0"]:
		await dress(finished.replace("sun.shadow_blur = 2.0", "sun.shadow_blur = " + value))
		var still := await shot("filter_blur_" + value)
		blurs[value] = {"read_back": sun_of(scene).shadow_blur, "bytes_unlike_the_still_at_2": bytes_unlike(own, still)[0], "shadow_edge_px": edge(still)["edge_band_px"]}
	silent["shadow_blur"] = blurs
	record["lines that change no pixel"] = silent
	# The sky mirrored in the bodies: the gradient sky with the mirroring switched off.
	var sky_only := text_of("res://steps/10_gradient_sky.gd")
	await dress(sky_only)
	var with_sky := await shot("")
	await dress(with_line_under(sky_only, "sky.background_mode = Environment.BG_SKY", "sky.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED"))
	var unmirrored := await shot("filter_unmirrored")
	await dress(text_of(PLAIN))
	var plain_still := await shot("")
	record["the gradient sky mirrored in the bodies"] = {
		"box_top_in_the_plain_look": hex(mean(plain_still, BOX_TOP)), "box_top_under_the_gradient_sky": hex(mean(with_sky, BOX_TOP)),
		"box_top_with_reflected_light_disabled": hex(mean(unmirrored, BOX_TOP)),
		"box_side_in_the_plain_look": hex(mean(plain_still, BOX_SIDE)), "box_side_under_the_gradient_sky": hex(mean(with_sky, BOX_SIDE)),
		"box_side_with_reflected_light_disabled": hex(mean(unmirrored, BOX_SIDE)),
	}
	# The second light: stronger, alone, and with the hall's switch before and after it.
	var second := text_of("res://steps/11_second_light.gd")
	var lights := {}
	await dress(second.replace("fill.light_energy = 0.05", "fill.light_energy = 0.5"))
	lights["at energy 0.5"] = read(await shot("filter_fill_strong"))
	await dress(with_line_under(sky_only, "add_child(sun)", "sun.visible = false"))
	var before := await shot("filter_switch_before_fill")
	lights["the sun switched off, before the second light"] = read(before)
	await dress(with_line_under(second, "add_child(sun)", "sun.visible = false"))
	var after := await shot("filter_switch_with_fill")
	lights["the sun switched off, with the second light"] = read(after)
	lights["the two differ on pct of the still"] = differ_pct(before, after)
	await dress(with_line_under(finished, "add_child(sun)", "sun.visible = false"))
	var last := await shot("filter_switch_finished")
	lights["the sun switched off, in the finished look"] = read(last)
	lights["the sun switched off, in the finished look"]["BODY c6ff3d as rendered"] = faces_of(last)
	record["the second light"] = lights
	# Saturation, pushed.
	await dress(finished.replace("adjustment_saturation = 1.08", "adjustment_saturation = 2.0"))
	record["saturation 2.0"] = read(await shot("filter_saturation_2"))
	# What was tried and left out: one line each, added to the finished look.
	var tried := {}
	var lines := {
		"fog, as it comes": ["sky.fog_enabled = true"],
		"glow, as it comes": ["sky.glow_enabled = true"],
		"glow with bloom 0.5": ["sky.glow_bloom = 0.5", "sky.glow_enabled = true"],
		"tonemap Reinhard": ["sky.tonemap_mode = Environment.TONE_MAPPER_REINHARDT"],
		"tonemap filmic": ["sky.tonemap_mode = Environment.TONE_MAPPER_FILMIC"],
		"tonemap ACES": ["sky.tonemap_mode = Environment.TONE_MAPPER_ACES"],
		"tonemap AgX": ["sky.tonemap_mode = Environment.TONE_MAPPER_AGX"],
	}
	for name: String in lines:
		var source := finished
		for line: String in lines[name]:
			source = with_line_under(source, "sky.adjustment_contrast = 1.04", line)
		await dress(source)
		var still := await shot("filter_tried_" + name.replace(",", "").replace(" ", "_"))
		var row := read(still)
		var top := mean(still, BOX_TOP)
		row["box_top_off_BODY_by"] = apart(top, body)
		row["differs_from_the_finished_look_on_pct_of_the_still"] = differ_pct(own, still)
		var unlike := bytes_unlike(own, still)
		row["bytes_unlike_the_finished_look"] = unlike[0]
		row["largest_step_of_one_channel"] = unlike[1]
		tried[name] = row
		print("%-22s %s" % [name, row])
	var fresh := Environment.new()
	tried["what a new Environment has"] = {"fog_light_color": hex(fresh.fog_light_color), "tonemap_mode_is_linear": fresh.tonemap_mode == Environment.TONE_MAPPER_LINEAR, "tonemap_white": fresh.tonemap_white, "glow_hdr_threshold": fresh.glow_hdr_threshold}
	var new_sky := ProceduralSkyMaterial.new()
	tried["what a new ProceduralSkyMaterial has"] = {"sky_top_color": hex(new_sky.sky_top_color), "sky_horizon_color": hex(new_sky.sky_horizon_color), "ground_bottom_color": hex(new_sky.ground_bottom_color),
		"ground_horizon_color": hex(new_sky.ground_horizon_color), "sky_curve": snappedf(new_sky.sky_curve, 0.01), "ground_curve": snappedf(new_sky.ground_curve, 0.01), "sun_angle_max": new_sky.sun_angle_max}
	record["tried and left out"] = tried
	print(JSON.stringify(record, "  "))
	report["the filter, line by line"] = record

# ---------------------------------------------------------------- the argument

## One pair in one look, with the sun shown or not: the box against the bare ground.
func measure_pair(source: String, pair: Array, sun_on: bool, save_as: String) -> Dictionary:
	await dress(with_pair(source, pair[1], pair[2]))
	sun_of(scene).visible = sun_on
	var box: MeshInstance3D = scene.get_node("Box")
	var taken: Array = await portrait(box, save_as)
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
	return {"measured": measured, "still": still, "pixels": pixels, "grey": still_grey}

func pairs_sheet() -> void:
	var tiles: Array[Image] = []
	var greys: Array[Image] = []
	var names := []
	var grey_names := []
	var stills := []
	var masks := []
	var record := {}
	var least := ""
	var plain := text_of(PLAIN)
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
			var slug: String = pair[0].replace(" ", "_") + ("" if sun_on else "_no_sun")
			var got: Dictionary = await measure_pair(plain, pair, sun_on, "pair_" + slug)
			var measured: Dictionary = got["measured"]
			if sun_on:
				row["in_the_look"] = measured
				tiles.append(small(got["still"]))
				greys.append(small(got["grey"]))
				names.append(pair[0])
				grey_names.append(pair[0] + ", made grey")
				stills.append(got["still"])
				masks.append(got["pixels"])
				(got["grey"] as Image).save_png("res://stills/pair_%s_grey.png" % slug)
				if least == "" or measured["box_apart_in_grey_of_765"] < record[least]["in_the_look"]["box_apart_in_grey_of_765"]:
					least = pair[0]
			else:
				row["with_the_sun_switched_off"] = measured
			print("%-20s sun %-5s box seen %6.2f%% (%5.1f of 765)   in grey %6.2f%% (%5.1f of 765)   shadow %5.2f%% / grey %5.2f%%" % [
				pair[0], sun_on, measured["box_seen_pct"], measured["box_apart_of_765"], measured["box_seen_in_grey_pct"], measured["box_apart_in_grey_of_765"],
				measured["its_shadow_pct_of_the_still"], measured["its_shadow_in_grey_pct_of_the_still"]])
		record[pair[0]] = row
	record["hardest_to_read_in_grey"] = least
	record["how"] = "each pair is the plain look (steps/8_palette.gd, the script as it stood before the filter) with its two lines const GROUND and const BODY written again; the box's pixels are found by a second still with the box in one flat colour; `seen` is the share of those pixels where the still differs from a still of the same scene with the box away, by more than 25 of 255 over the three channels; `apart` is the mean of that difference; grey is each pixel's luminance, 0.2126 R + 0.7152 G + 0.0722 B of the linear values, written back as a grey"
	record["between_the_stills"] = compare_all(names, stills, masks)
	tiles.append_array(greys)
	names.append_array(grey_names)
	report["pairs"] = record
	report["sheet_png"] = await compose(tiles, PAIRS.size(), names, "res://sheet.png")
	# The same four pairs under the filter, in look.gd as it is shipped: what a
	# learner sees when the pair runs. Not on the sheet; the numbers only.
	var worn := {}
	var finished := text_of("res://look.gd")
	for pair: Array in PAIRS:
		var row := {}
		for sun_on: bool in [true, false]:
			var slug: String = "filtered_" + pair[0].replace(" ", "_") + ("" if sun_on else "_no_sun")
			var got: Dictionary = await measure_pair(finished, pair, sun_on, "pair_" + slug)
			row["in_the_look" if sun_on else "with_the_sun_switched_off"] = got["measured"]
			if sun_on:
				(got["grey"] as Image).save_png("res://stills/pair_%s_grey.png" % slug)
			print("filtered %-20s sun %-5s box seen %6.2f%% (%5.1f of 765)   in grey %6.2f%% (%5.1f of 765)" % [
				pair[0], sun_on, got["measured"]["box_seen_pct"], got["measured"]["box_apart_of_765"], got["measured"]["box_seen_in_grey_pct"], got["measured"]["box_apart_in_grey_of_765"]])
		worn[pair[0]] = row
	worn["how"] = "the same measure on look.gd as shipped, with its filter: the gradient sky, the second light, the tinted ambient light, saturation 1.08 and contrast 1.04"
	report["pairs under the filter"] = worn

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
	# The sky, through the same eyes: level, and then looking up, as the mouse would.
	var sky := {}
	for up: float in [0.0, 20.0, 45.0, 80.0]:
		eyes.rotation.x = deg_to_rad(up)
		var still := await shot("place_eyes_up_%d" % int(up))
		sky["%d degrees up" % int(up)] = hex(middle_of(still))
	record["the sky through the walker's eyes, the middle of the picture"] = sky
	print(JSON.stringify(record, "  "))
	report["place"] = record
	room.free()
