extends "res://supplied/verify_tools.gd"
## Headless checks of the Spiral stair kit. From this folder:
##   godot --headless --path . --xr-mode off --script res://verify.gd
## Writes verification.json beside this file; the exit code is the number of
## checks that failed. No import step is needed: nothing here has a class_name.
## Headless draws no frames, so what the eye gets is measured by sheet.gd.
## The walker walks in real time, and there are about thirty walks: the run
## takes about two minutes. Add --fixed-fps 60 and the same steps of the
## physics are taken as fast as the machine can, in a few seconds.

const Look := preload("res://supplied/look.gd")
const CheckGuest := preload("res://supplied/check_guest.gd")
const Trig := preload("res://borrowed/trig_lines.gd")
const Stair := preload("res://stair.gd")
const SCENE := "res://spiral_stair.tscn"
const WALKER := "res://supplied/walker.tscn"
const GUEST := "res://guests/spiral-stair/"
const START := Vector3(2.7, 0.0, 0.0)    # where spiral_stair.tscn puts the walker

func text_of(path: String) -> String:
	return FileAccess.get_file_as_string(path)

func flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)

## The angle of a point round the middle, in degrees, -180 to 180.
func angle_of(v: Vector3) -> float:
	return rad_to_deg(atan2(v.z, v.x))

func close(node: Node) -> void:
	node.free()
	await frames(1)

## A stair with these values, not yet in a scene.
func stair(values := {}) -> Node3D:
	var body: Node3D = Stair.new()
	for key: String in values:
		body.set(key, values[key])
	return body

## A base, a stair in it and a walker at START; returns [base, stair, walker].
func world(body: Node3D, walker_values := {}, start := START) -> Array:
	var base: Node3D = load("res://supplied/base.tscn").instantiate()
	root.add_child(base)
	base.add_child(body)
	var walker: CharacterBody3D = load(WALKER).instantiate()
	walker.position = start      # before add_child: a body is in the room from the step it is added
	for key: String in walker_values:
		walker.set(key, walker_values[key])
	base.add_child(walker)
	await physics_frames(20)
	return [base, body, walker]

## Send a walker up a stair and say how it ended: {how, feet, at}.
func climb(values := {}, walker_values := {}) -> Dictionary:
	var w: Array = await world(stair(values), walker_values)
	var how := await walk(w[2], w[1].route())
	var at: Vector3 = w[2].global_position
	var last: Vector3 = w[1].route()[-1]
	var out := {"how": how, "feet": snappedf(at.y, 0.01), "top": snappedf(w[1].top(), 0.01), "from_the_last_point_m": snappedf(flat(at - last).length(), 0.01)}
	await close(w[0])
	return out

## The steepest and the flattest triangle of a ramp, in degrees from level.
func slopes(ramp: Node3D) -> Vector2:
	var surface: MeshInstance3D = ramp.find_children("*", "MeshInstance3D", true, false)[0]
	var corners: PackedVector3Array = surface.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var steepest := 0.0
	var flattest := 90.0
	for k in range(0, corners.size(), 3):
		var normal := (corners[k + 1] - corners[k]).cross(corners[k + 2] - corners[k]).normalized()
		var tilt := rad_to_deg(acos(absf(normal.y)))
		steepest = maxf(steepest, tilt)
		flattest = minf(flattest, tilt)
	return Vector2(flattest, steepest)

func run() -> void:
	project()
	trigonometry()
	borrowed_lines()
	await the_stair()
	await the_scene()
	await the_rises()
	await the_planted_bug()
	await the_ramp()
	await who_is_excluded()
	await down_again()
	await the_marble()
	await the_guest()

func project() -> void:
	check(ProjectSettings.get_setting("application/config/name") == "Spiral stair" and ProjectSettings.get_setting("application/run/main_scene") == SCENE
		and ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility" and ResourceLoader.exists(SCENE),
		"the project is named Spiral stair, its main scene is spiral_stair.tscn, its renderer Compatibility")
	var named := []
	var supplied := []
	for file in DirAccess.get_files_at("res://supplied"):
		if not file.ends_with(".uid"):    # the editor writes one beside every script it has seen
			supplied.append(file)
	check(supplied == ["base.tscn", "base_look.gd", "check_guest.gd", "look.gd", "marble.gd", "marble.tscn", "mover.gd", "segment.gd", "sheet_tools.gd", "sweep_sheet.gd", "sweep_sheet.tscn", "trace_strip.gd", "verify_tools.gd", "walker.gd", "walker.tscn"], "supplied/ holds the base's 15 files: %s" % [supplied])
	var spaced := []
	var ours := 0
	for folder: String in ["res://", "res://supplied/", "res://borrowed/", GUEST]:
		for file in DirAccess.get_files_at(folder):
			if not file.ends_with(".gd"):
				continue
			var text := text_of(folder + file)
			ours += 1
			if RegEx.create_from_string("(?m)^ +\\S").search(text) != null or text.contains("\r"):
				spaced.append(file)
			if RegEx.create_from_string("(?m)^\\s*class_name\\s").search(text) != null:
				named.append(file)
	check(spaced.is_empty(), "the %d scripts of the kit are indented with tabs and end their lines with a line feed: %s" % [ours, spaced])
	check(named.is_empty() and ProjectSettings.get_global_class_list().is_empty(), "no script declares a class_name, and the project lists no named class: nothing needs an import")
	check(FileAccess.file_exists("res://walk_test.gd") and text_of("res://walk_test.gd").begins_with("extends \"res://supplied/verify_tools.gd\"") and text_of("res://walk_test.gd").contains("walk_test.json"),
		"walk_test.gd, the lesson's own test, is built on the supplied harness and writes walk_test.json, not this file's result")

