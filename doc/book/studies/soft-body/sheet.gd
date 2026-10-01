extends "res://supplied/sheet_tools.gd"
## The sheet of the Soft body study. It needs a window, so run it WITHOUT
## --headless, from this folder:
##   godot --path . --xr-mode off --script res://sheet.gd
## It writes
##   sheet.png    two rows of four: our cloth at 1, 4, 16 and 64 passes over
##                its links in one step, and the SoftBody3D of Godot at
##                simulation_precision 1, 4, 16 and 64; each alone in the
##                studio, from the front, at rest
##   process.png  the strip: seven stills from one standpoint, one after each
##                operation of the lesson
##   sheet.json   every pair of each row; the lowest point, the stretch and
##                the cost of each value; what each step of the strip changed
## and the stills, in stills/. Our cloth is stepped by this script, 1200 steps
## of 1/60 s for each still, so the same picture comes out on every run. The
## soft body of Godot is stepped by the engine, 600 steps of 1/60 s. For those
## the clock runs four times as fast and the physics ticks four times as
## often, which leaves the length of a step as it was and keeps the window
## open for a shorter time.

const Cloth := preload("res://cloth.gd")
const SoftCloth := preload("res://soft_cloth.gd")
const VALUES := [1, 4, 16, 64]
const STEP := 1.0 / 60.0
const TAUT := 0.8                  # metres: where the lowest point would be if no link gave
const FLOOR := [Vector3(0.0, -1000.0, 0.0), Vector3(0.0, -1000.0, 0.0), 1000.01]

func run() -> void:
	await sheet()
	await process_strip()

## Our cloth, hung at 2 m, not stepping by itself.
func hung(passes: int) -> MeshInstance3D:
	var cloth: MeshInstance3D = Cloth.new()
	cloth.iterations = passes
	cloth.position = Vector3(0.0, 2.0, 0.0)
	cloth.process_mode = Node.PROCESS_MODE_DISABLED   # it steps when this script steps it, and at no other time
	return cloth

## `steps` steps of a cloth; `bodies` are told to it before each. Returns the milliseconds one step took.
func stepped(cloth: MeshInstance3D, steps: int, bodies := []) -> float:
	var began := Time.get_ticks_usec()
	for i in steps:
		for body: Array in bodies:
			cloth.meet(body[0], body[1], body[2])
		cloth.step(STEP)
	var cost := (Time.get_ticks_usec() - began) / 1000.0 / steps
	cloth.draw()
	return cost

func measure(cloth: MeshInstance3D) -> Dictionary:
	var lowest := INF
	for particle in cloth.particles:
		lowest = minf(lowest, cloth.to_global(particle.position).y)
	var total := 0.0
	var worst := 0.0
	for k in range(0, cloth.links.size(), 2):
		var length: float = cloth.particles[cloth.links[k]].position.distance_to(cloth.particles[cloth.links[k + 1]].position)
		total += absf(length - cloth.spacing) / cloth.spacing
		worst = maxf(worst, length / cloth.spacing)
	return {
		"lowest_point_m": snappedf(lowest, 0.0001), "below_taut_cm": snappedf((TAUT - lowest) * 100.0, 0.01),
		"mean_link_error_pct": snappedf(100.0 * total / (cloth.links.size() / 2.0), 0.01), "longest_link_pct_of_its_length": snappedf(100.0 * worst, 0.1),
	}

func physics_steps(count: int) -> void:
	for i in count:
		await physics_frame

## The soft body of Godot, as soft_body.tscn has it: the same plane, the same script.
func godots(precision: int) -> SoftBody3D:
	var soft: SoftBody3D = SoftCloth.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(1.2, 1.2)
	plane.subdivide_width = 9
	plane.subdivide_depth = 9
	plane.orientation = PlaneMesh.FACE_Z
	soft.mesh = plane
	soft.simulation_precision = precision
	soft.position = Vector3(0.0, 1.4, 0.0)
	return soft

