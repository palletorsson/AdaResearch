extends SceneTree
## Photographs the three bodies and makes the process strip. Needs a window, so
## run it WITHOUT --headless:
##   godot --path . --xr-mode off --script res://sheet.gd
## The sheet: the three values of the axis (by hand, drafted, found), each body
## alone on the sheet, 2 m from its middle. `level` looks at it from the side,
## at the height of its middle. `above` looks straight down. `faceted` is
## `level` with every triangle lit flat: the same corners, the normals not
## smoothed. For these three every body wears the sheet's one paint, so that
## bodies are compared and not materials; `own` is `level` with the found body
## in the material its file brought. The study's own points, line, marble and
## labels are hidden and the light casts no shadow.
## Each still is taken twice: once as the eye gets it, once with the body in
## one flat colour, which says exactly which pixels are body.
## It writes stills/<name>.png, sheet.png (level, above, faceted; named) and
## sheet.json, the measurements TUTORIAL.md quotes: how many triangles each
## body lists and how many the renderer drew, on how much of the still two
## bodies differ, how much of that is outline (one body is there and the other
## is not) and how much inside, and the two made bodies again with a cut of
## 0.9 asked of both.
## The strip: one still after each operation of the lesson, from one fixed
## camera, composed left to right into process.png with the operation named
## under each.

const VALUES := ["by hand", "drafted", "found"]
const VIEWS := ["level", "above", "faceted"]
const TILE := Vector2i(320, 240)    # one tile of the sheet and of the strip
const GUTTER := 4                   # pixels between two tiles
const AT := 2.0                     # metres from the body's middle to the camera
const FOV := 40.0
const STRIP_FROM := Vector3(-0.6, 1.9, 5.3)
const STRIP_AT := Vector3(-0.6, 0.5, 0.9)
const DISTANCES := [2.0, 4.0, 8.0, 16.0]     # metres from the found body, for what the renderer draws
const FLAT := Color(1.0, 0.0, 1.0)  # the one colour of the second still
const STUDY_ONLY := ["A", "B", "Segment", "Strip", "Marble", "Record", "Readout"]

var report := {}
var window := Vector2i.ZERO   # the still's size
var crop := Rect2i()          # the middle 4:3 of it: what is measured

func _initialize() -> void: run.call_deferred()

## One study. `setup` is a dictionary of Collage's variables to set before it is
## built; an empty one leaves the finished collage.gd as it is; null takes the
## script off Collage, so that this script can build on it by hand.
func open(setup: Variant) -> Node3D:
	var study: Node3D = load("res://collage.tscn").instantiate()
	var collage: Node3D = study.get_node("Collage")
	if setup == null:
		collage.set_script(null)
	else:
		for key: String in setup:
			collage.set(key, setup[key])
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
	strip_camera.far = 400.0
	study.add_child(strip_camera)
	strip_camera.look_at_from_position(STRIP_FROM, STRIP_AT)
	return study

func close(study: Node3D) -> void:
	study.free()
	await process_frame

## The meshes of a body: the body itself if it is a mesh node, or the mesh
## nodes anywhere below it if it came from a file.
func parts(body: Node3D) -> Array:
	if body is MeshInstance3D:
		return [body]
	return body.find_children("*", "MeshInstance3D", true, false)

func listed(mesh: Mesh) -> int:
	var arrays := mesh.surface_get_arrays(0)
	if arrays[Mesh.ARRAY_INDEX] == null:
		return arrays[Mesh.ARRAY_VERTEX].size() / 3
	return arrays[Mesh.ARRAY_INDEX].size() / 3

func corner_at(arrays: Array, i: int) -> Vector3:
	if arrays[Mesh.ARRAY_INDEX] == null:
		return arrays[Mesh.ARRAY_VERTEX][i]
	return arrays[Mesh.ARRAY_VERTEX][arrays[Mesh.ARRAY_INDEX][i]]

func triangles_with_area(mesh: Mesh) -> int:
	var arrays := mesh.surface_get_arrays(0)
	var count := 0
	for t in listed(mesh):
		var a := corner_at(arrays, t * 3)
		if (corner_at(arrays, t * 3 + 1) - a).cross(corner_at(arrays, t * 3 + 2) - a).length_squared() > 1e-16:
			count += 1
	return count