## What the lesson says of sin(), cos(), radians and TAU.
func trigonometry() -> void:
	check(is_equal_approx(sin(deg_to_rad(30.0)), 0.5) and absf(sin(30.0) + 0.988032) < 0.000001, "sin(deg_to_rad(30)) is 0.5 and sin(30) is %.6f: sin() reads its number as radians" % sin(30.0))
	check(is_equal_approx(deg_to_rad(360.0), TAU) and is_equal_approx(deg_to_rad(180.0), PI) and absf(TAU - 6.283185) < 0.000001, "a whole turn is TAU radians, %.6f; half a turn is PI" % TAU)
	check(absf(rad_to_deg(1.0) - 57.29578) < 0.0001, "one radian is %.2f degrees" % rad_to_deg(1.0))
	var first := [str(Vector3(1.2 * cos(0.0), 0.09, 1.2 * sin(0.0))), str(Vector3(1.2 * cos(1.0), 0.09, 1.2 * sin(1.0))), str(Vector3(1.2 * cos(deg_to_rad(30.0)), 0.09, 1.2 * sin(deg_to_rad(30.0))))]
	check(first == ["(1.2, 0.09, 0.0)", "(0.648363, 0.09, 1.009765)", "(1.03923, 0.09, 0.6)"] and absf(deg_to_rad(30.0) - 0.5236) < 0.0001,
		"the lesson's first tread: at angle 0 it is printed %s, at 1.0 %s, at deg_to_rad(30.0), which is %.4f, %s" % [first[0], first[1], deg_to_rad(30.0), first[2]])
	check("%s %s" % [sin(30), sin(deg_to_rad(30))] == "-0.98803162409286 0.5", "print(sin(30), \" \", sin(deg_to_rad(30))) gives %s %s" % [sin(30), sin(deg_to_rad(30))])
	var body := stair()
	var on_circle := true
	for i in 10:
		on_circle = on_circle and absf(flat(body.place(i, 1.2)).length() - 1.2) < 0.00001 and is_equal_approx(body.place(i, 1.2).y, 0.18 * i)
	check(on_circle and body.place(0, 1.2).is_equal_approx(Vector3(1.2, 0, 0)) and body.place(3, 1.2).is_equal_approx(Vector3(0, 0.54, 1.2)) and body.place(6, 1.2).is_equal_approx(Vector3(-1.2, 1.08, 0)) and body.place(9, 1.2).is_equal_approx(Vector3(0, 1.62, -1.2)),
		"place(i, r) stays r from the middle and rises 0.18 m with every i: place(0) is (1.2, 0, 0), place(3) is (0, 0.54, 1.2), place(6) is (-1.2, 1.08, 0), place(9) is (0, 1.62, -1.2)")
	check(body.place(0.5, 1.2).is_equal_approx(Vector3(1.2 * cos(deg_to_rad(15.0)), 0.09, 1.2 * sin(deg_to_rad(15.0)))), "place() takes a number between two treads: place(0.5) is 15 degrees round and 0.09 m up")
	var sag := 1.2 * Trig.gap_to_circle(12)
	check(absf(flat((body.place(1, 1.2) + body.place(2, 1.2)) / 2.0).length() - (1.2 - sag)) < 0.00001 and absf(sag - 0.0409) < 0.0001,
		"the straight way from one tread's middle to the next comes %.4f m nearer the middle than the circle: 1.2 * gap_to_circle(12)" % sag)
	measured["trigonometry"] = {"sin_30": snappedf(sin(30.0), 0.000001), "sin_deg_to_rad_30": snappedf(sin(deg_to_rad(30.0)), 0.000001), "TAU": snappedf(TAU, 0.000001),
		"one_radian_deg": snappedf(rad_to_deg(1.0), 0.01), "deg_to_rad_30": snappedf(deg_to_rad(30.0), 0.0001), "the_first_tread_printed": first, "sin_30_printed": str(sin(30)), "chord_between_tread_middles_m": snappedf((body.place(2, 1.2) - body.place(1, 1.2) - Vector3(0, 0.18, 0)).length(), 0.001),
		"route_nearer_the_middle_than_the_circle_m": snappedf(sag, 0.0001)}
	body.free()

