extends "res://supplied/verify_tools.gd"
## The checks of the Implicit study. Headless, from this folder:
##   godot --headless --path . --xr-mode off --script res://verify.gd
## It writes verification.json; the exit code is the number of checks that failed.
## With --fixed-fps 60 added the result is the same: where a check has to wait for
## a build, which takes real time on its thread, it waits for the body's state
## and not for a count of frames.
## What it checks, in this order: the project and its files; the borrowed table
## against itself; the field; the skin (which way it faces, whether it is
## closed, whether it stands); the four thresholds and where the count of
## bodies changes; what the grid and the box do to the body; the worker thread,
## the planted bug and the comparison turned round; the walker, the carving and
## the marble; the guest. Every number the lesson gives that is not a still's
## is in `measured`.

const Pieces := preload("res://pieces.gd")
const Table := preload("res://mc_table.gd")
const GuestTable := preload("res://guests/implicit/mc_table.gd")
const CheckGuest := preload("res://supplied/check_guest.gd")
const VALUES := [0.2, 0.4, 0.6, 0.8]
const OURS := ["res://field_body.gd", "res://implicit.gd", "res://pieces.gd", "res://mc_table.gd", "res://table_station.gd", "res://verify.gd", "res://sheet.gd",
	"res://guests/implicit/implicit.gd", "res://guests/implicit/mc_table.gd"]

func run() -> void:
	project_and_files()
	the_table()
	await the_field_and_the_skin()
	await the_thresholds()
	await the_grid_and_the_box()
	await the_thread()
	await the_faults()
	await the_place()
	await the_guest()

# ---------------------------------------------------------------- helpers

## A body with field_body.gd (or `script`) on it, in the tree, its first skin on.
func new_body(script: Script = null, settings := {}) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	body.set_script(script if script != null else load("res://field_body.gd"))
	for key: String in settings:
		body.set(key, settings[key])
	root.add_child(body)
	await new_skin(body, null)
	return body

## Wait until `body` wears another skin than `old` and no build is running: at most 8 seconds.
## It does not wait for the signal `built`, so a body whose signal never comes fails a check and not the run.
func new_skin(body: Node, old: Mesh) -> void:
	await wait_until(func() -> bool: return body.mesh != old and body.task == -1, 8000)

## field_body.gd with one piece of its text changed: a fault, planted.
func changed(old: String, new: String) -> GDScript:
	var text := FileAccess.get_file_as_string("res://field_body.gd")
	var script := GDScript.new()
	script.source_code = text.replace(old, new)
	check(text.count(old) == 1 and script.reload() == OK, "field_body.gd holds `%s` once, and loads with `%s` in its place" % [old.strip_edges(), new.strip_edges()])
	return script

## The skin of `body` at `level`: three points for every triangle.
func skin(body: MeshInstance3D, level: float) -> PackedVector3Array:
	var old: Mesh = body.mesh
	body.threshold = level
	body.rebuild()
	await new_skin(body, old)
	return points_of(body)

func points_of(body: MeshInstance3D) -> PackedVector3Array:
	if body.mesh == null or body.mesh.get_surface_count() == 0:
		return PackedVector3Array()
	return body.mesh.get_faces()

func lowest(points: PackedVector3Array) -> float:
	var low := INF
	for p in points:
		low = minf(low, p.y)
	return low

func box(points: PackedVector3Array) -> AABB:
	if points.is_empty():
		return AABB()
	var out := AABB(points[0], Vector3.ZERO)
	for p in points:
		out = out.expand(p)
	return out

## Wait until `test` says true, at most `limit` milliseconds.
func wait_until(test: Callable, limit: int) -> void:
	var began := Time.get_ticks_msec()
	while not test.call() and Time.get_ticks_msec() - began < limit:
		await process_frame

## Wait until the guest's threshold is at `level` and no build is running: at most ten seconds.
## A build takes real time on its worker thread, and a step of the physics under --fixed-fps
## takes almost none. So the guest is asked where it is; the steps are not counted.
func come_to(guest: Node, level: float) -> void:
	await wait_until(func() -> bool: return guest.task == -1 and is_equal_approx(guest.threshold, level), 10000)

## Does the guest build nothing for `steps` steps of the physics? A build begun in them has
## either ended (`builds` has grown) or is still running (`task` is not -1), whatever the clock.
func rests(guest: Node, steps: int) -> bool:
	var builds: int = guest.builds
	await physics_frames(steps)
	return guest.builds == builds and guest.task == -1

## Press `action` as a key would, and wait until `body` has its next skin on.
func press_and_built(action: String, body: MeshInstance3D) -> void:
	var done := [false]
	body.built.connect(func() -> void: done[0] = true, CONNECT_ONE_SHOT)
	await press(action)
	await wait_until(func() -> bool: return done[0], 5000)
	await frames(4)

## The longest frame, in milliseconds, from now until two frames after `body` says built.
func longest_frame_of_a_build(body: MeshInstance3D) -> float:
	var old: Mesh = body.mesh
	var longest := 0.0
	var began := Time.get_ticks_msec()
	var before := Time.get_ticks_usec()
	body.rebuild()
	var after := 0
	while after < 2 and Time.get_ticks_msec() - began < 8000:
		await process_frame
		var now := Time.get_ticks_usec()
		longest = maxf(longest, (now - before) / 1000.0)
		before = now
		if body.mesh != old and body.task == -1:
			after += 1
	return snappedf(longest, 0.01)