## The box of a body in the room, in metres, from its corners where they stand.
func box_of(body: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for part: MeshInstance3D in parts(body):
		for v: Vector3 in part.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			var at := part.global_transform * v
			box = AABB(at, Vector3.ZERO) if first else box.expand(at)
			first = false
	return box

## Puts the Eye `distance` metres from the middle of the first place on the
## sheet, at the side or above, and hides the plates.
func look(study: Node3D, view: String, distance: float) -> void:
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

## One body, photographed twice: as the eye gets it, and in one flat colour.
## Returns the still and the body: one byte for each pixel, 1 where the body is.
func portrait(body: Node3D, name: String) -> Array:
	var still := await shot(name)
	var worn := []
	var flat := StandardMaterial3D.new()
	flat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flat.albedo_color = FLAT
	for part: MeshInstance3D in parts(body):
		worn.append(part.material_override)
		part.material_override = flat
	var second := await shot("")
	var i := 0
	for part: MeshInstance3D in parts(body):
		part.material_override = worn[i]
		i += 1
	var data := second.get_data()
	var mask := PackedByteArray()
	mask.resize(data.size() / 3)
	for k in mask.size():
		if data[k * 3] > 200 and data[k * 3 + 1] < 60 and data[k * 3 + 2] > 200:
			mask[k] = 1
	return [still, mask]

## Two bodies compared: on how much of the still they differ, how much of that
## is outline (one body is there and the other is not: the rim, and any hole
## one can see through) and how much inside (both are there, in another
## colour). `outline_px` is the outline as a band: its pixels divided by the
## length of the larger body's edge, taken as a circle.
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
		"differ_pct": snappedf(100.0 * differ / total, 0.01), "outline_pct": snappedf(100.0 * rim / total, 0.01),
		"inside_pct": snappedf(100.0 * inside / total, 0.01), "outline_px": snappedf(rim / (TAU * radius), 0.01),
	}

## The same corners and triangles with every triangle lit flat.
func faceted(mesh: Mesh) -> ArrayMesh:
	var arrays := mesh.surface_get_arrays(0)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for i in listed(mesh) * 3:
		surface.add_vertex(corner_at(arrays, i))
	surface.generate_normals()
	return surface.commit()

func paint(body: Node3D, material: Material) -> void:
	for part: MeshInstance3D in parts(body):
		part.material_override = material