## The four lines the lesson opens.
func borrowed_lines() -> void:
	check(absf(Trig.gap_to_circle(16) - 0.019215) < 0.000001 and is_equal_approx(Trig.gap_to_circle(16), 1.0 - cos(deg_to_rad(11.25))) and absf(Trig.gap_to_circle(12) - 0.034074) < 0.000001,
		"gap_to_circle(16) is %.4f, the family lesson's 1 - cos(11.25 degrees); gap_to_circle(12) is %.4f" % [Trig.gap_to_circle(16), Trig.gap_to_circle(12)])
	check(is_equal_approx(Trig.wave_height(PI / 2.0, PI / 2.0), 1.0) and absf(Trig.wave_height(PI, 1.0)) < 0.000001 and is_equal_approx(Trig.wave_height(0.5, 0.25), Trig.wave_height(0.5 + TAU, 0.25)),
		"wave_height(x, z) is sin(x) * sin(z): 1 at (PI / 2, PI / 2), 0 along x = PI, and the same again TAU metres on")
	var waist := Trig.catenoid(0.0, 0.0)
	var higher := Trig.catenoid(deg_to_rad(90.0), 1.0)
	check(waist.is_equal_approx(Vector3(1, 0, 0)) and higher.is_equal_approx(Vector3(0, 1, cosh(1.0))), "catenoid(u, v) is a circle whose radius is cosh(v): 1 at the waist, %.3f one metre up" % cosh(1.0))
	var ring: Array = Trig.base_ring(4, 1.2)
	var body := stair({"turn_deg": 90.0, "rise": 0.0})
	var same := ring.size() == 4
	for i in ring.size():
		same = same and (ring[i] as Vector3).is_equal_approx(body.place(i + 2.5, 1.2))
	check(same, "base_ring(4, 1.2) is place(i + 2.5, 1.2) with a turn of 90 degrees and no rise: the pyramid's base is this chapter's function, started at 225 degrees")
	body.free()

## The stair as stair.gd builds it.
func the_stair() -> void:
	var w: Array = await world(stair())
	var body: Node3D = w[1]
	var treads := body.get_children()
	var right := treads.size() == 9
	var size := Vector3(0.9, 0.18, 0.7)
	var radial := true
	var painted := true
	for i in treads.size():
		var tread: Node = treads[i]
		var block: MeshInstance3D = tread.get_child(0) if tread.get_child_count() == 2 else null
		var collider: CollisionShape3D = tread.get_child(1) if tread.get_child_count() == 2 else null
		right = right and tread is StaticBody3D and block != null and collider != null and block.mesh is BoxMesh and collider.shape is BoxShape3D
		if not right:
			break
		right = right and block.mesh.size.is_equal_approx(size) and collider.shape.size.is_equal_approx(size)
		right = right and (tread.position + Vector3(0, 0.09, 0)).is_equal_approx(body.place(i + 1, 1.2))
		var outward := Vector3(tread.position.x, 0, tread.position.z).normalized()
		radial = radial and (tread.global_basis.x).is_equal_approx(outward)
		painted = painted and block.material_override is StandardMaterial3D and block.material_override.albedo_color.is_equal_approx(Look.BODY)
	check(right, "the stair is 9 treads: each a StaticBody3D with a box of 0.9 x 0.18 x 0.7 m as its mesh and as its collider, the middle of its top at place(i)")
	check(radial, "each tread is turned so that its long side points away from the middle")
	check(painted, "each tread is painted BODY")
	var route: Array = body.route()
	check(route.size() == 10 and (route[0] as Vector3).is_equal_approx(Vector3(1.2, 0, 0)) and (route[9] as Vector3).is_equal_approx(body.place(9, 1.2)) and is_equal_approx(body.top(), 1.62),
		"route() is 10 points, from the foot on the floor at (1.2, 0, 0) to the middle of the top tread; top() is 1.62 m")
	body.position = Vector3(1.0, 0.0, -0.5)
	check((body.route()[0] as Vector3).is_equal_approx(Vector3(2.2, 0, -0.5)), "route() gives places in the room: move the stair and the route moves with it")
	await close(w[0])