# ---------------------------------------------------------------- the project

func project_and_files() -> void:
	check(ProjectSettings.get_setting("application/config/name") == "Implicit", "the project is named Implicit")
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://implicit.tscn", "its main scene is implicit.tscn")
	check(DirAccess.get_files_at("res://supplied").size() == 15, "supplied/ holds its 15 files: %d" % DirAccess.get_files_at("res://supplied").size())
	var spaced: Array[String] = []
	var named: Array[String] = []
	var finder := RegEx.create_from_string("(?m)^\\s*class_name\\s")
	var missing: Array[String] = []
	for path: String in OURS:
		if not FileAccess.file_exists(path):
			missing.append(path)
			continue
		var text := FileAccess.get_file_as_string(path)
		for line in text.split("\n"):
			if line.begins_with("  ") and not spaced.has(path):
				spaced.append(path)
		if finder.search(text) != null:
			named.append(path)
	check(missing.is_empty(), "the %d scripts of the kit are there: %s" % [OURS.size(), missing])
	check(spaced.is_empty(), "every script of the kit is indented with tabs: %s" % [spaced])
	check(named.is_empty(), "no script of the kit declares a class_name: %s" % [named])
	var left_over: Array[String] = []
	for folder: String in ["res://", "res://supplied/", "res://guests/implicit/"]:
		for file in DirAccess.get_files_at(folder):
			if file.ends_with(".uid") or file.ends_with(".import"):
				left_over.append(folder + file)
	check(left_over.is_empty(), "no .uid and no .import file is left in the kit: %s" % [left_over])

# ---------------------------------------------------------------- the borrowed table

func the_table() -> void:
	var triangles := 0
	var threes := true
	for row: Array in Table.TRIANGLE_TABLE:
		triangles += row.size() / 3
		threes = threes and row.size() % 3 == 0
	check(Table.TRIANGLE_TABLE.size() == 256 and threes and triangles == 820, "the triangle table has 256 rows, each a list of threes, 820 triangles in all: %d rows, %d triangles" % [Table.TRIANGLE_TABLE.size(), triangles])
	# For each case, the edges that are crossed follow from the corner bits alone:
	# an edge is crossed when its two corners are on different sides.
	var wrong_triangle_rows := 0
	var wrong_edge_rows: Array[int] = []
	var thirteenth := 0
	for which in 256:
		var crossed := 0
		for edge in 12:
			var a: int = Table.EDGE_CONNECTIONS[edge][0]
			var b: int = Table.EDGE_CONNECTIONS[edge][1]
			if ((which >> a) & 1) != ((which >> b) & 1):
				crossed |= 1 << edge
		var used := 0
		for edge: int in Table.TRIANGLE_TABLE[which]:
			used |= 1 << edge
		if used != crossed:
			wrong_triangle_rows += 1
		if Table.EDGE_TABLE[which] != crossed:
			wrong_edge_rows.append(which)
		if Table.EDGE_TABLE[which] >= 1 << 12:
			thirteenth += 1
	check(wrong_triangle_rows == 0, "every row of the triangle table uses exactly the edges its corners say are crossed: %d rows do not" % wrong_triangle_rows)
	check(wrong_edge_rows.size() == 32 and wrong_edge_rows[0] == 48 and wrong_edge_rows[15] == 63 and wrong_edge_rows[16] == 192 and wrong_edge_rows[31] == 207,
		"Ada's edge table, as borrowed, disagrees with the corner bits in 32 of its 256 rows, 48 to 63 and 192 to 207: %s" % [wrong_edge_rows])
	check(thirteenth == 4, "and %d of those rows name a thirteenth edge, which a cell does not have" % thirteenth)
	var code := CheckGuest._code_only(FileAccess.get_file_as_string("res://field_body.gd"))
	check(not code.contains("EDGE_TABLE"), "field_body.gd never reads the edge table")
	check(Table.TRIANGLE_TABLE == GuestTable.TRIANGLE_TABLE and Table.EDGE_CONNECTIONS == GuestTable.EDGE_CONNECTIONS and Table.CUBE_VERTICES == GuestTable.CUBE_VERTICES and Table.EDGE_TABLE == GuestTable.EDGE_TABLE,
		"the guest's own copy of the table holds the same four lists")
	var z_of_first_four := 0.0
	for i in 4:
		z_of_first_four += Table.CUBE_VERTICES[i].z
	check(z_of_first_four == 0.0 and Table.CUBE_VERTICES[4].z == 1.0, "the four corners Ada's comment calls the bottom face differ from the four it calls the top face in z, not in y")
	# The station a learner runs says the same.
	var from := printed.size()
	var station: Node = load("res://table_station.tscn").instantiate()
	root.add_child(station)
	var lines := printed.slice(from)
	check(lines.size() == 3 and lines[0] == "triangle table: 256 rows, 820 triangles; rows that disagree with the corner bits: []"
		and lines[1].begins_with("edge table: 256 rows; rows that disagree with the corner bits: [48, 49, 50,") and lines[1].ends_with("205, 206, 207]")
		and lines[2] == "edge table: rows that name a thirteenth edge: [62, 63, 192, 193]", "table_station.tscn prints its three lines: %s" % [lines])
	station.free()
	measured["table_station_prints"] = lines
	measured["table"] = {"triangle_rows": 256, "triangles": triangles, "edge_table_rows_that_disagree": wrong_edge_rows, "edge_table_rows_with_a_thirteenth_edge": thirteenth}