func run() -> void:
	# The named classes and the imported file have to be there before anything can load.
	var named := []
	for entry: Dictionary in ProjectSettings.get_global_class_list():
		named.append(entry["class"])
	if not named.has(&"Solid") or not named.has(&"Found") or not ResourceLoader.exists("res://found.gltf"):
		print("Godot has not listed this project's named classes or imported found.gltf yet. Run this once, then run sheet.gd again:")
		print("  godot --headless --path . --xr-mode off --import")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://stills"))
	FileAccess.open("res://stills/.gdignore", FileAccess.WRITE)   # the editor then leaves the stills alone
	var stills := {}
	var masks := {}
	var members := {}
	for how: String in VALUES:
		var study := await open({"made": how})
		var sheet: Node3D = study.get_node("Sheet")
		var body: Node3D = sheet.hung[0]
		var meshes := parts(body)
		var box := box_of(body)
		var entry := {
			"class": body.get_class(), "mesh_nodes": meshes.size(), "triangles": listed(meshes[0].mesh), "triangles_with_area": triangles_with_area(meshes[0].mesh),
			"corners_listed": meshes[0].mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size(), "has_a_list_of_corner_numbers": meshes[0].mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX] != null,
			"box_m": [snappedf(box.size.x, 0.001), snappedf(box.size.y, 0.001), snappedf(box.size.z, 0.001)], "lowest_point_m": snappedf(box.position.y, 0.001),
			"painted_by_the_sheet": meshes[0].material_override == sheet.paint,
		}
		if how == "found":
			look(study, "level", AT)
			var own: Array = await portrait(body, "found_own")
			stills["found_own"] = own[0]
			masks["found_own"] = own[1]
			paint(body, sheet.paint)
		for view: String in VIEWS:
			look(study, "above" if view == "above" else "level", AT)
			if view == "faceted":
				meshes[0].mesh = faceted(meshes[0].mesh)
				paint(body, sheet.paint)
			var key := "%s_%s" % [how, view]
			var taken: Array = await portrait(body, key.replace(" ", "_"))
			stills[key] = taken[0]
			masks[key] = taken[1]
			entry["covers_pct_" + view] = share(taken[1])
			if view == "level":
				entry["primitives_drawn"] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		if how == "found":
			var drawn := {}
			for distance: float in DISTANCES:
				look(study, "level", distance)
				await shot("")
				drawn["%s m" % distance] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
			entry["primitives_drawn_from"] = drawn
			print("the found body lists %d triangles; with it in the frame the renderer drew %s" % [entry["triangles"], drawn])
		members[how] = entry
		print("%-8s %5d triangles (%5d with area), %5d corners listed, box %s m; it covers %5.2f%% of the still from the side, %5.2f%% from above" % [
			how, entry["triangles"], entry["triangles_with_area"], entry["corners_listed"], entry["box_m"], entry["covers_pct_level"], entry["covers_pct_above"]])
		await close(study)
	report["members"] = members
	# The sheet with nobody on it: what the renderer draws before any body.
	var bare := await open(null)
	look(bare, "level", AT)
	await shot("")
	report["primitives_drawn_with_nobody"] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	print("primitives in the frame, from the side: %d with nobody on the sheet, %d by hand, %d drafted, %d found" % [
		report["primitives_drawn_with_nobody"], members["by hand"]["primitives_drawn"], members["drafted"]["primitives_drawn"], members["found"]["primitives_drawn"]])
	await close(bare)
	# The three pairs of the argument, from each standpoint.
	for view: String in VIEWS:
		var pairs := {}
		var closest := ""
		var farthest := ""
		for i in VALUES.size():
			for j in range(i + 1, VALUES.size()):
				var a := "%s_%s" % [VALUES[i], view]
				var b := "%s_%s" % [VALUES[j], view]
				var key := "%s vs %s" % [VALUES[i], VALUES[j]]
				pairs[key] = compare(stills[a], masks[a], stills[b], masks[b])
				if closest == "" or pairs[key]["differ_pct"] < pairs[closest]["differ_pct"]:
					closest = key
				if farthest == "" or pairs[key]["differ_pct"] > pairs[farthest]["differ_pct"]:
					farthest = key
				print("%s: %s differ on %5.2f%% of the still: %5.2f%% outline (a band of %.2f pixels), %5.2f%% inside" % [view, key, pairs[key]["differ_pct"], pairs[key]["outline_pct"], pairs[key]["outline_px"], pairs[key]["inside_pct"]])
		report["pairs_" + view] = pairs
		report["closest_pair_" + view] = closest
		report["farthest_pair_" + view] = farthest
		print("sheet: %s: the closest pair is %s (%.2f%%), the farthest %s (%.2f%%)" % [view, closest, pairs[closest]["differ_pct"], farthest, pairs[farthest]["differ_pct"]])
	# The found body in the material its file brought, against the solid by hand.
	report["found_in_its_own_material_vs_by_hand"] = compare(stills["by hand_level"], masks["by hand_level"], stills["found_own"], masks["found_own"])
	print("the found body in its own material against the one by hand: %.2f%% of the still, %.2f%% of it inside the outline" % [
		report["found_in_its_own_material_vs_by_hand"]["differ_pct"], report["found_in_its_own_material_vs_by_hand"]["inside_pct"]])
	# Where the two made bodies part: a cut of 0.9 asked of both.
	var asked := {}
	for how: String in ["by hand", "drafted"]:
		var study := await open({"made": how})
		var sheet: Node3D = study.get_node("Sheet")
		var body: MeshInstance3D = sheet.hung[0]
		body.cut = 0.9
		body.build()
		body.material_override = sheet.paint
		body.global_position.y = sheet.global_position.y - body.get_aabb().position.y
		look(study, "level", AT)
		var taken: Array = await portrait(body, how.replace(" ", "_") + "_cut_0.9")
		stills[how + "_far"] = taken[0]
		masks[how + "_far"] = taken[1]
		asked[how] = {"cut_field_says": body.cut, "triangles": listed(body.mesh), "height_m": snappedf(body.get_aabb().size.y, 0.001)}
		await close(study)
	asked["differ"] = compare(stills["by hand_far"], masks["by hand_far"], stills["drafted_far"], masks["drafted_far"])
	report["cut_0.9_asked_of_both"] = asked
	print("a cut of 0.9 asked of both: by hand says %.2f and stands %.3f m, drafted says %.2f and stands %.3f m; they differ on %.2f%% of the still" % [
		asked["by hand"]["cut_field_says"], asked["by hand"]["height_m"], asked["drafted"]["cut_field_says"], asked["drafted"]["height_m"], asked["differ"]["differ_pct"]])
	# sheet.png: from the side in the upper row, from above in the middle, faceted below.
	var tiles: Array[Image] = []
	var names := []
	for view: String in VIEWS:
		for how: String in VALUES:
			tiles.append(small(stills["%s_%s" % [how, view]]))
	for how: String in VALUES:
		names.append("%s: %d triangles" % [how, members[how]["triangles"]])
	report["sheet_png"] = await compose(tiles, VALUES.size(), names, "res://sheet.png")
	await strip()
	report["still"] = {"width": crop.size.x, "height": crop.size.y, "metres_to_the_body": AT, "fov": FOV}
	report["godot"] = Engine.get_version_info().string
	report["renderer"] = RenderingServer.get_video_adapter_name()
	FileAccess.open("res://sheet.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	quit(0)

func unique_corners(mesh: Mesh) -> int:
	var seen: Array[Vector3] = []
	for v: Vector3 in mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		var known := false
		for o in seen:
			if o.distance_to(v) < 0.0001:
				known = true
				break
		if not known:
			seen.append(v)
	return seen.size()

## What a step of the strip claims, counted on the two nodes: the bodies under
## Collage, the triangles with area of each, the corners and the height of the first,
## how high the last one's box is, how far its middle is from its plate, and
## what the plates say.
func counted(study: Node3D) -> Dictionary:
	var collage: Node3D = study.get_node("Collage")
	var sheet: Node3D = study.get_node("Sheet")
	var made := collage.get_children()
	var counts := []
	for body: Node3D in made:
		counts.append(triangles_with_area(parts(body)[0].mesh))
	var titles := []
	for plate: Label3D in sheet.plates:
		titles.append(plate.text)
	var first: MeshInstance3D = parts(made[0])[0]
	var last := box_of(made[-1])
	var plate_at: Vector3 = sheet.to_global(Vector3((made.size() - 1) * sheet.spacing, 0.0, 0.0))
	var middle := last.get_center()
	return {
		"bodies": made.size(), "triangles": counts, "plates": titles,
		"first_corners": unique_corners(first.mesh), "first_height_m": snappedf(box_of(made[0]).size.y, 0.001),
		"last_height_m": snappedf(last.size.y, 0.001), "last_lowest_point_m": snappedf(last.position.y, 0.001),
		"last_middle_from_its_plate_m": snappedf(Vector2(middle.x - plate_at.x, middle.z - plate_at.z).length(), 0.001),
	}

## The process strip. Each step is one operation of the lesson, done here as the
## lesson does it, and photographed. What each step claims is counted.
func strip() -> void:
	var names := ["1 the cube, pulled", "2 stood on its diagonal", "3 two corners cut", "4 a drafted answer", "5 a found body arrives", "6 its unit and its origin"]
	var tiles: Array[Image] = []
	var steps := []
	var SolidScript: Script = load("res://solid.gd")
	# 1: the cube pulled along its diagonal, before it is stood upright: the
	#    uncut member, turned back by the turn that build() applies.
	var study := await open(null)
	look_strip(study)
	var collage: Node3D = study.get_node("Collage")
	var solid: MeshInstance3D = SolidScript.new()
	solid.cut = 0.0
	collage.add_child(solid)
	solid.quaternion = Quaternion(Vector3.UP, Vector3.ONE.normalized())
	study.get_node("Sheet").hang(solid, "by hand")
	solid.global_position.y -= box_of(solid).position.y - study.get_node("Sheet").global_position.y
	tiles.append(small(await shot("strip_1")))
	steps.append(counted(study))
	await close(study)
	# 2: stood on its diagonal: the uncut member as the class builds it.
	study = await open(null)
	look_strip(study)
	collage = study.get_node("Collage")
	solid = SolidScript.new()
	solid.cut = 0.0
	collage.add_child(solid)
	study.get_node("Sheet").hang(solid, "by hand")
	tiles.append(small(await shot("strip_2")))
	steps.append(counted(study))
	await close(study)
	# 3: two corners cut: the member at its defaults.
	study = await open({"made": "by hand"})
	look_strip(study)
	tiles.append(small(await shot("strip_3")))
	steps.append(counted(study))
	await close(study)
	# 4: the drafted answer beside it.
	study = await open({"made": "by hand, drafted"})
	look_strip(study)
	tiles.append(small(await shot("strip_4")))
	steps.append(counted(study))
	await close(study)
	# 5: the found body as its file gives it: no unit, no origin.
	study = await open({"made": "by hand, drafted"})
	look_strip(study)
	collage = study.get_node("Collage")
	var raw := Node3D.new()
	raw.add_child(load("res://found.gltf").instantiate())
	collage.add_child(raw)
	study.get_node("Sheet").hang(raw, "found")
	tiles.append(small(await shot("strip_5")))
	steps.append(counted(study))
	await close(study)
	# 6: collage.gd as it is shipped.
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
		print("strip %-27s %d bodies, triangles with area %s, first: %d corners, %.3f m high; last: %.3f m high, lowest point %.3f m, middle %.3f m from its plate; plates %s; differs from the step before on %5.2f%% of the tile" % [
			names[i], steps[i]["bodies"], steps[i]["triangles"], steps[i]["first_corners"], steps[i]["first_height_m"], steps[i]["last_height_m"],
			steps[i]["last_lowest_point_m"], steps[i]["last_middle_from_its_plate_m"], steps[i]["plates"], steps[i]["differs_from_step_before_pct"]])
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