## The scene as it is shipped: the walker climbs.
func the_scene() -> void:
	var before := errors.size()
	var lines := printed.size()
	var scene: Node3D = load(SCENE).instantiate()
	root.add_child(scene)
	var walker: CharacterBody3D = scene.get_node("Walker")
	check(walker.position.is_equal_approx(START) and scene.get_node("Stair").get_child_count() == 9 and scene.get_node_or_null("Look/Sun") != null,
		"spiral_stair.tscn inherits the base: the look, a Stair of 9 treads, the Walker on the floor at (2.7, 0, 0)")
	var how: String = await walker.walk_ended
	await frames(2)
	var at := walker.global_position
	check(how == "arrived" and absf(at.y - 1.62) < 0.02 and flat(at - Vector3(0, 0, -1.2)).length() < 0.11,
		"run, the walker climbs the stair: its walk ended \"%s\" with its feet at %.2f m, on the top tread" % [how, at.y])
	var said := ""
	for line in printed.slice(lines):
		if line.begins_with("the walker "):
			said = line
	check(said == "the walker arrived with its feet at 1.62 m; the top is at 1.62 m", "climb.gd prints what happened: \"%s\"" % said)
	await frames(180)
	check(errors.size() == before, "the scene ran 180 frames more and Godot logged no error: %s" % [errors.slice(before)])
	measured["the_scene"] = {"walk_ended": how, "feet_at_m": snappedf(at.y, 0.01), "printed": said}
	await close(scene)
	# The lesson's fourth step: treads that are meshes only. The walker arrives, on the floor.
	var w: Array = await world(stair())
	for shape: CollisionShape3D in w[1].find_children("*", "CollisionShape3D", true, false):
		shape.disabled = true
	how = await walk(w[2], w[1].route())
	at = w[2].global_position
	check(how == "arrived" and absf(at.y) < 0.02, "with no colliders the same walk ends \"%s\" with the feet at %.2f m: the walker went through the treads, so \"arrived\" alone does not say it climbed" % [how, at.y])
	measured["no_colliders"] = {"walk_ended": how, "feet_at_m": snappedf(at.y, 0.01)}
	await close(w[0])

## The argument: four rises, and where the walker's limit is.
func the_rises() -> void:
	var table := {}
	for rise: float in [0.10, 0.18, 0.30, 0.60, 0.35, 0.36]:
		table["%.2f" % rise] = await climb({"rise": rise})
	for rise: String in ["0.10", "0.18", "0.30"]:
		var r: Dictionary = table[rise]
		check(r["how"] == "arrived" and absf(r["feet"] - r["top"]) < 0.02, "rise %s m: the walk ended \"%s\" with the feet at %.2f m; the top is at %.2f m" % [rise, r["how"], r["feet"], r["top"]])
	var high: Dictionary = table["0.60"]
	check(high["how"] == "blocked" and absf(high["feet"]) < 0.02, "rise 0.60 m: the walk ended \"%s\" with the feet at %.2f m, in front of the first tread; the top is at %.2f m" % [high["how"], high["feet"], high["top"]])
	check(table["0.35"]["how"] == "arrived" and absf(table["0.35"]["feet"] - 3.15) < 0.02 and table["0.36"]["how"] == "blocked" and absf(table["0.36"]["feet"]) < 0.02,
		"the limit is the walker's step_height, 0.35 m: at a rise of 0.35 m it reaches the top (%.2f m), at 0.36 m it is stopped on the floor" % table["0.35"]["feet"])
	var walker: CharacterBody3D = load(WALKER).instantiate()
	check(is_equal_approx(walker.step_height, 0.35) and is_equal_approx(walker.floor_max_angle, deg_to_rad(45.0)) and is_equal_approx(walker.floor_snap_length, 0.1),
		"the supplied walker steps up 0.35 m; as a CharacterBody3D it calls a slope a floor up to 45 degrees and snaps to a floor within 0.1 m")
	walker.free()
	measured["rises"] = table
	# More than one turn: the treads above are a ceiling.
	var turns := {}
	for rise: float in [0.18, 0.20, 0.21, 0.30]:
		turns["%.2f" % rise] = await climb({"rise": rise, "treads": 16})
	check(turns["0.18"]["how"] == "blocked" and absf(turns["0.18"]["feet"]) < 0.02 and turns["0.30"]["how"] == "arrived" and absf(turns["0.30"]["feet"] - 4.8) < 0.02,
		"16 treads go once round and a third, and tread 12 hangs over the foot. At a rise of 0.18 m its underside is 11 rises up, %.2f m, and the walker is stopped on the floor (feet at %.2f m); at 0.30 m it reaches the top, %.2f m" % [11 * 0.18, turns["0.18"]["feet"], turns["0.30"]["feet"]])
	check(turns["0.20"]["how"] == "blocked" and absf(turns["0.20"]["feet"] - 0.2) < 0.02 and turns["0.21"]["how"] == "arrived" and absf(turns["0.21"]["feet"] - 3.36) < 0.02,
		"with 11 rises of 0.20 m overhead, %.2f m, it takes one tread and is stopped (feet at %.2f m); with 11 of 0.21 m, %.2f m, it climbs to the top, %.2f m" % [11 * 0.20, turns["0.20"]["feet"], 11 * 0.21, turns["0.21"]["feet"]])
	measured["sixteen_treads"] = turns

