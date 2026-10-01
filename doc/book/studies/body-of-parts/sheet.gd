extends SceneTree
## Renders the argument's sheet and the process strip. Needs a window, so run it
## WITHOUT --headless:
##   godot --path . --xr-mode off --script res://sheet.gd
## The sheet: the four values of `parenting`, each in three poses: at rest, with
## the root turned 30 degrees, and with every pivot turned 30 degrees. It writes
## stills/<name>.png and sheet.json, the measurements TUTORIAL.md quotes: where
## the parts are, which two values look most alike in each pose, and what a
## stretched root does. `above` is the study's own camera. `top` is a camera
## this script brings: it hangs over the body and looks straight down, so that a
## turn about the upright axis is seen as it is. From the top the study's own
## points, line and marble are hidden, and the light casts no shadow.
## The strip: one still after each operation of the body, from one fixed camera,
## composed left to right into process.png with the operation named under each.

const VALUES := ["flat", "a chain", "a chain with offset pivots", "two chains from one hip"]
const VIEWS := ["above", "top"]
const POSES := ["rest", "root", "pivots"]
const SMALL := Vector2i(320, 180)   # stills are measured at this size, saved at full size
const TILE := Vector2i(320, 240)    # one tile of the strip
const TOP_FROM := Vector3(0.4, 4.0, 1.0)
const STRIP_FROM := Vector3(0.4, 4.4, 4.45)
const STRIP_AT := Vector3(0.4, 0.3, 0.9)
const GUTTER := 4                   # pixels between two tiles
const TURN := 30.0                  # degrees
const WALK_MIDDLE := Vector3(1.2, 1.12, 0.45)
const STUDY_ONLY := ["A", "B", "Segment", "Strip", "Marble"]

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

## One study with the body built from one value of `parenting`; -1 leaves the
## body empty. Nothing moves by itself: this script sets the pose and the camera.
func open(value: int) -> Node3D:
	var study: Node3D = load("res://body.tscn").instantiate()
	var body: Node3D = study.get_node("Body")
	if value < 0:
		body.set_script(null)
	else:
		body.parenting = value
	root.add_child(study)
	body.set_process(false)
	await process_frame
	await process_frame
	study.set_process(false)
	study.get_node("Record").visible = false
	study.get_node("Readout").visible = false
	var top := Camera3D.new()
	top.name = "Top"
	top.projection = Camera3D.PROJECTION_ORTHOGONAL
	top.size = 4.6
	study.add_child(top)
	top.position = TOP_FROM
	top.rotation = Vector3(-PI / 2.0, 0.0, 0.0)
	var strip_camera := Camera3D.new()
	strip_camera.name = "StripCamera"
	strip_camera.fov = 30.0
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

func pose(body: Node3D, name: String) -> void:
	body.rotation.y = deg_to_rad(TURN) if name == "root" else 0.0
	for pivot: Node3D in body.pivots:
		pivot.rotation.y = deg_to_rad(TURN) if name == "pivots" else 0.0

func rounded(v: Vector3) -> Array:
	return [snappedf(v.x, 0.001), snappedf(v.y, 0.001), snappedf(v.z, 0.001)]

func part(body: Node3D, name: String) -> Node3D:
	return body.find_child(name, true, false)

func where(body: Node3D) -> Dictionary:
	return {
		"point": rounded(part(body, "Point").global_position),
		"plane_middle": rounded(part(body, "Plane").to_global(WALK_MIDDLE)),
		"cube": rounded(part(body, "Cube").global_position),
		"hip": rounded(part(body, "Limb").global_position),
		"toe": rounded(part(body, "Toe").global_position),
	}