# ---------------------------------------------------------------- the field and the skin

func the_field_and_the_skin() -> void:
	var before := errors.size()
	var body := await new_body()
	check(errors.size() == before, "a body with field_body.gd builds its first skin and Godot logs no error: %s" % [errors.slice(before)])
	var said := {}
	for place: Vector3 in [body.centres[0], Vector3(0.0, 0.9, 0.0), Vector3(0.0, 0.9, 2.0)]:
		said[str(place)] = "%.3f" % body.value_at(place)
	check(said.values() == ["1.022", "0.475", "-0.012"], "the field at a centre, between the two lower centres and 2 m in front: %s" % [said])
	var n: int = body.cells + 1
	var step: float = body.size / body.cells
	var inside := 0
	var began := Time.get_ticks_usec()
	for z in n:
		for y in n:
			for x in n:
				if body.value_at(Vector3(-body.size / 2.0, 0.0, -body.size / 2.0) + Vector3(x, y, z) * step) > 0.4:
					inside += 1
	var asking := (Time.get_ticks_usec() - began) / 1000.0
	check(n * n * n == 68921 and inside == 5873, "the grid has %d samples, %d of them inside at 0.4; asking them all took %.1f ms here" % [n * n * n, inside, asking])
	var points := points_of(body)
	check(points.size() == 18846 and body.pieces == 1, "at 0.4 the skin has %d points, %d triangles, and is %d body" % [points.size(), points.size() / 3, body.pieces])
	var field := func(p: Vector3) -> float: return body.value_at(p)
	var share := Pieces.outward(points, field)
	check(share == 1.0, "every triangle with an area faces outward, toward where the field is lower: a share of %.4f" % share)
	check(Pieces.open_edges(points, 0.0001) == 0, "above the ground the skin is closed: %d open edges" % Pieces.open_edges(points, 0.0001))
	check(Pieces.open_edges(points) > 0 and lowest(points) == 0.0, "it is open where it stands: a rim of %d edges at height %.4f m" % [Pieces.open_edges(points), lowest(points)])
	check(Pieces.flat(points) == 5, "%d of its triangles have two corners in one place" % Pieces.flat(points))
	var off := 0.0
	for p in points:
		off = maxf(off, absf(body.value_at(p) - 0.4))
	check(off < 0.03, "every point of the skin lies where the field is 0.4, give or take %.4f" % off)
	check(body.wall != null and body.wall.get_child_count() == 1 and body.wall.get_parent() == body, "the body has a wall: a StaticBody3D with one shape, made from the same triangles")
	# The normals: one for every point, shared by the points in one place, pointing to where the field is lower.
	var arrays := body.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals := PackedVector3Array()
	if arrays[Mesh.ARRAY_NORMAL] != null:
		normals = arrays[Mesh.ARRAY_NORMAL]
	var pointing_out := 0
	var normal_at := {}
	var places_with_two_normals := 0
	for i in normals.size():
		if body.value_at(vertices[i] + normals[i] * 0.03) < body.value_at(vertices[i] - normals[i] * 0.03):
			pointing_out += 1
		if normal_at.has(vertices[i]) and not normal_at[vertices[i]].is_equal_approx(normals[i]):
			places_with_two_normals += 1
		normal_at[vertices[i]] = normals[i]
	check(normals.size() == vertices.size() and places_with_two_normals == 0 and pointing_out == normals.size(),
		"every point has a normal, the points in one place share one, and %d of %d point to where the field is lower" % [pointing_out, normals.size()])
	var alone := exp(-pow(body.centres[0].distance_to(Vector3(0.0, 0.9, 0.0)) / body.radius, 2.0))
	measured["field"] = {"at": said, "samples": n * n * n, "samples_inside_at_0.4": inside, "asking_every_sample_ms": snappedf(asking, 0.1), "one_lower_source_alone_halfway_between_the_two": snappedf(alone, 0.001), "furthest_a_point_is_from_the_threshold": snappedf(off, 0.0001)}
	measured["skin_at_0.4"] = {"points": points.size(), "triangles": points.size() / 3, "share_facing_outward": share, "open_edges_above_ground": 0,
		"rim_edges_on_the_ground": Pieces.open_edges(points), "triangles_with_two_corners_in_one_place": Pieces.flat(points), "build_ms": snappedf(body.cost, 0.1)}
	body.queue_free()
	await frames(2)

# ---------------------------------------------------------------- the argument

