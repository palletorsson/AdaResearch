extends SceneTree
## Renders the argument's sheet: the four values of `side`, each from above and
## from below, on one fixed walk. Needs a window, so run it WITHOUT --headless:
##   godot --path . --xr-mode off --script res://sheet.gd
## Writes stills/<n>_<view>.png and sheet.json, the measurements TUTORIAL.md quotes:
## how much of the frame each face covers, how bright it is, how much shadow it casts,
## and which two values look most alike from above. The labels are hidden so that
## only the face can differ.

const VALUES := ["clockwise", "clockwise flipped normals", "counter-clockwise", "counter-clockwise double-sided"]
const SMALL := Vector2i(320, 180)   # stills are measured at this size, saved at full size

var report := {}

func _initialize() -> void: run.call_deferred()

## The same walk as verify.gd: twelve kept positions, clockwise as seen from above.
func walk() -> Array[Vector3]:
	var centre := Vector3(0.15, 1.12, 0.5)
	var points: Array[Vector3] = []
	for k in 12:
		var t := -k * TAU / 12.0
		points.append(centre + Vector3(1.1 * cos(t), 0.0, -0.75 * sin(t)))
	return points

func shot(name: String) -> Image:
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	image.save_png("res://stills/" + name + ".png")
	image.resize(SMALL.x, SMALL.y, Image.INTERPOLATE_BILINEAR)
	return image

func changed(p: Color, q: Color) -> bool:
	return absf(p.r - q.r) + absf(p.g - q.g) + absf(p.b - q.b) > 0.1

## A still against the outline-only still of the same view. Pixels that became
## brighter are the face; pixels that became darker are its shadow.
func compare(still: Image, outline: Image) -> Dictionary:
	var brighter := 0
	var darker := 0
	var luma := 0.0
	for y in SMALL.y:
		for x in SMALL.x:
			var p := still.get_pixel(x, y)
			var q := outline.get_pixel(x, y)
			if changed(p, q):
				if p.get_luminance() > q.get_luminance():
					brighter += 1
					luma += p.get_luminance()
				else:
					darker += 1
	var total := float(SMALL.x * SMALL.y)
	return {
		"face_share_pct": snappedf(100.0 * brighter / total, 0.01),
		"face_brightness": snappedf(luma / maxf(brighter, 1), 0.01),
		"shadow_share_pct": snappedf(100.0 * darker / total, 0.01),
	}

## The share of the frame on which two stills differ.
func differ_pct(a: Image, b: Image) -> float:
	var count := 0
	for y in SMALL.y:
		for x in SMALL.x:
			if changed(a.get_pixel(x, y), b.get_pixel(x, y)):
				count += 1
	return snappedf(100.0 * count / float(SMALL.x * SMALL.y), 0.01)

func look(from_below: bool) -> void:
	if from_below:
		Input.action_press("look")
	else:
		Input.action_release("look")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://stills"))
	FileAccess.open("res://stills/.gdignore", FileAccess.WRITE)   # the editor then leaves the stills alone
	var study: Node3D = load("res://plane.tscn").instantiate()
	root.add_child(study)
	await process_frame
	study.get_node("Record").visible = false
	study.get_node("Readout").visible = false
	study.trace = walk()
	study.closed = true
	study.recording = false
	var views := {"above": false, "below": true}
	var stills := {}
	# The reference: the closed outline, no face.
	for view in views:
		look(views[view])
		stills["outline_" + view] = await shot("outline_" + view)
	# The four values.
	for v in VALUES.size():
		study.side = v
		study.build_face()
		for view in views:
			look(views[view])
			var name := "%d_%s" % [v, view]
			stills[name] = await shot(name)
			var c := compare(stills[name], stills["outline_" + view])
			c["value"] = VALUES[v]
			c["view"] = view
			report[name] = c
			print("%d %-31s %-5s  face %5.2f%% of the frame, brightness %.2f, shadow %5.2f%%" % [
				v, VALUES[v], view, c["face_share_pct"], c["face_brightness"], c["shadow_share_pct"]])
	look(false)
	# Pairs from above: which two look most alike.
	var pairs := {}
	var closest := ""
	var closest_share := 1.0e9
	for i in VALUES.size():
		for j in range(i + 1, VALUES.size()):
			var share := differ_pct(stills["%d_above" % i], stills["%d_above" % j])
			var key := "%d vs %d" % [i, j]
			pairs[key] = share
			if share < closest_share:
				closest_share = share
				closest = key
			print("above: %s differ on %5.2f%% of the frame" % [key, share])
	report["pairs_above_pct"] = pairs
	report["closest_pair_above"] = closest
	# Outside the axis: the same clockwise fan with no normals at all.
	var bare := SurfaceTool.new()
	bare.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points := walk()
	for i in range(1, points.size() - 1):
		bare.add_vertex(points[0])
		bare.add_vertex(points[i])
		bare.add_vertex(points[i + 1])
	study.side = 0
	study.build_face()
	study.get_node("Face").mesh = bare.commit()
	stills["no_normals_above"] = await shot("no_normals_above")
	report["no_normals_vs_clockwise_above_pct"] = differ_pct(stills["no_normals_above"], stills["0_above"])
	print("above: a clockwise face with no normals differs from side 0 on %5.2f%% of the frame" % report["no_normals_vs_clockwise_above_pct"])
	# The marble on the counter-clockwise face: a body resting on a face the eye cannot see.
	study.side = 2
	study.build_face()
	study.get_node("Marble").drop(Vector3(0.15, 2.12, 0.5))
	for i in 150:
		await physics_frame
	report["marble_on_counter_clockwise"] = {"rest_y": snappedf(study.get_node("Marble").position.y, 0.001)}
	await shot("marble_on_2_above")
	print("marble on the counter-clockwise face rests at y = %.3f" % study.get_node("Marble").position.y)
	report["godot"] = Engine.get_version_info().string
	report["walk_points"] = walk().size()
	FileAccess.open("res://sheet.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("sheet: closest pair from above is ", closest, " (", closest_share, "% of the frame differs)")
	quit(0)
