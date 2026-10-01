extends SceneTree
## Headless checks for the Organism study. From this folder:
##   godot --headless --path . --xr-mode off --script res://verify.gd
## Writes verification.json beside this file; exit code 0 when every check passes.
## Headless draws no frames, so what the eye gets is measured by sheet.gd, and what
## a real frame rate does by second.gd; here we check what the chain is made of
## (who is whose parent, where a joint puts its child), what the numbers in
## TUTORIAL.md claim (positions worked out by hand, the angle after one second,
## the cells the lattice loses), and that last chapter's cube and instruments
## still stand. Nothing in this run is expected to print an error.

var checks := []
var measured := {}

const HIP := Vector3(-0.9, 1.12, 0.8)        # where the Hip node stands
const L := 0.3                               # one bar's length
const DROP := 0.13                           # the toe hangs this far under the foot
const FRACTIONS := [0.0, 1.0 / 3.0, 0.5, -0.5]
const NAMES := ["at the end", "at one third", "at the centre", "outside"]
const LATTICE_AT := Vector3(-0.6, 0.99, 0.24)
const SPACING := 0.12
const BITE := 0.16
const CUBE_AT := Vector3(1.05, 1.37, 0.6)
const RADIUS := 0.1                          # the marble's radius
const CHAIN := "Organism/Hip/Upper/Lower/Foot/Toe"

func _initialize() -> void: run.call_deferred()

func check(label: String, passed: bool) -> void:
	checks.append({"name": label, "passed": passed})
	print(("PASS " if passed else "FAIL ") + label)

func frames(count: int) -> void:
	for i in count:
		await process_frame

## Let the marble fall and come to rest: up to four seconds of physics.
func settle(marble: RigidBody3D) -> Vector3:
	for i in 240:
		await physics_frame
		if i > 30 and marble.sleeping:
			break
	return marble.position

func key_names(codes: Array) -> String:
	return ", ".join(codes.map(func(c): return OS.get_keycode_string(c)))

## One study with the limb built from one value of `pivot`. The organism does
## not run by itself: this script calls its _process, so every step is counted.
func open(value: int, script_path := "") -> Node3D:
	var study: Node3D = load("res://organism.tscn").instantiate()
	if script_path != "":
		study.get_node("Organism").set_script(load(script_path))
	else:
		study.get_node("Organism").pivot = value
	root.add_child(study)
	study.get_node("Organism").set_process(false)
	await frames(2)
	await physics_frame
	return study

func close(study: Node3D) -> void:
	study.free()
	await process_frame

func near(a: Vector3, b: Vector3, slack := 0.0005) -> bool:
	return (a - b).length() < slack

func rounded(v: Vector3) -> Array:
	return [snappedf(v.x, 0.001), snappedf(v.y, 0.001), snappedf(v.z, 0.001)]

## The direction a bar points after turning by `a` about the upright axis: at 0
## it points along +z, towards the camera, and a positive angle carries it to +x.
func heading(a: float) -> Vector3:
	return Vector3(sin(a), 0.0, cos(a))

## The chain worked out by hand, joint after joint. `p` is where the pivot sits
## on each bar, as a fraction of its length.
func foot_by_hand(p: float, a1: float, a2: float) -> Vector3:
	return HIP + Vector3(0, 0, p * L) + L * heading(a1) + L * heading(a1 + a2)

func toe_by_hand(p: float, a1: float, a2: float, a3: float) -> Vector3:
	return foot_by_hand(p, a1, a2) + (L - p * L) * heading(a1 + a2 + a3) + Vector3(0, -DROP, 0)

func set_angles(study: Node3D, a1: float, a2: float, a3: float) -> void:
	study.get_node("Organism/Hip/Upper").rotation.y = a1
	study.get_node("Organism/Hip/Upper/Lower").rotation.y = a2
	study.get_node("Organism/Hip/Upper/Lower/Foot").rotation.y = a3

## The middle of one end face of a bar, in the room: z = 0.25 is the far end of
## the cube the bar is made of, z = -0.25 its near end.
func bar_end(study: Node3D, joint: String, far: bool) -> Vector3:
	var bar: Node3D = study.get_node("Organism/" + joint + "/Bar")
	return bar.to_global(Vector3(0, 0, 0.25 if far else -0.25))