func the_thresholds() -> void:
	var body := await new_body()
	var field := func(p: Vector3) -> float: return body.value_at(p)
	var rows := {}
	var counts := []
	var closed := true
	var faces_out := true
	for level: float in VALUES:
		var points := await skin(body, level)
		var around := box(points)
		counts.append(body.pieces)
		closed = closed and Pieces.open_edges(points, 0.0001) == 0
		faces_out = faces_out and Pieces.outward(points, field) == 1.0
		rows["%.1f" % level] = {"bodies": body.pieces, "triangles_of_each": Pieces.sizes(points), "triangles": points.size() / 3, "lowest_point_m": snappedf(lowest(points), 0.001),
			"wide_m": snappedf(around.size.x, 0.01), "high_m": snappedf(around.end.y, 0.01), "deep_m": snappedf(around.size.z, 0.01), "build_ms": snappedf(body.cost, 0.1)}
	check(counts == [1, 1, 3, 3], "at 0.2, 0.4, 0.6 and 0.8 the skin is %s bodies" % [counts])
	check(closed and faces_out, "at all four it is closed above the ground and faces outward")
	check(rows["0.4"]["lowest_point_m"] == 0.0 and rows["0.6"]["lowest_point_m"] > 0.2, "at 0.4 it stands on the ground; at 0.6 its lowest point is %.3f m up: nothing holds the bodies" % rows["0.6"]["lowest_point_m"])
	var welded := await skin(body, 0.6)
	var places := {}
	for p in welded:
		places[p] = true
	check(places.size() == welded.size() / 6 + 2 * 3, "at 0.6 the %d triangles meet in %d places: three closed skins with no seam" % [welded.size() / 3, places.size()])
	# Where does one become three? In steps of a hundredth.
	var fine := {}
	var last_one := 0.0
	var first_three := 0.0
	for i in range(40, 61):
		var level := i / 100.0
		await skin(body, level)
		fine["%.2f" % level] = body.pieces
		if body.pieces == 1:
			last_one = level
		if body.pieces == 3 and first_three == 0.0:
			first_three = level
	check(last_one == 0.48 and first_three == 0.5 and fine["0.49"] == 2, "one body up to %.2f, two at 0.49, three from %.2f" % [last_one, first_three])
	measured["thresholds"] = rows
	measured["bodies_by_threshold_in_hundredths"] = fine
	# Another cause: how far apart the sources are. The same three, 1.17 times further from their middle.
	var kit_centres: PackedVector3Array = body.centres
	var middle := (kit_centres[0] + kit_centres[1] + kit_centres[2]) / 3.0
	var spread := PackedVector3Array()
	for centre in kit_centres:
		spread.append(middle + (centre - middle) * 1.17)
	var wide := await new_body(null, {"centres": spread, "size": 6.0, "cells": 48})
	var wide_counts := []
	for level: float in VALUES:
		await skin(wide, level)
		wide_counts.append(wide.pieces)
	var between := snappedf(spread[0].distance_to(spread[1]) / wide.radius, 0.01)
	check(wide_counts == [1, 3, 3, 3], "with the sources %.2f radii apart in place of %.2f, the four thresholds give %s bodies: the count changes between 0.2 and 0.4" % [between, kit_centres[0].distance_to(kit_centres[1]) / wide.radius, wide_counts])
	# Another cause: the noise. The same three sources with none.
	var plain := await new_body(null, {"wobble": 0.0})
	var plain_counts := {}
	for i in range(44, 53):
		await skin(plain, i / 100.0)
		plain_counts["%.2f" % (i / 100.0)] = plain.pieces
	check(plain_counts["0.47"] == 1 and plain_counts["0.49"] == 3 and not plain_counts.values().has(2), "without the noise the three necks part together: %s" % [plain_counts])
	measured["bodies_by_threshold_without_noise"] = plain_counts
	plain.queue_free()
	measured["sources_further_apart"] = {"radii_apart": between, "radii_apart_in_the_kit": snappedf(kit_centres[0].distance_to(kit_centres[1]) / wide.radius, 0.01), "bodies_at_0.2_0.4_0.6_0.8": wide_counts}
	wide.queue_free()
	body.queue_free()
	await frames(2)

# ---------------------------------------------------------------- the debt: the grid, the box