## The comparison sheet: both cloths at the four values, every pair measured.
func sheet() -> void:
	var tiles: Array[Image] = []
	var captions := []
	var names := []
	for value: int in VALUES:
		names.append(str(value))
	# Ours.
	var stills := []
	var pixels := []
	var ours := {}
	for value: int in VALUES:
		var cloth := hung(value)
		await stand(cloth)
		var cost := stepped(cloth, 600)
		var at_600 := measure(cloth)
		stepped(cloth, 600)
		var row := measure(cloth)
		row["lowest_point_after_600_steps_m"] = at_600["lowest_point_m"]
		row["ms_a_step"] = snappedf(cost, 0.001)
		look("level", 3.2, Vector3(0.0, 1.05, 0.0))
		var taken: Array = await portrait(cloth, "ours_%d" % value)
		row["covers_pct"] = share(taken[1])
		ours[str(value)] = row
		stills.append(taken[0])
		pixels.append(taken[1])
		tiles.append(small(taken[0]))
		captions.append("ours, %d pass%s" % [value, "" if value == 1 else "es"])
		print("ours, %2d passes: lowest point %.4f m, %.2f cm below taut, longest link %.1f%%, mean error %.2f%%, %.3f ms a step, covers %.2f%%" % [
			value, row["lowest_point_m"], row["below_taut_cm"], row["longest_link_pct_of_its_length"], row["mean_link_error_pct"], row["ms_a_step"], row["covers_pct"]])
	report["ours"] = ours
	report["pairs_ours"] = compare_all(names, stills, pixels)
	# The soft body of Godot.
	stills = []
	pixels = []
	var theirs := {}
	Engine.physics_ticks_per_second = 240
	Engine.time_scale = 4.0
	for value: int in VALUES:
		var soft := godots(value)
		await stand(soft, false)
		await physics_steps(600)
		var lowest := INF
		for i in 121:
			lowest = minf(lowest, soft.get_point_transform(i).y)
		look("level", 3.2, Vector3(0.0, 1.05, 0.0))
		var taken: Array = await portrait(soft, "godots_%d" % value)
		theirs[str(value)] = {"lowest_point_m": snappedf(lowest, 0.0001), "below_taut_cm": snappedf((TAUT - lowest) * 100.0, 0.01),
			"covers_pct": share(taken[1]), "linear_stiffness": soft.linear_stiffness}
		stills.append(taken[0])
		pixels.append(taken[1])
		tiles.append(small(taken[0]))
		captions.append("Godot's, precision %d" % value)
		print("Godot's, precision %2d: lowest point %.4f m, %.2f cm below taut, covers %.2f%%" % [value, lowest, theirs[str(value)]["below_taut_cm"], theirs[str(value)]["covers_pct"]])
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	report["godots"] = theirs
	report["pairs_godots"] = compare_all(names, stills, pixels)
	report["how"] = "each cloth alone in the studio, 1.2 m square, 11 by 11 points, hung by its two top corners at 2 m, seen from the front, 3.2 m from the point (0, 1.05, 0); ours after 1200 steps of 1/60 s made by sheet.gd, the soft body of Godot after 600 steps of the engine; below_taut_cm is how far the lowest point is below 0.8 m"
	report["sheet_png"] = await compose(tiles, VALUES.size(), captions, "res://sheet.png")

## A group for one tile of the strip: the cloth with its Hand, hung at (0.3, 2, 0).
func tile_group(passes: int) -> Node3D:
	var group := Node3D.new()
	var cloth := hung(passes)
	cloth.name = "Cloth"
	cloth.position = Vector3(0.3, 2.0, 0.0)
	var hand := MeshInstance3D.new()
	hand.name = "Hand"
	var dot := SphereMesh.new()
	dot.radius = 0.05
	dot.height = 0.1
	hand.mesh = dot
	hand.material_override = Look.paint(Look.BONE)
	hand.position = Vector3(0.6, 0.0, 0.0)
	cloth.add_child(hand)
	group.add_child(cloth)
	return group

## Moves the hand to `to`, in the frame of the cloth, at 1.2 m a second, one step of the cloth at a time.
func carry(cloth: MeshInstance3D, to: Vector3, bodies: Array) -> void:
	var hand: Node3D = cloth.get_node("Hand")
	while hand.position.distance_to(to) > 0.0001:
		hand.position = hand.position.move_toward(to, 1.2 * STEP)
		stepped(cloth, 1, bodies)

func pinned(cloth: MeshInstance3D) -> int:
	var count := 0
	for particle in cloth.particles:
		if particle is Cloth.PinnedParticle:
			count += 1
	return count

