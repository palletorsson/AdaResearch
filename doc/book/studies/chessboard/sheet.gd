extends SceneTree
## Renders the argument's sheet and the process strip. Needs a window, so run it
## WITHOUT --headless:
##   godot --path . --xr-mode off --script res://sheet.gd
## The sheet: the four values of `rhythm` over the same 8 x 8 cubes, each from
## two cameras. `above` is the study's own camera, 5.9 m from the middle of the
## floor. `top` is a camera this script brings: it hangs over the floor and looks
## straight down, the study's own points, line and marble are hidden, and the
## light casts no shadow. It writes stills/<name>.png, sheet.png (the four from
## above, side by side, named) and sheet.json, the measurements TUTORIAL.md
## quotes: on how much of the frame two values differ cell by cell, how far
## apart their average colours are, and what the floor costs to draw.
## The strip: one still after each operation of the floor, from one fixed camera,
## composed left to right into process.png with the operation named under each.

const VALUES := ["every cell alike", "(x + z) % 2 chessboard", "x % 3 stripes", "hue from x + z"]
const VIEWS := ["above", "top"]
const SMALL := Vector2i(320, 180)   # stills are measured at this size, saved at full size
const TILE := Vector2i(320, 240)    # one tile of the strip
const TOP_FROM := Vector3(0.0, 6.0, -0.25)
const STRIP_FROM := Vector3(0.35, 6.6, 5.8)
const STRIP_AT := Vector3(0.35, 0.25, -0.35)
const GUTTER := 4                   # pixels between two tiles
const STUDY_ONLY := ["A", "B", "Segment", "Strip", "Marble"]
const GHOST := [5, 5]
const OPENED := 0.6                 # the spacing of the strip's last tile

var report := {}
var stills := {}

func _initialize() -> void: run.call_deferred()

func shot(name: String) -> Image:
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	image.save_png("res://stills/" + name + ".png")
	image.resize(SMALL.x, SMALL.y, Image.INTERPOLATE_BILINEAR)
	stills[name] = image
	return image

func changed(p: Color, q: Color) -> bool:
	return absf(p.r - q.r) + absf(p.g - q.g) + absf(p.b - q.b) > 0.1

## The share of the frame on which two stills differ.
func differ_pct(a: Image, b: Image) -> float:
	var count := 0
	for y in a.get_height():
		for x in a.get_width():
			if changed(a.get_pixel(x, y), b.get_pixel(x, y)):
				count += 1
	return snappedf(100.0 * count / float(a.get_width() * a.get_height()), 0.01)

## The average colour of a still: what is left of it from very far away.
func tone(image: Image) -> Color:
	var sum := Vector3.ZERO
	for y in image.get_height():
		for x in image.get_width():
			var p := image.get_pixel(x, y)
			sum += Vector3(p.r, p.g, p.b)
	sum /= float(image.get_width() * image.get_height())
	return Color(sum.x, sum.y, sum.z)

## How far apart two average colours are, in 255ths, summed over red, green and blue.
func tone_apart(a: Image, b: Image) -> float:
	var p := tone(a)
	var q := tone(b)
	return snappedf(255.0 * (absf(p.r - q.r) + absf(p.g - q.g) + absf(p.b - q.b)), 0.01)

## One study. `setup` is a dictionary of the board's variables to set before it
## is built; an empty one leaves the finished chessboard.gd as it is; null takes
## the script off the board, so that this script can build on it by hand.
func open(setup: Variant) -> Node3D:
	var study: Node3D = load("res://chessboard.tscn").instantiate()
	var board: Node3D = study.get_node("Chessboard")
	if setup == null:
		board.set_script(null)
	else:
		for key: String in setup:
			board.set(key, setup[key])
	root.add_child(study)
	await process_frame
	await process_frame
	study.set_process(false)
	study.get_node("Record").visible = false
	study.get_node("Readout").visible = false
	var top := Camera3D.new()
	top.name = "Top"
	top.projection = Camera3D.PROJECTION_ORTHOGONAL
	top.size = 4.8
	study.add_child(top)
	top.position = TOP_FROM
	top.rotation = Vector3(-PI / 2.0, 0.0, 0.0)
	var strip_camera := Camera3D.new()
	strip_camera.name = "StripCamera"
	strip_camera.fov = 36.0
	study.add_child(strip_camera)
	strip_camera.look_at_from_position(STRIP_FROM, STRIP_AT)
	return study

func look(study: Node3D, view: String) -> void:
	var camera := {"above": "Camera3D", "top": "Top", "strip": "StripCamera"}
	study.get_node(camera[view]).current = true
	study.get_node("DirectionalLight3D").shadow_enabled = view != "top"
	for path: String in STUDY_ONLY:
		study.get_node(path).visible = view == "above"

func close(study: Node3D) -> void:
	study.free()
	await process_frame