func the_grid_and_the_box() -> void:
	# The same field, asked on four grids. A piece is a closed skin: a body, or a crumb.
	var grids := {}
	for cells: int in [10, 20, 40, 80]:
		var body := await new_body(null, {"cells": cells})
		var row := {"cell_m": snappedf(body.size / cells, 0.0001), "triangles_at_0.4": points_of(body).size() / 3, "build_ms_at_0.4": snappedf(body.cost, 0.1)}
		var by_threshold := {}
		var last_one := 0.0
		var first_three := 0.0
		for i in range(43, 53):
			var sizes := Pieces.sizes(await skin(body, i / 100.0))
			by_threshold["%.2f" % (i / 100.0)] = sizes
			var large := 0          # pieces of more than 50 triangles: bodies, not crumbs
			for size: int in sizes:
				if size > 50:
					large += 1
			if large == 1:
				last_one = i / 100.0
			if large == 3 and first_three == 0.0:
				first_three = i / 100.0
		row["triangles_of_each_piece"] = by_threshold
		row["one_body_up_to"] = last_one
		row["three_bodies_from"] = first_three
		var at_sheet := []
		for level: float in VALUES:
			await skin(body, level)
			at_sheet.append(body.pieces)
		row["pieces_at_0.2_0.4_0.6_0.8"] = at_sheet
		grids[cells] = row
		body.queue_free()
		await frames(2)
	check(grids[10]["triangles_at_0.4"] == 364 and grids[20]["triangles_at_0.4"] == 1548 and grids[40]["triangles_at_0.4"] == 6282 and grids[80]["triangles_at_0.4"] == 25264,
		"a finer grid makes more triangles of the same field: %d, %d, %d and %d at 10, 20, 40 and 80 cells" % [grids[10]["triangles_at_0.4"], grids[20]["triangles_at_0.4"], grids[40]["triangles_at_0.4"], grids[80]["triangles_at_0.4"]])
	check(grids[10]["one_body_up_to"] == 0.46 and grids[20]["one_body_up_to"] == 0.47 and grids[40]["one_body_up_to"] == 0.48 and grids[80]["one_body_up_to"] == 0.48,
		"the grid decides where one body ends: up to %.2f, %.2f, %.2f and %.2f" % [grids[10]["one_body_up_to"], grids[20]["one_body_up_to"], grids[40]["one_body_up_to"], grids[80]["one_body_up_to"]])
	check(grids[10]["three_bodies_from"] == 0.0 and grids[20]["three_bodies_from"] == 0.51 and grids[40]["three_bodies_from"] == 0.5 and grids[80]["three_bodies_from"] == 0.51,
		"and where three begin: from %.2f, %.2f and %.2f at 20, 40 and 80 cells; at 10 cells there are still two at 0.52" % [grids[20]["three_bodies_from"], grids[40]["three_bodies_from"], grids[80]["three_bodies_from"]])
	check(grids[80]["triangles_of_each_piece"]["0.43"] == [24196, 8] and grids[40]["triangles_of_each_piece"]["0.43"] == [6024],
		"at 0.43 the grid of 80 cells finds a crumb of 8 triangles beside the body; the grid of 40 does not: %s against %s" % [grids[80]["triangles_of_each_piece"]["0.43"], grids[40]["triangles_of_each_piece"]["0.43"]])
	check(grids[10]["pieces_at_0.2_0.4_0.6_0.8"] == [1, 1, 3, 3] and grids[20]["pieces_at_0.2_0.4_0.6_0.8"] == [1, 1, 3, 3] and grids[80]["pieces_at_0.2_0.4_0.6_0.8"] == [1, 1, 3, 3],
		"at the sheet's four thresholds every grid counts the same: %s" % [grids[10]["pieces_at_0.2_0.4_0.6_0.8"]])
	measured["grids"] = grids
	# The box: what crosses its wall is cut open.
	var small := await new_body(null, {"size": 4.4, "cells": 40})
	var cut := await skin(small, 0.2)
	var open_small := Pieces.open_edges(cut, 0.0001)
	small.queue_free()
	var whole := await new_body()
	var open_whole := Pieces.open_edges(await skin(whole, 0.2), 0.0001)
	whole.queue_free()
	await frames(2)
	check(open_small > 0 and open_whole == 0, "at 0.2 a box of 4.4 m cuts the body open (%d open edges above the ground); the box of 5 m holds it (%d)" % [open_small, open_whole])
	measured["box"] = {"open_edges_at_0.2_in_a_box_of_4.4_m": open_small, "open_edges_at_0.2_in_the_box_of_5_m": open_whole}

# ---------------------------------------------------------------- the thread

func the_thread() -> void:
	var clean := errors.size()
	var body := await new_body()
	check(body.threaded and body.task == -1, "the body builds on a worker thread, and once the skin is on no task is left waiting")
	await frames(10)
	var times := {"worker": [], "main": []}
	var costs := {"worker": [], "main": []}
	for turn in 3:
		for mode: String in ["main", "worker"]:
			body.threaded = mode == "worker"
			times[mode].append(await longest_frame_of_a_build(body))
			costs[mode].append(snappedf(body.cost, 0.1))
	body.threaded = true
	check(times["worker"].max() < times["main"].min() / 2.0, "the longest frame while the body is built: %s ms on the main thread, %s ms with a worker (three builds each, no window)" % [times["main"], times["worker"]])
	measured["longest_frame_ms_without_a_window"] = times
	measured["build_ms_without_a_window"] = costs
	# What stays on the main thread: the hand-back.
	var made: ArrayMesh = body.mesh
	var began := Time.get_ticks_usec()
	body.show_mesh(made, body.pieces, body.cost)
	var hand_back := (Time.get_ticks_usec() - began) / 1000.0
	measured["hand_back_ms_without_a_window"] = snappedf(hand_back, 0.01)
	check(hand_back < body.cost / 2.0, "the hand-back, show_mesh(), took %.2f ms of the main thread; the build took %.1f ms of the worker" % [hand_back, body.cost])
	# Asked twice: the second wish is not lost.
	var seen := []      # how many bodies each new skin had
	var count_skins := func() -> void: seen.append(body.pieces)
	body.built.connect(count_skins)
	body.threshold = 0.2
	body.rebuild()
	body.threshold = 0.8
	body.rebuild()
	check(body.stale, "asked again while a build runs, the body remembers it: stale")
	await wait_until(func() -> bool: return seen.size() >= 2 and body.task == -1, 8000)
	check(seen == [1, 3] and not body.stale and body.task == -1, "it finished the build for 0.2 (1 body), then built for 0.8 (3 bodies): %s" % [seen])
	body.built.disconnect(count_skins)
	# Carving while a build runs waits for the hand-back.
	body.threshold = 0.4
	body.rebuild()
	body.carve(Vector3(0.0, 0.0, 0.1))
	check(body.cuts.is_empty() and body.task != -1, "carve() during a build does not touch the field yet")
	await wait_until(func() -> bool: return body.cuts.size() == 1, 8000)
	check(body.cuts.size() == 1 and body.task != -1, "it carves when the build has handed back, and a new build starts")
	await wait_until(func() -> bool: return body.task == -1, 8000)
	check(body.value_at(Vector3(0.0, 0.9, 0.1)) < 0.0, "and then the field in the hole is under every threshold: %.2f" % body.value_at(Vector3(0.0, 0.9, 0.1)))
	# Leaving in the middle of a build. Only tried when all went well so far: a body whose
	# thread touches the scene can wait for the main thread while the main thread waits for it.
	var before := errors.size()
	if before == clean:
		body.rebuild()
		await frames(1)
		body.queue_free()
		await frames(30)
		check(errors.size() == before, "a body freed in the middle of a build: Godot logs no error: %s" % [errors.slice(before)])
	else:
		check(false, "a body freed in the middle of a build: not tried, because Godot had logged errors before: %s" % [errors.slice(clean)])
		body.queue_free()
		await frames(30)
	# Nothing to show.
	var none := await new_body()
	before = errors.size()
	var nothing := await skin(none, 1.2)
	check(nothing.is_empty() and none.pieces == 0 and none.wall.get_child_count() == 0 and errors.size() == before, "at 1.2 the field has no skin: no triangle, 0 bodies, a wall with no shape, no error")
	none.queue_free()
	await frames(2)