## The process strip: one still after each operation, from one standpoint.
func process_strip() -> void:
	var names := ["1 a sheet of particles", "2 two are pinned", "3 links: 1 pass a step", "4 16 passes a step", "5 carried by a corner", "6 a walker in it", "7 the nail is pulled"]
	var tiles: Array[Image] = []
	var counts := []
	var from := Vector3(0.3, 1.7, 5.0)
	var at := Vector3(0.3, 1.05, 0.0)
	# 1. Nothing holds it and nothing joins it: after 20 steps it has fallen whole.
	var group := tile_group(4)
	await stand(group)
	var cloth: MeshInstance3D = group.get_node("Cloth")
	cloth.let_go()
	cloth.let_go()
	stepped(cloth, 20)
	look_from(from, at)
	tiles.append(small(await shot("strip_1")))
	counts.append({"pinned": pinned(cloth), "passes": 0, "lowest_point_m": measure(cloth)["lowest_point_m"]})
	# 2. Two are pinned, and still nothing joins them: after 25 steps.
	group = tile_group(0)
	await stand(group)
	cloth = group.get_node("Cloth")
	stepped(cloth, 25)
	look_from(from, at)
	tiles.append(small(await shot("strip_2")))
	counts.append({"pinned": pinned(cloth), "passes": 0, "lowest_point_m": measure(cloth)["lowest_point_m"]})
	# 3 and 4. Links, relaxed once and sixteen times a step, at rest.
	for passes: int in [1, 16]:
		group = tile_group(passes)
		await stand(group)
		cloth = group.get_node("Cloth")
		stepped(cloth, 1200)
		look_from(from, at)
		tiles.append(small(await shot("strip_%d" % (tiles.size() + 1))))
		counts.append({"pinned": pinned(cloth), "passes": passes, "lowest_point_m": measure(cloth)["lowest_point_m"]})
	# 5. The hand carries its corner 1.2 m toward us.
	group = tile_group(16)
	await stand(group)
	cloth = group.get_node("Cloth")
	stepped(cloth, 600)
	carry(cloth, Vector3(0.6, 0.0, 1.2), [])
	stepped(cloth, 300)
	look_from(from, at)
	tiles.append(small(await shot("strip_5")))
	counts.append({"pinned": pinned(cloth), "passes": 16, "lowest_point_m": measure(cloth)["lowest_point_m"], "longest_link_pct_of_its_length": measure(cloth)["longest_link_pct_of_its_length"]})
	# 6. A walker stands in it. The cloth is told where: a capsule.
	group = tile_group(16)
	var walker: CharacterBody3D = load("res://supplied/walker.tscn").instantiate()
	walker.position = Vector3(0.3, 0.0, 0.07)
	group.add_child(walker)
	await stand(group)
	cloth = group.get_node("Cloth")
	stepped(cloth, 600)
	stepped(cloth, 300, [[Vector3(0.3, 0.3, 0.07), Vector3(0.3, 1.5, 0.07), 0.34]])
	look_from(from, at)
	tiles.append(small(await shot("strip_6")))
	var out_of_plane := 0.0
	for particle in cloth.particles:
		out_of_plane = maxf(out_of_plane, absf(particle.position.z))
	counts.append({"pinned": pinned(cloth), "passes": 16, "lowest_point_m": measure(cloth)["lowest_point_m"], "pushed_out_of_its_plane_m": snappedf(out_of_plane, 0.001)})
	# 7. The nail is pulled: the cloth hangs from the hand alone, over the floor.
	group = tile_group(16)
	await stand(group)
	cloth = group.get_node("Cloth")
	stepped(cloth, 600, [FLOOR])
	cloth.let_go()
	stepped(cloth, 900, [FLOOR])
	look_from(from, at)
	tiles.append(small(await shot("strip_7")))
	var widest := 0.0
	var in_the_air := 0
	for particle in cloth.particles:
		if cloth.to_global(particle.position).y > 0.1:
			in_the_air += 1
			widest = maxf(widest, Vector2(particle.position.x - 0.6, particle.position.z).length())
	counts.append({"pinned": pinned(cloth), "passes": 16, "lowest_point_m": measure(cloth)["lowest_point_m"], "particles_above_0.1_m": in_the_air, "their_farthest_from_the_line_under_the_hand_m": snappedf(widest, 0.001)})
	report["strip"] = await strip(tiles, names)
	report["strip"]["counts"] = counts
