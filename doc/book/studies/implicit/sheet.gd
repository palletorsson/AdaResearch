extends "res://supplied/sheet_tools.gd"
## The stills and the measures of the Implicit study. It needs a window, so run
## it WITHOUT --headless, from this folder:
##   godot --path . --xr-mode off --script res://sheet.gd
## It writes
##   sheet.png    one field at the thresholds 0.2, 0.4, 0.6 and 0.8, each body
##                alone in the studio, seen level from the front: the upper row
##                on the grid of 40 cells, the lower row on a grid of 10
##   process.png  the strip: one still after each operation, from one standpoint
##   sheet.json   every pair of each row compared, the closest and the farthest
##                pair, what each still holds (pieces, triangles, how much of the
##                still it covers), how much each step of the strip changed, and
##                the longest frame while the body was built in the running
##                scene, on the main thread and on a worker, at 40 and at 80 cells
## and the single stills, in stills/.

const Pieces := preload("res://pieces.gd")
const VALUES := [0.2, 0.4, 0.6, 0.8]      # the axis: the threshold
const GRIDS := [40, 10]                   # cells along one side: the kit's, and a coarse one
const MIDDLE := Vector3(0.0, 2.0, 0.0)    # what the eye looks at
const DISTANCE := 6.5                     # metres from the eye to the middle

func run() -> void:
	await frames_measured()
	await sheet()
	await process_strip()

## A body with field_body.gd on it and `settings` set, not yet in a scene.
func new_body(settings: Dictionary) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	body.set_script(load("res://field_body.gd"))
	for key: String in settings:
		body.set(key, settings[key])
	return body

## Wait until `body` wears the skin of its last rebuild().
func skin_on(body: MeshInstance3D) -> void:
	for i in 2:
		await process_frame
	while body.task != -1 or body.mesh == null:
		await process_frame

func points_of(body: MeshInstance3D) -> PackedVector3Array:
	if body.mesh == null or body.mesh.get_surface_count() == 0:
		return PackedVector3Array()
	return body.mesh.get_faces()

## The comparison sheet: every threshold on both grids, every pair of a row measured.
func sheet() -> void:
	var tiles: Array[Image] = []
	var captions := []
	report["stills"] = {}
	for cells: int in GRIDS:
		var names := []
		var stills := []
		var pixels := []
		for level: float in VALUES:
			var body := new_body({"threshold": level, "cells": cells})
			await stand(body)
			await skin_on(body)
			look("level", DISTANCE, MIDDLE)
			var name := "threshold_%.1f_cells_%d" % [level, cells]
			var taken: Array = await portrait(body, name)
			var points := points_of(body)
			names.append("%.1f" % level)
			stills.append(taken[0])
			pixels.append(taken[1])
			tiles.append(small(taken[0]))
			captions.append("threshold %.1f, %d cells: %d %s" % [level, cells, body.pieces, "body" if body.pieces == 1 else "bodies"])
			report["stills"][name] = {"pieces": body.pieces, "triangles_of_each": Pieces.sizes(points), "triangles": points.size() / 3,
				"covers_pct_of_the_still": share(taken[1]), "build_ms": snappedf(body.cost, 0.1)}
			print("%s: %d pieces, %d triangles, covers %.2f%% of the still" % [name, body.pieces, points.size() / 3, share(taken[1])])
		report["pairs_cells_%d" % cells] = compare_all(names, stills, pixels)
	report["sheet_png"] = await compose(tiles, VALUES.size(), captions, "res://sheet.png")
	report["eye"] = {"view": "level", "distance_m": DISTANCE, "looks_at": [MIDDLE.x, MIDDLE.y, MIDDLE.z]}

## The process strip: the body after each operation, from one standpoint.
func process_strip() -> void:
	var names := ["1 three sources, 10 cells", "2 a grid of 40 cells", "3 noise in the field", "4 the threshold falls to 0.4", "5 two holes carved", "6 a walker stands in it"]
	var tiles: Array[Image] = []
	var counts := []
	var group := Node3D.new()
	await stand(group, false)
	look_from(Vector3(2.4, 2.3, 7.4), Vector3(0.0, 1.8, 0.0))
	var body := new_body({"threshold": 0.6, "cells": 10, "wobble": 0.0})
	group.add_child(body)
	for step in 6:
		match step:
			1:
				body.cells = 40
				body.rebuild()
			2:
				body.wobble = 0.08
				body.rebuild()
			3:
				body.threshold = 0.4
				body.rebuild()
			4:
				# the two places the walker carved in verify.gd, 0.6 m ahead of where the skin stopped it
				body.carve(Vector3(0.03, 0.0, 0.11))
				await skin_on(body)
				body.carve(Vector3(0.02, 0.0, -0.79))
			5:
				var walker: CharacterBody3D = load("res://supplied/walker.tscn").instantiate()
				walker.position = Vector3(0.0, 0.0, 0.0)   # before add_child: a body is in the room from the step it is added
				walker.keys = false
				group.add_child(walker)
		await skin_on(body)
		shadows(true)   # the new skin casts a shadow too
		tiles.append(small(await shot("strip_%d" % (step + 1))))
		counts.append({"step": names[step], "pieces": body.pieces, "triangles": points_of(body).size() / 3})
	report["strip"] = await strip(tiles, names)
	report["strip"]["bodies_and_triangles"] = counts

## The running scene: how long is the longest frame while the body is built?
func frames_measured() -> void:
	var out := {}
	for cells: int in [40, 80]:
		var scene: Node3D = load("res://implicit.tscn").instantiate()
		var body: MeshInstance3D = scene.get_node("Body")
		body.cells = cells
		root.add_child(scene)
		await skin_on(body)
		for i in 30:
			await process_frame
		var usual := []
		var before := Time.get_ticks_usec()
		for i in 120:
			await process_frame
			var now := Time.get_ticks_usec()
			usual.append((now - before) / 1000.0)
			before = now
		usual.sort()
		var row := {"usual_frame_ms": snappedf(usual[60], 0.01), "longest_of_120_usual_frames_ms": snappedf(usual[119], 0.01), "main": [], "worker": [], "build_ms_main": [], "build_ms_worker": [], "triangles": points_of(body).size() / 3}
		for turn in 3:
			for mode: String in ["main", "worker"]:
				body.threaded = mode == "worker"
				row[mode].append(await longest_frame_of_a_build(body))
				row["build_ms_" + mode].append(snappedf(body.cost, 0.1))
		print("%d cells: a usual frame %.2f ms; the longest frame while building: main %s, worker %s; builds took %s and %s ms" % [cells, row["usual_frame_ms"], row["main"], row["worker"], row["build_ms_main"], row["build_ms_worker"]])
		out["cells_%d" % cells] = row
		scene.free()
		await process_frame
	out["how"] = "the scene implicit.tscn in a window; the time from one frame to the next, the longest from rebuild() until two frames after the new skin is on; three builds each way"
	report["longest_frame_ms_in_a_window"] = out
	_last_sign = Time.get_ticks_msec()

func longest_frame_of_a_build(body: MeshInstance3D) -> float:
	var done := [false]
	body.built.connect(func() -> void: done[0] = true, CONNECT_ONE_SHOT)
	var longest := 0.0
	var before := Time.get_ticks_usec()
	body.rebuild()
	var after := 0
	while after < 2:
		await process_frame
		var now := Time.get_ticks_usec()
		longest = maxf(longest, (now - before) / 1000.0)
		before = now
		if done[0]:
			after += 1
	_last_sign = Time.get_ticks_msec()
	return snappedf(longest, 0.01)