# ---------------------------------------------------------------- the faults the lesson names

func the_faults() -> void:
	# The planted bug: the hand-back called straight from the worker thread.
	var before := errors.size()
	var script := changed("\tshow_mesh.call_deferred(made, count,", "\tshow_mesh(made, count,")
	var scene: Node3D = load("res://implicit.tscn").instantiate()
	var body: MeshInstance3D = scene.get_node("Body")
	body.set_script(script)
	root.add_child(scene)
	await wait_until(func() -> bool: return body.task == -1 and body.mesh != null, 3000)
	await frames(10)
	var said := errors.slice(before)
	var texts := "\n".join(said)
	check(said.size() == 4, "show_mesh() called from the worker thread: Godot logs %d errors and does not stop" % said.size())
	check(texts.contains("Adding children to a node inside the SceneTree is only allowed from the main thread. Use call_deferred(\"add_child\",node)."),
		"one of them is about add_child(): Adding children to a node inside the SceneTree is only allowed from the main thread")
	check(texts.contains("The caller thread can't call the function `update_gizmos()` on this node. Use `call_deferred()` or `call_deferred_thread_group()` instead.")
		and texts.count("The caller thread can't call the function `emit_signalp()` on this node.") == 2,
		"the other three are for `mesh =` and for the signal: The caller thread can't call the function ... on this node")
	check(body.mesh != null and body.mesh.get_surface_count() == 1 and (body.wall == null or body.wall.get_parent() == null), "the skin is on all the same, and the wall is not in the scene")
	check(scene.get_node("Readout").text == "", "the line over the scene stays empty: nobody heard `built`")
	var how := await walk(scene.get_node("Walker"), [Vector3(0.0, 0.0, 2.3), Vector3(0.0, 0.0, -2.2)])
	check(how == "arrived", "and a walker sent at the body walks through it: \"%s\"" % how)
	measured["planted_bug"] = {"errors": said, "the_skin_is_on": body.mesh != null, "the_wall_is_in_the_scene": body.wall != null and body.wall.get_parent() != null, "a_walker_sent_at_the_body": how}
	if body.wall != null and body.wall.get_parent() == null:
		body.wall.free()
	scene.queue_free()
	await frames(3)
	# The comparison as Ada's generator writes it: a bit for each corner UNDER the threshold.
	before = errors.size()
	var turned := await new_body(changed("\t\t\t\t\tif at[i] > level:", "\t\t\t\t\tif at[i] < level:"))
	var points := points_of(turned)
	var field := func(p: Vector3) -> float: return turned.value_at(p)
	var share := Pieces.outward(points, field)
	check(share == 0.0 and points.size() == 18846 and errors.size() == before, "with `<` in place of `>` the same %d triangles are made and %.0f%% of them face outward: inside out, and no error" % [points.size() / 3, share * 100.0])
	measured["with_adas_comparison"] = {"triangles": points.size() / 3, "share_facing_outward": share}
	turned.queue_free()
	await frames(2)

# ---------------------------------------------------------------- place