## The planted bug: the turn handed to cos() and sin() in degrees.
func the_planted_bug() -> void:
	# cos() takes radians, so 30 is 30 radians. A turn of rad_to_deg(30) degrees is the same stair.
	var w: Array = await world(stair({"turn_deg": rad_to_deg(30.0)}))
	var body: Node3D = w[1]
	var angles := []
	var expected := [-81.1, -162.3, 116.6, 35.5, -45.6, -126.8, 152.1, 71.0, -10.1]
	var as_expected := body.get_child_count() == expected.size()
	for tread in body.get_children():
		angles.append(snappedf(angle_of(tread.position), 0.1))
		as_expected = as_expected and absf(angles[-1] - expected[angles.size() - 1]) < 0.06
	var apart := flat(body.place(2, 1.2) - body.place(1, 1.2)).length()
	check(as_expected and absf(apart - 1.56) < 0.01,
		"with 30 read as radians each tread lies 278.9 degrees on from the last, which is 81.1 degrees back: %s; two neighbours are %.2f m apart, not 0.62 m" % [angles, apart])
	check(absf(30.0 / TAU - 4.7746) < 0.0001 and absf(rad_to_deg(fposmod(30.0, TAU)) - 278.87) < 0.01, "30 radians is %.2f turns: four whole turns and %.1f degrees" % [30.0 / TAU, rad_to_deg(fposmod(30.0, TAU))])
	var before := errors.size() + warnings.size()
	var how := await walk(w[2], body.route())
	var at: Vector3 = w[2].global_position
	check(how == "blocked" and absf(at.y) < 0.02, "the walker's walk ends \"%s\" with its feet at %.2f m: the top tread hangs over the foot of the stair, its underside at 1.44 m" % [how, at.y])
	check(errors.size() + warnings.size() == before, "and Godot logged no error and no warning: the fault is silent")
	var back := 360.0 - rad_to_deg(fposmod(30.0, TAU))
	check(absf(back - 81.1) < 0.05 and absf(9.0 * back / 360.0 - 2.03) < 0.005 and absf(at.x - 2.0) < 0.02, "nine treads 81.1 degrees apart go %.2f times round the middle, backwards; the walker stands at x = %.2f m, %.2f m short of the foot" % [9.0 * back / 360.0, at.x, at.x - 1.2])
	measured["planted_bug"] = {"degrees_back_per_tread": snappedf(back, 0.1), "turns_backwards": snappedf(9.0 * back / 360.0, 0.01), "short_of_the_foot_m": snappedf(at.x - 1.2, 0.01), "tread_angles_deg": angles, "neighbours_apart_m": snappedf(apart, 0.01), "walk_ended": how, "feet_at_m": snappedf(at.y, 0.01), "walker_at": [snappedf(at.x, 0.01), snappedf(at.z, 0.01)]}
	await close(w[0])

## The ramp: the same function as one surface.
func the_ramp() -> void:
	var w: Array = await world(stair({"ramp": true}))
	var body: Node3D = w[1]
	var slope: Node = body.get_child(0) if body.get_child_count() == 1 else null
	var surface: MeshInstance3D = slope.get_child(0) if slope != null else null
	var collider: CollisionShape3D = slope.get_child(1) if slope != null else null
	var corners := 0
	var faces := 0
	if surface != null and surface.mesh != null:
		corners = surface.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()
	if collider != null and collider.shape is ConcavePolygonShape3D:
		faces = collider.shape.get_faces().size() / 3
	check(slope is StaticBody3D and corners == 60 and faces == 20, "with `ramp` ticked the stair is one body: a surface of 10 pieces, %d corners, and one ConcavePolygonShape3D of %d triangles" % [corners, faces])
	var box: AABB = surface.get_aabb() if surface != null else AABB()
	check(surface != null and absf(box.position.y) < 0.001 and absf(box.end.y - 1.8) < 0.001 and surface.material_override.albedo_color.is_equal_approx(Look.BODY) and surface.material_override.cull_mode == BaseMaterial3D.CULL_DISABLED,
		"the ramp starts on the floor and ends at %.2f m, one piece past the walker's last point; it is BODY, drawn from both sides" % box.end.y)
	var tilt := slopes(body)
	var middle := rad_to_deg(atan(0.18 / (1.2 * deg_to_rad(30.0))))
	check(absf(tilt.x - 12.3) < 0.1 and absf(tilt.y - 25.6) < 0.1 and absf(middle - 16.0) < 0.1,
		"each piece is two flat triangles, one %.1f and one %.1f degrees steep; the curve under the walker's feet rises at %.1f degrees" % [tilt.x, tilt.y, middle])
	await close(w[0])
	var table := {}
	for rise: float in [0.10, 0.18, 0.30, 0.60]:
		table["%.2f" % rise] = await climb({"rise": rise, "ramp": true})
		var body_at := stair({"rise": rise, "ramp": true})
		root.add_child(body_at)
		var s := slopes(body_at)
		table["%.2f" % rise]["flattest_triangle_deg"] = snappedf(s.x, 0.1)
		table["%.2f" % rise]["steepest_triangle_deg"] = snappedf(s.y, 0.1)
		table["%.2f" % rise]["curve_under_the_feet_deg"] = snappedf(rad_to_deg(atan(rise / (1.2 * deg_to_rad(30.0)))), 0.1)
		body_at.free()
	for rise: String in ["0.10", "0.18", "0.30"]:
		var r: Dictionary = table[rise]
		check(r["how"] == "arrived" and absf(r["feet"] - r["top"]) < 0.06 and r["steepest_triangle_deg"] < 45.0,
			"the ramp at a rise of %s m: the walk ended \"%s\" with the feet at %.2f m of %.2f m; its steepest triangle is %.1f degrees" % [rise, r["how"], r["feet"], r["top"], r["steepest_triangle_deg"]])
	var high: Dictionary = table["0.60"]
	check(high["how"] == "blocked" and high["feet"] < 0.5 and high["steepest_triangle_deg"] > 45.0 and absf(high["curve_under_the_feet_deg"] - 43.7) < 0.05,
		"the ramp at 0.60 m: the walk ended \"%s\" with the feet at %.2f m. The curve under the feet rises at %.1f degrees; the steepest triangle is %.1f, more than the 45 the walker calls a floor" % [high["how"], high["feet"], high["curve_under_the_feet_deg"], high["steepest_triangle_deg"]])
	var wider := await climb({"rise": 0.60, "ramp": true}, {"floor_max_angle": deg_to_rad(70.0)})
	check(wider["how"] == "arrived" and absf(wider["feet"] - 5.4) < 0.06, "a walker told that 70 degrees is still a floor climbs that ramp: \"%s\", feet at %.2f m. The slope was what stopped it" % [wider["how"], wider["feet"]])
	table["0.60, floor_max_angle 70"] = wider
	table["0.60, floor_max_angle 60"] = await climb({"rise": 0.60, "ramp": true}, {"floor_max_angle": deg_to_rad(60.0)})
	table["0.60, floor_max_angle 61"] = await climb({"rise": 0.60, "ramp": true}, {"floor_max_angle": deg_to_rad(61.0)})
	check(table["0.60, floor_max_angle 60"]["how"] == "blocked" and table["0.60, floor_max_angle 61"]["how"] == "arrived",
		"that ramp's steepest triangle is 58.0 degrees, yet a walker with a floor_max_angle of 60 is stopped (feet at %.2f m) and one with 61 climbs: the limit is not the triangle's own slope" % table["0.60, floor_max_angle 60"]["feet"])
	table["0.38"] = await climb({"rise": 0.38, "ramp": true})
	table["0.40"] = await climb({"rise": 0.40, "ramp": true})
	check(table["0.38"]["how"] == "arrived" and table["0.40"]["how"] == "blocked", "the ramp's own limit for this walker lies between a rise of 0.38 m (\"%s\") and of 0.40 m (\"%s\", feet at %.2f m)" % [table["0.38"]["how"], table["0.40"]["how"], table["0.40"]["feet"]])
	measured["ramp"] = table

