extends "res://supplied/sheet_tools.gd"
## The kit base's own sheet: it proves the still-making tools and measures the
## look. It needs a window, so run it WITHOUT --headless, from this folder:
##   godot --path . --xr-mode off --script res://sheet.gd
## It writes
##   sheet.png    two values of one axis (a box of 0.5 m and of 0.8 m), each
##                alone in the studio, from the side and from above
##   process.png  a strip of three steps from one standpoint: a box; a marble
##                dropped on it; a walker beside it
##   look.png     five boxes in BODY, SECOND, THIRD, BONE and GHOST from the
##                fixed camera, as the eye gets them
##   sheet.json   the measurements: on how much of the still the two boxes
##                differ, how much each strip step changed, and for the look
##                the colour each box's faces were rendered in, how far that is
##                from the palette, and its contrast against the rendered floor
## and the stills, in stills/. A kit replaces this file with its own, built on
## the same first line.

const VALUES := [0.5, 0.8]            # the axis: the edge of a box, in metres
const VIEWS := ["level", "above"]
const ROLES := ["BODY", "SECOND", "THIRD", "BONE", "GHOST"]

func box(edge: float, material: Material) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(edge, edge, edge)
	body.mesh = mesh
	body.material_override = material
	body.position.y = edge / 2.0
	return body

func run() -> void:
	await sheet()
	await process_strip()
	await look_measured()

## The comparison sheet: every value from every standpoint, every pair measured.
func sheet() -> void:
	var tiles: Array[Image] = []
	var names := []
	for value: float in VALUES:
		names.append("edge %.1f m" % value)
	for view: String in VIEWS:
		var stills := []
		var pixels := []
		for value: float in VALUES:
			var taken: Array = await photograph(box(value, Look.paint(Look.BODY)), view, "edge_%.1f_%s" % [value, view])
			stills.append(taken[0])
			pixels.append(taken[1])
			tiles.append(small(taken[0]))
			print("%s, edge %.1f m: the box covers %.2f%% of the still" % [view, value, share(taken[1])])
		report["pairs_" + view] = compare_all(names, stills, pixels)
	report["sheet_png"] = await compose(tiles, VALUES.size(), names, "res://sheet.png")

## The process strip: one still after each step, from one standpoint.
func process_strip() -> void:
	var names := ["1 a box", "2 a marble dropped on it", "3 a walker beside it"]
	var tiles: Array[Image] = []
	var group := Node3D.new()
	await stand(group, false)     # not held: the marble has to fall
	look_from(Vector3(0.3, 1.8, 4.4), Vector3(0.3, 0.7, 0.0))
	group.add_child(load("res://guests/example/example.tscn").instantiate())
	tiles.append(small(await shot("strip_1")))
	var marble: RigidBody3D = load("res://supplied/marble.tscn").instantiate()
	group.add_child(marble)
	marble.drop(Vector3(0.0, 1.5, 0.0))
	for i in 150:
		await physics_frame
	tiles.append(small(await shot("strip_2")))
	var walker: CharacterBody3D = load("res://supplied/walker.tscn").instantiate()
	walker.position = Vector3(0.9, 0.0, 0.0)   # before add_child: a body added at the origin would knock the marble away
	group.add_child(walker)
	for i in 30:
		await physics_frame
	tiles.append(small(await shot("strip_3")))
	report["strip"] = await strip(tiles, names)
	report["strip"]["marble_rests_at_m"] = snappedf(marble.global_position.y, 0.001)