func the_place() -> void:
	var before := errors.size()
	var scene: Node3D = load("res://implicit.tscn").instantiate()
	root.add_child(scene)
	var body: MeshInstance3D = scene.get_node("Body")
	var walker: CharacterBody3D = scene.get_node("Walker")
	var readout: Label3D = scene.get_node("Readout")
	await new_skin(body, null)
	await frames(180)
	check(errors.size() == before, "the scene ran 180 frames and Godot logged no error: %s" % [errors.slice(before)])
	check(readout.text.begins_with("threshold 0.4: 1 body, 6282 triangles"), "the line over the scene: %s" % readout.text.get_slice("\n", 0))
	check(readout.modulate == preload("res://supplied/look.gd").INK and body.material_override.albedo_color == preload("res://supplied/look.gd").BODY, "the body is BODY and the line is INK")
	await press_and_built("pause", body)
	check(is_equal_approx(body.threshold, 0.6) and readout.text.begins_with("threshold 0.6: 3 bodies, 3588 triangles"), "Space: %s" % readout.text.get_slice("\n", 0))
	check(readout.text.contains("on a worker thread; the longest frame meanwhile") and not readout.text.contains("press Space"), "and it says what the build cost: %s" % readout.text.get_slice("\n", 1))
	for i in 3:
		await press_and_built("pause", body)
	check(is_equal_approx(body.threshold, 0.4) and body.pieces == 1, "three more: 0.8, 0.2 and back to 0.4")
	# The marble: does a loose body meet the skin? Dropped over the top source, 0.2 m off its middle.
	var marble: RigidBody3D = load("res://supplied/marble.tscn").instantiate()
	marble.position = Vector3(0.2, 4.6, 0.0)
	scene.add_child(marble)
	marble.drop(Vector3(0.2, 4.6, 0.0))
	var beside: RigidBody3D = load("res://supplied/marble.tscn").instantiate()   # the same drop where no body is
	beside.position = Vector3(3.4, 4.6, 1.5)
	scene.add_child(beside)
	beside.drop(Vector3(3.4, 4.6, 1.5))
	await physics_frames(60)
	var over: float = marble.global_position.y
	var free: float = beside.global_position.y
	check(over > 3.0 and free < 0.2, "a marble dropped from 4.6 m over the top source meets the skin: one second later it is %.2f m up, on the skin; the same drop beside the body is at %.2f m, on the floor" % [over, free])
	measured["marble"] = {"over_the_top_source_after_one_second_m": snappedf(over, 0.01), "beside_the_body_after_one_second_m": snappedf(free, 0.01)}
	marble.queue_free()
	beside.queue_free()
	# The walker: stopped, then two holes, then through.
	var how := await walk(walker, [Vector3(0.0, 0.0, 2.3)])
	var walks := []
	var carved := 0
	for attempt in 6:
		how = await walk(walker, [Vector3(0.0, 0.0, -2.2)])
		walks.append([how, snappedf(walker.global_position.z, 0.01)])
		if how != "blocked":
			break
		await press_and_built("drop", body)
		await physics_frames(2)
		carved += 1
	check(walks.size() == 3 and walks[0][0] == "blocked" and walks[1][0] == "blocked" and walks[2][0] == "arrived", "the walker is stopped by the body, carves, is stopped again, carves, and walks through: %s" % [walks])
	check(body.cuts.size() == 2 and carved == 2 and body.pieces == 1, "two holes, and the body is still %d body" % body.pieces)
	var points := points_of(body)
	# Both halves of a carving: the hole is empty, its wall is where it should be, and the rest stands.
	var in_hole := 0
	var on_wall := 0
	for p in points:
		for foot in body.cuts:
			var d := p.distance_to(Geometry3D.get_closest_point_to_segment(p, foot, foot + Vector3(0.0, 1.5, 0.0)))
			if d < 0.5:
				in_hole += 1
			elif d < 0.6:
				on_wall += 1
	var around := box(points)
	check(in_hole == 0 and on_wall > 100, "no point of the skin is nearer than 0.5 m to a hole's middle line, and %d lie on the holes' walls" % on_wall)
	check(around.size.x > 4.1 and around.end.y > 3.8, "the rest stands: %.2f m wide and %.2f m high, as before" % [around.size.x, around.end.y])
	check(Pieces.open_edges(points, 0.0001) == 0, "and the carved skin is closed above the ground")
	how = await walk(walker, [Vector3(0.0, 0.0, 0.0)])
	var above: float = body.value_at(Vector3(0.0, 2.9, 0.0))
	check(how == "arrived" and above > body.threshold, "the walker stands inside: \"%s\" at z %.2f, with the third source over its head (the field there is %.2f)" % [how, walker.global_position.z, above])
	measured["place"] = {"walks": walks, "holes": body.cuts.size(), "bodies_after": body.pieces, "triangles_after": points.size() / 3, "points_on_the_holes_walls": on_wall, "points_inside_a_hole": in_hole}
	check(errors.size() == before, "and Godot logged no error in all of it: %s" % [errors.slice(before)])
	scene.queue_free()
	await frames(3)

# ---------------------------------------------------------------- the guest