func pairs(view: String) -> void:
	var cells := {}
	var tones := {}
	var closest := ""
	var farthest := ""
	var closest_tone := ""
	for i in VALUES.size():
		for j in range(i + 1, VALUES.size()):
			var key := "%d vs %d" % [i, j]
			cells[key] = differ_pct(stills["%d_%s" % [i, view]], stills["%d_%s" % [j, view]])
			tones[key] = tone_apart(stills["%d_%s" % [i, view]], stills["%d_%s" % [j, view]])
			if closest == "" or cells[key] < cells[closest]:
				closest = key
			if farthest == "" or cells[key] > cells[farthest]:
				farthest = key
			if closest_tone == "" or tones[key] < tones[closest_tone]:
				closest_tone = key
			print("%s: %s differ on %5.2f%% of the frame; their average colours are %6.2f apart" % [view, key, cells[key], tones[key]])
	report["pairs_%s_pct" % view] = cells
	report["tones_apart_%s" % view] = tones
	report["closest_pair_%s" % view] = closest
	report["farthest_pair_%s" % view] = farthest
	report["closest_tone_%s" % view] = closest_tone
	print("sheet: %s: cell by cell the closest pair is %s (%.2f%%), the farthest %s (%.2f%%); by average colour the closest is %s (%.2f)" % [
		view, closest, cells[closest], farthest, cells[farthest], closest_tone, tones[closest_tone]])