## The debt: a body that does not step, on the stair and on the ramp.
func who_is_excluded() -> void:
	var table := {}
	for rise: float in [0.10, 0.18, 0.30, 0.60]:
		table["stair %.2f" % rise] = await climb({"rise": rise}, {"step_height": 0.0})
		table["ramp %.2f" % rise] = await climb({"rise": rise, "ramp": true}, {"step_height": 0.0})
	var stairs_closed := true
	var ramps_open := true
	for rise: String in ["0.10", "0.18", "0.30"]:
		stairs_closed = stairs_closed and table["stair " + rise]["how"] == "blocked" and absf(table["stair " + rise]["feet"]) < 0.02
		ramps_open = ramps_open and table["ramp " + rise]["how"] == "arrived" and absf(table["ramp " + rise]["feet"] - table["ramp " + rise]["top"]) < 0.06
	check(stairs_closed, "a walker with step_height 0, a body that does not step, is stopped on the floor by the stair at 0.10, 0.18 and 0.30 m")
	check(ramps_open, "the same body reaches the top of the ramp at 0.10, 0.18 and 0.30 m: %.2f, %.2f and %.2f m" % [table["ramp 0.10"]["feet"], table["ramp 0.18"]["feet"], table["ramp 0.30"]["feet"]])
	table["ramp 0.35"] = await climb({"rise": 0.35, "ramp": true}, {"step_height": 0.0})
	check(table["ramp 0.35"]["how"] == "blocked" and table["ramp 0.35"]["feet"] < 0.5, "on the ramp at 0.35 m, which the walker climbs up to 0.38 m, the body that does not step is stopped with its feet at %.2f m: the step helps on a ramp too" % table["ramp 0.35"]["feet"])
	check(table["stair 0.60"]["how"] == "blocked" and absf(table["stair 0.60"]["feet"]) < 0.02 and table["ramp 0.60"]["how"] == "blocked" and table["ramp 0.60"]["feet"] < 0.5,
		"at 0.60 m it is stopped by both: on the floor by the stair, with its feet at %.2f m by the ramp" % table["ramp 0.60"]["feet"])
	measured["a_body_that_does_not_step"] = table

## Up and down again, counting the steps of the physics in which the walker is off the floor.
func there_and_back(values: Dictionary, snap: float) -> Dictionary:
	var w: Array = await world(stair(values), {"floor_snap_length": snap})
	var up := await walk(w[2], w[1].route())
	var back: Array = w[1].route()
	back.reverse()
	back.append(START)
	w[2].walk_to(back)
	var steps := 0
	var in_the_air := 0
	while w[2].walking:
		await physics_frame
		steps += 1
		if not w[2].is_on_floor():
			in_the_air += 1
	await frames(2)
	var out := {"up": up, "down": w[2].ended, "feet": snappedf(w[2].global_position.y, 0.01), "steps_down": steps, "steps_in_the_air": in_the_air}
	await close(w[0])
	return out