func the_guest() -> void:
	var needs := CheckGuest.outside("res://guests/implicit/")
	check(needs.is_empty(), "the guest names nothing outside its folder: %s" % [needs])
	check(CheckGuest.class_names("res://guests/implicit/").is_empty(), "the guest declares no class_name")
	var before := errors.size()
	# A floor to stand on: the supplied base. The guest at one end, a walker at the other.
	var stage: Node3D = load("res://supplied/base.tscn").instantiate()
	root.add_child(stage)
	var home := Vector3(-2.8, 0.0, 0.0)
	var guest: Node = load("res://guests/implicit/implicit.tscn").instantiate()
	check(guest is Node3D, "its first node is a kind of Node3D: %s" % guest.get_class())
	guest.position = home
	stage.add_child(guest)
	await new_skin(guest, null)
	var resting := await rests(guest, 60)
	var apart := points_of(guest)
	var around := box(apart)
	check(guest.builds == 1 and resting and is_equal_approx(guest.threshold, 0.6) and Pieces.count(apart) == 3, "alone it builds once and rests: threshold %.1f, %d bodies, %d build" % [guest.threshold, Pieces.count(apart), guest.builds])
	check(lowest(apart) == 0.0 and absf(around.position.x) <= 0.8 and around.end.x <= 0.8 and absf(around.position.z) <= 0.8 and around.end.z <= 0.8,
		"it stands on the ground and fits its place: %.2f m wide, %.2f m deep, %.2f m high" % [around.size.x, around.size.z, around.end.y])
	var walker: CharacterBody3D = load("res://supplied/walker.tscn").instantiate()
	walker.position = Vector3(3.2, 0.0, 0.0)
	walker.keys = false
	stage.add_child(walker)
	resting = await rests(guest, 60)
	check(guest.builds == 1 and resting, "a walker 6 m away does not wake it")
	# The walker comes in two walks. The first ends 2 m from the guest's middle: inside its reach
	# of 2.5 m and clear of its skin. There the walker stands until the guest has come together,
	# however long its six builds take. Only then does it walk on, into the one body.
	var near_by := home + Vector3(2.0, 0.0, 0.0)
	var how := await walk(walker, [near_by])
	await come_to(guest, 0.3)
	resting = await rests(guest, 60)
	var together := points_of(guest)
	around = box(together)
	check(how == "arrived" and is_equal_approx(guest.threshold, 0.3) and Pieces.count(together) == 1 and guest.builds == 7 and resting, "the walker comes near: the threshold falls to %.1f in %d builds and the three are %d body" % [guest.threshold, guest.builds - 1, Pieces.count(together)])
	how = await walk(walker, [home])
	var gap := snappedf(walker.global_position.distance_to(home), 0.01)
	var feet := snappedf(walker.global_position.y, 0.01)
	check(how == "blocked" and absf(feet) <= 0.01 and guest.builds == 7 and around.size.x <= 1.6 and around.size.z <= 1.6, "its wall stops the walker (\"%s\", %.2f m from its middle, its feet at %.2f m); it is %.2f m wide and %.2f m deep now" % [how, gap, feet, around.size.x, around.size.z])
	measured["guest"] = {"alone": {"threshold": 0.6, "bodies": 3, "triangles": apart.size() / 3}, "with_a_walker_near": {"threshold": 0.3, "bodies": 1, "triangles": together.size() / 3, "wide_m": snappedf(around.size.x, 0.01), "deep_m": snappedf(around.size.z, 0.01), "high_m": snappedf(around.end.y, 0.01)},
		"walker_waited_at_m_from_its_middle": 2.0, "walker_stopped_at_m_from_its_middle": gap, "walker_feet_at_m": feet, "builds_when_the_three_were_one": guest.builds}
	how = await walk(walker, [Vector3(3.2, 0.0, 0.0)])
	await come_to(guest, 0.6)
	var builds: int = guest.builds
	resting = await rests(guest, 120)
	check(is_equal_approx(guest.threshold, 0.6) and Pieces.count(points_of(guest)) == 3 and resting and builds == 13, "the walker leaves: three bodies again after %d builds in all, and then it rests" % builds)
	measured["guest"]["builds_after_the_walker_left"] = builds
	check(errors.size() == before, "and Godot logged no error: %s" % [errors.slice(before)])
	stage.queue_free()
	await frames(3)
	# The room task, done once on the guest: fuse with a fourth source, carve with one hole.
	var fused: MeshInstance3D = load("res://guests/implicit/implicit.tscn").instantiate()
	fused.centres.append(Vector3(0.0, 0.36, 0.0))
	root.add_child(fused)
	await new_skin(fused, null)
	var fused_count := Pieces.count(points_of(fused))
	fused.queue_free()
	check(fused_count == 1, "fused: a fourth source between the three makes the guest %d body while nobody is near" % fused_count)
	var foot := Vector3(0.0, 0.0, 0.0)
	var carved: MeshInstance3D = load("res://guests/implicit/implicit.tscn").instantiate()
	carved.apart = 0.3      # one body, as when somebody is near, so that there is something to carve between the sources
	carved.cuts.append(foot)
	root.add_child(carved)
	await new_skin(carved, null)
	var carved_points := points_of(carved)
	var in_hole := 0
	var on_wall := 0
	for p in carved_points:
		var d := p.distance_to(Geometry3D.get_closest_point_to_segment(p, foot, foot + Vector3(0.0, 0.5, 0.0)))
		if d < 0.1:
			in_hole += 1
		elif d < 0.15:
			on_wall += 1
	var carved_count := Pieces.count(carved_points)
	carved.queue_free()
	await frames(3)
	check(in_hole == 0 and on_wall > 20 and carved_count == 1 and carved_points.size() != together.size(), "carved: a hole between the two lower sources, at threshold 0.3: %d points on its wall, none inside, %d triangles where there were %d, still %d body" % [on_wall, carved_points.size() / 3, together.size() / 3, carved_count])
	# Measured once, in a scratch copy of my-room with this guest added, by the room's own
	# guest_trial.gd and by a probe that watched the guest. Recorded here; not measured again.
	measured["room_trial_recorded"] = {"checks": 8, "passed": 8, "place": 2, "walk_to_the_aisle": "arrived", "walk_at_the_guest": "blocked",
		"metres_from_the_middle_of_the_place": 0.64, "feet_at_m": 0.0,
		"probe": {"builds_while_nobody_is_near": 1, "threshold_with_the_walker_in_the_aisle_2_m_away": 0.3, "builds_by_then": 7, "triangles_then": 1420, "builds_after_the_walker_left": 13}}
	measured["room_task"] = {"fused_bodies_at_0.6": fused_count, "carved_triangles_at_0.3": carved_points.size() / 3, "carved_points_on_the_holes_wall": on_wall, "carved_bodies_at_0.3": carved_count}