## Which way every triangle of a bar's mesh faces, as in the cube's own checks.
func outward(bar: MeshInstance3D) -> int:
	var vs: PackedVector3Array = (bar.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var count := 0
	for t in vs.size() / 3:
		var plane := Plane(vs[t * 3], vs[t * 3 + 1], vs[t * 3 + 2])
		if plane.normal.dot((vs[t * 3] + vs[t * 3 + 1] + vs[t * 3 + 2]) / 3.0) > 0.0:
			count += 1
	return count

## The cells a body standing at `at` must take, and the cells it may take: the
## lattice's rule worked out here a second time, with 2 mm of slack either way.
func cells_near(at: Vector3, must: Dictionary, may: Dictionary) -> void:
	for column in 8:
		for row in 11:
			var across := Vector2(LATTICE_AT.x + column * SPACING - at.x, LATTICE_AT.z + row * SPACING - at.z).length()
			if across <= BITE - 0.002:
				must[Vector2i(column, row)] = true
			if across <= BITE + 0.002:
				may[Vector2i(column, row)] = true

func as_set(list: Array) -> Dictionary:
	var result := {}
	for key in list:
		result[key] = true
	return result

func subset(small: Dictionary, big: Dictionary) -> bool:
	for key in small:
		if not big.has(key):
			return false
	return true

## What a ray sent straight down meets first: the path of the body it hit and
## the height of the hit, or "nothing".
func ray_down(over: Vector3, to_height: float) -> Array:
	var query := PhysicsRayQueryParameters3D.create(Vector3(over.x, 2.5, over.z), Vector3(over.x, to_height, over.z))
	var hit := root.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return ["nothing", 0.0]
	return [str(hit.collider.get_path()), hit.position.y]

## One whole turn in steps of `step` seconds through the organism's own _process.
func turn(study: Node3D, step: float) -> int:
	var organism := study.get_node("Organism")
	var lattice := organism.get_node("Lattice")
	organism.angle = 0.0
	lattice.fill()
	while organism.angle < TAU:
		organism._process(step)
	return lattice.lost.size()

func run() -> void:
	# The Input Map: the nine actions of the Cube study, unchanged.
	var wanted := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_forward": [KEY_W, KEY_UP], "move_backward": [KEY_S, KEY_DOWN],
		"pause": [KEY_SPACE], "close": [KEY_ENTER], "fill": [KEY_F], "drop": [KEY_M], "look": [KEY_V],
	}
	for action: String in wanted:
		var bound := []
		if InputMap.has_action(action):
			for event in InputMap.action_get_events(action):
				if event is InputEventKey:
					bound.append(event.physical_keycode)
		check("action %s exists, bound to %s" % [action, key_names(wanted[action])], bound == wanted[action])

	# The earlier studies are carried unchanged and still run on their own.
	var lines: Node3D = load("res://line.tscn").instantiate()
	root.add_child(lines)
	await frames(2)
	check("line.tscn still runs on its own: readout 1.50 m", lines.get_node("Readout").text == "1.50 m")
	lines.free()
	var trace_study: Node3D = load("res://trace.tscn").instantiate()
	root.add_child(trace_study)
	await frames(2)
	check("trace.tscn still runs on its own: 1 kept", trace_study.get_node("Record").text.begins_with("1 kept"))
	trace_study.free()
	var plane_study: Node3D = load("res://plane.tscn").instantiate()
	root.add_child(plane_study)
	await frames(2)
	check("plane.tscn still runs on its own: open, no face, no cube",
		plane_study.get_node("Record").text.contains("open") and plane_study.get_node("Face").mesh == null
		and not plane_study.has_node("Cube"))
	plane_study.free()
	var cube_study: Node3D = load("res://cube.tscn").instantiate()
	root.add_child(cube_study)
	await frames(2)
	check("cube.tscn still runs on its own: a cube of 12 outward triangles, and no organism",
		outward(cube_study.get_node("Cube")) == 12 and not cube_study.has_node("Organism"))
	cube_study.free()

	# The scene inherits Cube: last chapter's body and instruments are there.
	var study := await open(0)
	var organism: Node3D = study.get_node("Organism")
	var lattice: Node3D = organism.get_node("Lattice")
	var hip: Node3D = organism.get_node("Hip")
	var upper: Node3D = hip.get_node("Upper")
	var lower: Node3D = upper.get_node("Lower")
	var foot: Node3D = lower.get_node("Foot")
	var toe: Node3D = foot.get_node("Toe")
	var cube: MeshInstance3D = study.get_node("Cube")
	var marble: RigidBody3D = study.get_node("Marble")
	var b: Node3D = study.get_node("B")
	check("the root still runs plane.gd; A, B, Segment, Strip, Record, Face, FaceBody, Marble and Under are inherited",
		study.get_script().resource_path == "res://plane.gd" and study.has_node("A") and study.has_node("Segment")
		and study.has_node("Strip") and study.has_node("Record") and study.has_node("Face")
		and study.has_node("FaceBody/CollisionShape3D") and study.has_node("Under")
		and marble.get_script().resource_path == "res://marble.gd"
		and b.get_script().resource_path == "res://mover.gd")
	check("the cube stands where it stood, at (1.05, 1.37, 0.6), repaired: 12 outward triangles, 0.5 m on every edge",
		cube.position.is_equal_approx(CUBE_AT) and cube.draft == 3 and outward(cube) == 12
		and cube.mesh.get_aabb().size.is_equal_approx(Vector3(0.5, 0.5, 0.5)))
	marble.drop(CUBE_AT + Vector3(0.1, 0.75, -0.1))
	var rest := await settle(marble)
	check("the marble still reads the cube: dropped over its top it rests at %.3f m" % rest.y, absf(rest.y - 1.72) < 0.02)

	# The chain: who is whose parent.
	check("Organism runs organism.gd and Lattice runs lattice.gd",
		organism.get_script().resource_path == "res://organism.gd" and lattice.get_script().resource_path == "res://lattice.gd")
	check("the chain is nested in the scene: Organism > Hip > Upper > Lower > Foot > Toe",
		toe.get_parent() == foot and foot.get_parent() == lower and lower.get_parent() == upper
		and upper.get_parent() == hip and hip.get_parent() == organism and organism.get_parent() == study)
	check("thirteen nodes hang below Hip: three pins, three bars with a Body and a shape each, and the toe", hip.find_children("*", "", true, false).size() == 13)
	check("the lattice is no part of the chain: it is Organism's other child", lattice.get_parent() == organism and not hip.is_ancestor_of(lattice))
	var bars: Array = [upper.get_node("Bar"), lower.get_node("Bar"), foot.get_node("Bar")]
	var ours := true
	for bar: MeshInstance3D in bars:
		ours = (ours and bar.get_script().resource_path == "res://cube.gd" and bar.corners == cube.corners
			and bar.triangles == cube.triangles and bar.get_node("Body/CollisionShape3D").shape is ConcavePolygonShape3D)
	check("each of the three joints has a Bar that runs our cube.gd, with the cube's own 8 corners and 12 triples and a Body", ours)
	var stretched := true
	for bar: MeshInstance3D in bars:
		stretched = (stretched and bar.mesh.get_aabb().size.is_equal_approx(Vector3(0.5, 0.5, 0.5))
			and bar.scale.is_equal_approx(Vector3(0.16, 0.16, 0.6)) and outward(bar) == 12)
	check("each Bar's mesh is still the cube, 0.5 m on every edge; the node's scale (0.16, 0.16, 0.6) makes it a bar of 0.08 x 0.08 x 0.3 m", stretched)
	check("no joint is scaled: the stretch sits on the leaves", upper.scale.is_equal_approx(Vector3.ONE)
		and lower.scale.is_equal_approx(Vector3.ONE) and foot.scale.is_equal_approx(Vector3.ONE) and hip.scale.is_equal_approx(Vector3.ONE))
	var bar0: MeshInstance3D = bars[0]
	check("corner 6 of the upper bar is (0.25, 0.25, 0.25) in its list and (-0.86, 1.16, 1.1) in the room: to_global()",
		bar0.corners[6].is_equal_approx(Vector3(0.25, 0.25, 0.25)) and near(bar0.to_global(bar0.corners[6]), Vector3(-0.86, 1.16, 1.1)))

	# At rest.
	check("at rest the Hip stands at (-0.9, 1.12, 0.8), at the height of the walk, and Upper, its pin, stands in it",
		near(hip.global_position, HIP) and near(upper.global_position, HIP))
	check("at rest the three bars lie end to end along +z: 0.8 to 1.1, 1.1 to 1.4, 1.4 to 1.7",
		near(bar_end(study, "Hip/Upper", false), HIP) and near(bar_end(study, "Hip/Upper", true), HIP + Vector3(0, 0, 0.3))
		and near(bar_end(study, "Hip/Upper/Lower", false), HIP + Vector3(0, 0, 0.3)) and near(bar_end(study, "Hip/Upper/Lower", true), HIP + Vector3(0, 0, 0.6))
		and near(bar_end(study, "Hip/Upper/Lower/Foot", false), HIP + Vector3(0, 0, 0.6)) and near(bar_end(study, "Hip/Upper/Lower/Foot", true), HIP + Vector3(0, 0, 0.9)))
	check("at rest the foot's position is (0, 0, 0.3) and its global_position is (-0.9, 1.12, 1.4); the toe is at (-0.9, 0.99, 1.7)",
		near(foot.position, Vector3(0, 0, 0.3)) and near(foot.global_position, Vector3(-0.9, 1.12, 1.4)) and near(toe.global_position, Vector3(-0.9, 0.99, 1.7)))

	# A child moves with its parent.
	var thirty := deg_to_rad(30.0)
	set_angles(study, thirty, 0.0, 0.0)
	check("Upper turned 30 degrees: the foot's position is still (0, 0, 0.3); its global_position is (-0.6, 1.12, 1.3196), 0.6 m from the hip",
		near(foot.position, Vector3(0, 0, 0.3)) and near(foot.global_position, Vector3(-0.6, 1.12, 1.319615))
		and near(foot.global_position, foot_by_hand(0.0, thirty, 0.0)) and absf((foot.global_position - HIP).length() - 0.6) < 0.0005)
	set_angles(study, thirty, thirty, 0.0)
	check("Upper and Lower turned 30 degrees: the foot is at (-0.4902, 1.12, 1.2098), as worked out by hand",
		near(foot.global_position, Vector3(-0.490192, 1.12, 1.209808)) and near(foot.global_position, foot_by_hand(0.0, thirty, thirty))
		and near(foot.position, Vector3(0, 0, 0.3)))
	var on_circle := true
	for degrees in [0.0, 45.0, 90.0, 200.0, 310.0]:
		set_angles(study, thirty, deg_to_rad(degrees), 0.0)
		on_circle = (on_circle and absf((foot.global_position - lower.global_position).length() - 0.3) < 0.0005
			and near(lower.global_position, Vector3(-0.75, 1.12, 1.059808)))
	check("turning Lower swings the foot around Lower's origin: 0.3 m from the knee at five angles, and the knee does not move", on_circle)
	var by_hand := true
	for angles: Array in [[10.0, 25.0, 40.0], [-70.0, 115.0, 5.0], [200.0, -33.0, 91.0]]:
		var a1 := deg_to_rad(angles[0])
		var a2 := deg_to_rad(angles[1])
		var a3 := deg_to_rad(angles[2])
		set_angles(study, a1, a2, a3)
		by_hand = (by_hand and near(foot.global_position, foot_by_hand(0.0, a1, a2)) and near(toe.global_position, toe_by_hand(0.0, a1, a2, a3))
			and near(foot.position, Vector3(0, 0, 0.3)) and near(toe.position, Vector3(0, -DROP, 0.3)))
	check("at three other sets of joint angles the foot's and the toe's global_position equal the sum worked out by hand, and their position never changes", by_hand)

	# Basis: which way a bar points.
	set_angles(study, thirty, thirty, thirty)
	check("every joint at 30 degrees: the foot's basis.z is (0.5, 0, 0.866) and its global_basis.z is (1, 0, 0): it points along +x",
		near(foot.basis.z, Vector3(0.5, 0, 0.866025)) and near(foot.global_basis.z, Vector3(1, 0, 0)) and near(lower.global_basis.z, Vector3(0.866025, 0, 0.5)))
	check("the toe is at (-0.1902, 0.99, 1.2098): the foot's global_position and 0.3 m along its global_basis.z, 0.13 m down",
		near(toe.global_position, Vector3(-0.190192, 0.99, 1.209808)) and near(toe.global_position, toe_by_hand(0.0, thirty, thirty, thirty))
		and near(foot.global_position + foot.global_basis.z * 0.3 + Vector3(0, -DROP, 0), toe.global_position))
	check("to_global() does the same sum: foot.to_global(Vector3(0, -0.13, 0.3)) is the toe; to_local() undoes it",
		near(foot.to_global(Vector3(0, -DROP, 0.3)), toe.global_position) and near(foot.to_local(toe.global_position), toe.position))
	measured["toe_at_30_30_30"] = rounded(toe.global_position)

	# The bodies follow the bars: each Bar's collider is stretched and carried with it.
	await physics_frame
	await physics_frame
	var foot_bar: Node3D = foot.get_node("Bar")
	var on_bar := ray_down(foot_bar.global_position, 0.5)
	var beside := ray_down(Vector3(-0.9, 0, 1.55), 1.06)
	check("a ray sent down meets the foot's bar where it now lies, at its top, 1.16 m, and nothing where it lay at rest",
		on_bar[0].ends_with("Foot/Bar/Body") and absf(on_bar[1] - 1.16) < 0.001 and beside[0] == "nothing")

	# The command chain: a child cannot move its parent.
	set_angles(study, 0.0, 0.0, 0.0)
	foot.global_position = Vector3(0.0, 1.12, 1.0)
	check("the foot placed by hand at (0, 1.12, 1.0): the hip and the knee stay; the foot's position becomes (0.9, 0, -0.1)",
		near(hip.global_position, HIP) and near(lower.global_position, HIP + Vector3(0, 0, 0.3)) and near(foot.position, Vector3(0.9, 0, -0.1)))
	foot.position = Vector3(0, 0, 0.3)
	hip.position += Vector3(0.5, 0, 0)
	check("the hip moved 0.5 m along x: the knee, the foot and the toe move 0.5 m with it, and no position below the hip changes",
		near(lower.global_position, HIP + Vector3(0.5, 0, 0.3)) and near(toe.global_position, Vector3(-0.4, 0.99, 1.7))
		and near(foot.position, Vector3(0, 0, 0.3)) and near(lower.position, Vector3(0, 0, 0.3)))
	hip.position = HIP

	# The wrong node: the bars turned and not their joints.
	for bar: MeshInstance3D in bars:
		bar.rotation.y = thirty
	check("the three Bars turned 30 degrees and no joint: every bar spins on its own middle, and the foot and the toe stay where they rest",
		near(foot.global_position, Vector3(-0.9, 1.12, 1.4)) and near(toe.global_position, Vector3(-0.9, 0.99, 1.7))
		and near(bar0.global_position, HIP + Vector3(0, 0, 0.15)) and bar0.scale.is_equal_approx(Vector3(0.16, 0.16, 0.6)))
	var gap := (bar_end(study, "Hip/Upper", true) - bar_end(study, "Hip/Upper/Lower", false)).length()
	check("and the chain comes apart: the upper bar's far end and the lower bar's near end are %.3f m apart" % gap, absf(gap - 2.0 * 0.3 * sin(thirty / 2.0)) < 0.001)
	measured["bars_turned_gap_m"] = snappedf(gap, 0.001)
	for bar: MeshInstance3D in bars:
		bar.rotation.y = 0.0

	# It moves by itself: one call of _process.
	organism.angle = 0.0
	lattice.fill()
	organism._process(0.25)
	check("one call of _process(0.25) with speed 0.6: angle is 0.15, and each of the three joints is turned by it",
		is_equal_approx(organism.angle, 0.15) and is_equal_approx(upper.rotation.y, 0.15)
		and is_equal_approx(lower.rotation.y, 0.15) and is_equal_approx(foot.rotation.y, 0.15) and is_equal_approx(organism.speed, 0.6))
	await close(study)

	# Delta: one second at four frame rates, stepped by hand.
	var with_delta := {}
	var without := {}
	for rate in [30, 60, 90, 144]:
		study = await open(0)
		organism = study.get_node("Organism")
		for i in rate:
			organism._process(1.0 / rate)
		with_delta[rate] = organism.angle
		var at_delta: Vector3 = study.get_node(CHAIN).global_position
		await close(study)
		study = await open(0, "res://organism_frames.gd")
		organism = study.get_node("Organism")
		for i in rate:
			organism._process(1.0 / rate)
		without[rate] = organism.angle
		measured["one_second_%d_frames" % rate] = {"angle_with_delta": snappedf(with_delta[rate], 0.0001), "angle_per_frame": snappedf(without[rate], 0.0001), "toe_with_delta": rounded(at_delta)}
		await close(study)
	check("angle += speed * delta: after one second the angle is 0.6000 rad at 30, 60, 90 and 144 frames a second",
		absf(with_delta[30] - 0.6) < 0.000001 and absf(with_delta[60] - 0.6) < 0.000001
		and absf(with_delta[90] - 0.6) < 0.000001 and absf(with_delta[144] - 0.6) < 0.000001)
	check("angle += 0.01 a frame: after one second it is 0.30 at 30, 0.60 at 60, 0.90 at 90 and 1.44 at 144: it scales with the frame rate",
		absf(without[30] - 0.3) < 0.000001 and absf(without[60] - 0.6) < 0.000001
		and absf(without[90] - 0.9) < 0.000001 and absf(without[144] - 1.44) < 0.000001)
	check("without delta, 90 frames a second turn the limb 1.5 times as far as 60, and 144 turn it 4.8 times as far as 30",
		absf(without[90] / without[60] - 1.5) < 0.000001 and absf(without[144] / without[30] - 4.8) < 0.000001)

	# The pivot: four values, the same three joint angles.
	var toes := []
	var gaps := []
	var bars_at_rest := []
	var joints_ok := true
	for v in 4:
		study = await open(v)
		var p: float = FRACTIONS[v]
		bars_at_rest.append([bar_end(study, "Hip/Upper", false), bar_end(study, "Hip/Upper/Lower", false), bar_end(study, "Hip/Upper/Lower/Foot", true), study.get_node(CHAIN).global_position])
		joints_ok = (joints_ok and near(study.get_node("Organism/Hip/Upper").global_position, HIP + Vector3(0, 0, p * L))
			and near(study.get_node("Organism/Hip/Upper/Lower").position, Vector3(0, 0, L))
			and near(study.get_node("Organism/Hip/Upper/Lower/Foot").position, Vector3(0, 0, L))
			and near(study.get_node("Organism/Hip/Upper/Bar").position, Vector3(0, 0, L / 2.0 - p * L)))
		set_angles(study, thirty, thirty, thirty)
		var at: Vector3 = study.get_node(CHAIN).global_position
		toes.append(at)
		gaps.append((bar_end(study, "Hip/Upper", true) - bar_end(study, "Hip/Upper/Lower", false)).length())
		check("pivot %d %s: with every joint at 30 degrees the toe is at (%.3f, %.3f, %.3f), as worked out by hand" % [v, NAMES[v], at.x, at.y, at.z],
			near(at, toe_by_hand(p, thirty, thirty, thirty)))
		await close(study)
	var same_rest := true
	for v in range(1, 4):
		for k in 4:
			same_rest = same_rest and near(bars_at_rest[v][k], bars_at_rest[0][k])
	check("at rest the four values put every bar and the toe in the same place: only the pins differ", same_rest)
	check("the Upper pin stands 0, 0.1, 0.15 m ahead of the hip and 0.15 m behind it; Lower and Foot stay one bar's length from their parents", joints_ok)
	check("the toes at 30 degrees are the lesson's: (-0.19, 1.21), (-0.29, 1.31), (-0.34, 1.36) and (-0.04, 1.06) in x and z",
		near(toes[0], Vector3(-0.190, 0.99, 1.210), 0.002) and near(toes[1], Vector3(-0.290, 0.99, 1.310), 0.002)
		and near(toes[2], Vector3(-0.340, 0.99, 1.360), 0.002) and near(toes[3], Vector3(-0.040, 0.99, 1.060), 0.002))
	check("the closest two toes are one third and the centre, %.3f m apart; the end and one third are %.3f m apart" % [(toes[1] - toes[2]).length(), (toes[0] - toes[1]).length()],
		(toes[1] - toes[2]).length() < (toes[0] - toes[1]).length() and (toes[1] - toes[2]).length() < (toes[0] - toes[3]).length()
		and (toes[1] - toes[2]).length() < (toes[2] - toes[3]).length())
	check("only with the pivot at the end does the chain stay joined: the gap at the knee is %.3f, %.3f, %.3f and %.3f m" % gaps,
		gaps[0] < 0.0005 and absf(gaps[1] - 2.0 * 0.1 * sin(thirty / 2.0)) < 0.0005
		and absf(gaps[2] - 2.0 * 0.15 * sin(thirty / 2.0)) < 0.0005 and absf(gaps[3] - 2.0 * 0.15 * sin(thirty / 2.0)) < 0.0005)
	measured["toe_at_30_by_pivot"] = [rounded(toes[0]), rounded(toes[1]), rounded(toes[2]), rounded(toes[3])]
	measured["knee_gap_at_30_by_pivot_m"] = gaps.map(func(g): return snappedf(g, 0.001))

	# The lattice.
	study = await open(0)
	organism = study.get_node("Organism")
	lattice = organism.get_node("Lattice")
	toe = study.get_node(CHAIN)
	marble = study.get_node("Marble")
	check("the lattice is 8 columns by 11 rows of 0.1 m cells, 0.12 m apart: 88 cells, the first at (-0.6, 0.99, 0.24), their tops at 1.04 m",
		lattice.cells.size() == 88 and lattice.columns == 8 and lattice.rows == 11 and near(lattice.global_position, LATTICE_AT)
		and near(lattice.cells[Vector2i(0, 0)][0].global_position, LATTICE_AT)
		and near(lattice.cells[Vector2i(7, 10)][0].global_position, LATTICE_AT + Vector3(0.84, 0, 1.2))
		and lattice.get_node("Count").text == "88 of 88 cells")
	check("the limb slides over it and only the toe dips in: the bars' undersides are at 1.08 m, the toe's middle at 0.99 m",
		absf(bar_end(study, "Hip/Upper", true).y - 0.04 - 1.08) < 0.0005 and absf(toe.global_position.y - 0.99) < 0.0005)
	check("carve() far from every cell takes nothing and returns 0", lattice.carve(Vector3(3, 1, 3)) == 0 and lattice.cells.size() == 88)
	var taken: int = lattice.carve(LATTICE_AT + Vector3(0.36, 5.0, 0.6))
	check("carve() over the middle of cell (3, 5), five metres up, returns 5: the cell and its four neighbours; height does not count",
		taken == 5 and as_set(lattice.lost) == as_set([Vector2i(3, 5), Vector2i(2, 5), Vector2i(4, 5), Vector2i(3, 4), Vector2i(3, 6)])
		and lattice.get_node("Count").text == "83 of 88 cells")
	check("carve() at the same place again returns 0: the cut stays, and nothing is lost twice", lattice.carve(LATTICE_AT + Vector3(0.36, 5.0, 0.6)) == 0)
	lattice.fill()
	check("fill() builds the lattice again, whole", lattice.cells.size() == 88 and lattice.lost.is_empty())

	# One whole turn with the toe's global_position: the lesson's line.
	var lost_global := turn(study, 1.0 / 60.0)
	var must := {}
	var may := {}
	for k in range(1, 630):
		cells_near(toe_by_hand(0.0, k * 0.01, k * 0.01, k * 0.01), must, may)
	var lost_set := as_set(lattice.lost)
	check("one whole turn, told the toe's global_position: the lattice loses %d cells and reads '%s'" % [lost_global, lattice.get_node("Count").text],
		lost_global == 33 and lattice.get_node("Count").text == "55 of 88 cells")
	check("they are the cells the toe passed over: every cell within 0.16 m of the path worked out by hand, and no other",
		subset(must, lost_set) and subset(lost_set, may) and must.size() >= 30)
	var again := 0
	for i in 629:
		again += lattice.carve(toe_by_hand(0.0, i * 0.01, i * 0.01, i * 0.01))
	check("a second turn takes nothing more: the cut is kept", again == 0 and lattice.cells.size() == 55)
	organism._process(0.0)
	marble.drop(LATTICE_AT + Vector3(0.42, 1.0, 0.96))
	rest = await settle(marble)
	check("a marble dropped over the cut falls through the lattice to the floor: %.3f m" % rest.y, rest.y < 0.2)
	marble.drop(LATTICE_AT + Vector3(0.72, 1.0, 0.24))
	rest = await settle(marble)
	check("a marble dropped over cells that are left rests on them: %.3f m, their tops at 1.04 m and its radius" % rest.y, absf(rest.y - (1.04 + RADIUS)) < 0.02)
	measured["cells_lost_in_one_turn_global"] = lost_global
	var kept: Array = lattice.lost.duplicate()

	# The same turn with the toe's position: the planted mistake.
	lattice.fill()
	var first: int = lattice.carve(toe.position)
	var local_total := first
	for k in range(1, 630):
		set_angles(study, k * 0.01, k * 0.01, k * 0.01)
		local_total += lattice.carve(toe.position)
	var local_set := as_set(lattice.lost)
	check("told the toe's position, (0, -0.13, 0.3), the lattice loses 6 cells in the first frame and no more in a whole turn: '%s'" % lattice.get_node("Count").text,
		first == 6 and local_total == 6 and lattice.get_node("Count").text == "82 of 88 cells" and near(toe.position, Vector3(0, -DROP, 0.3)))
	check("they are the wrong cells: columns 4 to 6 of rows 0 and 1, over the spot 0.3 m in front of the middle of the room",
		local_set == as_set([Vector2i(4, 0), Vector2i(4, 1), Vector2i(5, 0), Vector2i(5, 1), Vector2i(6, 0), Vector2i(6, 1)]))
	var shared := 0
	for key in local_set:
		if may.has(key):
			shared += 1
	check("not one of them is a cell the toe passes over: the two cuts share no cell", shared == 0 and not subset(local_set, as_set(kept)))
	measured["cells_lost_local_position"] = local_total

	# The cut and the frame rate: delta repairs the speed, not the sampling.
	var by_rate := {}
	for rate in [144, 60, 30, 10, 5, 3]:
		by_rate[rate] = turn(study, 1.0 / rate)
	check("one turn takes 33 cells at 144, 60, 30 and 10 frames a second, %d at 5 and %d at 3: slow frames step over cells" % [by_rate[5], by_rate[3]],
		by_rate[144] == 33 and by_rate[60] == 33 and by_rate[30] == 33 and by_rate[10] == 33 and by_rate[5] == 32 and by_rate[3] == 26)
	measured["cells_lost_in_one_turn_by_frame_rate"] = by_rate
	await close(study)

	# The pivot decides the cut.
	var cuts := []
	for v in 4:
		study = await open(v)
		cuts.append(turn(study, 1.0 / 60.0))
		await close(study)
	check("one turn takes 33, 26, 23 and 45 cells at the four values of pivot: the same bars and angles, four cuts", cuts == [33, 26, 23, 45])
	measured["cells_lost_in_one_turn_by_pivot"] = cuts

	# A stretch on a joint shears what hangs below it.
	study = await open(0)
	set_angles(study, thirty, thirty, thirty)
	lower = study.get_node("Organism/Hip/Upper/Lower")
	var square := rad_to_deg(lower.global_basis.x.angle_to(lower.global_basis.z))
	study.get_node("Organism/Hip/Upper").scale = Vector3(1, 1, 2)
	var sheared := rad_to_deg(lower.global_basis.x.angle_to(lower.global_basis.z))
	check("Upper stretched to (1, 1, 2) with the joints at 30 degrees: Lower's x and z axes stand at %.1f degrees, where they stood at %.1f" % [sheared, square],
		absf(square - 90.0) < 0.01 and absf(sheared - 123.0) < 0.05)
	check("and they are no longer 1 long: %.3f and %.3f; Lower's own scale still reads (1, 1, 1)" % [lower.global_basis.x.length(), lower.global_basis.z.length()],
		absf(lower.global_basis.x.length() - 1.323) < 0.001 and absf(lower.global_basis.z.length() - 1.803) < 0.001 and lower.scale.is_equal_approx(Vector3.ONE))
	measured["shear_lower_axes_degrees"] = snappedf(sheared, 0.01)
	await close(study)

	# Become it: the hip follows B, and B is walked through the lattice.
	study = await open(0)
	organism = study.get_node("Organism")
	lattice = organism.get_node("Lattice")
	hip = organism.get_node("Hip")
	b = study.get_node("B")
	marble = study.get_node("Marble")
	b.set_process(false)
	organism.speed = 0.0
	check("B starts at (0.75, 1.12, 0), at the hip's height: the hip can take B's position as it is", near(b.position, Vector3(0.75, 1.12, 0.0)) and is_equal_approx(b.position.y, hip.position.y))
	var x := 0.75
	while x > -1.55:
		b.position.x = x
		hip.position = b.position
		organism._process(1.0 / 60.0)
		x -= 0.02
	var passage := as_set(lattice.lost)
	var rows_5_6 := {}
	for column in 8:
		rows_5_6[Vector2i(column, 5)] = true
		rows_5_6[Vector2i(column, 6)] = true
	check("the hip carried by B from x = 0.75 to -1.55, the limb held straight: the toe cuts a passage of 16 cells, rows 5 and 6 from side to side",
		passage == rows_5_6 and lattice.get_node("Count").text == "72 of 88 cells")
	marble.drop(Vector3(-0.2, 2.0, 0.9))
	rest = await settle(marble)
	check("a marble dropped over the passage falls through it to the floor: %.3f m" % rest.y, rest.y < 0.2)
	await close(study)

	# The measured second: what second.gd wrote at real fixed frame rates.
	if FileAccess.file_exists("res://second.json"):
		var second: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://second.json"))
		measured["second"] = second
		second_checks(second)

	# The sheet's record, if it has been rendered.
	if FileAccess.file_exists("res://sheet.json"):
		var sheet: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://sheet.json"))
		measured["sheet"] = sheet
		sheet_checks(sheet, cuts)

	var passed := checks.all(func(c): return c.passed)
	var report := {"passed": passed, "godot": Engine.get_version_info().string, "measured": measured, "checks": checks}
	FileAccess.open("res://verification.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("Organism study: ", checks.size(), " checks; passed=", passed)
	quit(0 if passed else 1)

func second_checks(second: Dictionary) -> void:
	var rates_ok := true
	var same := true
	var scaled := true
	for rate in ["30", "60", "90", "144"]:
		var entry: Dictionary = second.get(rate, {})
		var per_frame: Dictionary = entry.get("per_frame", {})
		var per_second: Dictionary = entry.get("per_second", {})
		rates_ok = rates_ok and int(per_frame.get("frames", 0)) == int(rate) and int(per_second.get("frames", 0)) == int(rate)
		same = same and absf(per_second.get("angle_rad", 0.0) - 0.6) < 0.0001 and per_second.get("toe", []) == second["60"]["per_second"]["toe"]
		scaled = scaled and absf(per_frame.get("angle_rad", 0.0) - 0.01 * int(rate)) < 0.0001
	check("second.json: runs with --fixed-fps 30, 60, 90 and 144 counted 30, 60, 90 and 144 frames in one second", rates_ok)
	check("second.json: with speed * delta the angle after one second was 0.6000 rad in all four runs, and the toe in the same place", same)
	check("second.json: with 0.01 a frame it was 0.30, 0.60, 0.90 and 1.44 rad: 17, 34, 52 and 83 degrees", scaled)

func sheet_checks(sheet: Dictionary, cuts: Array) -> void:
	check("sheet.json: with every joint at 30 degrees the closest pair is one third and the centre, from above and from the top",
		sheet.get("closest_pair_above", "") == "1 vs 2" and sheet.get("closest_pair_top", "") == "1 vs 2")
	var rest_pairs: Dictionary = sheet.get("pairs_rest_top_pct", {"none": 100.0})
	var pose_pairs: Dictionary = sheet.get("pairs_top_pct", {"none": 0.0})
	check("sheet.json: at rest no two values differ on more than 0.3% of the frame (the pins); at 30 degrees every pair differs on more than 1%",
		rest_pairs.values().max() < 0.3 and pose_pairs.values().min() > 1.0)
	var toes_ok := true
	var cells_ok := true
	var expected := [[-0.19, 0.99, 1.21], [-0.29, 0.99, 1.31], [-0.34, 0.99, 1.36], [-0.04, 0.99, 1.06]]
	for v in 4:
		var entry: Dictionary = sheet.get(str(v), {})
		var at: Array = entry.get("toe", [9, 9, 9])
		toes_ok = toes_ok and absf(at[0] - expected[v][0]) < 0.002 and absf(at[1] - expected[v][1]) < 0.002 and absf(at[2] - expected[v][2]) < 0.002
		cells_ok = cells_ok and int(entry.get("cells_lost_in_one_turn", -1)) == cuts[v]
	check("sheet.json: with a window the four toes are where they are headless", toes_ok)
	check("sheet.json: with a window one turn takes the same 33, 26, 23 and 45 cells", cells_ok)
	check("sheet.json: told the toe's position, the lattice lost 6 cells in a whole turn",
		int(sheet.get("local_position", {}).get("cells_lost_in_one_turn", -1)) == 6)
	check("sheet.json: the bars turned and no joint: the toe stays at (-0.9, 0.99, 1.7), and the still differs from rest",
		sheet.get("bars_turned", {}).get("toe", []) == [-0.9, 0.99, 1.7] and sheet.get("bars_turned", {}).get("differs_from_rest_pct", 0.0) > 0.5)
	check("sheet.json: a stretch on Upper shears Lower to 123 degrees and changes the still on more than 1% of the frame",
		absf(sheet.get("stretched_joint", {}).get("lower_x_to_z_degrees", 0.0) - 123.0) < 0.05
		and sheet.get("stretched_joint", {}).get("differs_from_unstretched_pct", 0.0) > 1.0)