## Floor snap: what keeps a body's feet on a floor that falls away.
func down_again() -> void:
	var table := {"stair, snap 0.1": await there_and_back({}, 0.1), "ramp, snap 0.1": await there_and_back({"ramp": true}, 0.1), "ramp, snap 0": await there_and_back({"ramp": true}, 0.0)}
	var all_down := true
	for key: String in table:
		all_down = all_down and table[key]["up"] == "arrived" and table[key]["down"] == "arrived" and absf(table[key]["feet"]) < 0.02
	check(all_down, "sent back down the same route, the walker ends \"arrived\" on the floor, on the stair and on the ramp")
	check(table["ramp, snap 0.1"]["steps_in_the_air"] == 0 and table["ramp, snap 0"]["steps_in_the_air"] > 100 and table["stair, snap 0.1"]["steps_in_the_air"] > 50,
		"going down the ramp with floor_snap_length 0.1 it is off the floor in %d of %d steps; with the snap at 0 in %d of %d; down the stair, with the snap, in %d of %d" % [
			table["ramp, snap 0.1"]["steps_in_the_air"], table["ramp, snap 0.1"]["steps_down"], table["ramp, snap 0"]["steps_in_the_air"], table["ramp, snap 0"]["steps_down"], table["stair, snap 0.1"]["steps_in_the_air"], table["stair, snap 0.1"]["steps_down"]])
	measured["down_again"] = table

## A stair keeps what is put on it. A ramp gives it back.
func the_marble() -> void:
	var rests := {}
	for ramp: bool in [false, true]:
		var w: Array = await world(stair({"ramp": ramp}))
		var marble: RigidBody3D = load("res://supplied/marble.tscn").instantiate()
		marble.position = Vector3(3.5, 0.1, 2.0)
		w[0].add_child(marble)
		await frames(2)
		marble.drop(w[1].route()[-1] + Vector3(0, 0.5, 0))
		var lowest := INF
		for i in 240:      # four seconds
			await physics_frame
			lowest = minf(lowest, marble.global_position.y)
		rests["ramp" if ramp else "stair"] = {"after_4_s_at_m": snappedf(marble.global_position.y, 0.01), "from_the_middle_m": snappedf(flat(marble.global_position).length(), 0.01)}
		await close(w[0])
	check(absf(rests["stair"]["after_4_s_at_m"] - 1.72) < 0.02, "a marble dropped on the top tread stays there: its middle at %.2f m" % rests["stair"]["after_4_s_at_m"])
	check(rests["ramp"]["after_4_s_at_m"] < 0.5, "dropped on the same point of the ramp it rolls down and away: four seconds later it is at %.2f m, %.2f m from the middle" % [rests["ramp"]["after_4_s_at_m"], rests["ramp"]["from_the_middle_m"]])
	measured["marble"] = rests

