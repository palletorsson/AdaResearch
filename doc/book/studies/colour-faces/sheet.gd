extends "res://supplied/sheet_tools.gd"
## The stills and the measurements of "A colour has many faces". It needs a
## window, so run it WITHOUT --headless, from this folder:
##   godot --path . --xr-mode off --script res://sheet.gd
## It writes
##   sheet.png    the argument: one wall alone for each of the four mixing
##                spaces, its steps drawn 1.8 m high; the upper row between
##                BODY and its complement, the lower row between red and cyan
##   lamp.png     the four walls and the lamp of faces.gd in the studio, seen from
##                where the walker's eyes would be: the lamp off, white, in the
##                first colour and in the second
##   process.png  the strip: one still after each operation of the lesson
##   sheet.json   every pair of walls measured three ways, the colour each
##                step was rendered in, how two lights add on a grey wall,
##                the middle steps under each light of the lamp, and how
##                much each step of the strip changed the picture
## and the single stills, in stills/. It closes its window by itself.

const Wall := preload("res://wall.gd")
const Oklab := preload("res://oklab.gd")
const SPACES := ["rgb", "hsv", "linear", "oklab"]
const Faces := preload("res://faces.gd")
const EYES := Vector3(0, 1.6, 1.6)    # where the walker's eyes are when it stands at the middle of the wall
const START := Vector3(-2, 0, 1.6)    # where the walker stands when faces.tscn starts

func run() -> void:
	await argument("lime_violet", Look.BODY, Look.BODY.inverted())
	await argument("red_cyan", Color.RED, Color.CYAN)
	report["sheet_png"] = await compose(sheet_tiles, 4, SPACES, "res://sheet.png")
	await two_lights()
	var strip_tiles: Array[Image] = []
	var strip_names := []
	await making(strip_tiles, strip_names)
	await place(strip_tiles, strip_names)
	report["strip"] = await strip(strip_tiles, strip_names)

var sheet_tiles: Array[Image] = []

func hex(c: Color) -> String:
	return "#" + c.to_html(false)

func hexes(colours: Array) -> Array:
	var out := []
	for c: Color in colours:
		out.append(hex(c))
	return out

## The mean colour of a still inside a four-cornered face given in the room,
## as `camera` sees it, the face shrunk to `keep` of its size about its middle.
func mean(still: Image, camera: Camera3D, corners: Array, keep := 0.7) -> Color:
	var quad := PackedVector2Array()
	var middle := Vector2.ZERO
	for corner: Vector3 in corners:
		var at := camera.unproject_position(corner) - Vector2(crop.position)
		quad.append(at)
		middle += at / corners.size()
	for i in quad.size():
		quad[i] = middle + (quad[i] - middle) * keep
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

## The four corners of the face of step `i` of a wall that looks at us.
func face(wall: Node3D, i: int) -> Array:
	var box: MeshInstance3D = wall.boxes[i]
	var c := box.global_position + Vector3(0, 0, 0.1)
	var w: float = wall.size.x / 2.0
	var h: float = wall.size.y / 2.0
	return [c + Vector3(-w, -h, 0), c + Vector3(w, -h, 0), c + Vector3(w, h, 0), c + Vector3(-w, h, 0)]

