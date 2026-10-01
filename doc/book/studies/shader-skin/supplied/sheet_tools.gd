extends SceneTree
## Supplied still-maker. A kit's sheet.gd begins with this line
##   extends "res://supplied/sheet_tools.gd"
## and writes ONE function, run(). Do not write _initialize().
## It NEEDS A WINDOW. Headless draws no frames, so run it WITHOUT --headless:
##   godot --path . --xr-mode off --script res://sheet.gd
## Run headless it says so and exits 1. The window closes by itself when run()
## returns; 60 seconds without a new still and it closes too, with exit code 1.
## A script error in sheet.gd also gives exit code 1: the sheet is not whole.
## Contract (`await` every function marked (waits)):
##   stand(body)               (waits) the studio: the supplied base, and `body` alone in it
##   look(view, distance)      the eye `distance` m from the middle: "level" or "above"; no shadows
##   look_from(from, at)       the eye anywhere, looking at `at`; with shadows
##   shadows(on)               whether what stands in the studio casts a shadow
##   shot(name)                (waits) the still the window shows, cut to its middle 4:3
##   portrait(body, name)      (waits) [the still, the body's pixels] by a second, flat-coloured still
##   photograph(body, view, name)   (waits) stand, look and portrait in one call
##   differs(a, b), share(mask), differ_pct(a, b)   where and on how much two stills differ
##   compare(a, pixels_a, b, pixels_b)      differ, outline, inside and elsewhere, in percent of the still
##   compare_all(names, stills, pixels)     every pair, the closest and the farthest
##   small(still)              a tile of 320 x 240
##   compose(tiles, columns, names, path)   (waits) tiles in rows, named, as one PNG
##   strip(tiles, names, path)              (waits) one row, and how much each step changed
##   report                    a dictionary of your own; it becomes sheet.json when run() returns
## Stills go to stills/<name>.png (git and the editor leave that folder alone).
## Two stills differ at a pixel when its three channels together are more than
## 25 of 255 apart, a tenth of full scale: the threshold of every kit.

const Look := preload("res://supplied/look.gd")
const Verify := preload("res://supplied/verify_tools.gd")   # for its Catcher: what Godot logs
const TILE := Vector2i(320, 240)    # one tile of a sheet or a strip
const GUTTER := 4                   # pixels between two tiles
const BAND := 26                    # pixels of caption under the tiles
const FOV := 40.0                   # the eye's field of view, in degrees
const FLAT := Color(1.0, 0.0, 1.0)  # the one colour of the second still
const THRESHOLD := 25               # of 255, the three channels added

var report := {}
var studio: Node3D      # the supplied base, made by the first stand(): floor, sky, sun
var eye: Camera3D       # the camera of the stills
var subject: Node3D     # what stands in the studio now
var window := Vector2i.ZERO   # the size of the window's picture
var crop := Rect2i()          # the middle 4:3 of it: what a still is

var _last_sign := 0
var _finished := false
var _shadowless := false
var _catcher := Verify.Catcher.new()

func _initialize() -> void:
	if DisplayServer.get_name() == "headless":
		print("sheet.gd needs a window: run it without --headless. Headless draws no frames.")
		quit(1)
		return
	_catcher.watch = [(get_script() as Script).resource_path, "res://supplied/sheet_tools.gd"]
	OS.add_logger(_catcher)
	_begin.call_deferred()
	_give_up.call_deferred()

func _begin() -> void:
	await run()
	finish()

## The kit's own stills go here: write `func run() -> void:` in sheet.gd.
func run() -> void:
	pass

func _give_up() -> void:
	_last_sign = Time.get_ticks_msec()
	while Time.get_ticks_msec() - _last_sign < 60000:
		await process_frame
	print("sheet.gd did not run to its end: 60 seconds passed without a new still; it is waiting for something that does not come")
	_finished = true
	quit(1)

