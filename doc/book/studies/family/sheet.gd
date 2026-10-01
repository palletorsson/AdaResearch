extends SceneTree
## Photographs the sweep sheet and makes the process strip. Needs a window, so
## run it WITHOUT --headless:
##   godot --path . --xr-mode off --script res://sheet.gd
## The sheet: the four values of the axis (segments 4, 8, 16, 64, rings half of
## that), each member alone on the sheet, from four standpoints 2 m from its
## middle. `level` looks at it from the side, at the height of its middle.
## `above` looks straight down its axis. `turned` is `level` with the member
## turned half a segment, so that an edge faces us where a corner did.
## `faceted` is `level` with every triangle lit flat: the same corners, the
## normals not smoothed. The study's own points, line, marble and labels are
## hidden and the light casts no shadow, so that only the body is compared.
## Each still is taken twice: once as the eye gets it, once with the member in
## one flat colour, which says exactly which pixels are body.
## It writes stills/<name>.png, sheet.png (level in the upper row, above in the
## middle, faceted in the lower, named) and sheet.json, the measurements TUTORIAL.md quotes: on how
## much of the still two members differ, how much of that lies on the rim (one
## body is there and the other is not) and how much inside, how far each
## outline is from a circle, a longer series of members against 64, two pairs
## from four distances, and the octahedron beside the member of 4.
## The strip: one still after each operation of the lesson, from one fixed
## camera, composed left to right into process.png with the operation named
## under each.

const VALUES := [4, 8, 16, 64]
const SERIES := [4, 6, 8, 12, 16, 24, 32, 48, 64]   # each of these against 64
const DISTANCES := [1.5, 2.0, 4.0, 8.0]             # metres from the member's middle
const VIEWS := ["level", "above", "turned", "faceted"]
const TILE := Vector2i(320, 240)    # one tile of the sheet and of the strip
const GUTTER := 4                   # pixels between two tiles
const AT := 2.0                     # metres from the member's middle to the camera
const FOV := 40.0
const STRIP_FROM := Vector3(0.0, 3.3, 6.9)
const STRIP_AT := Vector3(0.0, 0.3, 1.1)
const FLAT := Color(1.0, 0.0, 1.0)  # the one colour of the second still
const STUDY_ONLY := ["A", "B", "Segment", "Strip", "Marble", "Record", "Readout"]

var report := {}
var window := Vector2i.ZERO   # the still's size
var crop := Rect2i()          # the middle 4:3 of it: what is measured
var GlobeScript: Script

func _initialize() -> void: run.call_deferred()

## One study. `setup` is a dictionary of Family's variables to set before it is
## built; an empty one leaves the finished family.gd as it is; null takes the
## script off Family, so that this script can build on it by hand.
func open(setup: Variant) -> Node3D:
	var study: Node3D = load("res://family.tscn").instantiate()
	var family: Node3D = study.get_node("Family")
	if setup == null:
		family.set_script(null)
	else:
		for key: String in setup:
			family.set(key, setup[key])
	root.add_child(study)
	await process_frame
	await process_frame
	study.set_process(false)
	for path: String in STUDY_ONLY:
		study.get_node(path).visible = false
	var eye := Camera3D.new()
	eye.name = "Eye"
	eye.fov = FOV
	study.add_child(eye)
	var strip_camera := Camera3D.new()
	strip_camera.name = "StripCamera"
	strip_camera.fov = 36.0
	study.add_child(strip_camera)
	strip_camera.look_at_from_position(STRIP_FROM, STRIP_AT)
	return study

func close(study: Node3D) -> void:
	study.free()
	await process_frame

