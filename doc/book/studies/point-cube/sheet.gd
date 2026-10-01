extends SceneTree
## Renders the argument's sheet: the four values of `draft`, each from three
## standpoints. Needs a window, so run it WITHOUT --headless:
##   godot --path . --xr-mode off --script res://sheet.gd
## Writes stills/<n>_<view>.png and sheet.json, the measurements TUTORIAL.md quotes:
## how much of the frame each cube covers, how much shadow it casts, which two
## values look most alike from each standpoint, and where a dropped marble ends.
## `above` is the study's own camera and `below` is Under. `behind` is a third
## camera this script brings: it stands on the far side of the cube and sees the
## two faces the others never face, the back and the right.
## The labels are hidden so that only the cube can differ.

const VALUES := ["my one face", "one-line draft", "three-line draft", "repaired"]
const VIEWS := ["above", "below", "behind"]
const SMALL := Vector2i(320, 180)   # stills are measured at this size, saved at full size
const BEHIND_FROM := Vector3(2.4, 2.2, -1.3)

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
	return image

func changed(p: Color, q: Color) -> bool:
	return absf(p.r - q.r) + absf(p.g - q.g) + absf(p.b - q.b) > 0.1

## A still against the empty still of the same view. Of the pixels that changed,
## the warm ones (more red than blue: the cube's orange) are the cube, and the
## ones that only became darker are its shadow.
func compare(still: Image, empty: Image) -> Dictionary:
	var warm := 0
	var darker := 0
	var luma := 0.0
	for y in SMALL.y:
		for x in SMALL.x:
			var p := still.get_pixel(x, y)
			var q := empty.get_pixel(x, y)
			if changed(p, q):
				if p.r - p.b > 0.15:
					warm += 1
					luma += p.get_luminance()
				elif p.get_luminance() < q.get_luminance():
					darker += 1
	var total := float(SMALL.x * SMALL.y)
	return {
		"cube_share_pct": snappedf(100.0 * warm / total, 0.01),
		"cube_brightness": snappedf(luma / maxf(warm, 1), 0.01),
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

## One study with the cube built from one value of `draft`. The study's own
## _process is stopped after two frames so that this script chooses the camera.
func open(value: int) -> Node3D:
	var study: Node3D = load("res://cube.tscn").instantiate()
	study.get_node("Cube").draft = value
	root.add_child(study)
	await process_frame
	await process_frame
	study.set_process(false)
	study.get_node("Record").visible = false
	study.get_node("Readout").visible = false
	var behind := Camera3D.new()
	behind.name = "Behind"
	behind.fov = 48.0
	study.add_child(behind)
	behind.look_at_from_position(BEHIND_FROM, study.get_node("Cube").position)
	return study

func look(study: Node3D, view: String) -> void:
	var camera := {"above": "Camera3D", "below": "Under", "behind": "Behind"}
	study.get_node(camera[view]).current = true

func close(study: Node3D) -> void:
	study.free()
	await process_frame

func drop_marble(study: Node3D, offset: Vector3) -> Vector3:
	var marble: RigidBody3D = study.get_node("Marble")
	marble.drop(study.get_node("Cube").position + offset)
	for i in 200:
		await physics_frame
		if i > 30 and marble.sleeping:
			break
	return marble.position

func rounded(v: Vector3) -> Array:
	return [snappedf(v.x, 0.001), snappedf(v.y, 0.001), snappedf(v.z, 0.001)]

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://stills"))
	FileAccess.open("res://stills/.gdignore", FileAccess.WRITE)   # the editor then leaves the stills alone
	# The reference: the study with no cube at all.
	var study := await open(3)
	study.get_node("Cube").visible = false
	for view in VIEWS:
		look(study, view)
		stills["empty_" + view] = await shot("empty_" + view)
	await close(study)
	# The four values, each from three standpoints, then the marble.
	for v in VALUES.size():
		study = await open(v)
		for view in VIEWS:
			look(study, view)
			var name := "%d_%s" % [v, view]
			stills[name] = await shot(name)
			var c := compare(stills[name], stills["empty_" + view])
			c["value"] = VALUES[v]
			c["view"] = view
			report[name] = c
			print("%d %-16s %-6s  cube %5.2f%% of the frame, brightness %.2f, shadow %5.2f%%" % [
				v, VALUES[v], view, c["cube_share_pct"], c["cube_brightness"], c["shadow_share_pct"]])
		var rest := await drop_marble(study, Vector3(0.1, 0.75, -0.1))
		report["marble_%d" % v] = {"value": VALUES[v], "rest": rounded(rest)}
		print("%d %-16s marble dropped over the top ends at y = %.3f" % [v, VALUES[v], rest.y])
		look(study, "above")
		await shot("%d_marble_above" % v)
		await close(study)
	# Pairs: which two look most alike, from each standpoint.
	for view in VIEWS:
		var pairs := {}
		var closest := ""
		var closest_share := 1.0e9
		for i in VALUES.size():
			for j in range(i + 1, VALUES.size()):
				var share := differ_pct(stills["%d_%s" % [i, view]], stills["%d_%s" % [j, view]])
				var key := "%d vs %d" % [i, j]
				pairs[key] = share
				if share < closest_share:
					closest_share = share
					closest = key
				print("%s: %s differ on %5.2f%% of the frame" % [view, key, share])
		report["pairs_%s_pct" % view] = pairs
		report["closest_pair_" + view] = closest
		print("sheet: closest pair from %s is %s (%.2f%% of the frame differs)" % [view, closest, closest_share])
	# Outside the axis. One face with the hall's triples: the same corners, the other order.
	study = await open(0)
	var cube: MeshInstance3D = study.get_node("Cube")
	cube.triangles = [[4, 5, 7], [5, 6, 7]]
	cube.build()
	for view in ["above", "behind"]:
		look(study, view)
		var name: String = "hall_face_" + view
		stills[name] = await shot(name)
		report[name] = compare(stills[name], stills["empty_" + view])
		print("one face in the hall's order, %s: cube %5.2f%% of the frame" % [view, report[name]["cube_share_pct"]])
	await close(study)
	# Outside the axis. The repaired cube with smooth normals: build() without set_smooth_group(-1).
	study = await open(3)
	cube = study.get_node("Cube")
	var smooth := SurfaceTool.new()
	smooth.begin(Mesh.PRIMITIVE_TRIANGLES)
	for triangle in cube.triangles:
		for index in triangle:
			smooth.add_vertex(cube.corners[index])
	smooth.generate_normals()
	cube.mesh = smooth.commit()
	look(study, "above")
	stills["smooth_above"] = await shot("smooth_above")
	report["smooth_vs_flat_above_pct"] = differ_pct(stills["smooth_above"], stills["3_above"])
	print("above: the repaired cube with smooth normals differs from flat on %5.2f%% of the frame" % report["smooth_vs_flat_above_pct"])
	# Outside the axis. The repaired cube with no normals at all.
	var bare := SurfaceTool.new()
	bare.begin(Mesh.PRIMITIVE_TRIANGLES)
	for triangle in cube.triangles:
		for index in triangle:
			bare.add_vertex(cube.corners[index])
	cube.mesh = bare.commit()
	stills["no_normals_above"] = await shot("no_normals_above")
	report["no_normals_vs_flat_above_pct"] = differ_pct(stills["no_normals_above"], stills["3_above"])
	print("above: the repaired cube with no normals differs from flat on %5.2f%% of the frame" % report["no_normals_vs_flat_above_pct"])
	await close(study)
	# Outside the axis. The repaired cube on a walked plane: a square around it, closed and filled.
	study = await open(3)
	var loop: Array[Vector3] = [Vector3(0.75, 1.12, 0.0), Vector3(1.95, 1.12, 0.0), Vector3(1.95, 1.12, 1.2), Vector3(0.75, 1.12, 1.2)]
	study.trace = loop
	study.closed = true
	study.recording = false
	study.build_face()
	study._process(0.0)   # one pass, so that the strip draws the closed outline
	for view in ["above", "below"]:
		look(study, view)
		var name: String = "on_plane_" + view
		stills[name] = await shot(name)
		report[name] = compare(stills[name], stills["empty_" + view])
		print("the repaired cube on a walked plane, %s: cube %5.2f%% of the frame" % [view, report[name]["cube_share_pct"]])
	await close(study)
	report["godot"] = Engine.get_version_info().string
	report["renderer"] = RenderingServer.get_video_adapter_name()
	FileAccess.open("res://sheet.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	quit(0)