func finish() -> void:
	if _finished:
		return
	_finished = true
	report["still"] = {"width": crop.size.x, "height": crop.size.y, "fov": FOV, "differ_threshold_of_255": THRESHOLD}
	report["godot"] = Engine.get_version_info().string
	report["renderer"] = RenderingServer.get_video_adapter_name()
	var file := FileAccess.open("res://sheet.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	print("sheet.json written")
	OS.remove_logger(_catcher)
	var own := _catcher.copy(_catcher.own)
	if not own.is_empty():
		print("sheet.gd had a script error of its own; the rest of that function was skipped, so the sheet is not whole: ", own[0])
	quit(0 if own.is_empty() else 1)

## The studio with `body` alone in it, where its own position puts it (a body
## whose origin is at its feet stands on the floor). The body before it is
## freed. With `held` the body's own _process stops after two frames, so that
## two stills of it show one moment.
func stand(body: Node3D, held := true) -> void:
	if studio == null:
		studio = load("res://supplied/base.tscn").instantiate()
		root.add_child(studio)
		# The studio is plain: the flat sky, the white ambient light, no fill light and
		# a hard shadow edge. A still measures the body, not the look's filter.
		studio.get_node("Look/Sky").environment = Look.studio_environment()
		if studio.has_node("Look/Fill"):
			studio.get_node("Look/Fill").free()
		studio.get_node("Look/Sun").shadow_blur = 1.0
		eye = Camera3D.new()
		eye.name = "Eye"
		eye.fov = FOV
		studio.add_child(eye)
		look("level")
	if subject != null and is_instance_valid(subject):
		subject.free()
	subject = body
	if body != null:
		studio.add_child(body)
	await process_frame
	await process_frame
	if body != null and held:
		body.process_mode = Node.PROCESS_MODE_DISABLED
	shadows(not _shadowless)

## The eye `distance` metres from `middle`: "level" looks from the side, at the
## height of the middle; "above" looks straight down. The body casts no shadow,
## so that two stills differ only where the bodies do.
func look(view: String, distance := 2.0, middle := Vector3(0.0, 0.5, 0.0)) -> void:
	if view == "above":
		eye.look_at_from_position(middle + Vector3(0.0, distance, 0.0), middle, Vector3(0.0, 0.0, -1.0))
	else:
		eye.look_at_from_position(middle + Vector3(0.0, 0.0, distance), middle)
	eye.current = true
	shadows(false)

## The eye at `from`, looking at `at`: the standpoint of a strip. Shadows on.
func look_from(from: Vector3, at: Vector3) -> void:
	eye.look_at_from_position(from, at)
	eye.current = true
	shadows(true)

## Whether what stands in the studio now casts a shadow. The sun is left as
## it is: in Godot 4.6's Compatibility renderer a sun with its shadows off
## lights a face less than half as brightly, so the body is told not to cast
## one instead. What is added to the studio later is not touched.
func shadows(on: bool) -> void:
	_shadowless = not on
	if subject == null or not is_instance_valid(subject):
		return
	for part: GeometryInstance3D in parts(subject):
		if not part.has_meta("cast_before"):
			part.set_meta("cast_before", part.cast_shadow)
		part.cast_shadow = part.get_meta("cast_before") if on else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

## The still as the window shows it now, whatever is in the window, cut to the
## middle 4:3. With a name it is saved as stills/<name>.png.
func shot(name := "") -> Image:
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
		if not DirAccess.dir_exists_absolute("res://stills"):
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://stills"))
			FileAccess.open("res://stills/.gdignore", FileAccess.WRITE).close()   # the editor then leaves the stills alone
		image.save_png("res://stills/" + name + ".png")
	_last_sign = Time.get_ticks_msec()
	return image

func small(image: Image) -> Image:
	var tile: Image = image.duplicate()
	tile.resize(TILE.x, TILE.y, Image.INTERPOLATE_BILINEAR)
	return tile

## Everything of a body that is drawn: the body itself and all below it.
func parts(body: Node3D) -> Array:
	var out := body.find_children("*", "GeometryInstance3D", true, false)
	if body is GeometryInstance3D:
		out.push_front(body)
	return out

## The box of a body in the room, in metres.
func box_of(body: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for part: GeometryInstance3D in parts(body):
		var here: AABB = part.global_transform * part.get_aabb()
		box = here if first else box.merge(here)
		first = false
	return box

## One body, photographed twice: as the eye gets it, and with everything of it
## in one flat colour. Returns [the still, the body's pixels]: one byte for
## each pixel of the still, 1 where the body is.
func portrait(body: Node3D, name := "") -> Array:
	var still := await shot(name)
	var worn := []
	var flat := StandardMaterial3D.new()
	flat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flat.albedo_color = FLAT
	for part: GeometryInstance3D in parts(body):
		worn.append(part.material_override)
		part.material_override = flat
	var second := await shot("")
	var i := 0
	for part: GeometryInstance3D in parts(body):
		part.material_override = worn[i]
		i += 1
	var data := second.get_data()
	var pixels := PackedByteArray()
	pixels.resize(data.size() / 3)
	for k in pixels.size():
		if data[k * 3] > 200 and data[k * 3 + 1] < 60 and data[k * 3 + 2] > 200:
			pixels[k] = 1
	return [still, pixels]

## A body alone in the studio from one standpoint, as a PNG: stand(), look()
## and portrait() in one call. Returns what portrait() returns.
func photograph(body: Node3D, view: String, name: String, distance := 2.0) -> Array:
	await stand(body)
	look(view, distance)
	return await portrait(body, name)

## Where a still differs from another: one byte for each pixel, 1 where the
## three channels together are more than THRESHOLD apart.
func differs(a: Image, b: Image) -> PackedByteArray:
	var p := a.get_data()
	var q := b.get_data()
	var out := PackedByteArray()
	out.resize(p.size() / 3)
	for i in out.size():
		var k := i * 3
		if absi(p[k] - q[k]) + absi(p[k + 1] - q[k + 1]) + absi(p[k + 2] - q[k + 2]) > THRESHOLD:
			out[i] = 1
	return out

## How much of the still a list of pixels covers, in percent.
func share(pixels: PackedByteArray) -> float:
	return snappedf(100.0 * pixels.count(1) / float(pixels.size()), 0.01)

## On how much of the still two stills differ, in percent.
func differ_pct(a: Image, b: Image) -> float:
	return share(differs(a, b))

## Two bodies compared: on how much of the still they differ, how much of that
## is outline (one body is there and the other is not), how much inside (both
## are there, in another colour) and how much elsewhere (neither is there: a
## shadow, a reflection). `outline_px` is the outline as a band: its pixels
## divided by the length of the larger body's edge, taken as a circle.
func compare(a: Image, pixels_a: PackedByteArray, b: Image, pixels_b: PackedByteArray) -> Dictionary:
	var d := differs(a, b)
	var differ := 0
	var rim := 0
	var inside := 0
	for i in d.size():
		if pixels_a[i] != pixels_b[i]:
			rim += 1
			differ += 1
		elif d[i] == 1:
			differ += 1
			if pixels_a[i] == 1:
				inside += 1
	var total := float(d.size())
	var radius := sqrt(maxi(maxi(pixels_a.count(1), pixels_b.count(1)), 1) / PI)
	return {
		"differ_pct": snappedf(100.0 * differ / total, 0.01), "outline_pct": snappedf(100.0 * rim / total, 0.01),
		"inside_pct": snappedf(100.0 * inside / total, 0.01), "elsewhere_pct": snappedf(100.0 * (differ - rim - inside) / total, 0.01),
		"outline_px": snappedf(rim / (TAU * radius), 0.01),
	}

## Every pair of a sheet's values. `names`, `stills` and `pixels` are three
## lists in the same order. Returns {"pairs": {"a vs b": compare(), ...},
## "closest": "a vs b", "farthest": "c vs d"}, by differ_pct.
func compare_all(names: Array, stills: Array, pixels: Array) -> Dictionary:
	var pairs := {}
	var closest := ""
	var farthest := ""
	for i in names.size():
		for j in range(i + 1, names.size()):
			var key := "%s vs %s" % [names[i], names[j]]
			pairs[key] = compare(stills[i], pixels[i], stills[j], pixels[j])
			if closest == "" or pairs[key]["differ_pct"] < pairs[closest]["differ_pct"]:
				closest = key
			if farthest == "" or pairs[key]["differ_pct"] > pairs[farthest]["differ_pct"]:
				farthest = key
			print("%s differ on %5.2f%% of the still: %5.2f%% outline (a band of %.2f pixels), %5.2f%% inside" % [key, pairs[key]["differ_pct"], pairs[key]["outline_pct"], pairs[key]["outline_px"], pairs[key]["inside_pct"]])
	return {"pairs": pairs, "closest": closest, "farthest": farthest}

## Tiles in rows of `columns`, as one image at `path`. `names` holds one
## caption for each column (written once, under the last row) or one for each
## tile (written under every tile), in INK on SHADE. A tile is a small() still:
## its background is the scene's own. Returns the image's width, height and bytes.
func compose(tiles: Array[Image], columns: int, names: Array, path: String) -> Dictionary:
	var rows := ceili(tiles.size() / float(columns))
	var each := names.size() == tiles.size() and rows > 1   # a caption under every tile
	var row_height := TILE.y + GUTTER + (BAND if each else 0)
	var sheet := SubViewport.new()
	sheet.size = Vector2i(TILE.x * columns + GUTTER * (columns - 1), row_height * rows - GUTTER + (0 if each else BAND))
	sheet.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sheet)
	var ground := ColorRect.new()
	ground.color = Look.SHADE
	ground.size = sheet.size
	sheet.add_child(ground)
	for i in tiles.size():
		var picture := TextureRect.new()
		picture.texture = ImageTexture.create_from_image(tiles[i])
		picture.position = Vector2((TILE.x + GUTTER) * (i % columns), row_height * (i / columns))
		sheet.add_child(picture)
	for i in names.size():
		var label := Label.new()
		label.text = str(names[i])
		var row := (i / columns) if each else (rows - 1)
		label.position = Vector2((TILE.x + GUTTER) * (i % columns), row_height * row + TILE.y)
		label.size = Vector2(TILE.x, BAND)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 15)
		label.add_theme_color_override("font_color", Look.INK)
		sheet.add_child(label)
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = sheet.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	image.save_png(path)
	sheet.free()
	_last_sign = Time.get_ticks_msec()
	var result := {"width": image.get_width(), "height": image.get_height(), "bytes": FileAccess.get_file_as_bytes(path).size()}
	print("%s: %d x %d, %d bytes" % [path.get_file(), result["width"], result["height"], result["bytes"]])
	return result

## The process strip: `tiles` left to right in one row, each named, as one
## image at `path`. Returns {"steps": [{"step": name, "differs_from_step_before_pct": n}, ...],
## "changed_most": the name of the step that differs most from the one before, "png": compose()}.
func strip(tiles: Array[Image], names: Array, path := "res://process.png") -> Dictionary:
	var steps := []
	var most := mini(1, tiles.size() - 1)
	for i in tiles.size():
		var changed := share(differs(tiles[i], tiles[i - 1])) if i > 0 else 0.0
		steps.append({"step": str(names[i]), "differs_from_step_before_pct": changed})
		if i > 0 and changed > steps[most]["differs_from_step_before_pct"]:
			most = i
		print("strip %-28s differs from the step before on %5.2f%% of the tile" % [names[i], changed])
	var png := await compose(tiles, tiles.size(), names, path)
	return {"steps": steps, "changed_most": str(names[most]), "png": png}