## What the renderer reports for the frame just drawn.
func drawn() -> Dictionary:
	return {
		"draw_calls": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		"objects": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
	}

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://stills"))
	FileAccess.open("res://stills/.gdignore", FileAccess.WRITE)   # the editor then leaves the stills alone
	# The reference: the study with an empty board.
	var study := await open(null)
	for view: String in VIEWS:
		look(study, view)
		await shot("empty_" + view)
		report["empty_" + view] = drawn()
	look(study, "strip")
	await tile("strip_0")
	report["empty"] = drawn()
	await close(study)
	# The four values of `rhythm`.
	var above: Array[Image] = []
	for v in VALUES.size():
		study = await open({"rhythm": v})
		var board: Node3D = study.get_node("Chessboard")
		var entry := {"value": VALUES[v], "cubes": board.cubes.size(), "materials": board.count_materials(), "colours": colours(board).size()}
		for view: String in VIEWS:
			look(study, view)
			var name := "%d_%s" % [v, view]
			await shot(name)
			entry["floor_share_%s_pct" % view] = differ_pct(stills[name], stills["empty_" + view])
			var average := tone(stills[name])
			entry["tone_%s" % view] = [snappedf(average.r, 0.001), snappedf(average.g, 0.001), snappedf(average.b, 0.001)]
			entry["drawn_%s" % view] = drawn()
		if v == 3:
			entry["bands_top"] = bands(study, stills["3_top"])
		look(study, "above")
		above.append(await tile("sheet_%d" % v))
		report[str(v)] = entry
		print("%d %-24s %d cubes, %d materials, %d colours; the floor is on %5.2f%% of the frame from above, %5.2f%% from the top; %d draw calls from above, %d from the top" % [
			v, VALUES[v], entry["cubes"], entry["materials"], entry["colours"], entry["floor_share_above_pct"], entry["floor_share_top_pct"], entry["drawn_above"]["draw_calls"], entry["drawn_top"]["draw_calls"]])
		await close(study)
	for view: String in VIEWS:
		pairs(view)
	report["sheet_png"] = await compose(above, ["0 every cell alike", "1 (x + z) % 2 chessboard", "2 x % 3 stripes", "3 hue from x + z"], "res://sheet.png")
	await strip()
	report["godot"] = Engine.get_version_info().string
	report["renderer"] = RenderingServer.get_video_adapter_name()
	FileAccess.open("res://sheet.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	quit(0)

## The hue ramp as the screen shows it: the colour at the middle of one cell of
## each of the 15 bands, from the top, and how far each band is from the next,
## in 255ths summed over red, green and blue.
func bands(study: Node3D, still: Image) -> Dictionary:
	var board: Node3D = study.get_node("Chessboard")
	var top: Camera3D = study.get_node("Top")
	var window := Vector2(root.size)
	var seen: Array[Color] = []
	for k in 15:
		var x := mini(k, 7)
		var z := k - x
		var at := top.unproject_position(board.to_global(Vector3(x * board.spacing, 0.5, z * board.spacing)))
		seen.append(still.get_pixel(int(at.x * SMALL.x / window.x), int(at.y * SMALL.y / window.y)))
	var steps := []
	for k in 14:
		steps.append(snappedf(255.0 * (absf(seen[k].r - seen[k + 1].r) + absf(seen[k].g - seen[k + 1].g) + absf(seen[k].b - seen[k + 1].b)), 0.1))
	var smallest: int = steps.find(steps.min())
	var largest: int = steps.find(steps.max())
	print("hue ramp on the screen: the step from band %d to %d is the smallest (%.1f), from band %d to %d the largest (%.1f)" % [smallest, smallest + 1, steps[smallest], largest, largest + 1, steps[largest]])
	return {
		"colours": seen.map(func(c: Color): return [snappedf(c.r, 0.001), snappedf(c.g, 0.001), snappedf(c.b, 0.001)]),
		"step_to_next": steps, "smallest_step_from_band": smallest, "largest_step_from_band": largest,
	}

## The colours on the floor, each once.
func colours(board: Node3D) -> Array:
	var seen := []
	for cube: MeshInstance3D in board.get_children():
		var colour: Color = cube.material_override.albedo_color
		if not seen.has(colour):
			seen.append(colour)
	return seen

## One tile: the middle 4:3 of the window, at 320 x 240.
func tile(name: String) -> Image:
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var side := image.get_height() * TILE.x / TILE.y
	image = image.get_region(Rect2i((image.get_width() - side) / 2, 0, side, image.get_height()))
	image.resize(TILE.x, TILE.y, Image.INTERPOLATE_BILINEAR)
	image.save_png("res://stills/" + name + ".png")
	return image

## What a step of the strip claims, counted on the board.
func counted(board: Node3D) -> Dictionary:
	var materials := []
	var enabled := 0
	var far := Vector3.ZERO
	for cube: MeshInstance3D in board.get_children():
		if not materials.has(cube.material_override):
			materials.append(cube.material_override)
		if not cube.get_node("Body/CollisionShape3D").disabled:
			enabled += 1
		far = far.max(cube.position)
	return {
		"cubes": board.get_child_count(),
		"nodes_below_board": board.find_children("*", "", true, false).size(),
		"materials": materials.size(),
		"colours": colours(board).size(),
		"colliders": enabled,
		"far_corner": [snappedf(far.x, 0.001), snappedf(far.z, 0.001)],
	}

## The process strip. Each step is one operation on the same floor, done here as
## the lesson does it, and photographed. What each step claims is counted.
func strip() -> void:
	var names := ["1 one cube", "2 a row", "3 the floor", "4 two colours", "5 hue by index", "6 a ghost cell", "7 spacing opened"]
	var tiles: Array[Image] = []
	var steps := []
	# 1 to 3: the cube part instanced once, eight times, and eight times eight, by
	# hand, as the lesson first does it. No material is made: the part brings its own.
	var study := await open(null)
	look(study, "strip")
	var board: Node3D = study.get_node("Chessboard")
	var scene: PackedScene = load("res://parts/cube_part.tscn")
	for z in range(8):
		for x in range(8):
			if z == 0 and x == 1:
				tiles.append(await tile("strip_1"))
				steps.append(counted(board).merged(drawn()))
			if z == 1 and x == 0:
				tiles.append(await tile("strip_2"))
				steps.append(counted(board).merged(drawn()))
			var cube: Node3D = scene.instantiate()
			board.add_child(cube)
			cube.position = Vector3(x * 0.5, 0.25, z * 0.5)
	tiles.append(await tile("strip_3"))
	steps.append(counted(board).merged(drawn()))
	await close(study)
	# 4 to 7: chessboard.gd, with one thing changed at each step.
	var setups := [
		{"rhythm": 1, "ghost_x": -1},
		{"rhythm": 3, "ghost_x": -1},
		{"rhythm": 3, "ghost_x": GHOST[0], "ghost_z": GHOST[1]},
		{"rhythm": 3, "ghost_x": GHOST[0], "ghost_z": GHOST[1], "spacing": OPENED},
	]
	for i in setups.size():
		study = await open(setups[i])
		look(study, "strip")
		tiles.append(await tile("strip_%d" % (i + 4)))
		steps.append(counted(study.get_node("Chessboard")).merged(drawn()))
		await close(study)
	var most := 0
	for i in names.size():
		steps[i]["step"] = names[i]
		steps[i]["differs_from_step_before_pct"] = differ_pct(tiles[i], tiles[i - 1]) if i > 0 else 0.0
		if steps[i]["differs_from_step_before_pct"] > steps[most]["differs_from_step_before_pct"]:
			most = i
		print("strip %-17s %2d cubes, %3d nodes, %2d materials, %2d colours, %2d colliders, far corner at %s, %3d draw calls; differs from the step before on %5.2f%% of the tile" % [
			names[i], steps[i]["cubes"], steps[i]["nodes_below_board"], steps[i]["materials"], steps[i]["colours"], steps[i]["colliders"],
			steps[i]["far_corner"], steps[i]["draw_calls"], steps[i]["differs_from_step_before_pct"]])
	report["strip"] = steps
	report["strip_step_that_changed_most"] = names[most]
	report["process_png"] = await compose(tiles, names, "res://process.png")

## Tiles side by side with a name under each, drawn in a viewport of its own
## and saved as one image.
func compose(tiles: Array[Image], names: Array, path: String) -> Dictionary:
	var band := 26
	var sheet := SubViewport.new()
	sheet.size = Vector2i(TILE.x * tiles.size() + GUTTER * (tiles.size() - 1), TILE.y + band)
	sheet.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sheet)
	var ground := ColorRect.new()
	ground.color = Color(0.08, 0.09, 0.11)
	ground.size = sheet.size
	sheet.add_child(ground)
	for i in tiles.size():
		var picture := TextureRect.new()
		picture.texture = ImageTexture.create_from_image(tiles[i])
		picture.position = Vector2((TILE.x + GUTTER) * i, 0)
		sheet.add_child(picture)
		var label := Label.new()
		label.text = names[i]
		label.position = Vector2((TILE.x + GUTTER) * i, TILE.y)
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
