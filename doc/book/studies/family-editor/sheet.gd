extends "res://supplied/sheet_tools.gd"
## The sheet of this kit. It needs a window, so run it WITHOUT --headless, from
## this folder:
##   godot --path . --xr-mode off --script res://sheet.gd
## It writes
##   sheet.png    Ada's pyramid at the four values of apex_stance, each alone
##                in the studio, in BODY, from four standpoints, each 2 m from
##                the middle: level (from the front), plan (straight down and
##                without perspective, as a map is drawn), across (square to
##                the diagonal the apex walks) and along (on that diagonal, so
##                that the apex walks away from the eye)
##   process.png  five steps of the making, in the studio, from its fixed camera
##   sheet.json   every pair from every standpoint, the closest and the
##                farthest; the three steps of the axis and which is largest;
##                where each apex is in plan and how far apart; the spire at
##                nine values of lean, each against the one before; and how
##                much each step of the strip changed
## and the stills, in stills/. The values of the axis are read from the class,
## as the lesson's own sheet reads them.

const AdaPyramid := preload("res://borrowed/ada_pyramid.gd")
const SPIRE := "res://guests/family-editor/family-editor.tscn"
const AXIS := "apex_stance"
const VIEWS := ["level", "plan", "across", "along"]
const PLAN_SIZE := 1.82    # metres of floor from top to bottom of a plan: what the eye 2 m above the middle sees of the floor
const ACROSS := Vector3(-1.41421, 0.5, 1.41421)   # 2 m from the middle, square to the diagonal the apex walks
const ALONG := Vector3(1.41421, 0.5, 1.41421)     # 2 m from the middle, on that diagonal: the apex walks away from the eye
const MIDDLE := Vector3(0.0, 0.5, 0.0)

func values_of(script: Script, field: String) -> PackedStringArray:
	for property: Dictionary in script.get_script_property_list():
		if property["name"] == field:
			return property["hint_string"].split(",")
	return PackedStringArray()

func member(value: String) -> Node3D:
	var body := AdaPyramid.new()
	body.set(AXIS, value)    # before it enters the studio: this class builds once
	return body

## One body alone in the studio from one of the four standpoints.
func taken(body: Node3D, view: String, name: String) -> Array:
	await stand(body)
	eye.projection = Camera3D.PROJECTION_PERSPECTIVE
	if view == "across" or view == "along":
		look_from(ACROSS if view == "across" else ALONG, MIDDLE)
		shadows(false)
	elif view == "plan":
		look("above")
		eye.projection = Camera3D.PROJECTION_ORTHOGONAL
		eye.size = PLAN_SIZE
	else:
		look(view)
	return await portrait(body, name)

func run() -> void:
	await sheet()
	light()
	await series()
	await process_strip()

## The comparison sheet: every value from every standpoint, every pair measured.
func sheet() -> void:
	var values := values_of(AdaPyramid, AXIS)
	var names := Array(values)
	report["axis"] = AXIS
	report["values_read_from_the_class"] = names
	var plan := {}
	var apexes := []
	for value: String in values:
		var body := member(value)
		var apex: Vector3 = body._apex_position(body._base_ring())
		apexes.append(Vector2(apex.x, apex.z))
		plan[value] = {"apex_x": snappedf(apex.x, 0.001), "apex_z": snappedf(apex.z, 0.001),
			"over_its_base": maxf(absf(apex.x), absf(apex.z)) <= body.base_size / 2 + 0.001}
		body.free()
	var apart := {}
	for i in names.size():
		for j in range(i + 1, names.size()):
			apart["%s vs %s" % [names[i], names[j]]] = snappedf((apexes[i] - apexes[j]).length(), 0.001)
	report["apex_in_plan_m"] = plan
	report["apexes_apart_in_plan_m"] = apart
	var tiles: Array[Image] = []
	var captions := []
	var covers := {}
	var closest := {}
	var steps := {}
	for view: String in VIEWS:
		var stills := []
		var pixels := []
		for value: String in values:
			var got: Array = await taken(member(value), view, "%s_%s" % [value, view])
			stills.append(got[0])
			pixels.append(got[1])
			tiles.append(small(got[0]))
			captions.append("%s: %s" % [view, value])
			covers["%s, %s" % [view, value]] = share(got[1])
		print("--- ", view)
		var pairs := compare_all(names, stills, pixels)
		report["pairs_" + view] = pairs
		closest[view] = pairs["closest"]
		# The axis as three steps, each value against the one before it.
		var row := {}
		var largest := ""
		for i in range(1, names.size()):
			var key := "%s vs %s" % [names[i - 1], names[i]]
			row[key] = pairs["pairs"][key]["differ_pct"]
			if largest == "" or row[key] > row[largest]:
				largest = key
		row["largest"] = largest
		steps[view] = row
	report["closest_by_view"] = closest
	report["steps_by_view"] = steps
	report["body_covers_pct"] = covers
	report["sheet_png"] = await compose(tiles, values.size(), captions, "res://sheet.png")