func pairs(pose_name: String, view: String) -> void:
	var table := {}
	var closest := ""
	var closest_share := 1.0e9
	var farthest := ""
	var farthest_share := -1.0
	for i in VALUES.size():
		for j in range(i + 1, VALUES.size()):
			var share := differ_pct(stills["%d_%s_%s" % [i, pose_name, view]], stills["%d_%s_%s" % [j, pose_name, view]])
			var key := "%d vs %d" % [i, j]
			table[key] = share
			if share < closest_share:
				closest_share = share
				closest = key
			if share > farthest_share:
				farthest_share = share
				farthest = key
			print("%s, %s: %s differ on %5.2f%% of the frame" % [pose_name, view, key, share])
	report["pairs_%s_%s_pct" % [pose_name, view]] = table
	report["closest_pair_%s_%s" % [pose_name, view]] = closest
	report["farthest_pair_%s_%s" % [pose_name, view]] = farthest
	print("sheet: %s, %s: closest pair %s (%.2f%%); farthest %s (%.2f%%)" % [pose_name, view, closest, closest_share, farthest, farthest_share])

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://stills"))
	FileAccess.open("res://stills/.gdignore", FileAccess.WRITE)   # the editor then leaves the stills alone
	# The reference: the study with an empty body.
	var study := await open(-1)
	for view: String in VIEWS:
		look(study, view)
		await shot("empty_" + view)
	await close(study)
	# The four values in three poses.
	for v in VALUES.size():
		study = await open(v)
		var body: Node3D = study.get_node("Body")
		var entry := {"value": VALUES[v], "root_children": body.get_child_count(), "nodes_below_root": body.find_children("*", "", true, false).size()}
		for pose_name: String in POSES:
			pose(body, pose_name)
			entry[pose_name] = where(body)
			for view: String in VIEWS:
				look(study, view)
				var name := "%d_%s_%s" % [v, pose_name, view]
				await shot(name)
				entry["body_share_%s_%s_pct" % [pose_name, view]] = differ_pct(stills[name], stills["empty_" + view])
		report[str(v)] = entry
		print("%d %-27s root has %d children; pivots turned: toe at %s; body on %5.2f%% of the frame from above, %5.2f%% from the top" % [
			v, VALUES[v], entry["root_children"], entry["pivots"]["toe"], entry["body_share_pivots_above_pct"], entry["body_share_pivots_top_pct"]])
		await close(study)
	for pose_name: String in POSES:
		for view: String in VIEWS:
			pairs(pose_name, view)
	# Outside the axis. The root scaled: evenly, then along one direction, with every pivot turned.
	for case: Array in [["scaled_2", Vector3(2, 2, 2)], ["stretched_z", Vector3(1, 1, 2)]]:
		study = await open(0)
		var body: Node3D = study.get_node("Body")
		pose(body, "pivots")
		body.scale = case[1]
		var limb: Node3D = part(body, "Limb")
		var cube: Node3D = part(body, "Cube")
		look(study, "top")
		await shot(case[0] + "_top")
		report[case[0]] = {
			"scale": rounded(case[1]),
			"limb_x_to_z_degrees": snappedf(rad_to_deg(limb.global_basis.x.angle_to(limb.global_basis.z)), 0.01),
			"limb_x_length": snappedf(limb.global_basis.x.length(), 0.001),
			"limb_z_length": snappedf(limb.global_basis.z.length(), 0.001),
			"cube_x_to_z_degrees": snappedf(rad_to_deg(cube.global_basis.x.angle_to(cube.global_basis.z)), 0.01),
			"toe": rounded(part(body, "Toe").global_position),
			"differs_from_unscaled_pct": differ_pct(stills[case[0] + "_top"], stills["0_pivots_top"]),
		}
		print("root scaled %s, every pivot at 30 degrees: the limb's x and z axes stand at %.2f degrees, %.3f and %.3f long" % [
			case[1], report[case[0]]["limb_x_to_z_degrees"], report[case[0]]["limb_x_length"], report[case[0]]["limb_z_length"]])
		await close(study)
	await strip()
	report["godot"] = Engine.get_version_info().string
	report["renderer"] = RenderingServer.get_video_adapter_name()
	FileAccess.open("res://sheet.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	quit(0)

## One tile: the middle 4:3 of the window, at 320 x 240.
func tile(name: String) -> Image:
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var side := image.get_height() * TILE.x / TILE.y
	image = image.get_region(Rect2i((image.get_width() - side) / 2, 0, side, image.get_height()))
	image.resize(TILE.x, TILE.y, Image.INTERPOLATE_BILINEAR)
	image.save_png("res://stills/strip_" + name + ".png")
	return image

func instance_part(kind: String) -> Node3D:
	return load("res://parts/" + kind + "_part.tscn").instantiate()

## The process strip. Each step is one operation on the same body, done here as
## the lesson does it, and photographed. What each step claims is counted.
func strip() -> void:
	var study := await open(-1)
	look(study, "strip")
	var body: Node3D = study.get_node("Body")
	var names := ["1 point", "2 + plane", "3 + cube", "4 + limb", "5 pivots set", "6 a chain", "7 every pivot turned"]
	var tiles: Array[Image] = []
	var steps := []
	# 1 to 4: each part instanced under the root. The point, the cube and the limb
	# are given a position; the plane arrives where it was walked.
	var point := instance_part("point")
	body.add_child(point)
	point.position = Vector3(-0.8, 0.075, 0.0)
	tiles.append(await tile("1"))
	steps.append(counted(body))
	var plane := instance_part("plane")
	body.add_child(plane)
	tiles.append(await tile("2"))
	steps.append(counted(body))
	var cube := instance_part("cube")
	body.add_child(cube)
	cube.position = Vector3(0.55, 0.25, 0.0)
	tiles.append(await tile("3"))
	steps.append(counted(body))
	var limb := instance_part("limb")
	body.add_child(limb)
	limb.position = Vector3(0.55, 0.25, 0.25)
	tiles.append(await tile("4"))
	steps.append(counted(body))
	await close(study)
	# 5: the same four parts, each under an empty parent: the flat body of body.gd.
	study = await open(0)
	look(study, "strip")
	body = study.get_node("Body")
	tiles.append(await tile("5"))
	steps.append(counted(body))
	await close(study)
	# 6 and 7: re-parented into a chain, then every pivot turned.
	study = await open(1)
	look(study, "strip")
	body = study.get_node("Body")
	tiles.append(await tile("6"))
	steps.append(counted(body))
	pose(body, "pivots")
	tiles.append(await tile("7"))
	steps.append(counted(body))
	await close(study)
	var most := 0
	for i in names.size():
		steps[i]["step"] = names[i]
		steps[i]["differs_from_step_before_pct"] = differ_pct(tiles[i], tiles[i - 1]) if i > 0 else 0.0
		if steps[i]["differs_from_step_before_pct"] > steps[most]["differs_from_step_before_pct"]:
			most = i
		print("strip %-22s root children %d, nodes below the root %d; differs from the step before on %5.2f%% of the tile" % [
			names[i], steps[i]["root_children"], steps[i]["nodes_below_root"], steps[i]["differs_from_step_before_pct"]])
	report["strip"] = steps
	report["strip_step_that_changed_most"] = names[most]
	await compose(tiles, names)

func counted(body: Node3D) -> Dictionary:
	var result := {"root_children": body.get_child_count(), "nodes_below_root": body.find_children("*", "", true, false).size()}
	if part(body, "Plane") != null:
		result["plane_middle"] = rounded(part(body, "Plane").to_global(WALK_MIDDLE))
	if part(body, "Toe") != null:
		result["toe"] = rounded(part(body, "Toe").global_position)
	return result

## The tiles side by side with the operation's name under each, drawn in a
## viewport of its own and saved as process.png.
func compose(tiles: Array[Image], names: Array) -> void:
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
	image.save_png("res://process.png")
	report["process_png"] = {"width": image.get_width(), "height": image.get_height(), "bytes": FileAccess.get_file_as_bytes("res://process.png").size()}
	print("process.png: %d x %d, %d bytes" % [image.get_width(), image.get_height(), report["process_png"]["bytes"]])
	sheet.free()