## How far apart two colours are: red, green and blue together, each of 255.
func off(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length() * 255.0

## Two walls, step against step, as they were rendered.
func steps_apart(a: Array, b: Array) -> Dictionary:
	var rgb := 0.0
	var ok := 0.0
	var over := 0
	var each := []
	for i in a.size():
		var p: Color = a[i]
		var q: Color = b[i]
		rgb += off(p, q) / a.size()
		ok += Oklab.apart(p, q) / a.size()
		each.append(snappedf(off(p, q), 0.1))
		if (absf(p.r - q.r) + absf(p.g - q.g) + absf(p.b - q.b)) * 255.0 > THRESHOLD:
			over += 1
	return {"rgb_of_255": snappedf(rgb, 0.1), "oklab_times_100": snappedf(ok, 0.1), "steps_over_the_threshold": over, "each_step_rgb_of_255": each}

## The argument for one pair of colours: four walls, each alone, every pair measured.
func argument(title: String, first: Color, second: Color) -> void:
	var stills := []
	var pixels := []
	var rendered := {}
	var as_painted := {}
	var record := {"first": hex(first), "second": hex(second), "walls": {}}
	for space: String in SPACES:
		var wall := Wall.new()
		wall.space = space
		wall.first = first
		wall.second = second
		wall.size = Vector2(0.4, 1.8)
		await stand(wall)
		look("level", 4.4, Vector3(0, 0.9, 0))
		var taken: Array = await portrait(wall, "%s_%s" % [title, space])
		stills.append(taken[0])
		pixels.append(taken[1])
		sheet_tiles.append(small(taken[0]))
		var painted := []
		var seen := []
		var least := 1.0
		for i in wall.steps:
			painted.append(wall.mix(i / float(wall.steps - 1)))
			seen.append(mean(taken[0], eye, face(wall, i)))
			least = minf(least, (seen[i] as Color).s)
		rendered[space] = seen
		as_painted[space] = painted
		record["walls"][space] = {"painted": hexes(painted), "rendered": hexes(seen), "covers_pct": share(taken[1]),
			"middle_painted": hex(painted[4]), "middle_rendered": hex(seen[4]), "middle_rendered_saturation": snappedf((seen[4] as Color).s, 0.001),
			"least_rendered_saturation": snappedf(least, 0.001), "middle_off_by": snappedf(off(painted[4], seen[4]), 0.1)}
		print("%s %-7s painted middle %s, rendered %s, saturation %.3f; least saturated step %.3f" % [title, space, hex(painted[4]), hex(seen[4]), (seen[4] as Color).s, least])
	record["standard"] = compare_all(SPACES, stills, pixels)
	# The kit's usual measure counts WHERE two stills differ. Walls of flat steps can tie on it.
	var shares := {}
	for key: String in record["standard"]["pairs"]:
		shares[record["standard"]["pairs"][key]["differ_pct"]] = true
	record["standard_is_a_tie"] = shares.size() == 1
	var pairs := {}
	var painted_pairs := {}
	var closest := ""
	var farthest := ""
	var closest_ok := ""
	for i in SPACES.size():
		for j in range(i + 1, SPACES.size()):
			var key := "%s vs %s" % [SPACES[i], SPACES[j]]
			pairs[key] = steps_apart(rendered[SPACES[i]], rendered[SPACES[j]])
			painted_pairs[key] = steps_apart(as_painted[SPACES[i]], as_painted[SPACES[j]])
			if closest == "" or pairs[key]["rgb_of_255"] < pairs[closest]["rgb_of_255"]:
				closest = key
			if farthest == "" or pairs[key]["rgb_of_255"] > pairs[farthest]["rgb_of_255"]:
				farthest = key
			if closest_ok == "" or pairs[key]["oklab_times_100"] < pairs[closest_ok]["oklab_times_100"]:
				closest_ok = key
			print("%s %-18s steps apart: %5.1f of 255 in RGB, %5.1f in OKLab x 100, %d of 9 over the threshold; the stills differ on %5.2f%%" % [
				title, key, pairs[key]["rgb_of_255"], pairs[key]["oklab_times_100"], pairs[key]["steps_over_the_threshold"], record["standard"]["pairs"][key]["differ_pct"]])
	record["steps_apart"] = pairs
	record["steps_apart_as_painted"] = painted_pairs     # the same measure on the colours mix() returned, before any light
	record["closest_by_rgb"] = closest
	record["farthest_by_rgb"] = farthest
	record["closest_by_oklab"] = closest_ok
	record["how"] = "each wall alone, its nine steps 0.4 m wide and 1.8 m high, the eye level, 4.4 m away; a step's colour is the mean of the still inside its face, shrunk to 0.7; two walls are compared step against step: the mean distance in red, green and blue together (each of 255), the mean distance in OKLab times 100, and how many of the nine steps differ by more than the threshold"
	print("%s: closest by RGB distance %s, by OKLab distance %s; farthest %s" % [title, closest, closest_ok, farthest])
	report[title] = record

## How does this renderer add two lights on one surface: as amounts of light,
## or as the numbers the screen gets? A wall painted 808080 all over, four
## stills: the ambient light alone, with the sun, with the lamp, with both.
func two_lights() -> void:
	var wall := Wall.new()
	wall.first = Color("808080")
	wall.second = Color("808080")
	wall.size = Vector2(0.4, 1.8)
	await stand(wall)
	look("level", 4.4, Vector3(0, 0.9, 0))
	var sun: DirectionalLight3D = studio.get_node("Look/Sun")
	var record := {}
	for energy: float in [1.0, 3.0]:
		var lamp := SpotLight3D.new()
		lamp.spot_angle = 25.0
		lamp.light_energy = energy
		lamp.position = Vector3(0, 0.9, 1.6)     # 2.5 m from the wall's face, as the walker's lamp is
		studio.add_child(lamp)
		var seen := {}
		for state: Array in [["ambient", false, false], ["sun", true, false], ["lamp", false, true], ["both", true, true]]:
			sun.visible = state[1]
			lamp.visible = state[2]
			var still := await shot("two_lights_%s_energy_%d" % [state[0], energy])
			var sum := 0.0
			for y in range(crop.size.y / 2 - 20, crop.size.y / 2 + 20):
				for x in range(crop.size.x / 2 - 20, crop.size.x / 2 + 20):
					sum += still.get_pixel(x, y).r
			seen[state[0]] = sum / 1600.0
		lamp.free()
		var as_numbers: float = seen["sun"] + seen["lamp"] - seen["ambient"]
		var light: float = to_light(seen["sun"]) + to_light(seen["lamp"]) - to_light(seen["ambient"])
		var as_light := Color(light, light, light).linear_to_srgb().r
		record["lamp_energy_%d" % energy] = {"ambient_only": snappedf(seen["ambient"] * 255.0, 0.1), "with_the_sun": snappedf(seen["sun"] * 255.0, 0.1),
			"with_the_lamp": snappedf(seen["lamp"] * 255.0, 0.1), "with_both": snappedf(seen["both"] * 255.0, 0.1),
			"if_added_as_numbers": snappedf(as_numbers * 255.0, 0.1), "if_added_as_light": snappedf(as_light * 255.0, 0.1)}
		print("two lights, lamp energy %.0f: the grey wall is %.1f of 255 in the ambient light alone, %.1f with the sun, %.1f with the lamp, %.1f with both; added as numbers %.1f, added as light %.1f" % [
			energy, seen["ambient"] * 255.0, seen["sun"] * 255.0, seen["lamp"] * 255.0, seen["both"] * 255.0, as_numbers * 255.0, as_light * 255.0])
	sun.visible = true
	record["how"] = "a wall painted 808080, the mean red channel of the 40 x 40 pixels at the middle of the still, where the lamp points; the ambient light is in all four stills, so it is taken off once"
	report["two_lights"] = record

## A screen number, 0 to 1, as an amount of light.
func to_light(v: float) -> float:
	return Color(v, v, v).srgb_to_linear().r

## A row of steps, for the strip: the colours as given, row 0 on the floor.
func row(group: Node3D, colours: Array, height: int) -> void:
	for i in colours.size():
		var step := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.4, 0.45, 0.2)
		step.mesh = mesh
		step.material_override = Look.paint(colours[i])
		step.position = Vector3((i - 4) * 0.4, 0.225 + height * 0.45, -1)
		group.add_child(step)