## The body handed to the room.
func the_guest() -> void:
	var needs := CheckGuest.outside(GUEST)
	check(needs.is_empty(), "the guest names nothing outside its folder: %s" % [needs])
	check(CheckGuest.class_names(GUEST).is_empty(), "the guest declares no class_name")
	var base: Node3D = load("res://supplied/base.tscn").instantiate()
	root.add_child(base)
	var guest: Node = load(GUEST + "spiral-stair.tscn").instantiate()
	base.add_child(guest)
	await frames(2)
	var box := AABB()
	var first := true
	for part: MeshInstance3D in guest.find_children("*", "MeshInstance3D", true, false):
		var here: AABB = part.global_transform * part.get_aabb()
		box = here if first else box.merge(here)
		first = false
	check(guest is Node3D and guest.get_child_count() == 7 and absf(box.position.y) < 0.001 and absf(box.end.y - 1.8) < 0.001,
		"the guest is a Node3D: a stair of 6 treads and a plate at its foot, standing on the ground, %.2f m high" % box.end.y)
	check(box.position.x >= -0.8 and box.end.x <= 0.8 and box.position.z >= -0.8 and box.end.z <= 0.8,
		"it fits the place of 1.6 m by 1.6 m: from %.3f to %.3f m in x and from %.3f to %.3f m in z" % [box.position.x, box.end.x, box.position.z, box.end.z])
	var colours := true
	for part: MeshInstance3D in guest.find_children("*", "MeshInstance3D", true, false):
		var colour: Color = part.material_override.albedo_color
		colours = colours and (colour.is_equal_approx(Look.BODY) or colour.is_equal_approx(Look.LINE))
	check(colours, "its treads are BODY and its plate LINE, written out as the look's own values")
	measured["guest"] = {"box_x": [snappedf(box.position.x, 0.001), snappedf(box.end.x, 0.001)], "box_z": [snappedf(box.position.z, 0.001), snappedf(box.end.z, 0.001)], "height_m": snappedf(box.end.y, 0.01)}
	# A walker comes from the aisle, as in the room, and walks at the middle of the place.
	var walker: CharacterBody3D = load(WALKER).instantiate()
	walker.position = Vector3(0.0, 0.0, 2.0)
	base.add_child(walker)
	await physics_frames(20)
	var how := await walk(walker, [Vector3.ZERO])
	var at := walker.global_position
	check(how == "arrived" and absf(at.y - 1.8) < 0.02 and flat(at - guest.route()[-1]).length() < 0.11,
		"a walker that steps on the plate is handed the route and climbs: its walk ended \"%s\" with its feet at %.2f m, on the top tread" % [how, at.y])
	measured["guest"]["walk_ended"] = how
	measured["guest"]["feet_at_m"] = snappedf(at.y, 0.01)
	await close(base)
	# The same guest for two other bodies, and as a ramp.
	var others := {}
	for trial: Array in [["a body that does not step", {}, {"step_height": 0.0}], ["as a ramp", {"ramp": true}, {}], ["as a ramp with a rise of 0.10 m", {"ramp": true, "rise": 0.10}, {}], ["with the kit's rise, 0.18 m", {"rise": 0.18}, {}]]:
		base = load("res://supplied/base.tscn").instantiate()
		root.add_child(base)
		guest = load(GUEST + "spiral-stair.tscn").instantiate()
		for key: String in trial[1]:
			guest.set(key, trial[1][key])
		base.add_child(guest)
		walker = load(WALKER).instantiate()
		walker.position = Vector3(0.0, 0.0, 2.0)
		for key: String in trial[2]:
			walker.set(key, trial[2][key])
		base.add_child(walker)
		await physics_frames(20)
		how = await walk(walker, [Vector3.ZERO])
		others[trial[0]] = {"walk_ended": how, "feet_at_m": snappedf(walker.global_position.y, 0.01), "top_m": snappedf(guest.top(), 0.01)}
		await close(base)
	check(others["a body that does not step"]["walk_ended"] == "blocked" and absf(others["a body that does not step"]["feet_at_m"]) < 0.02, "the guest stops a body that does not step, on the floor")
	check(others["as a ramp"]["walk_ended"] == "blocked" and others["as a ramp"]["feet_at_m"] < 0.5, "as a ramp at its own rise, 0.30 m, it stops the walker too, its feet at %.2f m: on a place 1.6 m wide that ramp is too steep" % others["as a ramp"]["feet_at_m"])
	check(others["as a ramp with a rise of 0.10 m"]["walk_ended"] == "arrived" and absf(others["as a ramp with a rise of 0.10 m"]["feet_at_m"] - 0.6) < 0.06, "a ramp that fits the place and can be walked rises 0.10 m a piece: it ends \"arrived\" at %.2f m" % others["as a ramp with a rise of 0.10 m"]["feet_at_m"])
	check(others["with the kit's rise, 0.18 m"]["walk_ended"] == "blocked" and absf(others["with the kit's rise, 0.18 m"]["feet_at_m"]) < 0.02, "at the kit's own rise, 0.18 m, the narrow stair stops the walker on the floor: on treads 0.35 m deep this body needs the steeper stair")
	measured["guest"]["others"] = others
	# Why the kit's rise stops it: the walker's own landing test (see _step_up() in walker.gd), repeated where that walk ended.
	base = load("res://supplied/base.tscn").instantiate()
	root.add_child(base)
	guest = load(GUEST + "spiral-stair.tscn").instantiate()
	guest.set("rise", 0.18)
	base.add_child(guest)
	walker = load(WALKER).instantiate()
	walker.position = Vector3(0.0, 0.0, 2.0)
	base.add_child(walker)
	await physics_frames(20)
	how = await walk(walker, [Vector3.ZERO])
	var ahead: Vector3 = guest.route()[0] - walker.global_position    # it was on its way to the foot of the stair
	ahead.y = 0.0
	ahead = ahead.normalized() * 0.32
	var up: Vector3 = Vector3.UP * walker.step_height
	var landing := KinematicCollision3D.new()
	var lands: bool = walker.test_move(walker.global_transform.translated(up + ahead), -up, landing)
	var tread: int = (landing.get_collider() as Node).get_index() + 1 if lands else 0
	var level: float = landing.get_normal().y if lands else 0.0
	check(how == "blocked" and tread == 2 and level < 0.9 and level > 0.5 and is_equal_approx(guest.top() / 6.0 * 2.0, 0.36),
		"why: lifted %.2f m and moved ahead, the walker would come down on tread %d, whose top is at 0.36 m, and on its edge: the landing's normal has y = %.2f, and the walker steps only onto a level top, y above 0.9" % [walker.step_height, tread, level])
	measured["guest"]["at_the_kits_rise"] = {"walk_ended": how, "would_land_on_tread": tread, "landing_normal_y": snappedf(level, 0.01), "that_treads_top_m": 0.36, "the_walker_lifts_itself_m": walker.step_height}
	await close(base)