## Puts the Eye `distance` metres from the middle of the first place on the
## sheet, at the side or above, turns what stands there, and hides the plates.
func look(study: Node3D, view: String, distance: float, turn := 0.0) -> void:
	var sheet: Node3D = study.get_node("Sheet")
	var middle := sheet.to_global(Vector3(0.0, 0.5, 0.0))
	var eye: Camera3D = study.get_node("Eye")
	if view == "above":
		eye.look_at_from_position(middle + Vector3(0.0, distance, 0.0), middle, Vector3(0.0, 0.0, -1.0))
	else:
		eye.look_at_from_position(middle + Vector3(0.0, 0.0, distance), middle)
	eye.current = true
	study.get_node("DirectionalLight3D").shadow_enabled = false
	for plate: Label3D in sheet.plates:
		plate.visible = false
	for member: Node3D in sheet.hung:
		member.rotation.y = turn

func look_strip(study: Node3D) -> void:
	study.get_node("StripCamera").current = true
	study.get_node("DirectionalLight3D").shadow_enabled = true

## The still as the window shows it, cut to the middle 4:3.
func shot(name: String) -> Image:
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	if window == Vector2i.ZERO:
		window = image.get_size()
		var side := window.y * TILE.x / TILE.y
		crop = Rect2i((window.x - side) / 2, 0, side, window.y)
	image = image.get_region(crop)
	if name != "":
		image.save_png("res://stills/" + name + ".png")
	return image

func small(image: Image) -> Image:
	var tile: Image = image.duplicate()
	tile.resize(TILE.x, TILE.y, Image.INTERPOLATE_BILINEAR)
	return tile

## Where a still differs from another: one byte for each pixel, 1 where the
## three channels together are more than a tenth of full scale apart.
func differs(a: Image, b: Image) -> PackedByteArray:
	var p := a.get_data()
	var q := b.get_data()
	var out := PackedByteArray()
	out.resize(p.size() / 3)
	for i in out.size():
		var k := i * 3
		if absi(p[k] - q[k]) + absi(p[k + 1] - q[k + 1]) + absi(p[k + 2] - q[k + 2]) > 25:
			out[i] = 1
	return out

func share(mask: PackedByteArray) -> float:
	return snappedf(100.0 * mask.count(1) / float(mask.size()), 0.01)

## One member, photographed twice: as the eye gets it, and in one flat colour.
## Returns the still and the body: one byte for each pixel, 1 where the member is.
func portrait(member: MeshInstance3D, name: String) -> Array:
	var still := await shot(name)
	var paint := member.material_override
	var flat := StandardMaterial3D.new()
	flat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flat.albedo_color = FLAT
	member.material_override = flat
	var second := await shot("")
	member.material_override = paint
	var data := second.get_data()
	var body := PackedByteArray()
	body.resize(data.size() / 3)
	for i in body.size():
		if data[i * 3] > 200 and data[i * 3 + 1] < 60 and data[i * 3 + 2] > 200:
			body[i] = 1
	return [still, body]

## Two members compared: on how much of the still they differ, how much of
## that is rim (one body is there and the other is not) and how much inside
## (both are there, in another colour). `rim_px` is the rim as a band: its
## pixels divided by the length of the larger body's edge, taken as a circle.
func compare(a: Image, body_a: PackedByteArray, b: Image, body_b: PackedByteArray) -> Dictionary:
	var d := differs(a, b)
	var differ := 0
	var rim := 0
	var inside := 0
	for i in d.size():
		if body_a[i] != body_b[i]:
			rim += 1
			differ += 1
		elif d[i] == 1:
			differ += 1
			if body_a[i] == 1:
				inside += 1
	var total := float(d.size())
	var radius := sqrt(maxi(body_a.count(1), body_b.count(1)) / PI)
	return {
		"differ_pct": snappedf(100.0 * differ / total, 0.01), "rim_pct": snappedf(100.0 * rim / total, 0.01),
		"inside_pct": snappedf(100.0 * inside / total, 0.01), "rim_px": snappedf(rim / (TAU * radius), 0.01),
	}