## Another cause than the standpoint: where the studio's sun stands against the
## diagonal the apex walks, and at which lean the face on the +x side, dark at
## lean 0, first turns towards the sun. Arithmetic on the sun's own direction.
func light() -> void:
	var to_sun: Vector3 = studio.get_node("Look/Sun").global_basis.z
	var along_floor := Vector2(-to_sun.x, -to_sun.z).normalized()    # the way the light travels over the floor
	var walk := Vector2(-1.0, -1.0).normalized()                     # the way the apex walks
	var turns_at := -1.0
	for step in 161:
		var lean := step * 0.01
		var apex := Vector3(-0.3 * lean, 0.8, -0.3 * lean)
		var normal := (Vector3(0.3, 0.0, 0.3) - Vector3(0.3, 0.0, -0.3)).cross(apex - Vector3(0.3, 0.0, -0.3))
		if normal.x < 0.0:
			normal = -normal
		if normal.dot(to_sun) > 0.0 and turns_at < 0.0:
			turns_at = lean
	report["light"] = {"sun_to_apex_diagonal_deg": snappedf(absf(rad_to_deg(along_floor.angle_to(walk))), 0.1),
		"sun_above_the_horizon_deg": snappedf(rad_to_deg(asin(to_sun.y)), 0.1),
		"plus_x_face_turns_to_the_sun_at_lean": snappedf(turns_at, 0.01)}
	print("light: ", report["light"])

## The spire at nine values of lean: each against the one before, and against 0.
func series() -> void:
	var rows := {}
	for view: String in VIEWS:
		var first: Image
		var before: Image
		var row := []
		for step in 9:
			var lean := step * 0.2
			var spire: Node3D = load(SPIRE).instantiate()
			spire.lean = lean
			var got: Array = await taken(spire, view, "")
			if step > 0:
				row.append({"lean": snappedf(lean, 0.01), "differs_from_the_one_before_pct": differ_pct(got[0], before),
					"differs_from_lean_0_pct": differ_pct(got[0], first), "over_its_base": spire.over_base()})
				print("%s, lean %.1f: differs from %.1f on %5.2f%% of the still, from 0 on %5.2f%%" % [view, lean, lean - 0.2, row[-1]["differs_from_the_one_before_pct"], row[-1]["differs_from_lean_0_pct"]])
			else:
				first = got[0]
			before = got[0]
		rows[view] = row
	report["spire_series"] = rows

## The process strip: one still after each step. The chapter's scene stands in
## the studio without its own floor, sky, light and camera, so that the stills
## are made in the plain look, from the studio's fixed camera, with shadows.
func process_strip() -> void:
	var scene: Node3D = load("res://family_editor.tscn").instantiate()
	for own: String in ["Look", "Floor", "FloorBody", "Camera3D"]:
		scene.get_node(own).free()
	var walker: CharacterBody3D = scene.get_node("Walker")
	walker.position = Vector3(3.2, 0.0, -1.6)   # off the rail, before the scene starts
	for hidden: String in ["Wall", "Rail", "Walker", "Readout"]:
		scene.get_node(hidden).visible = false
	await stand(scene, false)     # not held: the walker has to walk
	eye.projection = Camera3D.PROJECTION_PERSPECTIVE
	studio.get_node("Camera3D").current = true
	shadows(true)
	var spire: Node3D = scene.get_node("Spire")
	var names := ["1 the class as written: lean 0", "2 the value the scene stores: 1.6", "3 set while it stands: 0.8", "4 our sheet: Ada's four stances", "5 the rail, walked to its low end"]
	var tiles: Array[Image] = []
	spire.lean = 0.0
	tiles.append(small(await shot("strip_1")))
	spire.lean = 1.6
	tiles.append(small(await shot("strip_2")))
	spire.lean = 0.8
	tiles.append(small(await shot("strip_3")))
	scene.get_node("Wall").visible = true
	tiles.append(small(await shot("strip_4")))
	for shown: String in ["Rail", "Walker", "Readout"]:
		scene.get_node(shown).visible = true
	walker.stand_at(Vector3(1.9, 0.0, 1.5))
	walker.walk_to([Vector3(1.9, 0.0, -0.5)])
	for i in 150:
		await physics_frame
	tiles.append(small(await shot("strip_5")))
	report["strip"] = await strip(tiles, names)
	report["strip"]["lean_after_the_walk"] = snappedf(spire.lean, 0.01)
	report["strip"]["spire_built_times"] = spire.rebuilds
	await stand(null)    # the scene leaves the studio before the window closes