func nine(wall: Node3D) -> Array:
	var out := []
	for i in 9:
		out.append(wall.mix(i / 8.0))
	return out

## The strip's first six tiles: the making, one still after each operation,
## from where the walker's eyes are when it stands at the middle of the wall.
func making(tiles: Array[Image], names: Array) -> void:
	var first := Look.BODY
	var second := first.inverted()
	var rgb := Wall.new()
	var hsv := Wall.new()
	hsv.space = "hsv"
	var states := []
	# 1 one step: the middle
	var group := Node3D.new()
	row(group, [first.lerp(second, 0.5)], 0)
	group.get_child(0).position.x = 0.0     # one step, in the middle of where the wall will be
	states.append(["1 one step, half way", group])
	# 2 a row in RGB
	group = Node3D.new()
	row(group, nine(rgb), 0)
	states.append(["2 a row: RGB", group])
	# 3 a second row in HSV, the hue lerped plainly
	group = Node3D.new()
	row(group, nine(rgb), 0)
	var plain := []
	for i in 9:
		var t := i / 8.0
		plain.append(Color.from_hsv(lerpf(first.h, second.h, t), lerpf(first.s, second.s, t), lerpf(first.v, second.v, t)))
	row(group, plain, 1)
	states.append(["3 a second row: HSV", group])
	# 4 pink to orange: the long way round
	group = Node3D.new()
	rgb.first = Look.SKY
	rgb.second = Look.THIRD
	hsv.first = Look.SKY
	hsv.second = Look.THIRD
	row(group, nine(rgb), 0)
	plain = []
	for i in 9:
		var t := i / 8.0
		plain.append(Color.from_hsv(lerpf(Look.SKY.h, Look.THIRD.h, t), lerpf(Look.SKY.s, Look.THIRD.s, t), lerpf(Look.SKY.v, Look.THIRD.v, t)))
	row(group, plain, 1)
	states.append(["4 pink to orange: the long way", group])
	# 5 the difference wrapped
	group = Node3D.new()
	row(group, nine(rgb), 0)
	row(group, nine(hsv), 1)
	states.append(["5 the turn wrapped", group])
	rgb.free()
	hsv.free()
	# 6 a class: four spaces
	group = Node3D.new()
	for i in SPACES.size():
		var wall := Wall.new()
		wall.space = SPACES[i]
		wall.position = Vector3(0, i * 0.45, -1)
		group.add_child(wall)
	states.append(["6 a class: four spaces", group])
	for state: Array in states:
		await stand(state[1])
		eye.fov = 70.0                 # the field of view of the walker's Eyes
		look_from(EYES, EYES + Vector3(0, 0, -1))
		tiles.append(small(await shot("strip_%s" % (state[0] as String).left(1))))
		names.append(state[0])
	eye.fov = FOV