## The outline of a body in a still: the nearest and the farthest point of its
## edge from its middle, in pixels, looking along 720 directions.
func outline(body: PackedByteArray) -> Dictionary:
	var w := crop.size.x
	var h := crop.size.y
	var sum := Vector2.ZERO
	var count := 0
	for i in body.size():
		if body[i] == 1:
			sum += Vector2(i % w + 0.5, i / w + 0.5)
			count += 1
	if count == 0:
		return {"pixels": 0}
	var middle := sum / float(count)
	var nearest := 1.0e9
	var farthest := 0.0
	for step in 720:
		var direction := Vector2.from_angle(step * TAU / 720.0)
		var r := 0.0
		while true:
			var at := middle + direction * (r + 0.25)
			if at.x < 0 or at.y < 0 or at.x >= w or at.y >= h or body[int(at.y) * w + int(at.x)] == 0:
				break
			r += 0.25
		nearest = minf(nearest, r)
		farthest = maxf(farthest, r)
	return {
		"pixels": count, "share_pct": snappedf(100.0 * count / float(body.size()), 0.01),
		"nearest_px": nearest, "farthest_px": farthest,
		"misses_the_circle_by_pct": snappedf(100.0 * (1.0 - nearest / farthest), 0.01),
	}

## The same corners and triangles with every triangle lit flat.
func faceted(mesh: Mesh) -> ArrayMesh:
	var arrays := mesh.surface_get_arrays(0)
	var corners: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for i in index:
		surface.add_vertex(corners[i])
	surface.generate_normals()
	return surface.commit()

func triangles_with_area(mesh: Mesh) -> int:
	var arrays := mesh.surface_get_arrays(0)
	var corners: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var count := 0
	for t in index.size() / 3:
		var a := corners[index[t * 3]]
		if (corners[index[t * 3 + 1]] - a).cross(corners[index[t * 3 + 2]] - a).length_squared() > 1e-16:
			count += 1
	return count