## The look, measured: what the light and the tonemap do to the palette.
func look_measured() -> void:
	var group := Node3D.new()
	var boxes := []
	for i in ROLES.size():
		var material: Material = Look.ghost() if ROLES[i] == "GHOST" else Look.paint(colour_of(ROLES[i]))
		var body := box(0.5, material)
		body.position += Vector3((i - 2) * 1.1, 0.0, 0.3)
		group.add_child(body)
		boxes.append(body)
	await stand(group)
	var camera: Camera3D = studio.get_node("Camera3D")
	camera.current = true         # the fixed camera of base.tscn, as a kit's scene shows it
	shadows(true)
	var still := await shot("look")
	still.save_png("res://look.png")
	var light: Vector3 = -studio.get_node("Look/Sun").global_basis.z   # the way the light travels
	var floor_lit := mean(still, camera, [Vector3(-0.6, 0, 1.3), Vector3(-0.4, 0, 1.3), Vector3(-0.4, 0, 1.5), Vector3(-0.6, 0, 1.5)])
	var sky := still.get_pixel(20, 20)
	var record := {"sky": entry(sky, Look.SKY), "floor_in_the_sun": entry(floor_lit, Look.GROUND), "boxes": {}}
	record["sky_against_floor_contrast"] = contrast(sky, floor_lit)
	print("look: the sky is rendered %s (SKY is %s); the floor in the sun %s (GROUND is %s, %.1f away); sky against floor %.2f : 1" % [
		hex(sky), hex(Look.SKY), hex(floor_lit), hex(Look.GROUND), record["floor_in_the_sun"]["off_by"], record["sky_against_floor_contrast"]])
	for i in ROLES.size():
		var c: Vector3 = boxes[i].position
		var top := mean(still, camera, [c + Vector3(-0.25, 0.25, -0.25), c + Vector3(0.25, 0.25, -0.25), c + Vector3(0.25, 0.25, 0.25), c + Vector3(-0.25, 0.25, 0.25)])
		var front := mean(still, camera, [c + Vector3(-0.25, -0.25, 0.25), c + Vector3(0.25, -0.25, 0.25), c + Vector3(0.25, 0.25, 0.25), c + Vector3(-0.25, 0.25, 0.25)])
		# A patch of floor in the box's shadow: beside its right edge, a quarter of the shadow's reach along the light.
		var reach: float = 0.5 / -light.y
		var s := Vector3(c.x + 0.25 + light.x * reach * 0.5, 0.0, c.z + 0.1 + light.z * reach * 0.25)
		var shadow := mean(still, camera, [s + Vector3(-0.04, 0, -0.04), s + Vector3(0.04, 0, -0.04), s + Vector3(0.04, 0, 0.04), s + Vector3(-0.04, 0, 0.04)])
		var palette := colour_of(ROLES[i])
		var row := {"palette": hex(palette), "lit_face": entry(top, palette), "front_face": entry(front, palette),
			"lit_face_against_floor_contrast": contrast(top, floor_lit), "front_face_against_floor_contrast": contrast(front, floor_lit),
			"floor_in_its_shadow": hex(shadow), "floor_in_the_sun_against_its_shadow_contrast": contrast(floor_lit, shadow)}
		record["boxes"][ROLES[i]] = row
		print("look: %-6s %s  lit face %s, %5.1f away, %5.2f : 1 against the floor; front face %s, %5.1f away, %5.2f : 1; the floor in its shadow %s, %.2f : 1 against the floor in the sun" % [
			ROLES[i], hex(palette), hex(top), row["lit_face"]["off_by"], row["lit_face_against_floor_contrast"], hex(front), row["front_face"]["off_by"], row["front_face_against_floor_contrast"],
			hex(shadow), row["floor_in_the_sun_against_its_shadow_contrast"]])
	record["sun"] = {"energy": Look.SUN_ENERGY, "turn_rad": [Look.SUN_TURN.x, Look.SUN_TURN.y, Look.SUN_TURN.z], "ambient_energy": Look.AMBIENT_ENERGY, "tonemap": "linear", "glow": false, "fog": false}
	record["how"] = "mean of the still's pixels inside each face, the face shrunk to 0.7 of its size; off_by is the distance in red, green and blue together, of 255 each; contrast is (L1 + 0.05) / (L2 + 0.05) of the two relative luminances"
	report["look"] = record

func colour_of(role: String) -> Color:
	return (Look as Script).get_script_constant_map()[role]

func hex(c: Color) -> String:
	return "#" + c.to_html(false)

func entry(rendered: Color, palette: Color) -> Dictionary:
	var off := Vector3(rendered.r - palette.r, rendered.g - palette.g, rendered.b - palette.b).length() * 255.0
	return {"rendered": hex(rendered), "off_by": snappedf(off, 0.1)}

func luminance(c: Color) -> float:
	var linear := c.srgb_to_linear()
	return 0.2126 * linear.r + 0.7152 * linear.g + 0.0722 * linear.b

func contrast(a: Color, b: Color) -> float:
	var high := maxf(luminance(a), luminance(b))
	var low := minf(luminance(a), luminance(b))
	return snappedf((high + 0.05) / (low + 0.05), 0.01)

## The mean colour of a still inside a four-cornered face given in the room,
## as `camera` sees it, the face shrunk to 0.7 of its size about its middle.
func mean(still: Image, camera: Camera3D, corners: Array) -> Color:
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