## The lamp and the ray. A still of the running scene would measure the look's
## filter as well, so the scene's own script, faces.gd, stands in the studio's
## plain light, with a marker called Walker where the walker would stand: the
## script puts its lamp 0.7 m above that marker, as it does above the walker.
func place(tiles: Array[Image], names: Array) -> void:
	var faces: Node3D = Faces.new()
	var marker := Node3D.new()
	marker.name = "Walker"
	marker.position = START
	faces.add_child(marker)
	await stand(faces, false)     # not held: its _process moves the lamp and hears the keys
	eye.fov = 70.0
	var lamp: SpotLight3D = faces.lamp
	# As the scene starts: the walker in front of the wall's left end, the lamp white.
	look_from(START + Vector3(0, 1.6, 0), START + Vector3(0, 1.6, -1))
	var start := {}
	for light: String in ["off", "white"]:
		lamp.visible = light == "white"
		var start_still := await shot("start_lamp_" + light)
		for wall: Node3D in faces.walls:
			start["%s_first_step_lamp_%s" % [wall.space, light]] = hex(mean(start_still, eye, face(wall, 0), 0.5))
	print("at the start the first, lime step of the four walls is rendered %s %s %s %s with the lamp off and %s %s %s %s under the white lamp" % [
		start["rgb_first_step_lamp_off"], start["hsv_first_step_lamp_off"], start["linear_first_step_lamp_off"], start["oklab_first_step_lamp_off"],
		start["rgb_first_step_lamp_white"], start["hsv_first_step_lamp_white"], start["linear_first_step_lamp_white"], start["oklab_first_step_lamp_white"]])
	# In front of the middle of the wall.
	marker.position = Vector3(0, 0, 1.6)
	look_from(EYES, EYES + Vector3(0, 0, -1))
	for i in 4:
		await physics_frame
	await process_frame
	var record := {"lamp_at": [snappedf(lamp.position.x, 0.01), snappedf(lamp.position.y, 0.01), snappedf(lamp.position.z, 0.01)], "cone_degrees": lamp.spot_angle, "energy": lamp.light_energy, "lights": {},
		"at_the_start": start}
	var lamp_tiles: Array[Image] = []
	var lamp_names := []
	var seen := {}
	for light: String in ["off", "white", "first", "second"]:
		if light == "off":
			lamp.visible = false
		else:
			lamp.visible = true
			if light != "white":
				await press("pause")
		var still := await shot("lamp_" + light)
		lamp_tiles.append(small(still))
		lamp_names.append("lamp %s%s" % [light, "" if light == "off" else " " + hex(lamp.light_color)])
		var row_record := {"light": "none" if light == "off" else hex(lamp.light_color)}
		seen[light] = {}
		for w in faces.walls.size():
			var wall: Node3D = faces.walls[w]
			var c := mean(still, eye, face(wall, 4), 0.5)
			seen[light][wall.space] = c
			row_record[wall.space + "_middle"] = hex(c)
		record["lights"][light] = row_record
		print("lamp %-6s the four middle steps are rendered %s %s %s %s" % [light, row_record["rgb_middle"], row_record["hsv_middle"], row_record["linear_middle"], row_record["oklab_middle"]])
		if light == "first":
			tiles.append(small(still))
			names.append("7 under the lamp")
	var two := {}
	for space: String in SPACES:
		two[space] = {"painted": hex(faces.walls[SPACES.find(space)].mix(0.5)),
			"under_first_vs_under_second_rgb_of_255": snappedf(off(seen["first"][space], seen["second"][space]), 0.1),
			"under_first_vs_under_second_oklab_times_100": snappedf(Oklab.apart(seen["first"][space], seen["second"][space]), 0.1),
			"off_vs_white_rgb_of_255": snappedf(off(seen["off"][space], seen["white"][space]), 0.1)}
	record["one_colour_two_lights"] = two
	record["how"] = "faces.gd in the sheet's studio, a marker in the walker's place at (0, 0, 1.6), the eye where the walker's eyes would be (1.6 m up, field of view 70 degrees); a step's colour is the mean of the still inside the middle half of its face"
	report["lamp"] = record
	report["lamp_png"] = await compose(lamp_tiles, 4, lamp_names, "res://lamp.png")
	# Paint with the ray. The lamp is violet now: two presses on a step of the second wall, left of the middle.
	# Then the lamp in lime, and two presses on a step right of the middle.
	var painted := {}
	for stop: Array in [[-0.8, 0], [0.8, 2]]:
		for i in stop[1]:
			await press("pause")
		marker.position = Vector3(stop[0], 0, 1.6)
		await process_frame
		for i in 4:
			await physics_frame
		var step: MeshInstance3D = faces.walls[1].boxes[4 + roundi(stop[0] / 0.4)]
		var before := hex(step.material_override.albedo_color)
		await press("drop")
		await press("drop")
		painted["step %d" % (4 + roundi(stop[0] / 0.4))] = {"with": hex(lamp.light_color), "from": before, "to": hex(step.material_override.albedo_color)}
	marker.position = Vector3(0, 0, 1.6)
	for i in 4:
		await physics_frame
	tiles.append(small(await shot("strip_8")))
	names.append("8 painted by the ray")
	report["painted_steps_of_the_hsv_wall"] = painted
	eye.fov = FOV

## An action of the Input Map, pressed and let go, as a key would.
func press(action: String) -> void:
	await process_frame
	Input.action_press(action)
	await physics_frame
	await process_frame
	Input.action_release(action)
	await process_frame