func run() -> void:
	# The named class has to be listed before anything that says Globe can load.
	var listed := false
	for entry: Dictionary in ProjectSettings.get_global_class_list():
		listed = listed or entry["class"] == &"Globe"
	if not listed:
		print("Godot has not listed this project's named classes yet. Run this once, then run sheet.gd again:")
		print("  godot --headless --path . --xr-mode off --import")
		quit(1)
		return
	GlobeScript = load("res://globe.gd")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://stills"))
	FileAccess.open("res://stills/.gdignore", FileAccess.WRITE)   # the editor then leaves the stills alone
	var stills := {}
	var bodies := {}
	var members := {}
	# The longer series, each member alone on the sheet. The four values of the argument are among them.
	for n: int in SERIES:
		var study := await open({"values": str(n)})
		var member: MeshInstance3D = study.get_node("Sheet").hung[0]
		var entry := {"segments": member.segments, "rings": member.rings, "triangles": member.triangles(), "triangles_with_area": triangles_with_area(member.mesh)}
		for distance: float in DISTANCES:
			if distance != AT and (n == 8 or n == 16 or n == 64):
				look(study, "level", distance)
				var key := "%d_level_%s" % [n, distance]
				var far: Array = await portrait(member, "")
				stills[key] = far[0]
				bodies[key] = far[1]
		for view: String in VIEWS:
			look(study, "above" if view == "above" else "level", AT, PI / member.segments if view == "turned" else 0.0)
			if view == "faceted":
				member.mesh = faceted(member.mesh)
			var key := "%d_%s" % [n, view]
			var taken: Array = await portrait(member, key if VALUES.has(n) else "")
			stills[key] = taken[0]
			bodies[key] = taken[1]
			entry["outline_" + view] = outline(bodies[key])
			if view == "level":
				entry["primitives_drawn"] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		members[str(n)] = entry
		print("%2d segments, %2d rings: %4d triangles (%4d with area); its outline misses the circle by %5.2f%% from the side, %5.2f%% from above; it covers %5.2f%% and %5.2f%% of the still" % [
			entry["segments"], entry["rings"], entry["triangles"], entry["triangles_with_area"],
			entry["outline_level"]["misses_the_circle_by_pct"], entry["outline_above"]["misses_the_circle_by_pct"],
			entry["outline_level"]["share_pct"], entry["outline_above"]["share_pct"]])
		await close(study)
	report["members"] = members
	# The sheet with nobody on it: what the renderer draws before any member.
	var bare := await open(null)
	look(bare, "level", AT)
	await shot("")
	report["primitives_drawn_with_nobody"] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	print("primitives in the frame, from the side: %d with nobody on the sheet, %d with the member of 4, %d with the member of 64" % [
		report["primitives_drawn_with_nobody"], members["4"]["primitives_drawn"], members["64"]["primitives_drawn"]])
	await close(bare)
	# The six pairs of the argument, from each standpoint.
	for view: String in VIEWS:
		var pairs := {}
		var closest := ""
		var farthest := ""
		for i in VALUES.size():
			for j in range(i + 1, VALUES.size()):
				var a := "%d_%s" % [VALUES[i], view]
				var b := "%d_%s" % [VALUES[j], view]
				var key := "%d vs %d" % [VALUES[i], VALUES[j]]
				pairs[key] = compare(stills[a], bodies[a], stills[b], bodies[b])
				if closest == "" or pairs[key]["differ_pct"] < pairs[closest]["differ_pct"]:
					closest = key
				if farthest == "" or pairs[key]["differ_pct"] > pairs[farthest]["differ_pct"]:
					farthest = key
				print("%s: %s differ on %5.2f%% of the still: %5.2f%% on the rim (a band of %.2f pixels), %5.2f%% inside" % [view, key, pairs[key]["differ_pct"], pairs[key]["rim_pct"], pairs[key]["rim_px"], pairs[key]["inside_pct"]])
		report["pairs_" + view] = pairs
		report["closest_pair_" + view] = closest
		report["farthest_pair_" + view] = farthest
		print("sheet: %s: the closest pair is %s (%.2f%%), the farthest %s (%.2f%%)" % [view, closest, pairs[closest]["differ_pct"], farthest, pairs[farthest]["differ_pct"]])
	# Every member of the series against 64.
	for view: String in VIEWS:
		var against := {}
		var line := ""
		for n: int in SERIES:
			if n != 64:
				var a := "%d_%s" % [n, view]
				var b := "64_%s" % view
				against[str(n)] = compare(stills[a], bodies[a], stills[b], bodies[b])
				line += "  %d: %.2f%%" % [n, against[str(n)]["differ_pct"]]
		report["against_64_" + view] = against
		print("%s, each against 64:%s" % [view, line])
	# Two pairs from four distances, from the side.
	var far := {}
	for distance: float in DISTANCES:
		var suffix := "level" if distance == AT else "level_%s" % distance
		var row := {}
		for pair: Array in [[8, 16], [16, 64]]:
			var a := "%d_%s" % [pair[0], suffix]
			var b := "%d_%s" % [pair[1], suffix]
			row["%d vs %d" % pair] = compare(stills[a], bodies[a], stills[b], bodies[b])
		row["body_share_pct"] = share(bodies["64_" + suffix])
		far["%s m" % distance] = row
		print("from %.1f m: 8 and 16 differ on %5.2f%% of the still (a band of %.2f pixels), 16 and 64 on %5.2f%% (%.2f pixels); the body covers %5.2f%%" % [
			distance, row["8 vs 16"]["differ_pct"], row["8 vs 16"]["rim_px"], row["16 vs 64"]["differ_pct"], row["16 vs 64"]["rim_px"], row["body_share_pct"]])
	report["from_four_distances"] = far
	# The octahedron: 4 segments and ONE ring, beside the member of 4, which has two.
	var study := await open({"values": "4"})
	var eight: MeshInstance3D = study.get_node("Sheet").hung[0]
	eight.rings = 1
	eight.build()
	var octahedron := {"segments": eight.segments, "rings": eight.rings, "triangles": eight.triangles(), "triangles_with_area": triangles_with_area(eight.mesh)}
	for view: String in ["level", "above", "turned"]:
		look(study, "above" if view == "above" else "level", AT, PI / eight.segments if view == "turned" else 0.0)
		var taken: Array = await portrait(eight, "octahedron_" + view)
		octahedron["against_4_" + view] = compare(taken[0], taken[1], stills["4_" + view], bodies["4_" + view])
		octahedron["against_8_" + view] = compare(taken[0], taken[1], stills["8_" + view], bodies["8_" + view])
	report["octahedron"] = octahedron
	print("the octahedron (4 segments, 1 ring, %d triangles, %d with area) against the member of 4: %.2f%% of the still from the side, %.2f%% from above, %.2f%% turned; against the member of 8: %.2f%%, %.2f%%, %.2f%%" % [
		octahedron["triangles"], octahedron["triangles_with_area"],
		octahedron["against_4_level"]["differ_pct"], octahedron["against_4_above"]["differ_pct"], octahedron["against_4_turned"]["differ_pct"],
		octahedron["against_8_level"]["differ_pct"], octahedron["against_8_above"]["differ_pct"], octahedron["against_8_turned"]["differ_pct"]])
	await close(study)
	# sheet.png: from the side in the upper row, from above in the middle, faceted below.
	var tiles: Array[Image] = []
	var names := []
	for view: String in ["level", "above", "faceted"]:
		for n: int in VALUES:
			tiles.append(small(stills["%d_%s" % [n, view]]))
	for n: int in VALUES:
		names.append("%d segments, %d rings: %d triangles" % [n, members[str(n)]["rings"], members[str(n)]["triangles"]])
	report["sheet_png"] = await compose(tiles, VALUES.size(), names, "res://sheet.png")
	await strip()
	report["still"] = {"width": crop.size.x, "height": crop.size.y, "metres_to_the_member": AT, "fov": FOV}
	report["godot"] = Engine.get_version_info().string
	report["renderer"] = RenderingServer.get_video_adapter_name()
	FileAccess.open("res://sheet.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	quit(0)

## What a step of the strip claims, counted on the two nodes.
func counted(study: Node3D) -> Dictionary:
	var family: Node3D = study.get_node("Family")
	var sheet: Node3D = study.get_node("Sheet")
	var made := family.get_children()
	var counts := []
	var of_the_class := 0
	for body: MeshInstance3D in made:
		counts.append(body.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size() / 3)
		if body.get_script() == GlobeScript:
			of_the_class += 1
	var different := []
	for c: int in counts:
		if not different.has(c):
			different.append(c)
	var titles := []
	for plate: Label3D in sheet.plates:
		titles.append(plate.text)
	return {"bodies": made.size(), "of_the_class": of_the_class, "triangles": counts, "different_bodies": different.size(), "plates": titles}

## The process strip. Each step is one operation of the lesson, done here as the
## lesson does it, and photographed. What each step claims is counted.
func strip() -> void:
	var names := ["1 a sphere, written out", "2 the same, as a class", "3 a row of four", "4 hung and named", "5 the axis by name: four alike", "6 the right name"]
	var tiles: Array[Image] = []
	var steps := []
	# 1: a mesh node and a SphereMesh, written out, as the lesson first does it.
	var study := await open(null)
	look_strip(study)
	var family: Node3D = study.get_node("Family")
	var sphere := SphereMesh.new()
	sphere.radial_segments = 16
	sphere.rings = 8
	var body := MeshInstance3D.new()
	body.mesh = sphere
	family.add_child(body)
	body.position = Vector3(0, 0.5, 0)
	tiles.append(small(await shot("strip_1")))
	steps.append(counted(study))
	await close(study)
	# 2: one member of the class in its place.
	study = await open(null)
	look_strip(study)
	family = study.get_node("Family")
	var member: MeshInstance3D = GlobeScript.new()
	family.add_child(member)
	member.position = Vector3(0, 0.5, 0)
	tiles.append(small(await shot("strip_2")))
	steps.append(counted(study))
	await close(study)
	# 3: four members by a loop over numbers, placed by hand.
	study = await open(null)
	look_strip(study)
	family = study.get_node("Family")
	var place := 0
	for n: int in VALUES:
		member = GlobeScript.new()
		member.segments = n
		member.rings = n / 2
		family.add_child(member)
		member.position = Vector3(place * 1.2, 0.5, 0)
		place += 1
	tiles.append(small(await shot("strip_3")))
	steps.append(counted(study))
	await close(study)
	# 4: the same four, hung on the sheet under the number we asked for.
	study = await open(null)
	look_strip(study)
	family = study.get_node("Family")
	for n: int in VALUES:
		member = GlobeScript.new()
		member.segments = n
		member.rings = n / 2
		family.add_child(member)
		study.get_node("Sheet").hang(member, str(n))
	tiles.append(small(await shot("strip_4")))
	steps.append(counted(study))
	await close(study)
	# 5: the field named in a text, with a name the class does not have.
	study = await open(null)
	look_strip(study)
	family = study.get_node("Family")
	for word: String in "4, 8, 16, 64".split(","):
		var title := word.strip_edges()
		member = GlobeScript.new()
		member.set("radial_segments", title)
		member.rings = member.segments / 2
		family.add_child(member)
		study.get_node("Sheet").hang(member, title)
	tiles.append(small(await shot("strip_5")))
	steps.append(counted(study))
	await close(study)
	# 6: family.gd as it is shipped.
	study = await open({})
	look_strip(study)
	tiles.append(small(await shot("strip_6")))
	steps.append(counted(study))
	await close(study)
	var most := 1
	for i in names.size():
		steps[i]["step"] = names[i]
		steps[i]["differs_from_step_before_pct"] = share(differs(tiles[i], tiles[i - 1])) if i > 0 else 0.0
		if i > 0 and steps[i]["differs_from_step_before_pct"] > steps[most]["differs_from_step_before_pct"]:
			most = i
		print("strip %-31s %d bodies, %d of the class, triangles %s, %d different, plates %s; differs from the step before on %5.2f%% of the tile" % [
			names[i], steps[i]["bodies"], steps[i]["of_the_class"], steps[i]["triangles"], steps[i]["different_bodies"], steps[i]["plates"], steps[i]["differs_from_step_before_pct"]])
	report["strip"] = steps
	report["strip_step_that_changed_most"] = names[most]
	report["process_png"] = await compose(tiles, tiles.size(), names, "res://process.png")

## Tiles in rows of `columns`, with a name under each column, drawn in a
## viewport of its own and saved as one image.
func compose(tiles: Array[Image], columns: int, names: Array, path: String) -> Dictionary:
	var band := 26
	var rows := tiles.size() / columns
	var sheet := SubViewport.new()
	sheet.size = Vector2i(TILE.x * columns + GUTTER * (columns - 1), (TILE.y + GUTTER) * rows - GUTTER + band)
	sheet.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sheet)
	var ground := ColorRect.new()
	ground.color = Color(0.08, 0.09, 0.11)
	ground.size = sheet.size
	sheet.add_child(ground)
	for i in tiles.size():
		var picture := TextureRect.new()
		picture.texture = ImageTexture.create_from_image(tiles[i])
		picture.position = Vector2((TILE.x + GUTTER) * (i % columns), (TILE.y + GUTTER) * (i / columns))
		sheet.add_child(picture)
	for i in columns:
		var label := Label.new()
		label.text = names[i]
		label.position = Vector2((TILE.x + GUTTER) * i, (TILE.y + GUTTER) * rows - GUTTER)
		label.size = Vector2(TILE.x, band)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 15)
		sheet.add_child(label)
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = sheet.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	image.save_png(path)
	sheet.free()
	var result := {"width": image.get_width(), "height": image.get_height(), "bytes": FileAccess.get_file_as_bytes(path).size()}
	print("%s: %d x %d, %d bytes" % [path.get_file(), result["width"], result["height"], result["bytes"]])
	return result
